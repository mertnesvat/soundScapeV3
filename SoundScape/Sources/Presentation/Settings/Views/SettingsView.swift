import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppearanceService.self) private var appearanceService
    @Environment(SleepBuddyService.self) private var sleepBuddyService
    @Environment(AnalyticsService.self) private var analyticsService

    @State private var sleepBuddyTapped = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        AppearanceSettingsView()
                    } label: {
                        Label("Appearance", systemImage: "paintbrush")
                    }
                }

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

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
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
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppearanceService())
        .environment(SleepBuddyService())
        .environment(AnalyticsService())
        .preferredColorScheme(.dark)
}
