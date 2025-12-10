import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/account_model.dart';

class AccountService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = 'accounts';

  /// Create new admin account with Firebase Authentication
  Future<String> createAccount({
    required String username,
    required String email,
    required String password,
    required String role,
    String? company,
  }) async {
    try {
      // Validate that Admin role has a company
      if (role == 'Admin' && (company == null || company.isEmpty)) {
        throw Exception('Company is required for Admin role');
      }

      // Create user in Firebase Authentication
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;

      // Create account document in Firestore
      final account = Account(
        username: username,
        email: email,
        role: role,
        company: role == 'Admin' ? company : null,
      );

      await _firestore.collection(collectionName).doc(uid).set(account.toMap());

      return uid;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error creating account: $e');
    }
  }

  /// Sign in with email and password
  Future<Account> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;

      // Get account details from Firestore
      final doc = await _firestore.collection(collectionName).doc(uid).get();

      if (!doc.exists) {
        throw Exception('Account not found');
      }

      return Account.fromMap(doc.data()!, doc.id);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error signing in: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get current user account
  Future<Account?> getCurrentAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection(collectionName)
          .doc(user.uid)
          .get();

      if (!doc.exists) return null;

      return Account.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Error getting current account: $e');
    }
  }

  /// Get all accounts (Super Admin only)
  Stream<List<Account>> getAccounts() {
    return _firestore
        .collection(collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Account.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  /// Check if email already exists
  Future<bool> isEmailExists(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(collectionName)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error checking email: $e');
    }
  }

  /// Delete account
  Future<void> deleteAccount(String uid) async {
    try {
      await _firestore.collection(collectionName).doc(uid).delete();
      // Note: Deleting Firebase Auth user requires re-authentication
      // This should be handled separately for security
    } catch (e) {
      throw Exception('Error deleting account: $e');
    }
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}
