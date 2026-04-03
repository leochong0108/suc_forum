import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/auth_form.dart';
import '../widgets/profile_header.dart';
import '../widgets/user_posts_list.dart';
import 'favorite_screen.dart';

class YouScreen extends StatelessWidget {
  const YouScreen({super.key});

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('You', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (authService.isAuthenticated)
            IconButton(
              tooltip: 'My Collections',
              icon: const Icon(Icons.bookmarks_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CollectionsScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      body: authService.isAuthenticated
          ? _buildProfile(context, authService)
          : AuthForm(
              authService: authService,
              onError: (msg) => _showError(context, msg),
            ),
    );
  }

  Widget _buildProfile(BuildContext context, AuthService authService) {
    final user = authService.user!;

    return Column(
      children: [
        ProfileHeader(authService: authService),
        const Divider(height: 1),
        // List of User's Posts
        Expanded(child: UserPostsList(uid: user.uid)),
      ],
    );
  }
}
