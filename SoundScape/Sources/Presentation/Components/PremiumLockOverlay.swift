import SwiftUI

// MARK: - Premium Lock Overlay Modifier

/// A view modifier that overlays a lock icon with blur effect on premium content.
/// When locked content is tapped, it triggers a callback (typically to show paywall).
struct PremiumLockOverlayModifier: ViewModifier {
    let isLocked: Bool
    let onTap: () -> Void

    @State private var isAnimating = false

    func body(content: Content) -> some View {
        if isLocked {
            content
                .blur(radius: 6)
                .overlay {
                    lockOverlay
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onTap()
                }
        } else {
            content
        }
    }

    private var lockOverlay: some View {
        ZStack {
            // Semi-transparent gradient for better lock visibility
            LinearGradient(
                colors: [
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Lock icon with subtle animation
            Image(systemName: "lock.fill")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                .scaleEffect(isAnimating ? 1.0 : 0.8)
                .opacity(isAnimating ? 1.0 : 0.0)
                .onAppear {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        isAnimating = true
                    }
                }
        }
    }
}

// MARK: - View Extension

extension View {
    /// Applies a premium lock overlay when the content is locked.
    /// - Parameters:
    ///   - isLocked: When true, shows blur effect with lock icon
    ///   - onTap: Callback triggered when locked content is tapped
    /// - Returns: A view with optional premium lock overlay
    func premiumLocked(isLocked: Bool, onTap: @escaping () -> Void) -> some View {
        modifier(PremiumLockOverlayModifier(isLocked: isLocked, onTap: onTap))
    }
}

// MARK: - Preview

#Preview("Locked Card") {
    VStack(spacing: 20) {
        // Simulated sound card - locked
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.purple.opacity(0.3))
            .frame(width: 160, height: 180)
            .overlay {
                VStack {
                    Image(systemName: "waveform")
                        .font(.largeTitle)
                    Text("Premium Sound")
                        .font(.headline)
                }
                .foregroundStyle(.white)
            }
            .premiumLocked(isLocked: true) {
                print("Show paywall")
            }

        // Simulated sound card - unlocked
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.green.opacity(0.3))
            .frame(width: 160, height: 180)
            .overlay {
                VStack {
                    Image(systemName: "waveform")
                        .font(.largeTitle)
                    Text("Free Sound")
                        .font(.headline)
                }
                .foregroundStyle(.white)
            }
            .premiumLocked(isLocked: false) {
                print("Show paywall")
            }
    }
    .preferredColorScheme(.dark)
}

#Preview("Locked List Row") {
    List {
        HStack {
            Image(systemName: "cloud.rain.fill")
                .foregroundStyle(.blue)
            Text("Rain Sounds")
            Spacer()
            Image(systemName: "play.fill")
        }
        .padding(.vertical, 8)
        .premiumLocked(isLocked: true) {
            print("Show paywall")
        }

        HStack {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
            Text("Campfire")
            Spacer()
            Image(systemName: "play.fill")
        }
        .padding(.vertical, 8)
        .premiumLocked(isLocked: false) {
            print("Show paywall")
        }
    }
    .preferredColorScheme(.dark)
}
