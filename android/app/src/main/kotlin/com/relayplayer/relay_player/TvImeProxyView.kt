package com.relayplayer.relay_player

import android.annotation.SuppressLint
import android.content.Context
import android.view.KeyEvent
import android.view.View
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputConnection
import io.flutter.embedding.android.FlutterView

/**
 * Stands in for [FlutterView] as the window's focused view on a TV, so the
 * on-screen keyboard is actually bound to a text field and the D-pad can reach
 * it.
 *
 * The bug this works around is flutter/flutter#177360, observed on a Chromecast
 * with Google TV on 2026-09-28: focus a TextField, the keyboard appears, and the
 * D-pad keeps moving Flutter's focus behind it instead of moving across the
 * keys. The cause is one missing override. FlutterView never implements
 * [View.onCheckIsTextEditor], so it always answers false, and InputMethodManager
 * turns that answer into the IS_TEXT_EDITOR start-input flag. Low-RAM TV builds
 * ship `config_preventImeStartupUnlessTextEditor=true` and answer any start
 * without that flag with NO_EDITOR, unbinding the IME. The keyboard is drawn but
 * has no input session, so ViewRootImpl's IME stage has nothing to hand the
 * arrow keys to and they fall through to the app. That is why it reproduces on
 * a Chromecast and not on a phone or the emulator, which do not set the flag.
 *
 * The engine fix (flutter/flutter#193074, adding the override) was still unmerged
 * when this was written and is absent from Flutter 3.47. FlutterActivity builds
 * its FlutterView privately, so it cannot be subclassed from here. What can be
 * done is to put a view that *does* answer true in the focused position and have
 * it delegate everything else back to FlutterView:
 *
 *  - [onCreateInputConnection] returns FlutterView's connection, so the IME
 *    talks to Flutter's TextInputPlugin exactly as before.
 *  - [checkInputConnectionProxy] accepts FlutterView, because TextInputPlugin
 *    calls showSoftInput / restartInput with FlutterView as the argument and
 *    InputMethodManager ignores those calls from any view but the served one
 *    unless the served view vouches for it. Platform-view proxies are still
 *    passed through to FlutterView's own check.
 *  - [dispatchKeyEvent] forwards to FlutterView, which is where Flutter's
 *    KeyboardManager lives. Key events reach the focused view, and this is it
 *    now; without the forward every D-pad press outside a text field would be
 *    lost.
 *
 * For the proxy to keep focus, [MainActivity] also makes FlutterView
 * unfocusable: TextInputPlugin.showTextInput calls FlutterView.requestFocus()
 * before showing the keyboard, and if that succeeded focus would move back to
 * the view that answers false and the bug would return on the first field.
 *
 * Answering true unconditionally is broader than the engine fix, which answers
 * true only while a text client is attached. The difference matters for the
 * system's auto-show on window focus, which [MainActivity] suppresses with
 * SOFT_INPUT_STATE_HIDDEN. When no field is active FlutterView's connection is
 * null, so the IME is bound to nothing and does not draw.
 *
 * Installed on TVs only. Phones and tablets do not have the bug, and swapping
 * the focused view under a touch UI is risk with no benefit. Delete this class
 * and its installation once the engine fix ships in a stable Flutter.
 */
@SuppressLint("ViewConstructor")
class TvImeProxyView(context: Context, private val flutterView: FlutterView) : View(context) {
    init {
        isFocusable = true
        isFocusableInTouchMode = true
    }

    override fun onCheckIsTextEditor(): Boolean = true

    override fun onCreateInputConnection(outAttrs: EditorInfo): InputConnection? =
        flutterView.onCreateInputConnection(outAttrs)

    override fun checkInputConnectionProxy(view: View): Boolean =
        view === flutterView || flutterView.checkInputConnectionProxy(view)

    override fun dispatchKeyEvent(event: KeyEvent): Boolean = flutterView.dispatchKeyEvent(event)
}
