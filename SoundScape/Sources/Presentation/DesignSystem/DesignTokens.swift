import SwiftUI

/// Single source of truth for Next Sleep visual design tokens.
/// Mirrors the design tokens table documented in CLAUDE.md.
enum DesignTokens {

    // MARK: Colors

    /// Brand accent — purple used across primary interactive elements.
    static let accent = Color(red: 0x7F / 255.0, green: 0x6F / 255.0, blue: 0xD8 / 255.0)

    /// OLED-black surface used as the app's primary canvas.
    static let surface = Color.black

    // MARK: Category colors

    static let categoryNoise = Color(red: 0x7F / 255.0, green: 0x6F / 255.0, blue: 0xD8 / 255.0) // purple
    static let categoryNature = Color(red: 0x4A / 255.0, green: 0xC2 / 255.0, blue: 0x7A / 255.0) // green
    static let categoryWeather = Color(red: 0x5A / 255.0, green: 0x9C / 255.0, blue: 0xE8 / 255.0) // blue
    static let categoryFire = Color(red: 0xE8 / 255.0, green: 0x8A / 255.0, blue: 0x4A / 255.0) // orange
    static let categoryMusic = Color(red: 0xE8 / 255.0, green: 0x6F / 255.0, blue: 0xB8 / 255.0) // pink

    /// Returns the canonical accent color for a sound category.
    static func categoryColor(for category: SoundCategory) -> Color {
        switch category {
        case .noise: return categoryNoise
        case .nature: return categoryNature
        case .weather: return categoryWeather
        case .fire: return categoryFire
        case .music: return categoryMusic
        case .asmr: return accent
        }
    }

    // MARK: Corner radii

    enum radius {
        static let card: CGFloat = 16
        static let button: CGFloat = 12
        static let badge: CGFloat = 8
    }

    // MARK: Padding

    enum padding {
        static let edges: CGFloat = 24
        static let standard: CGFloat = 16
        static let compact: CGFloat = 12
    }

    // MARK: Shadow

    enum shadow {
        static let minRadius: CGFloat = 8
        static let maxRadius: CGFloat = 16
        static let opacity: Double = 0.6
    }

    // MARK: Spring animation

    enum spring {
        static let minResponse: Double = 0.3
        static let maxResponse: Double = 0.6
        static let minDamping: Double = 0.6
        static let maxDamping: Double = 0.7

        static let standard = Animation.spring(response: 0.45, dampingFraction: 0.65)
        static let snappy = Animation.spring(response: minResponse, dampingFraction: minDamping)
        static let gentle = Animation.spring(response: maxResponse, dampingFraction: maxDamping)
    }

    // MARK: Font weights

    enum font {
        static let display: Font.Weight = .thin
        static let body: Font.Weight = .medium
        static let header: Font.Weight = .bold
    }
}
