import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/pdf_chat_state.dart';
import '../providers/pdf_chat_notifier.dart';
import 'chat_message_bubble.dart';

/// Draggable bottom sheet panel for AI chat with PDF.
class PdfChatPanel extends ConsumerStatefulWidget {
  const PdfChatPanel({
    super.key,
    required this.pdfId,
    required this.pdfPath,
    required this.pdfTitle,
  });

  final String pdfId;
  final String pdfPath;
  final String pdfTitle;

  @override
  ConsumerState<PdfChatPanel> createState() => _PdfChatPanelState();
}

class _PdfChatPanelState extends ConsumerState<PdfChatPanel> {
  late final TextEditingController _textController;
  late final ScrollController _scrollController;
  bool _isScrolledToTop = true;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScrollChanged);
    // Note: Text extraction is now triggered on-demand when user taps Quick Actions
    // This avoids race conditions with provider state initialization
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController
      ..removeListener(_onScrollChanged)
      ..dispose();
    super.dispose();
  }

  void _onScrollChanged() {
    final scrolledToTop =
        _scrollController.position.minScrollExtent >=
        _scrollController.offset - 10;
    if (_isScrolledToTop != scrolledToTop) {
      setState(() => _isScrolledToTop = scrolledToTop);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(pdfChatNotifierProvider(widget.pdfId));

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context, chatState),
          _buildQuickActions(context, chatState),
          if (chatState.isExtractingText)
            _buildExtractionProgress(context, chatState),
          Expanded(child: _buildMessagesList(context, chatState)),
          _buildInputArea(context, chatState),
        ],
      ),
    );
  }

  /// Build panel header with title and close button
  Widget _buildHeader(BuildContext context, PdfChatState chatState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'AI Assistant',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.pdfTitle,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (chatState.messages.isNotEmpty && !chatState.isLoading)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () {
                ref
                    .read(pdfChatNotifierProvider(widget.pdfId).notifier)
                    .clearChat();
              },
              tooltip: 'Clear chat',
              visualDensity: VisualDensity.compact,
            ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              ref
                  .read(pdfChatNotifierProvider(widget.pdfId).notifier)
                  .closePanel();
              Navigator.of(context).pop();
            },
            tooltip: 'Close',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  /// Build quick action buttons
  Widget _buildQuickActions(BuildContext context, PdfChatState chatState) {
    final isProcessing = chatState.isLoading || chatState.isExtractingText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _QuickActionChip(
            icon: Icons.summarize,
            label: 'Summary',
            isProcessing: isProcessing,
            onTap: () {
              ref
                  .read(pdfChatNotifierProvider(widget.pdfId).notifier)
                  .generateSummary();
            },
          ),
          _QuickActionChip(
            icon: Icons.format_list_bulleted,
            label: 'Key Points',
            isProcessing: isProcessing,
            onTap: () {
              ref
                  .read(pdfChatNotifierProvider(widget.pdfId).notifier)
                  .extractKeyPoints();
            },
          ),
        ],
      ),
    );
  }

  /// Build text extraction progress indicator
  Widget _buildExtractionProgress(
    BuildContext context,
    PdfChatState chatState,
  ) {
    final progress = chatState.maybeWhen(
      visible: (_, _1, _2, extractProgress, _3, _4, _5, _6) =>
          extractProgress ?? 0.0,
      orElse: () => 0.0,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: progress,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Extracting text from PDF... ${(progress * 100).round()}%',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ],
      ),
    );
  }

  /// Build messages list
  Widget _buildMessagesList(BuildContext context, PdfChatState chatState) {
    final messages = chatState.messages;
    final error = chatState.error;

    // Show error message if present
    if (error != null && error.isNotEmpty) {
      return _buildErrorView(context, error, () {
        ref.read(pdfChatNotifierProvider(widget.pdfId).notifier).dismissError();
      });
    }

    if (messages.isEmpty &&
        !chatState.isLoading &&
        !chatState.isExtractingText) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8, top: 8),
      itemCount: messages.length + (chatState.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < messages.length) {
          return ChatMessageBubble(
            key: ValueKey(messages[index].id),
            message: messages[index],
            onRetry: messages[index].isUser && messages[index].isFailed
                ? () => ref
                      .read(pdfChatNotifierProvider(widget.pdfId).notifier)
                      .retryMessage(messages[index].id)
                : null,
          );
        } else {
          // Show loading indicator at the end
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text(
                  'AI is thinking...',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  /// Build error view when chat fails
  Widget _buildErrorView(
    BuildContext context,
    String error,
    VoidCallback onDismiss,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Failed to get response',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Dismiss'),
                  onPressed: onDismiss,
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                  onPressed: () {
                    // Find the last failed user message to retry
                    final notifier = ref.read(
                      pdfChatNotifierProvider(widget.pdfId).notifier,
                    );
                    final failedMsg = ref
                        .read(pdfChatNotifierProvider(widget.pdfId))
                        .messages
                        .lastWhere(
                          (m) => m.isFailed,
                          orElse: () => ChatMessage.user(''),
                        );
                    if (failedMsg.content.isNotEmpty) {
                      notifier.retryMessage(failedMsg.id);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state when no messages
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 32,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ask anything about this PDF',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Try quick actions above or type your own question',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build input area with text field and send button
  Widget _buildInputArea(BuildContext context, PdfChatState chatState) {
    final isProcessing = chatState.isLoading || chatState.isExtractingText;
    // Get keyboard height to push input area above keyboard
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: 12 + keyboardHeight, // Add keyboard height to bottom padding
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                enabled: !isProcessing,
                decoration: InputDecoration(
                  hintText: 'Ask a question about this PDF...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: isProcessing ? null : (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: isProcessing ? Colors.grey.shade300 : AppTheme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: isProcessing ? null : _sendMessage,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.send, size: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Send user message
  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    ref.read(pdfChatNotifierProvider(widget.pdfId).notifier).sendMessage(text);

    // Scroll to bottom after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

/// Quick action chip widget
class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isProcessing = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isProcessing ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isProcessing
                ? Colors.grey.shade100
                : AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isProcessing
                  ? Colors.transparent
                  : AppTheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isProcessing ? Colors.grey.shade400 : AppTheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isProcessing ? Colors.grey.shade400 : AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
