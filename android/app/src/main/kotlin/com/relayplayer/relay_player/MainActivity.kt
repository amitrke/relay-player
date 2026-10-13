package com.relayplayer.relay_player

import android.app.UiModeManager
import android.content.Context
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (isTelevision()) installTvImeProxy()
    }

    /**
     * Routes the on-screen keyboard through [TvImeProxyView] so the D-pad can
     * reach it on a Chromecast with Google TV. The class comment has the full
     * account of the engine bug; this is only the wiring.
     *
     * super.onCreate has already set FlutterView as the content view, so it is
     * found there rather than constructed. If it is not found - a future
     * embedding that wraps it differently - nothing is installed and the app
     * behaves as it did before, bug included, rather than failing to start.
     */
    private fun installTvImeProxy() {
        val content = findViewById<ViewGroup>(android.R.id.content) ?: return
        val flutterView = findFlutterView(content) ?: return

        val proxy = TvImeProxyView(this, flutterView)
        addContentView(proxy, ViewGroup.LayoutParams(1, 1))

        // TextInputPlugin calls FlutterView.requestFocus() before every
        // showSoftInput. Were FlutterView still focusable that would take focus
        // back from the proxy and undo the fix on the first field.
        flutterView.isFocusable = false
        flutterView.isFocusableInTouchMode = false
        proxy.requestFocus()

        // The proxy reports itself as a text editor even when no field is
        // focused, and on a large screen Android auto-shows the keyboard for a
        // text editor when the activity is first shown. Keep it hidden until a
        // field asks. adjustResize is carried over from the manifest.
        window.setSoftInputMode(
            WindowManager.LayoutParams.SOFT_INPUT_STATE_HIDDEN or
                WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE,
        )
    }

    private fun findFlutterView(view: View): FlutterView? {
        if (view is FlutterView) return view
        if (view is ViewGroup) {
            for (i in 0 until view.childCount) {
                findFlutterView(view.getChildAt(i))?.let { return it }
            }
        }
        return null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isTelevision" -> result.success(isTelevision())
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Whether this is a TV, which Flutter cannot tell us.
     *
     * Screen size cannot answer it: a 1080p TV reports 960x540 dp and a 4K
     * panel raises density to land in the same place, so a TV looks exactly
     * like a tablet from Dart. MediaQuery.navigationMode is no help either --
     * it defaults to traditional and only changes if the app sets it.
     *
     * Three signals because they disagree in practice: leanback is the Android
     * TV feature and the one Google TV reports, the television hardware type
     * is what some boxes advertise instead, and the UI mode catches a device
     * that is running in a TV dock or launcher without declaring either.
     */
    private fun isTelevision(): Boolean {
        if (packageManager.hasSystemFeature(PackageManager.FEATURE_LEANBACK)) return true
        if (packageManager.hasSystemFeature(PackageManager.FEATURE_TELEVISION)) return true
        val uiMode = getSystemService(Context.UI_MODE_SERVICE) as? UiModeManager
        return uiMode?.currentModeType == Configuration.UI_MODE_TYPE_TELEVISION
    }

    companion object {
        private const val CHANNEL = "relay_player/platform"
    }
}
