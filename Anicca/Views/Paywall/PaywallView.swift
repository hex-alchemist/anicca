import SwiftUI
import SafariServices

struct PaywallView: View {
    @StateObject private var viewModel = PaywallViewModel()
    @EnvironmentObject private var entitlements: EntitlementManager
    @Environment(\.dismiss) private var dismiss
    @State private var safariURL: URL?

    var body: some View {
        ZStack {
            MeshGradientBackground()
            ScrollView {
                VStack(spacing: AniccaTheme.Spacing.s20) {
                    dismissBar
                    iconBlock
                    headlineBlock
                    featureList
                    intervalToggle
                    purchaseButtons
                    Button(Strings.Paywall.restore) {
                        Task { await viewModel.restore() }
                    }
                    .buttonStyle(GhostButtonStyle())
                    footer
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .anicca(.caption)
                            .foregroundStyle(AniccaTheme.error)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(AniccaTheme.Spacing.s20)
            }
        }
        .task {
            await viewModel.load()
        }
        .onChange(of: viewModel.purchaseCompleted) { _, completed in
            if completed { dismiss() }
        }
        .sheet(item: $safariURL) { url in
            SafariView(url: url)
        }
    }

    // MARK: - Sections

    private var dismissBar: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(AniccaTheme.textSecondary.opacity(0.6))
            }
            .accessibilityLabel("Close paywall")
        }
    }

    private var iconBlock: some View {
        Image(systemName: "sparkles.rectangle.stack.fill")
            .font(.system(size: 64, weight: .semibold))
            .foregroundStyle(AniccaTheme.brandPrimary)
            .padding(.top, AniccaTheme.Spacing.s8)
    }

    private var headlineBlock: some View {
        VStack(spacing: AniccaTheme.Spacing.s8) {
            Text(Strings.Paywall.headline).anicca(.title).multilineTextAlignment(.center)
            Text(Strings.Paywall.subheadline)
                .anicca(.body)
                .foregroundStyle(AniccaTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var featureList: some View {
        VStack(spacing: 0) {
            featureHeader
            featureRow("Check-ins per month", free: "30", pro: "Unlimited")
            featureRow("Chakra radar chart", free: "✓", pro: "✓")
            featureRow("7-day timeline", free: "✓", pro: "✓")
            featureRow("14-day + Monthly timeline", free: "—", pro: "✓")
            featureRow("Weekly summary", free: "—", pro: "✓")
            featureRow("AI insight (Gemini)", free: "—", pro: "✓")
            featureRow("Check-in streak tracking", free: "—", pro: "✓")
            featureRow("Reminder scheduling", free: "—", pro: "✓")
            featureRow("PDF export", free: "—", pro: "✓")
            featureRow("Yggdrasil integration", free: "—", pro: "Bundle")
        }
        .aniccaCard(padding: AniccaTheme.Spacing.s12)
    }

    private var featureHeader: some View {
        HStack {
            Text("Feature").anicca(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Free").anicca(.subheadline)
                .frame(width: 75)
            Text("Pro").anicca(.subheadline)
                .frame(width: 75)
        }
        .padding(.vertical, AniccaTheme.Spacing.s8)
        .background {
            Rectangle().fill(AniccaTheme.surfaceElevated.opacity(0.7))
        }
    }

    private func featureRow(_ name: String, free: String, pro: String) -> some View {
        HStack {
            Text(name).anicca(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(free)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AniccaTheme.textSecondary)
                .frame(width: 75)
            Text(pro)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AniccaTheme.brandPrimary)
                .frame(width: 75)
        }
        .padding(.vertical, AniccaTheme.Spacing.s8)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AniccaTheme.textMuted.opacity(0.15)).frame(height: 0.5)
        }
    }

    private var intervalToggle: some View {
        HStack(spacing: 0) {
            ForEach([SubscriptionInterval.monthly, .annual], id: \.self) { interval in
                Button {
                    withAnimation(AniccaTheme.springAnimation) {
                        viewModel.selectedInterval = interval
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(interval == .monthly ? Strings.Paywall.monthly : Strings.Paywall.annual)
                            .font(.system(size: 15, weight: .semibold))
                        if interval == .annual {
                            Text(Strings.Paywall.saveBadge)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(AniccaTheme.success))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AniccaTheme.Spacing.s12)
                    .foregroundStyle(viewModel.selectedInterval == interval ? .white : AniccaTheme.textPrimary)
                    .background {
                        if viewModel.selectedInterval == interval {
                            RoundedRectangle(cornerRadius: AniccaTheme.Radius.pill, style: .continuous)
                                .fill(AniccaTheme.brandPrimary)
                        }
                    }
                }
            }
        }
        .padding(4)
        .background {
            RoundedRectangle(cornerRadius: AniccaTheme.Radius.pill, style: .continuous)
                .fill(Color.white.opacity(0.6))
        }
    }

    private var purchaseButtons: some View {
        VStack(spacing: AniccaTheme.Spacing.s12) {
            Button {
                Task { await viewModel.buy(.pro) }
            } label: {
                HStack {
                    if viewModel.isWorking { ProgressView().tint(.white) }
                    Text("\(Strings.Paywall.startPro) — \(viewModel.proPriceString)")
                }
            }
            .buttonStyle(PrimaryButtonStyle(disabled: viewModel.isWorking))
            .disabled(viewModel.isWorking)

            Button {
                Task { await viewModel.buy(.bundle) }
            } label: {
                Text("\(Strings.Paywall.getBundle) — \(viewModel.bundlePriceString)")
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(viewModel.isWorking)
        }
    }

    private var footer: some View {
        VStack(spacing: 4) {
            Text(Strings.Paywall.footer).anicca(.caption)
            HStack(spacing: AniccaTheme.Spacing.s8) {
                Button("Privacy") { safariURL = AppConfig.privacyPolicyURL }
                    .buttonStyle(GhostButtonStyle())
                Button("Terms") { safariURL = AppConfig.termsOfUseURL }
                    .buttonStyle(GhostButtonStyle())
            }
        }
    }
}

// MARK: - Safari wrapper

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

extension URL: Identifiable {
    public var id: String { absoluteString }
}
