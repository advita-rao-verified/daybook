//
//  CalendarTimeline.swift
//  daybook.
//
//  Created by Advita Rao on 11/18/26.
//


import SwiftUI

struct CalendarTimeline: View {
    let days: [Date]
    @ObservedObject var store: TaskStore
    let edit: (CalendarTask) -> Void

    private let gutter: CGFloat = 72

    private var layout: AdaptiveTimelineLayout {
        AdaptiveTimelineLayout(
            days: days,
            tasksByDay: days.map {
                store.tasks(on: $0)
            }
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Color.clear
                    .frame(width: gutter)

                ForEach(days, id: \.self) { day in
                    VStack(spacing: 4) {
                        Text(
                            day.formatted("EEE").uppercased()
                        )
                        .font(.system(size: 10))
                        .foregroundStyle(Noir.muted)

                        Text(day.formatted("d"))
                            .font(.system(
                                size: 20,
                                weight: .semibold
                            ))
                            .foregroundStyle(
                                Calendar.current.isDateInToday(day)
                                ? Noir.accent
                                : Noir.pale
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 70)

            Divider()

            ScrollView(.vertical) {
                GeometryReader { geometry in
                    let sharedLayout = layout

                    let columnWidth = max(
                        1,
                        (geometry.size.width - gutter)
                        / CGFloat(max(1, days.count))
                    )

                    ZStack(alignment: .topLeading) {
                        HourGrid(
                            width: geometry.size.width,
                            gutter: gutter,
                            layout: sharedLayout,
                            showNow: days.contains {
                                Calendar.current.isDateInToday($0)
                            }
                        )

                        HStack(
                            alignment: .top,
                            spacing: 0
                        ) {
                            Color.clear
                                .frame(width: gutter)

                            ForEach(days, id: \.self) { day in
                                DayColumn(
                                    day: day,
                                    tasks: store.tasks(on: day),
                                    store: store,
                                    layout: sharedLayout,
                                    edit: edit
                                )
                                .frame(
                                    width: columnWidth,
                                    height: sharedLayout.totalHeight,
                                    alignment: .topLeading
                                )
                            }
                        }
                    }
                    .frame(
                        width: geometry.size.width,
                        height: sharedLayout.totalHeight,
                        alignment: .topLeading
                    )
                }
                .frame(height: layout.totalHeight)
            }
        }
    }
}
