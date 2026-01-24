import SwiftUI

// MARK: - OLED Background Modifier

struct OLEDBackgroundModifier: ViewModifier {
    @Environment(AppearanceService.self) private var appearanceService

    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(
                appearanceService.isOLEDModeEnabled
                    ? Color.black
                    : Color(.systemBackground)
            )
    }
}

// MARK: - View Extension

extension View {
    func oledBackground() -> some View {
        modifier(OLEDBackgroundModifier())
    }
}

// MARK: - OLED Card Background

struct OLEDCardBackgroundModifier: ViewModifier {
    @Environment(AppearanceService.self) private var appearanceService
    let isPlaying: Bool
    let categoryColor: Color

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardBackgroundColor)
                    .shadow(
                        color: glowColor,
                        radius: isPlaying ? 12 : 0
                    )
            )
    }

    private var cardBackgroundColor: Color {
        if appearanceService.isOLEDModeEnabled {
            return isPlaying
                ? Color(.systemGray6).opacity(0.2)
                : Color(.systemGray6).opacity(0.1)
        } else {
            return Color(.systemGray6)
        }
    }

    private var glowColor: Color {
        if isPlaying {
            return appearanceService.isOLEDModeEnabled
                ? categoryColor.opacity(0.6)
                : categoryColor.opacity(0.4)
        }
        return .clear
    }
}

extension View {
    func oledCardBackground(isPlaying: Bool, categoryColor: Color) -> some View {
        modifier(OLEDCardBackgroundModifier(isPlaying: isPlaying, categoryColor: categoryColor))
    }
}

// MARK: - OLED Now Playing Bar Background

struct OLEDNowPlayingBarModifier: ViewModifier {
    @Environment(AppearanceService.self) private var appearanceService

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundFill)
                    .shadow(
                        color: shadowColor,
                        radius: 10,
                        y: -5
                    )
            )
    }

    private var backgroundFill: Color {
        appearanceService.isOLEDModeEnabled
            ? Color(.systemGray6).opacity(0.3)
            : Color(.systemGray6)
    }

    private var shadowColor: Color {
        appearanceService.isOLEDModeEnabled
            ? Color.purple.opacity(0.3)
            : Color.black.opacity(0.3)
    }
}

extension View {
    func oledNowPlayingBarBackground() -> some View {
        modifier(OLEDNowPlayingBarModifier())
    }
}

// MARK: - OLED Glow Effect for Playing Sounds

struct OLEDGlowModifier: ViewModifier {
    @Environment(AppearanceService.self) private var appearanceService
    let isActive: Bool
    let color: Color

    func body(content: Content) -> some View {
        if appearanceService.isOLEDModeEnabled && isActive {
            content
                .shadow(color: color.opacity(0.6), radius: 8)
                .shadow(color: color.opacity(0.4), radius: 16)
        } else {
            content
        }
    }
}

extension View {
    func oledGlow(isActive: Bool, color: Color) -> some View {
        modifier(OLEDGlowModifier(isActive: isActive, color: color))
    }
}
