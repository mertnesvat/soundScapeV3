import SwiftUI

struct OnboardingReviewsView: View {
    let onContinue: () -> Void
    let onBack: () -> Void

    private let reviews: [(text: String, author: String, duration: String)] = [
        ("Finally found something that actually helps me sleep. The rain sounds are perfect for blocking out street noise.", "Sarah M.", "Using for 3 months"),
        ("I've tried many sleep apps but this one is different. Love the sound mixing feature and the variety.", "James K.", "Using for 6 months"),
        ("My anxiety is so much better at night. This app changed my bedtime routine completely.", "Emily R.", "Using for 2 months")
    ]

    var body: some View {
        ScrollView {
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

                // Rating section
                VStack(spacing: 8) {
                    Text("4.8")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundColor(.white)

                    // Stars
                    HStack(spacing: 4) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.title2)
                                .foregroundColor(.yellow)
                        }
                    }

                    Text("100,000+ happy sleepers")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 24)
                .padding(.bottom, 32)

                // Review cards
                VStack(spacing: 16) {
                    ForEach(reviews, id: \.author) { review in
                        ReviewCard(
                            text: review.text,
                            author: review.author,
                            duration: review.duration
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)

                // Continue button
                OnboardingButton(title: "Continue", action: onContinue)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
        }
        .background(Color.black)
    }
}

struct ReviewCard: View {
    let text: String
    let author: String
    let duration: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Stars
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                }
            }

            // Quote
            Text("\"\(text)\"")
                .font(.body)
                .foregroundColor(.white)
                .lineSpacing(4)

            // Author
            HStack {
                Text(author)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Text("•")
                    .foregroundColor(.gray)

                Text(duration)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    OnboardingReviewsView(
        onContinue: {},
        onBack: {}
    )
}
