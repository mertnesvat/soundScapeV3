import SwiftUI

// MARK: - Wind Down Content Category

enum WindDownCategory: String, CaseIterable, Identifiable {
    case yogaNidra = "Yoga Nidra"
    case sleepStories = "Sleep Stories"
    case meditations = "Meditations"
    case breathing = "Breathing"
    case hypnosis = "Hypnosis"
    case affirmations = "Affirmations"

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .yogaNidra: return String(localized: "Yoga Nidra")
        case .sleepStories: return String(localized: "Sleep Stories")
        case .meditations: return String(localized: "Meditations")
        case .breathing: return String(localized: "Breathing")
        case .hypnosis: return String(localized: "Hypnosis")
        case .affirmations: return String(localized: "Affirmations")
        }
    }

    var icon: String {
        switch self {
        case .yogaNidra: return "figure.mind.and.body"
        case .sleepStories: return "book.fill"
        case .meditations: return "brain.head.profile"
        case .breathing: return "wind"
        case .hypnosis: return "sparkles"
        case .affirmations: return "heart.text.square.fill"
        }
    }

    var color: Color {
        switch self {
        case .yogaNidra: return .indigo
        case .sleepStories: return .purple
        case .meditations: return .teal
        case .breathing: return .cyan
        case .hypnosis: return .pink
        case .affirmations: return .orange
        }
    }

    var description: String {
        switch self {
        case .yogaNidra: return "Deep relaxation practice"
        case .sleepStories: return "Soothing bedtime tales"
        case .meditations: return "Guided sleep meditation"
        case .breathing: return "Calming breath exercises"
        case .hypnosis: return "Gentle sleep hypnosis"
        case .affirmations: return "Positive sleep affirmations"
        }
    }

    var localizedDescription: String {
        switch self {
        case .yogaNidra: return String(localized: "Deep relaxation practice")
        case .sleepStories: return String(localized: "Soothing bedtime tales")
        case .meditations: return String(localized: "Guided sleep meditation")
        case .breathing: return String(localized: "Calming breath exercises")
        case .hypnosis: return String(localized: "Gentle sleep hypnosis")
        case .affirmations: return String(localized: "Positive sleep affirmations")
        }
    }

    var contentType: SleepContentType {
        switch self {
        case .yogaNidra: return .yogaNidra
        case .sleepStories: return .sleepStory
        case .meditations: return .guidedMeditation
        case .breathing: return .breathingExercise
        case .hypnosis: return .sleepHypnosis
        case .affirmations: return .affirmations
        }
    }
}

// MARK: - Wind Down View

struct WindDownView: View {
    @Environment(StoryProgressService.self) private var progressService
    @Environment(SleepContentPlayerService.self) private var playerService
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(PaywallService.self) private var paywallService
    @Environment(OnboardingService.self) private var onboardingService
    @Environment(SubscriptionService.self) private var subscriptionService

    @State private var selectedContent: SleepContent?

    // Featured content - default to yoga_nidra_10min
    private var featuredContent: SleepContent {
        SleepContentDataSource.content(withId: "yoga_nidra_10min") ??
        SleepContentDataSource.yogaNidraSessions.first!
    }

    // Continue listening - incomplete sessions (progress > 0 and < 95%)
    private var incompleteContent: [SleepContent] {
        let allContent = SleepContentDataSource.allContentFlat()
        return allContent.filter { content in
            let progress = progressFraction(for: content)
            return progress > 0 && progress < 0.95
        }
        .sorted { content1, content2 in
            // Sort by most recently played (highest progress first as proxy)
            progressFraction(for: content1) > progressFraction(for: content2)
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 21 || hour < 5 {
            return String(localized: "Ready for Sleep?")
        } else if hour >= 17 {
            return String(localized: "Good Evening")
        } else if hour >= 12 {
            return String(localized: "Good Afternoon")
        } else {
            return String(localized: "Good Morning")
        }
    }

    private var greetingSubtitle: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 21 || hour < 5 {
            return String(localized: "Let's help you drift off peacefully")
        } else if hour >= 17 {
            return String(localized: "Prepare for restful sleep")
        } else if hour >= 12 {
            return String(localized: "Take a moment to relax")
        } else {
            return String(localized: "Start your day with intention")
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Personalized Header
                    headerSection

                    // Featured Tonight Section
                    featuredSection

                    // Continue Listening Section (only if has incomplete content)
                    ContinueListeningSection(
                        incompleteContent: incompleteContent,
                        progressForContent: { progressFraction(for: $0) },
                        onContentTap: { playContent($0) }
                    )

                    // Content Sections by Category
                    ForEach(WindDownCategory.allCases) { category in
                        WindDownSectionView(
                            category: category,
                            onContentTap: { content in
                                let isLocked = premiumManager.isPremiumRequired(for: .windDownContent(id: content.id))
                                if isLocked {
                                    paywallService.triggerSmartPaywall(source: "sleep_stories") {
                                        playContent(content)
                                    }
                                } else {
                                    playContent(content)
                                }
                            },
                            progressForContent: { progressFraction(for: $0) },
                            isContentLocked: { premiumManager.isPremiumRequired(for: .windDownContent(id: $0.id)) },
                            onLockedTap: { paywallService.triggerSmartPaywall(source: "sleep_stories") {} }
                        )
                    }

                    // Bottom padding for tab bar and now playing bar
                    Spacer()
                        .frame(height: 120)
                }
                .padding(.top, 8)
            }
            .background(Color(.systemBackground))
            .navigationTitle(LocalizedStringKey("Wind Down"))
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedContent) { content in
                SleepContentPlayerView(
                    content: content,
                    onDismiss: { selectedContent = nil }
                )
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: Binding(
                get: { paywallService.showPaywall },
                set: { newValue in
                    if !newValue {
                        paywallService.handlePaywallDismissed()
                    }
                }
            )) {
                SmartPaywallView()
                    .environment(paywallService)
                    .environment(subscriptionService)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text(greetingSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Moon icon
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.indigo, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Featured Section

    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.title3)
                    .foregroundColor(.yellow)

                Text(LocalizedStringKey("Featured Tonight"))
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()
            }
            .padding(.horizontal, 16)

            LargeFeaturedCard(
                content: featuredContent,
                progress: progressFraction(for: featuredContent),
                isLocked: premiumManager.isPremiumRequired(for: .windDownContent(id: featuredContent.id)),
                onTap: {
                    let isLocked = premiumManager.isPremiumRequired(for: .windDownContent(id: featuredContent.id))
                    if isLocked {
                        paywallService.triggerSmartPaywall(source: "sleep_stories") {
                            playContent(featuredContent)
                        }
                    } else {
                        playContent(featuredContent)
                    }
                },
                onLockedTap: { paywallService.triggerSmartPaywall(source: "sleep_stories") {} }
            )
        }
    }

    // MARK: - Helper Methods

    private func progressFraction(for content: SleepContent) -> Double {
        let played = progressService.getProgress(for: content.id)
        guard content.duration > 0 else { return 0 }
        return min(played / content.duration, 1.0)
    }

    private func progressFraction(for contentId: String) -> Double {
        guard let content = SleepContentDataSource.content(withId: contentId) else {
            return 0
        }
        return progressFraction(for: content)
    }

    private func playContent(_ content: SleepContent) {
        selectedContent = content
    }
}

// MARK: - Section View

struct WindDownSectionView: View {
    let category: WindDownCategory
    let onContentTap: (SleepContent) -> Void
    let progressForContent: (SleepContent) -> Double
    let isContentLocked: (SleepContent) -> Bool
    let onLockedTap: () -> Void

    private var contentForCategory: [SleepContent] {
        SleepContentDataSource.content(for: category.contentType)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundColor(category.color)

                Text(category.localizedName)
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()

                if contentForCategory.count > 4 {
                    Button(action: {}) {
                        Text(LocalizedStringKey("See All"))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)

            // Horizontal Scroll of Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(contentForCategory) { content in
                        SleepContentCardView(
                            content: content,
                            progress: progressForContent(content),
                            isLocked: isContentLocked(content),
                            onTap: { onContentTap(content) },
                            onLockedTap: onLockedTap
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let paywallService = PaywallService()
    WindDownView()
        .environment(StoryProgressService())
        .environment(SleepContentPlayerService())
        .environment(AppearanceService())
        .environment(paywallService)
        .environment(PremiumManager(paywallService: paywallService))
        .preferredColorScheme(.dark)
}
