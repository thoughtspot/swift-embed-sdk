//
//  BaseControllerTests.swift
//  SwiftEmbedSDK
//
//  Created by Prashant.patil on 24/04/25.
//

import XCTest
import Combine
import WebKit
@testable import SwiftEmbedSDK

func createMockAuthCallback(result: Result<String, Error>) -> () -> Future<String,Error> {
    return {
        Future {
            promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                promise(result)
            }
        }
    }
}

class MockScriptMessage: WKScriptMessage {
    private var _mockBody: Any
    override var body: Any { return _mockBody }


    init(body: Any) {
        self._mockBody = body
        super.init()
    }
}


class BaseControllerTests: XCTestCase {
    
    var cancellables: Set<AnyCancellable>!
    
    var baseEmbed: BaseEmbedController!
    
    override func setUp() {
        try super.setUp()
        cancellables = []
    }
    
    override func tearDown() {
        baseEmbed = nil
        cancellables = nil
        try super.tearDown()
    }
    
    func testHandleRequestAuthToken_Success() throws {
        let expectation = XCTestExpectation(description: "Receive successful auth token response message")
        let testToken = "test-token-12345"
        let mockCallback = createMockAuthCallback(result: .success(testToken))
        let mockEmbedConfig = EmbedConfig(thoughtSpotHost: "https://genuine.com", authType: AuthType.TrustedAuthTokenCookieless)
        let mockLiveboardConfig = LiveboardViewConfig()
        let mockViewConfig = SpecificViewConfig.liveboard(mockLiveboardConfig)

        baseEmbed = BaseEmbedController(
            embedConfig: mockEmbedConfig,
            viewConfig: mockViewConfig,
            embedType: "liveboard",
            getAuthTokenCallback: mockCallback
        )

        var sentMessage: [String: Any]?
        baseEmbed.onMessageSend = { message in
            print("Test captured message: \(message)")
            sentMessage = message
            expectation.fulfill()
        }

        baseEmbed.handleRequestAuthToken()

        wait(for: [expectation], timeout: 1.0)

        XCTAssertNotNil(sentMessage, "onMessageSend should have been called")
        XCTAssertEqual(sentMessage?["type"] as? String, "AUTH_TOKEN_RESPONSE", "Message type should be AUTH_TOKEN_RESPONSE")
        XCTAssertEqual(sentMessage?["token"] as? String, testToken, "Message should contain the correct token")
    }
    
    func testHandleRequestAuthToken_Failure() throws {
        let expectation = XCTestExpectation(description: "Receive auth token error message")
        struct MockAuthError: LocalizedError { var errorDescription: String? = "Network unavailable" }
        let testError = MockAuthError()
        let mockCallback = createMockAuthCallback(result: .failure(testError))

        let mockEmbedConfig = EmbedConfig(thoughtSpotHost: "https://genuine.com", authType: AuthType.TrustedAuthTokenCookieless)
        let mockLiveboardConfig = LiveboardViewConfig()
        let mockViewConfig = SpecificViewConfig.liveboard(mockLiveboardConfig)

        baseEmbed = BaseEmbedController(
            embedConfig: mockEmbedConfig,
            viewConfig: mockViewConfig,
            embedType: "liveboard",
            getAuthTokenCallback: mockCallback
        )

        var sentMessage: [String: Any]?
        baseEmbed.onMessageSend = { message in
            sentMessage = message
            expectation.fulfill()
        }

        baseEmbed.handleRequestAuthToken()

        wait(for: [expectation], timeout: 1.0)

        XCTAssertNotNil(sentMessage, "onMessageSend should have been called")
        XCTAssertEqual(sentMessage?["type"] as? String, "AUTH_TOKEN_ERROR", "Message type should be AUTH_TOKEN_ERROR")
        XCTAssertEqual(sentMessage?["error"] as? String, testError.localizedDescription, "Message should contain the correct error description")
    }

    func testHandleRequestAuthToken_NilCallback() throws {
        let mockEmbedConfig = EmbedConfig(thoughtSpotHost: "https://genuine.com", authType: AuthType.TrustedAuthTokenCookieless)
        let mockLiveboardConfig = LiveboardViewConfig()
        let mockViewConfig = SpecificViewConfig.liveboard(mockLiveboardConfig)

        baseEmbed = BaseEmbedController(
            embedConfig: mockEmbedConfig,
            viewConfig: mockViewConfig,
            embedType: "liveboard",
            getAuthTokenCallback: nil
        )

        var messageWasSent = false
        baseEmbed.onMessageSend = { _ in
            messageWasSent = true
        }

        baseEmbed.handleRequestAuthToken()

        XCTAssertFalse(messageWasSent, "No message should be sent if the callback is nil")
    }
    
    // - userContentController
    func testUserContentController_HandlesInitVercelShell() throws {
        let mockEmbedConfig = EmbedConfig(thoughtSpotHost: "https://genuine.com", authType: AuthType.TrustedAuthTokenCookieless)
        let mockLiveboardConfig = LiveboardViewConfig()
        let mockViewConfig = SpecificViewConfig.liveboard(mockLiveboardConfig)
        baseEmbed = BaseEmbedController(embedConfig: mockEmbedConfig, viewConfig: mockViewConfig, embedType: "liveboard")

        let messagePayload: [String: Any] = ["type": "INIT_VERCEL_SHELL"]
        let jsonString = try! String(data: JSONSerialization.data(withJSONObject: messagePayload), encoding: .utf8)!
        let mockMessage = MockScriptMessage(body: jsonString)

        let expectation = XCTestExpectation(description: "Shell initialization messages sent")
        expectation.expectedFulfillmentCount = 2

        var sentMessages: [[String: Any]] = []
        baseEmbed.onMessageSend = { message in
            sentMessages.append(message)
            expectation.fulfill()
        }

        baseEmbed.userContentController(WKUserContentController(), didReceive: mockMessage)

        wait(for: [expectation], timeout: 0.5)

        XCTAssertEqual(sentMessages.count, 2)
        XCTAssertEqual(sentMessages.first?["type"] as? String, "INIT")
        XCTAssertEqual(sentMessages.last?["type"] as? String, "EMBED")
    }

    func testUserContentController_HandlesRequestAuthToken() throws {
        let expectation = XCTestExpectation(description: "Auth token request handled")
        let mockCallback = createMockAuthCallback(result: .success("dummy-token"))
        let mockEmbedConfig = EmbedConfig(thoughtSpotHost: "https://genuine.com", authType: AuthType.TrustedAuthTokenCookieless)
        let mockLiveboardConfig = LiveboardViewConfig()
        let mockViewConfig = SpecificViewConfig.liveboard(mockLiveboardConfig)

        baseEmbed = BaseEmbedController(
            embedConfig: mockEmbedConfig,
            viewConfig: mockViewConfig,
            embedType: "liveboard",
            getAuthTokenCallback: mockCallback
        )

        let messagePayload: [String: Any] = ["type": "REQUEST_AUTH_TOKEN"]
        let jsonString = try! String(data: JSONSerialization.data(withJSONObject: messagePayload), encoding: .utf8)!
        let mockMessage = MockScriptMessage(body: jsonString)

        baseEmbed.onMessageSend = { message in
            if message["type"] as? String == "AUTH_TOKEN_RESPONSE" {
                 expectation.fulfill()
            }
        }

        baseEmbed.userContentController(WKUserContentController(), didReceive: mockMessage)

        wait(for: [expectation], timeout: 1.0)
    }


    func testUserContentController_HandlesEmbedEvent() throws {
        let expectation = XCTestExpectation(description: "Embed event listener called")
        let mockEmbedConfig = EmbedConfig(thoughtSpotHost: "https://genuine.com", authType: AuthType.TrustedAuthTokenCookieless)
        let mockLiveboardConfig = LiveboardViewConfig()
        let mockViewConfig = SpecificViewConfig.liveboard(mockLiveboardConfig)
        baseEmbed = BaseEmbedController(embedConfig: mockEmbedConfig, viewConfig: mockViewConfig, embedType: "liveboard")

        let testEvent = EmbedEvent.AuthInit
        let testEventData: [String: Any] = ["detail": "some info", "value": 42]

        baseEmbed.on(event: testEvent) { data in
            XCTAssertNotNil(data)
            let receivedData = data as? [String: Any]
            XCTAssertEqual(receivedData?["detail"] as? String, "some info")
            XCTAssertEqual(receivedData?["value"] as? Int, 42)
            expectation.fulfill()
        }

        let messagePayload: [String: Any] = [
            "type": "EMBED_EVENT",
            "eventName": testEvent.rawValue,
            "data": testEventData
        ]
        let jsonString = try! String(data: JSONSerialization.data(withJSONObject: messagePayload), encoding: .utf8)!
        let mockMessage = MockScriptMessage(body: jsonString)

        baseEmbed.userContentController(WKUserContentController(), didReceive: mockMessage)

        wait(for: [expectation], timeout: 0.5)
    }


    func testUserContentController_HandlesInvalidJson() throws {
         let mockEmbedConfig = EmbedConfig(thoughtSpotHost: "https://genuine.com", authType: AuthType.TrustedAuthTokenCookieless)
        let mockLiveboardConfig = LiveboardViewConfig()
        let mockViewConfig = SpecificViewConfig.liveboard(mockLiveboardConfig)
        baseEmbed = BaseEmbedController(embedConfig: mockEmbedConfig, viewConfig: mockViewConfig, embedType: "liveboard")

        let invalidJsonString = "{ not json,"
        let mockMessage = MockScriptMessage(body: invalidJsonString)

        var handlerCalled = false
        baseEmbed.onMessageSend = { _ in handlerCalled = true }
        baseEmbed.on(event: EmbedEvent.AuthInit) { _ in handlerCalled = true }


        baseEmbed.userContentController(WKUserContentController(), didReceive: mockMessage)

        XCTAssertFalse(handlerCalled, "No handlers or callbacks should be invoked for invalid JSON")
    }
    
    // trigger
    func testTrigger_SendsCorrectlyFormattedMessage() throws {
        let expectation = XCTestExpectation(description: "HOST_EVENT message sent via onMessageSend")
        let mockEmbedConfig = EmbedConfig(thoughtSpotHost: "https://genuine.com", authType: AuthType.TrustedAuthTokenCookieless)
        let mockLiveboardConfig = LiveboardViewConfig()
        let mockViewConfig = SpecificViewConfig.liveboard(mockLiveboardConfig)
        baseEmbed = BaseEmbedController(embedConfig: mockEmbedConfig, viewConfig: mockViewConfig, embedType: "liveboard")

        let testHostEvent = HostEvent.Reload
        let testEventData: [String: Any] = ["buttonId": "submit", "count": 1]

        var sentMessage: [String: Any]?
        baseEmbed.onMessageSend = { message in
            sentMessage = message
            expectation.fulfill()
        }

        baseEmbed.trigger(event: testHostEvent, data: testEventData)

        wait(for: [expectation], timeout: 0.5)

        XCTAssertNotNil(sentMessage)
        XCTAssertEqual(sentMessage?["type"] as? String, "HOST_EVENT")
        XCTAssertEqual(sentMessage?["eventName"] as? String, testHostEvent.rawValue)
        XCTAssertNotNil(sentMessage?["eventId"] as? String, "eventId should be present")

        let payload = sentMessage?["payload"] as? [String: Any]
        XCTAssertNotNil(payload)
        XCTAssertEqual(payload?["buttonId"] as? String, "submit")
        XCTAssertEqual(payload?["count"] as? Int, 1)
    }
    
    
    func testOff_ListenerIsNotCalledAfterUnregistering() throws {
        let testEvent = EmbedEvent.AuthInit
        let testEventData: [String: Any] = ["action": "click"]

        let mockEmbedConfig = EmbedConfig(thoughtSpotHost: "https://genuine.com", authType: AuthType.TrustedAuthTokenCookieless)
        let mockLiveboardConfig = LiveboardViewConfig()
        let mockViewConfig = SpecificViewConfig.liveboard(mockLiveboardConfig)
        baseEmbed = BaseEmbedController(embedConfig: mockEmbedConfig, viewConfig: mockViewConfig, embedType: "liveboard")

        var listenerWasCalled = false
        let callback: BaseEmbedController.EventCallback = { _ in
            listenerWasCalled = true
        }

        baseEmbed.on(event: testEvent, callback: callback)

        baseEmbed.off(event: testEvent)

        let messagePayload: [String: Any] = [
            "type": "EMBED_EVENT",
            "eventName": testEvent.rawValue,
            "data": testEventData
        ]
        let jsonString = try! String(data: JSONSerialization.data(withJSONObject: messagePayload), encoding: .utf8)!
        let mockMessage = MockScriptMessage(body: jsonString)

        baseEmbed.userContentController(WKUserContentController(), didReceive: mockMessage)

        XCTAssertFalse(listenerWasCalled, "Listener should NOT have been called after 'off' was used.")
    }

    func testOn_MultipleListenersAreCalled() throws {
        let expectation = XCTestExpectation(description: "Both listeners should be called")
        expectation.expectedFulfillmentCount = 2

        let testEvent = EmbedEvent.AuthInit
        let testEventData: [String: Any] = ["status": "multiple"]

        let mockEmbedConfig = EmbedConfig(thoughtSpotHost: "https://genuine.com", authType: AuthType.TrustedAuthTokenCookieless)
        let mockLiveboardConfig = LiveboardViewConfig()
        let mockViewConfig = SpecificViewConfig.liveboard(mockLiveboardConfig)
        baseEmbed = BaseEmbedController(embedConfig: mockEmbedConfig, viewConfig: mockViewConfig, embedType: "liveboard")

        baseEmbed.on(event: testEvent) { _ in
            print("Listener 1 called")
            expectation.fulfill()
        }

        baseEmbed.on(event: testEvent) { _ in
             print("Listener 2 called")
            expectation.fulfill()
        }

        let messagePayload: [String: Any] = ["type": "EMBED_EVENT", "eventName": testEvent.rawValue, "data": testEventData]
        let jsonString = try! String(data: JSONSerialization.data(withJSONObject: messagePayload), encoding: .utf8)!
        let mockMessage = MockScriptMessage(body: jsonString)

        baseEmbed.userContentController(WKUserContentController(), didReceive: mockMessage)

        wait(for: [expectation], timeout: 0.5)
    }
}
