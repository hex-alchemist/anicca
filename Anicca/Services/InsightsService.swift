import Foundation

struct InsightsService {

    // MARK: - Balance Score

    /// Returns a normalized 0.0–1.0 score for a center based on entries.
    /// 0.0 → no entries (blocked); 0.5 → at the user's personal average; 1.0 → well above average.
    func balanceScore(for center: EnergyCenter, in entries: [EmotionEntry]) -> Double {
        guard !entries.isEmpty else { return 0.0 }

        var weightedTotals: [EnergyCenter: Double] = [:]
        for entry in entries {
            weightedTotals[entry.energyCenter, default: 0] += Double(entry.intensity)
        }
        let value = weightedTotals[center] ?? 0
        if value == 0 { return 0.0 }

        let perCenter = weightedTotals.values.reduce(0, +) / Double(EnergyCenter.allCases.count)
        guard perCenter > 0 else { return 0.0 }

        // Map: 0 → 0.0, average → 0.5, 2x average → 1.0.
        let ratio = value / (perCenter * 2.0)
        return min(max(ratio, 0.0), 1.0)
    }

    // MARK: - Dominant Center

    func dominantCenter(in entries: [EmotionEntry]) -> EnergyCenter? {
        guard !entries.isEmpty else { return nil }
        var totals: [EnergyCenter: Int] = [:]
        for entry in entries {
            totals[entry.energyCenter, default: 0] += entry.intensity
        }
        return totals.max { $0.value < $1.value }?.key
    }

    // MARK: - Streak

    func streak(from checkIns: [CheckIn]) -> Int {
        let sorted = checkIns.sorted(by: { $0.createdAt > $1.createdAt })
        guard !sorted.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        let dayKeys = Set(sorted.map { calendar.startOfDay(for: $0.createdAt) })
        var current = dayKeys.contains(today) ? today : (dayKeys.contains(yesterday) ? yesterday : nil)
        guard var cursor = current else { return 0 }

        var count = 1
        while true {
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            if dayKeys.contains(prev) {
                count += 1
                cursor = prev
            } else {
                break
            }
        }
        return count
    }

    // MARK: - Mood Timeline

    /// Returns a dictionary keyed by calendar day → dominant center for that day (nil if no check-in).
    func moodTimeline(for days: Int, from checkIns: [CheckIn]) -> [Date: EnergyCenter?] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var result: [Date: EnergyCenter?] = [:]

        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            result[day] = nil
        }

        let grouped = Dictionary(grouping: checkIns) { calendar.startOfDay(for: $0.createdAt) }
        for (day, sameDay) in grouped {
            guard result[day] != nil || result.keys.contains(day) else { continue }
            let allEntries = sameDay.flatMap { $0.entries }
            result[day] = dominantCenter(in: allEntries)
        }
        return result
    }

    // MARK: - Status

    func centerStatus(score: Double) -> CenterStatus {
        if score == 0 { return .noData }
        if score <= 0.35 { return .underactive }
        if score <= 0.65 { return .balanced }
        return .overactive
    }

    // MARK: - Aggregates

    func entriesInLast(days: Int, from checkIns: [CheckIn]) -> [EmotionEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return checkIns
            .filter { $0.createdAt >= cutoff }
            .flatMap { $0.entries }
    }

    func entryCount(per center: EnergyCenter, in entries: [EmotionEntry]) -> Int {
        entries.filter { $0.energyCenter == center }.count
    }

    func topEmotions(in entries: [EmotionEntry], limit: Int = 5) -> [(name: String, count: Int, avgIntensity: Double, center: EnergyCenter)] {
        let grouped = Dictionary(grouping: entries) { $0.emotionName }
        return grouped
            .map { (name, list) -> (String, Int, Double, EnergyCenter) in
                let avg = Double(list.reduce(0) { $0 + $1.intensity }) / Double(list.count)
                let center = list.first?.energyCenter ?? .heart
                return (name, list.count, avg, center)
            }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map { (name: $0.0, count: $0.1, avgIntensity: $0.2, center: $0.3) }
    }

    func valenceTrend(in entries: [EmotionEntry]) -> (positive: Int, neutral: Int, negative: Int) {
        var pos = 0, neu = 0, neg = 0
        for entry in entries {
            let center = entry.energyCenter
            if let emotion = EmotionLibrary.byCenter[center]?.first(where: { $0.name.caseInsensitiveCompare(entry.emotionName) == .orderedSame }) {
                switch emotion.valence {
                case .positive: pos += 1
                case .neutral: neu += 1
                case .negative: neg += 1
                }
            }
        }
        return (pos, neu, neg)
    }
}
