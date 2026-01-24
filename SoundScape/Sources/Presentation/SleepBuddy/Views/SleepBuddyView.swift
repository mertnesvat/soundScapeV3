import SwiftUI

struct SleepBuddyView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SleepBuddyService.self) private var buddyService

    @State private var showingInviteSheet = false
    @State private var showingUnpairAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if buddyService.isPaired {
                        pairedContent
                    } else {
                        unpairedContent
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Sleep Buddy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingInviteSheet) {
                InviteBuddyView()
            }
            .alert("Unpair Buddy", isPresented: $showingUnpairAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Unpair", role: .destructive) {
                    buddyService.unpair()
                }
            } message: {
                Text("Are you sure you want to unpair from your sleep buddy? You can always pair again later.")
            }
        }
    }

    // MARK: - Paired Content

    private var pairedContent: some View {
        VStack(spacing: 20) {
            // Buddy Status Card
            if let buddy = buddyService.buddy {
                BuddyStatusCard(
                    name: buddy.name,
                    streak: buddy.currentStreak,
                    lastActive: buddy.lastActiveDate,
                    isPaused: buddy.isPaused,
                    isBuddy: true
                )
            }

            // My Status Card
            BuddyStatusCard(
                name: "You",
                streak: buddyService.myStreak,
                lastActive: buddyService.myProfile.lastActiveDate,
                isPaused: buddyService.isSharingPaused,
                isBuddy: false
            )

            // Privacy Controls
            privacySection

            // Unpair Button
            unpairSection
        }
    }

    // MARK: - Unpaired Content

    private var unpairedContent: some View {
        VStack(spacing: 32) {
            // Header illustration
            VStack(spacing: 16) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.purple.gradient)

                Text("Find a Sleep Buddy")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Pair with a friend to motivate each other. See each other's sleep streaks and stay accountable together.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 20)

            // Your streak preview
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Current Streak")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Text(streakEmoji(for: buddyService.myStreak))
                        .font(.largeTitle)

                    VStack(alignment: .leading) {
                        Text("\(buddyService.myStreak) nights")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("Keep it going!")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Action buttons
            VStack(spacing: 12) {
                Button {
                    showingInviteSheet = true
                } label: {
                    Label("Invite a Friend", systemImage: "person.badge.plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.purple.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    showingInviteSheet = true
                } label: {
                    Label("Enter Invite Code", systemImage: "number")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            // Benefits
            benefitsSection
        }
    }

    // MARK: - Sections

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy")
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                Toggle(isOn: Binding(
                    get: { !buddyService.isSharingPaused },
                    set: { newValue in
                        if newValue {
                            buddyService.resumeSharing()
                        } else {
                            buddyService.pauseSharing()
                        }
                    }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Share My Progress")
                        Text("Your buddy can see your streak")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var unpairSection: some View {
        Button(role: .destructive) {
            showingUnpairAlert = true
        } label: {
            Text("Unpair from Buddy")
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Why pair with a buddy?")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                benefitRow(icon: "flame.fill", text: "Streak motivation keeps you consistent", color: .orange)
                benefitRow(icon: "bell.badge.fill", text: "Gentle nudges when streaks slip", color: .blue)
                benefitRow(icon: "heart.fill", text: "Celebrate milestones together", color: .pink)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func benefitRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)

            Spacer()
        }
    }

    // MARK: - Helpers

    private func streakEmoji(for streak: Int) -> String {
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
}

#Preview("Unpaired") {
    SleepBuddyView()
        .environment(SleepBuddyService())
        .preferredColorScheme(.dark)
}

#Preview("Paired") {
    let service = SleepBuddyService()
    service.loadMockBuddy()
    return SleepBuddyView()
        .environment(service)
        .preferredColorScheme(.dark)
}
