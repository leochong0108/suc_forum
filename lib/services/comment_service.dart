import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comment.dart';

class CommentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
}
