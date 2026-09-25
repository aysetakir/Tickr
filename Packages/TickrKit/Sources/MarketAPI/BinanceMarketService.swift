import Courier
import Foundation
import MarketCore

public struct BinanceMarketService: MarketDataService {
    private let client: any HTTPClientProtocol

    public init(client: any HTTPClientProtocol = HTTPClient()) {
        self.client = client
    }

    public func tradingPairs() async throws -> [TradingPair] {
        let dto: ExchangeInfoDTO = try await client.send(BinanceEndpoint.exchangeInfo)
        return dto.tradingPairs
    }

    public func tickers(for symbols: [String]) async throws -> [Ticker] {
        guard !symbols.isEmpty else { return [] }

        let dtos: [TickerDTO] = try await client.send(BinanceEndpoint.ticker24h(symbols: symbols))
        return dtos.map(\.ticker)
    }

    public func candles(for symbol: String, range: ChartRange) async throws -> [Candle] {
        let dtos: [KlineDTO] = try await client.send(
            BinanceEndpoint.klines(
                symbol: symbol,
                interval: range.interval,
                limit: range.candleCount
            )
        )
        return dtos.map(\.candle)
    }
}
