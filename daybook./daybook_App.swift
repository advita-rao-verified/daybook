//
//  daybook_App.swift
//  daybook.
//
//  Created by Advita Rao on 10/27/26.
//

//
//import SwiftUI
//import Combine
//
//// MARK: - APP
//
//@main
//struct DaybookApp: App {
//    var body: some Scene {
//        WindowGroup {
//            DaybookView()
//                .preferredColorScheme(.dark)
//                .frame(minWidth: 900, minHeight: 600)
//        }
//        .defaultSize(width: 1350, height: 850)
//    }
//}
//
//// MARK: - DESIGN
//
//extension Color {
//    init(hex: String) {
//        let number = Int(
//            hex.replacingOccurrences(of: "#", with: ""),
//            radix: 16
//        ) ?? 0
//
//        self.init(
//            .sRGB,
//            red: Double((number >> 16) & 255) / 255,
//            green: Double((number >> 8) & 255) / 255,
//            blue: Double(number & 255) / 255,
//            opacity: 1
//        )
//    }
//}
//
//enum Noir {
//    static let background = Color(hex: "#101013")
//    static let surface = Color(hex: "#19191E")
//    static let field = Color(hex: "#242027")
//    static let grid = Color(hex: "#303036")
//    static let muted = Color(hex: "#A99BA0")
//    static let accent = Color(hex: "#B95760")
//    static let pale = Color(hex: "#F4E9EC")
//}
//
//struct TaskShade: Identifiable {
//    let name: String
//    let hex: String
//
//    var id: String { hex }
//    var color: Color { Color(hex: hex) }
//}
//
//enum TaskPalette {
//    static let colors: [TaskShade] = [
//        .init(name: "Black Cherry", hex: "#471C26"),
//        .init(name: "Dark Wine", hex: "#6E2936"),
//        .init(name: "Burgundy", hex: "#963F4D"),
//        .init(name: "Dusty Rose", hex: "#B95760"),
//        .init(name: "Rosewood", hex: "#D58A8F"),
//        .init(name: "Blush", hex: "#E8B5B4"),
//        .init(name: "Plum", hex: "#4D303C"),
//        .init(name: "Mauve", hex: "#73505D"),
//        .init(name: "Orchid", hex: "#9D7582"),
//        .init(name: "Rose Mauve", hex: "#C39AA5"),
//        .init(name: "Soft Pink", hex: "#E0C2CA"),
//        .init(name: "Petal", hex: "#F0DDE0"),
//        .init(name: "Espresso", hex: "#6C4933"),
//        .init(name: "Caramel", hex: "#946A45"),
//        .init(name: "Muted Gold", hex: "#B68C62"),
//        .init(name: "Champagne", hex: "#D5B38C"),
//        .init(name: "Forest", hex: "#505C46"),
//        .init(name: "Sage", hex: "#718166"),
//        .init(name: "Eucalyptus", hex: "#94A485"),
//        .init(name: "Pistachio", hex: "#B9C5A8"),
//        .init(name: "Taupe", hex: "#625848"),
//        .init(name: "Stone", hex: "#8B806D"),
//        .init(name: "Sand", hex: "#B3A793"),
//        .init(name: "Ivory", hex: "#D6CCBB"),
//        .init(name: "Deep Slate", hex: "#354A54"),
//        .init(name: "Storm Blue", hex: "#4B6876"),
//        .init(name: "Dusty Blue", hex: "#7193A1"),
//        .init(name: "Ice Blue", hex: "#A3BBC3"),
//        .init(name: "Midnight", hex: "#3D4A67"),
//        .init(name: "Steel Blue", hex: "#596A90"),
//        .init(name: "Periwinkle", hex: "#8295BA"),
//        .init(name: "Cloud Blue", hex: "#B7C3DC"),
//        .init(name: "Dark Lavender", hex: "#51465F"),
//        .init(name: "Amethyst", hex: "#76658B"),
//        .init(name: "Lilac", hex: "#A08DB5"),
//        .init(name: "Lavender", hex: "#C8B9D5")
//    ]
//}
//
//// MARK: - DATA
//
//struct Subtask: Identifiable, Codable, Equatable {
//    var id = UUID()
//    var title: String
//    var isDone = false
//}
//
//struct CalendarTask: Identifiable, Codable {
//    var id = UUID()
//    var title: String
//    var start: Date
//    var end: Date
//    var colorHex: String
//    var notes: String = ""
//    var subtasks: [Subtask] = []
//
//    var color: Color { Color(hex: colorHex) }
//
//    var completedCount: Int {
//        subtasks.filter(\.isDone).count
//    }
//
//    var progress: Double {
//        guard !subtasks.isEmpty else { return 0 }
//        return Double(completedCount) / Double(subtasks.count)
//    }
//
//    enum CodingKeys: String, CodingKey {
//        case id, title, start, end, colorHex, notes, subtasks
//    }
//
//    init(
//        id: UUID = UUID(),
//        title: String,
//        start: Date,
//        end: Date,
//        colorHex: String,
//        notes: String = "",
//        subtasks: [Subtask] = []
//    ) {
//        self.id = id
//        self.title = title
//        self.start = start
//        self.end = end
//        self.colorHex = colorHex
//        self.notes = notes
//        self.subtasks = subtasks
//    }
//
//    init(from decoder: Decoder) throws {
//        let c = try decoder.container(keyedBy: CodingKeys.self)
//
//        id = try c.decode(UUID.self, forKey: .id)
//        title = try c.decode(String.self, forKey: .title)
//        start = try c.decode(Date.self, forKey: .start)
//        end = try c.decode(Date.self, forKey: .end)
//        colorHex = try c.decode(String.self, forKey: .colorHex)
//        notes = try c.decodeIfPresent(
//            String.self, forKey: .notes
//        ) ?? ""
//        subtasks = try c.decodeIfPresent(
//            [Subtask].self, forKey: .subtasks
//        ) ?? []
//    }
//}
//
//final class TaskStore: ObservableObject {
//    @Published var tasks: [CalendarTask] = [] {
//        didSet { persist() }
//    }
//
//    private let storageKey = "noir.calendar.tasks.v1"
//
//    init() {
//        if let data = UserDefaults.standard.data(
//            forKey: storageKey
//        ),
//        let decoded = try? JSONDecoder().decode(
//            [CalendarTask].self,
//            from: data
//        ) {
//            tasks = decoded
//        }
//    }
//
//    private func persist() {
//        guard let data = try? JSONEncoder().encode(tasks)
//        else { return }
//
//        UserDefaults.standard.set(data, forKey: storageKey)
//    }
//
//    func save(_ task: CalendarTask) {
//        if let index = tasks.firstIndex(where: {
//            $0.id == task.id
//        }) {
//            tasks[index] = task
//        } else {
//            tasks.append(task)
//        }
//    }
//
//    func delete(_ task: CalendarTask) {
//        tasks.removeAll { $0.id == task.id }
//    }
//
//    func toggle(taskID: UUID, subtaskID: UUID) {
//        guard let taskIndex = tasks.firstIndex(where: {
//            $0.id == taskID
//        }),
//        let subIndex = tasks[taskIndex].subtasks.firstIndex(
//            where: { $0.id == subtaskID }
//        ) else { return }
//
//        tasks[taskIndex].subtasks[subIndex].isDone.toggle()
//    }
//
//    func addSubtask(taskID: UUID, title: String) {
//        let cleaned = title.trimmingCharacters(
//            in: .whitespacesAndNewlines
//        )
//
//        guard !cleaned.isEmpty,
//              let index = tasks.firstIndex(where: {
//                  $0.id == taskID
//              }) else { return }
//
//        tasks[index].subtasks.append(
//            Subtask(title: cleaned)
//        )
//    }
//
//    func removeSubtask(taskID: UUID, subtaskID: UUID) {
//        guard let index = tasks.firstIndex(where: {
//            $0.id == taskID
//        }) else { return }
//
//        tasks[index].subtasks.removeAll {
//            $0.id == subtaskID
//        }
//    }
//
//    func tasks(on date: Date) -> [CalendarTask] {
//        let calendar = Calendar.current
//        let beginning = calendar.startOfDay(for: date)
//        let ending = calendar.date(
//            byAdding: .day,
//            value: 1,
//            to: beginning
//        )!
//
//        return tasks.filter {
//            $0.start < ending && $0.end > beginning
//        }
//        .sorted { $0.start < $1.start }
//    }
//}
//
//// MARK: - DATE HELPERS
//
//extension Date {
//    func addingDays(_ amount: Int) -> Date {
//        Calendar.current.date(
//            byAdding: .day,
//            value: amount,
//            to: self
//        ) ?? self
//    }
//
//    func formatted(_ pattern: String) -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = pattern
//        return formatter.string(from: self)
//    }
//
//    var monday: Date {
//        let calendar = Calendar.current
//        let day = calendar.startOfDay(for: self)
//        let weekday = calendar.component(
//            .weekday,
//            from: day
//        )
//
//        return day.addingDays(-((weekday + 5) % 7))
//    }
//
//    var monthStart: Date {
//        let calendar = Calendar.current
//        return calendar.date(
//            from: calendar.dateComponents(
//                [.year, .month],
//                from: self
//            )
//        ) ?? self
//    }
//}
//
//enum CalendarMode: String, CaseIterable {
//    case day = "Day"
//    case twoDays = "2 Days"
//    case week = "Week"
//    case month = "Month"
//}
//
//struct EditorRequest: Identifiable {
//    let id = UUID()
//    let task: CalendarTask?
//}
//
//// MARK: - MAIN WINDOW
//
//struct DaybookView: View {
//    @StateObject private var store = TaskStore()
//
//    @State private var selectedDate = Date()
//    @State private var mode: CalendarMode = .week
//    @State private var editorRequest: EditorRequest?
//
//    private var visibleDays: [Date] {
//        switch mode {
//        case .day:
//            return [selectedDate]
//
//        case .twoDays:
//            return [
//                selectedDate,
//                selectedDate.addingDays(1)
//            ]
//
//        case .week:
//            return (0..<7).map {
//                selectedDate.monday.addingDays($0)
//            }
//
//        case .month:
//            return []
//        }
//    }
//
//    var body: some View {
//        VStack(spacing: 0) {
//            header
//
//            Rectangle()
//                .fill(Noir.grid)
//                .frame(height: 1)
//
//            if mode == .month {
//                MonthCalendar(
//                    date: selectedDate,
//                    store: store,
//                    selectDay: { day in
//                        selectedDate = day
//                        mode = .day
//                    },
//                    selectTask: openEditor
//                )
//            } else {
//                CalendarTimeline(
//                    days: visibleDays,
//                    store: store,
//                    edit: openEditor
//                )
//            }
//        }
//        .background(Noir.background)
//        .foregroundStyle(Noir.pale)
//        .sheet(item: $editorRequest) { request in
//            TaskEditor(
//                task: request.task,
//                initialDate: selectedDate,
//                save: { updated in
//                    store.save(updated)
//                    editorRequest = nil
//                },
//                delete: { task in
//                    store.delete(task)
//                    editorRequest = nil
//                },
//                cancel: {
//                    editorRequest = nil
//                }
//            )
//        }
//    }
//
//    private var header: some View {
//        VStack(spacing: 17) {
//            HStack(spacing: 16) {
//                Image(systemName: "calendar")
//                    .foregroundStyle(Noir.accent)
//
//                Text("noir.")
//                    .font(.system(
//                        size: 24,
//                        weight: .semibold,
//                        design: .rounded
//                    ))
//
//                Spacer()
//
//                Button("Today") {
//                    selectedDate = Date()
//                }
//                .buttonStyle(.plain)
//                .padding(10)
//                .background(Noir.field)
//                .cornerRadius(9)
//
//                Button {
//                    navigate(-1)
//                } label: {
//                    Image(systemName: "chevron.left")
//                }
//                .buttonStyle(.plain)
//
//                Button {
//                    navigate(1)
//                } label: {
//                    Image(systemName: "chevron.right")
//                }
//                .buttonStyle(.plain)
//
//                Picker("", selection: $mode) {
//                    ForEach(
//                        CalendarMode.allCases,
//                        id: \.self
//                    ) { option in
//                        Text(option.rawValue).tag(option)
//                    }
//                }
//                .pickerStyle(.segmented)
//                .labelsHidden()
//                .frame(width: 295)
//
//                Button {
//                    editorRequest = EditorRequest(task: nil)
//                } label: {
//                    Image(systemName: "plus")
//                        .frame(width: 39, height: 39)
//                        .background(Noir.accent)
//                        .cornerRadius(10)
//                }
//                .buttonStyle(.plain)
//            }
//
//            HStack {
//                Text(selectedDate.formatted("MMMM yyyy"))
//                    .font(.system(
//                        size: 29,
//                        weight: .semibold
//                    ))
//
//                Spacer()
//
//                Text("\(store.tasks.count) tasks")
//                    .font(.system(size: 12))
//                    .foregroundStyle(Noir.muted)
//            }
//        }
//        .padding(22)
//    }
//
//    private func navigate(_ direction: Int) {
//        switch mode {
//        case .day:
//            selectedDate = selectedDate.addingDays(direction)
//
//        case .twoDays:
//            selectedDate = selectedDate.addingDays(
//                direction * 2
//            )
//
//        case .week:
//            selectedDate = selectedDate.addingDays(
//                direction * 7
//            )
//
//        case .month:
//            selectedDate = Calendar.current.date(
//                byAdding: .month,
//                value: direction,
//                to: selectedDate
//            ) ?? selectedDate
//        }
//    }
//
//    private func openEditor(_ task: CalendarTask) {
//        editorRequest = EditorRequest(task: task)
//    }
//}
//
//// MARK: - CALENDAR TIMELINE
//// All grid and task positions use the same top-left origin.
//
//struct CalendarTimeline: View {
//    let days: [Date]
//    @ObservedObject var store: TaskStore
//    let edit: (CalendarTask) -> Void
//
//    private let gutter: CGFloat = 72
//
//    private var hourHeight: CGFloat {
//        days.count <= 2 ? 95 : 85
//    }
//
//    var body: some View {
//        VStack(spacing: 0) {
//            HStack(spacing: 0) {
//                Color.clear.frame(width: gutter)
//
//                ForEach(days, id: \.self) { day in
//                    VStack(spacing: 4) {
//                        Text(day.formatted("EEE").uppercased())
//                            .font(.system(size: 10))
//                            .foregroundStyle(Noir.muted)
//
//                        Text(day.formatted("d"))
//                            .font(.system(
//                                size: 20,
//                                weight: .semibold
//                            ))
//                            .foregroundStyle(
//                                Calendar.current.isDateInToday(day)
//                                ? Noir.accent : Noir.pale
//                            )
//                    }
//                    .frame(maxWidth: .infinity)
//                }
//            }
//            .frame(height: 70)
//
//            Divider()
//
//            ScrollView(.vertical) {
//                GeometryReader { geometry in
//                    let columnWidth = max(
//                        1,
//                        (geometry.size.width - gutter) /
//                        CGFloat(max(1, days.count))
//                    )
//
//                    ZStack(alignment: .topLeading) {
//                        HourGrid(
//                            width: geometry.size.width,
//                            gutter: gutter,
//                            hourHeight: hourHeight,
//                            showNow: days.contains {
//                                Calendar.current.isDateInToday($0)
//                            }
//                        )
//
//                        HStack(
//                            alignment: .top,
//                            spacing: 0
//                        ) {
//                            Color.clear
//                                .frame(width: gutter)
//
//                            ForEach(days, id: \.self) { day in
//                                DayColumn(
//                                    day: day,
//                                    tasks: store.tasks(on: day),
//                                    store: store,
//                                    hourHeight: hourHeight,
//                                    edit: edit
//                                )
//                                .frame(
//                                    width: columnWidth,
//                                    height: 24 * hourHeight,
//                                    alignment: .topLeading
//                                )
//                            }
//                        }
//                        .frame(
//                            width: geometry.size.width,
//                            height: 24 * hourHeight,
//                            alignment: .topLeading
//                        )
//                    }
//                    .frame(
//                        width: geometry.size.width,
//                        height: 24 * hourHeight,
//                        alignment: .topLeading
//                    )
//                }
//                .frame(height: 24 * hourHeight)
//            }
//        }
//    }
//}
//
//// MARK: - HOUR GRID
//
//struct HourGrid: View {
//    let width: CGFloat
//    let gutter: CGFloat
//    let hourHeight: CGFloat
//    let showNow: Bool
//
//    var body: some View {
//        TimelineView(
//            .periodic(from: .now, by: 30)
//        ) { context in
//            ZStack(alignment: .topLeading) {
//                VStack(alignment: .leading, spacing: 0) {
//                    ForEach(0..<24, id: \.self) { hour in
//                        HStack(spacing: 0) {
//                            Text(hourLabel(hour))
//                                .font(.system(size: 10))
//                                .foregroundStyle(Noir.muted)
//                                .frame(
//                                    width: gutter - 10,
//                                    alignment: .trailing
//                                )
//
//                            Color.clear.frame(width: 10)
//
//                            Rectangle()
//                                .fill(Noir.grid)
//                                .frame(height: 1)
//                        }
//                        .frame(width: width)
//                        .frame(
//                            height: hourHeight,
//                            alignment: .top
//                        )
//                    }
//                }
//
//                if showNow {
//                    currentTimeLine(context.date)
//                }
//            }
//            .frame(
//                width: width,
//                height: 24 * hourHeight,
//                alignment: .topLeading
//            )
//        }
//        .allowsHitTesting(false)
//    }
//
//    private func hourLabel(_ hour: Int) -> String {
//        let display = hour % 12 == 0
//            ? 12
//            : hour % 12
//
//        return "\(display) \(hour < 12 ? "AM" : "PM")"
//    }
//
//    private func currentTimeLine(_ now: Date) -> some View {
//        let calendar = Calendar.current
//
//        let hour = calendar.component(
//            .hour, from: now
//        )
//        let minute = calendar.component(
//            .minute, from: now
//        )
//
//        let y = (
//            CGFloat(hour) +
//            CGFloat(minute) / 60
//        ) * hourHeight
//
//        return HStack(spacing: 0) {
//            Text(now.formatted("h:mm"))
//                .font(.system(size: 10))
//                .foregroundStyle(Noir.accent)
//                .frame(
//                    width: gutter - 5,
//                    alignment: .trailing
//                )
//
//            Circle()
//                .fill(Noir.accent)
//                .frame(width: 7, height: 7)
//
//            Rectangle()
//                .fill(Noir.accent)
//                .frame(height: 1.5)
//        }
//        .frame(width: width, height: 12)
//        .offset(y: y - 6)
//    }
//}
//
//// MARK: - DAY COLUMN
//
//struct DayColumn: View {
//    let day: Date
//    let tasks: [CalendarTask]
//    @ObservedObject var store: TaskStore
//    let hourHeight: CGFloat
//    let edit: (CalendarTask) -> Void
//
//    var body: some View {
//        GeometryReader { geometry in
//            ZStack(alignment: .topLeading) {
//                Rectangle()
//                    .fill(Noir.grid)
//                    .frame(width: 1)
//                    .frame(
//                        height: 24 * hourHeight,
//                        alignment: .top
//                    )
//
//                ForEach(tasks) { task in
//                    PositionedTask(
//                        task: task,
//                        day: day,
//                        allTasks: tasks,
//                        width: geometry.size.width,
//                        hourHeight: hourHeight,
//                        store: store,
//                        edit: edit
//                    )
//                }
//            }
//            .frame(
//                width: geometry.size.width,
//                height: 24 * hourHeight,
//                alignment: .topLeading
//            )
//        }
//    }
//}
//
//// MARK: - POSITIONED TASK
//// Explicit coordinates fix the floating task bug.
//
//struct PositionedTask: View {
//    let task: CalendarTask
//    let day: Date
//    let allTasks: [CalendarTask]
//    let width: CGFloat
//    let hourHeight: CGFloat
//    @ObservedObject var store: TaskStore
//    let edit: (CalendarTask) -> Void
//
//    @State private var expanded = false
//    @State private var editAfterDismiss = false
//
//    private var dayStart: Date {
//        Calendar.current.startOfDay(for: day)
//    }
//
//    private var dayEnd: Date {
//        dayStart.addingDays(1)
//    }
//
//    private var startY: CGFloat {
//        let visibleStart = max(task.start, dayStart)
//
//        return CGFloat(
//            visibleStart.timeIntervalSince(dayStart) / 3600
//        ) * hourHeight
//    }
//
//    private var taskHeight: CGFloat {
//        let visibleStart = max(task.start, dayStart)
//        let visibleEnd = min(task.end, dayEnd)
//
//        return max(
//            2,
//            CGFloat(
//                max(
//                    0,
//                    visibleEnd.timeIntervalSince(visibleStart)
//                ) / 3600
//            ) * hourHeight - 4
//        )
//    }
//
//    private var overlaps: [CalendarTask] {
//        allTasks.filter {
//            $0.start < task.end &&
//            $0.end > task.start
//        }
//        .sorted {
//            if $0.start == $1.start {
//                return $0.id.uuidString < $1.id.uuidString
//            }
//            return $0.start < $1.start
//        }
//    }
//
//    private var slotWidth: CGFloat {
//        max(
//            1,
//            (width - 8) /
//            CGFloat(max(1, overlaps.count))
//        )
//    }
//
//    private var slotIndex: Int {
//        overlaps.firstIndex {
//            $0.id == task.id
//        } ?? 0
//    }
//
//    private var cardWidth: CGFloat {
//        max(1, slotWidth - 3)
//    }
//
//    private var cardX: CGFloat {
//        4 + CGFloat(slotIndex) * slotWidth
//    }
//
//    var body: some View {
//        TaskCalendarCard(task: task)
//            .frame(
//                width: cardWidth,
//                height: taskHeight,
//                alignment: .topLeading
//            )
//            .contentShape(Rectangle())
//            .onTapGesture {
//                expanded = true
//            }
//            .popover(isPresented: $expanded) {
//                ExpandedTaskPanel(
//                    taskID: task.id,
//                    store: store,
//                    edit: {
//                        editAfterDismiss = true
//                        expanded = false
//                    }
//                )
//            }
//            .onChange(of: expanded) { _, isExpanded in
//                if !isExpanded && editAfterDismiss {
//                    editAfterDismiss = false
//
//                    DispatchQueue.main.asyncAfter(
//                        deadline: .now() + 0.3
//                    ) {
//                        edit(task)
//                    }
//                }
//            }
//            .contextMenu {
//                Button("Edit Task") {
//                    edit(task)
//                }
//            }
//            .position(
//                x: cardX + cardWidth / 2,
//                y: startY + taskHeight / 2 + 2
//            )
//    }
//}
//
//// MARK: - TASK CARD
//
//struct TaskCalendarCard: View {
//    let task: CalendarTask
//
//    var body: some View {
//        GeometryReader { geometry in
//            let compact = geometry.size.width < 180
//            let short = geometry.size.height < 65
//
//            HStack(alignment: .top, spacing: 0) {
//                Rectangle()
//                    .fill(task.color)
//                    .frame(width: 5)
//
//                VStack(
//                    alignment: .leading,
//                    spacing: 6
//                ) {
//                    Text(task.title)
//                        .font(.system(
//                            size: compact ? 12 : 16,
//                            weight: .semibold
//                        ))
//                        .lineLimit(
//                            geometry.size.height > 110 ? 3 : 1
//                        )
//                        .frame(
//                            maxWidth: .infinity,
//                            alignment: .leading
//                        )
//
//                    if !short {
//                        Text(
//                            "\(task.start.formatted("HH:mm")) – " +
//                            task.end.formatted("HH:mm")
//                        )
//                        .font(.system(
//                            size: compact ? 10 : 12
//                        ))
//                        .foregroundStyle(
//                            Noir.pale.opacity(0.75)
//                        )
//                    }
//
//                    if !task.subtasks.isEmpty &&
//                        geometry.size.height > 130 {
//
//                        ProgressView(value: task.progress)
//                            .tint(task.color)
//                            .padding(.top, 5)
//
//                        ForEach(
//                            task.subtasks.prefix(
//                                geometry.size.height > 280
//                                ? 8 : 2
//                            )
//                        ) { subtask in
//                            HStack(spacing: 6) {
//                                Image(
//                                    systemName: subtask.isDone
//                                    ? "checkmark.square"
//                                    : "square"
//                                )
//
//                                Text(subtask.title)
//                                    .lineLimit(1)
//                                    .strikethrough(
//                                        subtask.isDone
//                                    )
//                            }
//                            .font(.system(
//                                size: compact ? 10 : 12
//                            ))
//                            .foregroundStyle(
//                                subtask.isDone
//                                ? Noir.muted : Noir.pale
//                            )
//                        }
//                    }
//
//                    Spacer(minLength: 0)
//                }
//                .padding(compact ? 8 : 12)
//                .frame(
//                    maxWidth: .infinity,
//                    maxHeight: .infinity,
//                    alignment: .topLeading
//                )
//            }
//            .frame(
//                width: geometry.size.width,
//                height: geometry.size.height,
//                alignment: .topLeading
//            )
//            .background(task.color.opacity(0.22))
//            .clipShape(
//                RoundedRectangle(cornerRadius: 8)
//            )
//            .overlay {
//                RoundedRectangle(cornerRadius: 8)
//                    .stroke(task.color.opacity(0.25))
//            }
//        }
//    }
//}
//
//// MARK: - TASK POPOVER
//
//struct ExpandedTaskPanel: View {
//    let taskID: UUID
//    @ObservedObject var store: TaskStore
//    let edit: () -> Void
//
//    @State private var newSubtask = ""
//
//    private var task: CalendarTask? {
//        store.tasks.first {
//            $0.id == taskID
//        }
//    }
//
//    var body: some View {
//        VStack(
//            alignment: .leading,
//            spacing: 18
//        ) {
//            if let task {
//                HStack(alignment: .top) {
//                    VStack(
//                        alignment: .leading,
//                        spacing: 6
//                    ) {
//                        Text(task.title)
//                            .font(.system(
//                                size: 22,
//                                weight: .semibold
//                            ))
//                            .lineLimit(nil)
//                            .fixedSize(horizontal: false, vertical: true)
//                            .frame(maxWidth: .infinity, alignment: .leading)
//
//                        Text(
//                            "\(task.start.formatted("h:mm a")) – " +
//                            task.end.formatted("h:mm a")
//                        )
//                        .foregroundStyle(Noir.muted)
//                    }
//
//                    Spacer()
//
//                    Button(action: edit) {
//                        Image(systemName: "pencil")
//                            .font(.system(size: 17))
//                    }
//                    .buttonStyle(.plain)
//                    .help("Edit task")
//                }
//
//                if !task.subtasks.isEmpty {
//                    ProgressView(value: task.progress)
//                        .tint(task.color)
//
//                    Text(
//                        "\(task.completedCount) of " +
//                        "\(task.subtasks.count) completed"
//                    )
//                    .font(.system(size: 11))
//                    .foregroundStyle(Noir.muted)
//                }
//
//                ScrollView {
//                    VStack(
//                        alignment: .leading,
//                        spacing: 13
//                    ) {
//                        ForEach(task.subtasks) { subtask in
//                            HStack(spacing: 10) {
//                                Button {
//                                    store.toggle(
//                                        taskID: taskID,
//                                        subtaskID: subtask.id
//                                    )
//                                } label: {
//                                    Image(
//                                        systemName: subtask.isDone
//                                        ? "checkmark.square"
//                                        : "square"
//                                    )
//                                    .foregroundStyle(task.color)
//                                }
//                                .buttonStyle(.plain)
//
//                                Text(subtask.title)
//                                    .strikethrough(
//                                        subtask.isDone
//                                    )
//
//                                Spacer()
//
//                                Button {
//                                    store.removeSubtask(
//                                        taskID: taskID,
//                                        subtaskID: subtask.id
//                                    )
//                                } label: {
//                                    Image(systemName: "xmark")
//                                        .foregroundStyle(Noir.muted)
//                                }
//                                .buttonStyle(.plain)
//                            }
//                        }
//                    }
//                }
//                .frame(maxHeight: 280)
//
//                HStack {
//                    TextField(
//                        "Add a subtask...",
//                        text: $newSubtask
//                    )
//                    .textFieldStyle(.plain)
//                    .padding(10)
//                    .background(Noir.field)
//                    .cornerRadius(8)
//                    .onSubmit(addSubtask)
//
//                    Button(action: addSubtask) {
//                        Image(systemName: "plus")
//                    }
//                    .buttonStyle(.plain)
//                }
//            }
//        }
//        .padding(24)
//        .frame(width: 450)
//        .background(Color(hex: "#29191F"))
//        .foregroundStyle(Noir.pale)
//    }
//
//    private func addSubtask() {
//        store.addSubtask(
//            taskID: taskID,
//            title: newSubtask
//        )
//        newSubtask = ""
//    }
//}
//
//// MARK: - MONTH VIEW
//
//struct MonthCalendar: View {
//    let date: Date
//    @ObservedObject var store: TaskStore
//    let selectDay: (Date) -> Void
//    let selectTask: (CalendarTask) -> Void
//
//    private var dates: [Date] {
//        let first = date.monthStart
//
//        let weekday = Calendar.current.component(
//            .weekday,
//            from: first
//        )
//
//        let offset = (weekday + 5) % 7
//        let beginning = first.addingDays(-offset)
//
//        return (0..<42).map {
//            beginning.addingDays($0)
//        }
//    }
//
//    var body: some View {
//        VStack(spacing: 0) {
//            HStack {
//                ForEach(
//                    [
//                        "MON", "TUE", "WED", "THU",
//                        "FRI", "SAT", "SUN"
//                    ],
//                    id: \.self
//                ) { weekday in
//                    Text(weekday)
//                        .font(.system(size: 10))
//                        .foregroundStyle(Noir.muted)
//                        .frame(maxWidth: .infinity)
//                }
//            }
//            .padding(.vertical, 12)
//
//            GeometryReader { geometry in
//                let cellHeight = max(
//                    1,
//                    geometry.size.height / 6
//                )
//
//                VStack(spacing: 1) {
//                    ForEach(0..<6, id: \.self) { row in
//                        HStack(spacing: 1) {
//                            ForEach(0..<7, id: \.self) { col in
//                                let day = dates[row * 7 + col]
//
//                                MonthCell(
//                                    day: day,
//                                    tasks: store.tasks(on: day),
//                                    selectDay: selectDay,
//                                    selectTask: selectTask
//                                )
//                                .frame(
//                                    maxWidth: .infinity,
//                                    minHeight: cellHeight,
//                                    maxHeight: cellHeight
//                                )
//                            }
//                        }
//                    }
//                }
//            }
//        }
//        .padding(12)
//    }
//}
//
//struct MonthCell: View {
//    let day: Date
//    let tasks: [CalendarTask]
//    let selectDay: (Date) -> Void
//    let selectTask: (CalendarTask) -> Void
//
//    var body: some View {
//        VStack(
//            alignment: .leading,
//            spacing: 5
//        ) {
//            Button {
//                selectDay(day)
//            } label: {
//                Text(day.formatted("d"))
//                    .font(.system(
//                        size: 13,
//                        weight: .semibold
//                    ))
//                    .foregroundStyle(
//                        Calendar.current.isDateInToday(day)
//                        ? Noir.accent : Noir.pale
//                    )
//            }
//            .buttonStyle(.plain)
//
//            ForEach(tasks.prefix(3)) { task in
//                Button {
//                    selectTask(task)
//                } label: {
//                    HStack(spacing: 5) {
//                        Circle()
//                            .fill(task.color)
//                            .frame(width: 5, height: 5)
//
//                        Text(task.title)
//                            .font(.system(size: 10))
//                            .lineLimit(1)
//
//                        Spacer(minLength: 0)
//                    }
//                    .padding(5)
//                    .background(task.color.opacity(0.2))
//                    .cornerRadius(5)
//                }
//                .buttonStyle(.plain)
//            }
//
//            Spacer(minLength: 0)
//        }
//        .padding(8)
//        .frame(
//            maxWidth: .infinity,
//            maxHeight: .infinity,
//            alignment: .topLeading
//        )
//        .background(Noir.surface)
//    }
//}
//
//// MARK: - TASK EDITOR
//
//struct TaskEditor: View {
//    let task: CalendarTask?
//    let initialDate: Date
//    let save: (CalendarTask) -> Void
//    let delete: (CalendarTask) -> Void
//    let cancel: () -> Void
//
//    @State private var title = ""
//    @State private var start = Date()
//    @State private var end = Date()
//    @State private var colorHex = "#963F4D"
//    @State private var notes = ""
//    @State private var subtasks: [Subtask] = []
//    @State private var newSubtask = ""
//    @State private var confirmDelete = false
//
//    private let columns = Array(
//        repeating: GridItem(
//            .flexible(),
//            spacing: 10
//        ),
//        count: 6
//    )
//
//    private var valid: Bool {
//        !title.trimmingCharacters(
//            in: .whitespacesAndNewlines
//        ).isEmpty && end > start
//    }
//
//    var body: some View {
//        VStack(spacing: 0) {
//            ScrollView(.vertical) {
//                VStack(
//                    alignment: .leading,
//                    spacing: 20
//                ) {
//                    editorHeader
//                    nameField
//                    dateFields
//                    colorPicker
//                    subtasksEditor
//                    notesField
//                }
//                .padding(25)
//            }
//
//            Divider()
//
//            editorFooter
//                .padding(20)
//        }
//        .frame(width: 530, height: 690)
//        .background(Noir.surface)
//        .foregroundStyle(Noir.pale)
//        .preferredColorScheme(.dark)
//        .onAppear(perform: loadTask)
//        .confirmationDialog(
//            "Delete this task?",
//            isPresented: $confirmDelete,
//            titleVisibility: .visible
//        ) {
//            if let task {
//                Button(
//                    "Delete Task",
//                    role: .destructive
//                ) {
//                    delete(task)
//                }
//            }
//
//            Button(
//                "Cancel",
//                role: .cancel
//            ) {}
//        } message: {
//            Text(
//                "This will permanently delete the task " +
//                "and all of its subtasks."
//            )
//        }
//    }
//
//    private var editorHeader: some View {
//        HStack {
//            VStack(
//                alignment: .leading,
//                spacing: 5
//            ) {
//                Text(
//                    task == nil
//                    ? "New Task"
//                    : "Edit Task"
//                )
//                .font(.system(
//                    size: 25,
//                    weight: .semibold
//                ))
//
//                Text("Make time for what matters.")
//                    .font(.system(size: 12))
//                    .foregroundStyle(Noir.muted)
//            }
//
//            Spacer()
//
//            Button(action: cancel) {
//                Image(systemName: "xmark")
//            }
//            .buttonStyle(.plain)
//        }
//    }
//
//    private var nameField: some View {
//        VStack(
//            alignment: .leading,
//            spacing: 8
//        ) {
//            sectionLabel("TASK NAME")
//
//            TextField(
//                "What are you planning?",
//                text: $title
//            )
//            .textFieldStyle(.plain)
//            .padding(13)
//            .background(Noir.field)
//            .cornerRadius(9)
//        }
//    }
//
//    private var dateFields: some View {
//        HStack {
//            VStack(
//                alignment: .leading,
//                spacing: 8
//            ) {
//                sectionLabel("START")
//
//                DatePicker(
//                    "",
//                    selection: $start,
//                    displayedComponents: [
//                        .date, .hourAndMinute
//                    ]
//                )
//                .labelsHidden()
//            }
//
//            Spacer()
//
//            VStack(
//                alignment: .leading,
//                spacing: 8
//            ) {
//                sectionLabel("END")
//
//                DatePicker(
//                    "",
//                    selection: $end,
//                    displayedComponents: [
//                        .date, .hourAndMinute
//                    ]
//                )
//                .labelsHidden()
//            }
//        }
//    }
//
//    private var colorPicker: some View {
//        VStack(
//            alignment: .leading,
//            spacing: 12
//        ) {
//            HStack {
//                sectionLabel("TASK COLOR")
//
//                Spacer()
//
//                Text(
//                    TaskPalette.colors.first {
//                        $0.hex == colorHex
//                    }?.name ?? "Custom"
//                )
//                .font(.system(size: 12))
//                .foregroundStyle(Noir.muted)
//            }
//
//            LazyVGrid(
//                columns: columns,
//                spacing: 12
//            ) {
//                ForEach(TaskPalette.colors) { shade in
//                    Button {
//                        colorHex = shade.hex
//                    } label: {
//                        RoundedRectangle(
//                            cornerRadius: 8
//                        )
//                        .fill(shade.color)
//                        .frame(height: 43)
//                        .overlay {
//                            if colorHex == shade.hex {
//                                Image(
//                                    systemName: "checkmark"
//                                )
//                                .foregroundStyle(.white)
//                            }
//                        }
//                        .overlay {
//                            RoundedRectangle(
//                                cornerRadius: 8
//                            )
//                            .stroke(
//                                colorHex == shade.hex
//                                ? .white : .clear,
//                                lineWidth: 2
//                            )
//                        }
//                    }
//                    .buttonStyle(.plain)
//                    .help(shade.name)
//                }
//            }
//        }
//    }
//
//    private var subtasksEditor: some View {
//        VStack(
//            alignment: .leading,
//            spacing: 12
//        ) {
//            sectionLabel("SUBTASKS")
//
//            ForEach(subtasks) { subtask in
//                HStack(spacing: 10) {
//                    Button {
//                        if let index = subtasks.firstIndex(
//                            where: { $0.id == subtask.id }
//                        ) {
//                            subtasks[index].isDone.toggle()
//                        }
//                    } label: {
//                        Image(
//                            systemName: subtask.isDone
//                            ? "checkmark.square"
//                            : "square"
//                        )
//                        .foregroundStyle(Noir.accent)
//                    }
//                    .buttonStyle(.plain)
//
//                    Text(subtask.title)
//                        .strikethrough(subtask.isDone)
//
//                    Spacer()
//
//                    Button {
//                        subtasks.removeAll {
//                            $0.id == subtask.id
//                        }
//                    } label: {
//                        Image(systemName: "xmark")
//                            .foregroundStyle(Noir.muted)
//                    }
//                    .buttonStyle(.plain)
//                }
//            }
//
//            HStack {
//                TextField(
//                    "Add a subtask...",
//                    text: $newSubtask
//                )
//                .textFieldStyle(.plain)
//                .padding(11)
//                .background(Noir.field)
//                .cornerRadius(8)
//                .onSubmit(addSubtask)
//
//                Button(action: addSubtask) {
//                    Image(systemName: "plus")
//                }
//                .buttonStyle(.plain)
//            }
//        }
//    }
//
//    private var notesField: some View {
//        VStack(
//            alignment: .leading,
//            spacing: 8
//        ) {
//            sectionLabel("NOTES")
//
//            TextEditor(text: $notes)
//                .scrollContentBackground(.hidden)
//                .padding(8)
//                .frame(height: 80)
//                .background(Noir.field)
//                .cornerRadius(9)
//        }
//    }
//
//    private var editorFooter: some View {
//        HStack(spacing: 16) {
//            if task != nil {
//                Button(role: .destructive) {
//                    confirmDelete = true
//                } label: {
//                    Label(
//                        "Delete Task",
//                        systemImage: "trash"
//                    )
//                }
//                .buttonStyle(.plain)
//                .foregroundStyle(Noir.accent)
//            }
//
//            Spacer()
//
//            Button("Cancel", action: cancel)
//                .buttonStyle(.plain)
//
//            Button(action: saveTask) {
//                Text("Save Task")
//                    .font(.system(
//                        size: 13,
//                        weight: .semibold
//                    ))
//                    .padding(.horizontal, 18)
//                    .padding(.vertical, 11)
//                    .background(
//                        valid
//                        ? Noir.accent
//                        : Noir.field
//                    )
//                    .cornerRadius(9)
//            }
//            .buttonStyle(.plain)
//            .disabled(!valid)
//        }
//    }
//
//    private func sectionLabel(
//        _ text: String
//    ) -> some View {
//        Text(text)
//            .font(.system(
//                size: 10,
//                weight: .semibold
//            ))
//            .tracking(1.3)
//            .foregroundStyle(Noir.muted)
//    }
//
//    private func loadTask() {
//        if let task {
//            title = task.title
//            start = task.start
//            end = task.end
//            colorHex = task.colorHex
//            notes = task.notes
//            subtasks = task.subtasks
//        } else {
//            let beginning = Calendar.current.startOfDay(
//                for: initialDate
//            )
//
//            start = Calendar.current.date(
//                byAdding: .hour,
//                value: 9,
//                to: beginning
//            ) ?? initialDate
//
//            end = start.addingTimeInterval(3600)
//        }
//    }
//
//    private func addSubtask() {
//        let cleaned = newSubtask.trimmingCharacters(
//            in: .whitespacesAndNewlines
//        )
//
//        guard !cleaned.isEmpty else { return }
//
//        subtasks.append(
//            Subtask(title: cleaned)
//        )
//        newSubtask = ""
//    }
//
//    private func saveTask() {
//        guard valid else { return }
//
//        save(
//            CalendarTask(
//                id: task?.id ?? UUID(),
//                title: title.trimmingCharacters(
//                    in: .whitespacesAndNewlines
//                ),
//                start: start,
//                end: end,
//                colorHex: colorHex,
//                notes: notes,
//                subtasks: subtasks
//            )
//        )
//    }
//}
