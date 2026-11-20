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

    let layout: AdaptiveTimelineLayout
    let edit: (CalendarTask) -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Noir.grid)
                    .frame(
                        width: 1,
                        height: layout.totalHeight
                    )

                ForEach(tasks) { task in
                    PositionedTask(
                        task: task,
                        day: day,
                        allTasks: tasks,
                        width: geometry.size.width,
                        layout: layout,
                        store: store,
                        edit: edit
                    )
                }
            }
            .frame(
                width: geometry.size.width,
                height: layout.totalHeight,
                alignment: .topLeading
            )
        }
    }
}
