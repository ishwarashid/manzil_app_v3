import 'package:flutter/material.dart';

class NewMessageInput extends StatefulWidget {
  const NewMessageInput({super.key, required this.onSendMessage});
  final void Function(String) onSendMessage;

  @override
  State<NewMessageInput> createState() => _NewMessageInputState();
}

class _NewMessageInputState extends State<NewMessageInput> {
  final _messageController = TextEditingController();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _canSend = _messageController.text.trim().isNotEmpty;
    _messageController.addListener(() {
      final isNotEmpty = _messageController.text.trim().isNotEmpty;
      if (isNotEmpty != _canSend) {
        setState(() {
          _canSend = isNotEmpty;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      widget.onSendMessage(message);
      _messageController.clear();
      setState(() {
        _canSend = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      autocorrect: true,
                      enableSuggestions: true,
                      maxLines: null,
                      onChanged: (text) {
                        setState(() {
                          _canSend = text.trim().isNotEmpty;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Message',
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (value) {
                        if (_canSend) {
                          _handleSubmit();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _canSend ? _handleSubmit : null,
            child: Container(
              height: 46,
              width: 46,
              decoration: BoxDecoration(
                color: _canSend
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.withOpacity(0.3),
                shape: BoxShape.circle,
                boxShadow: _canSend
                    ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 5.0),
                child: Icon(
                  Icons.send_rounded,
                  color: _canSend ? Colors.white : Colors.grey[400],
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
