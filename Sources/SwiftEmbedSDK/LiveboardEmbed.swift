import SwiftUI
import WebKit

/// SwiftUI View for embedding Liveboards.
/// Initialize this view with an instance of `LiveboardEmbedController`.
public struct LiveboardEmbed: View {
    @ObservedObject public var controller: LiveboardEmbedController

    public init(controller: LiveboardEmbedController) {
        self.controller = controller
    }

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
            return webView
        }

        func updateUIView(_ uiView: WKWebView, context: Context) {
            // print("WebViewRepresentable: updateUIView called")
        }
    }
}
