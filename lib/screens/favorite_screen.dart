import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../widgets/post_card.dart'; // Import the same shared UI

class CollectionsScreen extends StatelessWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final firestoreService = context.read<FirestoreService>();
    final userId = authService.user?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('My Collections')),
      body: userId == null
          ? const Center(child: Text('Please log in to see collections'))
          : StreamBuilder<List<Post>>(
              stream: firestoreService.getFavoritePosts(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final posts = snapshot.data ?? [];
                if (posts.isEmpty) {
                  return const Center(child: Text('No saved posts yet.'));
                }

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    // REUSE THE SAME UI HERE
                    return PostCard(post: posts[index]);
                  },
                );
              },
            ),
    );
  }
}