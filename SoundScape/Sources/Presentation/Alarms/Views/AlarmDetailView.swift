import SwiftUI

struct AlarmDetailView: View {
    @Environment(AlarmService.self) private var alarmService
    @Environment(\.dismiss) private var dismiss

    let alarm: Alarm?
    let isNew: Bool

    @State private var time: Date
    @State private var label: String
    @State private var repeatDays: Set<Weekday>
    @State private var soundId: String
    @State private var volumeRampMinutes: Int
    @State private var snoozeMinutes: Int
    @State private var isEnabled: Bool

    @State private var showSoundPicker = false

    private let volumeRampOptions = [1, 5, 10, 15, 30]
    private let snoozeOptions = [5, 10, 15]

    init(alarm: Alarm?, isNew: Bool) {
        self.alarm = alarm
        self.isNew = isNew

        let alarmData = alarm ?? Alarm()
        _time = State(initialValue: alarmData.time)
        _label = State(initialValue: alarmData.label)
        _repeatDays = State(initialValue: alarmData.repeatDays)
        _soundId = State(initialValue: alarmData.soundId)
        _volumeRampMinutes = State(initialValue: alarmData.volumeRampMinutes)
        _snoozeMinutes = State(initialValue: alarmData.snoozeMinutes)
        _isEnabled = State(initialValue: alarmData.isEnabled)
    }

    private var selectedSoundName: String {
        LocalSoundDataSource.shared.getAllSounds()
            .first { $0.id == soundId }?.name ?? "Unknown"
    }

    var body: some View {
        Form {
            // Time Picker Section
            Section {
                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
            }

            // Label Section
            Section {
                TextField("Label", text: $label)
            } header: {
                Text("Label")
            }

            // Repeat Days Section
            Section {
                WeekdaySelector(selectedDays: $repeatDays)
            } header: {
                Text("Repeat")
            } footer: {
                Text(repeatDescription)
            }

            // Sound Section
            Section {
                Button {
                    showSoundPicker = true
                } label: {
                    HStack {
                        Text("Sound")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(selectedSoundName)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Alarm Sound")
            }

            // Volume Ramp Section
            Section {
                Picker("Wake Gradually", selection: $volumeRampMinutes) {
                    ForEach(volumeRampOptions, id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Volume Ramp")
            } footer: {
                Text("Gradually increase volume over \(volumeRampMinutes) minutes")
            }

            // Snooze Section
            Section {
                Picker("Snooze Duration", selection: $snoozeMinutes) {
                    ForEach(snoozeOptions, id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Snooze")
            }

            // Delete Button (for existing alarms)
            if !isNew {
                Section {
                    Button(role: .destructive) {
                        if let alarm = alarm {
                            alarmService.deleteAlarm(alarm)
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Alarm")
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle(isNew ? "Add Alarm" : "Edit Alarm")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isNew {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    saveAlarm()
                }
                .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showSoundPicker) {
            NavigationStack {
                SoundPickerView(selectedSoundId: $soundId)
            }
        }
    }

    private var repeatDescription: String {
        if repeatDays.isEmpty { return "Alarm will ring once" }
        if repeatDays.count == 7 { return "Every day" }
        if repeatDays == [.saturday, .sunday] { return "Weekends only" }
        if repeatDays == [.monday, .tuesday, .wednesday, .thursday, .friday] { return "Weekdays only" }
        return repeatDays.sorted().map { $0.fullName }.joined(separator: ", ")
    }

    private func saveAlarm() {
        let newAlarm = Alarm(
            id: alarm?.id ?? UUID(),
            time: time,
            repeatDays: repeatDays,
            soundId: soundId,
            volumeRampMinutes: volumeRampMinutes,
            snoozeMinutes: snoozeMinutes,
            isEnabled: isEnabled,
            label: label.isEmpty ? "Alarm" : label
        )

        if isNew {
            alarmService.addAlarm(newAlarm)
        } else {
            alarmService.updateAlarm(newAlarm)
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        AlarmDetailView(alarm: nil, isNew: true)
    }
    .environment(AlarmService())
    .preferredColorScheme(.dark)
}
