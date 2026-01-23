import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'storage_service.dart';
import 'audio_service.dart';

class CallService {
  final StorageService _storageService = StorageService();
  final AudioService _audioService = AudioService();
  
  // MethodChannel for native Android communication
  static const platform = MethodChannel('com.callblocker.call_blocker/call_screening');

  // Initialize call monitoring
  // Note: Real-time call detection requires system-level permissions
  // that are not available on modern Android/iOS without root access
  Future<bool> initializeCallMonitoring() async {
    // Request permissions
    final phonePermission = await Permission.phone.request();
    
    if (!phonePermission.isGranted) {
      return false;
    }

    // Check if call screening is available (Android 10+)
    try {
      final isAvailable = await platform.invokeMethod<bool>('isCallScreeningRoleAvailable') ?? false;
      if (isAvailable) {
        // Request call screening role
        await requestCallScreeningRole();
      }
    } catch (e) {
      print('Error initializing call screening: $e');
    }
    
    return true;
  }
  
  // Check if call screening role is available
  Future<bool> isCallScreeningAvailable() async {
    try {
      return await platform.invokeMethod<bool>('isCallScreeningRoleAvailable') ?? false;
    } catch (e) {
      print('Error checking call screening availability: $e');
      return false;
    }
  }
  
  // Check if app is set as default call screening app
  Future<bool> isDefaultCallScreeningApp() async {
    try {
      return await platform.invokeMethod<bool>('isDefaultCallScreeningApp') ?? false;
    } catch (e) {
      print('Error checking if default call screening app: $e');
      return false;
    }
  }
  
  // Request call screening role
  Future<bool> requestCallScreeningRole() async {
    try {
      return await platform.invokeMethod<bool>('requestCallScreeningRole') ?? false;
    } catch (e) {
      print('Error requesting call screening role: $e');
      return false;
    }
  }
  
  // Open call screening settings
  Future<bool> openCallScreeningSettings() async {
    try {
      return await platform.invokeMethod<bool>('openCallScreeningSettings') ?? false;
    } catch (e) {
      print('Error opening call screening settings: $e');
      return false;
    }
  }
  
  // Get blocked calls count from native storage
  Future<int> getBlockedCallsCount() async {
    return await _storageService.getBlockedCallsCount();
  }

  // Simulate checking if a number should be blocked
  Future<bool> shouldBlockNumber(String phoneNumber) async {
    return await _storageService.isNumberBlocked(phoneNumber);
  }

  // Request necessary permissions
  Future<Map<Permission, PermissionStatus>> requestPermissions() async {
    return await [
      Permission.phone,
      Permission.microphone,
      Permission.storage,
    ].request();
  }

  // Check if minimum permissions are granted (phone only)
  Future<bool> hasMinimumPermissions() async {
    final phoneStatus = await Permission.phone.status;
    return phoneStatus.isGranted || phoneStatus.isLimited;
  }

  // Check if all permissions are granted
  Future<bool> hasAllPermissions() async {
    final phoneStatus = await Permission.phone.status;
    final micStatus = await Permission.microphone.status;
    
    // Storage permission is optional on modern Android
    // Only require phone permission as mandatory
    return (phoneStatus.isGranted || phoneStatus.isLimited) && 
           (micStatus.isGranted || micStatus.isLimited || micStatus.isDenied);
  }

  void dispose() {
    _audioService.dispose();
  }
}
