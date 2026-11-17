package com.example.gpsf_app

import android.app.Activity
import android.content.Context
import android.os.Bundle
import android.os.CancellationSignal
import android.os.Handler
import android.os.Looper
import android.os.ParcelFileDescriptor
import android.print.PageRange
import android.print.PrintAttributes
import android.print.PrintDocumentAdapter
import android.print.PrintManager
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import android.webkit.RenderProcessGoneDetail
import android.os.Build
import io.flutter.plugin.common.MethodChannel

/** Retains the WebView until the spooler finishes reading every page. */
class MeetingSummaryPrinter(private val activity: Activity) {
    private var webView: WebView? = null
    private var pending: MethodChannel.Result? = null
    private var dialogOpen = false
    private val handler = Handler(Looper.getMainLooper())

    fun print(html: String?, name: String?, result: MethodChannel.Result) {
        if (webView != null) {
            result.error("print_busy", "A print job is already open.", null)
            return
        }
        if (html.isNullOrBlank() || name.isNullOrBlank()) {
            result.error("print_invalid", "Missing print document.", null)
            return
        }
        pending = result
        try {
            val view = WebView(activity)
            webView = view
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                view.setRendererPriorityPolicy(WebView.RENDERER_PRIORITY_IMPORTANT, false)
            }
            view.settings.javaScriptEnabled = true // Bundled calendar/readiness only.
            view.settings.allowFileAccess = false
            view.settings.allowContentAccess = false
            view.settings.blockNetworkLoads = true
            view.webViewClient = object : WebViewClient() {
                override fun onPageFinished(view: WebView, url: String?) {
                    awaitAssets(view, name, 0)
                }
                override fun onReceivedError(view: WebView, request: WebResourceRequest, error: WebResourceError) {
                    if (request.isForMainFrame) fail("Could not render the report.")
                }
                override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest) = true
                override fun onRenderProcessGone(view: WebView, detail: RenderProcessGoneDetail): Boolean {
                    fail("The print renderer was closed. Please try again.")
                    return true
                }
            }
            handler.postDelayed({ if (pending != null) fail("Print preparation timed out.") }, 20000)
            view.loadDataWithBaseURL(null, html, "text/html", "UTF-8", null)
        } catch (_: Exception) {
            fail("Could not prepare the report.")
        }
    }

    private fun awaitAssets(view: WebView, name: String, attempt: Int) {
        if (webView !== view || pending == null || dialogOpen) return
        view.evaluateJavascript("window.__meetingPrintFailed ? 'failed' : (window.__meetingPrintReady ? 'ready' : 'waiting')") { state ->
            if (webView !== view || pending == null) return@evaluateJavascript
            when {
                state == "\"ready\"" -> openPrint(view, name)
                state == "\"failed\"" || attempt >= 150 -> fail("Could not load print fonts or images.")
                else -> handler.postDelayed({ awaitAssets(view, name, attempt + 1) }, 100)
            }
        }
    }

    private fun openPrint(view: WebView, name: String) {
        if (dialogOpen) return
        try {
            dialogOpen = true
            handler.removeCallbacksAndMessages(null)
            val delegate = view.createPrintDocumentAdapter(name)
            val adapter = object : PrintDocumentAdapter() {
                override fun onStart() = delegate.onStart()
                override fun onLayout(old: PrintAttributes?, new: PrintAttributes?, cancellation: CancellationSignal?, callback: LayoutResultCallback?, extras: Bundle?) =
                    delegate.onLayout(old, new, cancellation, callback, extras)
                override fun onWrite(pages: Array<out PageRange>?, destination: ParcelFileDescriptor?, cancellation: CancellationSignal?, callback: WriteResultCallback?) =
                    delegate.onWrite(pages, destination, cancellation, callback)
                override fun onFinish() {
                    delegate.onFinish()
                    pending?.success(null) // Cancellation also returns to preview.
                    pending = null
                    dispose()
                }
            }
            val manager = activity.getSystemService(Context.PRINT_SERVICE) as PrintManager
            manager.print(name, adapter, PrintAttributes.Builder()
                .setMediaSize(PrintAttributes.MediaSize.ISO_A4)
                .setColorMode(PrintAttributes.COLOR_MODE_COLOR)
                .setMinMargins(PrintAttributes.Margins.NO_MARGINS).build())
        } catch (_: Exception) {
            fail("Could not open print preview.")
        }
    }

    private fun fail(message: String) {
        pending?.error("print_failed", message, null)
        pending = null
        dispose()
    }

    fun dispose() {
        handler.removeCallbacksAndMessages(null)
        pending?.error("print_cancelled", "Print preparation was cancelled.", null)
        pending = null
        webView?.destroy()
        webView = null
        dialogOpen = false
    }
}
