package com.callblocker.call_blocker

import android.content.Intent
import android.os.Build
import android.telecom.TelecomManager
import android.app.role.RoleManager
import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.callblocker.call_blocker/call_screening"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isCallScreeningRoleAvailable" -> {
                    result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
                }
                "isDefaultCallScreeningApp" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val roleManager = getSystemService(Context.ROLE_SERVICE) as RoleManager
                        val isDefault = roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)
                        result.success(isDefault)
                    } else {
                        result.success(false)
                    }
                }
                "requestCallScreeningRole" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val roleManager = getSystemService(Context.ROLE_SERVICE) as RoleManager
                        val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING)
                        startActivityForResult(intent, REQUEST_CODE_CALL_SCREENING)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "openCallScreeningSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        try {
                            // Try to open the specific call screening settings
                            val intent = Intent(android.provider.Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    } else {
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    override fun onDestroy() {
        methodChannel?.setMethodCallHandler(null)
        super.onDestroy()
    }
    
    companion object {
        private const val REQUEST_CODE_CALL_SCREENING = 1001
    }
}

