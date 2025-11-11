import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:habit_tracker/services/firestore_service.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Sign in failed');
      }

      // Get user data from Firestore
      return await _firestoreService.getUserProfile(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register with email and password
  Future<UserModel> registerWithEmail(
      String email,
      String password,
      String displayName,
      ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Registration failed');
      }

      // Update display name
      await credential.user!.updateDisplayName(displayName);

      // Create user profile in Firestore
      final userModel = UserModel(
        id: credential.user!.uid,
        email: email,
        displayName: displayName,
      );

      await _firestoreService.createUserProfile(userModel);

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with Google
  Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Quá trình đăng nhập Google đã bị hủy bởi người dùng.');
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw Exception('Đăng nhập Google không thành công.');
      }

      // Check if user exists in Firestore
      final userExists = await _firestoreService.userExists(
        userCredential.user!.uid,
      );

      if (!userExists) {
        // Create new user profile
        final userModel = UserModel(
          id: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          displayName: userCredential.user!.displayName,
          photoUrl: userCredential.user!.photoURL,
        );
        await _firestoreService.createUserProfile(userModel);
        return userModel;
      }

      return await _firestoreService.getUserProfile(userCredential.user!.uid);
    } catch (e) {
      throw e;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle auth exceptions
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return Exception('Email này đã được sử dụng bởi một tài khoản khác. Vui lòng sử dụng email khác hoặc đăng nhập.');
      case 'invalid-credential':
        return Exception('Thông tin xác thực không hợp lệ. Vui lòng kiểm tra email hoặc mật khẩu.');
      case 'user-not-found':
        return Exception('Tài khoản không tồn tại. Vui lòng kiểm tra email.');
      case 'wrong-password':
        return Exception('Mật khẩu không đúng. Vui lòng thử lại.');
      case 'invalid-email':
        return Exception('Email không hợp lệ. Vui lòng nhập email hợp lệ.');
      case 'user-disabled':
        return Exception('Tài khoản đã bị vô hiệu hóa.');
      case 'too-many-requests':
        return Exception('Quá nhiều lần thử đăng nhập. Vui lòng thử lại sau.');
      default:
        return Exception('Đã xảy ra lỗi: ${e.message}');
    }
  }
}