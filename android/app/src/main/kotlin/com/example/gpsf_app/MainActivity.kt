package com.example.gpsf_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var summaryPrinter: MeetingSummaryPrinter? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        summaryPrinter = MeetingSummaryPrinter(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "gpsf/meeting-summary-print")
            .setMethodCallHandler { call, result ->
                if (call.method == "printHtml") {
                    summaryPrinter?.print(call.argument("html"), call.argument("name"), result)
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        summaryPrinter?.dispose()
        super.onDestroy()
    }
}
