import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(AppearanceService.self) private var appearanceService
    @Environment(SleepBuddyService.self) private var sleepBuddyService
    @Environment(AnalyticsService.self) private var analyticsService
    @Environment(OnboardingService.self) private var onboardingService
    @Environment(PaywallService.self) private var paywallService
    @Environment(SubscriptionService.self) private var subscriptionService

    @State private var sleepBuddyTapped = false
    @State private var isRestoring = false
    @State private var showResetOnboardingAlert = false
    @State private var showPaywallSheet = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Display (Super Black at top)
                Section {
                    Toggle(isOn: Binding(
                        get: { appearanceService.isOLEDModeEnabled },
                        set: { _ in appearanceService.toggleOLEDMode() }
                    )) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.purple, .indigo, .black],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 32, height: 32)

                                Image(systemName: "moon.stars.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("SUPER BLACK")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.purple, .indigo],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )

                                Text("True black for OLED displays")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .tint(.purple)
                } header: {
                    Text("Display")
                } footer: {
                    Text("Pure black backgrounds save battery on OLED displays and reduce eye strain at night.")
                }

                // MARK: - Premium
                Section {
                    if paywallService.isPremium {
                        HStack {
                            Label {
                                Text("Premium Active")
                            } icon: {
                                Image(systemName: "crown.fill")
                                    .foregroundStyle(.yellow)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    } else {
                        Button {
                            showPaywallSheet = true
                        } label: {
                            HStack {
                                Label {
                                    Text("Upgrade to Premium")
                                } icon: {
                                    Image(systemName: "crown.fill")
                                        .foregroundStyle(.yellow)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .foregroundStyle(.primary)
                    }

                    Button {
                        isRestoring = true
                        Task {
                            await paywallService.restorePurchases()
                            isRestoring = false
                        }
                    } label: {
                        HStack {
                            Label(LocalizedStringKey("Restore Purchases"), systemImage: "arrow.triangle.2.circlepath")
                            Spacer()
                            if isRestoring {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(isRestoring)
                    .foregroundStyle(.primary)
                } header: {
                    Text("Premium")
                }

                // MARK: - Social
                Section {
                    Button {
                        if !sleepBuddyTapped {
                            sleepBuddyTapped = true
                            analyticsService.logSleepBuddyInterestShown()
                        }
                    } label: {
                        HStack {
                            Label {
                                Text("Sleep Buddy")
                            } icon: {
                                Image(systemName: "person.2.fill")
                                    .foregroundStyle(sleepBuddyTapped ? .gray : .purple)
                            }

                            Spacer()

                            if sleepBuddyTapped {
                                Text("Coming Soon")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Tap to learn more")
                                    .foregroundStyle(.secondary)
                            }

                            Image(systemName: sleepBuddyTapped ? "clock.fill" : "chevron.right")
                                .font(.caption)
                                .foregroundStyle(sleepBuddyTapped ? Color.orange : Color.gray.opacity(0.5))
                        }
                    }
                    .foregroundStyle(sleepBuddyTapped ? .secondary : .primary)
                    .disabled(sleepBuddyTapped)
                } header: {
                    Text("Social")
                } footer: {
                    if sleepBuddyTapped {
                        Text("Sleep Buddy is coming soon! Pair with a friend to motivate each other with sleep streaks. Stay tuned for updates.")
                    } else {
                        Text("Pair with a friend to motivate each other with sleep streaks")
                    }
                }

                #if DEBUG
                // MARK: - Developer
                Section {
                    Button(role: .destructive) {
                        showResetOnboardingAlert = true
                    } label: {
                        Label(LocalizedStringKey("Reset Onboarding"), systemImage: "arrow.counterclockwise")
                    }
                } header: {
                    Text("Developer")
                } footer: {
                    Text("Reset onboarding to test the onboarding flow again")
                }
                #endif

                // MARK: - About (at bottom)
                Section {
                    Button {
                        openURL(URL(string: "https://studionext.co.uk/")!)
                    } label: {
                        HStack {
                            Label(LocalizedStringKey("Website"), systemImage: "globe")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)

                    Button {
                        openURL(URL(string: "https://studionext.co.uk/soundscape-privacy.html")!)
                    } label: {
                        HStack {
                            Label(LocalizedStringKey("Privacy Policy"), systemImage: "hand.raised.fill")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)

                    Button {
                        openURL(URL(string: "https://studionext.co.uk/soundscape-terms.html")!)
                    } label: {
                        HStack {
                            Label(LocalizedStringKey("Terms of Use"), systemImage: "doc.text.fill")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)

                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                } footer: {
                    VStack(spacing: 4) {
                        Text("SoundScape")
                            .fontWeight(.medium)
                        Text("Made with ♥ by Studio Next")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                }
            }
            .navigationTitle(LocalizedStringKey("Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .oledBackground()
            .onAppear {
                analyticsService.logSettingsOpened()
            }
            .alert(LocalizedStringKey("Reset Onboarding?"), isPresented: $showResetOnboardingAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    onboardingService.resetOnboarding()
                    dismiss()
                }
            } message: {
                Text("This will reset your onboarding progress and show the onboarding flow again on next app launch.")
            }
            .sheet(isPresented: $showPaywallSheet) {
                OnboardingPaywallView(
                    onComplete: {
                        showPaywallSheet = false
                    },
                    isPresented: true
                )
                .environment(onboardingService)
                .environment(paywallService)
                .environment(subscriptionService)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppearanceService())
        .environment(SleepBuddyService())
        .environment(AnalyticsService())
        .environment(OnboardingService())
        .environment(PaywallService())
        .environment(SubscriptionService())
        .preferredColorScheme(.dark)
}
