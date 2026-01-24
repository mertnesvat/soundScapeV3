import SwiftUI

// MARK: - Reflective Sheen View Modifier

/// A view modifier that adds a premium metallic sheen effect that responds to device tilt.
/// The sheen moves horizontally based on device roll and adjusts intensity based on pitch.
struct ReflectiveSheenModifier: ViewModifier {
    @Environment(MotionService.self) private var motionService
    @Environment(AppearanceService.self) private var appearanceService

    /// The category color to tint the sheen
    let categoryColor: Color

    /// Corner radius to match the card's shape
    let cornerRadius: CGFloat

    // MARK: - Computed Properties

    /// Horizontal position of the sheen highlight (0 to 1)
    private var sheenPosition: CGFloat {
        // Convert roll (-1 to 1) to position (0 to 1)
        // Negative roll (tilt left) = highlight on left (0)
        // Positive roll (tilt right) = highlight on right (1)
        CGFloat((motionService.roll + 1.0) / 2.0)
    }

    /// Intensity/opacity of the sheen effect (0.1 to 0.25)
    private var sheenIntensity: CGFloat {
        // Base intensity with pitch adjustment
        // Tilting forward (positive pitch) increases intensity
        // Tilting back (negative pitch) decreases intensity
        let baseIntensity: CGFloat = 0.15
        let pitchAdjustment = CGFloat(motionService.pitch) * 0.1
        return max(0.08, min(0.25, baseIntensity + pitchAdjustment))
    }

    /// Whether to show motion-based sheen (vs static fallback)
    private var useMotionSheen: Bool {
        motionService.isMotionAvailable && motionService.isUpdating
    }

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .overlay(
                sheenOverlay
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .allowsHitTesting(false)
            )
    }

    // MARK: - Sheen Overlay

    @ViewBuilder
    private var sheenOverlay: some View {
        if useMotionSheen {
            motionSheenGradient
                .animation(.linear(duration: 0.1), value: motionService.roll)
                .animation(.linear(duration: 0.1), value: motionService.pitch)
        } else {
            staticSheenGradient
        }
    }

    /// Dynamic sheen that moves with device motion
    private var motionSheenGradient: some View {
        GeometryReader { geometry in
            // Create a moving highlight using a radial gradient
            let highlightX = sheenPosition * geometry.size.width
            let highlightY = geometry.size.height * 0.3

            RadialGradient(
                gradient: Gradient(colors: [
                    categoryColorTint.opacity(sheenIntensity * 0.6),
                    Color.white.opacity(sheenIntensity),
                    Color.white.opacity(sheenIntensity * 0.5),
                    Color.clear
                ]),
                center: UnitPoint(
                    x: highlightX / geometry.size.width,
                    y: highlightY / geometry.size.height
                ),
                startRadius: 0,
                endRadius: max(geometry.size.width, geometry.size.height) * 0.8
            )
            .blendMode(.softLight)
        }
    }

    /// Static subtle sheen for devices without motion sensors
    private var staticSheenGradient: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color.clear, location: 0.0),
                .init(color: categoryColorTint.opacity(0.08), location: 0.3),
                .init(color: Color.white.opacity(0.12), location: 0.5),
                .init(color: categoryColorTint.opacity(0.08), location: 0.7),
                .init(color: Color.clear, location: 1.0)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .blendMode(.softLight)
    }

    /// Category color adjusted for OLED mode
    private var categoryColorTint: Color {
        if appearanceService.isOLEDModeEnabled {
            // Slightly brighter tint for OLED to show against dark background
            return categoryColor.opacity(0.8)
        } else {
            return categoryColor.opacity(0.5)
        }
    }
}

// MARK: - View Extension

extension View {
    /// Applies a reflective metallic sheen effect that responds to device tilt.
    /// - Parameters:
    ///   - categoryColor: The color to tint the sheen (typically the sound category color)
    ///   - cornerRadius: The corner radius to match the card shape (default: 16)
    /// - Returns: A view with the reflective sheen overlay
    func reflectiveSheen(categoryColor: Color, cornerRadius: CGFloat = 16) -> some View {
        modifier(ReflectiveSheenModifier(categoryColor: categoryColor, cornerRadius: cornerRadius))
    }
}

// MARK: - Preview

#Preview("Reflective Sheen - Motion") {
    VStack(spacing: 20) {
        ForEach(["Purple", "Green", "Blue", "Orange", "Pink"], id: \.self) { colorName in
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6).opacity(0.15))
                .frame(width: 150, height: 180)
                .reflectiveSheen(categoryColor: color(for: colorName))
                .overlay(
                    Text(colorName)
                        .foregroundColor(.white)
                )
        }
    }
    .padding()
    .background(Color.black)
    .environment(MotionService())
    .environment(AppearanceService())
}

private func color(for name: String) -> Color {
    switch name {
    case "Purple": return .purple
    case "Green": return .green
    case "Blue": return .blue
    case "Orange": return .orange
    case "Pink": return .pink
    default: return .gray
    }
}
