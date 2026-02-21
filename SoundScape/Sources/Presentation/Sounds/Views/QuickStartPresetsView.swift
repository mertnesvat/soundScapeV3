import SwiftUI

struct QuickStartPresetsView: View {
    @Environment(QuickStartPresetsService.self) private var presetsService
    @Environment(AudioEngine.self) private var audioEngine
    @Environment(AppearanceService.self) private var appearanceService

    let allSounds: [Sound]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with collapse toggle
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    presetsService.toggleCollapsed()
                }
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                    Text(String(localized: "Quick Start"))
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: presetsService.isCollapsed ? "chevron.down" : "chevron.up")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if !presetsService.isCollapsed {
                // Horizontal scrolling preset cards
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(presetsService.presets) { preset in
                            PresetCardView(
                                preset: preset,
                                isActive: presetsService.activePresetId == preset.id
                            ) {
                                presetsService.loadPreset(preset, audioEngine: audioEngine, allSounds: allSounds)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }

            Divider()
                .padding(.horizontal, 16)
        }
    }
}

struct PresetCardView: View {
    let preset: SoundPreset
    let isActive: Bool
    let onTap: () -> Void

    @Environment(AppearanceService.self) private var appearanceService

    private var gradientStart: Color {
        colorFromString(preset.gradientColors[0])
    }

    private var gradientEnd: Color {
        colorFromString(preset.gradientColors[1])
    }

    private var cardBackgroundColor: Color {
        if appearanceService.isOLEDModeEnabled {
            return Color(.systemGray6).opacity(0.12)
        } else {
            return Color(.systemGray6)
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [gradientStart.opacity(0.3), gradientEnd.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    if isActive {
                        Circle()
                            .fill(gradientStart.opacity(0.2))
                            .frame(width: 54, height: 54)
                            .blur(radius: 8)
                    }

                    Image(systemName: preset.icon)
                        .font(.system(size: 20))
                        .foregroundColor(gradientStart)
                }

                Text(preset.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(preset.subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                // Sound count indicator
                HStack(spacing: 4) {
                    Image(systemName: "waveform")
                        .font(.caption2)
                    Text("\(preset.soundConfigs.count) \(String(localized: "sounds"))")
                        .font(.caption2)
                }
                .foregroundColor(gradientStart.opacity(0.8))
            }
            .frame(width: 130)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(cardBackgroundColor)
                    .shadow(
                        color: isActive ? gradientStart.opacity(0.4) : .clear,
                        radius: isActive ? 12 : 0
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isActive
                            ? LinearGradient(
                                colors: [gradientStart.opacity(0.7), gradientEnd.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.clear, Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.3), value: isActive)
    }

    private func colorFromString(_ name: String) -> Color {
        switch name {
        case "indigo": return .indigo
        case "purple": return .purple
        case "orange": return .orange
        case "pink": return .pink
        case "blue": return .blue
        case "cyan": return .cyan
        case "teal": return .teal
        case "green": return .green
        case "mint": return .mint
        default: return .blue
        }
    }
}

#Preview {
    QuickStartPresetsView(
        allSounds: LocalSoundDataSource.shared.getAllSounds()
    )
    .environment(QuickStartPresetsService())
    .environment(AudioEngine())
    .environment(AppearanceService())
    .preferredColorScheme(.dark)
    .background(Color(.systemBackground))
}
