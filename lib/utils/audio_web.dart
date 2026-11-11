import 'dart:async';
import 'dart:html' as html;
import 'audio_helper.dart';

AppAudioPlayer getAudioPlayer() => WebAudioPlayer();
AppAudioRecorder getAudioRecorder() => WebAudioRecorder();

class WebAudioPlayer implements AppAudioPlayer {
  html.AudioElement? _audio;
  String? _url;
  bool _isPlaying = false;
  StreamSubscription? _timeUpdateSub;
  StreamSubscription? _endedSub;

  @override
  void play(String url, {Function(Duration position, Duration duration)? onProgress, Function()? onComplete}) {
    if (_url == url && _audio != null) {
      _audio!.play();
      _isPlaying = true;
      return;
    }

    stop();
    _url = url;
    _audio = html.AudioElement(url);
    _audio!.autoplay = true;
    _isPlaying = true;

    _timeUpdateSub = _audio!.onTimeUpdate.listen((_) {
      if (_audio != null) {
        final pos = Duration(milliseconds: ((_audio!.currentTime ?? 0) * 1000).toInt());
        final dur = Duration(milliseconds: ((_audio!.duration ?? 0) * 1000).toInt());
        onProgress?.call(pos, dur);
      }
    });

    _endedSub = _audio!.onEnded.listen((_) {
      _isPlaying = false;
      onComplete?.call();
    });

    _audio!.play().catchError((e) {
      _isPlaying = false;
    });
  }

  @override
  void pause() {
    _audio?.pause();
    _isPlaying = false;
  }

  @override
  void stop() {
    _timeUpdateSub?.cancel();
    _endedSub?.cancel();
    _audio?.pause();
    _audio?.src = '';
    _audio = null;
    _isPlaying = false;
  }

  @override
  bool get isPlaying => _isPlaying;

  @override
  String? get currentUrl => _url;
}

class WebAudioRecorder implements AppAudioRecorder {
  html.MediaRecorder? _mediaRecorder;
  html.MediaStream? _stream;
  final List<html.Blob> _chunks = [];
  bool _isRecording = false;
  DateTime? _startTime;

  @override
  bool get isRecording => _isRecording;

  @override
  Future<bool> start() async {
    try {
      _chunks.clear();
      _stream = await html.window.navigator.mediaDevices?.getUserMedia({'audio': true});
      if (_stream == null) return false;

      _mediaRecorder = html.MediaRecorder(_stream!);
      _mediaRecorder!.addEventListener('dataavailable', (event) {
        final data = (event as dynamic).data as html.Blob?;
        if (data != null && data.size > 0) {
          _chunks.add(data);
        }
      });

      _mediaRecorder!.start();
      _isRecording = true;
      _startTime = DateTime.now();
      return true;
    } catch (e) {
      print('[WebAudioRecorder] Error starting recording: $e');
      return false;
    }
  }

  @override
  Future<AudioRecordResult?> stop() async {
    if (!_isRecording || _mediaRecorder == null) return null;

    final completer = Completer<AudioRecordResult?>();
    final durationSeconds = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : 0;

    _mediaRecorder!.addEventListener('stop', (_) async {
      try {
        final blob = html.Blob(_chunks, 'audio/webm');
        final reader = html.FileReader();
        reader.readAsArrayBuffer(blob);
        await reader.onLoadEnd.first;
        final list = (reader.result as dynamic) as List<int>;

        _stream?.getTracks().forEach((track) => track.stop());
        _isRecording = false;

        completer.complete(AudioRecordResult(
          bytes: list,
          fileName: 'voice_${DateTime.now().millisecondsSinceEpoch}.webm',
          mimeType: 'audio/webm',
          durationSeconds: durationSeconds > 0 ? durationSeconds : 1,
        ));
      } catch (e) {
        print('[WebAudioRecorder] Error processing recorded blob: $e');
        completer.complete(null);
      }
    });

    _mediaRecorder!.stop();
    return completer.future;
  }
}
