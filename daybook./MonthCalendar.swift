//
//  MonthCalendar.swift
//  daybook.
//
//  Created by Advita Rao on 11/18/26.
//


import SwiftUI

struct MonthCalendar: View {
    let date: Date
    @ObservedObject var store: TaskStore
    let selectDay: (Date) -> Void
    let selectTask: (CalendarTask) -> Void

    private var dates: [Date] {
        let first = date.monthStart

        let weekday = Calendar.current.component(
            .weekday,
            from: first
        )

        let offset = (weekday + 5) % 7
        let beginning = first.addingDays(-offset)

        return (0..<42).map {
            beginning.addingDays($0)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                ForEach(
                    ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"],
                    id: \.self
                ) { weekday in
                    Text(weekday)
                        .font(.system(size: 10))
                        .foregroundStyle(Noir.muted)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 12)

            GeometryReader { geometry in
                let cellHeight = max(
                    1,
                    geometry.size.height / 6
                )

                VStack(spacing: 1) {
                    ForEach(0..<6, id: \.self) { row in
                        HStack(spacing: 1) {
                            ForEach(0..<7, id: \.self) { col in
                                let day = dates[row * 7 + col]

                                MonthCell(
                                    day: day,
                                    tasks: store.tasks(on: day),
                                    selectDay: selectDay,
                                    selectTask: selectTask
                                )
                                .frame(
                                    maxWidth: .infinity,
                                    minHeight: cellHeight,
                                    maxHeight: cellHeight
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
    }
}

struct MonthCell: View {
    let day: Date
    let tasks: [CalendarTask]
    let selectDay: (Date) -> Void
    let selectTask: (CalendarTask) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Button {
                selectDay(day)
            } label: {
                Text(day.formatted("d"))
                    .font(.system(
                        size: 13,
                        weight: .semibold
                    ))
                    .foregroundStyle(
                        Calendar.current.isDateInToday(day)
                        ? Noir.accent : Noir.pale
                    )
            }
            .buttonStyle(.plain)

            ForEach(tasks.prefix(3)) { task in
                Button {
                    selectTask(task)
                } label: {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(task.color)
                            .frame(width: 5, height: 5)

                        Text(task.title)
                            .font(.system(size: 10))
                            .lineLimit(1)

                        Spacer(minLength: 0)
                    }
                    .padding(5)
                    .background(task.color.opacity(0.2))
                    .cornerRadius(5)
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .background(Noir.surface)
    }
}
