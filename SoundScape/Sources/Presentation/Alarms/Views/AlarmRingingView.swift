import SwiftUI

struct AlarmRingingView: View {
    let alarm: Alarm
    @Environment(AlarmService.self) private var alarmService
    @State private var isPulsing = false

    private var soundName: String {
        let sounds = LocalSoundDataSource.shared.getAllSounds()
        return sounds.first(where: { $0.id == alarm.soundId })?.name ?? "Default Sound"
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.3),
                    Color.black,
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Pulsing alarm icon
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: 180, height: 180)
                        .scaleEffect(isPulsing ? 1.3 : 1.0)
                        .opacity(isPulsing ? 0.0 : 0.6)

                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 140, height: 140)
                        .scaleEffect(isPulsing ? 1.2 : 1.0)
                        .opacity(isPulsing ? 0.2 : 0.5)

                    Circle()
                        .fill(Color.purple.opacity(0.3))
                        .frame(width: 100, height: 100)

                    Image(systemName: "alarm.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white)
                }

                // Alarm info
                VStack(spacing: 12) {
                    Text(alarm.timeString)
                        .font(.system(size: 56, weight: .light, design: .rounded))
                        .foregroundStyle(.white)

                    Text(alarm.label)
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.8))

                    Text(soundName)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))
                }

                Spacer()

                // Action buttons
                VStack(spacing: 16) {
                    Button {
                        alarmService.snoozeAlarm(alarm)
                    } label: {
                        HStack {
                            Image(systemName: "zzz")
                            Text("Snooze (\(alarm.snoozeMinutes) min)")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }

                    Button {
                        alarmService.stopAlarmSound()
                    } label: {
                        HStack {
                            Image(systemName: "stop.fill")
                            Text("Stop")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
            ) {
                isPulsing = true
            }
        }
    }
}
