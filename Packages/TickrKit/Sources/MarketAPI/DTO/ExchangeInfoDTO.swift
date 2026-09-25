import Foundation
import MarketCore

struct ExchangeInfoDTO: Decodable {
    let symbols: [SymbolDTO]

    struct SymbolDTO: Decodable {
        let symbol: String
        let baseAsset: String
        let quoteAsset: String
        let status: String
    }
}

extension ExchangeInfoDTO {
    var tradingPairs: [TradingPair] {
        symbols.compactMap { dto in
            guard dto.status == "TRADING" else { return nil }
            let pair = TradingPair(baseAsset: dto.baseAsset, quoteAsset: dto.quoteAsset)
            guard pair.symbol == dto.symbol else { return nil }
            return pair
        }
    }
}
