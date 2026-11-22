//
//  TaskStore.swift
//  daybook.
//
//  Created by Advita Rao on 11/18/26.
//



import SwiftUI
import Combine

final class TaskStore: ObservableObject {
    @Published var tasks: [CalendarTask] = [] {
        didSet { persist() }
    }

    private let storageKey = "noir.calendar.tasks.v1"
    private let calendar = Calendar.current

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(
                [CalendarTask].self,
                from: data
           ) {
            tasks = decoded
        }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(tasks)
        else { return }

        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func dateKey(_ date: Date) -> String {
        let components = calendar.dateComponents(
            [.year, .month, .day],
            from: date
        )

        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    // MARK: - Save

    func save(_ task: CalendarTask) {
        var updated = task
        updated.occurrenceDate = nil

        if let index = tasks.firstIndex(where: {
            $0.id == updated.id
        }) {
            tasks[index] = updated
        } else {
            tasks.append(updated)
        }
    }

    // MARK: - Delete Entire Series

    func delete(_ task: CalendarTask) {
        tasks.removeAll { $0.id == task.id }
    }

    // MARK: - Delete One Occurrence

    func deleteOccurrence(_ task: CalendarTask) {
        guard task.repeatsWeekly,
              let occurrenceDate = task.occurrenceDate,
              let index = tasks.firstIndex(where: {
                  $0.id == task.id
              })
        else {
            // Nonrecurring tasks are deleted normally.
            if !task.repeatsWeekly {
                delete(task)
            }
            return
        }

        var updated = tasks[index]
        updated.excludedDates.insert(
            dateKey(occurrenceDate)
        )

        tasks[index] = updated
    }

    // MARK: - Tasks for Calendar Date

    func tasks(on date: Date) -> [CalendarTask] {
        let beginning = calendar.startOfDay(for: date)

        guard let ending = calendar.date(
            byAdding: .day,
            value: 1,
            to: beginning
        ) else { return [] }

        var result: [CalendarTask] = []

        for task in tasks {
            // Normal one-time task
            if !task.repeatsWeekly {
                if task.start < ending && task.end > beginning {
                    result.append(task)
                }
                continue
            }

            guard !task.repeatDays.isEmpty else {
                continue
            }

            // Never repeat before the original start date.
            guard beginning >= calendar.startOfDay(
                for: task.start
            ) else {
                continue
            }

            let weekday = calendar.component(
                .weekday,
                from: beginning
            )

            guard task.repeatDays.contains(weekday) else {
                continue
            }

            // Skip individual deleted occurrences.
            guard !task.excludedDates.contains(
                dateKey(beginning)
            ) else {
                continue
            }

            var occurrence = task

            let startComponents = calendar.dateComponents(
                [.hour, .minute, .second],
                from: task.start
            )

            guard let occurrenceStart = calendar.date(
                bySettingHour: startComponents.hour ?? 0,
                minute: startComponents.minute ?? 0,
                second: startComponents.second ?? 0,
                of: beginning
            ) else {
                continue
            }

            let duration = task.end.timeIntervalSince(
                task.start
            )

            occurrence.start = occurrenceStart
            occurrence.end = occurrenceStart.addingTimeInterval(
                duration
            )
            occurrence.occurrenceDate = beginning

            let completed = task.completedOccurrences[
                dateKey(beginning)
            ] ?? []

            occurrence.subtasks = task.subtasks.map { subtask in
                var copy = subtask
                copy.isDone = completed.contains(subtask.id)
                return copy
            }

            result.append(occurrence)
        }

        return result.sorted {
            $0.start < $1.start
        }
    }

    // MARK: - Subtask Completion

    func toggle(
        taskID: UUID,
        subtaskID: UUID,
        occurrenceDate: Date? = nil
    ) {
        guard let index = tasks.firstIndex(where: {
            $0.id == taskID
        }) else {
            return
        }

        var task = tasks[index]

        if task.repeatsWeekly {
            guard let occurrenceDate else {
                return
            }

            let key = dateKey(occurrenceDate)
            var completed = task.completedOccurrences[key] ?? []

            if completed.contains(subtaskID) {
                completed.remove(subtaskID)
            } else {
                completed.insert(subtaskID)
            }

            task.completedOccurrences[key] = completed
        } else {
            guard let subIndex = task.subtasks.firstIndex(
                where: { $0.id == subtaskID }
            ) else {
                return
            }

            task.subtasks[subIndex].isDone.toggle()
        }

        tasks[index] = task
    }

    // MARK: - Add Subtask

    func addSubtask(taskID: UUID, title: String) {
        let cleaned = title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleaned.isEmpty,
              let index = tasks.firstIndex(where: {
                  $0.id == taskID
              })
        else {
            return
        }

        var updated = tasks[index]
        updated.subtasks.append(
            Subtask(title: cleaned)
        )

        tasks[index] = updated
    }

    // MARK: - Remove Subtask

    func removeSubtask(taskID: UUID, subtaskID: UUID) {
        guard let index = tasks.firstIndex(where: {
            $0.id == taskID
        }) else {
            return
        }

        var updated = tasks[index]

        updated.subtasks.removeAll {
            $0.id == subtaskID
        }

        for key in updated.completedOccurrences.keys {
            updated.completedOccurrences[key]?.remove(
                subtaskID
            )
        }

        tasks[index] = updated
    }
    
    // MARK: - Parent Calendar Tasks

    func children(of parent: CalendarTask) -> [CalendarTask] {
        tasks
            .filter { $0.parentTaskID == parent.id }
            .sorted { $0.start < $1.start }
    }

    func assignToParent(
        childID: UUID,
        parentID: UUID
    ) {
        guard childID != parentID,
              let parent = tasks.first(where: {
                  $0.id == parentID && $0.isParentTask
              }),
              let childIndex = tasks.firstIndex(where: {
                  $0.id == childID
              })
        else {
            return
        }

        guard !parent.repeatsWeekly,
              !tasks[childIndex].repeatsWeekly,
              !tasks[childIndex].isParentTask,
              tasks[childIndex].start >= parent.start,
              tasks[childIndex].end <= parent.end
        else {
            return
        }

        tasks[childIndex].parentTaskID = parentID
    }

    func removeFromParent(childID: UUID) {
        guard let index = tasks.firstIndex(where: {
            $0.id == childID
        }) else {
            return
        }

        tasks[index].parentTaskID = nil
    }

    func deleteParent(_ parent: CalendarTask) {
        for index in tasks.indices {
            if tasks[index].parentTaskID == parent.id {
                tasks[index].parentTaskID = nil
            }
        }

        tasks.removeAll { $0.id == parent.id }
    }

}
