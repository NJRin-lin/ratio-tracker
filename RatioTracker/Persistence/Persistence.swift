import Foundation
import SwiftData

@Model
final class RatioRecord {
    var pairName: String
    var ratio: Double
    var timestamp: Date

    init(pairName: String, ratio: Double, timestamp: Date) {
        self.pairName = pairName
        self.ratio = ratio
        self.timestamp = timestamp
    }
}

@MainActor
final class PersistenceController {
    let container: ModelContainer

    init() {
        let schema = Schema([RatioRecord.self])
        let config = ModelConfiguration("RatioTracker")
        container = try! ModelContainer(for: schema, configurations: [config])
    }

    func saveSnapshot(_ snapshot: RatioSnapshot) {
        let record = RatioRecord(pairName: snapshot.pair.shortName, ratio: snapshot.ratio, timestamp: snapshot.timestamp)
        container.mainContext.insert(record)
        try? container.mainContext.save()
    }

    func fetchHistory(for pairName: String, since: Date) -> [RatioRecord] {
        let descriptor = FetchDescriptor<RatioRecord>(sortBy: [SortDescriptor(\.timestamp, order: .forward)])
        let all = (try? container.mainContext.fetch(descriptor)) ?? []
        return all.filter { $0.pairName == pairName && $0.timestamp >= since }
    }

    func latestRatio(for pairName: String) -> RatioRecord? {
        let descriptor = FetchDescriptor<RatioRecord>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        let all = (try? container.mainContext.fetch(descriptor)) ?? []
        return all.first(where: { $0.pairName == pairName })
    }

    func cleanup(days: Int = 180) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<RatioRecord>()
        guard let results = try? container.mainContext.fetch(descriptor) else { return }
        for r in results where r.timestamp < cutoff { container.mainContext.delete(r) }
        try? container.mainContext.save()
    }
}
