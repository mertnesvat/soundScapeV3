import SwiftUI

/// Centralized design tokens for the Next Sleep app
enum AppTheme {
    // MARK: - Accent Colors

    /// Primary accent color used throughout the app
    static let accent: Color = .purple

    /// ASMR category purple - distinct from the main accent
    static let asmrPurple = Color(red: 0.8, green: 0.6, blue: 1.0)

    // MARK: - OLED Opacity Values

    /// Card background opacity when playing (OLED mode)
    static let cardPlayingOpacity: Double = 0.2

    /// Card background opacity when idle (OLED mode)
    static let cardIdleOpacity: Double = 0.1

    /// Now playing bar background opacity (OLED mode)
    static let nowPlayingBarOpacity: Double = 0.3

    /// Glow color opacity when playing (OLED mode)
    static let glowPlayingOpacity: Double = 0.6

    /// Glow color opacity when idle (OLED mode)
    static let glowIdleOpacity: Double = 0.4

    // MARK: - Layout

    /// Standard card corner radius
    static let cardRadius: CGFloat = 16

    /// Button corner radius
    static let buttonRadius: CGFloat = 12

    /// Badge corner radius
    static let badgeRadius: CGFloat = 8

    /// Standard edge padding
    static let edgePadding: CGFloat = 24

    /// Standard content padding
    static let standardPadding: CGFloat = 16

    /// Compact padding
    static let compactPadding: CGFloat = 12
}
