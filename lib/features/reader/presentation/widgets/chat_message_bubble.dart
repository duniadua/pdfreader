import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

import '../providers/pdf_chat_state.dart';
import '../../../../core/theme/app_theme.dart';

/// Widget displaying a single chat message bubble.
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onCopy,
  });

  final ChatMessage message;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Message row
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                _buildAvatar(context),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Message bubble
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: _getBubbleColor(context),
                        borderRadius: _getBorderRadius(isUser),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: isUser
                          ? _buildUserMessage(context)
                          : _buildAiMessage(context),
                    ),
                    // Copy button for non-empty messages
                    if (message.content.isNotEmpty && !message.isProcessing)
                      _buildCopyButton(context),
                  ],
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                _buildAvatar(context),
              ],
            ],
          ),
          // Timestamp
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the avatar icon
  Widget _buildAvatar(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: message.isUser
            ? AppTheme.primary.withValues(alpha: 0.1)
            : Colors.amber.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        message.isUser ? Icons.person : Icons.auto_awesome,
        size: 18,
        color: message.isUser ? AppTheme.primary : Colors.amber,
      ),
    );
  }

  /// Build user message text
  Widget _buildUserMessage(BuildContext context) {
    return Text(
      message.content,
      style: TextStyle(
        fontSize: 14,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  /// Build AI message with markdown rendering
  Widget _buildAiMessage(BuildContext context) {
    if (message.isProcessing) {
      return const _TypingIndicator();
    }

    return MarkdownBody(
      data: message.content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(
          fontSize: 14,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        h1: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        h2: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        h3: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        code: TextStyle(
          backgroundColor: Colors.grey.withValues(alpha: 0.2),
          fontFamily: 'monospace',
          fontSize: 13,
        ),
        blockquote: TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  /// Build copy button
  Widget _buildCopyButton(BuildContext context) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: message.content));
        onCopy?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied to clipboard'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.copy,
              size: 12,
              color: Colors.grey.shade500,
            ),
            const SizedBox(width: 4),
            Text(
              'Copy',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get bubble background color
  Color _getBubbleColor(BuildContext context) {
    if (message.isUser) {
      return AppTheme.primary.withValues(alpha: 0.1);
    }
    return Theme.of(context).colorScheme.surface;
  }

  /// Get border radius based on sender
  BorderRadius _getBorderRadius(bool isUser) {
    return BorderRadius.only(
      topLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
      topRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
      bottomLeft: const Radius.circular(16),
      bottomRight: const Radius.circular(16),
    );
  }

  /// Format timestamp for display
  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, HH:mm').format(timestamp);
    }
  }
}

/// Typing indicator for AI responses
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Dot(delay: 0),
        const SizedBox(width: 8),
        _Dot(delay: 150),
        const SizedBox(width: 8),
        _Dot(delay: 300),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.delay});

  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
