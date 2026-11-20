//
//  AdaptiveTimeLineLayout.swift
//  daybook.
//
//  Created by Advita Rao on 11/20/26.
//


import Foundation
import CoreGraphics

struct AdaptiveTimelineLayout {

    let points: [CGFloat]

    var totalHeight: CGFloat {
        points.last ?? 0
    }

    init(
        days: [Date],
        tasksByDay: [[CalendarTask]]
    ) {
        let calendar = Calendar.current

        struct Interval {
            let start: Int
            let end: Int
        }

        var intervals: [Interval] = []
        var boundaries: Set<Int> = [0, 1440]

        for (index, day) in days.enumerated() {
            guard index < tasksByDay.count else {
                continue
            }

            let dayStart = calendar.startOfDay(for: day)

            for task in tasksByDay[index] {
                let start = max(
                    0,
                    min(
                        1440,
                        Int(
                            floor(
                                task.start.timeIntervalSince(
                                    dayStart
                                ) / 60
                            )
                        )
                    )
                )

                let end = max(
                    0,
                    min(
                        1440,
                        Int(
                            ceil(
                                task.end.timeIntervalSince(
                                    dayStart
                                ) / 60
                            )
                        )
                    )
                )

                guard end > start else {
                    continue
                }

                intervals.append(
                    Interval(start: start, end: end)
                )

                boundaries.insert(start)
                boundaries.insert(end)
            }
        }

        // Start with the existing compact timeline.
        var heights = Array(
            repeating: CGFloat(0),
            count: 1440
        )

        for minute in 0..<1440 {
            let active = intervals.filter {
                $0.start <= minute && minute < $0.end
            }

            if active.isEmpty {
                heights[minute] = 0.35
            } else {
                let shortestDuration = active.map {
                    $0.end - $0.start
                }.min() ?? 60

                if shortestDuration <= 15 {
                    heights[minute] = 3.5
                } else if shortestDuration <= 30 {
                    heights[minute] = 2.5
                } else if shortestDuration <= 60 {
                    heights[minute] = 1.5
                } else if shortestDuration <= 120 {
                    heights[minute] = 1.0
                } else {
                    heights[minute] = 0.45
                }
            }
        }

        // Ensure every short task has enough room for
        // both its title and its time.
        for interval in intervals {
            let duration = interval.end - interval.start

            guard duration <= 30 else {
                continue
            }

            let minimumHeight: CGFloat =
                duration <= 15 ? 60 : 70

            let existingHeight = (
                interval.start..<interval.end
            ).reduce(CGFloat(0)) {
                $0 + heights[$1]
            }

            if existingHeight < minimumHeight {
                let extraPerMinute = (
                    minimumHeight - existingHeight
                ) / CGFloat(duration)

                for minute in interval.start..<interval.end {
                    heights[minute] += extraPerMinute
                }
            }
        }

        // Build the shared mapping.
        var result = Array(
            repeating: CGFloat(0),
            count: 1441
        )

        var y: CGFloat = 0

        for minute in 0..<1440 {
            y += heights[minute]
            result[minute + 1] = y
        }

        points = result
    }

    func y(forMinute minute: CGFloat) -> CGFloat {
        let clamped = max(
            0,
            min(1440, minute)
        )

        let lower = Int(floor(clamped))
        let upper = min(1440, lower + 1)

        let fraction = clamped - CGFloat(lower)

        return points[lower]
            + (points[upper] - points[lower])
            * fraction
    }

    func y(for date: Date, on day: Date) -> CGFloat {
        let dayStart = Calendar.current.startOfDay(
            for: day
        )

        let minutes = CGFloat(
            date.timeIntervalSince(dayStart) / 60
        )

        return y(forMinute: minutes)
    }
}
