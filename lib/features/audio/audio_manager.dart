import 'dart:async';
import 'dart:typed_data';
import 'package:sound_stream/sound_stream.dart';
import 'package:hoky_plain/core/constants.dart';

class AudioManager {
  final RecorderStream _recorder = RecorderStream();
  final PlayerStream _player = PlayerStream();

  StreamSubscription? _recorderSubscription;
  bool _isRecording = false;
  bool _isPlaybackActive = false;

  // Callback for when new audio data is recorded
  Function(Uint8List)? onAudioData;

  Future<void> init() async {
    await _recorder.initialize(sampleRate: AppConstants.sampleRate);
    await _player.initialize(sampleRate: AppConstants.sampleRate);
  }

  void startRecording() {
    if (_isRecording) return;
    _isRecording = true;
    _recorderSubscription = _recorder.audioStream.listen((data) {
      if (onAudioData != null) {
        onAudioData!(Uint8List.fromList(data));
      }
    });
    _recorder.start();
  }

  void stopRecording() {
    _isRecording = false;
    _recorder.stop();
    _recorderSubscription?.cancel();
  }

  void startPlayback() {
    if (_isPlaybackActive) return;
    _isPlaybackActive = true;
    _player.start();
  }

  void playAudioData(Uint8List data) {
    _player.writeChunk(data);
  }

  void stopPlayback() {
    _isPlaybackActive = false;
    _player.stop();
  }

  void dispose() {
    stopRecording();
    stopPlayback();
  }
}
