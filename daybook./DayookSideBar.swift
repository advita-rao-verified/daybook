//
//  DayookSideBar.swift
//  daybook.
//
//  Created by Advita Rao on 11/20/26.
//


import SwiftUI

enum DaybookSection: String, CaseIterable, Identifiable {
    case calendar = "Calendar"
    case tags = "Tags"
    case insights = "Insights"
    case customization = "Customization"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .calendar: return "calendar"
        case .tags: return "tag"
        case .insights: return "chart.bar.xaxis"
        case .customization: return "paintpalette"
        case .settings: return "gearshape"
        }
    }
}

struct DaybookSidebar: View {

    @Binding var selectedSection: DaybookSection
    @Binding var isExpanded: Bool

    private let expandedWidth: CGFloat = 220
    private let collapsedWidth: CGFloat = 62

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            HStack(spacing: 10) {
                if isExpanded {
                    Text("noir.")
                        .font(.system(
                            size: 23,
                            weight: .semibold,
                            design: .rounded
                        ))
                        .foregroundStyle(Noir.pale)

                    Spacer(minLength: 0)
                }

                Button {
                    withAnimation(
                        .easeInOut(duration: 0.22)
                    ) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(
                        systemName: isExpanded
                        ? "sidebar.left"
                        : "sidebar.right"
                    )
                    .font(.system(size: 17))
                    .foregroundStyle(Noir.muted)
                    .frame(
                        width: 36,
                        height: 36
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(
                    isExpanded
                    ? "Collapse Sidebar"
                    : "Expand Sidebar"
                )
            }
            .frame(height: 54)
            .padding(.horizontal, isExpanded ? 15 : 13)

            Rectangle()
                .fill(Noir.grid)
                .frame(height: 1)
                .padding(.horizontal, 12)

            VStack(spacing: 7) {
                ForEach(DaybookSection.allCases) { section in
                    sidebarButton(for: section)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 18)

            Spacer(minLength: 0)

            if isExpanded {
                Text("DAYBOOK")
                    .font(.system(
                        size: 10,
                        weight: .medium
                    ))
                    .tracking(2)
                    .foregroundStyle(Noir.muted)
                    .padding(.leading, 22)
                    .padding(.bottom, 18)
            }
        }
        .frame(
            width: isExpanded
            ? expandedWidth
            : collapsedWidth
        )
        .frame(maxHeight: .infinity)
        .background(Noir.surface)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Noir.grid)
                .frame(width: 1)
        }
    }

    private func sidebarButton(
        for section: DaybookSection
    ) -> some View {

        let isSelected = selectedSection == section

        return Button {
            selectedSection = section
        } label: {
            HStack(spacing: 13) {
                Image(systemName: section.icon)
                    .font(.system(
                        size: 17,
                        weight: .medium
                    ))
                    .frame(width: 22)

                if isExpanded {
                    Text(section.rawValue)
                        .font(.system(
                            size: 13,
                            weight: isSelected
                            ? .semibold
                            : .medium
                        ))

                    Spacer(minLength: 0)
                }
            }
            .foregroundStyle(
                isSelected
                ? Noir.pale
                : Noir.muted
            )
            .frame(
                maxWidth: .infinity,
                alignment: isExpanded
                ? .leading
                : .center
            )
            .frame(height: 43)
            .padding(.horizontal, isExpanded ? 12 : 0)
            .background {
                if isSelected {
                    RoundedRectangle(
                        cornerRadius: 10
                    )
                    .fill(Noir.accent.opacity(0.22))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(section.rawValue)
    }
}
