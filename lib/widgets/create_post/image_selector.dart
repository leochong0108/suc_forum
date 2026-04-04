import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ImageSelector extends StatefulWidget {
  final File? imageFile;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;

  const ImageSelector({
    super.key,
    required this.imageFile,
    required this.onPickImage,
    required this.onClearImage,
  });

  @override
  State<ImageSelector> createState() => _ImageSelectorState();
}

class _ImageSelectorState extends State<ImageSelector> {
  @override
  Widget build(BuildContext context) {
    if (widget.imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            kIsWeb
                ? Image.network(
                    widget.imageFile!.path,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Image.file(
                    widget.imageFile!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
            Positioned(
              right: 8,
              top: 8,
              child: GestureDetector(
                onTap: widget.onClearImage,
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
      onPressed: widget.onPickImage,
      icon: const Icon(Icons.add_a_photo_outlined),
      label: const Text("Add an image"),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
