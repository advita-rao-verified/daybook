//
//  TaskCalendarCard.swift
//  daybook.
//
//  Created by Advita Rao on 11/18/26.
//


import SwiftUI

struct TaskCalendarCard: View {
    let task: CalendarTask
    @ObservedObject var store: TaskStore
    let openDetails: () -> Void

    private var currentTask: CalendarTask {
        if task.repeatsWeekly, let date = task.occurrenceDate {
            return store.tasks(on: date).first {
                $0.id == task.id
            } ?? task
        }

        return store.tasks.first {
            $0.id == task.id
        } ?? task
    }

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.width < 180
            let short = geometry.size.height < 65
            let current = currentTask

            HStack(alignment: .top, spacing: 0) {
                Rectangle()
                    .fill(current.color)
                    .frame(width: 5)

                VStack(alignment: .leading, spacing: 6) {
                    Button(action: openDetails) {
                        Text(current.title)
                            .font(.system(
                                size: compact ? 12 : 16,
                                weight: .semibold
                            ))
                            .lineLimit(
                                geometry.size.height > 110 ? 3 : 1
                            )
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if !short {
                        Text(
                            "\(current.start.formatted("HH:mm")) – " +
                            current.end.formatted("HH:mm")
                        )
                        .font(.system(size: compact ? 10 : 12))
                        .foregroundStyle(Noir.pale.opacity(0.75))
                    }

                    if !current.subtasks.isEmpty &&
                        geometry.size.height > 130 {

                        ProgressView(value: current.progress)
                            .tint(current.color)
                            .padding(.top, 5)

                        ForEach(
                            Array(current.subtasks.prefix(
                                geometry.size.height > 280 ? 8 : 2
                            ))
                        ) { subtask in
                            Button {
                                store.toggle(
                                    taskID: current.id,
                                    subtaskID: subtask.id,
                                    occurrenceDate: current.occurrenceDate
                                )
                            } label: {
                                HStack(spacing: 6) {
                                    Image(
                                        systemName: subtask.isDone
                                        ? "checkmark.square.fill"
                                        : "square"
                                    )
                                    .foregroundStyle(
                                        subtask.isDone
                                        ? current.color : Noir.pale
                                    )

                                    Text(subtask.title)
                                        .lineLimit(1)
                                        .strikethrough(subtask.isDone)
                                        .frame(
                                            maxWidth: .infinity,
                                            alignment: .leading
                                        )
                                }
                                .font(.system(
                                    size: compact ? 10 : 12
                                ))
                                .foregroundStyle(
                                    subtask.isDone
                                    ? Noir.muted : Noir.pale
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(compact ? 8 : 12)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .background(current.color.opacity(0.22))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(current.color.opacity(0.25))
                    .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                openDetails()
            }
        }
    }
}
