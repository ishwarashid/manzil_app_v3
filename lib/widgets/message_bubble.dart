import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble.first({
    super.key,
    required this.name,
    required this.message,
    required this.isMe,
    required this.timestamp,
  }) : isFirstInSequence = true, userImage = " ";

  const MessageBubble.next({
    super.key,
    required this.message,
    required this.isMe,
    required this.timestamp,
  })  : isFirstInSequence = false,
        name = null,
        userImage = null;

  final bool isFirstInSequence;
  final String? userImage;
  final String? name;
  final String message;
  final DateTime timestamp;
  final bool isMe;

  String _formatTime() {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        if (userImage != null)
          Positioned(
            top: 15,
            right: isMe ? 0 : null,
            child: CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withOpacity(0.8),
              radius: 14,
              child: const Icon(
                Icons.person,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (isFirstInSequence) const SizedBox(height: 18),
                  if (name != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 13, right: 13),
                      child: Text(
                        name!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      color: isMe
                          ? theme.colorScheme.primary.withOpacity(0.9)
                          : theme.colorScheme.secondary.withOpacity(0.9),
                      borderRadius: BorderRadius.only(
                        topLeft: !isMe && isFirstInSequence
                            ? Radius.zero
                            : const Radius.circular(16),
                        topRight: isMe && isFirstInSequence
                            ? Radius.zero
                            : const Radius.circular(16),
                        bottomLeft: const Radius.circular(16),
                        bottomRight: const Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxWidth: 250),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 14,
                    ),
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 12,
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 34),
                          child: Text(
                            message,
                            style: TextStyle(
                              height: 1.3,
                              color: isMe ? Colors.white : Colors.white,
                            ),
                            softWrap: true,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Text(
                            _formatTime(),
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}