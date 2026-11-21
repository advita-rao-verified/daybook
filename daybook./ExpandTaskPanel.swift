//
//  ExpandTaskPanel.swift
//  daybook.
//
//  Created by Advita Rao on 11/18/26.
//


import SwiftUI

struct ExpandedTaskPanel: View {
    let taskID: UUID
    let occurrenceDate: Date?

    @ObservedObject var store: TaskStore
    @ObservedObject var tagStore: TagStore

    let edit: () -> Void

    @State private var newSubtask = ""

    // MARK: - Current Task

    private var task: CalendarTask? {
        guard let original = store.tasks.first(where: {
            $0.id == taskID
        }) else {
            return nil
        }

        if original.repeatsWeekly, let occurrenceDate {
            return store.tasks(on: occurrenceDate).first {
                $0.id == taskID
            }
        }

        return original
    }

    // MARK: - Assigned Tags

    private var assignedTag: DaybookTag? {
        guard let tagID = task?.tagID else {
            return nil
        }

        return tagStore.tags.first {
            $0.id == tagID
        }
    }

    private var assignedSubtag: DaybookSubtag? {
        guard let subtagID = task?.subtagID else {
            return nil
        }

        return assignedTag?.subtags.first {
            $0.id == subtagID
        }
    }

    private var tagLabel: String? {
        assignedSubtag?.name ?? assignedTag?.name
    }

    private var tagColor: Color {
        if let subtag = assignedSubtag {
            return Color(hex: subtag.colorHex)
        }

        return assignedTag?.primaryColor ?? Noir.accent
    }

    // MARK: - Main View

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            if let task {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(task.title)
                            .font(.system(
                                size: 22,
                                weight: .semibold
                            ))
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )
                            .frame(
                                maxWidth: .infinity,
                                alignment: .leading
                            )

                        Text(
                            "\(task.start.formatted("h:mm a")) – " +
                            task.end.formatted("h:mm a")
                        )
                        .foregroundStyle(Noir.muted)

                        // MARK: - Tag Indicator

                        if let label = tagLabel {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(tagColor)
                                    .frame(width: 10, height: 10)

                                Text(label.uppercased())
                                    .font(.system(
                                        size: 11,
                                        weight: .semibold
                                    ))
                                    .tracking(1.8)
                                    .foregroundStyle(Noir.pale)
                                    .lineLimit(1)
                            }
                            .padding(.top, 7)
                            .help(
                                assignedTag.map {
                                    "Tag: \($0.name)" +
                                    (assignedSubtag.map {
                                        " • Subtag: \($0.name)"
                                    } ?? "")
                                } ?? ""
                            )
                        }

                        if task.repeatsWeekly {
                            Label(
                                "Repeats weekly",
                                systemImage: "repeat"
                            )
                            .font(.system(size: 11))
                            .foregroundStyle(Noir.accent)
                            .padding(.top, 3)
                        }
                    }

                    Spacer()

                    Button(action: edit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 17))
                    }
                    .buttonStyle(.plain)
                    .help("Edit repeating series")
                }

                // MARK: - Subtask Progress

                if !task.subtasks.isEmpty {
                    ProgressView(value: task.progress)
                        .tint(task.color)

                    Text(
                        "\(task.completedCount) of " +
                        "\(task.subtasks.count) completed"
                    )
                    .font(.system(size: 11))
                    .foregroundStyle(Noir.muted)
                }

                // MARK: - Existing Subtasks

                ScrollView {
                    VStack(alignment: .leading, spacing: 13) {
                        ForEach(task.subtasks) { subtask in
                            HStack(spacing: 10) {
                                Button {
                                    store.toggle(
                                        taskID: taskID,
                                        subtaskID: subtask.id,
                                        occurrenceDate: task.occurrenceDate
                                    )
                                } label: {
                                    Image(
                                        systemName: subtask.isDone
                                            ? "checkmark.square.fill"
                                            : "square"
                                    )
                                    .foregroundStyle(task.color)
                                }
                                .buttonStyle(.plain)

                                Text(subtask.title)
                                    .strikethrough(subtask.isDone)

                                Spacer()

                                Button {
                                    store.removeSubtask(
                                        taskID: taskID,
                                        subtaskID: subtask.id
                                    )
                                } label: {
                                    Image(systemName: "xmark")
                                        .foregroundStyle(Noir.muted)
                                }
                                .buttonStyle(.plain)
                                .help("Remove subtask from task")
                            }
                        }
                    }
                }
                .frame(maxHeight: 280)

                // MARK: - Add Subtask

                HStack {
                    TextField(
                        "Add a subtask...",
                        text: $newSubtask
                    )
                    .textFieldStyle(.plain)
                    .padding(10)
                    .background(Noir.field)
                    .cornerRadius(8)
                    .onSubmit(addSubtask)

                    Button(action: addSubtask) {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(24)
        .frame(width: 450)
        .background(Color(hex: "#29191F"))
        .foregroundStyle(Noir.pale)
    }

    // MARK: - Add Subtask

    private func addSubtask() {
        store.addSubtask(
            taskID: taskID,
            title: newSubtask
        )

        newSubtask = ""
    }
}
