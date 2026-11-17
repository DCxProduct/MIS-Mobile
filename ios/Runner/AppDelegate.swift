import Flutter
import UIKit
import WebKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var summaryPrinter: MeetingSummaryPrinter?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MeetingSummaryPrinter") {
      let printer = MeetingSummaryPrinter()
      summaryPrinter = printer
      let channel = FlutterMethodChannel(name: "gpsf/meeting-summary-print", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { call, result in
        guard call.method == "printHtml" else {
          result(FlutterMethodNotImplemented)
          return
        }
        printer.printDocument(call.arguments as? [String: Any], result: result)
      }
    }
  }
}

/// WKWebView supplies native Khmer shaping, rich text and multipage printing.
private final class MeetingSummaryPrinter: NSObject, WKNavigationDelegate {
  private var webView: WKWebView?
  private var pending: FlutterResult?
  private var timeout: DispatchWorkItem?
  private var jobName = "Meeting Summary"
  private weak var hostView: UIView?

  func printDocument(_ arguments: [String: Any]?, result: @escaping FlutterResult) {
    guard webView == nil else {
      result(FlutterError(code: "print_busy", message: "A print job is already open.", details: nil))
      return
    }
    guard let html = arguments?["html"] as? String,
          let name = arguments?["name"] as? String,
          !html.isEmpty,
          let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
          let host = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController?.view else {
      result(FlutterError(code: "print_invalid", message: "Cannot open print preview.", details: nil))
      return
    }
    pending = result
    jobName = name
    hostView = host
    let view = WKWebView(frame: CGRect(x: -1000, y: 0, width: 794, height: 1123))
    webView = view
    view.navigationDelegate = self
    host.addSubview(view)
    let work = DispatchWorkItem { [weak self] in self?.fail("Print preparation timed out.") }
    timeout = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 20, execute: work)
    view.loadHTMLString(html, baseURL: nil)
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    awaitAssets(webView, attempt: 0)
  }

  private func awaitAssets(_ view: WKWebView, attempt: Int) {
    guard webView === view, pending != nil else { return }
    view.evaluateJavaScript("window.__meetingPrintFailed ? 'failed' : (window.__meetingPrintReady ? 'ready' : 'waiting')") { [weak self] state, error in
      guard let self = self, self.webView === view, self.pending != nil else { return }
      if error != nil || (state as? String) == "failed" || attempt >= 150 {
        self.fail("Could not load print fonts or images.")
      } else if (state as? String) == "ready" {
        self.openPrint(view)
      } else {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
          self?.awaitAssets(view, attempt: attempt + 1)
        }
      }
    }
  }

  private func openPrint(_ view: WKWebView) {
    timeout?.cancel()
    guard UIPrintInteractionController.isPrintingAvailable, let host = hostView else {
      fail("Printing is unavailable on this device.")
      return
    }
    let controller = UIPrintInteractionController.shared
    let info = UIPrintInfo(dictionary: nil)
    info.jobName = jobName
    info.outputType = .general
    info.orientation = .portrait
    controller.printInfo = info
    let formatter = view.viewPrintFormatter()
    formatter.perPageContentInsets = UIEdgeInsets(top: 42.5, left: 45.35, bottom: 42.5, right: 45.35)
    controller.printFormatter = formatter
    let completion: UIPrintInteractionController.CompletionHandler = { [weak self] _, _, error in
      guard let self = self else { return }
      if let error = error {
        self.fail(error.localizedDescription)
      } else {
        self.pending?(nil) // User cancellation is not a print error.
        self.pending = nil
        self.dispose()
      }
    }
    let presented: Bool
    if UIDevice.current.userInterfaceIdiom == .pad {
      presented = controller.present(from: CGRect(x: host.bounds.maxX - 48, y: 0, width: 48, height: 48), in: host, animated: true, completionHandler: completion)
    } else {
      presented = controller.present(animated: true, completionHandler: completion)
    }
    if !presented { fail("Could not open print preview.") }
  }

  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    fail(error.localizedDescription)
  }

  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    fail(error.localizedDescription)
  }

  private func fail(_ message: String) {
    pending?(FlutterError(code: "print_failed", message: message, details: nil))
    pending = nil
    dispose()
  }

  private func dispose() {
    timeout?.cancel()
    timeout = nil
    webView?.stopLoading()
    webView?.navigationDelegate = nil
    webView?.removeFromSuperview()
    webView = nil
  }
}
