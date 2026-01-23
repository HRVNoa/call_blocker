import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/blocked_prefix.dart';
import '../models/app_settings.dart';

class StorageService {
  static const String _prefixesKey = 'blocked_prefixes';
  static const String _settingsKey = 'app_settings';

  // Get all blocked prefixes
  Future<List<BlockedPrefix>> getBlockedPrefixes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? prefixesJson = prefs.getString(_prefixesKey);
    
    if (prefixesJson == null) {
      // Return default French telemarketing prefixes
      return _getDefaultPrefixes();
    }
    
    final List<dynamic> decoded = jsonDecode(prefixesJson);
    return decoded.map((json) => BlockedPrefix.fromJson(json)).toList();
  }

  // Save blocked prefixes
  Future<void> saveBlockedPrefixes(List<BlockedPrefix> prefixes) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(prefixes.map((p) => p.toJson()).toList());
    await prefs.setString(_prefixesKey, encoded);
  }

  // Add a new prefix
  Future<void> addPrefix(BlockedPrefix prefix) async {
    final prefixes = await getBlockedPrefixes();
    prefixes.add(prefix);
    await saveBlockedPrefixes(prefixes);
  }

  // Remove a prefix
  Future<void> removePrefix(String prefix) async {
    final prefixes = await getBlockedPrefixes();
    prefixes.removeWhere((p) => p.prefix == prefix);
    await saveBlockedPrefixes(prefixes);
  }

  // Update a prefix
  Future<void> updatePrefix(String oldPrefix, BlockedPrefix newPrefix) async {
    final prefixes = await getBlockedPrefixes();
    final index = prefixes.indexWhere((p) => p.prefix == oldPrefix);
    if (index != -1) {
      prefixes[index] = newPrefix;
      await saveBlockedPrefixes(prefixes);
    }
  }

  // Get app settings
  Future<AppSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? settingsJson = prefs.getString(_settingsKey);
    
    if (settingsJson == null) {
      return AppSettings();
    }
    
    return AppSettings.fromJson(jsonDecode(settingsJson));
  }

  // Save app settings
  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(settings.toJson());
    await prefs.setString(_settingsKey, encoded);
  }

  // Check if a phone number matches any blocked prefix
  Future<bool> isNumberBlocked(String phoneNumber) async {
    final prefixes = await getBlockedPrefixes();
    var cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Convert international format (+33...) to national format (0...)
    // +33661123456 -> 33661123456 -> 0661123456
    if (cleanNumber.startsWith('33') && cleanNumber.length >= 11) {
      cleanNumber = '0${cleanNumber.substring(2)}';
    }
    
    for (var prefix in prefixes) {
      if (prefix.isEnabled) {
        // Clean the prefix too (remove spaces and non-digit characters)
        final cleanPrefix = prefix.prefix.replaceAll(RegExp(r'[^\d]'), '');
        if (cleanNumber.startsWith(cleanPrefix)) {
          return true;
        }
      }
    }
    return false;
  }

  // Get blocked calls count from native storage
  Future<int> getBlockedCallsCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('blocked_calls_count') ?? 0;
  }

  // Save a blocked call to history
  Future<void> saveBlockedCall(String phoneNumber, String matchedPrefix) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing history
    final historyJson = prefs.getString('blocked_calls_history') ?? '[]';
    final List<dynamic> history = jsonDecode(historyJson);
    
    // Add new blocked call
    final blockedCall = {
      'phoneNumber': phoneNumber,
      'timestamp': DateTime.now().toIso8601String(),
      'matchedPrefix': matchedPrefix,
    };
    
    history.insert(0, blockedCall); // Add at the beginning
    
    // Keep only last 100 calls to avoid excessive storage
    if (history.length > 100) {
      history.removeRange(100, history.length);
    }
    
    // Save back
    await prefs.setString('blocked_calls_history', jsonEncode(history));
  }

  // Get blocked calls history
  Future<List<Map<String, dynamic>>> getBlockedCallsHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('blocked_calls_history') ?? '[]';
    final List<dynamic> history = jsonDecode(historyJson);
    return history.cast<Map<String, dynamic>>();
  }

  // Get call frequency by number
  Future<Map<String, int>> getCallFrequency() async {
    final history = await getBlockedCallsHistory();
    final Map<String, int> frequency = {};
    
    for (var call in history) {
      final number = call['phoneNumber'] as String;
      frequency[number] = (frequency[number] ?? 0) + 1;
    }
    
    return frequency;
  }

  // Get most blocked numbers (top 10)
  Future<List<MapEntry<String, int>>> getMostBlockedNumbers() async {
    final frequency = await getCallFrequency();
    final sorted = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(10).toList();
  }

  // Clear history
  Future<void> clearBlockedCallsHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('blocked_calls_history');
    await prefs.setInt('blocked_calls_count', 0);
  }

  // Default French telemarketing prefixes
  List<BlockedPrefix> _getDefaultPrefixes() {
    return [
      BlockedPrefix(
        prefix: '0162',
        description: 'Démarchage téléphonique Paris',
      ),
      BlockedPrefix(
        prefix: '0163',
        description: 'Démarchage téléphonique Paris',
      ),
      BlockedPrefix(
        prefix: '0270',
        description: 'Démarchage téléphonique Ouest',
      ),
      BlockedPrefix(
        prefix: '0271',
        description: 'Démarchage téléphonique Ouest',
      ),
      BlockedPrefix(
        prefix: '0377',
        description: 'Démarchage téléphonique Nord-Est',
      ),
      BlockedPrefix(
        prefix: '0378',
        description: 'Démarchage téléphonique Nord-Est',
      ),
      BlockedPrefix(
        prefix: '0424',
        description: 'Démarchage téléphonique Sud-Est',
      ),
      BlockedPrefix(
        prefix: '0425',
        description: 'Démarchage téléphonique Sud-Est',
      ),
      BlockedPrefix(
        prefix: '0568',
        description: 'Démarchage téléphonique Sud-Ouest',
      ),
      BlockedPrefix(
        prefix: '0569',
        description: 'Démarchage téléphonique Sud-Ouest',
      ),
    ];
  }
}
