import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/post.dart';
import '../../services/post_service.dart';
import '../shared/post_card.dart';

class PostSearchDelegate extends SearchDelegate {
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '', // Clear search text
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null), // Close search
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchList(context);
  }

  Widget _buildSearchList(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text(
          'Enter keywords to search...',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final postService = context.read<PostService>();

    return StreamBuilder<List<Post>>(
      stream: postService.searchPosts(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data!;
        if (results.isEmpty) {
          return const Center(
            child: Text(
              'No matching posts found.',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          itemCount: results.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: PostCard(post: results[index]),
          ),
        );
      },
    );
  }
}
