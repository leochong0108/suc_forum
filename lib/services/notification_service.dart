import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> sendNotification({
    required String userId,
    required String message,
  }) async {
    await _db.collection('notifications').add({
      'userId': userId,
      'message': message,
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
