//
//  DayColumn.swift
//  daybook.
//
//  Created by Advita Rao on 11/18/26.
//


import SwiftUI

struct DayColumn: View {
    let day: Date
    let tasks: [CalendarTask]
    @ObservedObject var store: TaskStore
    let hourHeight: CGFloat
    let edit: (CalendarTask) -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Noir.grid)
                    .frame(width: 1)
                    .frame(
                        height: 24 * hourHeight,
                        alignment: .top
                    )

                ForEach(tasks) { task in
                    PositionedTask(
                        task: task,
                        day: day,
                        allTasks: tasks,
                        width: geometry.size.width,
                        hourHeight: hourHeight,
                        store: store,
                        edit: edit
                    )
                }
            }
            .frame(
                width: geometry.size.width,
                height: 24 * hourHeight,
                alignment: .topLeading
            )
        }
    }
}
