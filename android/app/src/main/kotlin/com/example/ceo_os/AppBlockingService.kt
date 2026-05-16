package com.wakeapp.ceoos

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
    private var focusBlockedPackages = mutableSetOf<String>()
    private var classicBlockedPackages = mutableSetOf<String>()
    private var focusShieldActive = false
    private var classicShieldActive = false
    private var ceoShieldActive = false

    companion object {
        var instance: AppBlockingService? = null
        
        fun updateBlockList(packages: List<String>) {
            instance?.focusBlockedPackages?.clear()
            instance?.focusBlockedPackages?.addAll(packages)
            Log.d("AppBlockingService", "Updated block list: $packages")
        }

        fun updateClassicBlockList(packages: List<String>) {
            instance?.classicBlockedPackages?.clear()
            instance?.classicBlockedPackages?.addAll(packages)
            Log.d("AppBlockingService", "Updated classic block list: $packages")
        }

        fun setShieldActive(active: Boolean) {
            instance?.focusShieldActive = active
            instance?.ceoShieldActive = false
            instance?.refreshFocusBlockListFromPrefs()
            instance?.applyShieldState()
        }

        fun setClassicShieldActive(active: Boolean) {
            instance?.classicShieldActive = active
            instance?.refreshClassicBlockListFromPrefs()
            instance?.applyShieldState()
        }

        fun setCeoShieldActive(active: Boolean) {
            instance?.ceoShieldActive = active
            if (active) {
                instance?.refreshFocusBlockListFromPrefs()
            }
            instance?.applyShieldState()
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        refreshFocusBlockListFromPrefs()
        refreshClassicBlockListFromPrefs()
        refreshShieldFlagsFromPrefs()
        Log.d("AppBlockingService", "Service Connected")
    }

    private fun refreshFocusBlockListFromPrefs() {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val jsonStr = prefs.getString("flutter.active_block_list", null)
            if (jsonStr != null) {
                val json = JSONObject(jsonStr)
                val packagesArray = json.optJSONArray("blocked_package_names")
                focusBlockedPackages.clear()
                if (packagesArray != null) {
                    for (i in 0 until packagesArray.length()) {
                        focusBlockedPackages.add(packagesArray.getString(i))
                    }
                }
                Log.d("AppBlockingService", "Refreshed focus block list from prefs: $focusBlockedPackages")
            }
        } catch (e: Exception) {
            Log.e("AppBlockingService", "Error refreshing prefs", e)
        }
    }

    private fun refreshClassicBlockListFromPrefs() {
        try {
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val jsonStr = prefs.getString("classic_block_list", null)
            classicBlockedPackages.clear()
            if (jsonStr.isNullOrEmpty()) {
                return
            }
            val json = JSONObject(jsonStr)
            val packagesArray = json.optJSONArray("blocked_package_names")
            if (packagesArray != null) {
                for (i in 0 until packagesArray.length()) {
                    classicBlockedPackages.add(packagesArray.getString(i))
                }
            }
            Log.d("AppBlockingService", "Refreshed classic block list from prefs: $classicBlockedPackages")
        } catch (e: Exception) {
            Log.e("AppBlockingService", "Error refreshing classic prefs", e)
        }
    }

    private fun refreshShieldFlagsFromPrefs() {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        focusShieldActive = prefs.getBoolean("focus_shield_active", false)
        classicShieldActive = prefs.getBoolean("classic_shield_active", false)
        ceoShieldActive = prefs.getBoolean("ceo_shield_active", false)
    }

    private fun effectiveBlockedPackages(): Set<String> {
        val merged = mutableSetOf<String>()
        if (focusShieldActive || ceoShieldActive) {
            merged.addAll(focusBlockedPackages)
        }
        if (classicShieldActive) {
            merged.addAll(classicBlockedPackages)
        }
        return merged
    }

    private fun applyShieldState() {
        if (!focusShieldActive && !classicShieldActive && !ceoShieldActive) {
            removeBlockOverlay()
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!focusShieldActive && !classicShieldActive && !ceoShieldActive) return
        if (event?.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return
            
            if (effectiveBlockedPackages().contains(packageName)) {
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
