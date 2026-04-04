import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/comment.dart';
import '../../services/comment_service.dart';

class CommentList extends StatelessWidget {
  final String postId;

  const CommentList({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    final commentService = context.read<CommentService>();

    return StreamBuilder<List<Comment>>(
      stream: commentService.getComments(postId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final comments = snapshot.data!;
        if (comments.isEmpty) {
          return const Text('No comments yet.');
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final c = comments[index];
            final bool isAdminComment = c.authorRole == 'admin';

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor:
                    isAdminComment ? Colors.blue[50] : Colors.grey[100],
                child: Icon(
                  isAdminComment ? Icons.admin_panel_settings : Icons.person,
                  size: 20,
                ),
              ),
              title: Text(
                c.authorName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              subtitle: Text(c.text),
            );
          },
        );
      },
    );
  }
}
