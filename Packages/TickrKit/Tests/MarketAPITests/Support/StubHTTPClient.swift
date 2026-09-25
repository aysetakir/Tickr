import Courier
import Foundation

/// Ağa çıkmayan sahte `HTTPClientProtocol`.
///
/// `BinanceMarketService`'i `HTTPClient` yerine bununla kurunca iki şeyi
/// birden yapabiliyoruz:
/// - **Kayıt:** servis hangi uca gitti? (`requestedURLs`)
/// - **Kontrol:** sunucu ne döndürsün? (`handler`)
///
/// `actor`, çünkü `HTTPClientProtocol: Sendable` ve içeride değişen bir
/// dizi tutuyoruz. Protokolün metotları zaten `async`, o yüzden actor
/// olması çağıran tarafta hiçbir şeyi değiştirmiyor.
actor StubHTTPClient: HTTPClientProtocol {
    /// Servisin gittiği adresler, çağrı sırasıyla.
    ///
    /// `BinanceEndpoint` case'lerini değil URL'leri karşılaştırıyoruz:
    /// sunucunun gördüğü şey bu. Enum'u eşleseydik, `queryItems`'ta bir
    /// hata yapıldığında test yine geçerdi.
    private(set) var requestedURLs: [String] = []

    private let handler: @Sendable (any Endpoint) throws -> Data

    init(handler: @escaping @Sendable (any Endpoint) throws -> Data) {
        self.handler = handler
    }

    /// Hangi uca gidildiğinden bağımsız olarak hep aynı gövdeyi döndürür.
    init(responding data: Data) {
        self.handler = { _ in data }
    }

    /// Ne istenirse istensin hata fırlatır.
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
            // Gerçek `HTTPClient` de decode hatasını böyle sarıyor. Servisin
            // hatasına bakan bir kod varsa testte de aynısını görsün.
            throw NetworkError.decoding(error, raw: data)
        }
    }
}
