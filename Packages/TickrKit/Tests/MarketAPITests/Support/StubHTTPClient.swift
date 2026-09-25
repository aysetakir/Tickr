import Courier
import Foundation

actor StubHTTPClient: HTTPClientProtocol {
    private(set) var requestedURLs: [String] = []

    private let handler: @Sendable (any Endpoint) throws -> Data

    init(handler: @escaping @Sendable (any Endpoint) throws -> Data) {
        self.handler = handler
    }

    init(responding data: Data) {
        self.handler = { _ in data }
    }

    init(failingWith error: any Error) {
        self.handler = { _ in throw error }
    }

    func send(_ endpoint: any Endpoint) async throws -> Data {
        requestedURLs.append(try endpoint.makeURLRequest().url?.absoluteString ?? "")
        return try handler(endpoint)
    }

    func send<T: Decodable & Sendable>(_ endpoint: any Endpoint, as type: T.Type) async throws -> T {
        let data = try await send(endpoint)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decoding(error, raw: data)
        }
    }
}
