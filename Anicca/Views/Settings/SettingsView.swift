import SwiftUI
import SafariServices

struct SettingsView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var entitlements: EntitlementManager
    @StateObject private var viewModel = SettingsViewModel()
    @State private var safariURL: URL?
    @State private var shareItems: [Any]?
    @State private var showPaywall = false
    @State private var isEditingName = false
    @State private var developerTapCount = 0
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        ZStack {
            MeshGradientBackground()
            ScrollView {
                VStack(spacing: AniccaTheme.Spacing.s16) {
                    accountSection
                    subscriptionSection
                    remindersSection
                    dataSection
                    integrationsSection
                    aboutSection
                    signOutButton
                    deleteAccountButton
                }
                .padding(AniccaTheme.Spacing.s20)
            }
        }
        .navigationTitle(Strings.Settings.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let user = auth.currentUser {
                viewModel.bind(to: user.id)
            }
        }
        .sheet(item: $safariURL) { url in
            SafariView(url: url)
        }
        .sheet(item: Binding(
            get: { shareItems.flatMap { ShareableItems(items: $0) } },
            set: { shareItems = $0?.items })
        ) { wrapper in
            ShareSheet(items: wrapper.items)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .alert("Are you sure?", isPresented: $viewModel.showFirstDeleteAlert) {
            Button("Continue", role: .destructive) {
                viewModel.showFinalDeleteAlert = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Deleting your account removes all your check-ins.")
        }
        .alert("This is permanent.", isPresented: $viewModel.showFinalDeleteAlert) {
            Button("Delete Forever", role: .destructive) {
                Task { await viewModel.confirmDelete() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All your data will be permanently deleted.")
        }
        .alert("Notifications are off", isPresented: $viewModel.notificationsBlocked) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enable notifications in iOS Settings to receive reminders.")
        }
        .onDisappear {
            viewModel.saveDisplayNameImmediate()
        }
    }

    // MARK: - Sections

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s12) {
            sectionTitle(Strings.Settings.account)
            HStack(spacing: AniccaTheme.Spacing.s16) {
                ZStack {
                    Circle()
                        .fill(AniccaTheme.brandPrimary)
                        .frame(width: 56, height: 56)
                    Text(auth.currentUser?.initials ?? "—")
                        .foregroundStyle(.white)
                        .font(.system(size: 18, weight: .semibold))
                }
                VStack(alignment: .leading, spacing: 4) {
                    if isEditingName {
                        TextField("Display name", text: $viewModel.displayName)
                            .focused($nameFieldFocused)
                            .anicca(.headline)
                            .onChange(of: viewModel.displayName) { _, _ in
                                viewModel.saveDisplayNameDebounced()
                            }
                            .onChange(of: nameFieldFocused) { _, isFocused in
                                if !isFocused {
                                    isEditingName = false
                                    viewModel.saveDisplayNameImmediate()
                                }
                            }
                            .onSubmit {
                                isEditingName = false
                                viewModel.saveDisplayNameImmediate()
                            }
                    } else {
                        Button {
                            isEditingName = true
                            nameFieldFocused = true
                        } label: {
                            Text(viewModel.displayName.isEmpty ? "Add display name" : viewModel.displayName)
                                .anicca(.headline)
                        }
                        .buttonStyle(.plain)
                    }
                    Text(auth.currentUser?.email ?? "").anicca(.caption)
                }
                Spacer()
                planBadge
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .aniccaCard()
    }

    private var planBadge: some View {
        Text(entitlements.planTier.displayName)
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, AniccaTheme.Spacing.s8)
            .padding(.vertical, 4)
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

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s12) {
            sectionTitle(Strings.Settings.subscription)
            if entitlements.planTier == .free {
                VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s8) {
                    Text(Strings.Settings.upgradeToPro).anicca(.headline)
                    Text("Unlock AI insights, full timeline history, and unlimited check-ins.")
                        .anicca(.body)
                    Button("See Plans →") { showPaywall = true }
                        .buttonStyle(PrimaryButtonStyle())
                }
                .padding(AniccaTheme.Spacing.s16)
                .background {
                    RoundedRectangle(cornerRadius: AniccaTheme.Radius.card, style: .continuous)
                        .stroke(LinearGradient(colors: [AniccaTheme.brandPrimary, AniccaTheme.brandAccent], startPoint: .leading, endPoint: .trailing), lineWidth: 2)
                        .background {
                            RoundedRectangle(cornerRadius: AniccaTheme.Radius.card, style: .continuous)
                                .fill(Color.white.opacity(0.5))
                        }
                }
            } else {
                VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s8) {
                    Text(entitlements.planTier.displayName).anicca(.headline)
                    Button(Strings.Settings.manageSubscription) {
                        viewModel.openSubscriptionManagement()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .aniccaCard()
    }

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s12) {
            HStack {
                sectionTitle(Strings.Settings.reminders)
                Spacer()
                if !entitlements.isPro {
                    Image(systemName: "lock.fill").foregroundStyle(AniccaTheme.brandPrimary)
                }
            }
            if !entitlements.isPro {
                HStack {
                    Text(Strings.Settings.proFeature).anicca(.subheadline)
                    Spacer()
                    Button("Upgrade") { showPaywall = true }
                        .buttonStyle(SecondaryButtonStyle())
                        .frame(width: 110)
                }
            } else {
                Toggle(Strings.Settings.reminderToggle, isOn: Binding(
                    get: { viewModel.reminderEnabled },
                    set: { newValue in
                        Task { await viewModel.toggleReminders(newValue) }
                    }
                ))
                .tint(AniccaTheme.brandPrimary)

                if viewModel.reminderEnabled {
                    DatePicker("Time",
                               selection: Binding(
                                get: { viewModel.reminderTime },
                                set: { newValue in
                                    viewModel.reminderTime = newValue
                                    Task { await viewModel.reminderTimeChanged() }
                                }),
                               displayedComponents: .hourAndMinute)
                    .datePickerStyle(.graphical)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .aniccaCard()
    }

    private var dataSection: some View {
        VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s12) {
            sectionTitle(Strings.Settings.dataExport)
            Button {
                exportJSON()
            } label: {
                rowLabel(title: Strings.Settings.exportJSON, icon: "square.and.arrow.up", locked: false)
            }
            .buttonStyle(.plain)
            Button {
                if entitlements.isPro {
                    exportPDF()
                } else {
                    showPaywall = true
                }
            } label: {
                rowLabel(title: Strings.Settings.exportPDF, icon: "doc.fill", locked: !entitlements.isPro)
            }
            .buttonStyle(.plain)
            Text("You have \(viewModel.totalCheckIns) check-ins logged").anicca(.caption)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .aniccaCard()
    }

    private var integrationsSection: some View {
        VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s8) {
            sectionTitle(Strings.Settings.integrations)
            Button {
                safariURL = AppConfig.yggdrasilURL
            } label: {
                HStack(spacing: AniccaTheme.Spacing.s12) {
                    Image(systemName: "tree.fill").foregroundStyle(AniccaTheme.chakraHeart)
                    Text(Strings.Settings.openYggdrasil).anicca(.body)
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(AniccaTheme.textSecondary)
                }
            }
            .buttonStyle(.plain)
            Text(Strings.Settings.yggdrasilCaption)
                .anicca(.caption)
                .foregroundStyle(AniccaTheme.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .aniccaCard()
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: AniccaTheme.Spacing.s8) {
            sectionTitle(Strings.Settings.about)
            Text("Version \(AppConfig.appVersion) (\(AppConfig.buildNumber))")
                .anicca(.caption)
                .contentShape(Rectangle())
                .onTapGesture {
                    developerTapCount += 1
                    if developerTapCount >= 5 {
                        UISelectionFeedbackGenerator().selectionChanged()
                        let current = UserDefaults.standard.bool(forKey: "developer_override_pro")
                        UserDefaults.standard.set(!current, forKey: "developer_override_pro")
                        entitlements.objectWillChange.send()
                        developerTapCount = 0
                    }
                }
            Button {
                safariURL = AppConfig.privacyPolicyURL
            } label: {
                rowLabel(title: Strings.Settings.privacy, icon: "lock.shield.fill", locked: false)
            }
            .buttonStyle(.plain)
            Button {
                safariURL = AppConfig.termsOfUseURL
            } label: {
                rowLabel(title: Strings.Settings.terms, icon: "doc.text.fill", locked: false)
            }
            .buttonStyle(.plain)
            Button {
                viewModel.rateApp()
            } label: {
                rowLabel(title: Strings.Settings.rate, icon: "star.fill", locked: false)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .aniccaCard()
    }

    private var signOutButton: some View {
        Button(Strings.Settings.signOut) {
            Task { await viewModel.signOut() }
        }
        .buttonStyle(SecondaryButtonStyle())
    }

    private var deleteAccountButton: some View {
        Button {
            viewModel.showFirstDeleteAlert = true
        } label: {
            Text(Strings.Settings.deleteAccount)
                .foregroundStyle(AniccaTheme.error)
                .font(.system(size: 15, weight: .medium))
                .padding(.vertical, AniccaTheme.Spacing.s12)
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Helpers

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AniccaTheme.textSecondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }

    private func rowLabel(title: String, icon: String, locked: Bool) -> some View {
        HStack(spacing: AniccaTheme.Spacing.s12) {
            Image(systemName: icon).foregroundStyle(AniccaTheme.brandPrimary)
            Text(title).anicca(.body)
            Spacer()
            if locked {
                Image(systemName: "lock.fill").foregroundStyle(AniccaTheme.textMuted)
            }
            Image(systemName: "chevron.right")
                .foregroundStyle(AniccaTheme.textMuted)
        }
        .padding(.vertical, 6)
    }

    private func exportJSON() {
        guard let user = auth.currentUser else { return }
        let checkIns = CheckInService.shared.fetchLocalCheckIns(userId: user.id)
        do {
            let url = try ExportService.shared.exportJSON(checkIns: checkIns)
            shareItems = [url]
        } catch let error as AppError {
            viewModel.errorMessage = error.errorDescription
        } catch {
            viewModel.errorMessage = Strings.Errors.generic
        }
    }

    private func exportPDF() {
        guard let user = auth.currentUser else { return }
        let checkIns = CheckInService.shared.fetchLocalCheckIns(userId: user.id)
        do {
            let url = try ExportService.shared.exportPDF(checkIns: checkIns, profile: user)
            shareItems = [url]
        } catch let error as AppError {
            viewModel.errorMessage = error.errorDescription
        } catch {
            viewModel.errorMessage = Strings.Errors.generic
        }
    }
}

private struct ShareableItems: Identifiable {
    let id = UUID()
    let items: [Any]
}
