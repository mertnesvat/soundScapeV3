import SwiftUI

struct OnboardingButton: View {
    let title: String
    let action: () -> Void
    var style: OnboardingButtonStyle = .primary

    enum OnboardingButtonStyle {
        case primary
        case secondary
        case text
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(backgroundColor)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(borderColor, lineWidth: style == .secondary ? 1 : 0)
                )
        }
    }

    private var textColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .purple
        case .text: return .gray
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return .purple
        case .secondary, .text: return .clear
        }
    }

    private var borderColor: Color {
        style == .secondary ? .purple : .clear
    }
}

#Preview {
    VStack(spacing: 16) {
        OnboardingButton(title: "Get Started", action: {})
        OnboardingButton(title: "Skip", action: {}, style: .secondary)
        OnboardingButton(title: "Maybe Later", action: {}, style: .text)
    }
    .padding()
    .background(Color.black)
}
