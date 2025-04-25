import SwiftUI
import WebKit

/// SwiftUI View for embedding Liveboards.
/// Initialize this view with an instance of `LiveboardEmbedController`.
public struct LiveboardEmbed: View {
    // Using @ObservedObject because the controller's lifecycle
    // is managed by the parent view (using @StateObject)
    @ObservedObject public var controller: LiveboardEmbedController

    // Initializer accepts the controller
    public init(controller: LiveboardEmbedController) {
        self.controller = controller
    }

    // The body displays the web content using a representable
    public var body: some View {
        WebViewRepresentable(webView: controller.webView)
            .onAppear {
                 print("LiveboardEmbed (View) appeared")
            }
            .onDisappear {
                 print("LiveboardEmbed (View) disappeared")
            }
    }

    // --- UIViewRepresentable for SwiftUI Integration ---
    // Needed to host the WKWebView within SwiftUI
    private struct WebViewRepresentable: UIViewRepresentable {
        typealias UIViewType = WKWebView
        let webView: WKWebView

        func makeUIView(context: Context) -> WKWebView {
            print("WebViewRepresentable: makeUIView called")
            // Return the webView instance from the controller
            return webView
        }

        func updateUIView(_ uiView: WKWebView, context: Context) {
            // print("WebViewRepresentable: updateUIView called")
        }
    }
}
