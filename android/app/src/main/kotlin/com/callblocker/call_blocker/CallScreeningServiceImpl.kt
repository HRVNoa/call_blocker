package com.callblocker.call_blocker

import android.content.Context
import android.os.Build
import android.telecom.Call
import android.telecom.CallScreeningService
import androidx.annotation.RequiresApi
import android.util.Log

@RequiresApi(Build.VERSION_CODES.N)
class CallScreeningServiceImpl : CallScreeningService() {
    
    companion object {
        private const val TAG = "CallScreeningService"
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_SERVICE_ENABLED = "flutter.app_settings"
        private const val KEY_PREFIXES = "flutter.blocked_prefixes"
    }

    override fun onScreenCall(callDetails: Call.Details) {
        Log.d(TAG, "onScreenCall triggered")
        
        // Get the incoming phone number
        val phoneNumber = callDetails.handle?.schemeSpecificPart
        Log.d(TAG, "Incoming call from: $phoneNumber")
        
        if (phoneNumber == null || phoneNumber.isEmpty()) {
            // Allow the call if we can't get the number (hidden/blocked numbers)
            Log.d(TAG, "No phone number available (hidden/blocked), allowing call")
            respondToCall(callDetails, buildResponse(false))
            return
        }
        
        // Check if it's a short number (emergency, services, etc.)
        val cleanNumber = phoneNumber.replace(Regex("[^\\d]"), "")
        if (cleanNumber.length < 6) {
            Log.d(TAG, "Short number detected ($cleanNumber), allowing call")
            respondToCall(callDetails, buildResponse(false))
            return
        }
        
        // Check if service is enabled and if number should be blocked
        val shouldBlock = shouldBlockNumber(phoneNumber)
        Log.d(TAG, "Should block: $shouldBlock")
        
        if (shouldBlock) {
            // Block the call
            val response = CallScreeningService.CallResponse.Builder()
                .setDisallowCall(true)
                .setRejectCall(true)
                .setSkipCallLog(false)
                .setSkipNotification(false)
                .build()
            
            respondToCall(callDetails, response)
            Log.i(TAG, "✓ Call blocked from: $phoneNumber")
            
            // Increment blocked calls counter
            incrementBlockedCallsCounter()
        } else {
            // Allow the call
            respondToCall(callDetails, buildResponse(false))
            Log.d(TAG, "Call allowed from: $phoneNumber")
        }
    }
    
    private fun buildResponse(shouldBlock: Boolean): CallScreeningService.CallResponse {
        return CallScreeningService.CallResponse.Builder()
            .setDisallowCall(shouldBlock)
            .setRejectCall(shouldBlock)
            .setSkipCallLog(false)
            .setSkipNotification(false)
            .build()
    }
    
    private fun shouldBlockNumber(phoneNumber: String): Boolean {
        try {
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            
            // Check if service is enabled
            val settingsJson = prefs.getString(KEY_SERVICE_ENABLED, null)
            if (settingsJson == null) {
                Log.d(TAG, "No settings found, allowing call")
                return false
            }
            
            // Parse settings to check if service is enabled
            val isServiceEnabled = parseServiceEnabled(settingsJson)
            if (!isServiceEnabled) {
                Log.d(TAG, "Service is disabled, allowing call")
                return false
            }
            
            // Get blocked prefixes
            val prefixesJson = prefs.getString(KEY_PREFIXES, null)
            if (prefixesJson == null) {
                Log.d(TAG, "No prefixes found, allowing call")
                return false
            }
            
            
            // Clean the phone number (remove non-digits)
            var cleanNumber = phoneNumber.replace(Regex("[^\\d]"), "")
            Log.d(TAG, "Clean number: $cleanNumber")
            
            // Convert international format (+33...) to national format (0...)
            // +33661123456 -> 33661123456 -> 0661123456
            if (cleanNumber.startsWith("33") && cleanNumber.length >= 11) {
                cleanNumber = "0${cleanNumber.substring(2)}"
                Log.d(TAG, "Converted to national format: $cleanNumber")
            }
            
            // Parse and check prefixes
            val blockedPrefixes = parsePrefixes(prefixesJson)
            for (prefix in blockedPrefixes) {
                val cleanPrefix = prefix.replace(Regex("[^\\d]"), "")
                if (cleanNumber.startsWith(cleanPrefix)) {
                    Log.i(TAG, "✓ Number matches blocked prefix: $cleanPrefix")
                    return true
                }
            }

            
            return false
        } catch (e: Exception) {
            Log.e(TAG, "Error checking if number should be blocked", e)
            return false
        }
    }
    
    private fun parseServiceEnabled(json: String): Boolean {
        return try {
            // Simple JSON parsing for isServiceEnabled
            json.contains("\"isServiceEnabled\":true")
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing service enabled", e)
            false
        }
    }
    
    private fun parsePrefixes(json: String): List<String> {
        return try {
            val prefixes = mutableListOf<String>()
            
            // Simple JSON parsing - extract prefix values that are enabled
            // Format: [{"prefix":"0162","description":"...","isEnabled":true},...]
            val regex = Regex(""""prefix":"([^"]+)"[^}]*"isEnabled":true""")
            val matches = regex.findAll(json)
            
            for (match in matches) {
                val prefix = match.groupValues[1]
                prefixes.add(prefix)
                Log.d(TAG, "Found enabled prefix: $prefix")
            }
            
            prefixes
        } catch (e: Exception) {
            Log.e(TAG, "Error parsing prefixes", e)
            emptyList()
        }
    }
    
    private fun incrementBlockedCallsCounter() {
        try {
            val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val currentCount = prefs.getInt("flutter.blocked_calls_count", 0)
            prefs.edit().putInt("flutter.blocked_calls_count", currentCount + 1).apply()
            Log.d(TAG, "Blocked calls count: ${currentCount + 1}")
        } catch (e: Exception) {
            Log.e(TAG, "Error incrementing blocked calls counter", e)
        }
    }
}
