import SwiftUI

struct SleepRecordingView: View {
    @Environment(SleepRecordingService.self) private var sleepRecordingService
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(PaywallService.self) private var paywallService
    @Environment(SubscriptionService.self) private var subscriptionService
    @State private var selectedSegment = 0
    @State private var showSoundRecordingOptions = false

    var body: some View {
        NavigationStack {
            Group {
                if sleepRecordingService.isDelayActive {
                    // Show countdown during wind-down timer
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
            .navigationTitle(LocalizedStringKey("Sleep Recording"))
            .sheet(item: Binding(
                get: { sleepRecordingService.status == .complete ? sleepRecordingService.currentRecording : nil },
                set: { _ in sleepRecordingService.resetStatus() }
            )) { recording in
                NavigationStack {
                    SleepReportView(recording: recording)
                }
            }
        }
    }

    // MARK: - Empty State

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

    // MARK: - Analyzing State

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

    // MARK: - Record Button

    private var recordButton: some View {
        Button {
            paywallService.triggerSmartPaywall(source: "sleep_recording") {
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

#Preview {
    SleepRecordingView()
        .environment(SleepRecordingService())
        .environment(AudioEngine())
        .environment(PaywallService())
        .environment(SubscriptionService())
        .preferredColorScheme(.dark)
}
