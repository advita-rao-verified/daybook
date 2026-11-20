//
//  DaybookTag.swift
//  daybook.
//
//  Created by Advita Rao on 11/20/26.
//


import SwiftUI

// MARK: - Color Palette

struct TagPalette: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var colors: [String]
}

// MARK: - Subtag

struct DaybookSubtag: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var colorHex: String
}

// MARK: - Tag

struct DaybookTag: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var palette: TagPalette
    var subtags: [DaybookSubtag] = []

    var primaryColor: Color {
        Color(hex: palette.colors.first ?? "#722F42")
    }
}

// MARK: - Featured Palettes

enum DaybookPalettes {

    static let featured: [TagPalette] = [
        TagPalette(
            name: "Romantic Reds",
            colors: [
                "#722F42",
                "#642C38",
                "#B77C8A",
                "#956779",
                "#B76E59"
            ]
        ),
        TagPalette(
            name: "Matcha Morning",
            colors: [
                "#526A4B",
                "#80946A",
                "#B0B994",
                "#718A78",
                "#C7C6A3"
            ]
        ),
        TagPalette(
            name: "Lavender Dreams",
            colors: [
                "#75618E",
                "#9B87B1",
                "#C0AED3",
                "#A38EB9",
                "#D1BED8"
            ]
        ),
        TagPalette(
            name: "Coastal Blues",
            colors: [
                "#385D76",
                "#648BA4",
                "#9CB8C8",
                "#537D92",
                "#A8C8CC"
            ]
        )
    ]

    static let library: [TagPalette] = featured + [
        TagPalette(
            name: "Dark Academia",
            colors: [
                "#453A36",
                "#70564D",
                "#937B66",
                "#5F6652",
                "#A48A69"
            ]
        ),
        TagPalette(
            name: "Golden Hour",
            colors: [
                "#A86543",
                "#CE9062",
                "#E2B17D",
                "#B67C67",
                "#E0C4A0"
            ]
        ),
        TagPalette(
            name: "Cherry Blossom",
            colors: [
                "#A84D68",
                "#D47A95",
                "#F0B4C4",
                "#C58CA5",
                "#824C68"
            ]
        ),
        TagPalette(
            name: "Midnight Garden",
            colors: [
                "#344B42",
                "#526C61",
                "#6B5676",
                "#9B7892",
                "#B39B83"
            ]
        )
    ]
}
