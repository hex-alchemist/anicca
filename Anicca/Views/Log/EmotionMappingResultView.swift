import SwiftUI

/// Mode 1 confirmation screen — shown after Gemini maps free text to emotions.
/// Users can review, adjust intensities, remove emotions, or add more before saving.
struct EmotionMappingResultView: View {
    @ObservedObject var viewModel: LogViewModel
    @State private var showBrowseSheet = false

    var body: some View {
        ZStack {
            MeshGradientBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s20) {

                    // MARK: Header
                    VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s8) {
                        Text("We mapped this to…")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(AniccaTheme.textPrimary)
                            .tracking(-0.3)
                        Text("Tap the dots to adjust intensity. Hit ✕ to remove an emotion.")
                            .anicca(.subheadline)
                            .lineSpacing(3)
                    }

                    // MARK: Mapped emotion cards
                    if viewModel.mappedEmotions.isEmpty {
                        nothingMappedView
                    } else {
                        VStack(spacing: AniccaTheme.Spacing.s12) {
                            ForEach($viewModel.mappedEmotions) { $mapped in
                                MappedEmotionCard(mapped: $mapped) {
                                    withAnimation(AniccaTheme.springAnimation) {
                                        viewModel.removeMappedEmotion(mapped)
                                    }
                                }
                            }
                        }
                    }

                    // MARK: Add more
                    Button {
                        showBrowseSheet = true
                    } label: {
                        HStack(spacing: AniccaTheme.Spacing.s8) {
                            Image(systemName: "plus.circle")
                            Text("Add more emotions")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AniccaTheme.brandPrimary)
                        .padding(.vertical, AniccaTheme.Spacing.s12)
                        .frame(maxWidth: .infinity)
                        .background {
                            RoundedRectangle(cornerRadius: AniccaTheme.Radius.button, style: .continuous)
                                .fill(AniccaTheme.brandPrimary.opacity(0.1))
                                .overlay {
                                    RoundedRectangle(cornerRadius: AniccaTheme.Radius.button, style: .continuous)
                                        .stroke(AniccaTheme.brandPrimary.opacity(0.25), lineWidth: 1)
                                }
                        }
                    }
                    .buttonStyle(.plain)

                    // MARK: CTAs
                    VStack(spacing: AniccaTheme.Spacing.s12) {
                        Button {
                            viewModel.commitMappedEmotions()
                            viewModel.presentIntensity()
                        } label: {
                            HStack(spacing: AniccaTheme.Spacing.s8) {
                                Text("Looks right")
                                Image(systemName: "arrow.right")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle(disabled: viewModel.mappedEmotions.isEmpty))
                        .disabled(viewModel.mappedEmotions.isEmpty)

                        Button {
                            withAnimation(AniccaTheme.springAnimation) {
                                viewModel.mappedEmotions.removeAll()
                                viewModel.freeText = ""
                                viewModel.entryMode = .freeText
                            }
                        } label: {
                            Text("Start over")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(AniccaTheme.textMuted)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: AniccaTheme.Spacing.s32)
                }
                .padding(AniccaTheme.Spacing.s20)
            }
        }
        .navigationTitle("Your feelings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    withAnimation(AniccaTheme.springAnimation) {
                        viewModel.mappedEmotions.removeAll()
                        viewModel.freeText = ""
                        viewModel.entryMode = .freeText
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundStyle(AniccaTheme.brandPrimary)
                }
            }
        }
        .sheet(isPresented: $showBrowseSheet) {
            EmotionBrowseView(viewModel: viewModel, prefillSearch: "", isSheet: true)
        }
    }

    private var nothingMappedView: some View {
        VStack(spacing: AniccaTheme.Spacing.s12) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 36))
                .foregroundStyle(AniccaTheme.textMuted)
            Text("All emotions were removed.\nTap \"Add more\" or start over.")
                .anicca(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(AniccaTheme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(AniccaTheme.Spacing.s24)
    }
}

// MARK: - Mapped Emotion Card

private struct MappedEmotionCard: View {
    @Binding var mapped: MappedEmotion
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s12) {
            // Top row: chakra dot + name + remove button
            HStack(spacing: AniccaTheme.Spacing.s8) {
                Circle()
                    .fill(mapped.emotion.center.color)
                    .frame(width: 10, height: 10)
                VStack(alignment: .leading, spacing: 2) {
                    Text(mapped.emotion.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AniccaTheme.textPrimary)
                    Text(mapped.emotion.center.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(mapped.emotion.center.color)
                }
                Spacer()
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AniccaTheme.textMuted)
                }
                .buttonStyle(.plain)
            }

            // Description
            Text(mapped.emotion.description)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AniccaTheme.textSecondary)
                .lineLimit(2)

            // Intensity dots row
            HStack(spacing: AniccaTheme.Spacing.s8) {
                Text("Intensity")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AniccaTheme.textSecondary)
                Spacer()
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { i in
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            mapped.intensity = i
                            mapped.isTouched = true
                        } label: {
                            Circle()
                                .fill(i <= mapped.intensity ? mapped.emotion.center.color : AniccaTheme.textMuted.opacity(0.25))
                                .frame(width: 22, height: 22)
                                .scaleEffect(i <= mapped.intensity ? 1.1 : 1.0)
                                .animation(AniccaTheme.springAnimation, value: mapped.intensity)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(AniccaTheme.Spacing.s16)
        .background {
            RoundedRectangle(cornerRadius: AniccaTheme.Radius.card, style: .continuous)
                .fill(Color.white.opacity(0.88))
                .overlay {
                    RoundedRectangle(cornerRadius: AniccaTheme.Radius.card, style: .continuous)
                        .stroke(mapped.emotion.center.color.opacity(0.2), lineWidth: 1.5)
                }
        }
        .shadow(color: mapped.emotion.center.color.opacity(0.08), radius: 8, y: 3)
    }
}
