import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manzil_app_v3/providers/current_user_provider.dart';
import 'package:manzil_app_v3/screens/user_chat_screen.dart';

class ChatListItem extends ConsumerStatefulWidget {
  const ChatListItem({super.key, required this.userData});

  final Map<String, dynamic> userData;

  @override
  ConsumerState<ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends ConsumerState<ChatListItem> {
  String _getInitials(String fullName) {
    final names = fullName.split(' ');
    
    // print(names);
    if (names.length >= 2) {
      // print(names[2][0]);
      return '${names[0][0]}${names[1][0]}'.toUpperCase();

    }
    return names[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    if (widget.userData["id"] != currentUser['uid']) {
      final fullName = "${widget.userData["first_name"]} ${widget.userData["last_name"]}";
      final initials = _getInitials(fullName);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserChatScreen(
                  currentUser: currentUser,
                  fullName: fullName,
                  receiverId: widget.userData["id"],
                  receiverNumber: widget.userData["phone_number"]
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [

                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withBlue(
                          Theme.of(context).colorScheme.primary.blue + 20,
                        ),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          color: Color.fromARGB(255, 45, 45, 45),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to chat',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container();
  }
}
