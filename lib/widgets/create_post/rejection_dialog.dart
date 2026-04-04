import 'package:flutter/material.dart';

class RejectionDialog extends StatelessWidget {
  final String reason;

  const RejectionDialog({super.key, required this.reason});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Post Flagged (3R/Safety)',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ),
      content: Text(
        'Your post violates community guidelines.\n\nReason: $reason',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Understand'),
        ),
      ],
    );
  }
}
