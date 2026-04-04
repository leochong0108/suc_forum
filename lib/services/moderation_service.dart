import 'dart:convert';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

class ModerationService {
  Future<Map<String, String>> moderateContent(
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
      final prompt = """
          You are an MCMC-compliant moderator for a Malaysian university forum.
          Analyze this post for:
          - 3R violations (Race, Religion, Royalty).
          - Indecent content (Profanity, Violence).
          
          Post: "$title $text"
          
          Return JSON: {"status": "approved" | "rejected", "reason": "string"}
        """;

      // 3. Generate Content
      final response = await model.generateContent([Content.text(prompt)]);
      
      if (response.text == null) {
        return {'status': 'pending', 'reason': 'Moderation response error.'};
      }
      
      final Map<String, dynamic> data = jsonDecode(response.text!);

      return {
        'status': data['status'] ?? 'pending',
        'reason': data['reason'] ?? 'No reason provided',
      };
    } catch (e) {
      debugPrint("Moderation error: $e");
      return {'status': 'pending', 'reason': 'Moderation system error.'};
    }
  }
}
