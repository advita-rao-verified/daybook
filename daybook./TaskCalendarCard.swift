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
    @ObservedObject var tagStore: TagStore

    let openDetails: () -> Void
    @State private var showingTagPopover = false

    private var currentTask: CalendarTask {
        if task.repeatsWeekly,
           let date = task.occurrenceDate {
            return store.tasks(on: date).first {
                $0.id == task.id
            } ?? task
        }

        return store.tasks.first {
            $0.id == task.id
        } ?? task
    }

    private var assignedTag: DaybookTag? {
        guard let id = currentTask.tagID else {
            return nil
        }

        return tagStore.tags.first {
            $0.id == id
        }
    }

    private var assignedSubtag: DaybookSubtag? {
        guard let id = currentTask.subtagID else {
            return nil
        }

        return assignedTag?.subtags.first {
            $0.id == id
        }
    }

    private var tagLabel: String? {
        if let subtag = assignedSubtag {
            return subtag.name
        }

        return assignedTag?.name
    }

    private var tagColor: Color {
        if let subtag = assignedSubtag {
            return Color(hex: subtag.colorHex)
        }

        return assignedTag?.primaryColor ?? currentTask.color
    }

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.width < 180
            let height = geometry.size.height
            let current = currentTask
            let veryShort = height < 45
            let showSubtasks = height > 130
            let showTag = height > 85

            HStack(alignment: .top, spacing: 0) {
                Rectangle()
                    .fill(current.color)
                    .frame(width: 5)

                VStack(alignment: .leading, spacing: 4) {

                    Button(action: openDetails) {
                        Text(current.title)
                            .font(.system(
                                size: compact ? 12 : 16,
                                weight: .semibold
                            ))
                            .lineLimit(height > 110 ? 3 : 1)
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    // Always prioritize the task's time.
                    Text(
                        "\(current.start.formatted("HH:mm")) – " +
                        current.end.formatted("HH:mm")
                    )
                    .font(.system(
                        size: compact ? 10 : 12
                    ))
                    .foregroundStyle(
                        Noir.pale.opacity(0.75)
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                    // MARK: - Calendar Tag Indicator

                    if showTag, let label = tagLabel {
                        tagIndicator(label: label, compact: compact)
                            .padding(.top, 5)
                    }

                    // MARK: - Subtasks

                    if !current.subtasks.isEmpty && showSubtasks {
                        ProgressView(value: current.progress)
                            .tint(current.color)
                            .padding(.top, 5)

                        ForEach(
                            Array(
                                current.subtasks.prefix(
                                    height > 280 ? 8 : 2
                                )
                            )
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
                                            ? current.color
                                            : Noir.pale
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
                                        ? Noir.muted
                                        : Noir.pale
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(
                    veryShort ? 5 : (compact ? 8 : 12)
                )
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
            .background(
                current.color.opacity(0.22)
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 8)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        current.color.opacity(0.25)
                    )
                    .allowsHitTesting(false)
            }
        }
    }

    private func tagIndicator(
        label: String,
        compact: Bool
    ) -> some View {
        Button {
            showingTagPopover = true
        } label: {
            HStack(spacing: 6) {
                Circle()
                    .fill(tagColor)
                    .frame(width: 8, height: 8)

                Text(label.uppercased())
                    .font(.system(
                        size: compact ? 9 : 10,
                        weight: .semibold
                    ))
                    .tracking(compact ? 1 : 1.5)
                    .foregroundStyle(Noir.pale)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .popover(
            isPresented: $showingTagPopover,
            arrowEdge: .trailing
        ) {
            tagPopover
        }
    }

    // MARK: - Tag Details Popup

    private var tagPopover: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("TASK ORGANIZATION")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Noir.muted)

            if let tag = assignedTag {
                HStack(spacing: 10) {
                    Circle()
                        .fill(tag.primaryColor)
                        .frame(width: 12, height: 12)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("TAG")
                            .font(.system(size: 9))
                            .foregroundStyle(Noir.muted)

                        Text(tag.name)
                            .font(.system(
                                size: 14,
                                weight: .medium
                            ))
                    }
                }

                if let subtag = assignedSubtag {
                    Rectangle()
                        .fill(Noir.grid)
                        .frame(height: 1)

                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color(hex: subtag.colorHex))
                            .frame(width: 12, height: 12)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("SUBTAG")
                                .font(.system(size: 9))
                                .foregroundStyle(Noir.muted)

                            Text(subtag.name)
                                .font(.system(
                                    size: 14,
                                    weight: .medium
                                ))
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 230, alignment: .leading)
        .background(Noir.surface)
        .foregroundStyle(Noir.pale)
        .preferredColorScheme(.dark)
    }
}
