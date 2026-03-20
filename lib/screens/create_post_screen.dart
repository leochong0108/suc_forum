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

  // Future<String> _moderateContent(String text) async {
  //   // 3R Sensitivity & Indecent content check using Gemini
  //   try {
  //     // NOTE: This assumes standard generative_ai package initialized with API key,
  //     // or FirebaseVertexAI wrapper. We simulate the call structure here.
  //     // If FirebaseVertexAI is successfully configured:
  //     /*
  //     final model = FirebaseVertexAI.instance.generativeModel(model: 'gemini-2.5-flash');
  //     final prompt = "Review this post for 3R sensitivities (Race, Religion, Royalty in Malaysia contexts) and indecent content. Reply merely with 'APPROVED' if it is safe, or 'REJECTED: <reason>' if not. Text: $text";
  //     final response = await model.generateContent([Content.text(prompt)]);
  //     final result = response.text ?? 'APPROVED';
  //     if (result.contains('REJECTED')) return 'rejected';
  //     return 'approved';
  //     */

  //     final lower = text.toLowerCase();
  //     final badWords = ['badword', 'fuck', 'shit', 'babi', 'sial'];
  //     for (var word in badWords) {
  //       if (lower.contains(word)) return 'rejected';
  //     }
  //     return 'approved';
  //   } catch (e) {
  //     debugPrint("Moderation error: $e");
  //     return 'pending'; // Fallback to manual review
  //   }
  // }

  Future<Map<String, String>> _moderateContent(String title, String text) async {
    try {
      // 1. Initialize the model using the Google AI backend
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
        generationConfig: GenerationConfig(
          temperature: 0.1, // Lower temperature = more consistent "robot" moderation
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
      final moderation = await _moderateContent(
        _titleController.text,
        _textController.text,
      );

      final String status = moderation['status']!;
      final String reason = moderation['reason']!;

      // 2. Handle Rejection (3R / Indecency)
      if (status == 'rejected') {
        if (mounted) {
          _showRejectionDialog(reason); // Help the user understand why

        }
        setState(() => _isLoading = false);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedTopic,
                    items: _topics
                        .map(
                          (topic) => DropdownMenuItem(
                            value: topic,
                            child: Text(topic),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedTopic = val!),
                    decoration: const InputDecoration(
                      labelText: 'Topic',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _textController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Content',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_imageFile != null) ...[
                    kIsWeb
                        ? Image.network(_imageFile!.path, height: 150)
                        : Image.file(_imageFile!, height: 150),
                    const SizedBox(height: 8),
                  ],
                  OutlinedButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text('Attach Image'),
                    onPressed: _pickImage,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitPost,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Post', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
    );
  }
}
