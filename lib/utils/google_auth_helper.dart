import 'dart:async';
import 'google_auth_stub.dart'
    if (dart.library.html) 'google_auth_web.dart';

Future<String?> triggerGoogleAuth() async {
  return performGoogleAuth();
}
