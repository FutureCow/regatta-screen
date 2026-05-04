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
        const val WATCH_APP_ID   = "a3872ef8-5b7d-4c5e-9b1e-2f4d8a6c3e1f"
    }

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    private var appContext: Context? = null
    private var connectIQ: ConnectIQ? = null
    private var connectedDevice: IQDevice? = null
    private var watchApp: IQApp? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext

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
        appContext?.let { connectIQ?.shutdown(it) }
        appContext = null
    }

    private fun initConnectIQ() {
        val ctx = appContext ?: return
        try {
            connectIQ = ConnectIQ.getInstance(ctx, ConnectIQ.IQConnectType.WIRELESS)
            connectIQ?.initialize(ctx, false, object : ConnectIQ.ConnectIQListener {
                override fun onSdkReady() {
                    // Probeer al verbonden apparaten
                    val devices = connectIQ?.connectedDevices
                    if (!devices.isNullOrEmpty()) {
                        activateDevice(devices[0])
                    }
                    // Luister ook naar toekomstige verbindingswijzigingen
                    registerForDeviceEvents()
                }
                override fun onInitializeError(status: ConnectIQ.IQSdkErrorStatus) {}
                override fun onSdkShutDown() {
                    connectedDevice = null
                    watchApp = null
                }
            })
        } catch (e: Exception) {
            // Garmin Connect app niet geïnstalleerd
        }
    }

    private fun registerForDeviceEvents() {
        val knownDevices = try {
            connectIQ?.knownDevices
        } catch (e: Exception) { null } ?: return

        for (device in knownDevices) {
            try {
                connectIQ?.registerForDeviceEvents(device) { dev, status ->
                    when (status) {
                        IQDevice.IQDeviceStatus.CONNECTED -> activateDevice(dev)
                        else -> {
                            if (connectedDevice?.deviceIdentifier == dev.deviceIdentifier) {
                                connectedDevice = null
                                watchApp = null
                            }
                        }
                    }
                }
            } catch (e: Exception) {}
        }
    }

    private fun activateDevice(device: IQDevice) {
        connectedDevice = device
        watchApp = IQApp(WATCH_APP_ID)
        registerForWatchMessages()
    }

    private fun registerForWatchMessages() {
        val device = connectedDevice ?: return
        val app    = watchApp ?: return

        connectIQ?.registerForAppEvents(device, app,
            object : ConnectIQ.IQApplicationEventListener {
                override fun onMessageReceived(
                    device: IQDevice,
                    app: IQApp,
                    messageData: List<*>,
                    status: ConnectIQ.IQMessageStatus
                ) {
                    if (status != ConnectIQ.IQMessageStatus.SUCCESS) return
                    for (item in messageData) {
                        @Suppress("UNCHECKED_CAST")
                        val map = item as? Map<String, Any> ?: continue
                        val cmd = map["cmd"] as? String ?: continue
                        eventSink?.success(cmd)
                    }
                }
            }
        )
    }

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
        connectIQ?.sendMessage(device, app, data,
            object : ConnectIQ.IQSendMessageListener {
                override fun onMessageStatus(
                    device: IQDevice,
                    app: IQApp,
                    status: ConnectIQ.IQMessageStatus
                ) {}
            }
        )
    }
}
