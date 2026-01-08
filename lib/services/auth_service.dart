import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Tambahkan import ini

class AuthService {
  // Instance FirebaseAuth untuk berinteraksi dengan layanan Firebase Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream untuk memantau perubahan status autentikasi (login/logout)
  Stream<User?> get userStream => _auth.authStateChanges();

  // Mendapatkan User yang sedang aktif
  User? get currentUser => _auth.currentUser;

  // --- Metode REGISTER (Mendaftar Pengguna Baru) ---
  Future<String?> registerWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      await userCredential.user?.updateDisplayName(name);
      return null; // Register berhasil
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'Password terlalu lemah. Minimal 6 karakter.';
      } else if (e.code == 'email-already-in-use') {
        return 'Akun sudah terdaftar untuk email ini.';
      }
      return e.message;
    } catch (e) {
      return 'Terjadi kesalahan tak terduga: ${e.toString()}';
    }
  }

  // --- Metode LOGIN Email/Password ---
  Future<String?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Login berhasil
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'Tidak ada akun terdaftar untuk email ini.';
      } else if (e.code == 'wrong-password') {
        return 'Email atau password salah.';
      }
      return e.message;
    } catch (e) {
      return 'Terjadi kesalahan tak terduga: ${e.toString()}';
    }
  }

  // --- Metode LOGIN DENGAN GOOGLE ---
  Future<String?> signInWithGoogle() async {
    try {
      // 1. Mulai proses Google Sign In
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // Pengguna membatalkan proses login
        return 'Login dibatalkan oleh pengguna.';
      }

      // 2. Dapatkan detail otentikasi dari permintaan
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Buat kredensial Firebase baru dari Google Auth
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Masuk ke Firebase dengan kredensial Google
      await _auth.signInWithCredential(credential);

      return null; // Login berhasil
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Terjadi kesalahan konfigurasi Google Sign-In: ${e.toString()}';
    }
  }

  // --- Metode LOGOUT ---
  Future<void> signOut() async {
    await _auth.signOut();
    // Penting: Logout dari Google Sign-In juga
    await GoogleSignIn().signOut();
  }
}
