import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_ai/firebase_ai.dart';
import '../models/post.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
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

  final List<String> _topics = [
    'General',
    'Academics',
    'Sports',
    'Events',
    'Tech',
  ];

  // Replace with actual firebase_vertexai / generative_ai initialization
  // For standard Firebase Vertex AI in flutter: FirebaseVertexAI.instance.generativeModel
  // As package APIs shift rapidly, assuming a generic review placeholder if import fails,
  // but let's implement the logic structure.

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 25,
      maxWidth: 400,
      maxHeight: 400,
    );
    if (pickedFile != null) {
      setState(() {
        _pickedImage = pickedFile;
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _processImageBase64() async {
    if (_pickedImage == null) return null;
    try {
      final bytes = await _pickedImage!.readAsBytes();
      if (bytes.length > 400000) {
        throw Exception("Image is too large. Please select a smaller photo.");
      }
      return base64Encode(bytes);
    } catch (e) {
      debugPrint("Image encode error: $e");
      throw Exception("Image processing failed: $e");
    }
  }

  Future<Map<String, String>> _moderateContent(
    String title,
    String text,
  ) async {
    try {
      // 1. Initialize the model using the Google AI backend
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
        generationConfig: GenerationConfig(
          temperature:
              0.1, // Lower temperature = more consistent "robot" moderation
          responseMimeType: 'application/json', // Force JSON output
        ),
      );

      // 2. The Prompt (Tailored for Malaysian 3R)
      final prompt =
          """
          You are an MCMC-compliant moderator for a Malaysian university forum.
          Analyze this post for:
          - 3R violations (Race, Religion, Royalty).
          - Indecent content (Profanity, Violence).
          
          Post: "$title $text"
          
          Return JSON: {"status": "approved" | "rejected", "reason": "string"}
        """;

      // 3. Generate Content
      final response = await model.generateContent([Content.text(prompt)]);
      final Map<String, dynamic> data = jsonDecode(response.text!);

      return {
        'status': data['status'] ?? 'pending',
        'reason': data['reason'] ?? 'No reason provided',
      };
    } catch (e) {
      return {'status': 'pending', 'reason': 'Moderation system error.'};
    }
  }

  Future<void> _submitPost() async {
    final authService = context.read<AuthService>();
    final firestoreService = context.read<FirestoreService>();
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
      // final status = await _moderateContent(
      //   "${_titleController.text} ${_textController.text}",
      // );

      // 1. Run Gemini Moderation
      final moderation =
          await _moderateContent(
            _titleController.text,
            _textController.text,
          ).timeout(
            const Duration(seconds: 10),
          ); // Prevent infinite hanging if network is weak

      final String status = moderation['status']!;
      final String reason = moderation['reason']!;

      // 2. Handle Rejection (3R / Indecency)
      if (status != 'approved') {
        setState(() => _isLoading = false);

        if (status == 'rejected') {
          _showRejectionDialog(reason); // Help the user understand why
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
      String? imageUrl = await _processImageBase64();

      final authorName = user.isAnonymous
          ? "Anonymous User #${user.uid.substring(0, 5)}"
          : (user.displayName ?? "Unknown User");

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
      await firestoreService
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

  void _showRejectionDialog(String reason) {
    showDialog(
      context: context,
      barrierDismissible: false, // Force user to click "Understand"
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Post Flagged (3R/Safety)',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Your post violates community guidelines.\n\nReason: $reason',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Understand'),
          ),
        ],
      ),
    );
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
                  _buildInputCard(
                    title: "Topic",
                    icon: Icons.label_important_outline,
                    child: _buildTopicChips(),
                  ),

                  const SizedBox(height: 16),

                  // --- CARD 2: TEXT CONTENT ---
                  _buildInputCard(
                    title: "Post Content",
                    icon: Icons.edit_note_outlined,
                    child: Column(
                      children: [
                        TextField(
                          controller: _titleController,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Post Title',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const Divider(height: 20),
                        TextField(
                          controller: _textController,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            hintText: "What do you want to share with SUC?",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- CARD 3: ATTACHMENTS ---
                  _buildInputCard(
                    title: "Media",
                    icon: Icons.image_outlined,
                    child: _buildImageSection(primaryColor),
                  ),

                  const SizedBox(height: 32),

                  // --- SUBMIT BUTTON ---
                  ElevatedButton(
                    onPressed: _submitPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Publish to Forum',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Helper Widget to wrap sections in a Card-like Container
  Widget _buildInputCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.blueGrey),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildTopicChips() {
    return Wrap(
      spacing: 12.0,
      runSpacing: 12.0,
      children: _topics.map((topic) {
        final isSelected = _selectedTopic == topic;
        return ChoiceChip(
          label: Text(topic),
          selected: isSelected,
          onSelected: (selected) => setState(() => _selectedTopic = topic),
          selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  // Improved Image Display / Selector
  Widget _buildImageSection(Color primaryColor) {
    if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            kIsWeb
                ? Image.network(
                    _imageFile!.path,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    _imageFile!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
            Positioned(
              right: 8,
              top: 8,
              child: GestureDetector(
                onTap: () => setState(() => _imageFile = null),
                child: const CircleAvatar(
                  backgroundColor: Colors.black54,
                  radius: 14,
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: _pickImage,
      icon: const Icon(Icons.add_a_photo_outlined),
      label: const Text("Add an image"),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
