import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isAnonymous => _user?.isAnonymous ?? false;
  String? _userRole;
  String? get userRole => _userRole;
  bool get isAdmin => _userRole == 'admin';

  String get authorName {
    final u = _user;
    if (u == null) return "Guest";
    if (u.isAnonymous) {
      return "Anonymous User #${u.uid.substring(0, 5)}";
    }
    return u.displayName ?? "Unknown User";
  }

  AuthService() {
    _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _fetchUserRole(user.uid);
      } else {
        _userRole = null;
      }
      notifyListeners();
    });
  }

  Future<void> _fetchUserRole(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        _userRole = doc.data()!['role'] ?? 'user';
      } else {
        _userRole = 'user';
      }
    } catch (e) {
      debugPrint("Error fetching user role: $e");
    }
  }

  Future<void> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
    } catch (e) {
      debugPrint("Error signing in anonymously: $e");
      rethrow;
    }
  }

  // A basic register and sign-in for real-name mode
  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      debugPrint("Error signing in with email: $e");
      rethrow;
    }
  }

  Future<void> registerWithEmailPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        await cred.user!.updateDisplayName(displayName);
        // Force reload to get updated display name in the stream

        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set({
              'uid': cred.user!.uid,
              'name': displayName,
              'email': email,
              'role': 'user',
              'createdAt': FieldValue.serverTimestamp(),
            });

        await cred.user!.reload();
        _user = _auth.currentUser;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error registering with email: $e");
      rethrow;
    }
  }

  Future<void> updateUserName(String newName) async {
    try {
      if (_user != null) {
        await _user!.updateDisplayName(newName);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({'name': newName});
        await _user!.reload();
        _user = _auth.currentUser;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error updating user name: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
