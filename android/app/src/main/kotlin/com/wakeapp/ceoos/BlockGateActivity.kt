package com.wakeapp.ceoos

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView

class BlockGateActivity : Activity() {
    companion object {
        const val ACTION_DISMISS = "com.wakeapp.ceoos.action.DISMISS_BLOCK_GATE"
        const val EXTRA_BLOCK_TYPE = "extra_block_type"
        const val EXTRA_PACKAGE_NAME = "extra_package_name"
        const val EXTRA_DOMAIN = "extra_domain"
        const val EXTRA_REASON = "extra_reason"
        const val EXTRA_KICKER = "extra_kicker"
        const val EXTRA_TITLE = "extra_title"
        const val EXTRA_SUBTITLE = "extra_subtitle"
        const val EXTRA_PRIMARY_ACTION = "extra_primary_action"
        const val EXTRA_PRIMARY_LABEL = "extra_primary_label"
        @Volatile
        var isVisible: Boolean = false
    }

    private lateinit var kickerView: TextView
    private lateinit var titleView: TextView
    private lateinit var subtitleView: TextView
    private lateinit var homeLabel: TextView
    private lateinit var primaryButton: TextView
    private var primaryAction: String = "go_home"

    private val dismissReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == ACTION_DISMISS) {
                finish()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        isVisible = true
        window.setBackgroundDrawableResource(android.R.color.transparent)
        overridePendingTransition(0, 0)
        setFinishOnTouchOutside(false)
        buildUi()
        applyIntent(intent)
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        setIntent(intent)
        applyIntent(intent)
    }

    override fun onStart() {
        super.onStart()
        isVisible = true
        BlockingAccessibilityService.onBlockGateVisible()
        val filter = IntentFilter(ACTION_DISMISS)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(dismissReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("DEPRECATION")
            registerReceiver(dismissReceiver, filter)
        }
    }

    override fun onStop() {
        super.onStop()
        isVisible = false
        BlockingAccessibilityService.onBlockGateHidden()
        try {
            unregisterReceiver(dismissReceiver)
        } catch (_: Exception) {
        }
    }

    override fun onBackPressed() {
        runPrimaryAction()
    }

    private fun dp(value: Int): Int {
        return (value * resources.displayMetrics.density).toInt()
    }

    private fun goHome() {
        isVisible = false
        finish()
        overridePendingTransition(0, 0)
        BlockingAccessibilityService.navigateHomeFromBlockGate()
    }

    private fun goBackToBrowser() {
        isVisible = false
        BlockingAccessibilityService.navigateBackFromBlockGate()
        finish()
        overridePendingTransition(0, 0)
    }

    private fun runPrimaryAction() {
        when (primaryAction) {
            "go_back" -> goBackToBrowser()
            else -> goHome()
        }
    }

    private fun openWakeApp() {
        isVisible = false
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_NO_ANIMATION,
            )
        }
        if (launchIntent != null) {
            startActivity(launchIntent)
            finish()
            overridePendingTransition(0, 0)
        }
    }

    private fun applyIntent(intent: Intent?) {
        kickerView.text = intent?.getStringExtra(EXTRA_KICKER)?.uppercase() ?: "BLOCKED"
        titleView.text = intent?.getStringExtra(EXTRA_TITLE) ?: "This app is blocked"
        subtitleView.text =
            intent?.getStringExtra(EXTRA_SUBTITLE)
                ?: "WakeApp is preventing access right now."
        primaryAction = intent?.getStringExtra(EXTRA_PRIMARY_ACTION) ?: "go_home"
        val primaryLabelText = intent?.getStringExtra(EXTRA_PRIMARY_LABEL)
            ?: if (primaryAction == "go_back") {
                "Browser Home"
            } else {
                "Return to Home"
            }
        primaryButton.text = primaryLabelText
        homeLabel.text = if (primaryAction == "go_back") {
            "Browser"
        } else {
            "Home"
        }
    }

    private fun buildUi() {
        val root = FrameLayout(this).apply {
            setBackgroundColor(Color.parseColor("#F00B0D11"))
            isClickable = true
            isFocusable = true
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_YES
        }

        val chromeRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        val homeChip = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(16).toFloat()
                setColor(Color.parseColor("#1AF5F7FA"))
                setStroke(dp(1), Color.parseColor("#26F5F7FA"))
            }
            setPadding(dp(12), dp(10), dp(14), dp(10))
            setOnClickListener { runPrimaryAction() }
        }

        val arrow = ImageView(this).apply {
            setImageResource(android.R.drawable.ic_media_previous)
            setColorFilter(Color.parseColor("#FFF5F7FA"))
            layoutParams = LinearLayout.LayoutParams(dp(16), dp(16))
        }

        homeLabel = TextView(this).apply {
            text = "Home"
            setTextColor(Color.parseColor("#FFF5F7FA"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }

        (homeLabel.layoutParams as? LinearLayout.LayoutParams)?.marginStart = dp(8)
        homeChip.addView(arrow)
        homeChip.addView(homeLabel, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.WRAP_CONTENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        ).apply { marginStart = dp(8) })

        val brandPill = TextView(this).apply {
            text = "WakeApp"
            gravity = Gravity.CENTER
            setTextColor(Color.parseColor("#FFD7DCE5"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(16).toFloat()
                setColor(Color.parseColor("#12181D24"))
                setStroke(dp(1), Color.parseColor("#22F5F7FA"))
            }
            setPadding(dp(12), dp(10), dp(12), dp(10))
        }

        chromeRow.addView(homeChip)
        chromeRow.addView(View(this), LinearLayout.LayoutParams(0, 0, 1f))
        chromeRow.addView(brandPill)

        kickerView = TextView(this).apply {
            setTextColor(Color.parseColor("#FFAA7C"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 11f)
            letterSpacing = 0.18f
            typeface = Typeface.DEFAULT_BOLD
        }

        titleView = TextView(this).apply {
            setTextColor(Color.parseColor("#FFF5F7FA"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 31f)
            setLineSpacing(0f, 1.05f)
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }

        subtitleView = TextView(this).apply {
            setTextColor(Color.parseColor("#C9D0D8E2"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            setLineSpacing(0f, 1.28f)
        }

        primaryButton = TextView(this).apply {
            text = "Return to Home"
            gravity = Gravity.CENTER
            setTextColor(Color.parseColor("#FFF5F7FA"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 15f)
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            setPadding(dp(18), dp(15), dp(18), dp(15))
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(18).toFloat()
                setColor(Color.parseColor("#FF232A35"))
                setStroke(dp(1), Color.parseColor("#33F5F7FA"))
            }
            setOnClickListener { runPrimaryAction() }
        }

        val secondaryButton = TextView(this).apply {
            text = "Open WakeApp"
            gravity = Gravity.CENTER
            setTextColor(Color.parseColor("#FFAA7C"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
            setPadding(dp(12), dp(8), dp(12), dp(4))
            setOnClickListener { openWakeApp() }
        }

        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(24), dp(24), dp(24), dp(22))
            background = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = dp(28).toFloat()
                setColor(Color.parseColor("#F0171B22"))
                setStroke(dp(1), Color.parseColor("#33F5F7FA"))
            }
            elevation = dp(16).toFloat()
        }

        content.addView(chromeRow)
        content.addView(spacer(22))
        content.addView(kickerView)
        content.addView(spacer(10))
        content.addView(titleView)
        content.addView(spacer(12))
        content.addView(subtitleView)
        content.addView(spacer(22))
        content.addView(primaryButton, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT,
        ))
        content.addView(spacer(10))
        content.addView(secondaryButton)

        root.addView(
            content,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT,
                Gravity.CENTER,
            ).apply {
                setMargins(dp(24), dp(24), dp(24), dp(24))
            },
        )

        setContentView(root)
    }

    private fun spacer(heightDp: Int): View {
        return View(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dp(heightDp),
            )
        }
    }
}
