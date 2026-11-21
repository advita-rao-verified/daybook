//
//  (TaskEditor).swift
//  daybook.
//
//  Created by Advita Rao on 11/18/26.
//



import SwiftUI

struct TaskEditor: View {
    @ObservedObject var tagStore: TagStore

    let task: CalendarTask?
    let initialDate: Date
    let occurrenceDate: Date?

    let save: (CalendarTask) -> Void
    let delete: (CalendarTask) -> Void
    let deleteOccurrence: (CalendarTask, Date) -> Void
    let cancel: () -> Void

    @State private var title = ""
    @State private var start = Date()
    @State private var end = Date()
    @State private var colorHex = "#963F4D"
    @State private var selectedTagID: UUID?
    @State private var selectedSubtagID: UUID?
    @State private var notes = ""
    @State private var subtasks: [Subtask] = []
    @State private var newSubtask = ""

    @State private var repeatsWeekly = false
    @State private var repeatDays: Set<Int> = []

    @State private var confirmDelete = false
    @State private var chooseRecurringDeletion = false

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 10),
        count: 6
    )

    private let weekdays: [(name: String, number: Int)] = [
        ("M", 2),
        ("T", 3),
        ("W", 4),
        ("T", 5),
        ("F", 6),
        ("S", 7),
        ("S", 1)
    ]

    private var valid: Bool {
        !title.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
        && end > start
        && (!repeatsWeekly || !repeatDays.isEmpty)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 20) {
                    editorHeader
                    nameField
                    dateFields
                    repeatSection
                    tagSection
                    colorPicker
                    subtasksEditor
                    notesField
                }
                .padding(25)
            }

            Divider()

            editorFooter
                .padding(20)
        }
        .frame(width: 530, height: 690)
        .background(Noir.surface)
        .foregroundStyle(Noir.pale)
        .preferredColorScheme(.dark)
        .onAppear(perform: loadTask)

        // One-time task deletion confirmation
        .confirmationDialog(
            "Delete this task?",
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            if let task {
                Button(
                    "Delete Task",
                    role: .destructive
                ) {
                    delete(task)
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This task will be permanently deleted.")
        }

        // Recurring task deletion choices
        .confirmationDialog(
            "Delete repeating task?",
            isPresented: $chooseRecurringDeletion,
            titleVisibility: .visible
        ) {
            if let task {
                if let occurrenceDate {
                    Button(
                        "Delete Only This Occurrence",
                        role: .destructive
                    ) {
                        deleteOccurrence(task, occurrenceDate)
                    }
                }

                Button(
                    "Delete Entire Series",
                    role: .destructive
                ) {
                    delete(task)
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "Choose whether to remove only this date " +
                "or every occurrence of the repeating task."
            )
        }
    }

    // MARK: - Header

    private var editorHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(task == nil ? "New Task" : "Edit Task")
                    .font(.system(
                        size: 25,
                        weight: .semibold
                    ))

                Text("Make time for what matters.")
                    .font(.system(size: 12))
                    .foregroundStyle(Noir.muted)
            }

            Spacer()

            Button(action: cancel) {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Task Name

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("TASK NAME")

            TextField(
                "What are you planning?",
                text: $title
            )
            .textFieldStyle(.plain)
            .padding(13)
            .background(Noir.field)
            .cornerRadius(9)
        }
    }

    // MARK: - Dates

    private var dateFields: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("START")

                DatePicker(
                    "",
                    selection: $start,
                    displayedComponents: [
                        .date,
                        .hourAndMinute
                    ]
                )
                .labelsHidden()
            }

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("END")

                DatePicker(
                    "",
                    selection: $end,
                    displayedComponents: [
                        .date,
                        .hourAndMinute
                    ]
                )
                .labelsHidden()
            }
        }
    }

    // MARK: - Weekly Repeat

    private var repeatSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle(isOn: $repeatsWeekly) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Repeat weekly")
                        .font(.system(
                            size: 14,
                            weight: .medium
                        ))

                    Text("Automatically repeat on selected days")
                        .font(.system(size: 11))
                        .foregroundStyle(Noir.muted)
                }
            }
            .toggleStyle(.switch)
            .tint(Noir.accent)

            if repeatsWeekly {
                VStack(alignment: .leading, spacing: 10) {
                    sectionLabel("REPEAT ON")

                    HStack(spacing: 8) {
                        ForEach(
                            0..<weekdays.count,
                            id: \.self
                        ) { index in
                            let weekday = weekdays[index]
                            let selected = repeatDays.contains(
                                weekday.number
                            )

                            Button {
                                if selected {
                                    repeatDays.remove(
                                        weekday.number
                                    )
                                } else {
                                    repeatDays.insert(
                                        weekday.number
                                    )
                                }
                            } label: {
                                Text(weekday.name)
                                    .font(.system(
                                        size: 13,
                                        weight: .semibold
                                    ))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                                    .background(
                                        selected
                                        ? Noir.accent
                                        : Noir.field
                                    )
                                    .foregroundStyle(Noir.pale)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .help(
                                weekdayName(weekday.number)
                            )
                        }
                    }

                    HStack {
                        Text(repeatDescription)
                            .font(.system(size: 11))
                            .foregroundStyle(Noir.muted)

                        Spacer()

                        Button("Weekdays") {
                            repeatDays = [2, 3, 4, 5, 6]
                        }
                        .font(.system(size: 11))
                        .buttonStyle(.plain)
                        .foregroundStyle(Noir.accent)

                        Button("Every day") {
                            repeatDays = Set(1...7)
                        }
                        .font(.system(size: 11))
                        .buttonStyle(.plain)
                        .foregroundStyle(Noir.accent)
                    }
                }
            }
        }
        .padding(14)
        .background(Noir.field.opacity(0.45))
        .cornerRadius(12)
    }

    private var repeatDescription: String {
        if repeatDays.isEmpty {
            return "Select at least one day."
        }

        if repeatDays == Set(1...7) {
            return "Repeats every day"
        }

        if repeatDays == Set([2, 3, 4, 5, 6]) {
            return "Repeats Monday through Friday"
        }

        if repeatDays.count == 1,
           let day = repeatDays.first {
            return "Repeats every \(weekdayName(day))"
        }

        return "Repeats \(repeatDays.count) days per week"
    }

    private func weekdayName(_ day: Int) -> String {
        switch day {
        case 1: return "Sunday"
        case 2: return "Monday"
        case 3: return "Tuesday"
        case 4: return "Wednesday"
        case 5: return "Thursday"
        case 6: return "Friday"
        case 7: return "Saturday"
        default: return ""
        }
    }
    
    // MARK: - Tags and Subtags

    private var selectedTag: DaybookTag? {
        tagStore.tags.first { $0.id == selectedTagID }
    }

    private var selectedSubtag: DaybookSubtag? {
        selectedTag?.subtags.first {
            $0.id == selectedSubtagID
        }
    }

    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("ORGANIZATION")

            HStack(spacing: 12) {

                VStack(alignment: .leading, spacing: 7) {
                    Text("TAG")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Noir.muted)

                    Picker("Tag", selection: $selectedTagID) {
                        Text("No Tag")
                            .tag(nil as UUID?)

                        ForEach(tagStore.tags) { tag in
                            Text(tag.name)
                                .tag(Optional(tag.id))
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text("SUBTAG")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Noir.muted)

                    Picker("Subtag", selection: $selectedSubtagID) {
                        Text("No Subtag")
                            .tag(nil as UUID?)

                        if let tag = selectedTag {
                            ForEach(tag.subtags) { subtag in
                                Text(subtag.name)
                                    .tag(Optional(subtag.id))
                            }
                        }
                    }
                    .labelsHidden()
                    .disabled(selectedTag == nil)
                    .frame(maxWidth: .infinity)
                }
            }

            if let tag = selectedTag {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(hex: colorHex))
                        .frame(width: 15, height: 15)

                    Text(
                        selectedSubtag == nil
                            ? "Using \(tag.name)'s palette"
                            : "Color assigned from \(tag.name)"
                    )
                    .font(.system(size: 11))
                    .foregroundStyle(Noir.muted)
                }
            }
        }
        .padding(14)
        .background(Noir.field.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onChange(of: selectedTagID) { _, newID in
            selectedSubtagID = nil

            if let tag = tagStore.tags.first(where: {
                $0.id == newID
            }) {
                colorHex = tag.palette.colors.first ?? colorHex
            }
        }
        .onChange(of: selectedSubtagID) { _, newID in
            if let subtag = selectedTag?.subtags.first(where: {
                $0.id == newID
            }) {
                colorHex = subtag.colorHex
            } else if let tag = selectedTag {
                colorHex = tag.palette.colors.first ?? colorHex
            }
        }
    }


    // MARK: - Colors

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("TASK COLOR")

                Spacer()

                Text(
                    TaskPalette.colors.first {
                        $0.hex == colorHex
                    }?.name ?? "Custom"
                )
                .font(.system(size: 12))
                .foregroundStyle(Noir.muted)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(TaskPalette.colors) { shade in
                    Button {
                        colorHex = shade.hex
                    } label: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(shade.color)
                            .frame(height: 43)
                            .overlay {
                                if colorHex == shade.hex {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.white)
                                }
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        colorHex == shade.hex
                                        ? .white : .clear,
                                        lineWidth: 2
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                    .help(shade.name)
                }
            }
        }
    }

    // MARK: - Subtasks

    private var subtasksEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("SUBTASKS")

            ForEach(subtasks) { subtask in
                HStack(spacing: 10) {
                    Button {
                        if let index = subtasks.firstIndex(
                            where: { $0.id == subtask.id }
                        ) {
                            subtasks[index].isDone.toggle()
                        }
                    } label: {
                        Image(
                            systemName: subtask.isDone
                            ? "checkmark.square.fill"
                            : "square"
                        )
                        .foregroundStyle(Noir.accent)
                    }
                    .buttonStyle(.plain)

                    Text(subtask.title)
                        .strikethrough(subtask.isDone)

                    Spacer()

                    Button {
                        subtasks.removeAll {
                            $0.id == subtask.id
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Noir.muted)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                TextField(
                    "Add a subtask...",
                    text: $newSubtask
                )
                .textFieldStyle(.plain)
                .padding(11)
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

    // MARK: - Notes

    private var notesField: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("NOTES")

            TextEditor(text: $notes)
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(height: 80)
                .background(Noir.field)
                .cornerRadius(9)
        }
    }

    // MARK: - Footer

    private var editorFooter: some View {
        HStack(spacing: 16) {
            if let task {
                Button(role: .destructive) {
                    if task.repeatsWeekly {
                        chooseRecurringDeletion = true
                    } else {
                        confirmDelete = true
                    }
                } label: {
                    Label(
                        "Delete Task",
                        systemImage: "trash"
                    )
                }
                .buttonStyle(.plain)
                .foregroundStyle(Noir.accent)
            }

            Spacer()

            Button("Cancel", action: cancel)
                .buttonStyle(.plain)

            Button(action: saveTask) {
                Text("Save Task")
                    .font(.system(
                        size: 13,
                        weight: .semibold
                    ))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 11)
                    .background(
                        valid ? Noir.accent : Noir.field
                    )
                    .cornerRadius(9)
            }
            .buttonStyle(.plain)
            .disabled(!valid)
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(
                size: 10,
                weight: .semibold
            ))
            .tracking(1.3)
            .foregroundStyle(Noir.muted)
    }

    private func loadTask() {
        if let task {
            title = task.title
            start = task.start
            end = task.end
            colorHex = task.colorHex
            selectedTagID = task.tagID
            selectedSubtagID = task.subtagID
            notes = task.notes
            subtasks = task.subtasks
            repeatsWeekly = task.repeatsWeekly
            repeatDays = task.repeatDays
        } else {
            let beginning = Calendar.current.startOfDay(
                for: initialDate
            )

            start = Calendar.current.date(
                byAdding: .hour,
                value: 9,
                to: beginning
            ) ?? initialDate

            end = start.addingTimeInterval(3600)
        }
    }

    private func addSubtask() {
        let cleaned = newSubtask.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleaned.isEmpty else { return }

        subtasks.append(Subtask(title: cleaned))
        newSubtask = ""
    }

    private func saveTask() {
        guard valid else { return }

        save(
            CalendarTask(
                id: task?.id ?? UUID(),
                title: title.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
                start: start,
                end: end,
                colorHex: colorHex,
                notes: notes,
                subtasks: subtasks,
                tagID: selectedTagID,
                subtagID: selectedSubtagID,
                repeatsWeekly: repeatsWeekly,
                repeatDays: repeatsWeekly ? repeatDays : [],
                completedOccurrences:
                    task?.completedOccurrences ?? [:],
                excludedDates:
                    task?.excludedDates ?? []
            )
        )
    }
}
