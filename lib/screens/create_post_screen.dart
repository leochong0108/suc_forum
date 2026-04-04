import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/post.dart';
import '../services/auth_service.dart';
import '../services/post_service.dart';
import '../services/moderation_service.dart';
import '../services/image_service.dart';
import '../widgets/create_post/input_card.dart';
import '../widgets/create_post/topic_selector.dart';
import '../widgets/create_post/image_selector.dart';
import '../widgets/create_post/post_content_fields.dart';
import '../widgets/create_post/submit_post_button.dart';
import '../widgets/create_post/rejection_dialog.dart';
import '../utils/constants.dart';
import 'main_layout.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  String _selectedTopic = 'General';
  File? _imageFile;
  XFile? _pickedImage;
  bool _isLoading = false;

  final List<String> _topics = AppConstants.topics;

  Future<void> _pickImage() async {
    final imageService = context.read<ImageService>();
    final pickedFile = await imageService.pickImage();
    if (pickedFile != null) {
      setState(() {
        _pickedImage = pickedFile;
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitPost() async {
    final authService = context.read<AuthService>();
    final postService = context.read<PostService>();
    final moderationService = context.read<ModerationService>();
    final user = authService.user;

    if (user == null) {
      _showSnackBar('Please log in to post.');
      return;
    }
    if (_titleController.text.isEmpty || _textController.text.isEmpty) {
      _showSnackBar('Title and content are required.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Run Gemini Moderation using ModerationService
      final moderation = await moderationService
          .moderateContent(_titleController.text, _textController.text)
          .timeout(
            const Duration(seconds: 10),
          ); // Prevent infinite hanging if network is weak

      final String status = moderation['status']!;
      final String reason = moderation['reason']!;

      // 2. Handle Rejection (3R / Indecency)
      if (status != 'approved') {
        setState(() => _isLoading = false);

        if (status == 'rejected') {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => RejectionDialog(reason: reason),
          );
        } else {
          // This handles 'pending', 'failed', or any network errors
          _showSnackBar(
            'Security check failed. Please check your internet connection.',
          );
        }
        return;
      }

      // Generate a document ID locally
      final postId = DateTime.now().millisecondsSinceEpoch.toString();
      final imageService = context.read<ImageService>();
      String? imageUrl = await imageService.processImageBase64(_pickedImage);

      final authorName = authService.authorName;

      final post = Post(
        id: postId, // Using standard add() in service will ignore this local ID, but we needed one for image.
        title: _titleController.text,
        text: _textController.text,
        authorId: user.uid,
        authorName: authorName,
        topic: _selectedTopic,
        imageUrl: imageUrl,
        status: status, // typically 'approved' or 'pending'
        // rejectionReason: status == 'rejected' ? reason : null,
        createdAt: DateTime.now(),
      );

      // We use a timeout because Firestore offline persistence will immediately
      // save the post locally but the network sync might hang if there's no internet.
      await postService
          .createPost(post)
          .timeout(
            const Duration(seconds: 1),
            onTimeout: () {
              debugPrint(
                "Network sync timed out. Saved to local offline cache.",
              );
            },
          );

      if (mounted) {
        _showSnackBar('Post created successfully!');
        _titleController.clear();
        _textController.clear();
        setState(() {
          _imageFile = null;
          _pickedImage = null;
        });

        // Redirect back to Home Tab
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainLayout()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error creating post: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return; // Safety check
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[100], // Soft background to make cards "pop"
      appBar: AppBar(
        title: const Text(
          'Create Post',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- CARD 1: TOPIC SELECTION ---
                  InputCard(
                    title: "Topic",
                    icon: Icons.label_important_outline,
                    child: TopicSelector(
                      topics: _topics,
                      selectedTopic: _selectedTopic,
                      onTopicSelected: (topic) =>
                          setState(() => _selectedTopic = topic),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- CARD 2: TEXT CONTENT ---
                  InputCard(
                    title: "Post Content",
                    icon: Icons.edit_note_outlined,
                    child: PostContentFields(
                      titleController: _titleController,
                      textController: _textController,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- CARD 3: ATTACHMENTS ---
                  InputCard(
                    title: "Media",
                    icon: Icons.image_outlined,
                    child: ImageSelector(
                      imageFile: _imageFile,
                      onPickImage: _pickImage,
                      onClearImage: () => setState(() => _imageFile = null),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- SUBMIT BUTTON ---
                  SubmitPostButton(
                    onPressed: _submitPost,
                    backgroundColor: primaryColor,
                  ),
                ],
              ),
            ),
    );
  }
}
