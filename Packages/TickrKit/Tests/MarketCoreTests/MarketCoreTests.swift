import Foundation
import Testing
@testable import MarketCore

struct TradingPairTests {
    @Test func symbolIsBuiltFromAssets() {
        let pair = TradingPair(baseAsset: "btc", quoteAsset: "usdt")

        #expect(pair.symbol == "BTCUSDT")
        #expect(pair.displayName == "BTC/USDT")
    }
}

struct TickerTests {
    private func ticker(last: Decimal, open: Decimal) -> Ticker {
        Ticker(
            symbol: "BTCUSDT",
            lastPrice: last,
            openPrice: open,
            highPrice: last,
            lowPrice: open,
            quoteVolume: 0,
            updatedAt: .now
        )
    }

    @Test func percentChangeIsCalculatedFromOpenPrice() {
        let sut = ticker(last: 105, open: 100)

        #expect(sut.priceChange == 5)
        #expect(sut.priceChangePercent == 5)
        #expect(sut.isUp)
    }

    @Test func zeroOpenPriceDoesNotDivideByZero() {
        #expect(ticker(last: 10, open: 0).priceChangePercent == 0)
    }
}

struct ChartRangeTests {
    // Binance tek istekte en fazla 1000 mum veriyor.
    @Test(arguments: ChartRange.allCases)
    func fitsInSingleRequest(range: ChartRange) {
        #expect(range.candleCount <= 1000)
    }
}

struct PriceAlertTests {
    // Alarm diske ve App Group'a JSON olarak da yazılabilir. Küçük fiyatlı
    // coin'lerde (ör. 0.00001234) kodlayıp geri okurken basamak kaybolmamalı.
    @Test func roundTripKeepsDecimalPrecision() throws {
        let alert = PriceAlert(
            symbol: "PEPEUSDT",
            targetPrice: Decimal(string: "0.00001234")!,
            direction: .above
        )

        let data = try JSONEncoder().encode(alert)
        let decoded = try JSONDecoder().decode(PriceAlert.self, from: data)

        #expect(decoded == alert)
    }
}
