import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/post.dart';

class YouScreen extends StatefulWidget {
  const YouScreen({super.key});

  @override
  State<YouScreen> createState() => _YouScreenState();
}

class _YouScreenState extends State<YouScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(title: const Text('You')),
      body: authService.isAuthenticated
          ? _buildProfile(authService)
          : _buildAuthForm(authService),
    );
  }

  Widget _buildProfile(AuthService authService) {
    final user = authService.user!;
    final name = user.isAnonymous
        ? "Anonymous User #${user.uid.substring(0, 5)}"
        : (user.displayName ?? user.email ?? "Unknown User");

    return Column(
      children: [
        // Profile Header
        Container(
          padding: const EdgeInsets.all(24.0),
          width: double.infinity,
          color: Theme.of(context).primaryColor.withOpacity(0.1),
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
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showEditNameDialog(authService, name),
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
        ),
        const Divider(height: 1),

        // List of User's Posts
        Expanded(child: _buildUserPosts(user.uid)),
      ],
    );
  }

  Widget _buildUserPosts(String uid) {
    final firestoreService = context.watch<FirestoreService>();

    return StreamBuilder<List<Post>>(
      stream: firestoreService.getPostsByAuthor(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final posts = snapshot.data ?? [];
        if (posts.isEmpty) {
          return const Center(
            child: Text("You haven't created any posts yet."),
          );
        }

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: SizedBox(
                  width: 50,
                  height: 50,
                  child: post.imageUrl != null && post.imageUrl!.isNotEmpty
                      ? (post.imageUrl!.startsWith('http')
                            ? Image.network(post.imageUrl!, fit: BoxFit.cover)
                            : Image.memory(
                                base64Decode(post.imageUrl!),
                                fit: BoxFit.cover,
                              ))
                      : const Icon(Icons.image, color: Colors.grey),
                ),
                title: Text(
                  post.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  post.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editPost(post),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeletePost(post),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditNameDialog(AuthService authService, String currentName) {
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
                if (mounted) {
                  await context
                      .read<FirestoreService>()
                      .updateUserName(authService.user!.uid, newName);
                }

                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Name updated successfully!")),
                );
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _editPost(Post post) {
    final titleController = TextEditingController(text: post.title);
    final textController = TextEditingController(text: post.text);
    XFile? newPickedImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Post'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: textController,
                      decoration: const InputDecoration(labelText: 'Content'),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    if (newPickedImage != null)
                      const Text(
                        "New Image Selected",
                        style: TextStyle(color: Colors.green),
                      )
                    else if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                      const Text(
                        "Current Image Attached",
                        style: TextStyle(color: Colors.grey),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text('Change Image'),
                      onPressed: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 50,
                          maxWidth: 800,
                          maxHeight: 800,
                        );
                        if (pickedFile != null) {
                          setDialogState(() {
                            newPickedImage = pickedFile;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newTitle = titleController.text.trim();
                    final newText = textController.text.trim();
                    if (newTitle.isNotEmpty && newText.isNotEmpty) {
                      Navigator.pop(context); // close dialog

                      String? newImageBase64;
                      if (newPickedImage != null) {
                        try {
                          final bytes = await newPickedImage!.readAsBytes();
                          if (bytes.length > 700000) {
                            _showError(
                              "Image is too large. Please select a smaller photo.",
                            );
                            return;
                          }
                          newImageBase64 = base64Encode(bytes);
                        } catch (e) {
                          _showError("Failed to process new image: $e");
                          return;
                        }
                      }

                      try {
                        // Fire and forget without await for offline prototype
                        context.read<FirestoreService>().updatePost(
                          post.id,
                          newTitle,
                          newText,
                          newImageBase64,
                        );
                        _showError("Post updated successfully!");
                      } catch (e) {
                        _showError("Failed to update post: $e");
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeletePost(Post post) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const Text(
            'Are you sure you want to delete this post? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                try {
                  // Fire and forget without await
                  context.read<FirestoreService>().deletePost(post.id);
                  _showError("Post deleted successfully.");
                } catch (e) {
                  _showError("Failed to delete post: $e");
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAuthForm(AuthService authService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isLogin ? 'Welcome Back' : 'Create an Account',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          if (!_isLogin)
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
          if (!_isLogin) const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              try {
                if (_isLogin) {
                  await authService.signInWithEmailPassword(
                    _emailController.text,
                    _passwordController.text,
                  );
                } else {
                  await authService.registerWithEmailPassword(
                    _emailController.text,
                    _passwordController.text,
                    _nameController.text,
                  );
                }
              } catch (e) {
                _showError(e.toString());
              }
            },
            child: Text(_isLogin ? 'Sign In' : 'Register'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _isLogin = !_isLogin;
              });
            },
            child: Text(
              _isLogin
                  ? 'Need an account? Register'
                  : 'Have an account? Sign in',
            ),
          ),
          const Divider(height: 48),
          OutlinedButton(
            onPressed: () async {
              try {
                await authService.signInAnonymously();
              } catch (e) {
                _showError(e.toString());
              }
            },
            child: const Text('Continue Anonymously'),
          ),
        ],
      ),
    );
  }
}
