import Courier
import Foundation
import MarketCore
import Testing

@testable import MarketAPI

/// Servisin işi: doğru uca gitmek ve DTO'yu modele çevirmek. İkisi de
/// ağa çıkmadan, `StubHTTPClient` ile test ediliyor.
@Suite struct BinanceMarketServiceTests {

    // MARK: - tickers

    @Test func tickersMapsResponseToDomainModels() async throws {
        let client = StubHTTPClient(responding: try Fixture.data("ticker24hr"))
        let service = BinanceMarketService(client: client)

        let tickers = try await service.tickers(for: ["BTCUSDT", "ETHUSDT"])

        #expect(tickers.map(\.symbol) == ["BTCUSDT", "ETHUSDT"])
        #expect(await client.requestedURLs == [
            "https://api.binance.com/api/v3/ticker/24hr?symbols=%5B%22BTCUSDT%22,%22ETHUSDT%22%5D"
        ])
    }

    /// Watchlist boşken ekran açılışında gereksiz istek atılmasın — üstelik
    /// Binance `symbols=[]` çağrısına hata döndürüyor.
    @Test func tickersSkipsRequestForEmptySymbolList() async throws {
        let client = StubHTTPClient { _ in
            Issue.record("Boş listede ağa çıkılmamalıydı")
            return Data()
        }
        let service = BinanceMarketService(client: client)

        #expect(try await service.tickers(for: []).isEmpty)
        #expect(await client.requestedURLs.isEmpty)
    }

    // MARK: - candles

    /// "Hangi aralık kaç mum" kararı `ChartRange`'de (MarketCore) duruyor.
    /// Servis onu olduğu gibi uca taşıyor, kendi kopyasını tutmuyor.
    @Test(arguments: ChartRange.allCases)
    func candlesUsesIntervalAndCountFromRange(range: ChartRange) async throws {
        let client = StubHTTPClient(responding: try Fixture.data("klines"))
        let service = BinanceMarketService(client: client)

        _ = try await service.candles(for: "BTCUSDT", range: range)

        #expect(await client.requestedURLs == [
            "https://api.binance.com/api/v3/klines"
                + "?symbol=BTCUSDT&interval=\(range.interval.rawValue)&limit=\(range.candleCount)"
        ])
    }

    @Test func candlesMapsResponseToDomainModels() async throws {
        let client = StubHTTPClient(responding: try Fixture.data("klines"))
        let service = BinanceMarketService(client: client)

        let candles = try await service.candles(for: "BTCUSDT", range: .week)

        #expect(candles.count == 3)
        #expect(candles.map(\.openTime) == candles.map(\.openTime).sorted())
        #expect(candles.first?.close == (try dec("83923.71")))
    }

    // MARK: - tradingPairs

    @Test func tradingPairsFiltersNonTradingSymbols() async throws {
        let client = StubHTTPClient(responding: try Fixture.data("exchangeInfo"))
        let service = BinanceMarketService(client: client)

        let pairs = try await service.tradingPairs()

        #expect(pairs.map(\.symbol) == ["ETHBTC", "BTCUSDT"])
        #expect(await client.requestedURLs == ["https://api.binance.com/api/v3/exchangeInfo"])
    }

    // MARK: - hatalar

    /// Servis hatayı yutmuyor. Yutsaydı (ör. boş dizi dönseydi) ekran
    /// "hiç coin yok" derdi; oysa doğru mesaj "bağlanamadım, tekrar dene".
    @Test func propagatesTransportErrors() async throws {
        let client = StubHTTPClient(failingWith: NetworkError.transport(URLError(.notConnectedToInternet)))
        let service = BinanceMarketService(client: client)

        await #expect(throws: NetworkError.self) {
            try await service.tickers(for: ["BTCUSDT"])
        }
    }

    /// Bozuk gövde `NetworkError.decoding(_, raw:)` olarak çıkıyor: ham veri
    /// hatanın içinde kalıyor, çünkü böyle bir hatayı ayıklamanın tek yolu
    /// sunucunun tam olarak ne gönderdiğini görmek.
    @Test func surfacesDecodingErrorWithRawBody() async throws {
        let broken = Data(#"[{"symbol":"BTCUSDT","lastPrice":"n/a"}]"#.utf8)
        let client = StubHTTPClient(responding: broken)
        let service = BinanceMarketService(client: client)

        do {
            _ = try await service.tickers(for: ["BTCUSDT"])
            Issue.record("Hata bekleniyordu")
        } catch let error as NetworkError {
            guard case .decoding(_, let raw) = error else {
                Issue.record("Beklenen .decoding, gelen \(error)")
                return
            }
            #expect(raw == broken)
        }
    }
}
