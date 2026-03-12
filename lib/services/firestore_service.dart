import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';
import '../models/comment.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fetch approved posts by topic.
  Stream<List<Post>> getPostsByTopic(String topic) {
    Query query = _db
        .collection('posts')
        .where('status', isEqualTo: 'approved');
    if (topic != 'All') {
      query = query.where('topic', isEqualTo: topic);
    }
    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList(),
        );
  }

  Future<void> createPost(Post post) async {
    await _db.collection('posts').add(post.toMap());
  }

  Stream<List<Post>> getPostsByAuthor(String authorId) {
    return _db
        .collection('posts')
        .where('authorId', isEqualTo: authorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList(),
        );
  }

  Future<void> updatePost(
    String postId,
    String title,
    String text,
    String? imageUrl,
  ) async {
    final Map<String, dynamic> data = {'title': title, 'text': text};
    if (imageUrl != null) {
      data['imageUrl'] = imageUrl;
    }
    await _db.collection('posts').doc(postId).update(data);
  }

  Future<void> deletePost(String postId) async {
    // Note: To be totally clean, one might also delete the subcollections
    // (comments) but keeping it simple.
    await _db.collection('posts').doc(postId).delete();
  }

  Future<void> updateLike(String postId, {required bool increment}) async {
    await _db.collection('posts').doc(postId).update({
      'likesCount': FieldValue.increment(increment ? 1 : -1),
    });
  }

  // Comments
  Stream<List<Comment>> getComments(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Comment.fromFirestore(doc)).toList(),
        );
  }

  Future<void> addComment(String postId, Comment comment) async {
    final batch = _db.batch();

    final postRef = _db.collection('posts').doc(postId);
    final commentRef = postRef.collection('comments').doc();

    batch.set(commentRef, comment.toMap());
    batch.update(postRef, {'commentsCount': FieldValue.increment(1)});

    await batch.commit();
  }

  // Reports
  Future<void> reportPost(
    String postId,
    String reporterId,
    String reason,
  ) async {
    await _db.collection('reports').add({
      'postId': postId,
      'reporterId': reporterId,
      'reason': reason,
      'status': 'open',
      'createdAt': Timestamp.now(),
    });
  }

  // Notifications
  Future<void> sendNotification({
    required String userId,
    required String message,
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'message': message,
      // FieldValue.serverTimestamp() will hang forever offline. Use local Timestamp.
      'createdAt': Timestamp.now(),
      'isRead': false,
    });
  }

  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }
}
