import SwiftUI

struct InsightsView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var entitlements: EntitlementManager
    @StateObject private var viewModel = InsightsViewModel()
    @State private var showPaywall = false
    @State private var checkInToDelete: CheckIn?
    @State private var showDeleteAlert = false

    var body: some View {
        ZStack {
            MeshGradientBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s16) {
                    header
                    timeFilter
                    radarCard
                    weeklySummaryCard
                    timelineCard
                    centersBreakdownCard
                    aiInsightCard
                    recentCheckInsCard
                }
                .padding(AniccaTheme.Spacing.s20)
            }
        }
        .navigationTitle(Strings.Insights.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
            if entitlements.isPro {
                await viewModel.loadAIInsight()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .planUpgraded)) { _ in
            Task {
                if entitlements.isPro { await viewModel.loadAIInsight() }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert("Delete this check-in?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let target = checkInToDelete {
                    Task { await viewModel.deleteCheckIn(target) }
                }
            }
            Button("Cancel", role: .cancel) { checkInToDelete = nil }
        } message: {
            Text("This will permanently delete the check-in.")
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Strings.Insights.title).anicca(.largeTitle)
            Text("\(viewModel.totalCheckIns) check-ins logged").anicca(.subheadline)
            if let email = auth.currentUser?.email {
                Text(email).anicca(.caption)
            }
        }
    }

    private var timeFilter: some View {
        Picker("Range", selection: $viewModel.timeRange) {
            ForEach(InsightsTimeRange.allCases) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }

    private var radarCard: some View {
        VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s12) {
            HStack {
                Text(Strings.Insights.radarTitle).anicca(.headline)
                Spacer()
                Picker("Range", selection: $viewModel.radarAllTime) {
                    Text("14 Days").tag(false)
                    Text("All Time").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
            if viewModel.radarEntries.isEmpty {
                emptyRadar
            } else {
                let scores = Dictionary(uniqueKeysWithValues: EnergyCenter.allCases.map { ($0, viewModel.balanceScore(for: $0)) })
                RadarChartView(data: RadarChartData(scores: scores))
                    .frame(height: 280)
            }
            Text(Strings.Insights.radarSubtitle).anicca(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .aniccaCard()
    }

    private var emptyRadar: some View {
        VStack(spacing: AniccaTheme.Spacing.s8) {
            ZStack {
                ForEach([0.5, 1.0], id: \.self) { fraction in
                    Circle()
                        .stroke(AniccaTheme.textMuted.opacity(0.2), lineWidth: 1)
                        .padding(80 - 60 * fraction)
                }
            }
            .frame(height: 200)
            Text(Strings.Insights.emptyState)
                .anicca(.caption)
                .multilineTextAlignment(.center)
        }
    }

    private var weeklySummaryCard: some View {
        VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s12) {
            HStack {
                Text(Strings.Insights.weeklySummary).anicca(.headline)
                Spacer()
                if !entitlements.isPro {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(AniccaTheme.brandPrimary)
                }
            }
            ZStack {
                VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s8) {
                    if let dominant = viewModel.dominantCenter {
                        HStack(spacing: AniccaTheme.Spacing.s8) {
                            Circle().fill(dominant.color).frame(width: 12, height: 12)
                            Text("You've been focusing on \(dominant.displayName) energy this week.")
                                .anicca(.body)
                        }
                    } else {
                        Text("Log at least 3 check-ins this week to see your weekly summary.")
                            .anicca(.body)
                    }
                    ForEach(viewModel.weeklyTopEmotions, id: \.name) { item in
                        HStack(spacing: AniccaTheme.Spacing.s8) {
                            Circle().fill(item.center.color).frame(width: 8, height: 8)
                            Text("\(item.name) — \(item.count)x").anicca(.subheadline)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !entitlements.isPro {
                    Color.white.opacity(0.4)
                    VStack(spacing: AniccaTheme.Spacing.s8) {
                        Text("Unlock Weekly Summary").anicca(.headline)
                        Button("Get Pro →") { showPaywall = true }
                            .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding(AniccaTheme.Spacing.s12)
                }
            }
            .blur(radius: entitlements.isPro ? 0 : 4)
        }
        .aniccaCard()
    }

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s12) {
            Text(Strings.Insights.timeline).anicca(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AniccaTheme.Spacing.s8) {
                    ForEach(viewModel.moodTimeline(), id: \.date) { item in
                        TimelineDay(date: item.date, center: item.center)
                    }
                }
                .padding(.vertical, AniccaTheme.Spacing.s4)
            }
        }
        .aniccaCard()
    }

    private var centersBreakdownCard: some View {
        VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s12) {
            Text(Strings.Insights.centersBreakdown).anicca(.headline)
            ForEach(EnergyCenter.allCases) { center in
                let count = viewModel.entryCount(for: center)
                let status = viewModel.status(for: center)
                HStack(spacing: AniccaTheme.Spacing.s12) {
                    Circle().fill(center.color).frame(width: 12, height: 12)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(center.displayName).anicca(.body)
                        Text("\(count) entries").anicca(.caption)
                    }
                    Spacer()
                    Text(status.displayName)
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, AniccaTheme.Spacing.s8)
                        .padding(.vertical, 4)
                        .background {
                            Capsule().fill(status.color.opacity(0.18))
                        }
                        .foregroundStyle(status.color)
                }
                .padding(.vertical, 4)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(center.displayName) center, \(count) entries, \(status.displayName)")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .aniccaCard()
    }

    private var aiInsightCard: some View {
        VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(AniccaTheme.brandPrimary)
                Text(Strings.Insights.aiInsightTitle).anicca(.headline)
                Spacer()
                if !entitlements.isPro {
                    Image(systemName: "lock.fill").foregroundStyle(AniccaTheme.brandPrimary)
                }
            }
            Group {
                if !entitlements.isPro {
                    VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s12) {
                        Text("Your personalized AI insight").anicca(.body).blur(radius: 4)
                        Text("Gentle reflections about your weekly patterns will appear here.")
                            .anicca(.body)
                            .blur(radius: 4)
                        Button(Strings.Insights.aiInsightUnlock) { showPaywall = true }
                            .buttonStyle(SecondaryButtonStyle())
                    }
                } else if viewModel.aiLoading {
                    HStack {
                        ProgressView()
                        Text("Generating your insight…").anicca(.subheadline)
                    }
                } else if let insight = viewModel.aiInsight {
                    VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s8) {
                        Text(insight.insight).anicca(.body)
                        if !insight.suggestedPractices.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Try this week:").anicca(.subheadline)
                                ForEach(insight.suggestedPractices, id: \.self) { p in
                                    HStack(alignment: .top, spacing: 4) {
                                        Text("•")
                                        Text(p).anicca(.body)
                                    }
                                }
                            }
                        }
                        Text(Strings.Insights.aiInsightCaption).anicca(.caption)
                    }
                } else if let aiError = viewModel.aiError {
                    VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s8) {
                        Text(aiError).anicca(.body)
                        Button("Try again") {
                            Task { await viewModel.loadAIInsight() }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                } else {
                    Text("Log at least 3 check-ins this week to unlock your weekly AI insight.")
                        .anicca(.body)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .aniccaCard()
    }

    private var recentCheckInsCard: some View {
        VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s12) {
            Text(Strings.Insights.recentCheckIns).anicca(.headline)
            if viewModel.checkIns.isEmpty {
                Text("No check-ins yet.").anicca(.subheadline)
            } else {
                ForEach(viewModel.checkIns.prefix(20)) { checkIn in
                    NavigationLink {
                        CheckInDetailView(checkIn: checkIn)
                    } label: {
                        CheckInRow(checkIn: checkIn)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            checkInToDelete = checkIn
                            showDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .aniccaCard()
    }
}

// MARK: - Timeline Day

private struct TimelineDay: View {
    let date: Date
    let center: EnergyCenter?
    @State private var showPopover = false

    var body: some View {
        VStack(spacing: 4) {
            Text(weekdayLabel(date))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AniccaTheme.textSecondary)
            Button {
                showPopover = true
            } label: {
                Group {
                    if let center {
                        Circle().fill(center.color)
                    } else {
                        Rectangle()
                            .fill(AniccaTheme.textMuted.opacity(0.3))
                            .frame(width: 12, height: 2)
                    }
                }
                .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showPopover) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(date.shortDate).anicca(.headline)
                    if let center {
                        HStack(spacing: 6) {
                            Circle().fill(center.color).frame(width: 8, height: 8)
                            Text(center.displayName).anicca(.body)
                        }
                    } else {
                        Text("No check-in").anicca(.body)
                    }
                }
                .padding()
                .presentationCompactAdaptation(.popover)
            }
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(AniccaTheme.textMuted)
        }
        .accessibilityLabel(center == nil
                            ? "No check-in on \(date.shortDate)"
                            : "\(center!.displayName) center on \(date.shortDate)")
    }

    private func weekdayLabel(_ d: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EE"
        return formatter.string(from: d)
    }
}

// MARK: - Check-in Row

struct CheckInRow: View {
    let checkIn: CheckIn

    var body: some View {
        VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s8) {
            HStack {
                Text(checkIn.createdAt.humanReadable).anicca(.subheadline)
                Spacer()
                if !checkIn.syncedToSupabase {
                    Image(systemName: "icloud.slash")
                        .font(.system(size: 11))
                        .foregroundStyle(AniccaTheme.textMuted)
                }
            }
            HStack(spacing: AniccaTheme.Spacing.s8) {
                ForEach(checkIn.sortedEntries.prefix(4)) { entry in
                    pill(entry)
                }
                if checkIn.sortedEntries.count > 4 {
                    Text("+\(checkIn.sortedEntries.count - 4) more")
                        .anicca(.caption)
                }
            }
            if let note = checkIn.note, !note.isEmpty {
                Text(note)
                    .anicca(.caption)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.vertical, AniccaTheme.Spacing.s8)
    }

    private func pill(_ entry: EmotionEntry) -> some View {
        Text(entry.emotionName)
            .font(.system(size: 11, weight: .medium))
            .padding(.horizontal, AniccaTheme.Spacing.s8)
            .padding(.vertical, 4)
            .background {
                Capsule().fill(entry.energyCenter.color.opacity(0.18))
            }
            .foregroundStyle(entry.energyCenter.color)
    }
}
