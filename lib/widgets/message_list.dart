import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:manzil_app_v3/services/chat/chat_services.dart';
import 'package:manzil_app_v3/widgets/message_bubble.dart';

class MessageList extends StatelessWidget {
  MessageList({super.key, required this.currentUser, required this.receiverId});
  final Map<String, dynamic> currentUser;
  final String receiverId;
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _chatService.getMessages(currentUser['uid'], receiverId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Something went wrong!\nPlease try again later.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  "No messages yet.\nStart the conversation!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        final loadedMessages = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.only(
            bottom: 20,
            left: 13,
            right: 13,
          ),
          reverse: true,
          itemCount: loadedMessages.length,
          itemBuilder: (ctx, index) {
            final chatMessage = loadedMessages[index].data() as Map<String, dynamic>;
            final nextChatMessage = index + 1 < loadedMessages.length
                ? loadedMessages[index + 1].data() as Map<String, dynamic>
                : null;

            final currentMessageUserId = chatMessage['senderId'];
            final nextMessageUserId =
            nextChatMessage != null ? nextChatMessage['senderId'] : null;
            final nextUserIsSame = nextMessageUserId == currentMessageUserId;

            final timestamp = (chatMessage['timestamp'] as Timestamp).toDate();

            if (nextUserIsSame) {
              return MessageBubble.next(
                message: chatMessage['message'],
                isMe: currentUser['uid'] == currentMessageUserId,
                timestamp: timestamp,
              );
            } else {
              return MessageBubble.first(
                name: currentMessageUserId == currentUser['uid']
                    ? "You"
                    : chatMessage['sender_name'],
                message: chatMessage['message'],
                isMe: currentUser['uid'] == currentMessageUserId,
                timestamp: timestamp,
              );
            }
          },
        );
      },
    );
  }
}
