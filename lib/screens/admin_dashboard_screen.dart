import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../services/firestore_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard - Reports')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading reports: ${snapshot.error}'),
            );
          }

          final reports = snapshot.data?.docs ?? [];
          if (reports.isEmpty) {
            return const Center(child: Text('No reports found. All good!'));
          }

          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final doc = reports[index];
              final data = doc.data() as Map<String, dynamic>;
              final postId = data['postId'] ?? 'Unknown';
              final reason = data['reason'] ?? 'No reason provided';
              final reporterId = data['reporterId'] ?? 'Unknown';

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('posts')
                    .doc(postId)
                    .get(),
                builder: (context, postSnapshot) {
                  String postTitle = 'Loading...';
                  String postContent = '...';
                  String? postImageBase64;
                  Map<String, dynamic>? postData;

                  if (postSnapshot.connectionState == ConnectionState.done &&
                      postSnapshot.hasData) {
                    postData =
                        postSnapshot.data!.data() as Map<String, dynamic>?;
                    if (postData != null) {
                      postTitle = postData['title'] ?? 'No Title';
                      postContent = postData['text'] ?? 'No Content';
                      postImageBase64 = postData['imageUrl'];
                    } else {
                      postTitle = 'Post Deleted/NotFound';
                      postContent = '';
                    }
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: SizedBox(
                        width: 50,
                        height: 50,
                        child:
                            postImageBase64 != null &&
                                postImageBase64.isNotEmpty
                            ? (postImageBase64.startsWith('http')
                                  ? Image.network(
                                      postImageBase64,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.memory(
                                      base64Decode(postImageBase64),
                                      fit: BoxFit.cover,
                                    ))
                            : const Icon(Icons.warning, color: Colors.orange),
                      ),
                      title: Text('Reason: $reason\nPost: $postTitle'),
                      subtitle: Text(
                        'Content: $postContent\nReporter: $reporterId',
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // Send a notification before deleting if we know the author
                          if (postData != null &&
                              postData['authorId'] != null) {
                            final title = postData['title'] ?? 'your post';
                            // We don't await this because if there is no server connection,
                            // it will hang forever. The local cache handles it instantly.
                            context.read<FirestoreService>().sendNotification(
                              userId: postData['authorId'],
                              message:
                                  'Admin has removed your post "$title" due to a user report.',
                            );
                          }

                          // Delete the post and the report itself locally without awaiting
                          FirebaseFirestore.instance
                              .collection('posts')
                              .doc(postId)
                              .delete();
                          FirebaseFirestore.instance
                              .collection('reports')
                              .doc(doc.id)
                              .delete();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Post & Report deleted, User notified (Offline mode active).',
                                ),
                              ),
                            );
                          }
                        },
                        tooltip: 'Delete Post & Report',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
