import SwiftUI

struct AlarmsView: View {
    @Environment(AlarmService.self) private var alarmService
    @State private var showAddAlarm = false

    var body: some View {
        NavigationStack {
            Group {
                if alarmService.alarms.isEmpty {
                    ContentUnavailableView(
                        String(localized: "No Alarms"),
                        systemImage: "alarm",
                        description: Text("Tap + to create your first alarm")
                    )
                } else {
                    List {
                        ForEach(alarmService.alarms) { alarm in
                            NavigationLink {
                                AlarmDetailView(alarm: alarm, isNew: false)
                            } label: {
                                AlarmRowView(alarm: alarm) {
                                    alarmService.toggleAlarm(alarm)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                alarmService.deleteAlarm(alarmService.alarms[index])
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(LocalizedStringKey("Alarms"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddAlarm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddAlarm) {
                NavigationStack {
                    AlarmDetailView(alarm: nil, isNew: true)
                }
            }
        }
    }
}

#Preview {
    AlarmsView()
        .environment(AlarmService())
        .preferredColorScheme(.dark)
}
