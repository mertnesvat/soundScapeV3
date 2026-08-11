import SwiftUI

/// Centralized design tokens for the Next Sleep app.
/// All colors, opacities, spacing, and corner radii are defined here
/// to ensure visual consistency across screens.
enum AppTheme {

    // MARK: - Accent Colors

    /// Primary accent color used throughout the app
    static let accent: Color = .purple

    /// ASMR category highlight color
    static let asmrPurple = Color(red: 0.8, green: 0.6, blue: 1.0)

    // MARK: - OLED Opacities

    /// Subtle background opacity for cards on OLED displays
    static let oledCardOpacity: Double = 0.1

    /// Standard background opacity for interactive elements on OLED
    static let oledElementOpacity: Double = 0.2

    /// Elevated background opacity for prominent elements on OLED
    static let oledElevatedOpacity: Double = 0.3

    /// Glow/shadow intensity for category-colored glows
    static let glowIntensity: Double = 0.6

    // MARK: - Corner Radii

    /// Standard card corner radius
    static let cardRadius: CGFloat = 16

    /// Button corner radius
    static let buttonRadius: CGFloat = 12

    /// Badge corner radius
    static let badgeRadius: CGFloat = 8

    /// Large featured card corner radius
    static let featuredCardRadius: CGFloat = 20

    // MARK: - Spacing

    /// Edge padding for screen content
    static let edgePadding: CGFloat = 24

    /// Standard content padding
    static let standardPadding: CGFloat = 16

    /// Compact padding for tight spaces
    static let compactPadding: CGFloat = 12

    // MARK: - Animation

    /// Standard spring response for UI transitions
    static let springResponse: Double = 0.3

    /// Standard spring damping
    static let springDamping: Double = 0.7
}
