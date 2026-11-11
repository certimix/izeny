// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:js' as js;

Future<String?> performGoogleAuth() {
  final completer = Completer<String?>();

  try {
    js.context.callMethod('izenyGoogleAuth', [
      js.allowInterop((result) {
        if (!completer.isCompleted) {
          completer.complete(result?.toString());
        }
      }),
      js.allowInterop((error) {
        if (!completer.isCompleted) {
          completer.completeError(error?.toString() ?? 'Erro desconhecido no login com Google');
        }
      }),
    ]);
  } catch (e) {
    if (!completer.isCompleted) {
      completer.completeError('Não foi possível iniciar o login com Google: $e');
    }
  }

  return completer.future;
}
