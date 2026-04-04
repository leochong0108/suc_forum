import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../services/notification_service.dart';

class AdminReportCard extends StatelessWidget {
  final DocumentSnapshot reportDoc;

  const AdminReportCard({super.key, required this.reportDoc});

  @override
  Widget build(BuildContext context) {
    final data = reportDoc.data() as Map<String, dynamic>;
    final postId = data['postId'] ?? 'Unknown';
    final reason = data['reason'] ?? 'No reason provided';
    final reporterId = data['reporterId'] ?? 'Unknown';
    final adminService = context.read<AdminService>();
    final authService = context.read<AuthService>();
    final postService = context.read<PostService>();
    final notificationService = context.read<NotificationService>();

    return FutureBuilder<DocumentSnapshot>(
      future: postService.getPostById(postId),
      builder: (context, postSnapshot) {
        String postTitle = 'Loading...';
        String postContent = '...';
        String? postImageBase64;
        Map<String, dynamic>? postData;

        if (postSnapshot.connectionState == ConnectionState.done &&
            postSnapshot.hasData) {
          postData = postSnapshot.data!.data() as Map<String, dynamic>?;

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
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📌 Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: postImageBase64 != null &&
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
                            : Container(
                                color: Colors.orange.shade100,
                                child: const Icon(
                                  Icons.warning,
                                  color: Colors.orange,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // 📌 Text Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            postTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            postContent,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(height: 6),

                          // 📌 Reason Tag
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Reason: $reason',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Reporter: $reporterId',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // 📌 Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 🔘 Reject Button
                    TextButton.icon(
                      onPressed: () async {
                        await adminService.rejectReport(reportDoc.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Report rejected. No action taken on post.',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                      ),
                    ),

                    const SizedBox(width: 8),

                    // 🔴 Delete Button
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await adminService.deletePostAndReport(
                            postService: postService,
                            notificationService: notificationService,
                            reportId: reportDoc.id,
                            postId: postId,
                            postData: postData,
                            adminId: authService.user?.uid,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Post & Report deleted successfully.',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to remove post: $e',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
