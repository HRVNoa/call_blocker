import 'package:just_audio/just_audio.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  bool _isRecorderInitialized = false;

  // Initialize recorder
  Future<void> _initRecorder() async {
    if (!_isRecorderInitialized) {
      await _recorder.openRecorder();
      _isRecorderInitialized = true;
    }
  }

  // Play audio file
  Future<void> playAudio(String filePath) async {
    try {
      await _audioPlayer.setFilePath(filePath);
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing audio: $e');
      rethrow;
    }
  }

  // Stop audio playback
  Future<void> stopAudio() async {
    await _audioPlayer.stop();
  }

  // Start recording
  Future<String?> startRecording() async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        return null;
      }

      await _initRecorder();
      
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/voice_message_${DateTime.now().millisecondsSinceEpoch}.aac';
      
      await _recorder.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );
      
      _isRecording = true;
      return filePath;
    } catch (e) {
      print('Error starting recording: $e');
      return null;
    }
  }

  // Stop recording
  Future<String?> stopRecording() async {
    try {
      if (_isRecording) {
        final path = await _recorder.stopRecorder();
        _isRecording = false;
        return path;
      }
      return null;
    } catch (e) {
      print('Error stopping recording: $e');
      return null;
    }
  }

  // Check if currently recording
  bool get isRecording => _isRecording;

  // Get audio duration
  Future<Duration?> getAudioDuration(String filePath) async {
    try {
      await _audioPlayer.setFilePath(filePath);
      return _audioPlayer.duration;
    } catch (e) {
      print('Error getting audio duration: $e');
      return null;
    }
  }

  // Delete audio file
  Future<void> deleteAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting audio file: $e');
    }
  }

  // Dispose resources
  void dispose() {
    _audioPlayer.dispose();
    if (_isRecorderInitialized) {
      _recorder.closeRecorder();
    }
  }
}
