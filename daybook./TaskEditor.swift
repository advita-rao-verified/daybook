//
//  (TaskEditor).swift
//  daybook.
//
//  Created by Advita Rao on 11/18/26.
//




import SwiftUI

struct TaskEditor: View {

    @ObservedObject var tagStore: TagStore
    @ObservedObject var store: TaskStore

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

    @State private var isParentTask = false
    @State private var selectedParentID: UUID?

    @State private var confirmDelete = false
    @State private var chooseRecurringDeletion = false

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 10),
        count: 6
    )

    private let weekdays: [(name: String, number: Int)] = [
        ("M", 2), ("T", 3), ("W", 4),
        ("T", 5), ("F", 6), ("S", 7), ("S", 1)
    ]

    // MARK: - Validation

    private var valid: Bool {
        let hasTitle = !title.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty

        let validTime = end > start
        let validRepeat = !repeatsWeekly || !repeatDays.isEmpty

        let validRelationship: Bool

        if let parentID = selectedParentID {
            validRelationship = availableParents.contains {
                $0.id == parentID
            }
        } else {
            validRelationship = true
        }

        let validChildren: Bool

        if task?.isParentTask == true {
            let children = store.tasks.filter {
                $0.parentTaskID == task?.id
            }

            validChildren = isParentTask
                && !repeatsWeekly
                && children.allSatisfy {
                    $0.start >= start && $0.end <= end
                }
        } else {
            validChildren = true
        }

        return hasTitle
            && validTime
            && validRepeat
            && validRelationship
            && validChildren
    }

    // MARK: - Main View

    var body: some View {
        VStack(spacing: 0) {

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 20) {

                    editorHeader
                    nameField
                    dateFields
                    repeatSection
                    parentTaskSection
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

        .confirmationDialog(
            "Delete this task?",
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            if let task {
                Button("Delete Task", role: .destructive) {
                    delete(task)
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                task?.isParentTask == true
                ? "Deleting this parent will also affect its child tasks."
                : "This task will be permanently deleted."
            )
        }

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
                "Choose whether to remove only this date or every occurrence of the repeating task."
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
                    displayedComponents: [.date, .hourAndMinute]
                )
                .labelsHidden()
            }

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("END")

                DatePicker(
                    "",
                    selection: $end,
                    displayedComponents: [.date, .hourAndMinute]
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
            .disabled(
                isParentTask
                || selectedParentID != nil
                || task?.isParentTask == true
            )

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
                                    repeatDays.remove(weekday.number)
                                } else {
                                    repeatDays.insert(weekday.number)
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
                            .help(weekdayName(weekday.number))
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

    // MARK: - Parent / Child Calendar Blocks

    private var availableParents: [CalendarTask] {
        store.tasks
            .filter { candidate in
                candidate.isParentTask
                    && !candidate.repeatsWeekly
                    && candidate.id != task?.id
                    && candidate.start <= start
                    && candidate.end >= end
            }
            .sorted { $0.start < $1.start }
    }

    private var parentTaskSection: some View {
        VStack(alignment: .leading, spacing: 14) {

            sectionLabel("CALENDAR BLOCK TYPE")

            Toggle(isOn: $isParentTask) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Parent calendar block")
                        .font(.system(
                            size: 14,
                            weight: .medium
                        ))

                    Text(
                        "A larger event that contains smaller scheduled events."
                    )
                    .font(.system(size: 11))
                    .foregroundStyle(Noir.muted)
                }
            }
            .toggleStyle(.switch)
            .tint(Noir.accent)
            .disabled(
                repeatsWeekly
                || selectedParentID != nil
                || (task?.isParentTask == true
                    && store.tasks.contains {
                        $0.parentTaskID == task?.id
                    })
            )

            if !isParentTask && !repeatsWeekly {

                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("BELONGS TO")

                    Picker(
                        "Parent Event",
                        selection: $selectedParentID
                    ) {
                        Text("No Parent — Standalone Task")
                            .tag(nil as UUID?)

                        ForEach(availableParents) { parent in
                            Text(parent.title)
                                .tag(Optional(parent.id))
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity)

                    Text(
                        "Choose a parent event that fully contains this task's scheduled time."
                    )
                    .font(.system(size: 11))
                    .foregroundStyle(Noir.muted)
                }
            }

            if isParentTask {
                Label(
                    "You can place other calendar tasks inside this event.",
                    systemImage: "square.on.square"
                )
                .font(.system(size: 11))
                .foregroundStyle(Noir.muted)
            }

            if task?.isParentTask == true {
                let children = store.tasks.filter {
                    $0.parentTaskID == task?.id
                }

                if !children.isEmpty {
                    VStack(alignment: .leading, spacing: 5) {
                        sectionLabel("CHILD EVENTS")

                        ForEach(children) { child in
                            HStack(spacing: 7) {
                                Circle()
                                    .fill(Color(hex: child.colorHex))
                                    .frame(width: 7, height: 7)

                                Text(child.title)
                                    .font(.system(size: 12))

                                Spacer()

                                Text(
                                    child.start.formatted(
                                        date: .omitted,
                                        time: .shortened
                                    )
                                )
                                .font(.system(size: 10))
                                .foregroundStyle(Noir.muted)
                            }
                        }

                        Text(
                            "The parent must contain every child event's full time range."
                        )
                        .font(.system(size: 11))
                        .foregroundStyle(Noir.muted)
                    }
                }
            }
        }
        .padding(14)
        .background(Noir.field.opacity(0.45))
        .clipShape(
            RoundedRectangle(cornerRadius: 12)
        )
        .onChange(of: repeatsWeekly) { _, repeats in
            if repeats {
                isParentTask = false
                selectedParentID = nil
            }
        }
        .onChange(of: isParentTask) { _, newValue in
            if newValue {
                selectedParentID = nil
            }
        }
        .onChange(of: start) { _, _ in
            clearInvalidParent()
        }
        .onChange(of: end) { _, _ in
            clearInvalidParent()
        }
    }

    private func clearInvalidParent() {
        guard let selectedParentID else { return }

        if !availableParents.contains(where: {
            $0.id == selectedParentID
        }) {
            self.selectedParentID = nil
        }
    }

    // MARK: - Tags and Subtags

    private var selectedTag: DaybookTag? {
        tagStore.tags.first {
            $0.id == selectedTagID
        }
    }

    private var selectedSubtag: DaybookSubtag? {
        selectedTag?.subtags.first {
            $0.id == selectedSubtagID
        }
    }

    private var tagSection: some View {
        VStack(alignment: .leading, spacing: 14) {

            sectionLabel("ORGANIZATION")

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    sectionLabel("TAG")

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
                    sectionLabel("SUBTAG")

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
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        sectionLabel("TAG PALETTE")

                        Spacer()

                        Text(tag.palette.name)
                            .font(.system(size: 11))
                            .foregroundStyle(Noir.muted)
                    }

                    HStack(spacing: 9) {
                        ForEach(
                            tag.palette.colors,
                            id: \.self
                        ) { hex in
                            Button {
                                colorHex = hex
                            } label: {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: hex))
                                    .frame(
                                        maxWidth: .infinity
                                    )
                                    .frame(height: 42)
                                    .overlay {
                                        if colorHex == hex {
                                            Image(
                                                systemName: "checkmark"
                                            )
                                            .font(.system(
                                                size: 14,
                                                weight: .bold
                                            ))
                                            .foregroundStyle(.white)
                                        }
                                    }
                                    .overlay {
                                        RoundedRectangle(
                                            cornerRadius: 8
                                        )
                                        .stroke(
                                            colorHex == hex
                                            ? Color.white
                                            : Color.clear,
                                            lineWidth: 2
                                        )
                                    }
                            }
                            .buttonStyle(.plain)
                            .help("Use shade \(hex)")
                        }
                    }

                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: colorHex))
                            .frame(width: 10, height: 10)

                        Text(
                            selectedSubtag.map {
                                "\($0.name) • \(tag.name)"
                            } ?? "Choose a shade for this task"
                        )
                        .font(.system(size: 11))
                        .foregroundStyle(Noir.muted)

                        Spacer()

                        Text(colorHex.uppercased())
                            .font(.system(
                                size: 10,
                                design: .monospaced
                            ))
                            .foregroundStyle(Noir.muted)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(14)
        .background(Noir.field.opacity(0.45))
        .clipShape(
            RoundedRectangle(cornerRadius: 12)
        )
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

            LazyVGrid(
                columns: columns,
                spacing: 12
            ) {
                ForEach(TaskPalette.colors) { shade in
                    Button {
                        colorHex = shade.hex
                    } label: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(shade.color)
                            .frame(height: 43)
                            .overlay {
                                if colorHex == shade.hex {
                                    Image(
                                        systemName: "checkmark"
                                    )
                                    .foregroundStyle(.white)
                                }
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        colorHex == shade.hex
                                        ? Color.white
                                        : Color.clear,
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

    // MARK: - Checklist Subtasks

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

            isParentTask = task.isParentTask
            selectedParentID = task.parentTaskID

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

    // MARK: - Save Task

    private func saveTask() {
        guard valid else { return }

        let parentID: UUID? =
            (!isParentTask && !repeatsWeekly)
            ? selectedParentID
            : nil

        var updated = CalendarTask(
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

        updated.isParentTask =
            isParentTask && !repeatsWeekly

        updated.parentTaskID = parentID

        save(updated)
    }
}
