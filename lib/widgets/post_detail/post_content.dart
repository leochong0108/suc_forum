import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/post.dart';
import '../../utils/date_formatter.dart';

class PostContent extends StatelessWidget {
  final Post post;
  final bool isLiked;
  final VoidCallback onToggleLike;

  const PostContent({
    super.key,
    required this.post,
    required this.isLiked,
    required this.onToggleLike,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          post.title,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.person, size: 16),
            const SizedBox(width: 4),
            Text(post.authorName),
            const Spacer(),
            Text(DateFormatter.formatFull(post.createdAt)),
          ],
        ),
        const Divider(height: 32),
        if (post.imageUrl != null) ...[
          post.imageUrl!.startsWith('http')
              ? Image.network(post.imageUrl!)
              : Image.memory(base64Decode(post.imageUrl!)),
          const SizedBox(height: 16),
        ],
        Text(post.text, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 24),
        Row(
          children: [
            IconButton(
              icon: Icon(
                isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
              ),
              color: isLiked ? Colors.blue : null,
              onPressed: onToggleLike,
            ),
            Text('${post.likesCount + (isLiked ? 1 : 0)} Likes'),
          ],
        ),
      ],
    );
  }
}
