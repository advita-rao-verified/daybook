//
//  InsightsView.swift
//  daybook.
//
//  Created by Advita Rao on 11/20/26.
//


import SwiftUI
import Charts

private enum InsightsPeriod: String, CaseIterable {
    case today = "Today"
    case week = "Week"
    case month = "Month"
}

private struct TimeSlice: Identifiable {
    let id: String
    let name: String
    let seconds: Double
    let color: Color

    var hours: Double {
        seconds / 3600
    }
}

struct InsightsView: View {
    @ObservedObject var store: TaskStore
    @ObservedObject var tagStore: TagStore

    @State private var selectedPeriod: InsightsPeriod = .week
    @State private var referenceDate = Date()

    private let uncategorizedColor = Color(hex: "#77717A")

    // MARK: - Date Range

    private var dateRange: DateInterval {
        let calendar = Calendar.current

        switch selectedPeriod {
        case .today:
            let start = calendar.startOfDay(for: referenceDate)
            let end = calendar.date(
                byAdding: .day,
                value: 1,
                to: start
            ) ?? start.addingTimeInterval(86400)

            return DateInterval(start: start, end: end)

        case .week:
            return calendar.dateInterval(
                of: .weekOfYear,
                for: referenceDate
            ) ?? DateInterval(
                start: referenceDate,
                duration: 604800
            )

        case .month:
            return calendar.dateInterval(
                of: .month,
                for: referenceDate
            ) ?? DateInterval(
                start: referenceDate,
                duration: 2592000
            )
        }
    }

    private var periodTitle: String {
        switch selectedPeriod {
        case .today:
            return referenceDate.formatted(
                .dateTime.month(.wide).day().year()
            )

        case .week:
            let lastDay = Calendar.current.date(
                byAdding: .day,
                value: -1,
                to: dateRange.end
            ) ?? dateRange.end

            return "\(dateRange.start.formatted(.dateTime.month(.abbreviated).day())) – \(lastDay.formatted(.dateTime.month(.abbreviated).day().year()))"

        case .month:
            return referenceDate.formatted(
                .dateTime.month(.wide).year()
            )
        }
    }

    // MARK: - Calculate Scheduled Time

    private var slices: [TimeSlice] {
        let calendar = Calendar.current
        let range = dateRange

        var totals: [String: Double] = [:]
        var day = calendar.startOfDay(for: range.start)

        while day < range.end {
            for task in store.tasks(on: day) {

                // Only count the portion of a task inside
                // the selected day and selected period.
                let nextDay = calendar.date(
                    byAdding: .day,
                    value: 1,
                    to: day
                ) ?? day.addingTimeInterval(86400)

                let overlapStart = max(
                    task.start,
                    day,
                    range.start
                )

                let overlapEnd = min(
                    task.end,
                    nextDay,
                    range.end
                )

                let duration = overlapEnd.timeIntervalSince(
                    overlapStart
                )

                guard duration > 0 else {
                    continue
                }

                let key = task.tagID?.uuidString
                    ?? "uncategorized"

                totals[key, default: 0] += duration
            }

            guard let nextDay = calendar.date(
                byAdding: .day,
                value: 1,
                to: day
            ) else {
                break
            }

            day = nextDay
        }

        return totals.map { key, seconds in
            if let tag = tagStore.tags.first(where: {
                $0.id.uuidString == key
            }) {
                return TimeSlice(
                    id: key,
                    name: tag.name,
                    seconds: seconds,
                    color: tag.primaryColor
                )
            }

            return TimeSlice(
                id: key,
                name: "Uncategorized",
                seconds: seconds,
                color: uncategorizedColor
            )
        }
        .sorted { $0.seconds > $1.seconds }
    }

    private var totalSeconds: Double {
        slices.reduce(0) { $0 + $1.seconds }
    }

    private func percentage(for slice: TimeSlice) -> Int {
        guard totalSeconds > 0 else { return 0 }

        return Int(
            (slice.seconds / totalSeconds * 100).rounded()
        )
    }

    private func formattedDuration(_ seconds: Double) -> String {
        let minutes = Int((seconds / 60).rounded())
        let hours = minutes / 60
        let remaining = minutes % 60

        if hours == 0 {
            return "\(remaining)m"
        }

        if remaining == 0 {
            return "\(hours)h"
        }

        return "\(hours)h \(remaining)m"
    }

    // MARK: - Main View

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {

                header

                periodControls

                if slices.isEmpty {
                    emptyState
                } else {
                    chartCard
                }

                Spacer(minLength: 20)
            }
            .padding(30)
            .frame(
                maxWidth: 1000,
                alignment: .leading
            )
            .frame(maxWidth: .infinity)
        }
        .background(Noir.background)
        .foregroundStyle(Noir.pale)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Your Insights")
                .font(.system(
                    size: 30,
                    weight: .semibold
                ))

            Text("A closer look at where your time goes.")
                .font(.system(size: 13))
                .foregroundStyle(Noir.muted)
        }
    }

    // MARK: - Period Controls

    private var periodControls: some View {
        HStack(spacing: 14) {
            HStack(spacing: 4) {
                ForEach(InsightsPeriod.allCases, id: \.self) { period in
                    Button {
                        selectedPeriod = period
                    } label: {
                        Text(period.rawValue)
                            .font(.system(
                                size: 12,
                                weight: .medium
                            ))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                selectedPeriod == period
                                    ? Noir.accent
                                    : Color.clear
                            )
                            .clipShape(
                                RoundedRectangle(cornerRadius: 8)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(Noir.surface)
            .clipShape(
                RoundedRectangle(cornerRadius: 12)
            )

            Spacer(minLength: 0)

            Button {
                changePeriod(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)

            Text(periodTitle)
                .font(.system(size: 12))
                .foregroundStyle(Noir.muted)
                .lineLimit(1)

            Button {
                changePeriod(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.plain)
        }
    }

    private func changePeriod(by amount: Int) {
        let component: Calendar.Component

        switch selectedPeriod {
        case .today:
            component = .day
        case .week:
            component = .weekOfYear
        case .month:
            component = .month
        }

        if let updated = Calendar.current.date(
            byAdding: component,
            value: amount,
            to: referenceDate
        ) {
            referenceDate = updated
        }
    }

    // MARK: - Chart Card

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 24) {

            VStack(alignment: .leading, spacing: 6) {
                Text("WHERE YOUR TIME GOES")
                    .font(.system(
                        size: 10,
                        weight: .semibold
                    ))
                    .tracking(2)
                    .foregroundStyle(Noir.muted)

                Text(formattedDuration(totalSeconds))
                    .font(.system(
                        size: 28,
                        weight: .semibold
                    ))

                Text("Total scheduled time")
                    .font(.system(size: 12))
                    .foregroundStyle(Noir.muted)
            }

            // MARK: - Doughnut Chart

            Chart(slices) { slice in
                SectorMark(
                    angle: .value(
                        "Scheduled Time",
                        slice.seconds
                    ),
                    innerRadius: .ratio(0.58),
                    angularInset: 0
                )
                .foregroundStyle(slice.color)
                .annotation(position: .overlay) {
                    if slice.seconds / totalSeconds >= 0.055 {
                        Text("\(percentage(for: slice))%")
                            .font(.system(
                                size: 13,
                                weight: .semibold
                            ))
                            .foregroundStyle(.white)
                    }
                }
            }
            .chartLegend(.hidden)
            .frame(height: 360)
            .chartBackground { _ in
                GeometryReader { geometry in
                    let diameter = min(
                        geometry.size.width,
                        geometry.size.height
                    )

                    VStack(spacing: 5) {
                        ForEach(
                            Array(slices.prefix(5))
                        ) { slice in
                            Text(slice.name)
                                .font(.system(
                                    size: 10,
                                    weight: .medium
                                ))
                                .foregroundStyle(slice.color)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }

                        if slices.count > 5 {
                            Text("+\(slices.count - 5) more")
                                .font(.system(size: 9))
                                .foregroundStyle(Noir.muted)
                        }
                    }
                    .frame(width: diameter * 0.36)
                    .position(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    )
                }
            }

            Rectangle()
                .fill(Noir.grid)
                .frame(height: 1)

            // MARK: - Category Breakdown

            VStack(spacing: 16) {
                ForEach(slices) { slice in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(slice.color)
                            .frame(width: 11, height: 11)

                        Text(slice.name)
                            .font(.system(
                                size: 13,
                                weight: .medium
                            ))

                        Spacer()

                        Text("\(percentage(for: slice))%")
                            .foregroundStyle(Noir.muted)

                        Text(formattedDuration(slice.seconds))
                            .fontWeight(.semibold)
                            .frame(
                                width: 85,
                                alignment: .trailing
                            )
                    }
                    .font(.system(size: 12))
                }
            }

            Text("Based on scheduled calendar tasks. Overlapping tasks are counted individually.")
                .font(.system(size: 11))
                .foregroundStyle(Noir.muted)
        }
        .padding(26)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .background(Noir.surface)
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Noir.grid, lineWidth: 1)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "chart.pie")
                .font(.system(size: 36))
                .foregroundStyle(Noir.accent)

            Text("Nothing to chart just yet.")
                .font(.system(
                    size: 19,
                    weight: .semibold
                ))

            Text("Schedule some tasks to see how your time is distributed.")
                .font(.system(size: 13))
                .foregroundStyle(Noir.muted)
                .multilineTextAlignment(.center)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 340
        )
        .background(Noir.surface)
        .clipShape(
            RoundedRectangle(cornerRadius: 18)
        )
    }
}
