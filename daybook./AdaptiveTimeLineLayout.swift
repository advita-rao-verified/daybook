//
//  AdaptiveTimeLineLayout.swift
//  daybook.
//
//  Created by Advita Rao on 11/20/26.
//


import Foundation
import CoreGraphics

struct AdaptiveTimelineLayout {

    // A single shared scale for all visible days.
    let points: [CGFloat]

    // Each point represents one minute after midnight.
    // There are 1,441 entries: 0...1440.
    var totalHeight: CGFloat {
        points.last ?? 0
    }

    init(
        days: [Date],
        tasksByDay: [[CalendarTask]]
    ) {
        let calendar = Calendar.current

        // Count how many task boundaries fall in each
        // 15-minute segment across all visible days.
        var activity = Array(
            repeating: 0,
            count: 96
        )

        var occupied = Array(
            repeating: false,
            count: 96
        )

        for (index, day) in days.enumerated() {
            guard index < tasksByDay.count else {
                continue
            }

            let dayStart = calendar.startOfDay(for: day)

            for task in tasksByDay[index] {
                let startMinute = max(
                    0,
                    min(
                        1440,
                        Int(
                            task.start.timeIntervalSince(
                                dayStart
                            ) / 60
                        )
                    )
                )

                let endMinute = max(
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

                guard endMinute > startMinute else {
                    continue
                }

                // Mark all occupied segments.
                let first = startMinute / 15
                let last = min(
                    95,
                    (endMinute - 1) / 15
                )

                for segment in first...last {
                    occupied[segment] = true
                }

                // Give additional space near task starts
                // and ends, where labels tend to cluster.
                let startSegment = min(
                    95,
                    startMinute / 15
                )

                let endSegment = min(
                    95,
                    max(0, endMinute - 1) / 15
                )

                activity[startSegment] += 1
                activity[endSegment] += 1
            }
        }

        var segmentHeights = Array(
            repeating: CGFloat(0),
            count: 96
        )

        for segment in 0..<96 {
            let nearbyActivity = (
                activity[max(0, segment - 1)]
                + activity[segment]
                + activity[min(95, segment + 1)]
            )

            if nearbyActivity >= 4 {
                // Very busy period
                segmentHeights[segment] = 42
            } else if nearbyActivity >= 2 {
                // Several nearby tasks
                segmentHeights[segment] = 31
            } else if nearbyActivity >= 1 {
                // Task begins or ends nearby
                segmentHeights[segment] = 23
            } else if occupied[segment] {
                // Middle of a long task
                segmentHeights[segment] = 9
            } else {
                // Empty time
                segmentHeights[segment] = 5
            }
        }

        // Build a continuous time-to-position lookup.
        var result = Array(
            repeating: CGFloat(0),
            count: 1441
        )

        var y: CGFloat = 0

        for minute in 0..<1440 {
            let segment = minute / 15
            let pixelsPerMinute =
                segmentHeights[segment] / 15

            y += pixelsPerMinute
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
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: day)

        let minutes = CGFloat(
            date.timeIntervalSince(dayStart) / 60
        )

        return y(forMinute: minutes)
    }
}
