import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'admin_dashboard_screen.dart';
import '../services/auth_service.dart';
import '../widgets/home/topic_post_list.dart';
import '../widgets/home/post_search_delegate.dart';
import '../widgets/home/forum_tab_bar.dart';
import '../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _topics = AppConstants.homeTopics;

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
        title: const Text(
          'SUC Forum - Home',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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
        bottom: ForumTabBar(
          tabController: _tabController,
          topics: _topics,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _topics.map((topic) => TopicPostList(topic: topic)).toList(),
      ),
    );
  }
}

