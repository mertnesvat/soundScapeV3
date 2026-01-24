import SwiftUI

struct ASMRInfoView: View {
    @Environment(\.dismiss) private var dismiss

    private let asmrColor = Color(red: 0.8, green: 0.6, blue: 1.0)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    headerSection

                    // What is ASMR
                    descriptionSection

                    // Common Triggers
                    triggersSection

                    // Tips
                    tipsSection
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .navigationTitle("What is ASMR?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(asmrColor.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Image(systemName: "hand.wave.fill")
                        .font(.system(size: 36))
                        .foregroundColor(asmrColor)
                }

                Text("ASMR")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Autonomous Sensory Meridian Response")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical)
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What is ASMR?")
                .font(.headline)

            Text("ASMR is a calming, pleasurable sensation often described as \"tingles\" that typically begins on the scalp and moves down the back of the neck and spine. It's triggered by specific sounds, visuals, or gentle touches.")
                .font(.body)
                .foregroundColor(.secondary)

            Text("Many people find ASMR helpful for relaxation, falling asleep, or reducing stress and anxiety.")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }

    private var triggersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Common Triggers")
                .font(.headline)

            VStack(spacing: 8) {
                TriggerRowView(
                    icon: "book.pages",
                    title: "Page Turning",
                    description: "The gentle rustling of book pages"
                )

                TriggerRowView(
                    icon: "mouth",
                    title: "Soft Whispers",
                    description: "Gentle, quiet speaking tones"
                )

                TriggerRowView(
                    icon: "hand.tap",
                    title: "Gentle Tapping",
                    description: "Fingernails on various surfaces"
                )

                TriggerRowView(
                    icon: "paintbrush",
                    title: "Soft Brushing",
                    description: "Brush strokes on microphone or surfaces"
                )

                TriggerRowView(
                    icon: "doc.text",
                    title: "Paper Crinkle",
                    description: "Crinkling paper, fabric, or packaging"
                )
            }
        }
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tips for Best Experience")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                tipItem("Use headphones for the full immersive experience")
                tipItem("Start with low volume - ASMR works best when subtle")
                tipItem("Try mixing ASMR with ambient sounds for a layered effect")
                tipItem("Different triggers work for different people - experiment!")
            }
        }
    }

    private func tipItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "sparkle")
                .font(.caption)
                .foregroundColor(asmrColor)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

private struct TriggerRowView: View {
    let icon: String
    let title: String
    let description: String

    private let asmrColor = Color(red: 0.8, green: 0.6, blue: 1.0)

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(asmrColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

/// Service to track if user has seen ASMR info
final class ASMRInfoService {
    private let hasSeenKey = "hasSeenASMRInfo"

    var hasSeenInfo: Bool {
        get { UserDefaults.standard.bool(forKey: hasSeenKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasSeenKey) }
    }

    func markAsSeen() {
        hasSeenInfo = true
    }
}

#Preview {
    ASMRInfoView()
        .preferredColorScheme(.dark)
}
