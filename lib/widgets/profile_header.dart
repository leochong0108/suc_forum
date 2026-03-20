import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class ProfileHeader extends StatelessWidget {
  final AuthService authService;

  const ProfileHeader({
    super.key,
    required this.authService,
  });

  void _showEditNameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Name"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "New Display Name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                // Update Firebase Auth display name and 'users' collection
                await authService.updateUserName(newName);

                // Update 'posts' and 'comments' where this user is the author
                if (context.mounted) {
                  await context
                      .read<FirestoreService>()
                      .updateUserName(authService.user!.uid, newName);
                }

                if (context.mounted) Navigator.pop(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Name updated successfully!")),
                  );
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.user!;
    final name = user.isAnonymous
        ? "Anonymous User #${user.uid.substring(0, 5)}"
        : (user.displayName ?? user.email ?? "Unknown User");

    return Container(
      padding: const EdgeInsets.all(24.0),
      width: double.infinity,
      color: Theme.of(context).primaryColor.withAlpha(25),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            child: Icon(
              user.isAnonymous ? Icons.person_outline : Icons.person,
              size: 40,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(name, style: Theme.of(context).textTheme.headlineSmall),
              if (!user.isAnonymous)
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showEditNameDialog(context, name),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(user.isAnonymous ? "Anonymous Mode" : "Real-Name Mode"),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => authService.signOut(),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
