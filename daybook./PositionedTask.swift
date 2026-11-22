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
        layout.y(
            for: max(task.start, dayStart),
            on: day
        )
    }

    private var taskHeight: CGFloat {
        let start = max(task.start, dayStart)
        let end = min(task.end, dayEnd)

        return max(
            2,
            layout.y(for: end, on: day)
                - layout.y(for: start, on: day)
                - 4
        )
    }

    // MARK: - Parent / Child Relationships

    private var children: [CalendarTask] {
        guard task.isParentTask else {
            return []
        }

        return allTasks
            .filter { $0.parentTaskID == task.id }
            .sorted { $0.start < $1.start }
    }

    // Only top-level tasks participate in
    // the calendar's horizontal overlap layout.

    private var overlaps: [CalendarTask] {
        allTasks
            .filter { candidate in
                let isTopLevel = candidate.parentTaskID == nil
                    || !allTasks.contains {
                        $0.id == candidate.parentTaskID
                            && $0.isParentTask
                    }

                return isTopLevel
                    && candidate.start < task.end
                    && candidate.end > task.start
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

    // MARK: - Editing

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

    // MARK: - Main View

    var body: some View {
        Group {
            if task.isParentTask {
                parentCard
            } else {
                regularCard
            }
        }
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

    // MARK: - Regular Task

    private var regularCard: some View {
        TaskCalendarCard(
            task: task,
            store: store,
            tagStore: tagStore,
            openDetails: {
                expanded = true
            }
        )
    }

    // MARK: - Parent Task

    private var parentCard: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {

                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        Color(hex: task.colorHex)
                            .opacity(0.22)
                    )

                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        Color(hex: task.colorHex)
                            .opacity(0.65),
                        lineWidth: 1
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Button {
                        expanded = true
                    } label: {
                        VStack(
                            alignment: .leading,
                            spacing: 3
                        ) {
                            Text(task.title)
                                .font(.system(
                                    size: 12,
                                    weight: .semibold
                                ))
                                .foregroundStyle(Noir.pale)
                                .lineLimit(2)

                            Text(
                                "\(task.start.formatted(date: .omitted, time: .shortened)) – \(task.end.formatted(date: .omitted, time: .shortened))"
                            )
                            .font(.system(size: 10))
                            .foregroundStyle(Noir.muted)
                        }
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 9)
                    .padding(.top, 8)

                    // Children use the SAME timeline scale
                    // as the parent, so their vertical
                    // positions represent actual times.

                    ForEach(children) { child in
                        childCard(
                            child,
                            parentHeight: geometry.size.height
                        )
                    }
                }
            }
            .clipShape(
                RoundedRectangle(cornerRadius: 12)
            )
        }
    }

    // MARK: - Nested Child Card

    private func childCard(
        _ child: CalendarTask,
        parentHeight: CGFloat
    ) -> some View {

        let childStart = max(
            child.start,
            task.start,
            dayStart
        )

        let childEnd = min(
            child.end,
            task.end,
            dayEnd
        )

        let childY = layout.y(
            for: childStart,
            on: day
        ) - startY

        let childHeight = max(
            22,
            layout.y(for: childEnd, on: day)
                - layout.y(for: childStart, on: day)
                - 3
        )

        return TaskCalendarCard(
            task: child,
            store: store,
            tagStore: tagStore,
            openDetails: {
                edit(child)
            }
        )
        .frame(
            height: childHeight,
            alignment: .topLeading
        )
        .padding(.horizontal, 6)
        .offset(y: max(0, childY - 45))
    }
}
