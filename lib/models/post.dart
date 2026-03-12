import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String title;
  final String text;
  final String authorId;
  final String authorName;
  final String topic;
  final String? imageUrl;
  final int likesCount;
  final int commentsCount;
  final String status; // 'approved', 'pending', 'rejected'
  final DateTime createdAt;

  Post({
    required this.id,
    required this.title,
    required this.text,
    required this.authorId,
    required this.authorName,
    required this.topic,
    this.imageUrl,
    this.likesCount = 0,
    this.commentsCount = 0,
    required this.status,
    required this.createdAt,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Post(
      id: doc.id,
      title: data['title'] ?? '',
      text: data['text'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown User',
      topic: data['topic'] ?? 'General',
      imageUrl: data['imageUrl'],
      likesCount: data['likesCount'] ?? 0,
      commentsCount: data['commentsCount'] ?? 0,
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'text': text,
      'authorId': authorId,
      'authorName': authorName,
      'topic': topic,
      'imageUrl': imageUrl,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
