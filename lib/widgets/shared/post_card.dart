import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/post.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../screens/post_detail_screen.dart';
import 'package:share_plus/share_plus.dart';

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  // Helper method to trigger the native share sheet
  void _handleShare() {
    Share.share(
      'Check out this post on SUC Forum!\n\n'
      '${post.title}\n'
      'By: ${post.authorName}\n\n'
      '${post.text}',
      subject: post.title,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final userService = context.read<UserService>();
    final userId = authService.user?.uid;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      elevation: 1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(post: post),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: User Info & Topic
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(radius: 20, child: Icon(Icons.person)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              post.topic,
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '•  ${timeago.format(post.createdAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (userId != null)
                    StreamBuilder<bool>(
                      stream: userService.isPostFavorited(userId, post.id),
                      builder: (context, snapshot) {
                        final isBookmarked = snapshot.data ?? false;
                        return IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            size: 22,
                            color: isBookmarked
                                ? Theme.of(context).primaryColor
                                : Colors.grey[400],
                          ),
                          onPressed: () {
                            userService.toggleFavorite(
                              userId,
                              post,
                              !isBookmarked,
                            );
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isBookmarked
                                      ? 'Removed from Favorites'
                                      : 'Saved to Collections',
                                ),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                                width: 250,
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Post Title
              if (post.title.isNotEmpty)
                Text(
                  post.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),

              const SizedBox(height: 4),

              // Post Text
              if (post.text.isNotEmpty)
                Text(
                  post.text,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),

              const SizedBox(height: 12),

              // Post Image (Full Width)
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: post.imageUrl!.startsWith('http')
                        ? Image.network(post.imageUrl!, fit: BoxFit.cover)
                        : Image.memory(
                            base64Decode(post.imageUrl!),
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Footer: Likes
              Divider(height: 1, color: Colors.grey[300]),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.thumb_up_alt_outlined,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${post.likesCount}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Icon(
                    Icons.comment_outlined,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${post.commentsCount} Replies',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  // Share Button
                  IconButton(
                    icon: Icon(Icons.share_outlined, size: 20, color: Colors.grey[600]),
                    onPressed: _handleShare,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
