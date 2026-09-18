import Foundation

/// Uygulamanın REST tarafından istediği her şey.
///
/// Feature modülleri (watchlist, detay ekranı) Binance'i de Courier'i de
/// bilmez, sadece bu protokolü bilir. Bunun iki faydası var:
/// - **Test:** ViewModel testlerinde gerçek ağa gitmeden sahte bir
///   `MarketDataService` verirsin. "API hata dönerse ekran ne gösteriyor?"
///   durumunu tek satırla kurarsın.
/// - **Kaynak değişimi:** Yarın Binance yerine başka bir borsa (ya da hisse
///   senedi API'si) kullanmak istersen yeni bir implementasyon yazarsın,
///   ekranlara dokunmazsın.
///
/// Gerçek implementasyon MarketAPI modülünde, Courier ile yazılacak.
///
/// `Sendable`, çünkü aynı servis birden fazla `Task`'tan aynı anda
/// çağrılacak (watchlist yenilenirken kullanıcı detay ekranını açabilir).
public protocol MarketDataService: Sendable {
    /// İşlem yapılabilen tüm çiftler. Coin arama ekranında kullanılacak.
    func tradingPairs() async throws -> [TradingPair]

    /// Verilen sembollerin 24 saatlik özeti. Watchlist ilk açıldığında
    /// WebSocket bağlanana kadar ekranı doldurmak için.
    func tickers(for symbols: [String]) async throws -> [Ticker]

    /// Grafik için geçmiş mumlar, eskiden yeniye sıralı.
    func candles(for symbol: String, range: ChartRange) async throws -> [Candle]
}
