import Foundation
import Combine
import SwiftUI

@MainActor
final class RatioViewModel: ObservableObject {
    @Published var snapshots: [String: RatioSnapshot] = [:]
    @Published var chartData: [String: [(Date, Double)]] = [:]
    @Published var rangeChangePct: [String: Double] = [:]
    @Published var selectedRange: String = "6mo"
    @Published var isRefreshing = false
    @Published var lastUpdated: Date?
    @Published var errorMessage: String?

    private let service = RatioService()
    private let persistence = PersistenceController()

    let pairs = TrackedPair.pairs
    let timeRanges = ["5d", "1mo", "3mo", "6mo", "1y"]
    var rangeLabel: String { selectedRange }

    init() {
        Task { await initialLoad() }
    }

    func refresh() async {
        isRefreshing = true
        errorMessage = nil
        defer { isRefreshing = false }

        for pair in pairs {
            do {
                let snapshot = try await service.fetchSnapshot(for: pair)
                snapshots[pair.shortName] = snapshot
                persistence.saveSnapshot(snapshot)
            } catch {
                let existing = snapshots[pair.shortName]
                if existing == nil {
                    errorMessage = "\(pair.shortName): \(error.localizedDescription)"
                }
            }
        }
        lastUpdated = Date()
        await loadChartData()
    }

    func loadChartData() async {
        for pair in pairs {
            if let data = try? await service.fetchHistory(for: pair, range: selectedRange) {
                chartData[pair.shortName] = data
                // 根据选中时间范围重算涨跌百分比
                if let first = data.first, let last = data.last, first.1 != 0 {
                    rangeChangePct[pair.shortName] = (last.1 - first.1) / abs(first.1) * 100
                }
            }
        }
        persistence.cleanup(days: 180)
    }

    // MARK: - Private

    private func initialLoad() async {
        for pair in pairs {
            let history = persistence.fetchHistory(for: pair.shortName, since: Date().addingTimeInterval(-86400))
            if let latest = history.last {
                snapshots[pair.shortName] = RatioSnapshot(
                    pair: pair, numeratorPrice: 0, denominatorPrice: 0,
                    ratio: latest.ratio, previousRatio: nil,
                    changePercent: nil, timestamp: latest.timestamp
                )
            }
        }
        await refresh()
    }
}
