import 'package:flutter/material.dart';

class CommentInput extends StatefulWidget {
  final void Function(String) onSend;

  const CommentInput({super.key, required this.onSend});

  @override
  State<CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final _commentController = TextEditingController();

  void _handleSend() {
    final text = _commentController.text.trim();
    if (text.isNotEmpty) {
      widget.onSend(text);
      _commentController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _handleSend,
          ),
        ],
      ),
    );
  }
}
