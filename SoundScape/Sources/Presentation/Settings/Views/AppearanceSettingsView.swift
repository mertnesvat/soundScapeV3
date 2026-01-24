import SwiftUI

struct AppearanceSettingsView: View {
    @Environment(AppearanceService.self) private var appearanceService

    var body: some View {
        @Bindable var service = appearanceService

        List {
            Section {
                Toggle(isOn: Binding(
                    get: { appearanceService.isOLEDModeEnabled },
                    set: { _ in appearanceService.toggleOLEDMode() }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("OLED Mode")
                        Text("Pure black backgrounds for OLED displays")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .tint(.purple)
            } header: {
                Text("Display")
            } footer: {
                Text("OLED Mode uses pure black (#000000) backgrounds to save battery on OLED displays and reduce eye strain at night. Active sounds will glow softly against the dark background.")
            }

            Section {
                OLEDPreviewCard(isOLEDMode: appearanceService.isOLEDModeEnabled)
            } header: {
                Text("Preview")
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

            Text(isOLEDMode ? "OLED Mode: On" : "Standard Mode")
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
