import SwiftUI

/// LogView is now a coordinator that routes between Mode 1 (Free Text), the mapping
/// confirmation screen, and Mode 2 (Browse). All three share a single LogViewModel.
struct LogView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var entitlements: EntitlementManager
    @StateObject private var viewModel = LogViewModel()

    var body: some View {
        ZStack {
            // Background is always visible
            MeshGradientBackground()

            // Route based on current entryMode
            Group {
                switch viewModel.entryMode {
                case .freeText:
                    FreeTextEntryView(viewModel: viewModel)
                        .transition(.asymmetric(
                            insertion: .opacity,
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))

                case .mappingResult:
                    EmotionMappingResultView(viewModel: viewModel)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        ))

                case .browse(let prefill):
                    EmotionBrowseView(viewModel: viewModel, prefillSearch: prefill)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            .animation(AniccaTheme.springAnimation, value: viewModel.entryMode)

            // Success toast — always on top
            if viewModel.showSavedToast {
                VStack {
                    Spacer()
                    successToast
                        .padding(.bottom, AniccaTheme.Spacing.s32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(AniccaTheme.springAnimation, value: viewModel.showSavedToast)
            }
        }
        .onAppear {
            viewModel.refreshMonthCount()
        }
        .sheet(isPresented: $viewModel.showIntensitySheet) {
            IntensitySheetWrapper(viewModel: viewModel)
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

// MARK: - Intensity Sheet (internal to LogView coordinator)

struct IntensitySheetWrapper: View {
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
                            IntensityRowView(
                                emotion: emotion,
                                value: Binding(
                                    get: { viewModel.selectedEmotions[emotion] ?? 3 },
                                    set: { viewModel.updateIntensity($0, for: emotion) }
                                ),
                                isTouched: viewModel.touchedIntensity.contains(emotion)
                            )
                        }

                        // Note field
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

                        // Warning: untouched sliders
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

                        // Save button
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

// MARK: - Intensity Row (shared component)

struct IntensityRowView: View {
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
