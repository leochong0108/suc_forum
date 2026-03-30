import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String text;
  final String authorId;
  final String authorName;
  final String authorRole;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.text,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.createdAt,
  });

  factory Comment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Comment(
      id: doc.id,
      text: data['text'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown User',
      authorRole: data['authorRole'] ?? 'user',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
