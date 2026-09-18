import Foundation

/// Bir işlem çifti: hangi varlığın, hangi varlık cinsinden fiyatlandığı.
///
/// Borsada "BTC"nin tek başına bir fiyatı yoktur. "BTCUSDT" demek "1 BTC kaç
/// USDT eder" demektir. Uygulamada bir coin'i temsil eden kimlik budur:
/// watchlist, grafik, alarm ve WebSocket aboneliği hep `symbol` üzerinden
/// konuşur.
public struct TradingPair: Hashable, Codable, Sendable, Identifiable {
    /// Borsanın kullandığı birleşik sembol, ör. `"BTCUSDT"`.
    ///
    /// Büyük harfle tutuluyor çünkü REST böyle bekliyor. WebSocket stream
    /// adları ise küçük harf ister (`"btcusdt@miniTicker"`); o dönüşüm
    /// MarketStream'in işi, model bunu bilmez.
    public let symbol: String

    /// Fiyatı sorulan varlık, ör. `"BTC"`.
    public let baseAsset: String

    /// Fiyatın ifade edildiği varlık, ör. `"USDT"`.
    public let quoteAsset: String

    /// `ForEach` ve `List` için. Aynı sembol iki kez olamayacağı için
    /// ayrı bir UUID'ye gerek yok.
    public var id: String { symbol }

    /// `symbol` elle verilmiyor, parçalardan üretiliyor. Böylece
    /// `baseAsset: "BTC", symbol: "ETHUSDT"` gibi tutarsız bir çift
    /// oluşturulamaz.
    public init(baseAsset: String, quoteAsset: String) {
        self.baseAsset = baseAsset.uppercased()
        self.quoteAsset = quoteAsset.uppercased()
        self.symbol = self.baseAsset + self.quoteAsset
    }

    /// Ekranda gösterilecek hali, ör. `"BTC/USDT"`.
    public var displayName: String { "\(baseAsset)/\(quoteAsset)" }
}
