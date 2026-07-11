import WidgetKit

struct RatioTimelineProvider: TimelineProvider {
    private let service = RatioService()

    func placeholder(in context: Context) -> RatioEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping (RatioEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
        } else {
            Task {
                let entry = await fetchEntry()
                completion(entry)
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RatioEntry>) -> Void) {
        Task {
            let entry = await fetchEntry()
            let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
    }

    private func fetchEntry() async -> RatioEntry {
        var hgGC: (Double, Double)? = nil
        var soxxQQQ: (Double, Double)? = nil

        for pair in TrackedPair.pairs {
            do {
                let snap = try await service.fetchSnapshot(for: pair)
                let data = (snap.ratio, snap.changePercent ?? 0)
                if pair.shortName == "HG/GC" { hgGC = data }
                else { soxxQQQ = data }
            } catch {
                // keep nil for failed fetches
            }
        }

        return RatioEntry(date: Date(), hgGC: hgGC, soxxQQQ: soxxQQQ, isPlaceholder: false)
    }
}
