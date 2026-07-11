import Foundation

actor RateLimiter {
    private let maxPerSecond: Double = 2
    private let burst: Int = 5
    private var tokens: Double
    private var lastRefill: Date

    init() { tokens = Double(burst); lastRefill = Date() }

    func acquire() async {
        refill()
        if tokens >= 1 { tokens -= 1 }
        else {
            let wait = (1 - tokens) / maxPerSecond
            try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
            tokens = 0; lastRefill = Date()
        }
    }

    private func refill() {
        let now = Date()
        tokens = min(Double(burst), tokens + now.timeIntervalSince(lastRefill) * maxPerSecond)
        lastRefill = now
    }
}

final class RatioService {
    private let baseURL = "https://query1.finance.yahoo.com/v8/finance/chart"
    private let session: URLSession
    private let limiter = RateLimiter()

    init(session: URLSession = .shared) { self.session = session }

    func fetchSnapshot(for pair: TrackedPair) async throws -> RatioSnapshot {
        async let numPrice = fetchPrice(ticker: pair.numeratorTicker)
        async let denPrice = fetchPrice(ticker: pair.denominatorTicker)
        let (num, den) = try await (numPrice, denPrice)
        let ratio = num / den

        // 获取前值以计算涨跌
        let numSeries = try? await fetchSeries(ticker: pair.numeratorTicker, range: "5d")
        let denSeries = try? await fetchSeries(ticker: pair.denominatorTicker, range: "5d")
        var previousRatio: Double?
        var changePercent: Double?
        if let ns = numSeries, let ds = denSeries, ns.count >= 2, ds.count >= 2 {
            let prevNum = ns[ns.count - 2].1
            let prevDen = ds[ds.count - 2].1
            previousRatio = prevNum / prevDen
            if let prev = previousRatio, prev != 0 {
                changePercent = (ratio - prev) / abs(prev) * 100
            }
        }

        return RatioSnapshot(
            pair: pair, numeratorPrice: num, denominatorPrice: den,
            ratio: ratio, previousRatio: previousRatio,
            changePercent: changePercent, timestamp: Date()
        )
    }

    func fetchHistory(for pair: TrackedPair, range: String, interval: String = "1d") async throws -> [(Date, Double)] {
        async let numSeries = fetchSeries(ticker: pair.numeratorTicker, range: range, interval: interval)
        async let denSeries = fetchSeries(ticker: pair.denominatorTicker, range: range, interval: interval)
        let (nums, dens) = try await (numSeries, denSeries)

        let denDict = Dictionary(grouping: dens, by: { Calendar.current.startOfDay(for: $0.0) })
            .compactMapValues { $0.first?.1 }
        return nums.compactMap { (date, val) in
            let day = Calendar.current.startOfDay(for: date)
            guard let denVal = denDict[day], denVal != 0 else { return nil }
            return (date, val / denVal)
        }
    }

    // MARK: - Private

    private func fetchPrice(ticker: String) async throws -> Double {
        await limiter.acquire()
        let data = try await fetch(ticker: ticker, range: "1d")
        guard let price = data.first?.1 else { throw RatioError.noData }
        return price
    }

    private func fetchSeries(ticker: String, range: String, interval: String = "1d") async throws -> [(Date, Double)] {
        await limiter.acquire()
        return try await fetch(ticker: ticker, range: range, interval: interval)
    }

    private func fetch(ticker: String, range: String, interval: String = "1d") async throws -> [(Date, Double)] {
        let encoded = ticker.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ticker
        var components = URLComponents(string: "\(baseURL)/\(encoded)")!
        components.queryItems = [
            URLQueryItem(name: "range", value: range),
            URLQueryItem(name: "interval", value: interval),
        ]
        guard let url = components.url else { throw RatioError.invalidURL }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw RatioError.httpError
        }

        let decoded = try JSONDecoder().decode(YahooResponse.self, from: data)
        guard let result = decoded.chart?.result?.first,
              let timestamps = result.timestamp,
              let quotes = result.indicators?.quote?.first?.close else {
            throw RatioError.noData
        }
        return zip(timestamps, quotes).compactMap { ts, val in
            guard let val else { return nil }
            return (Date(timeIntervalSince1970: TimeInterval(ts)), val)
        }
    }
}

// MARK: - Models & Errors

private struct YahooResponse: Decodable {
    let chart: YahooChart?
}
private struct YahooChart: Decodable {
    let result: [YahooResult]?
}
private struct YahooResult: Decodable {
    let timestamp: [Int]?
    let indicators: YahooIndicators?
}
private struct YahooIndicators: Decodable {
    let quote: [YahooQuote]?
}
private struct YahooQuote: Decodable {
    let close: [Double?]?
}

enum RatioError: LocalizedError {
    case invalidURL, httpError, noData
    var errorDescription: String? {
        switch self {
        case .invalidURL: "URL 构造失败"
        case .httpError: "请求失败"
        case .noData: "无数据返回"
        }
    }
}
