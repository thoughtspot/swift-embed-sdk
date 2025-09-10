//
//  LiveboardEmbedController.swift
//  SwiftEmbedSDK
//
//  Created by Prashant.patil on 24/04/25.
//
import Foundation
import WebKit
import SwiftUI
import Combine

/// Controller class responsible for managing an embedded ThoughtSpot Liveboard.
/// Create an instance of this class using `@StateObject` in your SwiftUI view,
/// configure it, and pass it to the `LiveboardEmbed` view.
public final class LiveboardEmbedController: ObservableObject {
    
    internal let base: BaseEmbedController
    public var webView: WKWebView {
        base.webView
    }

    public init(
        tsEmbedConfig: TSEmbedConfig,
        viewConfig: LiveboardViewConfig
    ) {
        self.base = BaseEmbedController(
            embedConfig: tsEmbedConfig.embedConfig,
            viewConfig: .liveboard(viewConfig),
            embedType: "Liveboard",
            getAuthTokenCallback: tsEmbedConfig.getAuthToken,
            initializationCompletion: tsEmbedConfig.initializationCompletion
        )
        print("LiveboardEmbedController Initialized")
    }

    // --- API mirroring BaseEmbedController ---
    // (on, off, trigger methods)

    /// Registers a callback for a specific EmbedEvent received from the embedded Liveboard.
    public func on(event: EmbedEvent, callback: @escaping BaseEmbedController.EventCallback) {
        base.on(event: event, callback: callback)
    }

    /// Unregisters all callbacks for a specific EmbedEvent.
    public func off(event: EmbedEvent) {
        base.off(event: event)
    }

    /// Triggers an event to be sent to the embedded Liveboard.
    public func trigger(event: HostEvent, data: Any? = nil) {
        base.trigger(event: event, data: data)
    }
    
    public func cleanup() {
        webView.loadHTMLString("", baseURL: nil)
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        webView.removeFromSuperview()
    }

    // MARK: - Deinit
    deinit {
         print("LiveboardEmbedController cleanup happening")
         cleanup()
    }
}
