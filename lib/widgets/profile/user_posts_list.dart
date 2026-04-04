import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import '../../models/post.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class UserPostsList extends StatelessWidget {
  final String uid;

  const UserPostsList({
    super.key,
    required this.uid,
  });

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _editPost(BuildContext context, Post post) {
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
                            if (context.mounted) {
                              _showError(context, "Image is too large. Please select a smaller photo.");
                            }
                            return;
                          }
                          newImageBase64 = base64Encode(bytes);
                        } catch (e) {
                          if (context.mounted) {
                            _showError(context, "Failed to process new image: $e");
                          }
                          return;
                        }
                      }

                      try {
                        if (context.mounted) {
                          context.read<FirestoreService>().updatePost(
                            post.id,
                            newTitle,
                            newText,
                            newImageBase64,
                          );
                          _showError(context, "Post updated successfully!");
                        }
                      } catch (e) {
                        if (context.mounted) {
                          _showError(context, "Failed to update post: $e");
                        }
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

  void _confirmDeletePost(BuildContext context, Post post) {
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
                  context.read<FirestoreService>().deletePost(post.id);
                  _showError(context, "Post deleted successfully.");
                } catch (e) {
                  _showError(context, "Failed to delete post: $e");
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

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.watch<FirestoreService>();
    final authService = context.read<AuthService>();

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
                    if (!authService.isAnonymous)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editPost(context, post),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDeletePost(context, post),
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
}
