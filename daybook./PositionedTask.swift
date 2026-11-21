//
//  PositionedTask.swift
//  daybook.
//
//  Created by Advita Rao on 11/18/26.
//


import SwiftUI

struct PositionedTask: View {
    let task: CalendarTask
    let day: Date
    let allTasks: [CalendarTask]
    let width: CGFloat
    let layout: AdaptiveTimelineLayout

    @ObservedObject var store: TaskStore
    @ObservedObject var tagStore: TagStore
    

    let edit: (CalendarTask) -> Void

    @State private var expanded = false
    @State private var editAfterDismiss = false

    private var dayStart: Date {
        Calendar.current.startOfDay(for: day)
    }

    private var dayEnd: Date {
        Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: dayStart
        ) ?? dayStart.addingTimeInterval(86400)
    }

    private var startY: CGFloat {
        let visibleStart = max(task.start, dayStart)

        return layout.y(
            for: visibleStart,
            on: day
        )
    }

    private var taskHeight: CGFloat {
        let visibleStart = max(task.start, dayStart)
        let visibleEnd = min(task.end, dayEnd)

        let endY = layout.y(
            for: visibleEnd,
            on: day
        )

        let beginningY = layout.y(
            for: visibleStart,
            on: day
        )

        return max(2, endY - beginningY - 4)
    }

    private var overlaps: [CalendarTask] {
        allTasks.filter {
            $0.start < task.end
            && $0.end > task.start
        }
        .sorted {
            if $0.start == $1.start {
                return $0.id.uuidString
                    < $1.id.uuidString
            }

            return $0.start < $1.start
        }
    }

    private var slotWidth: CGFloat {
        max(
            1,
            (width - 8)
            / CGFloat(max(1, overlaps.count))
        )
    }

    private var slotIndex: Int {
        overlaps.firstIndex {
            $0.id == task.id
        } ?? 0
    }

    private var cardWidth: CGFloat {
        max(1, slotWidth - 3)
    }

    private var cardX: CGFloat {
        4 + CGFloat(slotIndex) * slotWidth
    }

    private func openSeriesEditor() {
        guard let original = store.tasks.first(
            where: { $0.id == task.id }
        ) else {
            return
        }

        var selectedOccurrence = original

        if original.repeatsWeekly {
            selectedOccurrence.occurrenceDate =
                task.occurrenceDate
                ?? Calendar.current.startOfDay(for: day)
        }

        edit(selectedOccurrence)
    }

    var body: some View {
        TaskCalendarCard(
            task: task,
            store: store,
            tagStore: tagStore,
            openDetails: {
                expanded = true
            }
        )
        .frame(
            width: cardWidth,
            height: taskHeight,
            alignment: .topLeading
        )
        .popover(isPresented: $expanded) {
            ExpandedTaskPanel(
                taskID: task.id,
                occurrenceDate: task.occurrenceDate,
                store: store,
                tagStore: tagStore,
                edit: {
                    editAfterDismiss = true
                    expanded = false
                }
            )
        }
        .onChange(of: expanded) { _, isExpanded in
            if !isExpanded && editAfterDismiss {
                editAfterDismiss = false

                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 0.3
                ) {
                    openSeriesEditor()
                }
            }
        }
        .contextMenu {
            Button("Edit Task") {
                openSeriesEditor()
            }
        }
        .position(
            x: cardX + cardWidth / 2,
            y: startY + taskHeight / 2 + 2
        )
    }
}
