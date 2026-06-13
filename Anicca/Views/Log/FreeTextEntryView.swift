import SwiftUI

/// Mode 1 — Default check-in entry screen.
/// Shows a large text input and maps free text to emotions via Gemini Flash.
struct FreeTextEntryView: View {
    @ObservedObject var viewModel: LogViewModel
    @FocusState private var isTextFocused: Bool

    var body: some View {
        ZStack {
            MeshGradientBackground()
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture {
                isTextFocused = false
            }
            ScrollView {
                VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s24) {
                    // MARK: Header
                    VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s8) {
                        Text("How are you feeling?")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(AniccaTheme.textPrimary)
                            .tracking(-0.3)
                        Text("Describe it in your own words — a word, a sentence, anything.")
                            .anicca(.subheadline)
                            .lineSpacing(3)
                    }

                    // MARK: Text input card
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: AniccaTheme.Radius.card, style: .continuous)
                            .fill(Color.white.opacity(0.88))
                            .shadow(color: AniccaTheme.cardShadowColor, radius: 12, y: 4)

                        if viewModel.freeText.isEmpty {
                            Text("e.g. anxious, kind of numb, like I want to disappear...")
                                .font(.system(size: 17, weight: .regular))
                                .foregroundStyle(AniccaTheme.textMuted)
                                .padding(.horizontal, AniccaTheme.Spacing.s16)
                                .padding(.top, AniccaTheme.Spacing.s16)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $viewModel.freeText)
                            .font(.system(size: 17, weight: .regular))
                            .foregroundStyle(AniccaTheme.textPrimary)
                            .frame(minHeight: 160)
                            .padding(AniccaTheme.Spacing.s12)
                            .scrollContentBackground(.hidden)
                            .focused($isTextFocused)
                    }
                    .frame(minHeight: 160)

                    // MARK: CTA Buttons
                    VStack(spacing: AniccaTheme.Spacing.s12) {
                        Button {
                            isTextFocused = false
                            Task { await viewModel.mapFreeText() }
                        } label: {
                            HStack(spacing: AniccaTheme.Spacing.s8) {
                                if viewModel.isMappingText {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.9)
                                    Text("Reading your feelings...")
                                } else {
                                    Text("Map my feelings")
                                    Image(systemName: "arrow.right")
                                }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle(disabled: viewModel.freeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isMappingText))
                        .disabled(viewModel.freeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isMappingText)
                        .animation(AniccaTheme.springAnimation, value: viewModel.isMappingText)

                        Button {
                            viewModel.entryMode = .browse(prefillSearch: "")
                        } label: {
                            Text("Browse emotions instead")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(AniccaTheme.brandPrimary)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: AniccaTheme.Spacing.s32)
                }
                .padding(AniccaTheme.Spacing.s20)
            }
        }
        .navigationTitle("Check-in #\(viewModel.nextCheckInNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    isTextFocused = false
                    viewModel.reset()
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()

                Button("Done") {
                    isTextFocused = false
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                guard viewModel.entryMode == .freeText else { return }
                isTextFocused = true
            }
        }
    }
}