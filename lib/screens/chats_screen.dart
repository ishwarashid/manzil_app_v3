import 'package:flutter/material.dart';
import 'package:manzil_app_v3/widgets/chat_list.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
      ),
      body: ChatList(),
    );

  }
}
