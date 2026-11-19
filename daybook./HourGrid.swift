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

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(0..<24, id: \.self) { hour in
                        HStack(spacing: 0) {
                            Text(hourLabel(hour))
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
                        .frame(
                            height: hourHeight,
                            alignment: .top
                        )
                    }
                }

                if showNow {
                    currentTimeLine(context.date)
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

    private func hourLabel(_ hour: Int) -> String {
        let display = hour % 12 == 0 ? 12 : hour % 12
        return "\(display) \(hour < 12 ? "AM" : "PM")"
    }

    private func currentTimeLine(_ now: Date) -> some View {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)

        let y = (
            CGFloat(hour) +
            CGFloat(minute) / 60
        ) * hourHeight

        return HStack(spacing: 0) {
            Text(now.formatted("h:mm"))
                .font(.system(size: 10))
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
        .frame(width: width, height: 12)
        .offset(y: y - 6)
    }
}
