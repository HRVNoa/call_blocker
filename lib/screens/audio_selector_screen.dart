import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';

class AudioSelectorScreen extends StatefulWidget {
  const AudioSelectorScreen({super.key});

  @override
  State<AudioSelectorScreen> createState() => _AudioSelectorScreenState();
}

class _AudioSelectorScreenState extends State<AudioSelectorScreen> {
  final AudioService _audioService = AudioService();
  final StorageService _storageService = StorageService();
  
  String? _currentAudioPath;
  bool _isRecording = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentAudio();
  }

  Future<void> _loadCurrentAudio() async {
    final settings = await _storageService.getSettings();
    setState(() {
      _currentAudioPath = settings.audioFilePath;
    });
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      final settings = await _storageService.getSettings();
      final newSettings = settings.copyWith(audioFilePath: filePath);
      await _storageService.saveSettings(newSettings);
      
      setState(() {
        _currentAudioPath = filePath;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fichier audio sélectionné')),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    final path = await _audioService.startRecording();
    if (path != null) {
      setState(() {
        _isRecording = true;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de démarrer l\'enregistrement'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioService.stopRecording();
    setState(() {
      _isRecording = false;
    });
    
    if (path != null) {
      // Save as current audio
      final settings = await _storageService.getSettings();
      final newSettings = settings.copyWith(audioFilePath: path);
      await _storageService.saveSettings(newSettings);
      
      setState(() {
        _currentAudioPath = path;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enregistrement sauvegardé')),
        );
      }
    }
  }

  Future<void> _playAudio() async {
    if (_currentAudioPath != null) {
      setState(() {
        _isPlaying = true;
      });
      
      await _audioService.playAudio(_currentAudioPath!);
      
      // Wait for audio to finish (simplified - in production use audio player callbacks)
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    }
  }

  Future<void> _stopAudio() async {
    await _audioService.stopAudio();
    setState(() {
      _isPlaying = false;
    });
  }

  Future<void> _deleteAudio() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le message'),
        content: const Text('Voulez-vous vraiment supprimer ce message vocal ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && _currentAudioPath != null) {
      await _audioService.deleteAudioFile(_currentAudioPath!);
      
      final settings = await _storageService.getSettings();
      final newSettings = settings.copyWith(audioFilePath: null);
      await _storageService.saveSettings(newSettings);
      
      setState(() {
        _currentAudioPath = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message supprimé')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message vocal'),
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Audio Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      _currentAudioPath != null ? Icons.mic : Icons.mic_none,
                      size: 64,
                      color: _currentAudioPath != null 
                          ? Colors.blue 
                          : Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentAudioPath != null 
                          ? 'Message vocal configuré' 
                          : 'Aucun message vocal',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_currentAudioPath != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _currentAudioPath!.split('/').last,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isPlaying ? _stopAudio : _playAudio,
                            icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                            label: Text(_isPlaying ? 'Arrêter' : 'Écouter'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _deleteAudio,
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text('Supprimer', 
                              style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Recording Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Enregistrer un nouveau message',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isRecording)
                      Column(
                        children: [
                          const Icon(
                            Icons.fiber_manual_record,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Enregistrement en cours...',
                            style: TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ElevatedButton.icon(
                      onPressed: _isRecording ? _stopRecording : _startRecording,
                      icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                      label: Text(_isRecording 
                          ? 'Arrêter l\'enregistrement' 
                          : 'Commencer l\'enregistrement'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRecording ? Colors.red : null,
                        foregroundColor: _isRecording ? Colors.white : null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // File Picker Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Ou choisir un fichier audio',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _pickAudioFile,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Parcourir les fichiers'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Le message sera joué automatiquement lors des appels bloqués',
                      style: TextStyle(
                        color: Colors.blue[900],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
