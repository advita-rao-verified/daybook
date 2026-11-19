//
//  daybook_App.swift
//  daybook.
//
//  Created by Advita Rao on 10/27/26.
//


import SwiftUI
import Combine

// MARK: - APP

@main
struct DaybookApp: App {
    var body: some Scene {
        WindowGroup {
            DaybookView()
                .preferredColorScheme(.dark)
                .frame(minWidth: 950, minHeight: 650)
        }
        .defaultSize(width: 1350, height: 850)
    }
}

// MARK: - COLORS

extension Color {
    init(hex: String) {
        let value = Int(
            hex.replacingOccurrences(of: "#", with: ""),
            radix: 16
        ) ?? 0

        self.init(
            .sRGB,
            red: Double((value >> 16) & 255) / 255,
            green: Double((value >> 8) & 255) / 255,
            blue: Double(value & 255) / 255,
            opacity: 1
        )
    }
}

enum Noir {
    static let background = Color(hex: "#101013")
    static let surface = Color(hex: "#19191E")
    static let field = Color(hex: "#242027")
    static let grid = Color(hex: "#303036")
    static let muted = Color(hex: "#A99BA0")
    static let accent = Color(hex: "#B95760")
    static let pale = Color(hex: "#F4E9EC")
}

struct TaskShade: Identifiable {
    let name: String
    let hex: String

    var id: String { hex }
    var color: Color { Color(hex: hex) }
}

enum TaskPalette {
    static let colors: [TaskShade] = [
        .init(name: "Black Cherry", hex: "#471C26"),
        .init(name: "Dark Wine", hex: "#6E2936"),
        .init(name: "Burgundy", hex: "#963F4D"),
        .init(name: "Dusty Rose", hex: "#B95760"),
        .init(name: "Rosewood", hex: "#D58A8F"),
        .init(name: "Blush", hex: "#E8B5B4"),
        .init(name: "Plum", hex: "#4D303C"),
        .init(name: "Mauve", hex: "#73505D"),
        .init(name: "Orchid", hex: "#9D7582"),
        .init(name: "Rose Mauve", hex: "#C39AA5"),
        .init(name: "Soft Pink", hex: "#E0C2CA"),
        .init(name: "Petal", hex: "#F0DDE0"),
        .init(name: "Espresso", hex: "#6C4933"),
        .init(name: "Caramel", hex: "#946A45"),
        .init(name: "Muted Gold", hex: "#B68C62"),
        .init(name: "Champagne", hex: "#D5B38C"),
        .init(name: "Forest", hex: "#505C46"),
        .init(name: "Sage", hex: "#718166"),
        .init(name: "Eucalyptus", hex: "#94A485"),
        .init(name: "Pistachio", hex: "#B9C5A8"),
        .init(name: "Taupe", hex: "#625848"),
        .init(name: "Stone", hex: "#8B806D"),
        .init(name: "Sand", hex: "#B3A793"),
        .init(name: "Ivory", hex: "#D6CCBB"),
        .init(name: "Deep Slate", hex: "#354A54"),
        .init(name: "Storm Blue", hex: "#4B6876"),
        .init(name: "Dusty Blue", hex: "#7193A1"),
        .init(name: "Ice Blue", hex: "#A3BBC3"),
        .init(name: "Midnight", hex: "#3D4A67"),
        .init(name: "Steel Blue", hex: "#596A90"),
        .init(name: "Periwinkle", hex: "#8295BA"),
        .init(name: "Cloud Blue", hex: "#B7C3DC"),
        .init(name: "Dark Lavender", hex: "#51465F"),
        .init(name: "Amethyst", hex: "#76658B"),
        .init(name: "Lilac", hex: "#A08DB5"),
        .init(name: "Lavender", hex: "#C8B9D5")
    ]
}

// MARK: - MODELS

struct Subtask: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var isDone = false
}

struct CalendarTask: Identifiable, Codable {
    var id = UUID()
    var title: String
    var start: Date
    var end: Date
    var colorHex: String
    var notes = ""
    var subtasks: [Subtask] = []

    var color: Color { Color(hex: colorHex) }

    var completedCount: Int {
        subtasks.filter(\.isDone).count
    }

    var progress: Double {
        subtasks.isEmpty
        ? 0
        : Double(completedCount) / Double(subtasks.count)
    }

    enum CodingKeys: String, CodingKey {
        case id, title, start, end, colorHex, notes, subtasks
    }

    init(
        id: UUID = UUID(),
        title: String,
        start: Date,
        end: Date,
        colorHex: String,
        notes: String = "",
        subtasks: [Subtask] = []
    ) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.colorHex = colorHex
        self.notes = notes
        self.subtasks = subtasks
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        start = try c.decode(Date.self, forKey: .start)
        end = try c.decode(Date.self, forKey: .end)
        colorHex = try c.decode(String.self, forKey: .colorHex)
        notes = try c.decodeIfPresent(
            String.self, forKey: .notes
        ) ?? ""
        subtasks = try c.decodeIfPresent(
            [Subtask].self, forKey: .subtasks
        ) ?? []
    }
}

// MARK: - STORAGE

final class TaskStore: ObservableObject {
    @Published var tasks: [CalendarTask] = [] {
        didSet { persist() }
    }

    private let key = "noir.calendar.tasks.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let saved = try? JSONDecoder().decode(
                [CalendarTask].self, from: data
           ) {
            tasks = saved
        }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(tasks)
        else { return }

        UserDefaults.standard.set(data, forKey: key)
    }

    func save(_ task: CalendarTask) {
        if let index = tasks.firstIndex(where: {
            $0.id == task.id
        }) {
            tasks[index] = task
        } else {
            tasks.append(task)
        }
    }

    func delete(_ task: CalendarTask) {
        tasks.removeAll { $0.id == task.id }
    }

    func toggle(taskID: UUID, subtaskID: UUID) {
        guard let i = tasks.firstIndex(where: {
            $0.id == taskID
        }),
        let j = tasks[i].subtasks.firstIndex(where: {
            $0.id == subtaskID
        }) else { return }

        tasks[i].subtasks[j].isDone.toggle()
    }

    func addSubtask(taskID: UUID, title: String) {
        let clean = title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !clean.isEmpty,
              let i = tasks.firstIndex(where: {
                  $0.id == taskID
              }) else { return }

        tasks[i].subtasks.append(Subtask(title: clean))
    }

    func deleteSubtask(taskID: UUID, subtaskID: UUID) {
        guard let i = tasks.firstIndex(where: {
            $0.id == taskID
        }) else { return }

        tasks[i].subtasks.removeAll {
            $0.id == subtaskID
        }
    }

    func tasks(on day: Date) -> [CalendarTask] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        let end = cal.date(
            byAdding: .day, value: 1, to: start
        )!

        return tasks.filter {
            $0.start < end && $0.end > start
        }
        .sorted { $0.start < $1.start }
    }
}

// MARK: - DATE HELPERS

extension Date {
    func addDays(_ n: Int) -> Date {
        Calendar.current.date(
            byAdding: .day, value: n, to: self
        ) ?? self
    }

    func label(_ format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    var monday: Date {
        let day = Calendar.current.startOfDay(for: self)
        let weekday = Calendar.current.component(
            .weekday, from: day
        )
        return day.addDays(-((weekday + 5) % 7))
    }

    var monthStart: Date {
        let cal = Calendar.current
        return cal.date(
            from: cal.dateComponents(
                [.year, .month], from: self
            )
        ) ?? self
    }
}

enum CalendarMode: String, CaseIterable {
    case day = "Day"
    case twoDays = "2 Days"
    case week = "Week"
    case month = "Month"
}

// MARK: - EDITOR REQUEST

struct EditorRequest: Identifiable {
    let id = UUID()
    let task: CalendarTask?
}

// MARK: - MAIN VIEW

struct DaybookView: View {
    @StateObject private var store = TaskStore()

    @State private var selectedDate = Date()
    @State private var mode: CalendarMode = .twoDays
    @State private var editorRequest: EditorRequest?

    private var visibleDays: [Date] {
        switch mode {
        case .day:
            return [selectedDate]
        case .twoDays:
            return [selectedDate, selectedDate.addDays(1)]
        case .week:
            return (0..<7).map {
                selectedDate.monday.addDays($0)
            }
        case .month:
            return []
        }
    }

    var body: some View {
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
        .background(Noir.background)
        .foregroundStyle(.white)
        .sheet(item: $editorRequest) { request in
            TaskEditor(
                task: request.task,
                initialDate: selectedDate,
                save: { updated in
                    store.save(updated)
                    editorRequest = nil
                },
                delete: { task in
                    store.delete(task)
                    editorRequest = nil
                },
                cancel: {
                    editorRequest = nil
                }
            )
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: "calendar")
                    .foregroundStyle(Noir.accent)

                Text("noir.")
                    .font(.system(
                        size: 23,
                        weight: .semibold,
                        design: .rounded
                    ))

                Spacer()

                Button("Today") {
                    selectedDate = Date()
                }
                .buttonStyle(.plain)
                .padding(9)
                .background(Noir.field)
                .cornerRadius(8)

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
                    ForEach(CalendarMode.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 290)

                Button {
                    editorRequest = EditorRequest(task: nil)
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 36, height: 36)
                        .background(Noir.accent)
                        .cornerRadius(9)
                }
                .buttonStyle(.plain)
            }

            HStack {
                Text(selectedDate.label("MMMM yyyy"))
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

    private func navigate(_ direction: Int) {
        switch mode {
        case .day:
            selectedDate = selectedDate.addDays(direction)
        case .twoDays:
            selectedDate = selectedDate.addDays(direction * 2)
        case .week:
            selectedDate = selectedDate.addDays(direction * 7)
        case .month:
            selectedDate = Calendar.current.date(
                byAdding: .month,
                value: direction,
                to: selectedDate
            ) ?? selectedDate
        }
    }

    private func openEditor(_ task: CalendarTask) {
        editorRequest = EditorRequest(task: task)
    }
}

// MARK: - TIMELINE

struct CalendarTimeline: View {
    let days: [Date]
    @ObservedObject var store: TaskStore
    let edit: (CalendarTask) -> Void

    private let gutter: CGFloat = 70

    private var hourHeight: CGFloat {
        days.count <= 2 ? 100 : 76
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Color.clear.frame(width: gutter)

                ForEach(days, id: \.self) { day in
                    VStack(spacing: 5) {
                        Text(day.label("EEE").uppercased())
                            .font(.system(size: 10))
                            .foregroundStyle(Noir.muted)

                        Text(day.label("d"))
                            .font(.system(
                                size: 19, weight: .semibold
                            ))
                            .foregroundStyle(
                                Calendar.current.isDateInToday(day)
                                ? Noir.accent : .white
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 62)

            Divider()

            ScrollView(.vertical) {
                GeometryReader { geometry in
                    let columnWidth = max(
                        1,
                        (geometry.size.width - gutter) /
                        CGFloat(days.count)
                    )

                    ZStack(alignment: .topLeading) {
                        HourGrid(
                            width: geometry.size.width,
                            gutter: gutter,
                            hourHeight: hourHeight,
                            showNow: days.contains {
                                Calendar.current.isDateInToday($0)
                            }
                        )

                        HStack(alignment: .top, spacing: 0) {
                            Color.clear.frame(width: gutter)

                            ForEach(days, id: \.self) { day in
                                DayColumn(
                                    day: day,
                                    tasks: store.tasks(on: day),
                                    store: store,
                                    hourHeight: hourHeight,
                                    edit: edit
                                )
                                .frame(
                                    width: columnWidth,
                                    height: 24 * hourHeight
                                )
                            }
                        }
                    }
                    .frame(
                        width: geometry.size.width,
                        height: 24 * hourHeight,
                        alignment: .topLeading
                    )
                }
                .frame(height: 24 * hourHeight)
            }
        }
    }
}

// MARK: - HOUR GRID

struct HourGrid: View {
    let width: CGFloat
    let gutter: CGFloat
    let hourHeight: CGFloat
    let showNow: Bool

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            ZStack(alignment: .topLeading) {
                ForEach(0...24, id: \.self) { hour in
                    HStack(spacing: 0) {
                        Text(hour < 24 ? hourText(hour) : "")
                            .font(.system(size: 10))
                            .foregroundStyle(Noir.muted)
                            .frame(
                                width: gutter - 10,
                                alignment: .trailing
                            )

                        Color.clear.frame(width: 10)

                        Rectangle()
                            .fill(Noir.grid)
                            .frame(height: 1)
                    }
                    .frame(width: width)
                    .offset(
                        y: CGFloat(hour) * hourHeight
                    )
                }

                if showNow {
                    nowMarker(context.date)
                }
            }
            .frame(
                width: width,
                height: 24 * hourHeight,
                alignment: .topLeading
            )
        }
        .allowsHitTesting(false)
    }

    private func nowMarker(_ date: Date) -> some View {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: date)
        let minute = cal.component(.minute, from: date)

        let y = (
            CGFloat(hour) +
            CGFloat(minute) / 60
        ) * hourHeight

        return ZStack(alignment: .topLeading) {
            HStack(spacing: 4) {
                Text(date.label("h:mm"))
                    .font(.system(size: 10))
                    .monospacedDigit()

                Image(systemName: "chevron.right")
                    .font(.system(size: 9))
            }
            .foregroundStyle(Noir.accent)
            .frame(
                width: gutter - 3,
                alignment: .trailing
            )
            .offset(y: y - 7)

            Rectangle()
                .fill(Noir.accent)
                .frame(
                    width: max(0, width - gutter),
                    height: 1.5
                )
                .offset(x: gutter, y: y)
        }
    }

    private func hourText(_ hour: Int) -> String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        return "\(h) \(hour < 12 ? "AM" : "PM")"
    }
}

// MARK: - DAY COLUMN

struct DayColumn: View {
    let day: Date
    let tasks: [CalendarTask]
    @ObservedObject var store: TaskStore
    let hourHeight: CGFloat
    let edit: (CalendarTask) -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(Noir.grid)
                    .frame(width: 1)

                ForEach(tasks) { task in
                    PositionedTask(
                        task: task,
                        day: day,
                        allTasks: tasks,
                        width: geometry.size.width,
                        hourHeight: hourHeight,
                        store: store,
                        edit: edit
                    )
                }
            }
        }
    }
}

// MARK: - POSITIONED TASK

struct PositionedTask: View {
    let task: CalendarTask
    let day: Date
    let allTasks: [CalendarTask]
    let width: CGFloat
    let hourHeight: CGFloat
    @ObservedObject var store: TaskStore
    let edit: (CalendarTask) -> Void

    @State private var expanded = false
    @State private var editAfterDismiss = false

    private var dayStart: Date {
        Calendar.current.startOfDay(for: day)
    }

    private var dayEnd: Date {
        dayStart.addDays(1)
    }

    private var top: CGFloat {
        CGFloat(
            max(task.start, dayStart)
                .timeIntervalSince(dayStart) / 3600
        ) * hourHeight
    }

    private var blockHeight: CGFloat {
        let start = max(task.start, dayStart)
        let end = min(task.end, dayEnd)

        return max(
            1,
            CGFloat(max(0, end.timeIntervalSince(start)) / 3600)
                * hourHeight - 4
        )
    }

    private var overlapping: [CalendarTask] {
        allTasks.filter {
            $0.start < task.end && $0.end > task.start
        }
        .sorted { $0.start < $1.start }
    }

    private var slotWidth: CGFloat {
        max(
            1,
            (width - 8) /
            CGFloat(max(1, overlapping.count))
        )
    }

    private var horizontalOffset: CGFloat {
        let index = overlapping.firstIndex {
            $0.id == task.id
        } ?? 0

        return 4 + CGFloat(index) * slotWidth
    }

    var body: some View {
        TaskCalendarCard(task: task)
            .frame(
                width: max(1, slotWidth - 3),
                height: blockHeight
            )
            .contentShape(Rectangle())
            .onTapGesture {
                expanded = true
            }
            .popover(isPresented: $expanded) {
                ExpandedTaskPanel(
                    taskID: task.id,
                    store: store,
                    edit: {
                        editAfterDismiss = true
                        expanded = false
                    }
                )
            }
            .onChange(of: expanded) { _, value in
                if !value && editAfterDismiss {
                    editAfterDismiss = false
                    DispatchQueue.main.asyncAfter(
                        deadline: .now() + 0.25
                    ) {
                        edit(task)
                    }
                }
            }
            .contextMenu {
                Button("Edit Task") {
                    edit(task)
                }
            }
            .offset(
                x: horizontalOffset,
                y: top + 2
            )
    }
}

// MARK: - TASK CARD

struct TaskCalendarCard: View {
    let task: CalendarTask

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let large = width >= 390
            let medium = width >= 230
            let tiny = height < 55

            let titleSize: CGFloat =
                large ? 19 : (medium ? 15 : 12)

            let rowHeight: CGFloat =
                large ? 32 : (medium ? 27 : 23)

            let padding: CGFloat =
                large ? 16 : (medium ? 12 : 8)

            let titleLines = height >= 110 ? 3 : (
                height >= 65 ? 2 : 1
            )

            let headerSpace: CGFloat =
                CGFloat(titleLines) * (titleSize + 4) +
                (tiny ? 0 : 32) +
                padding * 2 + 25

            let available = max(0, height - headerSpace)

            let capacity = Int(available / rowHeight)
            let total = task.subtasks.count

            let visible = capacity >= total
                ? total
                : max(0, capacity - 1)

            let hidden = total - visible

            HStack(alignment: .top, spacing: 0) {
                Rectangle()
                    .fill(task.color)
                    .frame(width: large ? 6 : 4)

                VStack(alignment: .leading, spacing: 0) {
                    Text(task.title)
                        .font(.system(
                            size: titleSize,
                            weight: .semibold
                        ))
                        .lineLimit(titleLines)
                        .multilineTextAlignment(.leading)
                        .frame(
                            maxWidth: .infinity,
                            alignment: .leading
                        )

                    if !tiny {
                        Text(
                            task.start.label("HH:mm") +
                            " – " +
                            task.end.label("HH:mm")
                        )
                        .font(.system(
                            size: large ? 14 : 11
                        ))
                        .foregroundStyle(Noir.pale.opacity(0.8))
                        .padding(.top, 6)
                    }

                    if !task.subtasks.isEmpty &&
                        height > headerSpace {

                        GeometryReader { bar in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(task.color.opacity(0.2))

                                Capsule()
                                    .fill(task.color)
                                    .frame(
                                        width: bar.size.width *
                                            task.progress
                                    )
                            }
                        }
                        .frame(height: 5)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                        ForEach(
                            Array(task.subtasks.prefix(visible))
                        ) { subtask in
                            HStack(spacing: 8) {
                                Image(
                                    systemName: subtask.isDone
                                    ? "checkmark.square"
                                    : "square"
                                )

                                Text(subtask.title)
                                    .lineLimit(1)
                                    .strikethrough(subtask.isDone)

                                Spacer(minLength: 0)
                            }
                            .font(.system(
                                size: large ? 15 : 11
                            ))
                            .foregroundStyle(
                                subtask.isDone
                                ? Noir.muted : Noir.pale
                            )
                            .frame(height: rowHeight)
                        }

                        if hidden > 0 && capacity > visible {
                            Text("+\(hidden) more")
                                .font(.system(size: 10))
                                .foregroundStyle(Noir.muted)
                                .frame(height: rowHeight)
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(padding)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
            }
            .frame(
                width: width,
                height: height,
                alignment: .topLeading
            )
            .background(task.color.opacity(0.25))
            .clipShape(
                RoundedRectangle(cornerRadius: 7)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 7)
                    .stroke(task.color.opacity(0.3))
            }
        }
    }
}

// MARK: - EXPANDED TASK

struct ExpandedTaskPanel: View {
    let taskID: UUID
    @ObservedObject var store: TaskStore
    let edit: () -> Void

    @State private var newSubtask = ""

    private var task: CalendarTask? {
        store.tasks.first { $0.id == taskID }
    }

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

                        Text(
                            task.start.label("HH:mm") +
                            " – " +
                            task.end.label("HH:mm")
                        )
                        .foregroundStyle(Noir.muted)
                    }

                    Spacer()

                    Button(action: edit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 17))
                    }
                    .buttonStyle(.plain)
                    .help("Edit task")
                }

                if !task.subtasks.isEmpty {
                    ProgressView(value: task.progress)
                        .tint(task.color)

                    Text(
                        "\(task.completedCount) of \(task.subtasks.count) completed"
                    )
                    .font(.system(size: 11))
                    .foregroundStyle(Noir.muted)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(task.subtasks) { subtask in
                            HStack(spacing: 10) {
                                Button {
                                    store.toggle(
                                        taskID: taskID,
                                        subtaskID: subtask.id
                                    )
                                } label: {
                                    Image(
                                        systemName: subtask.isDone
                                        ? "checkmark.square"
                                        : "square"
                                    )
                                    .font(.system(size: 18))
                                    .foregroundStyle(task.color)
                                }
                                .buttonStyle(.plain)

                                Text(subtask.title)
                                    .strikethrough(subtask.isDone)
                                    .foregroundStyle(
                                        subtask.isDone
                                        ? Noir.muted : Noir.pale
                                    )

                                Spacer()

                                Button {
                                    store.deleteSubtask(
                                        taskID: taskID,
                                        subtaskID: subtask.id
                                    )
                                } label: {
                                    Image(systemName: "xmark")
                                        .foregroundStyle(Noir.muted)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .frame(maxHeight: 270)

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
        .frame(width: 390)
        .background(Color(hex: "#29191F"))
        .foregroundStyle(Noir.pale)
    }

    private func addSubtask() {
        store.addSubtask(
            taskID: taskID,
            title: newSubtask
        )
        newSubtask = ""
    }
}

// MARK: - MONTH VIEW

struct MonthCalendar: View {
    let date: Date
    @ObservedObject var store: TaskStore
    let selectDay: (Date) -> Void
    let selectTask: (CalendarTask) -> Void

    private var dates: [Date] {
        let first = date.monthStart
        let weekday = Calendar.current.component(
            .weekday, from: first
        )
        let offset = (weekday + 5) % 7
        let start = first.addDays(-offset)

        return (0..<42).map {
            start.addDays($0)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                ForEach(
                    ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"],
                    id: \.self
                ) { name in
                    Text(name)
                        .font(.system(size: 10))
                        .foregroundStyle(Noir.muted)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 12)

            GeometryReader { geometry in
                let cellHeight = max(
                    1, geometry.size.height / 6
                )

                VStack(spacing: 1) {
                    ForEach(0..<6, id: \.self) { row in
                        HStack(spacing: 1) {
                            ForEach(0..<7, id: \.self) { col in
                                let day = dates[row * 7 + col]

                                MonthCell(
                                    day: day,
                                    tasks: store.tasks(on: day),
                                    selectDay: selectDay,
                                    selectTask: selectTask
                                )
                                .frame(
                                    maxWidth: .infinity,
                                    minHeight: cellHeight,
                                    maxHeight: cellHeight
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
    }
}

struct MonthCell: View {
    let day: Date
    let tasks: [CalendarTask]
    let selectDay: (Date) -> Void
    let selectTask: (CalendarTask) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Button {
                selectDay(day)
            } label: {
                Text(day.label("d"))
                    .font(.system(
                        size: 13, weight: .semibold
                    ))
                    .foregroundStyle(
                        Calendar.current.isDateInToday(day)
                        ? Noir.accent : Noir.pale
                    )
            }
            .buttonStyle(.plain)

            ForEach(tasks.prefix(3)) { task in
                Button {
                    selectTask(task)
                } label: {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(task.color)
                            .frame(width: 5, height: 5)

                        Text(task.title)
                            .font(.system(size: 10))
                            .lineLimit(1)

                        Spacer(minLength: 0)
                    }
                    .padding(5)
                    .background(task.color.opacity(0.2))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
        .padding(8)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .background(Noir.surface)
    }
}

// MARK: - TASK EDITOR WITH DELETE

struct TaskEditor: View {
    let task: CalendarTask?
    let initialDate: Date
    let save: (CalendarTask) -> Void
    let delete: (CalendarTask) -> Void
    let cancel: () -> Void

    @State private var title = ""
    @State private var start = Date()
    @State private var end = Date()
    @State private var colorHex = "#963F4D"
    @State private var notes = ""
    @State private var subtasks: [Subtask] = []
    @State private var newSubtask = ""
    @State private var confirmDelete = false

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 10),
        count: 6
    )

    private var valid: Bool {
        !title.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty && end > start
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    nameField
                    dateFields
                    colorPicker
                    subtasksEditor
                    notesField
                }
                .padding(25)
            }

            Divider()

            footer
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
                "This will permanently delete the task and all its subtasks."
            )
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(task == nil ? "New Task" : "Edit Task")
                    .font(.system(
                        size: 25, weight: .semibold
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

    private var dateFields: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("START")

                DatePicker(
                    "",
                    selection: $start,
                    displayedComponents: [
                        .date, .hourAndMinute
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
                        .date, .hourAndMinute
                    ]
                )
                .labelsHidden()
            }
        }
    }

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

    private var subtasksEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("SUBTASKS")

            ForEach(subtasks) { subtask in
                HStack(spacing: 10) {
                    Button {
                        if let index = subtasks.firstIndex(where: {
                            $0.id == subtask.id
                        }) {
                            subtasks[index].isDone.toggle()
                        }
                    } label: {
                        Image(
                            systemName: subtask.isDone
                            ? "checkmark.square"
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

    private var notesField: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("NOTES")

            TextEditor(text: $notes)
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(height: 65)
                .background(Noir.field)
                .cornerRadius(9)
        }
    }

    private var footer: some View {
        HStack(spacing: 16) {
            if task != nil {
                Button(role: .destructive) {
                    confirmDelete = true
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

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(
                size: 10, weight: .semibold
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
            notes = task.notes
            subtasks = task.subtasks
        } else {
            let day = Calendar.current.startOfDay(
                for: initialDate
            )

            start = Calendar.current.date(
                byAdding: .hour,
                value: 9,
                to: day
            ) ?? initialDate

            end = start.addingTimeInterval(3600)
        }
    }

    private func addSubtask() {
        let clean = newSubtask.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !clean.isEmpty else { return }

        subtasks.append(Subtask(title: clean))
        newSubtask = ""
    }

    private func saveTask() {
        guard valid else { return }

        save(CalendarTask(
            id: task?.id ?? UUID(),
            title: title.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
            start: start,
            end: end,
            colorHex: colorHex,
            notes: notes,
            subtasks: subtasks
        ))
    }
}
