import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(AppearanceService.self) private var appearanceService
    @Environment(\.openURL) private var openURL

    var body: some View {
        @Bindable var service = appearanceService

        List {
            Section {
                Toggle(isOn: Binding(
                    get: { appearanceService.isOLEDModeEnabled },
                    set: { _ in appearanceService.toggleOLEDMode() }
                )) {
                    HStack(spacing: 12) {
                        // Gradient icon
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
                            // Gradient title
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
                Text("SUPER BLACK uses pure black (#000000) backgrounds to save battery on OLED displays and reduce eye strain at night. Active sounds glow softly against the dark.")
            }

            Section {
                OLEDPreviewCard(isOLEDMode: appearanceService.isOLEDModeEnabled)
            } header: {
                Text("Preview")
            }

            // About Section
            Section {
                Button(action: {
                    openURL(URL(string: "https://studionext.co.uk/")!)
                }) {
                    HStack {
                        Label("Website", systemImage: "globe")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.primary)

                Button(action: {
                    openURL(URL(string: "https://studionext.co.uk/soundscape-privacy.html")!)
                }) {
                    HStack {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.primary)

                Button(action: {
                    openURL(URL(string: "https://studionext.co.uk/soundscape-terms.html")!)
                }) {
                    HStack {
                        Label("Terms of Use", systemImage: "doc.text.fill")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .foregroundColor(.primary)
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
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .oledBackground()
    }
}

// MARK: - Preview Card

private struct OLEDPreviewCard: View {
    let isOLEDMode: Bool

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                // Sample sound card preview
                PreviewSoundCard(
                    name: "Rain",
                    color: .blue,
                    isPlaying: true,
                    isOLEDMode: isOLEDMode
                )

                PreviewSoundCard(
                    name: "Fire",
                    color: .orange,
                    isPlaying: false,
                    isOLEDMode: isOLEDMode
                )
            }

            Text(isOLEDMode ? "SUPER BLACK: On" : "Standard Mode")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(isOLEDMode ? Color.black : Color(.systemGray6))
        .cornerRadius(12)
    }
}

private struct PreviewSoundCard: View {
    let name: String
    let color: Color
    let isPlaying: Bool
    let isOLEDMode: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)

                if isPlaying && isOLEDMode {
                    Circle()
                        .fill(color.opacity(0.4))
                        .frame(width: 50, height: 50)
                        .blur(radius: 8)
                }

                Image(systemName: "waveform")
                    .foregroundColor(color)
            }

            Text(name)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isOLEDMode ? Color(.systemGray6).opacity(0.3) : Color(.systemGray5))
                .shadow(
                    color: isPlaying && isOLEDMode ? color.opacity(0.5) : .clear,
                    radius: isPlaying ? 10 : 0
                )
        )
    }
}

#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
    .environment(AppearanceService())
    .preferredColorScheme(.dark)
}
