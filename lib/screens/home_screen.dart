import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../services/firestore_service.dart';
// import 'post_detail_screen.dart';
import 'admin_dashboard_screen.dart';
import '../services/auth_service.dart';
import '../widgets/post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _topics = [
    'All',
    'General',
    'Academics',
    'Sports',
    'Events',
    'Tech',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _topics.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SUC Forum - Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: PostSearchDelegate());
            },
          ),
          if (authService.isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _topics.map((topic) => Tab(text: topic)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _topics.map((topic) => _PostList(topic: topic)).toList(),
      ),
    );
  }
}

class _PostList extends StatelessWidget {
  final String topic;

  const _PostList({required this.topic});

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
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return PostCard(post: post);
          },
        );
      },
    );
  }
}

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
      return const Center(child: Text('Enter keywords to search...'));
    }

    final firestoreService = context.read<FirestoreService>();

    return StreamBuilder<List<Post>>(
      stream: firestoreService.searchPosts(query),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data!;
        if (results.isEmpty) {
          return const Center(child: Text('No matching posts found.'));
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) => PostCard(post: results[index]),
        );
      },
    );
  }
}
