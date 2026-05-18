import SwiftUI

struct LogView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var entitlements: EntitlementManager
    @StateObject private var viewModel = LogViewModel()

    private let columns: [GridItem] = [
        GridItem(.adaptive(minimum: 100, maximum: 180), spacing: AniccaTheme.Spacing.s8)
    ]

    var body: some View {
        ZStack {
            MeshGradientBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s16) {
                    header
                    if let warn = viewModel.freeLimitWarning {
                        warningBanner(warn)
                    }
                    expansionControls
                    emotionSections
                    if viewModel.totalSelected > 0 {
                        Spacer()
                            .frame(height: 160) // Buffer for search bar + button
                    } else {
                        Spacer()
                            .frame(height: 100) // Buffer for just search bar
                    }
                }
                .padding(AniccaTheme.Spacing.s20)
            }
            VStack {
                Spacer()
                if viewModel.showSavedToast {
                    successToast
                        .padding(.bottom, AniccaTheme.Spacing.s32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            VStack {
                Spacer()
                
                // Floating Bottom Search Bar
                HStack(spacing: AniccaTheme.Spacing.s8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AniccaTheme.textMuted)
                    TextField(Strings.Log.searchPlaceholder, text: $viewModel.searchText)
                        .submitLabel(.done)
                        .autocorrectionDisabled()
                    if !viewModel.searchText.isEmpty {
                        Button {
                            withAnimation { viewModel.searchText = "" }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AniccaTheme.textMuted)
                        }
                    }
                }
                .padding(AniccaTheme.Spacing.s12)
                .background {
                    Capsule()
                        .fill(.regularMaterial)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
                }
                .overlay(Capsule().stroke(AniccaTheme.textMuted.opacity(0.2), lineWidth: 1))
                .padding(.horizontal, AniccaTheme.Spacing.s20)
                .padding(.bottom, viewModel.totalSelected > 0 ? AniccaTheme.Spacing.s8 : AniccaTheme.Spacing.s20)

                if viewModel.totalSelected > 0 {
                    Button {
                        viewModel.presentIntensity()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Set intensity — \(viewModel.totalSelected) selected")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, AniccaTheme.Spacing.s20)
                    .padding(.bottom, AniccaTheme.Spacing.s20)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .navigationTitle(Strings.Log.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.refreshMonthCount()
        }
        .sheet(isPresented: $viewModel.showIntensitySheet) {
            IntensitySheet(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallView()
        }
        .alert("Something went wrong", isPresented: errorBinding) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s4) {
            Text(Strings.Log.title).anicca(.largeTitle)
            Text(Strings.Log.subtitle).anicca(.subheadline)
            Text("Check-in #\(viewModel.nextCheckInNumber)").anicca(.caption)
        }
    }

    private func warningBanner(_ message: String) -> some View {
        HStack(spacing: AniccaTheme.Spacing.s8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AniccaTheme.warning)
            Text(message).anicca(.subheadline)
            Spacer()
        }
        .padding(AniccaTheme.Spacing.s12)
        .background {
            RoundedRectangle(cornerRadius: AniccaTheme.Radius.button, style: .continuous)
                .fill(AniccaTheme.warning.opacity(0.15))
        }
    }

    private var expansionControls: some View {
        HStack {
            Spacer()
            Button(viewModel.expandedCenters.count == EnergyCenter.allCases.count ? Strings.Log.collapseAll : Strings.Log.expandAll) {
                withAnimation(AniccaTheme.springAnimation) {
                    viewModel.setExpanded(viewModel.expandedCenters.count != EnergyCenter.allCases.count)
                }
            }
            .buttonStyle(GhostButtonStyle())
        }
    }

    private var emotionSections: some View {
        VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s12) {
            ForEach(EnergyCenter.allCases) { center in
                if viewModel.centerHasResults(center) {
                    sectionCard(center)
                }
            }
        }
    }

    private func sectionCard(_ center: EnergyCenter) -> some View {
        VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s12) {
            Button {
                withAnimation(AniccaTheme.springAnimation) {
                    viewModel.toggleSection(center)
                }
            } label: {
                HStack(spacing: AniccaTheme.Spacing.s12) {
                    Circle().fill(center.color).frame(width: 14, height: 14)
                        .accessibilityLabel("\(center.displayName) color indicator")
                    VStack(alignment: .leading, spacing: 2) {
                        Text(center.displayName).anicca(.headline)
                        Text(center.subtitle).anicca(.caption)
                    }
                    Spacer()
                    Image(systemName: viewModel.expandedCenters.contains(center) ? "chevron.up" : "chevron.down")
                        .foregroundStyle(AniccaTheme.textSecondary)
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())

            if viewModel.expandedCenters.contains(center) {
                LazyVGrid(columns: columns, spacing: AniccaTheme.Spacing.s8) {
                    ForEach(viewModel.filteredEmotions(for: center)) { emotion in
                        emotionPill(emotion)
                    }
                }
            }
        }
        .aniccaCard()
    }

    private func emotionPill(_ emotion: Emotion) -> some View {
        let isSelected = viewModel.selectedEmotions[emotion] != nil
        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(AniccaTheme.springAnimation) {
                viewModel.toggle(emotion)
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: emotion.sfSymbol)
                    .font(.system(size: 14, weight: .semibold))
                Text(emotion.name)
                    .font(.system(size: 13, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Text(emotion.description)
                    .font(.system(size: 10, weight: .regular))
                    .multilineTextAlignment(.center)
                    .opacity(0.8)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, AniccaTheme.Spacing.s8)
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(isSelected ? Color.white : emotion.center.color)
            .background {
                RoundedRectangle(cornerRadius: AniccaTheme.Radius.button, style: .continuous)
                    .fill(isSelected ? emotion.center.color : Color.white.opacity(0.7))
                    .overlay {
                        RoundedRectangle(cornerRadius: AniccaTheme.Radius.button, style: .continuous)
                            .stroke(emotion.center.color.opacity(isSelected ? 0 : 0.35), lineWidth: 1)
                    }
            }
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(emotion.name), \(emotion.center.displayName) center")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var successToast: some View {
        HStack(spacing: AniccaTheme.Spacing.s12) {
            if let center = viewModel.savedDominantCenter {
                Image(systemName: center.sfSymbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(center.color)
            } else {
                Image(systemName: "sparkles")
                    .foregroundStyle(AniccaTheme.brandPrimary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(Strings.Log.savedToast).anicca(.headline)
                if entitlements.isPro {
                    Text("🔥 \(viewModel.savedStreak) day streak").anicca(.caption)
                }
            }
            Spacer()
        }
        .padding(AniccaTheme.Spacing.s16)
        .aniccaCard()
        .padding(.horizontal, AniccaTheme.Spacing.s20)
    }
}

// MARK: - Intensity Sheet

private struct IntensitySheet: View {
    @ObservedObject var viewModel: LogViewModel
    @Environment(\.dismiss) private var dismiss
 
    var body: some View {
        NavigationStack {
            ZStack {
                AniccaTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: AniccaTheme.Spacing.s20) {
                        ForEach(Array(viewModel.selectedEmotions.keys).sorted { e1, e2 in
                            if e1.center.number != e2.center.number {
                                return e1.center.number < e2.center.number
                            }
                            return e1.name < e2.name
                        }, id: \.self) { emotion in
                            IntensityRow(
                                emotion: emotion,
                                value: Binding(
                                    get: { viewModel.selectedEmotions[emotion] ?? 3 },
                                    set: { viewModel.updateIntensity($0, for: emotion) }
                                ),
                                isTouched: viewModel.touchedIntensity.contains(emotion)
                            )
                        }
 
                        VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s8) {
                            Text("Note").anicca(.subheadline)
                            TextEditor(text: $viewModel.note)
                                .frame(minHeight: 100)
                                .padding(AniccaTheme.Spacing.s8)
                                .background {
                                    RoundedRectangle(cornerRadius: AniccaTheme.Radius.button, style: .continuous)
                                        .fill(Color.white.opacity(0.8))
                                }
                                .overlay(alignment: .topLeading) {
                                    if viewModel.note.isEmpty {
                                        Text(Strings.Log.notePlaceholder)
                                            .anicca(.body)
                                            .foregroundStyle(AniccaTheme.textMuted)
                                            .padding(AniccaTheme.Spacing.s16)
                                            .allowsHitTesting(false)
                                    }
                                }
                        }
                        .aniccaCard()
 
                        if !viewModel.canSave {
                            let untouchedCount = viewModel.selectedEmotions.count - viewModel.touchedIntensity.count
                            HStack(spacing: AniccaTheme.Spacing.s8) {
                                Image(systemName: "hand.tap.fill")
                                    .foregroundStyle(AniccaTheme.warning)
                                Text("Please confirm the intensity for all emotions by tapping or adjusting each slider (\(untouchedCount) remaining).")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(AniccaTheme.textSecondary)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(AniccaTheme.Spacing.s12)
                            .background {
                                RoundedRectangle(cornerRadius: AniccaTheme.Radius.button)
                                    .fill(AniccaTheme.warning.opacity(0.1))
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: AniccaTheme.Radius.button)
                                    .stroke(AniccaTheme.warning.opacity(0.2), lineWidth: 1)
                            }
                            .transition(.opacity)
                        }
 
                        Button {
                            Task { await viewModel.save() }
                        } label: {
                            HStack {
                                if viewModel.isSaving { ProgressView().tint(.white) }
                                Text(Strings.Log.saveCheckIn)
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle(disabled: !viewModel.canSave || viewModel.isSaving))
                        .disabled(!viewModel.canSave || viewModel.isSaving)
                    }
                    .padding(AniccaTheme.Spacing.s20)
                }
            }
            .navigationTitle(Strings.Log.intensityTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Log.cancel) { dismiss() }
                }
            }
        }
    }
}
 
private struct IntensityRow: View {
    let emotion: Emotion
    @Binding var value: Int
    let isTouched: Bool
    @State private var lastHapticValue: Int = -1
 
    var body: some View {
        VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s8) {
            HStack(spacing: AniccaTheme.Spacing.s8) {
                Circle()
                    .fill(isTouched ? emotion.center.color : AniccaTheme.textMuted.opacity(0.4))
                    .frame(width: 12, height: 12)
                Text(emotion.name)
                    .anicca(.headline)
                    .foregroundStyle(isTouched ? AniccaTheme.textPrimary : AniccaTheme.textSecondary)
                Spacer()
                if isTouched {
                    Text("\(value)/5")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(emotion.center.color)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.tap")
                            .font(.system(size: 11))
                        Text("Tap to set")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(AniccaTheme.warning)
                }
            }
            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { newValue in
                        let rounded = Int(newValue.rounded())
                        if rounded != lastHapticValue {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            lastHapticValue = rounded
                        }
                        value = rounded
                    }
                ),
                in: 1...5,
                step: 1
            )
            .tint(isTouched ? emotion.center.color : AniccaTheme.textMuted.opacity(0.4))
 
            HStack(spacing: AniccaTheme.Spacing.s8) {
                ForEach(1...5, id: \.self) { i in
                    Circle()
                        .fill(i <= value ? (isTouched ? emotion.center.color : AniccaTheme.textMuted.opacity(0.4)) : AniccaTheme.textMuted.opacity(0.2))
                        .frame(width: 10, height: 10)
                }
            }
        }
        .aniccaCard(padding: AniccaTheme.Spacing.s16)
        .opacity(isTouched ? 1.0 : 0.75)
    }
}
