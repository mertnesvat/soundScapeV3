import SwiftUI

struct WeekdaySelector: View {
    @Binding var selectedDays: Set<Weekday>

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Weekday.orderedForDisplay, id: \.self) { day in
                WeekdayButton(
                    day: day,
                    isSelected: selectedDays.contains(day)
                ) {
                    if selectedDays.contains(day) {
                        selectedDays.remove(day)
                    } else {
                        selectedDays.insert(day)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct WeekdayButton: View {
    let day: Weekday
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(day.shortName)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isSelected ? Color.purple : Color.gray.opacity(0.2))
                )
                .foregroundStyle(isSelected ? .white : .secondary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 20) {
        WeekdaySelector(selectedDays: .constant([]))
        WeekdaySelector(selectedDays: .constant([.monday, .wednesday, .friday]))
        WeekdaySelector(selectedDays: .constant(Set(Weekday.allCases)))
    }
    .padding()
    .preferredColorScheme(.dark)
}
