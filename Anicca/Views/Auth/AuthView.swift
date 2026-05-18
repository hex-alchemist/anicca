import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @FocusState private var focusedField: Field?

    private enum Field {
        case email, password, confirmPassword, displayName
    }

    var body: some View {
        ZStack {
            MeshGradientBackground()
            ScrollView {
                VStack(spacing: AniccaTheme.Spacing.s24) {
                    headerBlock
                    formCard
                    if let info = viewModel.infoMessage {
                        Text(info)
                            .anicca(.caption)
                            .foregroundStyle(AniccaTheme.success)
                            .multilineTextAlignment(.center)
                    }
                    if let error = viewModel.generalError {
                        Text(error)
                            .anicca(.caption)
                            .foregroundStyle(AniccaTheme.error)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(AniccaTheme.Spacing.s20)
                .padding(.top, AniccaTheme.Spacing.s32)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var headerBlock: some View {
        VStack(spacing: AniccaTheme.Spacing.s8) {
            Image(systemName: "sparkles")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(AniccaTheme.brandPrimary)
            Text(Strings.Auth.welcomeTitle)
                .anicca(.title)
                .multilineTextAlignment(.center)
            Text(viewModel.mode == .signIn
                 ? "Sign in to read your energy."
                 : "Create your account to begin.")
                .anicca(.subheadline)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, AniccaTheme.Spacing.s8)
    }

    private var formCard: some View {
        VStack(spacing: AniccaTheme.Spacing.s16) {
            appleButton
            googleButton
            HStack {
                Rectangle().fill(AniccaTheme.textMuted.opacity(0.3)).frame(height: 1)
                Text(Strings.Auth.or)
                    .anicca(.caption)
                    .padding(.horizontal, AniccaTheme.Spacing.s12)
                Rectangle().fill(AniccaTheme.textMuted.opacity(0.3)).frame(height: 1)
            }
            if viewModel.mode == .signUp {
                fieldGroup(
                    title: Strings.Auth.displayName,
                    text: $viewModel.displayName,
                    error: viewModel.displayNameError,
                    focus: .displayName,
                    isSecure: false,
                    keyboard: .default,
                    textContentType: .name
                )
            }
            fieldGroup(
                title: Strings.Auth.email,
                text: $viewModel.email,
                error: viewModel.emailError,
                focus: .email,
                isSecure: false,
                keyboard: .emailAddress,
                textContentType: .emailAddress
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            fieldGroup(
                title: Strings.Auth.password,
                text: $viewModel.password,
                error: viewModel.passwordError,
                focus: .password,
                isSecure: true,
                keyboard: .default,
                textContentType: viewModel.mode == .signIn ? .password : .newPassword
            )

            if viewModel.mode == .signUp {
                fieldGroup(
                    title: Strings.Auth.confirmPassword,
                    text: $viewModel.confirmPassword,
                    error: viewModel.confirmPasswordError,
                    focus: .confirmPassword,
                    isSecure: true,
                    keyboard: .default,
                    textContentType: .newPassword
                )
            }

            Button {
                Task { await viewModel.submit() }
            } label: {
                HStack {
                    if viewModel.isWorking {
                        ProgressView().tint(.white)
                    }
                    Text(viewModel.primaryActionTitle)
                }
            }
            .buttonStyle(PrimaryButtonStyle(disabled: viewModel.isWorking))
            .disabled(viewModel.isWorking)
            .accessibilityLabel(viewModel.primaryActionTitle)

            if viewModel.mode == .signIn {
                Button(Strings.Auth.forgotPassword) {
                    Task { await viewModel.sendPasswordReset() }
                }
                .buttonStyle(GhostButtonStyle())
            }

            Button(viewModel.toggleTitle) {
                withAnimation(AniccaTheme.springAnimation) {
                    viewModel.toggleMode()
                }
            }
            .buttonStyle(GhostButtonStyle())
        }
        .aniccaCard()
    }

    private var appleButton: some View {
        SignInWithAppleButton(.continue) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { _ in
            Task { await viewModel.signInWithApple() }
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 50)
        .clipShape(RoundedRectangle(cornerRadius: AniccaTheme.Radius.button, style: .continuous))
        .accessibilityLabel(Strings.Auth.continueWithApple)
    }

    private var googleButton: some View {
        Button {
            Task { await viewModel.signInWithGoogle() }
        } label: {
            HStack(spacing: AniccaTheme.Spacing.s8) {
                Image(systemName: "g.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                Text(Strings.Auth.continueWithGoogle)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(AniccaTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background {
                RoundedRectangle(cornerRadius: AniccaTheme.Radius.button, style: .continuous)
                    .fill(Color.white)
                    .overlay {
                        RoundedRectangle(cornerRadius: AniccaTheme.Radius.button, style: .continuous)
                            .stroke(AniccaTheme.textMuted.opacity(0.3), lineWidth: 1)
                    }
            }
        }
        .accessibilityLabel(Strings.Auth.continueWithGoogle)
    }

    @ViewBuilder
    private func fieldGroup(
        title: String,
        text: Binding<String>,
        error: String?,
        focus: Field,
        isSecure: Bool,
        keyboard: UIKeyboardType,
        textContentType: UITextContentType?
    ) -> some View {
        VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s4) {
            Text(title)
                .anicca(.subheadline)
            Group {
                if isSecure {
                    SecureField(title, text: text)
                } else {
                    TextField(title, text: text)
                }
            }
            .focused($focusedField, equals: focus)
            .keyboardType(keyboard)
            .textContentType(textContentType)
            .padding(AniccaTheme.Spacing.s12)
            .background {
                RoundedRectangle(cornerRadius: AniccaTheme.Radius.button, style: .continuous)
                    .fill(Color.white.opacity(0.7))
                    .overlay {
                        RoundedRectangle(cornerRadius: AniccaTheme.Radius.button, style: .continuous)
                            .stroke(error == nil ? AniccaTheme.textMuted.opacity(0.25) : AniccaTheme.error, lineWidth: 1)
                    }
            }
            if let error {
                Text(error)
                    .anicca(.caption)
                    .foregroundStyle(AniccaTheme.error)
            }
        }
    }
}
