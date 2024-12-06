import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:manzil_app_v3/services/chat/chat_services.dart';
import 'package:manzil_app_v3/widgets/message_list.dart';
import 'package:manzil_app_v3/widgets/new_message_input.dart';

class UserChatScreen extends StatelessWidget {
  UserChatScreen({
    super.key,
    required this.currentUser,
    required this.fullName,
    required this.receiverId,
    required this.receiverNumber
  });

  final Map<String, dynamic> currentUser;
  final String fullName;
  final String receiverId;
  final String receiverNumber;
  final ChatService _chatService = ChatService();

  void _sendMessage(String enteredMessage) async {
    if (enteredMessage.trim().isNotEmpty) {
      await _chatService.sendMessage(currentUser, receiverId, enteredMessage);
    }
  }

  void _copyNumber(BuildContext context, String number) async{
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: number));
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: const Text('Phone number copied to clipboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _copyNumber(context, receiverNumber),
                    child: Text(
                      receiverNumber,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              child: MessageList(currentUser: currentUser, receiverId: receiverId),
            ),
          ),
          NewMessageInput(onSendMessage: _sendMessage),
        ],
      ),
    );
  }
}
