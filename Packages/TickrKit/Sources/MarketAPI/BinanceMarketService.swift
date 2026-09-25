import Courier
import Foundation
import MarketCore

/// `MarketDataService`'in Binance REST implementasyonu.
///
/// Bu tip, MarketAPI'nin dışarıya açtığı tek yüz. Endpoint'ler, DTO'lar ve
/// Courier bu modülün içinde kalıyor; uygulamanın geri kalanı sadece
/// `MarketDataService` protokolünü görüyor.
///
/// Sınıfın kendi yaptığı iş üç satır: uç seç, gönder, DTO'yu modele çevir.
/// Yeniden deneme, hata sınıflandırma ve decode Courier'in işi.
public struct BinanceMarketService: MarketDataService {
    private let client: any HTTPClientProtocol

    /// Somut `HTTPClient` değil protokol alıyoruz.
    ///
    /// Testte `MockURLProtocol`'lü bir `URLSession` de verebilirdik ama
    /// protokol sınırı daha ucuz: sahte bir client'la "sunucu bozuk JSON
    /// dönerse ne oluyor?" durumunu ağ yığınına hiç girmeden kurabiliyoruz.
    /// Varsayılan parametre sayesinde uygulama tarafında `BinanceMarketService()`
    /// yazmak yetiyor.
    public init(client: any HTTPClientProtocol = HTTPClient()) {
        self.client = client
    }

    public func tradingPairs() async throws -> [TradingPair] {
        let dto: ExchangeInfoDTO = try await client.send(BinanceEndpoint.exchangeInfo)
        return dto.tradingPairs
    }

    public func tickers(for symbols: [String]) async throws -> [Ticker] {
        // Boş listeyle çağrılırsa Binance hata döner (`symbols=[]`).
        // Ağa hiç çıkmadan cevaplamak hem doğru hem hızlı: watchlist boşken
        // ekran açılışında gereksiz bir istek atılmıyor.
        guard !symbols.isEmpty else { return [] }

        let dtos: [TickerDTO] = try await client.send(BinanceEndpoint.ticker24h(symbols: symbols))
        return dtos.map(\.ticker)
    }

    public func candles(for symbol: String, range: ChartRange) async throws -> [Candle] {
        // "Hangi aralık kaç mum" kararı `ChartRange`'de, MarketCore'da.
        // Burada tekrar edilmiyor; olsaydı grafik ile API iki ayrı yerde
        // ayrı şeye inanabilirdi.
        let dtos: [KlineDTO] = try await client.send(
            BinanceEndpoint.klines(
                symbol: symbol,
                interval: range.interval,
                limit: range.candleCount
            )
        )
        // Binance zaten eskiden yeniye sıralı gönderiyor; protokol de öyle
        // söz veriyor. Sıralamayı burada yeniden yapmıyoruz, çünkü sessizce
        // düzeltmek sunucunun sözünü bozduğunu gizlerdi — testte doğruluyoruz.
        return dtos.map(\.candle)
    }
}
