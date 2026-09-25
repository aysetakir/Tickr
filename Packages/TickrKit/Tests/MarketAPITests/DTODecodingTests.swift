import Foundation
import MarketCore
import Testing

@testable import MarketAPI

@Suite struct TickerDTOTests {
    @Test func decodesRealResponse() throws {
        let tickers = try Fixture.decode([TickerDTO].self, from: "ticker24hr").map(\.ticker)

        #expect(tickers.map(\.symbol) == ["BTCUSDT", "ETHUSDT"])

        let btc = try #require(tickers.first)
        #expect(btc.lastPrice == (try dec("83588.15")))
        #expect(btc.openPrice == (try dec("84331.41")))
        #expect(btc.updatedAt == Date(timeIntervalSince1970: 1_790_350_757.010))
    }

    @Test func keepsFullPrecisionOfSmallPrices() throws {
        let json = #"""
        [{"symbol":"PEPEUSDT","lastPrice":"0.00000012","openPrice":"0.00000011",
          "highPrice":"0.00000013","lowPrice":"0.00000010",
          "quoteVolume":"1234.5","closeTime":1790350757010}]
        """#
        let ticker = try JSONDecoder().decode([TickerDTO].self, from: Data(json.utf8))[0].ticker

        #expect(ticker.lastPrice == (try dec("0.00000012")))
        #expect(ticker.lastPrice - ticker.openPrice == (try dec("0.00000001")))
    }

    @Test func throwsOnUnparsablePrice() throws {
        let json = #"""
        [{"symbol":"BTCUSDT","lastPrice":"n/a","openPrice":"1","highPrice":"1",
          "lowPrice":"1","quoteVolume":"1","closeTime":0}]
        """#
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode([TickerDTO].self, from: Data(json.utf8))
        }
    }

    @Test func decimalSeparatorIsLocaleIndependent() throws {
        #expect(Decimal(string: "63250.12", locale: Locale(identifier: "tr_TR")) == 63250)

        let json = #"""
        [{"symbol":"BTCUSDT","lastPrice":"63250.12","openPrice":"1","highPrice":"1",
          "lowPrice":"1","quoteVolume":"1","closeTime":0}]
        """#
        let ticker = try JSONDecoder().decode([TickerDTO].self, from: Data(json.utf8))[0].ticker
        #expect(ticker.lastPrice == (try dec("63250.12")))
    }
}

@Suite struct KlineDTOTests {
    @Test func decodesPositionalArray() throws {
        let candles = try Fixture.decode([KlineDTO].self, from: "klines").map(\.candle)

        #expect(candles.count == 3)

        let first = try #require(candles.first)
        #expect(first.openTime == Date(timeIntervalSince1970: 1_790_341_200))
        #expect(first.open == (try dec("84471.79")))
        #expect(first.high == (try dec("84600.01")))
        #expect(first.low == (try dec("83530.06")))
        #expect(first.close == (try dec("83923.71")))
        #expect(first.volume == (try dec("1647.67121")))
    }

    @Test func ohlcIsInternallyConsistent() throws {
        for candle in try Fixture.decode([KlineDTO].self, from: "klines").map(\.candle) {
            #expect(candle.low <= candle.open)
            #expect(candle.low <= candle.close)
            #expect(candle.high >= candle.open)
            #expect(candle.high >= candle.close)
        }
    }

    @Test func candlesAreOrderedOldestFirst() throws {
        let times = try Fixture.decode([KlineDTO].self, from: "klines").map(\.candle.openTime)
        #expect(times == times.sorted())
    }

    @Test func throwsOnUnparsableField() throws {
        let json = #"[[1790341200000,"1","2","n/a","4","5"]]"#
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode([KlineDTO].self, from: Data(json.utf8))
        }
    }
}

@Suite struct ExchangeInfoDTOTests {
    @Test func keepsOnlyTradingPairs() throws {
        let pairs = try Fixture.decode(ExchangeInfoDTO.self, from: "exchangeInfo").tradingPairs

        #expect(pairs.map(\.symbol) == ["ETHBTC", "BTCUSDT"])
        #expect(!pairs.map(\.symbol).contains("XYZUSDT"))
    }

    @Test func dropsPairsWhoseSymbolDoesNotMatchItsAssets() throws {
        let json = #"""
        {"symbols":[{"symbol":"WEIRD","status":"TRADING",
                     "baseAsset":"BTC","quoteAsset":"USDT"}]}
        """#
        let dto = try JSONDecoder().decode(ExchangeInfoDTO.self, from: Data(json.utf8))
        #expect(dto.tradingPairs.isEmpty)
    }

    @Test func buildsDisplayNameFromAssets() throws {
        let pairs = try Fixture.decode(ExchangeInfoDTO.self, from: "exchangeInfo").tradingPairs
        #expect(pairs.map(\.displayName) == ["ETH/BTC", "BTC/USDT"])
    }
}
