import SwiftUI

struct AlarmRowView: View {
    let alarm: Alarm
    let onToggle: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(alarm.timeString)
                    .font(.system(size: 42, weight: .light, design: .rounded))
                    .foregroundStyle(alarm.isEnabled ? .primary : .secondary)

                HStack(spacing: 8) {
                    Text(alarm.label)
                        .font(.subheadline)
                        .foregroundStyle(alarm.isEnabled ? .primary : .secondary)

                    Text(alarm.repeatDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .tint(.purple)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    List {
        AlarmRowView(
            alarm: Alarm(
                time: Date(),
                repeatDays: [.monday, .wednesday, .friday],
                isEnabled: true,
                label: "Morning"
            ),
            onToggle: {}
        )

        AlarmRowView(
            alarm: Alarm(
                time: Date(),
                repeatDays: [],
                isEnabled: false,
                label: "Weekend"
            ),
            onToggle: {}
        )
    }
    .preferredColorScheme(.dark)
}
