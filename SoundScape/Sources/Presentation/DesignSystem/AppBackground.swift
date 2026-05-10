import SwiftUI

/// Paints `DesignTokens.surface` (OLED black) edge-to-edge behind any view and
/// ignores safe areas so the canvas extends under status bar, home indicator,
/// and notches. Apply once at the root in `SoundScapeApp` so every screen
/// inherits the same OLED-black canvas instead of system grouped backgrounds.
struct AppBackground: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            DesignTokens.surface
                .ignoresSafeArea()
            content
        }
    }
}

extension View {
    /// Applies the OLED-black app canvas behind the view.
    func appBackground() -> some View {
        modifier(AppBackground())
    }
}
