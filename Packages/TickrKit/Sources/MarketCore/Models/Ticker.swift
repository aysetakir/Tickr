import Foundation

/// Bir çiftin anlık piyasa özeti: watchlist satırında görünen her şey.
///
/// İki kaynaktan beslenir:
/// 1. Açılışta REST (`/api/v3/ticker/24hr`) ile ilk değer gelir, ekran boş kalmaz.
/// 2. Sonra WebSocket (`<symbol>@miniTicker`) ile saniyede bir güncellenir.
///
/// Model hangi kaynaktan geldiğini bilmez. Binance JSON'ını `Ticker`'a çevirmek
/// MarketAPI'nin ve MarketStream'in işi.
///
/// Fiyatlar `Double` değil `Decimal`: `0.1 + 0.2` `Double`'da
/// `0.30000000000000004` eder. "Fiyat 60.000'e eşit mi, üstünde mi?"
/// sorusunun cevabı buna bağlı olduğunda (alarm), yuvarlama hatası bug demektir.
/// Binance fiyatları zaten string olarak gönderiyor (`"63250.12000000"`), yani
/// `Decimal(string:)` ile kayıpsız çevrilebilir.
public struct Ticker: Hashable, Codable, Sendable, Identifiable {
    /// Hangi çifte ait, ör. `"BTCUSDT"`.
    public let symbol: String

    /// Son işlem fiyatı.
    public let lastPrice: Decimal

    /// 24 saat önceki fiyat. Değişim yüzdesi buradan hesaplanır.
    public let openPrice: Decimal

    /// Son 24 saatin en yüksek ve en düşük fiyatı.
    public let highPrice: Decimal
    public let lowPrice: Decimal

    /// Son 24 saatte quote cinsinden hacim (USDT'de ne kadar işlem döndü).
    public let quoteVolume: Decimal

    /// Bu verinin borsadaki zamanı.
    ///
    /// Cihazın saati değil, borsanınki. WebSocket bağlantısı kopup yeniden
    /// bağlandığında eski bir mesaj yenisinin üstüne yazılmasın diye bu
    /// alana bakıp sıralayabilirsin.
    public let updatedAt: Date

    public var id: String { symbol }

    public init(
        symbol: String,
        lastPrice: Decimal,
        openPrice: Decimal,
        highPrice: Decimal,
        lowPrice: Decimal,
        quoteVolume: Decimal,
        updatedAt: Date
    ) {
        self.symbol = symbol
        self.lastPrice = lastPrice
        self.openPrice = openPrice
        self.highPrice = highPrice
        self.lowPrice = lowPrice
        self.quoteVolume = quoteVolume
        self.updatedAt = updatedAt
    }

    /// 24 saatlik mutlak değişim, ör. `+1250.50`.
    public var priceChange: Decimal { lastPrice - openPrice }

    /// 24 saatlik yüzde değişim, ör. `2.5` (yani %2,5).
    ///
    /// Neden hazır gelen alanı kullanmıyoruz? REST `priceChangePercent`
    /// veriyor ama `miniTicker` stream'i vermiyor. İkisi de `openPrice`
    /// verdiği için yüzdeyi tek bir yerde kendimiz hesaplıyoruz. Böylece
    /// değer hangi kaynaktan geldiğine göre değişmiyor.
    public var priceChangePercent: Decimal {
        // Sıfıra bölme olmasın. Yeni listelenmiş bir coin'de openPrice 0 gelebilir.
        guard openPrice != 0 else { return 0 }
        return (lastPrice - openPrice) / openPrice * 100
    }

    /// Satırı yeşil mi kırmızı mı boyayacağız?
    public var isUp: Bool { lastPrice >= openPrice }
}
