import Courier
import Foundation
import MarketCore
import Testing

@testable import MarketAPI

/// Uçların ürettiği URL'ler. Burada test edilen şey "kod derleniyor mu"
/// değil, "sunucunun beklediği adresi mi kuruyoruz": adreslerin hepsi
/// tarayıcıda açılıp doğrulandı, bu testler onları yerinde tutuyor.
@Suite struct BinanceEndpointTests {
    private func url(_ endpoint: BinanceEndpoint) throws -> String {
        try #require(endpoint.makeURLRequest().url?.absoluteString)
    }

    @Test func exchangeInfoNeedsNoQuery() throws {
        // Boş `queryItems` adresin sonuna çıplak bir "?" yapıştırmamalı.
        #expect(try url(.exchangeInfo) == "https://api.binance.com/api/v3/exchangeInfo")
    }

    /// Binance `symbols`'ü standart liste olarak (`symbols=A&symbols=B`)
    /// kabul etmiyor; tek parametrede, boşluksuz JSON dizisi istiyor.
    /// `%5B` = `[`, `%22` = `"`, `%5D` = `]`.
    @Test func ticker24hEncodesSymbolsAsJSONArray() throws {
        #expect(try url(.ticker24h(symbols: ["BTCUSDT", "ETHUSDT"]))
            == "https://api.binance.com/api/v3/ticker/24hr?symbols=%5B%22BTCUSDT%22,%22ETHUSDT%22%5D")
    }

    @Test func klinesCarriesSymbolIntervalAndLimit() throws {
        #expect(try url(.klines(symbol: "BTCUSDT", interval: .oneHour, limit: 168))
            == "https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1h&limit=168")
    }

    /// Courier'de varsayılan `true`. Ezmeyi unutsaydık `AuthInterceptor`
    /// olmayan bir token'ı aramaya kalkardı; Binance'in açık uçları
    /// anahtar istemiyor.
    @Test(arguments: [
        BinanceEndpoint.exchangeInfo,
        .ticker24h(symbols: ["BTCUSDT"]),
        .klines(symbol: "BTCUSDT", interval: .oneMinute, limit: 1),
    ])
    func endpointsAreUnauthenticated(endpoint: BinanceEndpoint) {
        #expect(endpoint.requiresAuthentication == false)
        #expect(endpoint.method == .get)
        #expect(endpoint.body == nil)
    }
}
