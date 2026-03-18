//import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final String role;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.role = 'user',
  });

  Map<String, dynamic> toMap() {
    return {'uid': uid, 'name': name, 'email': email, 'role': role};
  }
}
