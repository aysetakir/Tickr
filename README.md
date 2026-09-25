# Tickr

[![CI](https://github.com/aysetakir/Tickr/actions/workflows/ci.yml/badge.svg)](https://github.com/aysetakir/Tickr/actions/workflows/ci.yml)

Canlı kripto fiyatları gösteren bir iOS uygulaması. Veri iki yoldan geliyor
ve bu ayrım projenin omurgası:

|  | REST | WebSocket |
|---|---|---|
| Ne zaman | Ekran açılınca, bir kere | Ekran açık kaldıkça, sürekli |
| Ne için | Coin listesi, ilk fiyat, geçmiş mumlar | Canlı fiyat, canlı son mum |

REST katmanı [Courier](https://github.com/aysetakir/Courier) üzerine kurulu.

## Modüller

```
Tickr (app)            ← Bileşim kökü: somut tipleri seçip ekrana verir.
└── Packages/TickrKit
    ├── MarketCore     Modeller + protokoller. Kimseye bağımlı değil.
    └── MarketAPI      Binance REST. Courier'i yalnızca bu modül bilir.
```

Oklar hep `MarketCore`'a doğru gider. Feature modülleri `MarketDataService`
gibi protokolleri görür, `BinanceMarketService` gibi somut sınıfları görmez.
Kuralı derleyici zorlar: bağımlılık `Package.swift`'te yoksa `import`
derlenmez.

> Modüller ihtiyaç duyuldukça ekleniyor; yukarıdaki liste bugünkü hâli.

## Geliştirme

```sh
# UI'sız modüller — simülatör açmadan, hızlı
cd Packages/TickrKit && swift test

# App target'ı — iOS simülatöründe
xcodebuild test -project Tickr.xcodeproj -scheme Tickr \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest'
```

CI her push'ta bu iki işi de koşar.

## Gereksinimler

iOS 17+, Xcode 26+ (paket `swift-tools-version: 6.2` kullanıyor).
