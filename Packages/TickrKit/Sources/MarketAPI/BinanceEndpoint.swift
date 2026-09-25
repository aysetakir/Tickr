import Courier
import Foundation
import MarketCore

enum BinanceEndpoint: Endpoint {
    case exchangeInfo
    case ticker24h(symbols: [String])
    case klines(symbol: String, interval: CandleInterval, limit: Int)

    var baseURL: URL { Binance.restBaseURL }

    var path: String {
        switch self {
        case .exchangeInfo: "/api/v3/exchangeInfo"
        case .ticker24h:    "/api/v3/ticker/24hr"
        case .klines:       "/api/v3/klines"
        }
    }

    var requiresAuthentication: Bool { false }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .exchangeInfo:
            nil

        case .ticker24h(let symbols):
            [URLQueryItem(name: "symbols", value: jsonArrayLiteral(symbols))]

        case .klines(let symbol, let interval, let limit):
            [
                URLQueryItem(name: "symbol", value: symbol),
                URLQueryItem(name: "interval", value: interval.rawValue),
                URLQueryItem(name: "limit", value: String(limit)),
            ]
        }
    }
}

private func jsonArrayLiteral(_ values: [String]) -> String {
    "[" + values.map { "\"\($0)\"" }.joined(separator: ",") + "]"
}
