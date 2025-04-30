# ThoughtSpot Swift Embed SDK

ThoughtSpot Swift Embed SDK enables developers to seamlessly integrate ThoughtSpot into iOS applications. This SDK provides native Swift components to embed ThoughtSpot Liveboards and visualizations.

[![Swift](https://img.shields.io/badge/Swift-5.5+-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-14.0+-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-ThoughtSpot_EULA-green.svg)](https://www.thoughtspot.com/legal/thoughtspot-eula)

## Table of Contents

- [Installation](#installation)
- [Getting Started](#getting-started)
- [Authentication](#authentication)
- [Embedding Liveboards](#embedding-liveboards)
- [Event Handling](#event-handling)
- [Customization](#customization)
- [Host Events](#host-events)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Installation

### Swift Package Manager

The ThoughtSpot Swift Embed SDK can be installed using Swift Package Manager. In Xcode, go to `File > Add Packages...` and enter the following URL:

```
https://github.com/thoughtspot/swift-embed-sdk.git
```

Alternatively, add the following dependency to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/thoughtspot/swift-embed-sdk.git", from: "x.y.z")
]
```
Check the tags published on github repo.

## Getting Started

To begin using the SDK, first import the module in your Swift files:

```swift
import SwiftUI
import SwiftEmbedSDK
import Combine
```

## Authentication

The SDK supports authentication using the TrustedAuthTokenCookieless method. You'll need to implement a function to fetch the authentication token.

### Example Authentication Token Fetcher

You can provide your own Backend api call. This is just an example.
```swift
func fetchAuthToken(username: String, secretKey: String, host: String) async -> String? {
    let urlString = "\(host)/api/rest/2.0/auth/token/full"
    guard let url = URL(string: urlString) else {
        print("Error: Invalid URL: \(urlString)")
        return nil
    }
    
    let headers: [String: String] = [
        "Accept": "application/json",
        "Content-Type": "application/json"
    ]
    
    let body: [String: Any] = [
        "username": username,
        "validity_time_in_sec": 30,
        "auto_create": false,
        "secret_key": secretKey
    ]
    
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            // Handle error response
            return nil
        }
        
        let decodedResponse = try JSONDecoder().decode(AuthTokenResponse.self, from: data)
        return decodedResponse.token
        
    } catch {
        print("Error fetching auth token: \(error)")
        return nil
    }
}
```

## Embedding Liveboards

### Setting Up Configuration

Configure your embed with necessary settings:

```swift
// 1. Create a static embed configuration
let staticEmbedConfig = EmbedConfig(
    thoughtSpotHost: "https://your-thoughtspot-instance.com",
    authType: AuthType.TrustedAuthTokenCookieless,
    customizations: customizationsObject // Optional customizations
)

// 2. Create a token provider function
func getAuthToken() -> Future<String, Error> {
    Future { promise in
        Task {
            if let token = await fetchAuthToken(username: username, secretKey: secretKey, host: thoughtSpotHost) {
                promise(.success(token))
            } else {
                promise(.failure(NSError(
                    domain: "AuthError", code: 1, 
                    userInfo: [NSLocalizedDescriptionKey: "Failed to fetch auth token"]
                )))
            }
        }
    }
}

// 3. Create the TS embed configuration
let tsEmbedConfig = TSEmbedConfig(
    embedConfig: staticEmbedConfig,
    getAuthToken: getAuthToken,
)

// 4. Configure the Liveboard view
let liveboardViewConfig = LiveboardViewConfig(
    liveboardId: "your-liveboard-id"
)

// 5. Create the controller
let liveboardController = LiveboardEmbedController(
    tsEmbedConfig: tsEmbedConfig,
    viewConfig: liveboardViewConfig
)
```

### Embedding in SwiftUI

Here's a basic example of embedding a Liveboard in SwiftUI with Embed & HostEvents support:

```swift
struct LiveboardView: View {
    @StateObject var liveboardController: LiveboardEmbedController
    
    var body: some View {
        VStack {
            LiveboardEmbed(controller: liveboardController)
                .frame(height: 600)
                .cornerRadius(12)
                .onAppear {
                    registerEventListeners()
                }
            
            // Add custom UI controls if needed
            HStack {
                Button("Reload") {
                    liveboardController.trigger(event: HostEvent.Reload)
                }
                
                Button("Share") {
                    liveboardController.trigger(event: HostEvent.Share)
                }
            }
        }
        .padding()
    }
    // just an example function. you can directly add it in the .onAppear block
    func registerEventListeners() {
        // Register event listeners here
    }
}
```

## Event Handling

The SDK allows you to listen for events emitted by the embedded ThoughtSpot content:

```swift
func registerSDKListeners() {
    // Listen for authentication initialization
    liveboardController.on(event: EmbedEvent.AuthInit) { payload in
        print("Authentication initialized. Payload: \(payload ?? "nil")")
    }
    
    // Listen for Liveboard rendering completion
    liveboardController.on(event: EmbedEvent.LiveboardRendered) { payload in
        print("Liveboard rendered. Payload: \(payload ?? "nil")")
    }
    
    // Listen for errors
    liveboardController.on(event: EmbedEvent.Error) { payload in
        print("Error occurred. Payload: \(payload ?? "nil")")
    }
    
    // To remove a listener (removes all for the specified event)
    // liveboardController.off(event: EmbedEvent.AuthInit)
}
```

## Customization

You can customize the appearance of embedded ThoughtSpot content:

```swift
// Define custom CSS variables
let cssVariablesDict: [String: String] = [
    "--ts-var-root-background": "#fef4dd",
    "--ts-var-root-color": "#4a4a4a",
    "--ts-var-viz-title-color": "#8e6b23",
    "--ts-var-viz-title-font-family": "'Georgia', 'Times New Roman', serif",
    "--ts-var-viz-title-text-transform": "capitalize",
    "--ts-var-viz-description-color": "#6b705c",
    "--ts-var-viz-description-font-family": "'Verdana', 'Helvetica', sans-serif",
    "--ts-var-viz-border-radius": "6px",
    "--ts-var-viz-box-shadow": "0 3px 6px rgba(0, 0, 0, 0.15)",
    "--ts-var-viz-background": "#fffbf0",
    "--ts-var-viz-legend-hover-background": "#ffe4b5"
]

// Create custom CSS interface
let customCSSObject = customCssInterface(variables: cssVariablesDict)

// Create custom styles object
let styleObject = CustomStyles(
    customCSSUrl: "https://cdn.jsdelivr.net/gh/thoughtspot/custom-css-demo/css-variables.css", // Optional
    customCSS: customCSSObject
)

// Create customizations interface
let customizationsObject = CustomisationsInterface(
    style: styleObject
)

// Include customizations in your EmbedConfig
let embedConfig = EmbedConfig(
    thoughtSpotHost: thoughtSpotHost,
    authType: .TrustedAuthTokenCookieless,
    customizations: customizationsObject
)
```

## Host Events

You can trigger actions on the embedded ThoughtSpot content:

```swift
// Reload the Liveboard
liveboardController.trigger(event: HostEvent.Reload)

// Open the Share dialog
liveboardController.trigger(event: HostEvent.Share)

// Apply runtime filters
let filters = [
    RuntimeFilter(columnName: "Region", operator: .EQ, values: ["East", "West"])
]
liveboardController.trigger(event: HostEvent.UpdateRuntimeFilters, payload: filters)
```

## Complete Example

Here's a more complete SwiftUI example:

```swift
struct HomeView: View {
    var username: String
    var thoughtSpotHost: String
    var liveboardId: String
    var secretKey: String
    
    @StateObject var liveboardController: LiveboardEmbedController
    
    init(username: String, thoughtSpotHost: String, liveboardId: String, secretKey: String) {
        self.username = username
        self.thoughtSpotHost = thoughtSpotHost
        self.liveboardId = liveboardId
        self.secretKey = secretKey
        
        // Set up custom styling
        let customizationsObject = createCustomizations()
        
        // Create embed configuration
        let staticEmbedConfig = EmbedConfig(
            thoughtSpotHost: thoughtSpotHost,
            authType: AuthType.TrustedAuthTokenCookieless,
            customizations: customizationsObject
        )
        
        // Set up auth token provider
        func getAuthToken() -> Future<String, Error> {
            Future { promise in
                Task {
                    if let token = await fetchAuthToken(username: username, secretKey: secretKey, host: thoughtSpotHost) {
                        promise(.success(token))
                    } else {
                        promise(.failure(NSError(
                            domain: "AuthError", code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to fetch auth token"]
                        )))
                    }
                }
            }
        }
        
        // Create TS embed config
        let tsEmbedConfig = TSEmbedConfig(
            embedConfig: staticEmbedConfig,
            getAuthToken: getAuthToken,
            initializationCompletion: { result in
                // Handle initialization result
            }
        )
        
        // Configure Liveboard view
        let liveboardViewConfig = LiveboardViewConfig(
            liveboardId: liveboardId
        )
        
        // Create controller
        _liveboardController = StateObject(wrappedValue: LiveboardEmbedController(
            tsEmbedConfig: tsEmbedConfig,
            viewConfig: liveboardViewConfig
        ))
    }
    
    var body: some View {
        VStack {
            LiveboardEmbed(controller: liveboardController)
                .frame(height: 600)
                .cornerRadius(12)
                .onAppear {
                    registerSDKListeners()
                }
            
            HStack {
                Button {
                    liveboardController.trigger(event: HostEvent.Reload)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                
                Button {
                    liveboardController.trigger(event: HostEvent.Share)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .padding()
    }
    
    func registerSDKListeners() {
        liveboardController.on(event: EmbedEvent.AuthInit) { payload in
            print("Authentication initialized")
        }
        
        liveboardController.on(event: EmbedEvent.LiveboardRendered) { payload in
            print("Liveboard rendered")
        }
        
        liveboardController.on(event: EmbedEvent.Error) { payload in
            print("Error occurred")
        }
    }
    
    func createCustomizations() -> CustomisationsInterface {
        let cssVariablesDict: [String: String] = [
            "--ts-var-root-background": "#fef4dd",
            "--ts-var-root-color": "#4a4a4a",
            "--ts-var-viz-title-color": "#8e6b23"
        ]
        
        let customCSSObject = customCssInterface(variables: cssVariablesDict)
        let styleObject = CustomStyles(customCSS: customCSSObject)
        
        return CustomisationsInterface(style: styleObject)
    }
}
```

## Troubleshooting

### Common Issues

1. **Authentication Failures**
   - Ensure your ThoughtSpot host URL is correct and accessible
   - Verify that authentication credentials are valid
   - Check that your app has proper network permissions

2. **Content Not Loading**
   - Verify the Liveboard ID is correct
   - Use the EmbedEvent.Error listener to catch and log errors

3. **Rendering Problems**
   - Try adjusting the frame size constraints
   - Check for custom CSS conflicts
   - Register event listeners to track loading progress

## License

The ThoughtSpot Swift Embed SDK is licensed under the ThoughtSpot Development Tools End User License Agreement. See the LICENSE.md file for details.
