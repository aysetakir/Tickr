import Courier
import Foundation
import MarketCore
import Testing

@testable import MarketAPI

@Suite struct BinanceEndpointTests {
    private func url(_ endpoint: BinanceEndpoint) throws -> String {
        try #require(endpoint.makeURLRequest().url?.absoluteString)
    }

    @Test func exchangeInfoNeedsNoQuery() throws {
        #expect(try url(.exchangeInfo) == "https://api.binance.com/api/v3/exchangeInfo")
    }

    @Test func ticker24hEncodesSymbolsAsJSONArray() throws {
        #expect(try url(.ticker24h(symbols: ["BTCUSDT", "ETHUSDT"]))
            == "https://api.binance.com/api/v3/ticker/24hr?symbols=%5B%22BTCUSDT%22,%22ETHUSDT%22%5D")
    }

    @Test func klinesCarriesSymbolIntervalAndLimit() throws {
        #expect(try url(.klines(symbol: "BTCUSDT", interval: .oneHour, limit: 168))
            == "https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1h&limit=168")
    }

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
