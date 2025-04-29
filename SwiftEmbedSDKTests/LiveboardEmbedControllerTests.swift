//
//  LiveboardEmbedControllerTests.swift
//  SwiftEmbedSDK
//
//  Created by Prashant.patil on 28/04/25.
//

import XCTest
import Combine
@testable import SwiftEmbedSDK

final class LiveboardEmbedControllerTests: XCTestCase {

    var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        cancellables = []
    }

    override func tearDown() {
        super.tearDown()
    }

    func createMockAuthCallback(result: Result<String, Error>) -> (() -> Future<String, Error>)? {
        return {
            Future { promise in
                switch result {
                case .success(let token):
                    promise(.success(token))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
    }

    // MARK: - Initialization Tests

    func testLiveboardEmbedControllerInitialization() {
        let mockEmbedConfig = EmbedConfig(thoughtSpotHost: "https://genuine.com", authType: .TrustedAuthTokenCookieless)
        let mockLiveboardConfig = LiveboardViewConfig(liveboardId: "test-liveboard-id")
        let mockTSEmbedConfig = TSEmbedConfig(embedConfig: mockEmbedConfig, getAuthToken: nil, initializationCompletion: nil)

        let controller = LiveboardEmbedController(tsEmbedConfig: mockTSEmbedConfig, viewConfig: mockLiveboardConfig)

        XCTAssertNotNil(controller.base, "BaseEmbedController should be initialized")
        XCTAssertNotNil(controller.webView, "WebView should be accessible")
    }

    func testLiveboardEmbedControllerPassesConfigsToBaseEmbedController() {
        let mockEmbedConfig = EmbedConfig(thoughtSpotHost: "https://genuine.com", authType: .TrustedAuthTokenCookieless)
        let mockLiveboardConfig = LiveboardViewConfig(liveboardId: "test-liveboard-id")
        let mockAuthCallback = createMockAuthCallback(result: .success("test-token"))
        let mockCompletion: ((Result<Void, Error>) -> Void)? = { _ in }
        let mockTSEmbedConfig = TSEmbedConfig(embedConfig: mockEmbedConfig, getAuthToken: mockAuthCallback, initializationCompletion: mockCompletion)

        let controller = LiveboardEmbedController(tsEmbedConfig: mockTSEmbedConfig, viewConfig: mockLiveboardConfig)

        XCTAssertEqual(controller.base.embedConfig.thoughtSpotHost, mockEmbedConfig.thoughtSpotHost)
        XCTAssertEqual(controller.base.embedConfig.authType, mockEmbedConfig.authType)
        // TODO: Making LiveboardConfig - conform to Equatable
//        XCTAssertEqual(controller.base.viewConfig, .liveboard(mockLiveboardConfig))
        XCTAssertEqual(controller.base.embedType, "Liveboard")
        XCTAssertNotNil(controller.base.getAuthTokenCallback)
        XCTAssertNotNil(controller.base.initializationCompletion)
    }

    // MARK: - API Mirroring Tests

    func testOnEventIsForwardedToBaseEmbedController() {
        let mockEmbedConfig = EmbedConfig(thoughtSpotHost: "https://genuine.com", authType: .TrustedAuthTokenCookieless)
        let mockLiveboardConfig = LiveboardViewConfig()
        let mockTSEmbedConfig = TSEmbedConfig(embedConfig: mockEmbedConfig)
        let controller = LiveboardEmbedController(tsEmbedConfig: mockTSEmbedConfig, viewConfig: mockLiveboardConfig)

        let expectation = XCTestExpectation(description: "Callback should be executed")
        var callbackExecuted = false
        let mockCallback: (Any?) -> Void = { _ in
            callbackExecuted = true
            expectation.fulfill()
        }

        controller.on(event: EmbedEvent.AuthInit, callback: mockCallback)

        XCTAssertNotNil(controller.base.eventListeners[EmbedEvent.AuthInit])
        XCTAssertEqual(controller.base.eventListeners[EmbedEvent.AuthInit]?.count, 1)
    }

    func testOffEventIsForwardedToBaseEmbedController() {
        let mockEmbedConfig = EmbedConfig(thoughtSpotHost: "https://genuine.com", authType: .TrustedAuthTokenCookieless)
        let mockLiveboardConfig = LiveboardViewConfig()
        let mockTSEmbedConfig = TSEmbedConfig(embedConfig: mockEmbedConfig)
        let controller = LiveboardEmbedController(tsEmbedConfig: mockTSEmbedConfig, viewConfig: mockLiveboardConfig)

        let mockCallback: (Any?) -> Void = { _ in }
        controller.on(event: .AuthInit, callback: mockCallback)
        controller.off(event: .AuthInit)

        XCTAssertNil(controller.base.eventListeners[.AuthInit], "All listeners for .AuthInit should be removed")
    }

    func testTriggerEventIsForwardedToBaseEmbedController() {
        let mockEmbedConfig = EmbedConfig(thoughtSpotHost: "https://genuine.com", authType: .TrustedAuthTokenCookieless)
        let mockLiveboardConfig = LiveboardViewConfig()
        let mockTSEmbedConfig = TSEmbedConfig(embedConfig: mockEmbedConfig)
        let controller = LiveboardEmbedController(tsEmbedConfig: mockTSEmbedConfig, viewConfig: mockLiveboardConfig)

        let expectation = XCTestExpectation(description: "Message should be sent")
        var sentMessage: [String: Any]?
        controller.base.onMessageSend = { message in
            sentMessage = message
            expectation.fulfill()
        }

        let testData = ["key": "value"]
        controller.trigger(event: .Reload, data: testData)

        wait(for: [expectation], timeout: 0.1)

        XCTAssertNotNil(sentMessage, "Message should have been sent")
        XCTAssertEqual(sentMessage?["type"] as? String, "HOST_EVENT")
        XCTAssertEqual(sentMessage?["eventName"] as? String, HostEvent.Reload.rawValue)
        XCTAssertEqual((sentMessage?["payload"] as? [String: Any])?["key"] as? String, "value")
    }
}
