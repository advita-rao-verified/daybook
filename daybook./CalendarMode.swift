//
//  CalendarMode.swift
//  daybook.
//
//  Created by Advita Rao on 11/18/26.
//


import Foundation

enum CalendarMode: String, CaseIterable {
    case day = "Day"
    case twoDays = "2 Days"
    case week = "Week"
    case month = "Month"
}

struct EditorRequest: Identifiable {
    let id = UUID()
    let task: CalendarTask?
}
