import SwiftUI

/// Full-bleed editorial splash surface shown at cold-start.
///
/// Mirrors the left phone of `screenshots/design-refs/ref01-orange-editorial.jpg`:
/// saturated `Tokens.colorOrange` ground, all-caps stacked `NEXT` / `SLEEP` wordmark
/// in `Tokens.colorInk` rendered with `SF Pro Display Black` at a hero size, and a
/// small ink-filled square pinned to the top-trailing corner echoing the reference's
/// status-bar square.
struct SplashWordmarkView: View {

    /// Hero wordmark size — `≥ 96pt` per spec; sized generously so the letterforms
    /// extend toward the leading edge as in the reference.
    private let wordmarkSize: CGFloat = 132

    /// 12pt ink-filled square chip pinned top-trailing.
    private let chipSize: CGFloat = 12

    /// Negative kerning per spec to bring the heavy display letters into contact.
    private let wordmarkKerning: CGFloat = -2

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Tokens.colorOrange
                .ignoresSafeArea(.all, edges: .all)

            VStack(alignment: .leading, spacing: -wordmarkSize * 0.18) {
                Text("NEXT")
                Text("SLEEP")
            }
            .font(.system(size: wordmarkSize, weight: .black, design: .default))
            .kerning(wordmarkKerning)
            .foregroundStyle(Tokens.colorInk)
            .fixedSize()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.leading, 24)

            Rectangle()
                .fill(Tokens.colorInk)
                .frame(width: chipSize, height: chipSize)
                .padding(.trailing, 24)
                .padding(.top, 24)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Next Sleep"))
    }
}

#Preview {
    SplashWordmarkView()
}
