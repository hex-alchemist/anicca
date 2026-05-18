import Foundation
import SwiftUI
import Combine

enum InsightsTimeRange: String, CaseIterable, Identifiable {
    case week = "Week"
    case fortnight = "14 Days"
    case month = "Month"

    var id: String { rawValue }

    var days: Int {
        switch self {
        case .week: return 7
        case .fortnight: return 14
        case .month: return 30
        }
    }
}

@MainActor
final class InsightsViewModel: ObservableObject {
    @Published var timeRange: InsightsTimeRange = .week
    @Published var radarAllTime: Bool = false
    @Published var checkIns: [CheckIn] = []
    @Published var aiInsight: AIInsight?
    @Published var aiLoading: Bool = false
    @Published var aiError: String?

    private let checkInService = CheckInService.shared
    private let insightsService = InsightsService()
    private let auth = AuthService.shared

    var filteredEntries: [EmotionEntry] {
        insightsService.entriesInLast(days: timeRange.days, from: checkIns)
    }

    var radarEntries: [EmotionEntry] {
        if radarAllTime {
            return checkIns.flatMap { $0.entries }
        }
        return insightsService.entriesInLast(days: 14, from: checkIns)
    }

    var totalCheckIns: Int { checkIns.count }

    var weeklyTopEmotions: [(name: String, count: Int, center: EnergyCenter)] {
        let entries = insightsService.entriesInLast(days: 7, from: checkIns)
        return insightsService.topEmotions(in: entries, limit: 3).map {
            (name: $0.name, count: $0.count, center: $0.center)
        }
    }

    var dominantCenter: EnergyCenter? {
        insightsService.dominantCenter(in: insightsService.entriesInLast(days: 7, from: checkIns))
    }

    func balanceScore(for center: EnergyCenter) -> Double {
        insightsService.balanceScore(for: center, in: radarEntries)
    }

    func status(for center: EnergyCenter) -> CenterStatus {
        insightsService.centerStatus(score: balanceScore(for: center))
    }

    func entryCount(for center: EnergyCenter) -> Int {
        insightsService.entryCount(per: center, in: filteredEntries)
    }

    func moodTimeline() -> [(date: Date, center: EnergyCenter?)] {
        let map = insightsService.moodTimeline(for: timeRange.days, from: checkIns)
        return map.keys
            .sorted()
            .map { (date: $0, center: map[$0] ?? nil) }
    }

    // MARK: - Loading

    func load() async {
        guard let user = auth.currentUser else { return }
        await checkInService.loadRemoteCheckIns(userId: user.id)
        let local = checkInService.fetchLocalCheckIns(userId: user.id)
        self.checkIns = local
    }

    func deleteCheckIn(_ checkIn: CheckIn) async {
        do {
            try await checkInService.deleteCheckIn(checkIn)
            checkIns.removeAll { $0.id == checkIn.id }
        } catch {
            // ignored — UI will reload
        }
    }

    // MARK: - AI

    func loadAIInsight() async {
        guard let user = auth.currentUser, user.planTier.isPaid else { return }
        guard let dominant = dominantCenter ?? insightsService.dominantCenter(in: filteredEntries) else { return }
        aiLoading = true
        aiError = nil
        defer { aiLoading = false }
        do {
            let insight = try await AIService.shared.generateWeeklyInsight(
                userId: user.id,
                entries: filteredEntries,
                dominantCenter: dominant
            )
            self.aiInsight = insight
        } catch {
            self.aiError = Strings.Errors.aiUnavailable
        }
    }
}
