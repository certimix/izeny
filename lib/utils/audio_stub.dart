import 'audio_helper.dart';

AppAudioPlayer getAudioPlayer() => _StubAudioPlayer();
AppAudioRecorder getAudioRecorder() => _StubAudioRecorder();

class _StubAudioPlayer implements AppAudioPlayer {
  bool _playing = false;
  String? _url;

  @override
  void play(String url, {Function(Duration position, Duration duration)? onProgress, Function()? onComplete}) {
    _url = url;
    _playing = true;
  }

  @override
  void pause() {
    _playing = false;
  }

  @override
  void stop() {
    _playing = false;
  }

  @override
  bool get isPlaying => _playing;

  @override
  String? get currentUrl => _url;
}

class _StubAudioRecorder implements AppAudioRecorder {
  bool _recording = false;

  @override
  Future<bool> start() async {
    _recording = true;
    return true;
  }

  @override
  Future<AudioRecordResult?> stop() async {
    _recording = false;
    return null;
  }

  @override
  bool get isRecording => _recording;
}

