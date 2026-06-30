import SwiftUI
import WebKit
import AppKit

/// WKWebView wrapper for rendering HTML email bodies.
/// JavaScript is disabled. External links open in the default browser.
public struct MessageWebView: NSViewRepresentable {
    public let html: String

    public init(html: String) {
        self.html = html
    }

    public func makeNSView(context: Context) -> WKWebView {
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = false

        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences = prefs

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.enclosingScrollView?.hasVerticalScroller = true
        return webView
    }

    public func updateNSView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(styledHTML, baseURL: nil)
    }

    public func makeCoordinator() -> Coordinator { Coordinator() }

    // MARK: - Styling

    private var styledHTML: String {
        """
        <!DOCTYPE html><html><head>
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <style>
        :root { color-scheme: light dark; }
        body {
          font-family: -apple-system, system-ui, sans-serif;
          font-size: 14px;
          line-height: 1.55;
          margin: 20px 26px;
          word-break: break-word;
          -webkit-text-size-adjust: none;
        }
        a { color: #2F6BDB; }
        img { max-width: 100% !important; height: auto !important; }
        table { max-width: 100% !important; border-collapse: collapse; }
        pre, code { font-family: ui-monospace, monospace; font-size: 12px; }
        @media (prefers-color-scheme: dark) {
          body { color: #E5E5E5; }
          a    { color: #4F8EF0; }
        }
        </style>
        </head><body>\(html)</body></html>
        """
    }

    // MARK: - Coordinator

    public final class Coordinator: NSObject, WKNavigationDelegate {
        public func webView(
            _ webView: WKWebView,
            decidePolicyFor action: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if action.navigationType == .linkActivated,
               let url = action.request.url {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}
