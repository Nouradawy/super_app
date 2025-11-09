// lib/chat/widgets/message_row_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as types;
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../MessageWidget.dart';


class MessageRowWrapper extends StatelessWidget {
  final types.Message message;
  final int index;
  final bool isSentByMe;
  final String? fileId;
  final ReactionsController reactionsController;
  final Function(types.Message) onReply;
  final Function(types.Message) onDelete;
  final Function(String) onMessageVisible;
  final types.InMemoryChatController chatController;
  final bool isPreviousMessageFromSameUser;
  final Map<String, types.User> userCache;
  final Future<void> Function(String) resolveUser; // Function to fetch user
  final List<types.Message> localMessages;

  // NEW: notify parent about visibility for sticky header computation
  final void Function(String messageId, int index, double visibleFraction, DateTime? createdAt) onVisibilityForHeader;

  const MessageRowWrapper({
    super.key,
    required this.message,
    required this.index,
    required this.isSentByMe,
    this.fileId,
    required this.reactionsController,
    required this.onReply,
    required this.onDelete,
    required this.onMessageVisible,
    required this.chatController,
    required this.isPreviousMessageFromSameUser,
    required this.userCache,
    required this.resolveUser,
    required this.onVisibilityForHeader,
    required this.localMessages,
  });

  @override
  Widget build(BuildContext context) {
    final user = userCache[message.authorId];
    // 👇 THIS IS THE CORRECTED LINE
    final userNameString = user?.name ?? '...';

    final messagesList = List<types.Message>.from(chatController.messages);
    final controllerIndex = messagesList.indexWhere((m) => m.id == message.id);

    final DateTime? createdAt = message.createdAt?.toLocal();
    final DateTime? prevCreatedAt = controllerIndex > 0
        ? messagesList[controllerIndex - 1].createdAt?.toLocal()
        : null;

    bool _isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    final bool showHeader = createdAt != null &&
        (controllerIndex <= 0 || prevCreatedAt == null || !_isSameDay(prevCreatedAt, createdAt));

     final messageContent = ChatMessageWrapper(
      messageId: message.id,
      controller: reactionsController,
      config: const ChatReactionsConfig(
        dialogPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      ),
      onMenuItemTapped: (item) {
        if (item.label == "Reply") {
          onReply(message);
        }
        if (item.isDestructive) {
          onDelete(message);
        }
      },
      child: MessageWidget(
        message: message,
        controller: reactionsController,
        messageIndex: index,
        chatController: chatController,
        userName: userNameString,
        userCache: userCache,
        isPreviousMessageFromSameUser: isPreviousMessageFromSameUser,
        isSentByMe: isSentByMe,
        fileId: fileId,
        localMessages: localMessages,
      ),
    );

    final List<Widget> messageBody = [
      messageContent,
      Avatar(userId: message.authorId)
    ];

    return VisibilityDetector(
      key: Key(message.id),
      onVisibilityChanged: (VisibilityInfo info) {
        // Inform parent about visibility for sticky header
        onVisibilityForHeader(message.id, index, info.visibleFraction, createdAt);

        // Mark as seen when sufficiently visible
        if (info.visibleFraction >= 0.8 && !isSentByMe) {
          onMessageVisible(message.id);
        }
      },
      child: Column(
        children: [
          if (showHeader && createdAt != null) ...[
            DateHeader(date: createdAt),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: isSentByMe ? messageBody : messageBody.reversed.toList(),
          ),
        ],
      ),
    );
  }
}

class DateHeader extends StatelessWidget {
  final DateTime date;
  const DateHeader({super.key, required this.date});

  String _label(DateTime d) {
    final today = DateTime.now();
    final a = DateTime(today.year, today.month, today.day);
    final b = DateTime(d.year, d.month, d.day);
    final diff = b.difference(a).inDays;
    if (diff == 0) return 'Today';
    if (diff == -1) return 'Yesterday';
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _label(date.toLocal()),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}