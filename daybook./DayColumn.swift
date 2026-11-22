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
    @ObservedObject var tagStore: TagStore

    let layout: AdaptiveTimelineLayout
    let edit: (CalendarTask) -> Void

    // Parent tasks and standalone tasks appear
    // directly on the main calendar.
    //
    // Children will be drawn inside their parents
    // by PositionedTask in the next step.

    private var visibleTasks: [CalendarTask] {
        tasks.filter { task in

            guard let parentID = task.parentTaskID else {
                return true
            }

            // Hide a child from the top-level layout
            // only if its parent is visible today.
            let parentIsVisible = tasks.contains {
                $0.id == parentID && $0.isParentTask
            }

            return !parentIsVisible
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {

                Rectangle()
                    .fill(Noir.grid)
                    .frame(
                        width: 1,
                        height: layout.totalHeight
                    )

                ForEach(visibleTasks) { task in
                    PositionedTask(
                        task: task,
                        day: day,
                        allTasks: tasks,
                        width: geometry.size.width,
                        layout: layout,
                        store: store,
                        tagStore: tagStore,
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
