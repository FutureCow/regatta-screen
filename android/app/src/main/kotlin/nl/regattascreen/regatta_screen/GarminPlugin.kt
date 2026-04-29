package nl.regattascreen.regatta_screen

import android.content.Context
import com.garmin.android.connectiq.ConnectIQ
import com.garmin.android.connectiq.IQApp
import com.garmin.android.connectiq.IQDevice
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class GarminPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    companion object {
        const val METHOD_CHANNEL = "nl.regattascreen/garmin"
        const val EVENT_CHANNEL  = "nl.regattascreen/garmin_events"
        // Moet overeenkomen met de UUID in manifest.xml van de watch app
        const val WATCH_APP_ID   = "a3872ef8-5b7d-4c5e-9b1e-2f4d8a6c3e1f"
    }

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    private var context: Context? = null
    private var connectIQ: ConnectIQ? = null
    private var connectedDevice: IQDevice? = null
    private var watchApp: IQApp? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext

        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        methodChannel?.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        eventChannel?.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                eventSink = sink
            }
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        initConnectIQ()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel?.setMethodCallHandler(null)
        context?.let { connectIQ?.shutdown(it) }
        context = null
    }

    private fun initConnectIQ() {
        val ctx = context ?: return
        connectIQ = ConnectIQ.getInstance(ctx, ConnectIQ.IQConnectType.WIRELESS)
        connectIQ?.initialize(ctx, true, object : ConnectIQ.ConnectIQListener {
            override fun onSdkReady() {
                // Zoek het eerste verbonden Garmin-apparaat
                val devices = connectIQ?.connectedDevices
                if (!devices.isNullOrEmpty()) {
                    connectedDevice = devices[0]
                    watchApp = IQApp(WATCH_APP_ID)
                    registerForWatchMessages()
                }
            }
            override fun onInitializeError(status: ConnectIQ.IQSdkErrorStatus) {
                // Garmin Connect niet beschikbaar of geen apparaat
            }
            override fun onSdkShutDown() {
                connectedDevice = null
                watchApp = null
            }
        })
    }

    private fun registerForWatchMessages() {
        val device = connectedDevice ?: return
        val app    = watchApp ?: return

        connectIQ?.registerForAppEvents(device, app) { _, _, messageData, status ->
            if (status == ConnectIQ.IQMessageStatus.SUCCESS && messageData != null) {
                for (item in messageData) {
                    @Suppress("UNCHECKED_CAST")
                    val map = item as? Map<String, Any> ?: continue
                    val cmd = map["cmd"] as? String ?: continue
                    // Stuur commando door naar Flutter via EventChannel
                    eventSink?.success(cmd)
                }
            }
        }
    }

    // Flutter roept dit aan om de huidige timerstatus naar het horloge te sturen
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "sendTimerState" -> {
                val remaining = call.argument<Int>("remaining") ?: 0
                val running   = call.argument<Boolean>("running") ?: false
                sendToWatch(mapOf("remaining" to remaining, "running" to running))
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun sendToWatch(data: Map<String, Any>) {
        val device = connectedDevice ?: return
        val app    = watchApp ?: return
        connectIQ?.sendMessage(device, app, data) { _, _, _ -> }
    }
}
