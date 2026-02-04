import SwiftUI

struct ScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var schedule: ProfileSchedule
    let color: ProfileColor
    
    var body: some View {
        Form {
            Section {
                DatePicker(
                    "Start Time",
                    selection: Binding(
                        get: {
                            var components = DateComponents()
                            components.hour = schedule.startTime.hour
                            components.minute = schedule.startTime.minute
                            return Calendar.current.date(from: components) ?? Date()
                        },
                        set: { date in
                            schedule.startTime.hour = Calendar.current.component(.hour, from: date)
                            schedule.startTime.minute = Calendar.current.component(.minute, from: date)
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                
                DatePicker(
                    "End Time",
                    selection: Binding(
                        get: {
                            var components = DateComponents()
                            components.hour = schedule.endTime.hour
                            components.minute = schedule.endTime.minute
                            return Calendar.current.date(from: components) ?? Date()
                        },
                        set: { date in
                            schedule.endTime.hour = Calendar.current.component(.hour, from: date)
                            schedule.endTime.minute = Calendar.current.component(.minute, from: date)
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
            } header: {
                Text("Time Range")
            } footer: {
                Text("Apps will be blocked from \(schedule.startTimeString) to \(schedule.endTimeString)")
            }
            
            Section {
                ForEach(Weekday.allCases) { day in
                    Toggle(day.shortName, isOn: Binding(
                        get: { schedule.activeDays.contains(day) },
                        set: { isOn in
                            if isOn {
                                schedule.activeDays.insert(day)
                            } else {
                                schedule.activeDays.remove(day)
                            }
                        }
                    ))
                    .tint(color.color)
                }
            } header: {
                Text("Active Days")
            } footer: {
                Text("Select the days when this profile should automatically activate.")
            }
            
            Section {
                Button("Select Weekdays") {
                    schedule.activeDays = [.monday, .tuesday, .wednesday, .thursday, .friday]
                }
                
                Button("Select Weekend") {
                    schedule.activeDays = [.saturday, .sunday]
                }
                
                Button("Select All Days") {
                    schedule.activeDays = Set(Weekday.allCases)
                }
            } header: {
                Text("Quick Select")
            }
        }
        .navigationTitle("Schedule")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ScheduleView(schedule: .constant(ProfileSchedule()), color: .indigo)
    }
}
