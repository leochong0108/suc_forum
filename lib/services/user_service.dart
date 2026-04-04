import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
    QuerySnapshot userComments = await _db
        .collectionGroup('comments')
        .where('authorId', isEqualTo: uid)
        .get();

    for (var doc in userComments.docs) {
      batch.update(doc.reference, {'authorName': newName});
    }

    await batch.commit();
  }

  // Favorite logic
  Future<void> toggleFavorite(String userId, Post post, bool isFavorite) async {
    final ref = _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(post.id);

    if (isFavorite) {
      final data = post.toMap();
      data['postId'] = post.id;
      await ref.set(data);
    } else {
      await ref.delete();
    }
  }

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
}
