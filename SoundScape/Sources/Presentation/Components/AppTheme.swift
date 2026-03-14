import SwiftUI

/// Centralized design tokens for consistent theming across the app
enum AppTheme {
    // MARK: - Accent Colors

    /// Primary accent color used throughout the app (#7F6FD8 purple)
    static let accent = Color.purple

    /// ASMR category purple (distinct from the app accent)
    static let asmrPurple = Color(red: 0.8, green: 0.6, blue: 1.0)

    // MARK: - OLED Opacity Values

    /// Card background opacity for OLED mode
    static let oledCardOpacity: Double = 0.2

    /// Subtle background opacity for OLED mode
    static let oledSubtleOpacity: Double = 0.1

    /// Glow/accent opacity for OLED mode
    static let oledGlowOpacity: Double = 0.3

    // MARK: - Corner Radii

    /// Standard card corner radius
    static let cardRadius: CGFloat = 16

    /// Button corner radius
    static let buttonRadius: CGFloat = 12

    /// Badge corner radius
    static let badgeRadius: CGFloat = 8

    // MARK: - Spacing

    /// Edge padding
    static let edgePadding: CGFloat = 24

    /// Standard content padding
    static let standardPadding: CGFloat = 16

    /// Compact padding
    static let compactPadding: CGFloat = 12
}
