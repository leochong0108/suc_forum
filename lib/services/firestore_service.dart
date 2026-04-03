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
    // Note: requires a Collection Group Index on "favorites"
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

  Future<void> updateUserName(String uid, String newName) async {
    final batch = _db.batch();

    // 1. Update user document
    DocumentReference userRef = _db.collection('users').doc(uid);
    batch.update(userRef, {'name': newName});

    // 2. Update all posts by this author
    QuerySnapshot userPosts = await _db
        .collection('posts')
        .where('authorId', isEqualTo: uid)
        .get();

    for (var doc in userPosts.docs) {
      batch.update(doc.reference, {'authorName': newName});
    }

    // 3. Update all comments by this author using collection group
    // Note: If the user has > 500 posts+comments, this might exceed batch limit.
    // In a real app, you'd handle this with chunking or a Cloud Function.
    QuerySnapshot userComments = await _db
        .collectionGroup('comments')
        .where('authorId', isEqualTo: uid)
        .get();

    for (var doc in userComments.docs) {
      batch.update(doc.reference, {'authorName': newName});
    }

    await batch.commit();
  }

  // Favorite
  Future<void> toggleFavorite(String userId, Post post, bool isFavorite) async {
    final ref = _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(post.id);

    if (isFavorite) {
      // Save the whole post for offline viewing + add postId for better cleanup
      final data = post.toMap();
      data['postId'] = post.id;
      await ref.set(data);
    } else {
      await ref.delete();
    }
  }

  // Check if a post is already favorited (Real-time)
  Stream<bool> isPostFavorited(String userId, String postId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(postId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<List<Post>> getFavoritePosts(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Post.fromFirestore(doc)).toList(),
        );
  }

  Stream<List<Post>> searchPosts(String query) {
    return _db
        .collection('posts')
        .where('status', isEqualTo: 'approved') // Only search safe posts
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
