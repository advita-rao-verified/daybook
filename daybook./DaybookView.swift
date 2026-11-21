//
//  DaybookView.swift
//  daybook.
//
//  Created by Advita Rao on 11/18/26.
//


import SwiftUI

struct DaybookView: View {

    @StateObject private var store = TaskStore()
    @StateObject private var tagStore = TagStore()

    @State private var selectedDate = Date()
    @State private var mode: CalendarMode = .week
    @State private var editorRequest: EditorRequest?
    @State private var editingOccurrenceDate: Date?

    @State private var selectedSection: DaybookSection = .calendar
    @State private var sidebarExpanded = true

    private var visibleDays: [Date] {
        switch mode {
        case .day:
            return [selectedDate]

        case .twoDays:
            return [
                selectedDate,
                selectedDate.addingDays(1)
            ]

        case .week:
            return (0..<7).map {
                selectedDate.monday.addingDays($0)
            }

        case .month:
            return []
        }
    }

    var body: some View {
        HStack(spacing: 0) {

            DaybookSidebar(
                selectedSection: $selectedSection,
                isExpanded: $sidebarExpanded
            )

            Group {
                if selectedSection == .calendar {
                    calendarContent
                } else if selectedSection == .tags {
                    TagsView(store: tagStore)
                } else {
                    placeholderContent
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
        }
        .background(Noir.background)
        .foregroundStyle(Noir.pale)
        .sheet(item: $editorRequest) { request in
            TaskEditor(
                tagStore: tagStore,
                task: request.task,
                initialDate: selectedDate,
                occurrenceDate: request.task?.occurrenceDate,
                save: { updated in
                    store.save(updated)
                    closeEditor()
                },
                delete: { task in
                    store.delete(task)
                    closeEditor()
                },
                deleteOccurrence: { task, date in
                    guard let original = store.tasks.first(
                        where: { $0.id == task.id }
                    ) else {
                        return
                    }

                    var occurrence = original
                    occurrence.occurrenceDate = date

                    store.deleteOccurrence(occurrence)
                    closeEditor()
                },
                cancel: {
                    closeEditor()
                }
            )
        }
    }

    // MARK: - Calendar Content

    private var calendarContent: some View {
        VStack(spacing: 0) {

            header

            Rectangle()
                .fill(Noir.grid)
                .frame(height: 1)

            if mode == .month {
                MonthCalendar(
                    date: selectedDate,
                    store: store,
                    selectDay: { day in
                        selectedDate = day
                        mode = .day
                    },
                    selectTask: openEditor
                )
            } else {
                CalendarTimeline(
                    days: visibleDays,
                    store: store,
                    edit: openEditor
                )
            }
        }
    }

    // MARK: - Placeholder Pages

    private var placeholderContent: some View {
        VStack(spacing: 16) {

            Image(systemName: selectedSection.icon)
                .font(.system(size: 35))
                .foregroundStyle(Noir.accent)

            Text(selectedSection.rawValue)
                .font(.system(
                    size: 28,
                    weight: .semibold
                ))

            Text("Coming soon to Daybook.")
                .font(.system(size: 13))
                .foregroundStyle(Noir.muted)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 17) {

            HStack(spacing: 16) {

                Image(systemName: "calendar")
                    .foregroundStyle(Noir.accent)

                Text("noir.")
                    .font(.system(
                        size: 24,
                        weight: .semibold,
                        design: .rounded
                    ))

                Spacer()

                Button("Today") {
                    selectedDate = Date()
                }
                .buttonStyle(.plain)
                .padding(10)
                .background(Noir.field)
                .cornerRadius(9)

                Button {
                    navigate(-1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)

                Button {
                    navigate(1)
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.plain)

                Picker("", selection: $mode) {
                    ForEach(
                        CalendarMode.allCases,
                        id: \.self
                    ) { option in
                        Text(option.rawValue)
                            .tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 295)

                Button {
                    editingOccurrenceDate = nil
                    editorRequest = EditorRequest(task: nil)
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 39, height: 39)
                        .background(Noir.accent)
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }

            HStack {
                Text(
                    selectedDate.formatted("MMMM yyyy")
                )
                .font(.system(
                    size: 29,
                    weight: .semibold
                ))

                Spacer()

                Text("\(store.tasks.count) tasks")
                    .font(.system(size: 12))
                    .foregroundStyle(Noir.muted)
            }
        }
        .padding(22)
    }

    // MARK: - Date Navigation

    private func navigate(_ direction: Int) {
        switch mode {

        case .day:
            selectedDate = selectedDate.addingDays(
                direction
            )

        case .twoDays:
            selectedDate = selectedDate.addingDays(
                direction * 2
            )

        case .week:
            selectedDate = selectedDate.addingDays(
                direction * 7
            )

        case .month:
            selectedDate = Calendar.current.date(
                byAdding: .month,
                value: direction,
                to: selectedDate
            ) ?? selectedDate
        }
    }

    // MARK: - Task Editor

    private func openEditor(_ task: CalendarTask) {

        let original = store.tasks.first {
            $0.id == task.id
        } ?? task

        var editableTask = original

        if original.repeatsWeekly {
            editableTask.occurrenceDate =
                task.occurrenceDate ?? task.start
        }

        editorRequest = EditorRequest(
            task: editableTask
        )
    }

    private func closeEditor() {
        editorRequest = nil
        editingOccurrenceDate = nil
    }
}
