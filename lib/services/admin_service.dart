import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_service.dart';
import 'notification_service.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getReportsStream() {
    return _db
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> rejectReport(String reportId) async {
    await _db.collection('reports').doc(reportId).delete();
  }

  Future<void> deletePostAndReport({
    required PostService postService,
    required NotificationService notificationService,
    required String reportId,
    required String postId,
    required Map<String, dynamic>? postData,
    required String? adminId,
  }) async {
    // 1. Notify the author (if possible)
    if (postData != null && postData['authorId'] != null) {
      final title = postData['title'] ?? 'your post';
      await notificationService.sendNotification(
        userId: postData['authorId'],
        message: 'Admin has removed your post "$title" due to a user report.',
      );
    }

    // 2. Centralized cleanup: deletes post, comments, and all user favorites (via collection group)
    await postService.deletePost(postId);

    // 3. Explicitly delete from current admin favorites (fallback)
    if (adminId != null) {
      await _db
          .collection('users')
          .doc(adminId)
          .collection('favorites')
          .doc(postId)
          .delete();
    }

    // 4. Delete the report document
    await _db.collection('reports').doc(reportId).delete();
  }
}
