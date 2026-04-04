import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/post.dart';
import '../../services/firestore_service.dart';
import '../shared/post_card.dart';

class TopicPostList extends StatelessWidget {
  final String topic;

  const TopicPostList({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return StreamBuilder<List<Post>>(
      stream: firestoreService.getPostsByTopic(topic),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading posts: ${snapshot.error}'));
        }
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return const Center(child: Text('No posts found for this topic.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: PostCard(post: post),
            );
          },
        );
      },
    );
  }
}
