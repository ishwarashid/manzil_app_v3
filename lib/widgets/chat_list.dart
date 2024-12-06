import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manzil_app_v3/providers/current_user_provider.dart';

import 'package:manzil_app_v3/services/chat/chat_services.dart';
import 'package:manzil_app_v3/widgets/chat_list_item.dart';

class ChatList extends ConsumerWidget {
  ChatList({super.key});

  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    return StreamBuilder(
      stream: _chatService.getUsersStream(currentUser),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text("Something went wrong! Please try gain later."),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  "No chats yet",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Your conversations will appear here",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }
        print(snapshot.data);

        return ListView(
          children: snapshot.data!
              .map<Widget>((userData) => ChatListItem(userData: userData))
              .toList(),
        );
      },
    );
  }
}
