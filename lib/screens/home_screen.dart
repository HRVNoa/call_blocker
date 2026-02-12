import 'package:flutter/material.dart';
import '../models/blocked_prefix.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../services/call_service.dart';
import 'prefix_manager_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storageService = StorageService();
  final CallService _callService = CallService();
  
  List<BlockedPrefix> _prefixes = [];
  AppSettings _settings = AppSettings();
  bool _hasPermissions = false;
  bool _isDefaultApp = false;
  int _blockedCallsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefixes = await _storageService.getBlockedPrefixes();
    final settings = await _storageService.getSettings();
    final hasPerms = await _callService.hasAllPermissions();
    final isDefault = await _callService.isDefaultCallScreeningApp();
    final blockedCount = await _callService.getBlockedCallsCount();
    
    setState(() {
      _prefixes = prefixes;
      _settings = settings;
      _hasPermissions = hasPerms;
      _isDefaultApp = isDefault;
      _blockedCallsCount = blockedCount;
    });
  }

  Future<void> _toggleService(bool value) async {
    if (value) {
      // Request permissions first
      await _callService.requestPermissions();
      
      // Check if we have at least phone permission (minimum required)
      final hasMinimumPerms = await _callService.hasMinimumPermissions();
      
      if (!hasMinimumPerms) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission téléphone requise pour activer le service'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      
      // Show dialog explaining the setup
      if (mounted) {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('⚙️ Configuration du blocage'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pour bloquer les appels, vous devez :',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text('1️⃣ Accepter les permissions téléphone'),
                SizedBox(height: 8),
                Text('2️⃣ Définir "call_blocker" comme application de blocage par défaut'),
                SizedBox(height: 12),
                Text(
                  'Les paramètres Android vont s\'ouvrir pour configurer l\'application.',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text('Configurer'),
              ),
            ],
          ),
        );
        
        if (result == true) {
          // Initialize call monitoring and request role
          await _callService.initializeCallMonitoring();
          
          // Wait a bit and check if user configured it
          await Future.delayed(const Duration(seconds: 2));
          await _loadData();
          
          if (mounted && !_isDefaultApp) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('N\'oubliez pas de définir call_blocker comme app par défaut !'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Paramètres',
                  textColor: Colors.white,
                  onPressed: () => _callService.openCallScreeningSettings(),
                ),
              ),
            );
          }
        } else {
          return;
        }
      }
      
      // Update permission status
      final hasPerms = await _callService.hasAllPermissions();
      setState(() {
        _hasPermissions = hasPerms;
      });
    }
    
    final newSettings = _settings.copyWith(isServiceEnabled: value);
    await _storageService.saveSettings(newSettings);
    setState(() {
      _settings = newSettings;
    });
  }

  @override
  Widget build(BuildContext context) {
    final enabledPrefixes = _prefixes.where((p) => p.isEnabled).length;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anti-Démarchage'),
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Service Status Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Service de blocage',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Switch(
                        value: _settings.isServiceEnabled,
                        onChanged: _toggleService,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _settings.isServiceEnabled 
                        ? '✓ Actif - Les appels sont surveillés'
                        : '✗ Inactif - Aucun blocage',
                    style: TextStyle(
                      color: _settings.isServiceEnabled 
                          ? Colors.green 
                          : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_settings.isServiceEnabled) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _isDefaultApp ? Icons.check_circle : Icons.warning,
                          size: 16,
                          color: _isDefaultApp ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _isDefaultApp
                                ? 'App configurée comme app par défaut'
                                : 'Non définie comme app par défaut',
                            style: TextStyle(
                              color: _isDefaultApp ? Colors.green[700] : Colors.orange[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (!_isDefaultApp)
                          TextButton(
                            onPressed: () => _callService.openCallScreeningSettings(),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                            ),
                            child: const Text(
                              'Configurer',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (!_hasPermissions && _settings.isServiceEnabled)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '⚠ Permissions manquantes',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Statistics Card
          if (_settings.isServiceEnabled && _blockedCallsCount > 0)
            Card(
              elevation: 4,
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.block,
                      size: 40,
                      color: Colors.green[700],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Appels bloqués',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_blockedCallsCount appel${_blockedCallsCount > 1 ? 's' : ''} bloqué${_blockedCallsCount > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.green[900],
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          if (_settings.isServiceEnabled)
            const SizedBox(height: 16),
          
          // View Statistics Button
          if (_settings.isServiceEnabled)
            Card(
              elevation: 4,
              child: InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StatisticsScreen(),
                    ),
                  );
                  _loadData();
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.analytics,
                        size: 40,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Voir les statistiques',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Historique détaillé et analyse',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
          
          if (_settings.isServiceEnabled)
            const SizedBox(height: 16),
          
          // Prefixes Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Préfixes bloqués',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PrefixManagerScreen(),
                            ),
                          );
                          _loadData();
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Gérer'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$enabledPrefixes préfixe(s) actif(s) sur ${_prefixes.length}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _prefixes.take(6).map((prefix) {
                      return Chip(
                        label: Text(prefix.prefix),
                        backgroundColor: prefix.isEnabled 
                            ? Colors.blue[100] 
                            : Colors.grey[300],
                      );
                    }).toList(),
                  ),
                  if (_prefixes.length > 6)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '... et ${_prefixes.length - 6} autre(s)',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Info Card
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cette application détecte les appels provenant de numéros de démarchage téléphonique et les bloque selon le mode choisi.',
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Note: Sur les versions récentes d\'Android et iOS, certaines fonctionnalités peuvent être limitées par le système.',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _callService.dispose();
    super.dispose();
  }
}
