import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUserData;
  UserModel? get currentUserData => _currentUserData;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  AuthService() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        await _fetchUserData(user.uid);
      } else {
        _currentUserData = null;
      }
      _isInitialized = true;
      notifyListeners();
    });
  }

  Future<void> _fetchUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      _currentUserData = UserModel.fromMap(doc.data()!, doc.id);
    }
  }

  Future<UserCredential?> signUpUser({
    required String name,
    required String email,
    required String password,
    String role = 'user', // ADDED: Role specification
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (cred.user != null) {
        final userModel = UserModel(
          uid: cred.user!.uid,
          name: name,
          email: email,
          role: role,
        );
        await _firestore
            .collection('users')
            .doc(cred.user!.uid)
            .set(userModel.toMap());
        _currentUserData = userModel;
        notifyListeners(); // ADDED: ensuring UI updates immediately
      }
      return cred;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (cred.user != null) {
        // Fetch user data before returning so the UI can redirect seamlessly
        await _fetchUserData(cred.user!.uid);
        notifyListeners();
      }
      return cred;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
