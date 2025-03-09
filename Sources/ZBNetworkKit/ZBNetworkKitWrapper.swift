// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftUI
import Combine

@propertyWrapper
public struct ApiRequest<T: Decodable>: DynamicProperty {
    @State private var data: T?
    @State private var isLoadingState: Bool = false
    @State private var errorState: ZBAPIError?
    
    private let endpoint: any ZBEndpointProvider
    private let client: ZBNetworkClientProtocol
    // Combine publisher for UIKit
    private let subject = PassthroughSubject<(Result<T, ZBAPIError>), Never>()

    public var wrappedValue: T? {
        self.data
    }
    
    public var projectedValue: ApiRequest {
        self
    }
    
    public init(
        endpoint: some ZBEndpointProvider,
        client: ZBNetworkClientProtocol = ZBHttpClient()
    ) {
        self.endpoint = endpoint
        self.client = client
    }
    
    public func fetch() async {
        guard !isLoadingState else { return }
        
        self.isLoadingState = true
        
        do {
            let result = try await client.asyncRequest(
                endpoint: endpoint,
                responseModel: T.self
            )
            self.data = result
            self.errorState = nil
            self.subject.send(.success(result))
        } catch let error as ZBAPIError {
            self.errorState = error
            self.data = nil
            self.subject.send(.failure(error))
        } catch {
            self.errorState = error as? ZBAPIError
            self.data = nil
            self.subject.send(.failure(errorState!))
        }
        
        self.isLoadingState = false
    }
    
    public var isLoading: Bool {
        self.isLoadingState
    }
    
    public var error: ZBAPIError? {
        self.errorState
    }
    
    public func publisher() -> AnyPublisher<Result<T, ZBAPIError>, Never> {
        self.subject.eraseToAnyPublisher()
    }
}

// DownloadRequest for file downloads
@propertyWrapper
struct DownloadRequest: DynamicProperty {
    // State for SwiftUI
    @State private var data: Data?
    @State private var isLoadingState: Bool = false
    @State private var errorState: ZBAPIError?
    
    // Combine publisher for UIKit
    private let subject = PassthroughSubject<Result<Data, ZBAPIError>, Never>()
    
    private let endpoint: any ZBEndpointProvider
    private let client: ZBNetworkClientProtocol
    
    var wrappedValue: Data? {
        self.data
    }
    
    var projectedValue: DownloadRequest {
        self
    }
    
    init(
        endpoint: some ZBEndpointProvider,
        client: ZBNetworkClientProtocol = ZBHttpClient()
    ) {
        self.endpoint = endpoint
        self.client = client
    }
    
    func fetch() async {
        guard !isLoadingState else { return }
        
        self.isLoadingState = true
        
        do {
            let result = try await client.downloadFile(endpoint: endpoint)
            self.data = result
            self.errorState = nil
            self.subject.send(.success(result)) // Notify UIKit subscribers
        } catch let error as ZBAPIError {
            self.errorState = error
            self.data = nil
            self.subject.send(.failure(error)) // Notify UIKit subscribers
        } catch {
            self.errorState = error as? ZBAPIError
            self.data = nil
            self.subject.send(.failure(errorState!)) // Notify UIKit subscribers
        }
        
        self.isLoadingState = false
    }
    
    // For SwiftUI
    var isLoading: Bool {
        self.isLoadingState
    }
    
    // For SwiftUI
    var error: ZBAPIError? {
        self.errorState
    }
    
    // For UIKit
    func publisher() -> AnyPublisher<Result<Data, ZBAPIError>, Never> {
        self.subject.eraseToAnyPublisher()
    }
}

// UploadRequest for file uploads

@propertyWrapper
struct UploadRequest<T: Decodable>: DynamicProperty {
    // State for SwiftUI
    @State private var data: T?
    @State private var isLoadingState: Bool = false
    @State private var errorState: ZBAPIError?
    
    // Combine publisher for UIKit
    private let subject = PassthroughSubject<Result<T, ZBAPIError>, Never>()
    
    private let endpoint: any ZBEndpointProvider
    private let client: ZBNetworkClientProtocol
    
    var wrappedValue: T? {
        self.data
    }
    
    var projectedValue: UploadRequest {
        self
    }
    
    init(
        endpoint: some ZBEndpointProvider,
        client: ZBNetworkClientProtocol = ZBHttpClient()
    ) {
        self.endpoint = endpoint
        self.client = client
    }
    
    func fetch() async {
        guard !isLoadingState else { return }
        
        self.isLoadingState = true
        
        do {
            let result = try await client.asyncUpload(
                endpoint: endpoint,
                responseModel: T.self
            )
            self.data = result
            self.errorState = nil
            self.subject.send(.success(result)) // Notify UIKit subscribers
        } catch let error as ZBAPIError {
            self.errorState = error
            self.data = nil
            self.subject.send(.failure(error)) // Notify UIKit subscribers
        } catch {
            self.errorState = error as? ZBAPIError
            self.data = nil
            self.subject.send(.failure(errorState!)) // Notify UIKit subscribers
        }
        
        self.isLoadingState = false
    }
    
    // For SwiftUI
    var isLoading: Bool {
        self.isLoadingState
    }
    
    // For SwiftUI
    var error: ZBAPIError? {
        self.errorState
    }
    
    // For UIKit
    func publisher() -> AnyPublisher<Result<T, ZBAPIError>, Never> {
        self.subject.eraseToAnyPublisher()
    }
}
