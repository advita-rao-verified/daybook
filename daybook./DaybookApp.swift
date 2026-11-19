//
//  DaybookApp.swift
//  daybook.
//
//  Created by Advita Rao on 11/18/26.
//


import SwiftUI

@main
struct DaybookApp: App {
    var body: some Scene {
        WindowGroup {
            DaybookView()
                .preferredColorScheme(.dark)
                .frame(minWidth: 900, minHeight: 600)
        }
        .defaultSize(width: 1350, height: 850)
    }
}

