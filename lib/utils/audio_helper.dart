import 'audio_stub.dart'
    if (dart.library.html) 'audio_web.dart';

abstract class AppAudioPlayer {
  factory AppAudioPlayer() => getAudioPlayer();
  void play(String url, {Function(Duration position, Duration duration)? onProgress, Function()? onComplete});
  void pause();
  void stop();
  bool get isPlaying;
  String? get currentUrl;
}

abstract class AppAudioRecorder {
  factory AppAudioRecorder() => getAudioRecorder();
  Future<bool> start();
  Future<AudioRecordResult?> stop();
  bool get isRecording;
}

class AudioRecordResult {
  final List<int> bytes;
  final String fileName;
  final String mimeType;
  final int durationSeconds;

  AudioRecordResult({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
    this.durationSeconds = 0,
  });
}
