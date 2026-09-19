package com.example.mavepizon_tech

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.telephony.PhoneStateListener
import android.telephony.TelephonyManager
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val callChannel = "mavepizon/call"
    private val eventsChannelName = "mavepizon/call_events"
    private val PERMISSION_REQUEST_CODE = 7001

    private var methodChannel: MethodChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    private var telephonyManager: TelephonyManager? = null
    private var phoneStateListener: PhoneStateListener? = null

    // Outgoing-call tracking state
    private var isOutgoing = false
    private var startedAt: Long = 0
    private var connectedAt: Long = 0
    private var endAt: Long = 0
    private var dialingSeen = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        telephonyManager =
            getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager?

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, callChannel)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "placeCall" -> {
                    val number = call.argument<String>("number") ?: ""
                    if (number.isBlank()) {
                        result.success(mapOf("started" to false, "reason" to "no_number"))
                        return@setMethodCallHandler
                    }
                    if (!hasCallPermission() || !hasReadPhoneStatePermission()) {
                        requestCallPermissions()
                        result.success(mapOf("started" to false, "reason" to "permission_required"))
                        return@setMethodCallHandler
                    }
                    resetCallTracking()
                    isOutgoing = true
                    startedAt = System.currentTimeMillis()
                    emitState("started", startedAt)
                    try {
                        val intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$number"))
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(mapOf("started" to true))
                    } catch (e: Exception) {
                        isOutgoing = false
                        runOnUiThread {
                            endTrackingIfNeeded()
                        }
                        e.printStackTrace()
                        result.success(mapOf("started" to false, "reason" to "activity_error"))
                    }
                }
                "requestPermissions" -> {
                    requestCallPermissions()
                    result.success(true)
                }
                "getPermissions" -> {
                    result.success(
                        mapOf(
                            "callPhone" to hasCallPermission(),
                            "readPhoneState" to hasReadPhoneStatePermission()
                        )
                    )
                }
                "dispose" -> {
                    detachListener()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // EventChannel for native -> Flutter call lifecycle events
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventsChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(
                    arguments: Any?,
                    events: EventChannel.EventSink?
                ) {
                    eventSink = events
                    attachListener()
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    detachListener()
                }
            })
    }

    private fun resetCallTracking() {
        isOutgoing = false
        startedAt = 0
        connectedAt = 0
        endAt = 0
        dialingSeen = false
    }

    private fun emitState(state: String, ts: Long) {
        eventSink?.success(
            mapOf(
                "state" to state,
                "ts" to ts,
                "startedAt" to startedAt,
                "connectedAt" to connectedAt,
                "endAt" to endAt
            )
        )
    }

    private fun endTrackingIfNeeded() {
        if (!isOutgoing) return
        isOutgoing = false
        endAt = System.currentTimeMillis()
        emitState("ended", endAt)
    }

    private fun attachListener() {
        if (phoneStateListener != null) return
        phoneStateListener = object : PhoneStateListener() {
            override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                handleCallState(state)
            }
        }
        try {
            telephonyManager?.listen(
                phoneStateListener,
                PhoneStateListener.LISTEN_CALL_STATE
            )
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun detachListener() {
        phoneStateListener?.let {
            try {
                telephonyManager?.listen(it, PhoneStateListener.LISTEN_NONE)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        phoneStateListener = null
    }

    @Suppress("DEPRECATION")
    private fun handleCallState(state: Int) {
        val now = System.currentTimeMillis()
        when (state) {
            TelephonyManager.CALL_STATE_IDLE -> {
                if (isOutgoing) {
                    // Call finished (answered, missed or the dial was cancelled)
                    endTrackingIfNeeded()
                }
            }
            TelephonyManager.CALL_STATE_RINGING -> {
                // Remote end is ringing (outgoing dial). 
                if (isOutgoing) {
                    if (dialingSeen) {
                        // Dialing -> ringing means the number is being rung, not answered yet.
                        emitState("ringing", now)
                    }
                }
            }
            TelephonyManager.CALL_STATE_OFFHOOK -> {
                if (isOutgoing) {
                    if (!dialingSeen) {
                        // First OFFHOOK = the call is being placed (dialing).
                        dialingSeen = true
                        emitState("ringing", now) // "Ringing/Dialing" lifecycle stage
                    } else {
                        // Connected/active once we transition OFFHOOK after dialing/ringing.
                        if (connectedAt == 0L) {
                            connectedAt = now
                            emitState("connected", now)
                        }
                    }
                }
            }
        }
    }

    private fun hasCallPermission(): Boolean =
        ActivityCompat.checkSelfPermission(
            this, Manifest.permission.CALL_PHONE
        ) == PackageManager.PERMISSION_GRANTED

    private fun hasReadPhoneStatePermission(): Boolean =
        ActivityCompat.checkSelfPermission(
            this, Manifest.permission.READ_PHONE_STATE
        ) == PackageManager.PERMISSION_GRANTED

    private fun requestCallPermissions() {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(
                Manifest.permission.CALL_PHONE,
                Manifest.permission.READ_PHONE_STATE
            ),
            PERMISSION_REQUEST_CODE
        )
    }
}
