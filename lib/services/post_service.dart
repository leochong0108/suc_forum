import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';

class PostService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<DocumentSnapshot> getPostById(String postId) {
    return _db.collection('posts').doc(postId).get();
  }

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
    final batch = _db.batch();

    // 1. Delete the post itself
    final postRef = _db.collection('posts').doc(postId);
    batch.delete(postRef);

    // 2. Cleanup all comments (subcollection)
    final comments = await postRef.collection('comments').get();
    for (var doc in comments.docs) {
      batch.delete(doc.reference);
    }

    // 3. Cleanup all favorites (collection group)
    final favorites = await _db
        .collectionGroup('favorites')
        .where('postId', isEqualTo: postId)
        .get();

    for (var doc in favorites.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  Future<void> updateLike(String postId, {required bool increment}) async {
    await _db.collection('posts').doc(postId).update({
      'likesCount': FieldValue.increment(increment ? 1 : -1),
    });
  }

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

  Stream<List<Post>> searchPosts(String query) {
    return _db
        .collection('posts')
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Post.fromFirestore(doc))
              .where(
                (post) =>
                    post.title.toLowerCase().contains(query.toLowerCase()) ||
                    post.text.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
        });
  }
}
