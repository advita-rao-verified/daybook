//
//  AppColors.swift
//  daybook.
//
//  Created by Advita Rao on 11/18/26.
//


import SwiftUI

extension Color {
    init(hex: String) {
        let number = Int(
            hex.replacingOccurrences(of: "#", with: ""),
            radix: 16
        ) ?? 0

        self.init(
            .sRGB,
            red: Double((number >> 16) & 255) / 255,
            green: Double((number >> 8) & 255) / 255,
            blue: Double(number & 255) / 255,
            opacity: 1
        )
    }
}

enum Noir {
    static let background = Color(hex: "#101013")
    static let surface = Color(hex: "#19191E")
    static let field = Color(hex: "#242027")
    static let grid = Color(hex: "#303036")
    static let muted = Color(hex: "#A99BA0")
    static let accent = Color(hex: "#B95760")
    static let pale = Color(hex: "#F4E9EC")
}

struct TaskShade: Identifiable {
    let name: String
    let hex: String

    var id: String { hex }
    var color: Color { Color(hex: hex) }
}

enum TaskPalette {
    static let colors: [TaskShade] = [
        .init(name: "Black Cherry", hex: "#471C26"),
        .init(name: "Dark Wine", hex: "#6E2936"),
        .init(name: "Burgundy", hex: "#963F4D"),
        .init(name: "Dusty Rose", hex: "#B95760"),
        .init(name: "Rosewood", hex: "#D58A8F"),
        .init(name: "Blush", hex: "#E8B5B4"),
        .init(name: "Plum", hex: "#4D303C"),
        .init(name: "Mave", hex: "#73505D"),
        .init(name: "Orchid", hex: "#9D7582"),
        .init(name: "Rose Mauve", hex: "#C39AA5"),
        .init(name: "Soft Pink", hex: "#E0C2CA"),
        .init(name: "Petal", hex: "#F0DDE0"),
        .init(name: "Espresso", hex: "#6C4933"),
        .init(name: "Caramel", hex: "#946A45"),
        .init(name: "Muted Gold", hex: "#B68C62"),
        .init(name: "Champagne", hex: "#D5B38C"),
        .init(name: "Forest", hex: "#505C46"),
        .init(name: "Sage", hex: "#718166"),
        .init(name: "Eucalyptus", hex: "#94A485"),
        .init(name: "Pistachio", hex: "#B9C5A8"),
        .init(name: "Taupe", hex: "#625848"),
        .init(name: "Stone", hex: "#8B806D"),
        .init(name: "Sand", hex: "#B3A793"),
        .init(name: "Ivory", hex: "#D6CCBB"),
        .init(name: "Deep Slate", hex: "#354A54"),
        .init(name: "Storm Blue", hex: "#4B6876"),
        .init(name: "Dusty Blue", hex: "#7193A1"),
        .init(name: "Ice Blue", hex: "#A3BBC3"),
        .init(name: "Midnight", hex: "#3D4A67"),
        .init(name: "Steel Blue", hex: "#596A90"),
        .init(name: "Periwinkle", hex: "#8295BA"),
        .init(name: "Cloud Blue", hex: "#B7C3DC"),
        .init(name: "Dark Lavender", hex: "#51465F"),
        .init(name: "Amethyst", hex: "#76658B"),
        .init(name: "Lilac", hex: "#A08DB5"),
        .init(name: "Lavender", hex: "#C8B9D5")
    ]
}
