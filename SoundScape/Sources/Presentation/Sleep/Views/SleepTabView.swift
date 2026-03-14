import SwiftUI

struct SleepTabView: View {
    @State private var selectedSegment: SleepSegment = .windDown

    enum SleepSegment: String, CaseIterable {
        case windDown
        case sleepRec

        var localizedName: String {
            switch self {
            case .windDown: return String(localized: "Wind Down")
            case .sleepRec: return String(localized: "Sleep Rec")
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker(String(localized: "Sleep"), selection: $selectedSegment) {
                    ForEach(SleepSegment.allCases, id: \.self) { segment in
                        Text(segment.localizedName).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                Group {
                    switch selectedSegment {
                    case .windDown:
                        WindDownContentView()
                    case .sleepRec:
                        SleepRecordingContentView()
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("Sleep"))
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

/// WindDown content extracted without its own NavigationStack
private struct WindDownContentView: View {
    @Environment(StoryProgressService.self) private var progressService
    @Environment(SleepContentPlayerService.self) private var playerService
    @Environment(PremiumManager.self) private var premiumManager
    @Environment(PaywallService.self) private var paywallService
    @Environment(OnboardingService.self) private var onboardingService
    @Environment(SubscriptionService.self) private var subscriptionService
    @Environment(AnalyticsService.self) private var analyticsService

    @State private var selectedContent: SleepContent?

    private var featuredContent: SleepContent {
        SleepContentDataSource.content(withId: "yoga_nidra_10min") ??
        SleepContentDataSource.yogaNidraSessions.first!
    }

    private var incompleteContent: [SleepContent] {
        let allContent = SleepContentDataSource.allContentFlat()
        return allContent.filter { content in
            let progress = progressFraction(for: content)
            return progress > 0 && progress < 0.95
        }
        .sorted { content1, content2 in
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
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                featuredSection

                ContinueListeningSection(
                    incompleteContent: incompleteContent,
                    progressForContent: { progressFraction(for: $0) },
                    onContentTap: { playContent($0) }
                )

                ForEach(WindDownCategory.allCases) { category in
                    WindDownSectionView(
                        category: category,
                        onContentTap: { content in
                            let isLocked = premiumManager.isPremiumRequired(for: .windDownContent(id: content.id))
                            analyticsService.logWindDownContentTapped(
                                contentId: content.id,
                                title: content.title,
                                category: content.contentType.rawValue,
                                isPremium: isLocked,
                                isLocked: isLocked
                            )
                            if isLocked {
                                analyticsService.logWindDownPremiumBlocked(contentId: content.id, category: content.contentType.rawValue)
                                paywallService.triggerPaywall(placement: "premium_winddown") {
                                    playContent(content)
                                }
                            } else {
                                playContent(content)
                            }
                        },
                        progressForContent: { progressFraction(for: $0) },
                        isContentLocked: { premiumManager.isPremiumRequired(for: .windDownContent(id: $0.id)) },
                        onLockedTap: { paywallService.triggerPaywall(placement: "premium_winddown") {} }
                    )
                }

                Spacer()
                    .frame(height: 120)
            }
            .padding(.top, 8)
        }
        .background(Color(.systemBackground))
        .sheet(item: $selectedContent) { content in
            SleepContentPlayerView(
                content: content,
                onDismiss: { selectedContent = nil }
            )
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            let hour = Calendar.current.component(.hour, from: Date())
            let timeOfDay: String
            if hour >= 21 || hour < 5 { timeOfDay = "night" }
            else if hour >= 17 { timeOfDay = "evening" }
            else if hour >= 12 { timeOfDay = "afternoon" }
            else { timeOfDay = "morning" }
            analyticsService.logWindDownTabOpened(timeOfDay: timeOfDay, greeting: greeting)
        }
        .sheet(isPresented: Binding(
            get: { paywallService.showPaywall },
            set: { newValue in
                if !newValue {
                    paywallService.handlePaywallDismissed()
                }
            }
        )) {
            OnboardingPaywallView(
                onComplete: {
                    paywallService.showPaywall = false
                },
                isPresented: true
            )
            .environment(onboardingService)
            .environment(paywallService)
            .environment(subscriptionService)
        }
    }

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
                    analyticsService.logWindDownFeaturedTapped(contentId: featuredContent.id, title: featuredContent.title)
                    let isLocked = premiumManager.isPremiumRequired(for: .windDownContent(id: featuredContent.id))
                    if isLocked {
                        analyticsService.logWindDownPremiumBlocked(contentId: featuredContent.id, category: featuredContent.contentType.rawValue)
                        paywallService.triggerPaywall(placement: "premium_winddown") {
                            playContent(featuredContent)
                        }
                    } else {
                        playContent(featuredContent)
                    }
                },
                onLockedTap: {
                    analyticsService.logWindDownPremiumBlocked(contentId: featuredContent.id, category: featuredContent.contentType.rawValue)
                    paywallService.triggerPaywall(placement: "premium_winddown") {}
                }
            )
        }
    }

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

/// SleepRecording content extracted without its own NavigationStack
private struct SleepRecordingContentView: View {
    @Environment(SleepRecordingService.self) private var sleepRecordingService
    @Environment(AudioEngine.self) private var audioEngine
    @State private var selectedSegment = 0
    @State private var showSoundRecordingOptions = false

    var body: some View {
        Group {
            if sleepRecordingService.isDelayActive {
                RecordingControlsView()
            } else {
                switch sleepRecordingService.status {
                case .idle:
                    if sleepRecordingService.recordings.isEmpty {
                        emptyStateView
                    } else {
                        VStack(spacing: 0) {
                            Picker(String(localized: "View"), selection: $selectedSegment) {
                                Text(String(localized: "Recordings")).tag(0)
                                Text(String(localized: "Trends")).tag(1)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            .padding(.top, 8)

                            if selectedSegment == 0 {
                                RecordingHistoryView()
                            } else {
                                SnoreTrendsView()
                            }
                        }
                    }
                case .recording:
                    RecordingControlsView()
                case .analyzing:
                    analyzingView
                case .complete:
                    if sleepRecordingService.recordings.isEmpty {
                        emptyStateView
                    } else {
                        RecordingHistoryView()
                    }
                }
            }
        }
        .sheet(item: Binding(
            get: { sleepRecordingService.status == .complete ? sleepRecordingService.currentRecording : nil },
            set: { _ in sleepRecordingService.resetStatus() }
        )) { recording in
            NavigationStack {
                SleepReportView(recording: recording)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 32) {
            Spacer()

            ContentUnavailableView(
                String(localized: "No Recordings"),
                systemImage: "mic.fill",
                description: Text(String(localized: "Tap the record button to capture your sleep sounds and discover snoring patterns"))
            )

            recordButton
                .padding(.bottom, 40)

            Spacer()
        }
    }

    private var analyzingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text(String(localized: "Analyzing your sleep..."))
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var recordButton: some View {
        Button {
            if audioEngine.isAnyPlaying {
                showSoundRecordingOptions = true
            } else {
                Task {
                    let granted = await sleepRecordingService.requestMicrophonePermission()
                    if granted {
                        sleepRecordingService.startRecording()
                    }
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(.purple)
                    .frame(width: 80, height: 80)
                    .shadow(color: .purple.opacity(0.4), radius: 12, y: 4)

                Image(systemName: "mic.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
            }
        }
        .sheet(isPresented: $showSoundRecordingOptions) {
            SoundAwareRecordingSheet()
        }
    }
}

#Preview {
    let paywallService = PaywallService()
    SleepTabView()
        .environment(StoryProgressService())
        .environment(SleepContentPlayerService())
        .environment(AppearanceService())
        .environment(paywallService)
        .environment(PremiumManager(paywallService: paywallService))
        .environment(SleepRecordingService())
        .environment(AudioEngine())
        .environment(AnalyticsService())
        .preferredColorScheme(.dark)
}
