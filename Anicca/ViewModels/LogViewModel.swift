import Foundation
import SwiftUI
import SwiftData

@MainActor
final class LogViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var expandedCenters: Set<EnergyCenter> = Set(EnergyCenter.allCases)
    @Published var selectedEmotions: [Emotion: Int] = [:]
    @Published var touchedIntensity: Set<Emotion> = []
    @Published var note: String = ""

    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    @Published var showIntensitySheet: Bool = false
    @Published var showPaywall: Bool = false
    @Published var showSavedToast: Bool = false
    @Published var savedStreak: Int = 0
    @Published var savedDominantCenter: EnergyCenter?
    @Published var monthCount: Int = 0

    private let checkInService = CheckInService.shared
    private let insightsService = InsightsService()
    private let auth = AuthService.shared

    var totalSelected: Int { selectedEmotions.count }

    var canSave: Bool {
        !selectedEmotions.isEmpty &&
        selectedEmotions.allSatisfy { touchedIntensity.contains($0.key) }
    }

    var freeLimitWarning: String? {
        guard auth.currentUser?.planTier == .free else { return nil }
        if monthCount >= AppConfig.freeMonthlyWarningThreshold && monthCount < AppConfig.freeMonthlyCheckInLimit {
            let remaining = AppConfig.freeMonthlyCheckInLimit - monthCount
            return String(format: Strings.Log.freeLimitWarning, remaining)
        }
        return nil
    }

    var nextCheckInNumber: Int {
        (auth.currentUser?.totalCheckIns ?? 0) + 1
    }

    func filteredEmotions(for center: EnergyCenter) -> [Emotion] {
        let all = EmotionLibrary.byCenter[center] ?? []
        guard !searchText.isEmpty else { return all }
        let lower = searchText.lowercased()
        return all.filter { emotion in
            if emotion.name.lowercased().contains(lower) { return true }
            return emotion.synonyms.contains { $0.lowercased().contains(lower) }
        }
    }

    func centerHasResults(_ center: EnergyCenter) -> Bool {
        !filteredEmotions(for: center).isEmpty
    }

    func toggle(_ emotion: Emotion) {
        if selectedEmotions[emotion] != nil {
            selectedEmotions.removeValue(forKey: emotion)
            touchedIntensity.remove(emotion)
        } else {
            selectedEmotions[emotion] = 3
        }
    }

    func updateIntensity(_ value: Int, for emotion: Emotion) {
        selectedEmotions[emotion] = value
        touchedIntensity.insert(emotion)
    }

    func setExpanded(_ expanded: Bool) {
        if expanded {
            expandedCenters = Set(EnergyCenter.allCases)
        } else {
            expandedCenters.removeAll()
        }
    }

    func toggleSection(_ center: EnergyCenter) {
        if expandedCenters.contains(center) {
            expandedCenters.remove(center)
        } else {
            expandedCenters.insert(center)
        }
    }

    func presentIntensity() {
        guard !selectedEmotions.isEmpty else { return }
        showIntensitySheet = true
    }

    func reset() {
        selectedEmotions.removeAll()
        touchedIntensity.removeAll()
        note = ""
        showIntensitySheet = false
    }

    func refreshMonthCount() {
        guard let userId = auth.currentUser?.id else { return }
        monthCount = checkInService.currentMonthCount(userId: userId)
    }

    // MARK: - Save

    func save() async {
        guard let user = auth.currentUser else {
            errorMessage = Strings.Errors.generic
            return
        }
        refreshMonthCount()
        if user.planTier == .free && monthCount >= AppConfig.freeMonthlyCheckInLimit {
            showIntensitySheet = false
            showPaywall = true
            return
        }
        guard canSave else { return }
        isSaving = true
        defer { isSaving = false }

        let entries = selectedEmotions.map { (emotion: $0.key, intensity: $0.value) }
        do {
            let saved = try await checkInService.saveCheckIn(
                userId: user.id,
                note: note,
                entries: entries
            )
            let dominant = insightsService.dominantCenter(in: saved.entries)
            savedDominantCenter = dominant

            // Update streak + totals
            let allCheckIns = checkInService.fetchLocalCheckIns(userId: user.id)
            let streak = insightsService.streak(from: allCheckIns)
            await auth.updateStreakStats(
                streak: streak,
                totalCheckIns: allCheckIns.count,
                lastDate: saved.createdAt
            )
            savedStreak = streak
            refreshMonthCount()
            showIntensitySheet = false
            withAnimation(AniccaTheme.springAnimation) {
                showSavedToast = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
                withAnimation(AniccaTheme.springAnimation) {
                    self?.showSavedToast = false
                }
            }
            reset()
        } catch let error as AppError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = Strings.Errors.generic
        }
    }
}
