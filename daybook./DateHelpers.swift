//
//  DateHelpers.swift
//  daybook.
//
//  Created by Advita Rao on 11/18/26.
//


import Foundation

extension Date {
    func addingDays(_ amount: Int) -> Date {
        Calendar.current.date(
            byAdding: .day,
            value: amount,
            to: self
        ) ?? self
    }

    func formatted(_ pattern: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = pattern
        return formatter.string(from: self)
    }

    var monday: Date {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: self)
        let weekday = calendar.component(.weekday, from: day)
        return day.addingDays(-((weekday + 5) % 7))
    }

    var monthStart: Date {
        let calendar = Calendar.current
        return calendar.date(
            from: calendar.dateComponents(
                [.year, .month],
                from: self
            )
        ) ?? self
    }
}
