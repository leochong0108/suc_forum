import 'package:flutter/material.dart';

class PostContentFields extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController textController;

  const PostContentFields({
    super.key,
    required this.titleController,
    required this.textController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: titleController,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          decoration: const InputDecoration(
            hintText: 'Post Title',
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const Divider(height: 20),
        TextField(
          controller: textController,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: "What do you want to share with SUC?",
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
