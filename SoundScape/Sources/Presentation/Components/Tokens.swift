import SwiftUI

/// Editorial Light System tokens.
///
/// Encodes the warm, editorial, color-blocked palette and geometry derived from
/// `screenshots/design-refs/ref01-orange-editorial.jpg` and
/// `screenshots/design-refs/ref02-warm-dashboard.jpg`. These tokens supersede the
/// legacy dark/OLED/purple language for the in-scope surfaces — see DESIGN.md
/// "Editorial Light System" section for the per-screen specs.
///
/// All views in the in-scope screens MUST reference values from this file rather
/// than hard-coding hex values, radii, font sizes, or spring parameters.
public enum Tokens {

    // MARK: - Editorial Light Palette

    /// Primary editorial accent — a saturated, warm vermilion used for large
    /// color-blocked sections, primary actions, and chevron motif. Hex `#E84B1A`.
    public static let colorOrange = Color(red: 0xE8 / 255.0,
                                          green: 0x4B / 255.0,
                                          blue: 0x1A / 255.0)

    /// Editorial yellow used for highlight tiles, stat callouts, and accent
    /// numerals. Hex `#F5C518`.
    public static let colorYellow = Color(red: 0xF5 / 255.0,
                                          green: 0xC5 / 255.0,
                                          blue: 0x18 / 255.0)

    /// Soft peach used for secondary blocks, mid-tone cards, and warm fills.
    /// Hex `#F7D5BD`.
    public static let colorPeach = Color(red: 0xF7 / 255.0,
                                         green: 0xD5 / 255.0,
                                         blue: 0xBD / 255.0)

    /// Warm cream — the canvas background for the editorial light surfaces.
    /// Replaces OLED black as the default screen background. Hex `#F4F0E8`.
    public static let colorCream = Color(red: 0xF4 / 255.0,
                                         green: 0xF0 / 255.0,
                                         blue: 0xE8 / 255.0)

    /// Near-black ink used for body and display type on cream backgrounds.
    /// Slightly warmed off pure black for editorial softness. Hex `#111111`.
    public static let colorInk = Color(red: 0x11 / 255.0,
                                       green: 0x11 / 255.0,
                                       blue: 0x11 / 255.0)

    // MARK: - Geometry

    /// Corner radius for the large color-blocked card sections.
    public static let radiusBlock: CGFloat = 20

    /// Corner radius for stat / metric tiles and secondary cards.
    public static let radiusTile: CGFloat = 16

    /// Display-numeral type size (e.g. oversized stat numbers in the top-left
    /// of metric tiles, splash wordmark digits).
    public static let displayNumeralSize: CGFloat = 72

    /// Headline type size for editorial section headers and screen titles.
    public static let headlineSize: CGFloat = 28

    /// Standard height for numbered editorial rows ("01 / 02 / 03 …").
    public static let editorialRowHeight: CGFloat = 64

    // MARK: - Motion

    /// Tactile press animation used for buttons, tiles, and editorial rows.
    /// Pairs with a scale of `0.97` on press, returning to `1.0` on release.
    /// No glow — the press is registered through scale only.
    public static let tactilePress: Animation = .spring(response: 0.35, dampingFraction: 0.8)

    // MARK: - Legacy aliases (SUPERSEDED — do not use in new editorial surfaces)

    /// Legacy purple accent from the dark/OLED system. Retained as a
    /// `@available(*, deprecated)` alias so non-in-scope screens (Binaural,
    /// Wind Down, Sleep Rec, Discover, Adaptive, Insights, Onboarding) keep
    /// compiling. All in-scope surfaces must migrate to the editorial orange.
    @available(*, deprecated, message: "Use the editorial orange token. Purple accent is part of the SUPERSEDED dark system.")
    public static let accentBrandLegacy = Color(red: 0x7F / 255.0,
                                                green: 0x6F / 255.0,
                                                blue: 0xD8 / 255.0)
}
