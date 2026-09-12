package com.relayplayer.relay_player

import android.app.UiModeManager
import android.content.Context
import android.content.pm.PackageManager
import android.content.res.Configuration
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
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
