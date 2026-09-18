import SwiftUI
import MarketCore

// Geçici ekran: sadece paketin uygulamaya bağlandığını gösteriyor.
// Watchlist ekranı gelince silinecek.
struct ContentView: View {
    private let pair = TradingPair(baseAsset: "BTC", quoteAsset: "USDT")

    var body: some View {
        Text(pair.displayName)
            .font(.largeTitle.monospaced())
    }
}

#Preview {
    ContentView()
}
