import SwiftUI

struct BuddyStatusCard: View {
    let name: String
    let streak: Int
    let lastActive: Date
    let isPaused: Bool
    let isBuddy: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(isBuddy ? Color.purple.gradient : Color.blue.gradient)
                        .frame(width: 50, height: 50)

                    Text(initial)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(name)
                            .font(.headline)

                        if isPaused {
                            Image(systemName: "pause.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }

                    Text(lastActiveText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Streak badge
                streakBadge
            }

            // Streak progress bar
            if !isPaused {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Sleep Streak")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(streakMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Visual streak indicator
                    streakIndicator
                }
            } else {
                HStack {
                    Image(systemName: "eye.slash")
                        .foregroundStyle(.secondary)
                    Text("Progress hidden")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Subviews

    private var streakBadge: some View {
        HStack(spacing: 4) {
            Text(streakEmoji)
                .font(.title2)

            Text("\(streak)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(streakColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(streakColor.opacity(0.15))
        .clipShape(Capsule())
    }

    private var streakIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { index in
                Circle()
                    .fill(index < min(streak, 7) ? streakColor : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }

            if streak > 7 {
                Text("+\(streak - 7)")
                    .font(.caption2)
                    .foregroundStyle(streakColor)
            }
        }
    }

    // MARK: - Computed Properties

    private var initial: String {
        String(name.prefix(1)).uppercased()
    }

    private var lastActiveText: String {
        let interval = Date().timeIntervalSince(lastActive)

        if interval < 60 {
            return "Active now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "Active \(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "Active \(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "Active \(days)d ago"
        }
    }

    private var streakEmoji: String {
        switch streak {
        case 0:
            return "💤"
        case 1...3:
            return "🌱"
        case 4...7:
            return "🔥"
        case 8...14:
            return "⭐"
        case 15...30:
            return "🏆"
        default:
            return "👑"
        }
    }

    private var streakColor: Color {
        switch streak {
        case 0:
            return .gray
        case 1...3:
            return .green
        case 4...7:
            return .orange
        case 8...14:
            return .yellow
        case 15...30:
            return .purple
        default:
            return .pink
        }
    }

    private var streakMessage: String {
        switch streak {
        case 0:
            return "Start tonight!"
        case 1:
            return "Great start!"
        case 2...3:
            return "Building momentum"
        case 4...6:
            return "On a roll!"
        case 7:
            return "One week strong!"
        case 8...13:
            return "Impressive!"
        case 14:
            return "Two weeks!"
        case 15...29:
            return "Amazing dedication"
        case 30:
            return "One month!"
        default:
            return "Sleep champion!"
        }
    }
}

#Preview("Active Buddy") {
    VStack {
        BuddyStatusCard(
            name: "Sarah",
            streak: 7,
            lastActive: Date().addingTimeInterval(-3600),
            isPaused: false,
            isBuddy: true
        )

        BuddyStatusCard(
            name: "You",
            streak: 5,
            lastActive: Date(),
            isPaused: false,
            isBuddy: false
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}

#Preview("Paused") {
    BuddyStatusCard(
        name: "Alex",
        streak: 12,
        lastActive: Date().addingTimeInterval(-86400),
        isPaused: true,
        isBuddy: true
    )
    .padding()
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}

#Preview("High Streak") {
    BuddyStatusCard(
        name: "Champion",
        streak: 45,
        lastActive: Date().addingTimeInterval(-1800),
        isPaused: false,
        isBuddy: true
    )
    .padding()
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}
