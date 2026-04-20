import 'dart:collection';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/data/models/pdf_document.dart';
import '../../../../core/services/pdf_ai_service.dart';
import '../../../../core/data/repositories/chat_repository.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import 'pdf_chat_state.dart';

// Forward declaration to avoid circular dependency
// The repository will use RepositoryChatMessage internally

part 'pdf_chat_notifier.g.dart';

/// Provider for PDF AI service
@riverpod
PdfAIService pdfAIService(Ref ref) {
  return PdfAIService(
    functions: FirebaseFunctions.instanceFor(region: 'asia-southeast1'),
    auth: FirebaseAuth.instance,
  );
}

/// Provider for PDF chat state management
@riverpod
class PdfChatNotifier extends _$PdfChatNotifier {
  // Maximum cache size to prevent memory leaks
  static const int _maxCacheSize = 20;

  // Static cache that persists across provider instances with LRU eviction
  static final LinkedHashMap<String, String> _pdfPathCache = LinkedHashMap();
  static final LinkedHashMap<String, PdfDocument> _pdfCache = LinkedHashMap();
  static final LinkedHashMap<String, List<ChatMessage>> _messagesCache =
      LinkedHashMap();

  PdfAIService? _aiService;
  ChatRepository? _chatRepository;

  // Store current chat session ID
  String? _currentSessionId;

  // Store current PDF ID
  String? _currentPdfId;

  // Store current PDF document
  PdfDocument? _currentPdf;

  /// Add to cache with LRU eviction when size limit is reached
  void _addToCache<K, V>(LinkedHashMap<K, V> cache, K key, V value) {
    // Remove oldest entry if cache is full
    if (cache.length >= _maxCacheSize) {
      final oldestKey = cache.keys.first;
      cache.remove(oldestKey);
      AppLogger.d('Evicted oldest cache entry: $oldestKey');
    }
    cache[key] = value;
  }

  @override
  PdfChatState build(String pdfId) {
    AppLogger.i('=== PdfChatNotifier.build() called ===');
    AppLogger.i('pdfId parameter: $pdfId');
    _aiService = ref.watch(pdfAIServiceProvider);
    _chatRepository = ref.watch(chatRepositoryProvider);
    AppLogger.i('✅ _aiService initialized');
    AppLogger.i('✅ _chatRepository initialized');

    // Store pdfId for later use
    _currentPdfId = pdfId;

    // Check if we have a cached PDF path for this pdfId
    final cachedPath = _pdfPathCache[pdfId];
    if (cachedPath != null) {
      AppLogger.i('✅ Found cached PDF path for $pdfId: $cachedPath');

      // Restore _currentPdf from cache if available
      if (_pdfCache.containsKey(pdfId)) {
        _currentPdf = _pdfCache[pdfId];
        AppLogger.i('✅ Restored _currentPdf from cache: ${_currentPdf?.title}');
      }

      // Restore cached messages if available
      final cachedMessages = _messagesCache[pdfId];
      AppLogger.i('📋 Cached messages: ${cachedMessages?.length ?? 0}');

      // Return state with cached path and messages
      return PdfChatState.visible(
        currentPdfPath: cachedPath,
        messages: cachedMessages ?? [],
      );
    }

    AppLogger.i('No cached PDF path for $pdfId, returning initial state');
    return const PdfChatState.initial();
  }

  /// Toggle chat panel visibility
  void togglePanel() {
    state = state.isVisible
        ? const PdfChatState.hidden()
        : const PdfChatState.visible();
  }

  /// Load chat history for a PDF from database
  Future<void> _loadChatHistory(String pdfId) async {
    if (_chatRepository == null) {
      AppLogger.w('Chat repository not available, skipping history load');
      return;
    }

    try {
      AppLogger.i('📥 Loading chat history for PDF: $pdfId');
      final sessionResult = await _chatRepository!.getSessionByPdfId(pdfId);
      AppLogger.i('📊 Session result type: ${sessionResult.runtimeType}');

      // Use when instead of onSuccess to ensure callback is executed
      sessionResult.when(
        success: (session) async {
          AppLogger.i('✅ getSessionByPdfId returned SUCCESS');
          if (session != null) {
            AppLogger.i('📁 Found existing session: ${session.id}');
            _currentSessionId = session.id;

            // Load messages for this session
            final messagesResult = await _chatRepository!.getMessages(
              session.id,
            );
            AppLogger.i(
              '📊 Messages result type: ${messagesResult.runtimeType}',
            );

            messagesResult.when(
              success: (repoMessages) {
                AppLogger.i(
                  '✅ getMessages returned SUCCESS with ${repoMessages.length} messages',
                );
                try {
                  // Convert RepositoryChatMessage to ChatMessage
                  final messages = repoMessages.map((repoMsg) {
                    AppLogger.d(
                      'Converting message: ${repoMsg.id}, isUser: ${repoMsg.isUser}',
                    );
                    return ChatMessage(
                      id: repoMsg.id,
                      content: repoMsg.content,
                      isUser: repoMsg.isUser,
                      timestamp: repoMsg.timestamp,
                      isProcessing: repoMsg.isProcessing,
                      error: repoMsg.error,
                    );
                  }).toList();

                  AppLogger.i(
                    '💾 Loaded ${messages.length} messages from database',
                  );
                  AppLogger.i(
                    '🔄 Updating state with ${messages.length} messages',
                  );
                  AppLogger.d(
                    'First message: ${messages.isNotEmpty ? messages.first.content : "No messages"}',
                  );

                  // Cache messages for this PDF
                  _addToCache(_messagesCache, pdfId, messages);
                  AppLogger.i(
                    '✅ Cached ${messages.length} messages for PDF: $pdfId',
                  );

                  // Update state with loaded messages
                  state = PdfChatState.visible(
                    messages: messages,
                    currentPdfPath: session.pdfFilePath,
                    extractedText: state.extractedText,
                  );
                  AppLogger.i('✅ State updated with messages');
                } catch (e, st) {
                  AppLogger.e('❌ Error converting messages', e, st);
                }
              },
              failure: (error, stackTrace) {
                AppLogger.e('❌ Failed to load messages', error, stackTrace);
                // Continue with empty state on error
              },
            );
          } else {
            AppLogger.i('📭 No existing session found for PDF: $pdfId');
            _currentSessionId = null;
          }
        },
        failure: (error, stackTrace) {
          AppLogger.e(
            '❌ Failed to get session from database',
            error,
            stackTrace,
          );
          // Continue with empty state on error
          _currentSessionId = null;
        },
      );
    } catch (e, st) {
      AppLogger.e('💥 Exception in _loadChatHistory', e, st);
      _currentSessionId = null;
    }
  }

  /// Save a message to the database
  Future<void> _saveMessage(ChatMessage message) async {
    if (_chatRepository == null || _currentSessionId == null) {
      AppLogger.w('Cannot save message: repository or session not available');
      return;
    }

    try {
      // Convert ChatMessage to RepositoryChatMessage
      final repoMessage = RepositoryChatMessage(
        id: message.id,
        content: message.content,
        isUser: message.isUser,
        timestamp: message.timestamp,
        isProcessing: message.isProcessing,
        error: message.error,
      );
      await _chatRepository!.addMessage(_currentSessionId!, repoMessage);
      AppLogger.d('Saved message to database');
    } catch (e, st) {
      AppLogger.e('Failed to save message to database', e, st);
      // Don't throw - keep message in memory at least
    }
  }

  /// Update session metadata (message count, last message time)
  Future<void> _updateSessionMetadata() async {
    if (_chatRepository == null || _currentSessionId == null) {
      return;
    }

    try {
      final messageCount = state.messages.length;
      final lastMessage = state.messages.isNotEmpty
          ? state.messages.last.timestamp.millisecondsSinceEpoch
          : null;

      await _chatRepository!.updateSessionMetadata(
        sessionId: _currentSessionId!,
        messageCount: messageCount,
        lastMessageAt: lastMessage,
      );
      AppLogger.d('Updated session metadata');
    } catch (e, st) {
      AppLogger.e('Failed to update session metadata', e, st);
    }
  }

  /// Get or create chat session for current PDF
  Future<void> _getOrCreateSession() async {
    if (_chatRepository == null || _currentPdf == null) {
      AppLogger.w('Cannot get/create session: repository or PDF not available');
      return;
    }

    try {
      final result = await _chatRepository!.getOrCreateSession(
        _currentPdf!.id,
        _currentPdf!,
      );

      result
          .onSuccess((session) {
            _currentSessionId = session.id;
            AppLogger.i('Session ready: ${session.id}');
          })
          .onFailure((error, st) {
            AppLogger.e('Failed to get or create session', error, st);
            _currentSessionId = null;
          });
    } catch (e, st) {
      AppLogger.e('Error getting or creating session', e, st);
      _currentSessionId = null;
    }
  }

  /// Open the chat panel
  void openPanel() {
    AppLogger.i('=== openPanel called ===');
    AppLogger.i('State before: isVisible=${state.isVisible}');
    AppLogger.i('_currentPdfId: $_currentPdfId');
    AppLogger.i('_currentPdf: $_currentPdf');

    // Always load chat history when panel is opened
    // Use _currentPdfId if available, fallback to _currentPdf
    final pdfId = _currentPdfId ?? _currentPdf?.id;
    if (pdfId != null) {
      AppLogger.i('📝 Loading chat history for PDF: $pdfId');
      _loadChatHistory(pdfId);
    } else {
      AppLogger.w('⚠️  No PDF ID available, cannot load chat history');
    }

    if (!state.isVisible) {
      // Show panel first
      state = PdfChatState.visible(
        currentPdfPath: state.currentPdfPath,
        messages: state.messages,
        extractedText: state.extractedText,
      );
      AppLogger.i('✅ Set state to visible (preserved data)');
    } else {
      AppLogger.i('State already visible');
    }
    AppLogger.i('State after: isVisible=${state.isVisible}');
  }

  /// Close the chat panel
  void closePanel() {
    state = const PdfChatState.hidden();
  }

  /// Initialize with PDF document for text extraction
  Future<void> initializeWithPdf(PdfDocument pdf) async {
    AppLogger.i('=== initializeWithPdf called ===');
    AppLogger.i('pdf.id: ${pdf.id}');
    AppLogger.i('PDF title: ${pdf.title}');
    AppLogger.i('PDF filePath: ${pdf.filePath}');
    AppLogger.i('Current state.currentPdfPath before: ${state.currentPdfPath}');

    // Cache the PDF document
    _pdfCache[pdf.id] = pdf;
    _currentPdf = pdf;

    // Cache the PDF path
    _pdfPathCache[pdf.id] = pdf.filePath;
    AppLogger.i('✅ Cached PDF document and path for ${pdf.id}');

    // Store PDF path in state
    state = PdfChatState.visible(currentPdfPath: pdf.filePath);
    AppLogger.i('✅ Set state.currentPdfPath to: ${state.currentPdfPath}');

    // Load chat history for this PDF
    AppLogger.i('📝 Loading chat history for PDF: ${pdf.id}');
    await _loadChatHistory(pdf.id);
  }

  /// Extract text from the PDF document
  Future<void> extractPdfText(String filePath) async {
    AppLogger.i('=== extractPdfText called ===');
    AppLogger.i('File path: $filePath');

    // Removed isVisible check - if this method is called, panel is open
    if (_aiService == null) {
      AppLogger.w('❌ AI Service is null');
      return;
    }

    AppLogger.i('✅ Starting extraction...');
    // Update to extracting state, preserve currentPdfPath
    state = PdfChatState.visible(
      currentPdfPath: state.currentPdfPath,
      isExtractingText: true,
      extractProgress: 0.0,
    );

    try {
      AppLogger.i('Calling extractTextFromPdf...');
      double progress = 0.0;
      final text = await _aiService!.extractTextFromPdf(
        filePath,
        onProgress: (current, total) {
          progress = total > 0 ? current / total : 0.0;
          if ((progress * 100).toInt() % 10 == 0) {
            // Log every 10%
            AppLogger.d(
              'Extraction progress: $current/$total (${(progress * 100).toStringAsFixed(0)}%)',
            );
          }
          state = PdfChatState.visible(
            currentPdfPath: state.currentPdfPath,
            isExtractingText: true,
            extractProgress: progress,
          );
        },
      );

      AppLogger.i('✅ Extraction complete: ${text.length} chars extracted');
      state = PdfChatState.visible(
        currentPdfPath: state.currentPdfPath,
        extractedText: text,
        extractProgress: 1.0,
      );

      AppLogger.i('State updated with extracted text');
    } catch (e, stackTrace) {
      AppLogger.e('❌ Failed to extract PDF text', e, stackTrace);
      state = PdfChatState.visible(
        currentPdfPath: state.currentPdfPath,
        error: 'Failed to extract text from PDF: ${e.toString()}',
      );
    }
  }

  /// Send a message and get AI response
  Future<void> sendMessage(String message) async {
    if (!state.isVisible || _aiService == null) {
      return;
    }

    // Ensure we have extracted text
    if (state.extractedText == null && !state.isExtractingText) {
      // Need to extract text first
      final currentPath = state.currentPdfPath;
      if (currentPath != null) {
        await extractPdfText(currentPath);
      }
    }

    // Ensure we have a session
    if (_currentSessionId == null) {
      await _getOrCreateSession();
    }

    // Add user message
    final userMessage = ChatMessage.user(message);
    final updatedMessages = [...state.messages, userMessage];

    // Cache updated messages
    final pdfId = _currentPdfId ?? _currentPdf?.id;
    if (pdfId != null) {
      _addToCache(_messagesCache, pdfId, updatedMessages);
    }

    state = PdfChatState.visible(
      currentPdfPath: state.currentPdfPath,
      messages: updatedMessages,
      isLoading: true,
      extractedText: state.extractedText,
    );

    // Save user message to database
    await _saveMessage(userMessage);

    // Automatic retry: up to 4 retries with 60s delay
    const maxRetries = 4;
    const retryDelay = Duration(seconds: 60);

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          AppLogger.i('🔄 Auto-retry attempt $attempt/$maxRetries...');
          await Future.delayed(retryDelay);
          // Re-set loading state for retry
          state = PdfChatState.visible(
            currentPdfPath: state.currentPdfPath,
            messages: state.messages,
            isLoading: true,
            extractedText: state.extractedText,
          );
        }

        final textToUse = state.extractedText ?? '';
        if (textToUse.isEmpty) {
          throw Exception('No PDF content available for analysis');
        }

        final response = await _aiService!.chatWithDocument(
          textToUse,
          message,
          state.messages,
        );

        final aiMessage = ChatMessage.ai(response);
        final allMessages = [...updatedMessages, aiMessage];

        // Cache updated messages
        final pdfId = _currentPdfId ?? _currentPdf?.id;
        if (pdfId != null) {
          _addToCache(_messagesCache, pdfId, allMessages);
        }

        state = PdfChatState.visible(
          currentPdfPath: state.currentPdfPath,
          messages: allMessages,
          extractedText: state.extractedText,
        );

        // Save AI message to database
        await _saveMessage(aiMessage);

        // Update session metadata
        await _updateSessionMetadata();

        AppLogger.i('Chat message sent and response received');
        return; // Success — exit retry loop
      } catch (e, stackTrace) {
        AppLogger.e(
          'Attempt ${attempt + 1}/${maxRetries + 1} failed',
          e,
          stackTrace,
        );

        if (attempt >= maxRetries) {
          // All retries exhausted — mark as failed
          AppLogger.e('❌ All retries exhausted for message: $message');
          final failedMsg = ChatMessage.failed(message, id: userMessage.id);
          final failedMessages = [
            ...state.messages.sublist(0, state.messages.length - 1),
            failedMsg,
          ];

          state = PdfChatState.visible(
            currentPdfPath: state.currentPdfPath,
            messages: failedMessages,
            extractedText: state.extractedText,
          );
        }
      }
    }
  }

  /// Generate a quick summary of the PDF
  Future<void> generateSummary() async {
    AppLogger.i('=== generateSummary called ===');
    AppLogger.i('Current PDF path from state: ${state.currentPdfPath}');
    AppLogger.i('Has extracted text: ${state.extractedText != null}');
    AppLogger.i('Has AI Service: ${_aiService != null}');

    if (_aiService == null) {
      AppLogger.w('❌ AI Service not available');
      state = PdfChatState.visible(
        currentPdfPath: state.currentPdfPath,
        messages: state.messages,
        extractedText: state.extractedText,
        error: 'AI Service not initialized. Please try again.',
      );
      return;
    }

    final currentPath = state.currentPdfPath;
    if (currentPath == null) {
      AppLogger.w('❌ PDF not initialized');
      state = const PdfChatState.visible(
        error: 'PDF document not loaded. Please reopen the document.',
      );
      return;
    }

    // Ensure we have extracted text
    if (state.extractedText == null && !state.isExtractingText) {
      AppLogger.i('No extracted text, starting extraction...');
      await extractPdfText(currentPath);
      // Wait for extraction to complete
      AppLogger.i('Extraction finished, checking state...');
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Check again if we have text
    if (state.extractedText == null) {
      AppLogger.w('❌ Still no extracted text after extraction attempt');
      state = PdfChatState.visible(
        currentPdfPath: state.currentPdfPath,
        messages: state.messages,
        error: 'Failed to extract PDF text. Please try again.',
      );
      return;
    }

    // Add a system message showing we're generating summary
    final summaryRequestMessage = ChatMessage.user(
      'Generate a summary of this document',
    );
    final updatedMessages = [...state.messages, summaryRequestMessage];

    // Cache updated messages
    final pdfId = _currentPdfId ?? _currentPdf?.id;
    if (pdfId != null) {
      _addToCache(_messagesCache, pdfId, updatedMessages);
    }

    AppLogger.i('Setting loading state...');
    state = PdfChatState.visible(
      currentPdfPath: state.currentPdfPath,
      messages: updatedMessages,
      isLoading: true,
      extractedText: state.extractedText,
    );

    // Ensure we have a session
    if (_currentSessionId == null) {
      await _getOrCreateSession();
    }

    // Save summary request message
    await _saveMessage(summaryRequestMessage);

    try {
      final textToUse = state.extractedText ?? '';
      AppLogger.i('Text length for summary: ${textToUse.length} chars');

      if (textToUse.isEmpty) {
        AppLogger.e('Text is empty, cannot generate summary');
        throw Exception('No PDF content available for summary');
      }

      AppLogger.i('Calling AI service generateSummary...');
      final summary = await _aiService!.generateSummary(textToUse);
      AppLogger.i('✅ Summary received, length: ${summary.length} chars');

      final aiMessage = ChatMessage.ai(summary);
      final allMessages = [...updatedMessages, aiMessage];

      // Cache updated messages
      final pdfId = _currentPdfId ?? _currentPdf?.id;
      if (pdfId != null) {
        _addToCache(_messagesCache, pdfId, allMessages);
      }

      state = PdfChatState.visible(
        currentPdfPath: state.currentPdfPath,
        messages: allMessages,
        extractedText: state.extractedText,
      );

      // Save AI response
      await _saveMessage(aiMessage);
      await _updateSessionMetadata();

      AppLogger.i('✅✅✅ SUMMARY GENERATED SUCCESSFULLY! ✅✅✅');
    } catch (e, stackTrace) {
      AppLogger.e('❌ Failed to generate summary', e, stackTrace);
      state = PdfChatState.visible(
        currentPdfPath: state.currentPdfPath,
        messages: updatedMessages,
        error: 'Failed to generate summary: ${e.toString()}',
        extractedText: state.extractedText,
      );
    }
  }

  /// Extract key points from the PDF
  Future<void> extractKeyPoints() async {
    if (!state.isVisible || _aiService == null) {
      return;
    }

    // Ensure we have extracted text
    if (state.extractedText == null && !state.isExtractingText) {
      final currentPath = state.currentPdfPath;
      if (currentPath != null) {
        await extractPdfText(currentPath);
      }
    }

    final keyPointsMessage = ChatMessage.user(
      'What are the key points in this document?',
    );
    final updatedMessages = [...state.messages, keyPointsMessage];

    // Cache updated messages
    final pdfId = _currentPdfId ?? _currentPdf?.id;
    if (pdfId != null) {
      _addToCache(_messagesCache, pdfId, updatedMessages);
    }

    state = PdfChatState.visible(
      currentPdfPath: state.currentPdfPath,
      messages: updatedMessages,
      isLoading: true,
      extractedText: state.extractedText,
    );

    // Ensure we have a session
    if (_currentSessionId == null) {
      await _getOrCreateSession();
    }

    // Save key points request message
    await _saveMessage(keyPointsMessage);

    try {
      final textToUse = state.extractedText ?? '';
      if (textToUse.isEmpty) {
        throw Exception('No PDF content available');
      }

      final keyPoints = await _aiService!.extractData(
        textToUse,
        'Extract and summarize the key points from this document. Present them as a bulleted list.',
      );

      final aiMessage = ChatMessage.ai(keyPoints);
      final allMessages = [...updatedMessages, aiMessage];

      // Cache updated messages
      final pdfId = _currentPdfId ?? _currentPdf?.id;
      if (pdfId != null) {
        _addToCache(_messagesCache, pdfId, allMessages);
      }

      state = PdfChatState.visible(
        currentPdfPath: state.currentPdfPath,
        messages: allMessages,
        extractedText: state.extractedText,
      );

      // Save AI response
      await _saveMessage(aiMessage);
      await _updateSessionMetadata();

      AppLogger.i('Key points extracted successfully');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to extract key points', e, stackTrace);
      state = PdfChatState.visible(
        currentPdfPath: state.currentPdfPath,
        messages: updatedMessages,
        error: 'Failed to extract key points. Please try again.',
        extractedText: state.extractedText,
      );
    }
  }

  /// Extract custom data with a prompt
  Future<void> extractCustomData(String prompt) async {
    if (!state.isVisible || _aiService == null) {
      return;
    }

    // Ensure we have extracted text
    if (state.extractedText == null && !state.isExtractingText) {
      final currentPath = state.currentPdfPath;
      if (currentPath != null) {
        await extractPdfText(currentPath);
      }
    }

    final customMessage = ChatMessage.user(prompt);
    final updatedMessages = [...state.messages, customMessage];

    // Cache updated messages
    final pdfId = _currentPdfId ?? _currentPdf?.id;
    if (pdfId != null) {
      _addToCache(_messagesCache, pdfId, updatedMessages);
    }

    state = PdfChatState.visible(
      currentPdfPath: state.currentPdfPath,
      messages: updatedMessages,
      isLoading: true,
      extractedText: state.extractedText,
    );

    // Ensure we have a session
    if (_currentSessionId == null) {
      await _getOrCreateSession();
    }

    // Save custom data request message
    await _saveMessage(customMessage);

    try {
      final textToUse = state.extractedText ?? '';
      if (textToUse.isEmpty) {
        throw Exception('No PDF content available');
      }

      final result = await _aiService!.extractData(textToUse, prompt);

      final aiMessage = ChatMessage.ai(result);
      final allMessages = [...updatedMessages, aiMessage];

      // Cache updated messages
      final pdfId = _currentPdfId ?? _currentPdf?.id;
      if (pdfId != null) {
        _addToCache(_messagesCache, pdfId, allMessages);
      }

      state = PdfChatState.visible(
        currentPdfPath: state.currentPdfPath,
        messages: allMessages,
        extractedText: state.extractedText,
      );

      // Save AI response
      await _saveMessage(aiMessage);
      await _updateSessionMetadata();

      AppLogger.i('Custom data extracted successfully');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to extract custom data', e, stackTrace);
      state = PdfChatState.visible(
        currentPdfPath: state.currentPdfPath,
        messages: updatedMessages,
        error: 'Failed to extract data. Please try again.',
        extractedText: state.extractedText,
      );
    }
  }

  /// Clear all chat messages
  void clearChat() {
    if (!state.isVisible) return;

    state = PdfChatState.visible(currentPdfPath: state.currentPdfPath);
  }

  /// Dismiss any error message
  void dismissError() {
    if (!state.isVisible) return;

    state = PdfChatState.visible(
      currentPdfPath: state.currentPdfPath,
      messages: state.messages,
      extractedText: state.extractedText,
    );
  }

  /// Retry the last failed operation
  /// Retry a specific failed user message by its ID
  Future<void> retryMessage(String messageId) async {
    if (!state.isVisible) return;

    // Find the failed user message
    final failedIndex = state.messages.indexWhere(
      (m) => m.id == messageId && m.isFailed,
    );
    if (failedIndex == -1) return;

    final failedMessage = state.messages[failedIndex];

    // Remove all messages from the failed message onward
    final messagesToKeep = state.messages.sublist(0, failedIndex);

    state = PdfChatState.visible(
      currentPdfPath: state.currentPdfPath,
      messages: messagesToKeep,
      extractedText: state.extractedText,
    );

    // Re-send the failed message
    await sendMessage(failedMessage.content);
  }

  /// Clear cached PDF path for a specific PDF
  void clearPdfPathCache(String pdfId) {
    _pdfPathCache.remove(pdfId);
    AppLogger.i('Cleared PDF path cache for $pdfId');
  }

  /// Clear all cached PDF paths (use sparingly)
  void clearAllPdfPathCache() {
    final count = _pdfPathCache.length;
    _pdfPathCache.clear();
    AppLogger.i('Cleared all $count cached PDF paths');
  }
}

/// Extension on List<ChatMessage> to add firstOrNull
extension ChatMessageListX on List<ChatMessage> {
  ChatMessage? get firstOrNull {
    if (isEmpty) return null;
    return first;
  }
}
