//
//  daybook_App.swift
//  daybook.
//
//  Created by Advita Rao on 10/27/26.
//



import SwiftUI
import Combine

// MARK: - NOIR APP

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

// MARK: - THEME

enum Noir {
    static let background = Color(hex: "#101013")
    static let surface = Color(hex: "#19191E")
    static let field = Color(hex: "#242027")
    static let grid = Color(hex: "#303036")
    static let muted = Color(hex: "#A99BA0")
    static let accent = Color(hex: "#B95760")
    static let pale = Color(hex: "#F4E9EC")
}

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

    var color: Color {
        Color(hex: colorHex)
    }

    var completedCount: Int {
        subtasks.filter(\.isDone).count
    }

    var progress: Double {
        guard !subtasks.isEmpty else { return 0 }
        return Double(completedCount) / Double(subtasks.count)
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

// MARK: - PERSISTENT STORAGE

final class TaskStore: ObservableObject {
    @Published var tasks: [CalendarTask] = [] {
        didSet { persist() }
    }

    private let storageKey = "noir.calendar.tasks.v1"

    init() {
        guard let data = UserDefaults.standard.data(
            forKey: storageKey
        ),
        let saved = try? JSONDecoder().decode(
            [CalendarTask].self, from: data
        ) else { return }

        tasks = saved
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(tasks)
        else { return }

        UserDefaults.standard.set(data, forKey: storageKey)
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

    func toggleSubtask(taskID: UUID, subtaskID: UUID) {
        guard let i = tasks.firstIndex(where: {
            $0.id == taskID
        }),
        let j = tasks[i].subtasks.firstIndex(where: {
            $0.id == subtaskID
        }) else { return }

        tasks[i].subtasks[j].isDone.toggle()
    }

    func addSubtask(to taskID: UUID, title: String) {
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

        tasks[i].subtasks.removeAll { $0.id == subtaskID }
    }

    func tasks(on day: Date) -> [CalendarTask] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        let end = cal.date(byAdding: .day, value: 1, to: start)!

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
        let f = DateFormatter()
        f.dateFormat = format
        return f.string(from: self)
    }

    var monday: Date {
        let cal = Calendar.current
        let day = cal.startOfDay(for: self)
        let weekday = cal.component(.weekday, from: day)
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

// MARK: - MAIN VIEW

struct DaybookView: View {
    @StateObject private var store = TaskStore()

    @State private var selectedDate = Date()
    @State private var mode: CalendarMode = .twoDays
    @State private var editingTask: CalendarTask?
    @State private var showingEditor = false

    private var visibleDays: [Date] {
        switch mode {
        case .day:
            return [selectedDate]
        case .twoDays:
            return [selectedDate, selectedDate.addDays(1)]
        case .week, .month:
            return (0..<7).map {
                selectedDate.monday.addDays($0)
            }
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
                    edit: openEditor
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
        .sheet(isPresented: $showingEditor) {
            TaskEditor(
                task: editingTask,
                initialDate: selectedDate,
                save: { task in
                    store.save(task)
                    showingEditor = false
                },
                delete: { task in
                    store.delete(task)
                    showingEditor = false
                },
                cancel: {
                    showingEditor = false
                }
            )
            .id(editingTask?.id.uuidString ?? "new")
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: "calendar")
                    .foregroundStyle(Noir.accent)

                Text("noir.")
                    .font(.system(
                        size: 23, weight: .semibold,
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
                    editingTask = nil
                    showingEditor = true
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
                        size: 29, weight: .semibold,
                        design: .rounded
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
        editingTask = task
        showingEditor = true
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
            dateHeaders

            Rectangle()
                .fill(Noir.grid)
                .frame(height: 1)

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
                            Color.clear
                                .frame(width: gutter)

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
        .frame(maxHeight: .infinity)
    }

    private var dateHeaders: some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: gutter, height: 62)

            ForEach(days, id: \.self) { day in
                VStack(spacing: 5) {
                    Text(day.label("EEE").uppercased())
                        .font(.system(
                            size: 10, weight: .semibold
                        ))
                        .tracking(1.2)
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
                .frame(height: 62)
            }
        }
        .frame(height: 62)
    }
}

// MARK: - HOUR GRID AND LIVE TIME

struct HourGrid: View {
    let width: CGFloat
    let gutter: CGFloat
    let hourHeight: CGFloat
    let showNow: Bool

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            ZStack(alignment: .topLeading) {
                gridLines

                if showNow {
                    currentTimeMarker(context.date)
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

    private var gridLines: some View {
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
                .frame(width: width, height: 1)
                .offset(y: CGFloat(hour) * hourHeight)
            }
        }
    }

    private func currentTimeMarker(_ now: Date) -> some View {
        let cal = Calendar.current
        let hour = cal.component(.hour, from: now)
        let minute = cal.component(.minute, from: now)
        let second = cal.component(.second, from: now)

        let y = (
            CGFloat(hour) +
            CGFloat(minute) / 60 +
            CGFloat(second) / 3600
        ) * hourHeight

        return ZStack(alignment: .topLeading) {
            HStack(spacing: 4) {
                Text(now.label("h:mm"))
                    .font(.system(
                        size: 10, weight: .semibold
                    ))
                    .monospacedDigit()

                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundStyle(Noir.accent)
            .frame(
                width: gutter - 3,
                alignment: .trailing
            )
            .offset(y: y - 7)

            Rectangle()
                .fill(Noir.accent.opacity(0.9))
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
                    .allowsHitTesting(false)

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

// MARK: - TASK POSITIONING

struct PositionedTask: View {
    let task: CalendarTask
    let day: Date
    let allTasks: [CalendarTask]
    let width: CGFloat
    let hourHeight: CGFloat
    @ObservedObject var store: TaskStore
    let edit: (CalendarTask) -> Void

    @State private var expanded = false

    private var dayStart: Date {
        Calendar.current.startOfDay(for: day)
    }

    private var dayEnd: Date {
        Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: dayStart
        )!
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
        .sorted {
            if $0.start == $1.start {
                return $0.id.uuidString < $1.id.uuidString
            }
            return $0.start < $1.start
        }
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
                height: blockHeight,
                alignment: .topLeading
            )
            .clipped()
            .contentShape(Rectangle())
            .onTapGesture {
                expanded = true
            }
            .popover(
                isPresented: $expanded,
                arrowEdge: .trailing
            ) {
                ExpandedTaskPanel(
                    taskID: task.id,
                    store: store,
                    edit: {
                        expanded = false
                        edit(task)
                    }
                )
            }
            .offset(
                x: horizontalOffset,
                y: top + 2
            )
    }
}

// MARK: - FIXED TASK CARD

struct TaskCalendarCard: View {
    let task: CalendarTask

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            let large = width >= 390
            let medium = width >= 230
            let tiny = height < 55

            let inset: CGFloat = large ? 18 : (medium ? 13 : 8)
            let titleSize: CGFloat = large ? 19 : (medium ? 15 : 12)
            let timeSize: CGFloat = large ? 14 : (medium ? 12 : 10)
            let rowSize: CGFloat = large ? 15 : (medium ? 12 : 10)
            let rowHeight: CGFloat = large ? 32 : (medium ? 27 : 23)

            let titleLines = height >= 110 ? 3 : (height >= 65 ? 2 : 1)

            let headerHeight: CGFloat =
                CGFloat(titleLines) * (titleSize + 4) +
                (tiny ? 0 : timeSize + 13) +
                inset * 2 + 14

            let hasProgress =
                !task.subtasks.isEmpty &&
                height >= headerHeight + 18

            let remainingHeight = max(
                0,
                height - headerHeight -
                (hasProgress ? 20 : 0)
            )

            let rowCapacity = Int(
                remainingHeight / rowHeight
            )

            let total = task.subtasks.count

            let visibleCount: Int = {
                if rowCapacity >= total {
                    return total
                }
                return max(0, rowCapacity - 1)
            }()

            let hiddenCount = total - visibleCount

            ZStack(alignment: .topLeading) {
                task.color.opacity(0.25)

                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(task.color)
                        .frame(width: large ? 6 : 4)

                    VStack(
                        alignment: .leading,
                        spacing: 0
                    ) {
                        Text(task.title)
                            .font(.system(
                                size: titleSize,
                                weight: .semibold
                            ))
                            .foregroundStyle(.white)
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
                            .font(.system(size: timeSize))
                            .foregroundStyle(
                                Noir.pale.opacity(0.8)
                            )
                            .padding(.top, 6)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        }

                        if hasProgress {
                            HStack(spacing: 8) {
                                GeometryReader { bar in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(
                                                task.color.opacity(0.2)
                                            )

                                        Capsule()
                                            .fill(task.color)
                                            .frame(
                                                width: bar.size.width *
                                                    task.progress
                                            )
                                    }
                                }
                                .frame(height: 5)

                                Text(
                                    "\(task.completedCount)/\(total)"
                                )
                                .font(.system(size: 10))
                                .foregroundStyle(Noir.muted)
                            }
                            .frame(height: 12)
                            .padding(.top, 12)
                            .padding(.bottom, 8)

                            VStack(
                                alignment: .leading,
                                spacing: 0
                            ) {
                                ForEach(
                                    Array(
                                        task.subtasks.prefix(visibleCount)
                                    )
                                ) { subtask in
                                    HStack(spacing: 8) {
                                        Image(
                                            systemName: subtask.isDone
                                            ? "checkmark.square"
                                            : "square"
                                        )
                                        .font(.system(
                                            size: rowSize + 1
                                        ))
                                        .foregroundStyle(
                                            subtask.isDone
                                            ? task.color : Noir.pale
                                        )

                                        Text(subtask.title)
                                            .font(.system(
                                                size: rowSize
                                            ))
                                            .lineLimit(1)
                                            .strikethrough(
                                                subtask.isDone
                                            )
                                            .foregroundStyle(
                                                subtask.isDone
                                                ? Noir.muted
                                                : Noir.pale
                                            )

                                        Spacer(minLength: 0)
                                    }
                                    .frame(
                                        height: rowHeight,
                                        alignment: .leading
                                    )
                                    Spacer(minLength: 0)
                                }

                                if hiddenCount > 0 &&
                                    rowCapacity > visibleCount {
                                    Text("+\(hiddenCount) more")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Noir.muted)
                                        .frame(
                                            height: rowHeight,
                                            alignment: .leading
                                        )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, inset)
                    .padding(.vertical, tiny ? 5 : inset)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .topLeading
                    )
                }
            }
            .frame(
                width: width,
                height: height,
                alignment: .topLeading
            )
            .clipShape(
                RoundedRectangle(cornerRadius: 7)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 7)
                    .stroke(
                        task.color.opacity(0.3),
                        lineWidth: 1
                    )
            }
        }
    }
}

// MARK: - EXPANDED TASK PANEL

struct ExpandedTaskPanel: View {
    let taskID: UUID
    @ObservedObject var store: TaskStore
    let edit: () -> Void

    @State private var newSubtask = ""

    private var task: CalendarTask? {
        store.tasks.first { $0.id == taskID }
    }

    var body: some View {
        Group {
            if let task {
                panel(for: task)
            } else {
                Text("Task no longer exists")
                    .padding()
            }
        }
        .frame(width: 390)
        .background(Noir.background)
        .foregroundStyle(Noir.pale)
    }

    private func panel(for task: CalendarTask) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(task.title)
                        .font(.system(
                            size: 22, weight: .semibold
                        ))
                        .lineLimit(nil)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                        .multilineTextAlignment(.leading)

                    Text(
                        task.start.label("HH:mm") +
                        " – " +
                        task.end.label("HH:mm")
                    )
                    .foregroundStyle(Noir.muted)
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )

                Button(action: edit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 17))
                }
                .buttonStyle(.plain)
                .help("Edit task")
            }

            if !task.subtasks.isEmpty {
                HStack(spacing: 10) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(task.color.opacity(0.2))

                            Capsule()
                                .fill(task.color)
                                .frame(
                                    width: geometry.size.width *
                                        task.progress
                                )
                        }
                    }
                    .frame(height: 6)

                    Text(
                        "\(task.completedCount)/\(task.subtasks.count)"
                    )
                    .font(.system(size: 12))
                    .foregroundStyle(Noir.muted)
                }
            }

            if !task.notes.isEmpty {
                Text(task.notes)
                    .font(.system(size: 12))
                    .foregroundStyle(Noir.muted)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(task.subtasks) { subtask in
                        HStack(spacing: 10) {
                            Button {
                                store.toggleSubtask(
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
                                .foregroundStyle(
                                    subtask.isDone
                                    ? task.color : Noir.pale
                                )
                            }
                            .buttonStyle(.plain)

                            Text(subtask.title)
                                .font(.system(size: 13))
                                .strikethrough(subtask.isDone)
                                .foregroundStyle(
                                    subtask.isDone
                                    ? Noir.muted : Noir.pale
                                )
                                .fixedSize(
                                    horizontal: false,
                                    vertical: true
                                )

                            Spacer()

                            Button {
                                store.deleteSubtask(
                                    taskID: taskID,
                                    subtaskID: subtask.id
                                )
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10))
                                    .foregroundStyle(Noir.muted)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 280)

            HStack(spacing: 9) {
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
                        .frame(width: 34, height: 34)
                        .background(Noir.field)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(23)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#29191F"))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Noir.accent.opacity(0.5))
        }
        .padding(8)
    }

    private func addSubtask() {
        store.addSubtask(
            to: taskID,
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
    let edit: (CalendarTask) -> Void

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
            HStack(spacing: 0) {
                ForEach(
                    ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"],
                    id: \.self
                ) { name in
                    Text(name)
                        .font(.system(
                            size: 10, weight: .semibold
                        ))
                        .foregroundStyle(Noir.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }

            GeometryReader { geometry in
                let height = max(
                    1, (geometry.size.height - 5) / 6
                )

                VStack(spacing: 1) {
                    ForEach(0..<6, id: \.self) { row in
                        HStack(spacing: 1) {
                            ForEach(0..<7, id: \.self) { col in
                                MonthCell(
                                    day: dates[row * 7 + col],
                                    tasks: store.tasks(
                                        on: dates[row * 7 + col]
                                    ),
                                    selectDay: selectDay,
                                    edit: edit
                                )
                                .frame(
                                    maxWidth: .infinity,
                                    minHeight: height,
                                    maxHeight: height
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
    let edit: (CalendarTask) -> Void

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
                    edit(task)
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

            if tasks.count > 3 {
                Text("+\(tasks.count - 3) more")
                    .font(.system(size: 9))
                    .foregroundStyle(Noir.muted)
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

// MARK: - TASK EDITOR

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
                    editorHeader
                    nameField
                    dateFields
                    colorPicker
                    subtasksEditor
                    notesField
                }
                .padding(25)
            }

            Divider()

            editorButtons
                .padding(20)
        }
        .frame(width: 530, height: 690)
        .background(Noir.surface)
        .foregroundStyle(.white)
        .preferredColorScheme(.dark)
        .onAppear(perform: loadTask)
    }
    private var editorHeader: some View {
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
                        if let i = subtasks.firstIndex(where: {
                            $0.id == subtask.id
                        }) {
                            subtasks[i].isDone.toggle()
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

    private var editorButtons: some View {
        HStack(spacing: 16) {
            if let task {
                Button {
                    delete(task)
                } label: {
                    Label("Delete", systemImage: "trash")
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
                        size: 13, weight: .semibold
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

    private func sectionLabel(_ value: String) -> some View {
        Text(value)
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
                byAdding: .hour, value: 9, to: day
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
