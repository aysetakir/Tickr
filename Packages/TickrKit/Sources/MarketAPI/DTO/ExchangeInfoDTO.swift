import Foundation
import MarketCore

/// `/api/v3/exchangeInfo` cevabı.
///
/// Gerçek cevap devasa (~3000 çift, her birinde emir tipleri, filtreler,
/// izin grupları…). Burada sadece üç alan tanımlı; `Decodable` tanımadığı
/// anahtarları zaten atlar. Yani bu DTO aynı zamanda bir filtre: cevabın
/// hangi kısmına bağımlı olduğumuz tek bakışta görünüyor.
struct ExchangeInfoDTO: Decodable {
    let symbols: [SymbolDTO]

    struct SymbolDTO: Decodable {
        let symbol: String
        let baseAsset: String
        let quoteAsset: String
        /// `"TRADING"`, `"HALT"`, `"BREAK"`… İşlem görmeyen çiftleri
        /// listelemek istemiyoruz: kullanıcı ekleyebilse bile fiyat akmaz.
        let status: String
    }
}

extension ExchangeInfoDTO {
    /// İşlem gören çiftler.
    ///
    /// `TradingPair` sembolü `baseAsset + quoteAsset`'ten kendisi üretiyor,
    /// biz de öyle kuruyoruz. Binance'in gönderdiği `symbol` alanını
    /// kullanmıyoruz ama boşuna okumuyoruz: aşağıdaki kontrol, ikisinin
    /// ayrıştığı egzotik bir çift çıkarsa onu sessizce yanlış göstermek
    /// yerine listeden düşürüyor.
    var tradingPairs: [TradingPair] {
        symbols.compactMap { dto in
            guard dto.status == "TRADING" else { return nil }
            let pair = TradingPair(baseAsset: dto.baseAsset, quoteAsset: dto.quoteAsset)
            guard pair.symbol == dto.symbol else { return nil }
            return pair
        }
    }
}
