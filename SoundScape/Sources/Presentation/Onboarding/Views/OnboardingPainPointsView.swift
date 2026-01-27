import SwiftUI

struct OnboardingPainPointsView: View {
    @State private var currentPage = 0
    let onContinue: () -> Void
    let onBack: () -> Void

    private let painPoints: [(icon: String, headline: String, subtext: String)] = [
        ("moon.zzz", "Sleepless nights\ndrain your energy", "Tossing and turning affects your entire day, leaving you exhausted and unfocused."),
        ("brain", "Racing thoughts\nkeep you awake", "Your mind won't quiet down, replaying the day and worrying about tomorrow."),
        ("sunrise.fill", "You deserve\npeaceful rest", "Quality sleep is within reach. Let us help you find your path to better nights.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Back button
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            TabView(selection: $currentPage) {
                ForEach(0..<painPoints.count, id: \.self) { index in
                    PainPointPage(
                        icon: painPoints[index].icon,
                        headline: painPoints[index].headline,
                        subtext: painPoints[index].subtext
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Page indicator
            HStack(spacing: 8) {
                ForEach(0..<painPoints.count, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? Color.purple : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(currentPage == index ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }
            .padding(.bottom, 32)

            // Continue button
            OnboardingButton(
                title: currentPage < painPoints.count - 1 ? "Continue" : "See How We Help",
                action: {
                    if currentPage < painPoints.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        onContinue()
                    }
                }
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .background(Color.black)
    }
}

struct PainPointPage: View {
    let icon: String
    let headline: String
    let subtext: String

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Large icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.purple.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)

                Image(systemName: icon)
                    .font(.system(size: 70))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Headline
            Text(headline)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)

            // Subtext
            Text(subtext)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 32)

            Spacer()
        }
    }
}

#Preview {
    OnboardingPainPointsView(
        onContinue: {},
        onBack: {}
    )
}
