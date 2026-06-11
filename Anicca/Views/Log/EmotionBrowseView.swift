import SwiftUI

/// Mode 2 — Flat alphabetical emotion browse with AI-powered search and chakra filter chips.
/// Can be presented full-screen (default) or as a sheet from the mapping result view.
struct EmotionBrowseView: View {
    @ObservedObject var viewModel: LogViewModel
    @Environment(\.dismiss) private var dismiss
    let prefillSearch: String
    let isSheet: Bool

    @State private var searchText: String = ""
    @State private var activeFilter: EnergyCenter? = nil
    @State private var aiSearchResults: [Emotion]? = nil
    @State private var isSearching: Bool = false
    @State private var searchTask: Task<Void, Never>? = nil

    init(viewModel: LogViewModel, prefillSearch: String = "", isSheet: Bool = false) {
        self.viewModel = viewModel
        self.prefillSearch = prefillSearch
        self.isSheet = isSheet
        _searchText = State(initialValue: prefillSearch)
    }

    // MARK: - Derived emotion lists

    private var baseList: [Emotion] {
        let pool: [Emotion]
        if let filter = activeFilter {
            pool = EmotionLibrary.byCenter[filter] ?? []
        } else {
            pool = EmotionLibrary.all
        }

        // If AI search results exist, respect their ordering but restrict to pool
        if let ai = aiSearchResults {
            let poolIds = Set(pool.map { $0.id })
            let aiFiltered = ai.filter { poolIds.contains($0.id) }
            let aiIds = Set(aiFiltered.map { $0.id })
            let remainder = pool.filter { !aiIds.contains($0.id) }.sorted { $0.name < $1.name }
            return aiFiltered + remainder
        }

        if searchText.isEmpty {
            return pool.sorted { $0.name < $1.name }
        }

        // Local fallback filter
        let lower = searchText.lowercased()
        return pool
            .filter { e in
                e.name.lowercased().contains(lower) ||
                e.synonyms.contains { $0.lowercased().contains(lower) }
            }
            .sorted { $0.name < $1.name }
    }

    private var selectedEmotionList: [Emotion] {
        baseList.filter { viewModel.selectedEmotions[$0] != nil }
    }

    private var unselectedEmotionList: [Emotion] {
        baseList.filter { viewModel.selectedEmotions[$0] == nil }
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            AniccaTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                searchBar
                    .padding(.horizontal, AniccaTheme.Spacing.s16)
                    .padding(.top, AniccaTheme.Spacing.s12)
                    .padding(.bottom, AniccaTheme.Spacing.s8)

                filterChips
                    .padding(.bottom, AniccaTheme.Spacing.s4)

                Divider().opacity(0.4)

                emotionList
            }

            if viewModel.totalSelected > 0 {
                bottomBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle(isSheet ? "Add Emotions" : "Browse Emotions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isSheet {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            } else {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation(AniccaTheme.springAnimation) {
                            viewModel.reset() // This also resets entryMode back to .freeText
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
        }
        .animation(AniccaTheme.springAnimation, value: viewModel.totalSelected)
        .sheet(isPresented: $viewModel.showIntensitySheet) {
            IntensitySheetWrapper(viewModel: viewModel)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: AniccaTheme.Spacing.s8) {
            if isSearching {
                ProgressView().scaleEffect(0.8)
            } else {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AniccaTheme.textMuted)
            }
            TextField("Search emotions...", text: $searchText)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .onChange(of: searchText) { _, newValue in
                    scheduleSearch(query: newValue)
                }
            if !searchText.isEmpty {
                Button {
                    withAnimation { searchText = "" }
                    aiSearchResults = nil
                    searchTask?.cancel()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AniccaTheme.textMuted)
                }
            }
        }
        .padding(AniccaTheme.Spacing.s12)
        .background {
            RoundedRectangle(cornerRadius: AniccaTheme.Radius.button, style: .continuous)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.07), radius: 8, y: 3)
        }
        .overlay {
            RoundedRectangle(cornerRadius: AniccaTheme.Radius.button, style: .continuous)
                .stroke(AniccaTheme.textMuted.opacity(0.2), lineWidth: 1)
        }
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AniccaTheme.Spacing.s8) {
                filterChip(label: "All", color: AniccaTheme.brandPrimary, isActive: activeFilter == nil) {
                    withAnimation(AniccaTheme.springAnimation) { activeFilter = nil }
                }
                ForEach(EnergyCenter.allCases) { center in
                    filterChip(label: center.displayName, color: center.color, isActive: activeFilter == center) {
                        withAnimation(AniccaTheme.springAnimation) {
                            activeFilter = (activeFilter == center) ? nil : center
                        }
                    }
                }
            }
            .padding(.horizontal, AniccaTheme.Spacing.s16)
            .padding(.vertical, AniccaTheme.Spacing.s8)
        }
    }

    private func filterChip(label: String, color: Color, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if label != "All" {
                    Circle().fill(color).frame(width: 7, height: 7)
                }
                Text(label)
                    .font(.system(size: 13, weight: isActive ? .semibold : .medium))
            }
            .padding(.horizontal, AniccaTheme.Spacing.s12)
            .padding(.vertical, 7)
            .background {
                Capsule()
                    .fill(isActive ? color.opacity(0.18) : Color.white.opacity(0.75))
                    .overlay {
                        Capsule()
                            .stroke(isActive ? color.opacity(0.4) : AniccaTheme.textMuted.opacity(0.2), lineWidth: 1)
                    }
            }
            .foregroundStyle(isActive ? color : AniccaTheme.textSecondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Emotion List

    private var emotionList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                // "Selected" pinned section
                if !selectedEmotionList.isEmpty {
                    Section {
                        ForEach(selectedEmotionList) { emotion in
                            emotionRow(emotion)
                            if emotion.id != selectedEmotionList.last?.id {
                                Divider().padding(.leading, 48)
                            }
                        }
                    } header: {
                        sectionHeader("Selected (\(selectedEmotionList.count))", color: AniccaTheme.brandPrimary)
                    }
                }

                // Unselected emotions
                if !unselectedEmotionList.isEmpty {
                    Section {
                        ForEach(unselectedEmotionList) { emotion in
                            emotionRow(emotion)
                            if emotion.id != unselectedEmotionList.last?.id {
                                Divider().padding(.leading, 48)
                            }
                        }
                    } header: {
                        if !selectedEmotionList.isEmpty {
                            sectionHeader("All emotions", color: AniccaTheme.textSecondary)
                        }
                    }
                } else if selectedEmotionList.isEmpty && unselectedEmotionList.isEmpty {
                    noResultsView
                }
            }
            .padding(.bottom, viewModel.totalSelected > 0 ? 90 : 16)
        }
    }

    private func sectionHeader(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(color)
            .padding(.horizontal, AniccaTheme.Spacing.s16)
            .padding(.vertical, AniccaTheme.Spacing.s8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AniccaTheme.background.opacity(0.97))
    }

    private func emotionRow(_ emotion: Emotion) -> some View {
        let isSelected = viewModel.selectedEmotions[emotion] != nil
        return Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(AniccaTheme.springAnimation) {
                viewModel.toggle(emotion)
            }
        } label: {
            HStack(spacing: AniccaTheme.Spacing.s12) {
                Circle()
                    .fill(emotion.center.color)
                    .frame(width: 10, height: 10)
                    .padding(.leading, AniccaTheme.Spacing.s8)

                VStack(alignment: .leading, spacing: 3) {
                    Text(emotion.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isSelected ? emotion.center.color : AniccaTheme.textPrimary)
                    Text(emotion.description)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(AniccaTheme.textSecondary)
                        .lineLimit(2)
                }
                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(emotion.center.color)
                        .font(.system(size: 20))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.vertical, AniccaTheme.Spacing.s12)
            .padding(.trailing, AniccaTheme.Spacing.s16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var noResultsView: some View {
        VStack(spacing: AniccaTheme.Spacing.s12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(AniccaTheme.textMuted)
            Text("No emotions match \"\(searchText)\"")
                .anicca(.body)
                .foregroundStyle(AniccaTheme.textMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Bottom Sticky Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                viewModel.presentIntensity()
            } label: {
                HStack(spacing: AniccaTheme.Spacing.s8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Set intensity — \(viewModel.totalSelected) selected")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, AniccaTheme.Spacing.s20)
            .padding(.vertical, AniccaTheme.Spacing.s12)
            .background(.regularMaterial)
        }
    }

    // MARK: - AI Search Debounce

    private func scheduleSearch(query: String) {
        searchTask?.cancel()
        aiSearchResults = nil
        guard query.count >= 2 else { return }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000) // 400ms debounce
            guard !Task.isCancelled else { return }
            await performAISearch(query: query)
        }
    }

    @MainActor
    private func performAISearch(query: String) async {
        guard !query.isEmpty else { return }
        isSearching = true
        defer { isSearching = false }
        do {
            let results = try await EmotionMappingService.shared.searchEmotions(query: query)
            if !results.isEmpty {
                aiSearchResults = results
            }
        } catch {
            // Silently fall back to local string matching (handled in baseList)
            aiSearchResults = nil
        }
    }
}
