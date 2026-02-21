package com.example.ceo_os

import android.content.Intent
import android.provider.Settings
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.ceoos.app/focus"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermissions" -> {
                    // Open Accessibility Settings
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    
                    // Also check Overlay permission
                    if (!Settings.canDrawOverlays(this)) {
                        val overlayIntent = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, 
                            Uri.parse("package:$packageName"))
                        startActivity(overlayIntent)
                    }
                    result.success(true)
                }
                "startShield" -> {
                    val packages = call.argument<List<String>>("packages") ?: listOf()
                    AppBlockingService.updateBlockList(packages)
                    AppBlockingService.setShieldActive(true)
                    result.success(null)
                }
                "stopShield" -> {
                    AppBlockingService.setShieldActive(false)
                    result.success(null)
                }
                "isShieldActive" -> {
                    // Simple check if service is running/connected (approximate)
                    result.success(AppBlockingService.instance != null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
