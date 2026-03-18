import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/post.dart';
import '../services/firestore_service.dart';
import 'post_detail_screen.dart';
import 'admin_dashboard_screen.dart';
import '../services/auth_service.dart';

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
            return _PostCard(post: post);
          },
        );
      },
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      elevation: 1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(post: post),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: User Info & Topic
              Row(
                children: [
                  CircleAvatar(radius: 20, child: const Icon(Icons.person)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              post.topic,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '•  ${post.createdAt.toLocal().toString().split('.')[0]}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Post Title
              if (post.title.isNotEmpty)
                Text(
                  post.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              const SizedBox(height: 4),

              // Post Text
              if (post.text.isNotEmpty)
                Text(
                  post.text,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              const SizedBox(height: 12),

              // Post Image (Full Width)
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: post.imageUrl!.startsWith('http')
                        ? Image.network(post.imageUrl!, fit: BoxFit.cover)
                        : Image.memory(
                            base64Decode(post.imageUrl!),
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Footer: Likes
              Divider(height: 1, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.thumb_up_alt_outlined,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${post.likesCount}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.comment_outlined,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${post.commentsCount} Replies',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
