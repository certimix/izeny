import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:social_media_app/pocketbase/pb_compat.dart';
import 'package:social_media_app/utils/firebase.dart';
import 'package:social_media_app/utils/google_auth_helper.dart';

class AuthService {
  User getCurrentUser() {
    User user = firebaseAuth.currentUser!;
    return user;
  }

  // Create user
  Future<bool> createUser(
      {String? name,
      User? user,
      String? email,
      String? country,
      String? password}) async {
    var res = await firebaseAuth.createUserWithEmailAndPassword(
      email: '$email',
      password: '$password',
    );
    if (res.user != null) {
      await saveUserToFirestore(name!, res.user!, email!, country!);
      return true;
    } else {
      return false;
    }
  }

  saveUserToFirestore(
      String name, User user, String email, String country) async {
    await usersRef.doc(user.uid).set({
      'username': name,
      'email': email,
      'time': Timestamp.now(),
      'id': user.uid,
      'bio': "",
      'country': country,
      'photoUrl': user.photoURL ?? '',
      'gender': '',
    });
  }

  // Login with email and password
  Future<bool> loginUser({String? email, String? password}) async {
    var res = await firebaseAuth.signInWithEmailAndPassword(
      email: '${email?.trim()}',
      password: '$password',
    );

    if (res.user != null) {
      return true;
    } else {
      return false;
    }
  }

  // Login with Google OAuth
  Future<bool> loginWithGoogle() async {
    final resultStr = await triggerGoogleAuth();
    if (resultStr == null || resultStr.isEmpty) {
      return false;
    }
    final data = jsonDecode(resultStr) as Map<String, dynamic>;
    final token = data['token'] as String?;
    final record = data['record'] as Map<String, dynamic>?;

    if (token != null && record != null) {
      await PBClient.instance.saveAuth(token, record);
      return true;
    }
    return false;
  }

  // Direct password reset via microservice
  Future<bool> resetPassword({
    required String email,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final url = Uri.parse('${PBClient.instance.baseUrl}/api/auth/reset-password');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'newPassword': newPassword,
        'newPasswordConfirm': confirmPassword,
      }),
    );

    if (resp.statusCode == 200) {
      return true;
    } else {
      final err = jsonDecode(resp.body);
      throw Exception(err['error'] ?? 'Erro ao redefinir senha.');
    }
  }

  forgotPassword(String email) async {
    await firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  logOut() async {
    await firebaseAuth.signOut();
  }

  String handleFirebaseAuthError(String e) {
    if (e.contains("ERROR_WEAK_PASSWORD") || e.contains("weak-password")) {
      return "A senha é muito fraca. Escolha outra.";
    } else if (e.contains("invalid-email")) {
      return "Formato de e-mail inválido.";
    } else if (e.contains("ERROR_EMAIL_ALREADY_IN_USE") ||
        e.contains('email-already-in-use')) {
      return "Este e-mail já está em uso por outra conta.";
    } else if (e.contains("ERROR_NETWORK_REQUEST_FAILED")) {
      return "Erro de conexão de rede. Verifique sua internet.";
    } else if (e.contains("ERROR_USER_NOT_FOUND") ||
        e.contains('firebase_auth/user-not-found') ||
        e.contains('wrong-password') ||
        e.contains('Credenciais inválidas') ||
        e.contains('Failed to authenticate')) {
      return "E-mail ou senha incorretos. Verifique suas credenciais.";
    } else if (e.contains('firebase_auth/requires-recent-login')) {
      return 'Esta operação requer autenticação recente. Faça login novamente.';
    } else {
      return e.replaceAll('Exception:', '').trim();
    }
  }
}
