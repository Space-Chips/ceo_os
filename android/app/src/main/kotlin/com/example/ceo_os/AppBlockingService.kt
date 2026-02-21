package com.example.ceo_os

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.content.Intent
import android.graphics.PixelFormat
import android.view.Gravity
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.TextView
import android.graphics.Color
import android.content.Context
import android.os.Build
import android.util.Log
import org.json.JSONObject

class AppBlockingService : AccessibilityService() {

    private var windowManager: WindowManager? = null
    private var blockView: FrameLayout? = null
    private var blockedPackages = mutableSetOf<String>()
    private var isShieldActive = false

    companion object {
        var instance: AppBlockingService? = null
        
        fun updateBlockList(packages: List<String>) {
            instance?.blockedPackages?.clear()
            instance?.blockedPackages?.addAll(packages)
            Log.d("AppBlockingService", "Updated block list: $packages")
        }

        fun setShieldActive(active: Boolean) {
            instance?.isShieldActive = active
            if (active) {
                instance?.refreshBlockListFromPrefs()
            } else {
                instance?.removeBlockOverlay()
            }
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        refreshBlockListFromPrefs()
        Log.d("AppBlockingService", "Service Connected")
    }

    private fun refreshBlockListFromPrefs() {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val jsonStr = prefs.getString("flutter.active_block_list", null)
            if (jsonStr != null) {
                // Flutter's SharedPreferences adds "flutter." prefix
                val json = JSONObject(jsonStr)
                val packagesArray = json.optJSONArray("blocked_package_names")
                blockedPackages.clear()
                if (packagesArray != null) {
                    for (i in 0 until packagesArray.length()) {
                        blockedPackages.add(packagesArray.getString(i))
                    }
                }
                Log.d("AppBlockingService", "Refreshed block list from prefs: $blockedPackages")
            }
        } catch (e: Exception) {
            Log.e("AppBlockingService", "Error refreshing prefs", e)
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!isShieldActive) return
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return
            
            if (blockedPackages.contains(packageName)) {
                showBlockOverlay(packageName)
            }
        }
    }

    override fun onInterrupt() {}

    private fun showBlockOverlay(packageName: String) {
        if (blockView != null) return

        try {
            val params = WindowManager.LayoutParams(
                WindowManager.LayoutParams.MATCH_PARENT,
                WindowManager.LayoutParams.MATCH_PARENT,
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) 
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY 
                else 
                    WindowManager.LayoutParams.TYPE_PHONE,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or 
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or 
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
                PixelFormat.TRANSLUCENT
            )
            params.gravity = Gravity.CENTER

            blockView = FrameLayout(this)
            blockView?.setBackgroundColor(Color.parseColor("#000000"))
            
            val message = TextView(this)
            message.text = "SYSTEM_FOCUS_ACTIVE\n\nACCESS_DENIED"
            message.setTextColor(Color.parseColor("#FF5500"))
            message.textSize = 20f
            message.typeface = android.graphics.Typeface.MONOSPACE
            message.gravity = Gravity.CENTER
            
            val layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT, 
                FrameLayout.LayoutParams.WRAP_CONTENT
            )
            layoutParams.gravity = Gravity.CENTER
            blockView?.addView(message, layoutParams)

            windowManager?.addView(blockView, params)
            
            val homeIntent = Intent(Intent.ACTION_MAIN)
            homeIntent.addCategory(Intent.CATEGORY_HOME)
            homeIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            startActivity(homeIntent)
            
        } catch (e: Exception) {
            Log.e("AppBlockingService", "Error showing overlay", e)
        }
    }

    private fun removeBlockOverlay() {
        if (blockView != null) {
            try {
                windowManager?.removeView(blockView)
                blockView = null
            } catch (e: Exception) {
                Log.e("AppBlockingService", "Error removing overlay", e)
            }
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        instance = null
        removeBlockOverlay()
    }
}
