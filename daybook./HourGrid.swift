//
//  HourGrid.swift
//  daybook.
//
//  Created by Advita Rao on 11/18/26.
//


import SwiftUI

struct HourGrid: View {
    let width: CGFloat
    let gutter: CGFloat
    let hourHeight: CGFloat
    let showNow: Bool

    private var totalHeight: CGFloat {
        24 * hourHeight
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 15)) { context in
            ZStack(alignment: .topLeading) {

                // MARK: - Hour Lines

                ForEach(0..<24, id: \.self) { hour in
                    hourRow(hour)
                        .offset(
                            y: CGFloat(hour) * hourHeight
                        )
                }

                // MARK: - Current Time Indicator

                if showNow {
                    currentTimeLine(context.date)
                }
            }
            .frame(
                width: width,
                height: totalHeight,
                alignment: .topLeading
            )
        }
        .allowsHitTesting(false)
    }

    // MARK: - Hour Row

    private func hourRow(_ hour: Int) -> some View {
        HStack(spacing: 0) {
            Text(hourLabel(hour))
                .font(.system(size: 10))
                .foregroundStyle(Noir.muted)
                .frame(
                    width: gutter - 10,
                    alignment: .trailing
                )

            Color.clear
                .frame(width: 10)

            Rectangle()
                .fill(Noir.grid)
                .frame(height: 1)
        }
        .frame(
            width: width,
            height: 1,
            alignment: .leading
        )
    }

    // MARK: - Hour Label

    private func hourLabel(_ hour: Int) -> String {
        let display = hour % 12 == 0 ? 12 : hour % 12

        return "\(display) \(hour < 12 ? "AM" : "PM")"
    }

    // MARK: - Current Time Indicator

    private func currentTimeLine(_ now: Date) -> some View {
        let calendar = Calendar.current

        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let second = calendar.component(.second, from: now)

        // Exact position including seconds.
        let hoursSinceMidnight =
            CGFloat(hour)
            + CGFloat(minute) / 60
            + CGFloat(second) / 3600

        let yPosition = hoursSinceMidnight * hourHeight

        return HStack(spacing: 0) {
            Text(now.formatted("h:mm"))
                .font(.system(
                    size: 10,
                    weight: .semibold
                ))
                .foregroundStyle(Noir.accent)
                .frame(
                    width: gutter - 5,
                    alignment: .trailing
                )

            Circle()
                .fill(Noir.accent)
                .frame(width: 7, height: 7)

            Rectangle()
                .fill(Noir.accent)
                .frame(height: 1.5)
        }
        .frame(
            width: width,
            height: 12
        )
        .offset(y: yPosition - 6)
    }
}
