import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppearanceService.self) private var appearanceService
    @Environment(SleepBuddyService.self) private var sleepBuddyService

    @State private var showingSleepBuddy = false

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
                        showingSleepBuddy = true
                    } label: {
                        HStack {
                            Label {
                                Text("Sleep Buddy")
                            } icon: {
                                Image(systemName: "person.2.fill")
                                    .foregroundStyle(.purple)
                            }

                            Spacer()

                            if sleepBuddyService.isPaired, let buddy = sleepBuddyService.buddy {
                                Text(buddy.name)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Not paired")
                                    .foregroundStyle(.secondary)
                            }

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(.primary)
                } header: {
                    Text("Social")
                } footer: {
                    Text("Pair with a friend to motivate each other with sleep streaks")
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
            .sheet(isPresented: $showingSleepBuddy) {
                SleepBuddyView()
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppearanceService())
        .environment(SleepBuddyService())
        .preferredColorScheme(.dark)
}
