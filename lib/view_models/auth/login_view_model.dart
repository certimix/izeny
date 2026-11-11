import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:social_media_app/screens/mainscreen.dart';
import 'package:social_media_app/services/auth_service.dart';
import 'package:social_media_app/utils/validation.dart';

class LoginViewModel extends ChangeNotifier {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool validate = false;
  bool loading = false;
  String? email, password;
  FocusNode emailFN = FocusNode();
  FocusNode passFN = FocusNode();
  AuthService auth = AuthService();

  login(BuildContext context) async {
    validate = true;
    notifyListeners();
    FormState? form = formKey.currentState;
    if (form == null) return;
    form.save();
    if (!form.validate()) {
      showInSnackBar('Por favor, corrija os campos destacados em vermelho.', context);
      return;
    }

    loading = true;
    notifyListeners();
    try {
      bool success = await auth.loginUser(
        email: email?.trim(),
        password: password,
      );
      if (success) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (_) => TabScreen()),
        );
      }
    } catch (e) {
      loading = false;
      notifyListeners();
      showInSnackBar(auth.handleFirebaseAuthError(e.toString()), context);
    }
    loading = false;
    notifyListeners();
  }

  loginWithGoogle(BuildContext context) async {
    loading = true;
    notifyListeners();
    try {
      bool success = await auth.loginWithGoogle();
      if (success) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (_) => TabScreen()),
        );
      } else {
        showInSnackBar('Login com Google cancelado.', context);
      }
    } catch (e) {
      showInSnackBar('Erro ao conectar com Google: ${e.toString().replaceAll("Exception:", "").trim()}', context);
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> resetPassword({
    required BuildContext context,
    required String email,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      bool success = await auth.resetPassword(
        email: email.trim(),
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
      return success;
    } catch (e) {
      showInSnackBar(e.toString().replaceAll("Exception:", "").trim(), context);
      return false;
    }
  }

  forgotPassword(BuildContext context) async {
    // Legacy stub - now handled via dialog
  }

  setEmail(val) {
    email = val?.toString().trim();
    notifyListeners();
  }

  setPassword(val) {
    password = val;
    notifyListeners();
  }

  void showInSnackBar(String value, BuildContext context) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
