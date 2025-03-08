# ZBNetworkKit

ZBNetworkKitFramework is a lightweight, modern networking library for Swift, designed for iOS and macOS. Built with Swift’s `async/await` concurrency model, it provides a clean and flexible way to perform HTTP requests with customizable headers, interceptors, and SwiftUI integration.

## Features
- **Async/Await Support**: Modern concurrency for network calls.
- **Customizable Default Headers**: Headers applied to all requests.
- **Interceptors**: Custom logic for requests and responses.
- **Multipart Uploads**: Easy file uploads.
- **SwiftUI Integration**: Reactive networking with property wrappers.
- **Token Handling**: Built-in token management with refresh retry.

## Installation

### Swift Package Manager
Add `ZBNetworkKit` to your project via Swift Package Manager:

1. In Xcode, go to `File > Add Packages`.
2. Enter `https://github.com/zuhaibimtiaz/ZBNetworkKit.git`

Or add it directly to your `Package.swift`:

```swift
.package(url: "https://github.com/zuhaibimtiaz/ZBNetworkKit.git", from: "1.0.0")
```
## Configuration
### Usage
- Start by importing `ZBNetworkKiet`:
- Configure `ZBNetworkKit` with your `base URL`, `default headers`, and optional settings:
```swift
import ZBNetworkKitFramework

    ZBNetworkKit.configure(
        scheme: "https",
        baseURL: "api.myapp.com",,
        publicKeyHash: nil,
        refreshTokenEndpoint: nil,
        defaultHeaders: nil,
        globalInterceptors: nil,
        refreshTokenRetryCount: 0,
        defaultTimeout: 60,
        resourceTimeout: 90,
        isLogging: true
    )

```

## Token Handling
- Manage tokens with ZBNetworkKit:

```swift
// Set tokens after login
ZBNetworkKit.setToken(access: "your-access-token", refresh: "your-refresh-token")

// Clear tokens on logout
ZBNetworkKit.clearToken()
```

- Token Refresh: Add a refresh endpoint:
```swift
struct RefreshTokenEndpoint: ZBEndpointProvider {
    var path: String { "/refresh" }
    var method: ZBRequestMethod { .POST }
}

ZBNetworkKit.configure(
    baseURL: "api.myapp.com",
    refreshTokenEndpoint: RefreshTokenEndpoint(),
    refreshTokenRetryCount: 1
)
```

- Endpoints with accessTokenRequired: true (default false) include Bearer <access-token>.

## Using ZBHttpClient
### Basic Request

```swift
struct UserEndpoint: ZBEndpointProvider {
    var path: String { "/users/1" }
    var method: ZBRequestMethod { .GET }
}

let client = ZBHttpClient()
do {
    let user = try await client.asyncRequest(endpoint: UserEndpoint(), responseModel: User.self)
    print("User: \(user.name)")
} catch {
    print("Error: \(error.localizedDescription)")
}

struct User: Decodable {
    let id: Int
    let name: String
}
```
## Using Property Wrappers
- Use @ZBApiRequest for SwiftUI:
```swift
struct UserListView: View {
    @ApiRequest(endpoint: UserEndpoint()) private var users: [User]?
    
    var body: some View {
        VStack(spacing: 20) {
            if $users.isLoading {
                ProgressView("Loading users...")
            } else if let error = $users.error {
                Text("Users Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
            } else if let users = users {
                List(users, id: \.id) { user in
                    VStack(alignment: .leading) {
                        Text(user.name)
                            .font(.headline)
                        Text(user.email)
                            .font(.subheadline)
                    }
                }
            }
        }
        .task {
            await $users.fetch()
        }
    }
}

```
- user: Decoded response (User?).
- isLoading: true while fetching.
- error: ZBAPIError? if failed.
- fetch(): Starts the request.

## Using Interceptors
### Defining an Interceptor
```swift
struct CustomInterceptor: ZBInterceptor {
    func onRequest(_ request: inout URLRequest) {
        print("Request URL: \(request.url?.absoluteString ?? "")")
        request.setValue("custom-value", forHTTPHeaderField: "X-Custom")
    }
    
    func onResponse(_ data: Data?, _ response: URLResponse?, _ error: Error?) {
        if let httpResponse = response as? HTTPURLResponse {
            print("Response Status: \(httpResponse.statusCode)")
        }
    }
}
```
### Global Interceptor
```swift
ZBNetworkKit.configure(
    baseURL: "api.myapp.com",
    defaultHeaders: nil,
    globalInterceptors: [CustomInterceptor()]
)
```

### Endpoint-Specific Interceptor
```swift
struct UserEndpoint: ZBEndpointProvider {
    var path: String { "/users/1" }
    var method: ZBRequestMethod { .GET }
    var interceptors: [ZBInterceptor] { [CustomInterceptor()] }
}
```
- onRequest: Modifies the request before sending.
- onResponse: Processes the response after receiving.

## API Reference
### ZBNetworkKit
 
### Parameter Descriptions for `configure`
 Configure
- `configure(scheme:baseURL:publicKeyHash:refreshTokenEndpoint:defaultHeaders:globalInterceptors:refreshTokenRetryCount:defaultTimeout:resourceTimeout:isLogging:):`
- `setToken(access:refresh:)`: Set tokens.
- `clearToken()`: Clear tokens.

The `ZBNetworkKit.configure` method accepts the following parameters:

- **`scheme: String = "https"`**
  - URL scheme (protocol) for requests. Default is `"https"` for secure communication. Example: `"http"` for testing.

- **`baseURL: String`**
  - Required base URL for all API endpoints (e.g., `"https://api.myapp.com"`). No default—must be provided.

- **`publicKeyHash: String? = nil`**
  - Optional public key hash for SSL pinning to validate the server’s certificate. Default is `nil` (disabled). Example: `"sha256/abc123..."`.

- **`refreshTokenEndpoint: (any ZBEndpointProvider)? = nil`**
  - Optional endpoint for refreshing access tokens when they expire. Default is `nil` (no refresh). Example: `RefreshTokenEndpoint()`.

- **`defaultHeaders: [String: String]?`**
  - Optional headers applied to all requests. Default is `nil`. Example: `["client-id": "my-app-client-id"]`.

- **`globalInterceptors: [ZBInterceptor]?`**
  - Optional interceptors applied to all requests and responses. Default is `nil`. Example: `[ZBLoggingInterceptor()]`.

- **`refreshTokenRetryCount: Int = 0`**
  - Number of retries after token refresh on failure (e.g., 401). Default is `0` (no retries). Example: `2`.

- **`defaultTimeout: TimeInterval = 60`**
  - Timeout (seconds) for standard requests. Default is `60`. Example: `30`.

- **`resourceTimeout: TimeInterval = 90`**
  - Timeout (seconds) for resource-intensive requests (e.g., uploads). Default is `90`. Example: `120`.

- **`isLogging: Bool = true`**
  - Enables/disables built-in logging (e.g., cURL commands). Default is `true`. Example: `false` for production.


### ZBEndpointProvider

- `scheme`: https default
- `path`: Required path.
- `method`: HTTP method.
- `queryItems`: Pass [URLQueryItem] 
- `headers`: Custom headers.
- `parameters`: JSON dictionary.
- `encodedParams`: Encodable protocol.
- `multipart`: File uploads.
- `accessTokenRequired`: Bearer token (default: true).
- `timeoutInterval`: request timeout interval (default 60)
- `interceptors`: Per-endpoint interceptors.

### ZBHttpClient

- `asyncRequest(endpoint:responseModel:)`: Standard request.
- `asyncUpload(endpoint:responseModel:)`: Multipart upload.
- `downloadFile(endpoint:)`: Downloads raw `Data` from the specified endpoint, ideal for file

###ZBApiRequest

- `@ZBApiRequest(endpoint:)`: SwiftUI wrapper.

##Requirements
- iOS 13.0+
- Xcode 13+
- Swift 5.5+
