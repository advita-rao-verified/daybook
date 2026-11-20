//
//  TagStore.swift
//  daybook.
//
//  Created by Advita Rao on 11/20/26.
//


import Foundation
import Combine

@MainActor
final class TagStore: ObservableObject {

    @Published var tags: [DaybookTag] = [] {
        didSet {
            saveTags()
        }
    }

    private let storageKey = "daybook.savedTags"

    init() {
        loadTags()
    }

    // MARK: - Save

    private func saveTags() {
        guard let data = try? JSONEncoder().encode(tags) else {
            return
        }

        UserDefaults.standard.set(data, forKey: storageKey)
    }

    // MARK: - Load

    private func loadTags() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let savedTags = try? JSONDecoder().decode(
                [DaybookTag].self,
                from: data
              ) else {
            return
        }

        tags = savedTags
    }

    // MARK: - Create Tag

    func addTag(name: String, palette: TagPalette) {
        let tag = DaybookTag(
            name: name,
            palette: palette
        )

        tags.append(tag)
    }

    // MARK: - Delete Tag

    func deleteTag(id: UUID) {
        tags.removeAll { $0.id == id }
    }

    // MARK: - Add Subtag

    func addSubtag(
        to tagID: UUID,
        name: String,
        colorHex: String
    ) {
        guard let index = tags.firstIndex(where: { $0.id == tagID }) else {
            return
        }

        let subtag = DaybookSubtag(
            name: name,
            colorHex: colorHex
        )

        tags[index].subtags.append(subtag)
    }

    // MARK: - Delete Subtag

    func deleteSubtag(tagID: UUID, subtagID: UUID) {
        guard let index = tags.firstIndex(where: { $0.id == tagID }) else {
            return
        }

        tags[index].subtags.removeAll { $0.id == subtagID }
    }

    // MARK: - Update Palette

    func updatePalette(tagID: UUID, palette: TagPalette) {
        guard let index = tags.firstIndex(where: { $0.id == tagID }) else {
            return
        }

        tags[index].palette = palette
    }
}
