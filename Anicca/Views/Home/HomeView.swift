import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var entitlements: EntitlementManager
    @Binding var selectedTab: MainTab
    @State private var checkIns: [CheckIn] = []
    @State private var suggestions: [String] = []
    @State private var suggestionsLoading: Bool = false
    @State private var suggestionsError: String?
    @State private var isUsingAI = true
    @State private var underactiveCenter: EnergyCenter?
    @State private var showPaywall = false

    private let insights = InsightsService()
    private let service = CheckInService.shared

    var body: some View {
        ZStack {
            MeshGradientBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s16) {
                    header
                    quickStatsRow
                    logCTACard
                    suggestionCard
                    recentPreview
                }
                .padding(AniccaTheme.Spacing.s20)
            }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .task { await refresh() }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private var firstName: String {
        let raw = auth.currentUser?.displayName ?? auth.currentUser?.email.split(separator: "@").first.map(String.init) ?? ""
        return raw.split(separator: " ").first.map(String.init) ?? raw
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(Date().greeting), \(firstName)")
                    .anicca(.title)
                Spacer()
                planBadge
            }
            Text(Date().humanReadable)
                .anicca(.subheadline)
        }
    }

    private var planBadge: some View {
        Text(entitlements.planTier.displayName)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, AniccaTheme.Spacing.s8)
            .padding(.vertical, 3)
            .background {
                Capsule().fill(badgeColor.opacity(0.18))
            }
            .foregroundStyle(badgeColor)
    }

    private var badgeColor: Color {
        switch entitlements.planTier {
        case .free: return AniccaTheme.textMuted
        case .pro: return AniccaTheme.brandPrimary
        case .bundle: return AniccaTheme.brandAccent
        }
    }

    // MARK: - Stats

    private var quickStatsRow: some View {
        HStack(spacing: AniccaTheme.Spacing.s12) {
            statCard(title: "Streak",
                     value: entitlements.isPro ? "🔥 \(streak()) days" : "—",
                     locked: !entitlements.isPro)
            statCard(title: "This week",
                     value: "\(weekCount())",
                     locked: false)
            statCard(title: "Most active",
                     value: mostActiveText(),
                     locked: false,
                     accentColor: insights.dominantCenter(in: lastDays(7))?.color)
        }
    }

    private func statCard(title: String, value: String, locked: Bool, accentColor: Color? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                if let accentColor {
                    Circle().fill(accentColor).frame(width: 8, height: 8)
                }
                Text(title).anicca(.caption)
                Spacer()
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(AniccaTheme.textMuted)
                }
            }
            Text(value)
                .anicca(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(AniccaTheme.Spacing.s12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .aniccaCard(padding: AniccaTheme.Spacing.s12)
    }

    // MARK: - Log CTA

    private var logCTACard: some View {
        Button {
            selectedTab = .log
        } label: {
            VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s8) {
                Text("How are you feeling right now?").anicca(.headline)
                Text("Check-in #\((auth.currentUser?.totalCheckIns ?? 0) + 1)").anicca(.caption)
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Text("Start Check-in")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, AniccaTheme.Spacing.s16)
                    .padding(.vertical, AniccaTheme.Spacing.s12)
                    .background {
                        Capsule().fill(AniccaTheme.brandPrimary)
                    }
                }
            }
            .padding(AniccaTheme.Spacing.s20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: AniccaTheme.Radius.card, style: .continuous)
                    .fill(LinearGradient(
                        colors: [AniccaTheme.brandAccent.opacity(0.4), AniccaTheme.brandSecondary.opacity(0.3), Color(hex: "#FFE5D9").opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .overlay {
                        RoundedRectangle(cornerRadius: AniccaTheme.Radius.card, style: .continuous)
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    }
            }
            .shadow(color: AniccaTheme.cardShadowColor, radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Suggestion Card

    private var suggestionCard: some View {
        VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s12) {
            HStack {
                Text("Today's Suggestion").anicca(.headline)
                Spacer()
                if !entitlements.isPro {
                    Image(systemName: "lock.fill").foregroundStyle(AniccaTheme.brandPrimary)
                }
            }
            Group {
                if !entitlements.isPro {
                    VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s8) {
                        Text("Personalized practice for your most underactive center.")
                            .anicca(.body)
                            .blur(radius: 4)
                        Button("Unlock with Pro →") { showPaywall = true }
                            .buttonStyle(SecondaryButtonStyle())
                    }
                } else if suggestionsLoading {
                    HStack { ProgressView(); Text("Finding a practice…").anicca(.subheadline) }
                } else if let error = suggestionsError {
                    VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s8) {
                        Text(error).anicca(.body)
                        Button("Try again") {
                            Task { await loadSuggestions() }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                } else if let center = underactiveCenter, !suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s8) {
                        HStack(spacing: AniccaTheme.Spacing.s8) {
                            Circle().fill(center.color).frame(width: 10, height: 10)
                            Text("\(center.displayName) — \(center.subtitle)").anicca(.subheadline)
                        }
                        ForEach(suggestions, id: \.self) { practice in
                            HStack(alignment: .top, spacing: 4) {
                                Text("•")
                                Text(practice).anicca(.body)
                            }
                        }
                        Text(isUsingAI ? "Powered by Gemini" : "Handcrafted Practice").anicca(.caption)
                    }
                } else {
                    Text("Log a few check-ins to receive tailored practices.").anicca(.body)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .aniccaCard()
    }

    // MARK: - Recent

    private var recentPreview: some View {
        VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s12) {
            HStack {
                Text("Recent Check-ins").anicca(.headline)
                Spacer()
                Button("View All →") { selectedTab = .insights }
                    .buttonStyle(GhostButtonStyle())
            }
            if checkIns.isEmpty {
                Text("Nothing yet. Tap the Log tab to start.").anicca(.subheadline)
            } else {
                ForEach(checkIns.prefix(3)) { checkIn in
                    CheckInRow(checkIn: checkIn)
                    if checkIn.id != checkIns.prefix(3).last?.id {
                        Divider()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .aniccaCard()
    }

    // MARK: - Helpers

    private func refresh() async {
        guard let user = auth.currentUser else { return }
        await service.loadRemoteCheckIns(userId: user.id)
        self.checkIns = service.fetchLocalCheckIns(userId: user.id)
        await loadSuggestions()
    }

    private func loadSuggestions() async {
        guard entitlements.isPro else { return }
        suggestionsError = nil
        let allEntries = checkIns.flatMap { $0.entries }
        guard !allEntries.isEmpty else { return }
 
        var lowest: (EnergyCenter, Double) = (.heart, .infinity)
        for center in EnergyCenter.allCases {
            let score = insights.balanceScore(for: center, in: allEntries)
            if score < lowest.1 {
                lowest = (center, score)
            }
        }
        underactiveCenter = lowest.0
        suggestionsLoading = true
        defer { suggestionsLoading = false }
        do {
            let recent = insights.entriesInLast(days: 14, from: checkIns)
            let result = try await AIService.shared.generateCenterSuggestion(for: lowest.0, recentEntries: recent)
            self.suggestions = result
            self.isUsingAI = true
        } catch {
            // Fallback to high-quality handcrafted suggestions if the Gemini API key is invalid/unavailable
            self.suggestions = lowest.0.fallbackSuggestions
            self.isUsingAI = false
        }
    }

    private func streak() -> Int {
        insights.streak(from: checkIns)
    }

    private func weekCount() -> Int {
        insights.entriesInLast(days: 7, from: checkIns).count > 0
            ? checkIns.filter { $0.createdAt >= Date().daysAgo(7) }.count
            : 0
    }

    private func mostActiveText() -> String {
        let entries = lastDays(7)
        guard let center = insights.dominantCenter(in: entries) else { return "—" }
        return center.displayName
    }

    private func lastDays(_ days: Int) -> [EmotionEntry] {
        insights.entriesInLast(days: days, from: checkIns)
    }
}
