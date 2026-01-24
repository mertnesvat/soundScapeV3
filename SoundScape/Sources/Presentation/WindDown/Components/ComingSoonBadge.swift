import SwiftUI

/// A reusable "Coming Soon" badge overlay for content that is not yet available.
/// Used to indicate upcoming sleep content like stories, meditations, etc.
struct ComingSoonBadge: View {
    /// Style variant for the badge
    enum Style {
        case overlay     // Full card overlay with icon
        case compact     // Small badge for corner positioning
        case banner      // Horizontal banner style
    }

    let style: Style

    init(style: Style = .overlay) {
        self.style = style
    }

    var body: some View {
        switch style {
        case .overlay:
            overlayStyle
        case .compact:
            compactStyle
        case .banner:
            bannerStyle
        }
    }

    // MARK: - Overlay Style (Full card overlay)

    private var overlayStyle: some View {
        ZStack {
            // Semi-transparent dark background
            Color.black.opacity(0.6)

            VStack(spacing: 8) {
                Image(systemName: "clock.badge.checkmark")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.9))

                Text("Coming Soon")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }

    // MARK: - Compact Style (Small corner badge)

    private var compactStyle: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.caption2)
            Text("Soon")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.7))
        .clipShape(Capsule())
    }

    // MARK: - Banner Style (Bottom banner)

    private var bannerStyle: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "clock.badge.checkmark")
                    .font(.caption)
                Text("Coming Soon")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.75))
        }
    }
}

// MARK: - View Extension for Easy Application

extension View {
    /// Applies a "Coming Soon" badge overlay if the content is unavailable.
    /// - Parameters:
    ///   - isUnavailable: Whether the content is unavailable (coming soon)
    ///   - style: The badge style to use
    ///   - cornerRadius: Corner radius for the overlay (matches card shape)
    /// - Returns: The view with an optional coming soon overlay
    @ViewBuilder
    func comingSoonBadge(
        if isUnavailable: Bool,
        style: ComingSoonBadge.Style = .overlay,
        cornerRadius: CGFloat = 16
    ) -> some View {
        if isUnavailable {
            self.overlay(
                ComingSoonBadge(style: style)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            )
        } else {
            self
        }
    }
}

// MARK: - Preview

#Preview("Overlay Style") {
    ZStack {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.indigo.opacity(0.6))
            .frame(width: 140, height: 180)

        ComingSoonBadge(style: .overlay)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    .frame(width: 140, height: 180)
    .preferredColorScheme(.dark)
}

#Preview("Compact Style") {
    ZStack {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.purple.opacity(0.6))
            .frame(width: 140, height: 180)

        VStack {
            HStack {
                Spacer()
                ComingSoonBadge(style: .compact)
            }
            .padding(8)
            Spacer()
        }
    }
    .frame(width: 140, height: 180)
    .preferredColorScheme(.dark)
}

#Preview("Banner Style") {
    ZStack {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.teal.opacity(0.6))
            .frame(width: 200, height: 120)

        ComingSoonBadge(style: .banner)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    .frame(width: 200, height: 120)
    .preferredColorScheme(.dark)
}

#Preview("View Extension") {
    HStack(spacing: 16) {
        // Available content (no badge)
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.green.opacity(0.6))
            .frame(width: 120, height: 160)
            .comingSoonBadge(if: false)

        // Unavailable content (with badge)
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.indigo.opacity(0.6))
            .frame(width: 120, height: 160)
            .comingSoonBadge(if: true)
    }
    .padding()
    .preferredColorScheme(.dark)
}
