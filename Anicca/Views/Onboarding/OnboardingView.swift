import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            MeshGradientBackground()
            VStack(spacing: 0) {
                topBar
                Spacer()
                Group {
                    switch viewModel.step {
                    case 0: WelcomeStep()
                    case 1: CentersStep()
                    case 2: HowItWorksStep()
                    case 3: RemindersStep(
                        time: $viewModel.reminderTime,
                        isWorking: viewModel.isWorking,
                        onEnable: {
                            Task {
                                await viewModel.completeWithReminders()
                                onComplete()
                            }
                        },
                        onSkip: {
                            Task {
                                await viewModel.completeWithoutReminders()
                                onComplete()
                            }
                        }
                    )
                    default: WelcomeStep()
                    }
                }
                .transition(.opacity.combined(with: .slide))
                Spacer()
                bottomBar
            }
            .padding(AniccaTheme.Spacing.s20)
        }
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: AniccaTheme.Spacing.s8) {
                ForEach(0..<viewModel.totalSteps, id: \.self) { index in
                    Circle()
                        .fill(index == viewModel.step ? AniccaTheme.brandPrimary : AniccaTheme.textMuted.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(AniccaTheme.springAnimation, value: viewModel.step)
                }
            }
            Spacer()
            if viewModel.canSkip {
                Button(Strings.Onboarding.skip) {
                    viewModel.skipToEnd()
                }
                .buttonStyle(GhostButtonStyle())
            }
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        if viewModel.step < viewModel.totalSteps - 1 {
            Button(viewModel.step == viewModel.totalSteps - 2 ? Strings.Onboarding.getStarted : Strings.Onboarding.next) {
                viewModel.next()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.top, AniccaTheme.Spacing.s16)
        } else {
            EmptyView()
        }
    }
}

private struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: AniccaTheme.Spacing.s24) {
            ZStack {
                Circle()
                    .fill(AniccaTheme.brandAccent.opacity(0.3))
                    .frame(width: 220, height: 220)
                Image(systemName: "sparkles")
                    .font(.system(size: 90, weight: .semibold))
                    .foregroundStyle(AniccaTheme.brandPrimary)
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AniccaTheme.chakraHeart)
                    .offset(x: 70, y: -50)
                Image(systemName: "waveform.path")
                    .font(.system(size: 28))
                    .foregroundStyle(AniccaTheme.chakraThroat)
                    .offset(x: -80, y: 50)
            }
            VStack(spacing: AniccaTheme.Spacing.s12) {
                Text(Strings.Onboarding.step1Title)
                    .anicca(.title)
                    .multilineTextAlignment(.center)
                Text(Strings.Onboarding.step1Body)
                    .anicca(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AniccaTheme.textSecondary)
            }
            .padding(.horizontal, AniccaTheme.Spacing.s12)
        }
    }
}

private struct CentersStep: View {
    @State private var expandedCenter: EnergyCenter?

    var body: some View {
        VStack(spacing: AniccaTheme.Spacing.s20) {
            Text(Strings.Onboarding.step2Title)
                .anicca(.title)
            Text(Strings.Onboarding.step2Body)
                .anicca(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AniccaTheme.Spacing.s24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AniccaTheme.Spacing.s12) {
                    ForEach(EnergyCenter.allCases) { center in
                        centerCard(center)
                    }
                }
                .padding(.horizontal, AniccaTheme.Spacing.s12)
            }
        }
    }

    private func centerCard(_ center: EnergyCenter) -> some View {
        let isExpanded = expandedCenter == center
        return Button {
            withAnimation(AniccaTheme.springAnimation) {
                expandedCenter = isExpanded ? nil : center
            }
        } label: {
            VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s8) {
                HStack(spacing: AniccaTheme.Spacing.s12) {
                    Circle().fill(center.color).frame(width: 14, height: 14)
                    Image(systemName: center.sfSymbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(center.color)
                }
                Text(center.displayName).anicca(.headline)
                Text(center.subtitle).anicca(.caption)
                if isExpanded {
                    Text(center.description)
                        .anicca(.body)
                        .foregroundStyle(AniccaTheme.textSecondary)
                        .padding(.top, AniccaTheme.Spacing.s4)
                }
            }
            .frame(width: isExpanded ? 260 : 180, alignment: .leading)
            .padding(AniccaTheme.Spacing.s16)
            .background {
                RoundedRectangle(cornerRadius: AniccaTheme.Radius.card, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: AniccaTheme.Radius.card, style: .continuous)
                            .fill(Color.white.opacity(0.6))
                    }
            }
            .shadow(color: AniccaTheme.cardShadowColor, radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(center.displayName) center. \(center.subtitle)")
    }
}

private struct HowItWorksStep: View {
    @State private var visibleSteps: [Bool] = [false, false, false]

    private let steps: [(String, String, String)] = [
        ("01", "Notice", "Pause and tune in to what you're feeling — there's no right answer."),
        ("02", "Tap", "Choose the emotions that resonate. They span all seven energy centers."),
        ("03", "Reflect", "Rate intensity and add an optional note. Patterns emerge over time.")
    ]

    var body: some View {
        VStack(spacing: AniccaTheme.Spacing.s24) {
            Text(Strings.Onboarding.step3Title)
                .anicca(.title)
            VStack(spacing: AniccaTheme.Spacing.s12) {
                ForEach(steps.indices, id: \.self) { i in
                    HStack(alignment: .top, spacing: AniccaTheme.Spacing.s16) {
                        Text(steps[i].0)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(AniccaTheme.brandPrimary)
                            .frame(width: 44, alignment: .leading)
                        VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s4) {
                            Text(steps[i].1).anicca(.headline)
                            Text(steps[i].2).anicca(.subheadline)
                        }
                    }
                    .opacity(visibleSteps[i] ? 1 : 0)
                    .offset(y: visibleSteps[i] ? 0 : 12)
                }
            }
            .aniccaCard()
        }
        .onAppear {
            for i in steps.indices {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 * Double(i + 1)) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        visibleSteps[i] = true
                    }
                }
            }
        }
    }
}

private struct RemindersStep: View {
    @Binding var time: Date
    let isWorking: Bool
    let onEnable: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: AniccaTheme.Spacing.s24) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(AniccaTheme.brandPrimary)
            VStack(spacing: AniccaTheme.Spacing.s12) {
                Text(Strings.Onboarding.step4Title).anicca(.title)
                Text(Strings.Onboarding.step4Body)
                    .anicca(.subheadline)
                    .multilineTextAlignment(.center)
            }
            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(height: 140)

            VStack(spacing: AniccaTheme.Spacing.s12) {
                Button {
                    onEnable()
                } label: {
                    HStack {
                        if isWorking { ProgressView().tint(.white) }
                        Text(Strings.Onboarding.enableReminders)
                    }
                }
                .buttonStyle(PrimaryButtonStyle(disabled: isWorking))
                .disabled(isWorking)

                Button(Strings.Onboarding.maybeLater) {
                    onSkip()
                }
                .buttonStyle(GhostButtonStyle())
            }
        }
        .padding(.horizontal, AniccaTheme.Spacing.s12)
    }
}
