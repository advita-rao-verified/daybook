//
//  CalendarTask.swift
//  daybook.
//
//  Created by Advita Rao on 11/18/26.
//



import SwiftUI

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
    var notes: String = ""
    var subtasks: [Subtask] = []

    // MARK: - Weekly Recurrence

    // Sunday = 1, Monday = 2, ... Saturday = 7
    var repeatsWeekly: Bool = false
    var repeatDays: Set<Int> = []

    // Date represented by this calendar occurrence.
    // Nil for the original saved recurring series.
    var occurrenceDate: Date? = nil

    // Tracks completed subtasks independently for each date.
    var completedOccurrences: [String: Set<UUID>] = [:]

    // Dates removed from the repeating series.
    // Format: yyyy-MM-dd
    var excludedDates: Set<String> = []

    // MARK: - Display Properties

    var color: Color {
        Color(hex: colorHex)
    }

    var completedCount: Int {
        subtasks.filter(\.isDone).count
    }

    var progress: Double {
        guard !subtasks.isEmpty else { return 0 }

        return Double(completedCount) /
            Double(subtasks.count)
    }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case start
        case end
        case colorHex
        case notes
        case subtasks
        case repeatsWeekly
        case repeatDays
        case occurrenceDate
        case completedOccurrences
        case excludedDates
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        title: String,
        start: Date,
        end: Date,
        colorHex: String,
        notes: String = "",
        subtasks: [Subtask] = [],
        repeatsWeekly: Bool = false,
        repeatDays: Set<Int> = [],
        occurrenceDate: Date? = nil,
        completedOccurrences: [String: Set<UUID>] = [:],
        excludedDates: Set<String> = []
    ) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.colorHex = colorHex
        self.notes = notes
        self.subtasks = subtasks

        self.repeatsWeekly = repeatsWeekly
        self.repeatDays = repeatDays
        self.occurrenceDate = occurrenceDate

        self.completedOccurrences = completedOccurrences
        self.excludedDates = excludedDates
    }

    // MARK: - Decoder

    init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        id = try container.decode(
            UUID.self,
            forKey: .id
        )

        title = try container.decode(
            String.self,
            forKey: .title
        )

        start = try container.decode(
            Date.self,
            forKey: .start
        )

        end = try container.decode(
            Date.self,
            forKey: .end
        )

        colorHex = try container.decode(
            String.self,
            forKey: .colorHex
        )

        notes = try container.decodeIfPresent(
            String.self,
            forKey: .notes
        ) ?? ""

        subtasks = try container.decodeIfPresent(
            [Subtask].self,
            forKey: .subtasks
        ) ?? []

        // Older saved tasks won't contain recurrence data.
        repeatsWeekly = try container.decodeIfPresent(
            Bool.self,
            forKey: .repeatsWeekly
        ) ?? false

        repeatDays = try container.decodeIfPresent(
            Set<Int>.self,
            forKey: .repeatDays
        ) ?? []

        occurrenceDate = try container.decodeIfPresent(
            Date.self,
            forKey: .occurrenceDate
        )

        completedOccurrences = try container.decodeIfPresent(
            [String: Set<UUID>].self,
            forKey: .completedOccurrences
        ) ?? [:]

        excludedDates = try container.decodeIfPresent(
            Set<String>.self,
            forKey: .excludedDates
        ) ?? []
    }
}

