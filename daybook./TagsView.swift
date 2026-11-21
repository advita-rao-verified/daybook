//
//  TagsView.swift
//  daybook.
//
//  Created by Advita Rao on 11/20/26.
//


import SwiftUI

struct TagsView: View {

    @ObservedObject var store: TagStore

    @State private var showingTagEditor = false
    @State private var editingTagID: UUID?
    @State private var tagName = ""
    @State private var selectedPalette = DaybookPalettes.featured[0]
    @State private var showingAllPalettes = false
    @State private var paletteSearch = ""

    @State private var subtagParent: DaybookTag?
    @State private var editingSubtagID: UUID?
    @State private var subtagName = ""
    @State private var selectedSubtagColor = ""

    private let columns = [
        GridItem(.adaptive(minimum: 260), spacing: 18)
    ]

    private var availablePalettes: [TagPalette] {
        let palettes = showingAllPalettes
            ? DaybookPalettes.library
            : DaybookPalettes.featured

        return palettes.filter {
            paletteSearch.isEmpty ||
            $0.name.localizedCaseInsensitiveContains(paletteSearch)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Tags")
                        .font(.system(size: 30, weight: .semibold))

                    Text("Organize your world, beautifully.")
                        .font(.system(size: 13))
                        .foregroundStyle(Noir.muted)
                }

                Spacer()

                Button {
                    openNewTag()
                } label: {
                    Label("New Tag", systemImage: "plus")
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(Noir.accent)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 10)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(28)

            Rectangle()
                .fill(Noir.grid)
                .frame(height: 1)

            ScrollView {
                if store.tags.isEmpty {
                    emptyState
                } else {
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(store.tags) { tag in
                            tagCard(tag)
                        }
                    }
                    .padding(28)
                }
            }
        }
        .background(Noir.background)
        .sheet(isPresented: $showingTagEditor) {
            tagEditorSheet
        }
        .sheet(item: $subtagParent) { tag in
            subtagEditorSheet(for: tag)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 15) {
            Image(systemName: "tag")
                .font(.system(size: 36))
                .foregroundStyle(Noir.accent)

            Text("A little organization goes a long way.")
                .font(.system(size: 19, weight: .semibold))

            Text("Create your first tag to get started.")
                .font(.system(size: 13))
                .foregroundStyle(Noir.muted)

            Button("Create a Tag") {
                openNewTag()
            }
            .buttonStyle(.plain)
            .foregroundStyle(Noir.accent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, minHeight: 380)
    }

    // MARK: - Tag Card

    private func tagCard(_ tag: DaybookTag) -> some View {
        VStack(alignment: .leading, spacing: 15) {

            HStack {
                Text(tag.name)
                    .font(.system(size: 19, weight: .semibold))

                Spacer()

                Menu {
                    Button {
                        openEditTag(tag)
                    } label: {
                        Label("Edit Tag", systemImage: "pencil")
                    }

                    Divider()

                    Button(role: .destructive) {
                        store.deleteTag(id: tag.id)
                    } label: {
                        Label("Delete Tag", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Noir.muted)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            HStack(spacing: 5) {
                ForEach(
                    Array(tag.palette.colors.enumerated()),
                    id: \.offset
                ) { _, hex in
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(hex: hex))
                        .frame(maxWidth: .infinity)
                        .frame(height: 29)
                }
            }

            Text(tag.palette.name)
                .font(.system(size: 11))
                .foregroundStyle(Noir.muted)

            Rectangle()
                .fill(Noir.grid)
                .frame(height: 1)

            HStack {
                Text("SUBTAGS")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Noir.muted)

                Spacer()

                Button {
                    openNewSubtag(for: tag)
                } label: {
                    Label("Add Subtag", systemImage: "plus")
                        .font(.system(size: 11))
                        .foregroundStyle(Noir.accent)
                }
                .buttonStyle(.plain)
            }

            if tag.subtags.isEmpty {
                Text("No subtags yet")
                    .font(.system(size: 12))
                    .foregroundStyle(Noir.muted)
            } else {
                ForEach(tag.subtags) { subtag in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: subtag.colorHex))
                            .frame(width: 9, height: 9)

                        Text(subtag.name.uppercased())
                            .font(.system(size: 10, weight: .medium))
                            .tracking(1.5)

                        Spacer()

                        Button {
                            openEditSubtag(subtag, in: tag)
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 10))
                                .foregroundStyle(Noir.muted)
                        }
                        .buttonStyle(.plain)
                        .help("Edit subtag")

                        Button {
                            store.deleteSubtag(
                                tagID: tag.id,
                                subtagID: subtag.id
                            )
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 9))
                                .foregroundStyle(Noir.muted)
                        }
                        .buttonStyle(.plain)
                        .help("Delete subtag")
                    }
                    .padding(.vertical, 3)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Noir.surface)
        .clipShape(
            RoundedRectangle(cornerRadius: 15)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 15)
                .stroke(Noir.grid, lineWidth: 1)
        }
    }

    // MARK: - Open Tag Editors

    private func openNewTag() {
        editingTagID = nil
        tagName = ""
        selectedPalette = DaybookPalettes.featured[0]
        showingAllPalettes = false
        paletteSearch = ""
        showingTagEditor = true
    }

    private func openEditTag(_ tag: DaybookTag) {
        editingTagID = tag.id
        tagName = tag.name
        selectedPalette = tag.palette

        let isFeatured = DaybookPalettes.featured.contains {
            $0.name == tag.palette.name
        }

        showingAllPalettes = !isFeatured
        paletteSearch = ""
        showingTagEditor = true
    }

    private func saveTag() {
        let name = tagName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !name.isEmpty else { return }

        if let id = editingTagID {
            store.renameTag(id: id, name: name)
            store.updatePalette(
                tagID: id,
                palette: selectedPalette
            )
        } else {
            store.addTag(
                name: name,
                palette: selectedPalette
            )
        }

        showingTagEditor = false
    }

    // MARK: - Tag Editor Sheet

    private var tagEditorSheet: some View {
        VStack(alignment: .leading, spacing: 22) {

            HStack {
                Text(
                    editingTagID == nil
                        ? "Create a Tag"
                        : "Edit Tag"
                )
                .font(.system(size: 24, weight: .semibold))

                Spacer()

                Button {
                    showingTagEditor = false
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("TAG NAME")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Noir.muted)

                TextField("e.g. Homework", text: $tagName)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Text("CHOOSE A PALETTE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Noir.muted)

                Spacer()

                Button(
                    showingAllPalettes
                        ? "Featured"
                        : "Explore More"
                ) {
                    showingAllPalettes.toggle()
                    paletteSearch = ""
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(Noir.accent)
            }

            if showingAllPalettes {
                TextField(
                    "Search palettes...",
                    text: $paletteSearch
                )
                .textFieldStyle(.roundedBorder)
            }

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(availablePalettes) { palette in
                        Button {
                            selectedPalette = palette
                        } label: {
                            HStack(spacing: 12) {
                                VStack(
                                    alignment: .leading,
                                    spacing: 8
                                ) {
                                    Text(palette.name)
                                        .font(.system(
                                            size: 13,
                                            weight: .medium
                                        ))

                                    HStack(spacing: 4) {
                                        ForEach(
                                            Array(
                                                palette.colors.enumerated()
                                            ),
                                            id: \.offset
                                        ) { _, hex in
                                            RoundedRectangle(
                                                cornerRadius: 3
                                            )
                                            .fill(Color(hex: hex))
                                            .frame(
                                                maxWidth: .infinity
                                            )
                                            .frame(height: 19)
                                        }
                                    }
                                }

                                if selectedPalette.name == palette.name {
                                    Image(
                                        systemName: "checkmark.circle.fill"
                                    )
                                    .foregroundStyle(Noir.accent)
                                }
                            }
                            .padding(12)
                            .background(Noir.field)
                            .clipShape(
                                RoundedRectangle(cornerRadius: 10)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 300)

            if editingTagID != nil {
                Text(
                    "Existing subtags keep their colors when you change palettes."
                )
                .font(.system(size: 11))
                .foregroundStyle(Noir.muted)
            }

            Spacer(minLength: 0)

            HStack {
                Spacer()

                Button("Cancel") {
                    showingTagEditor = false
                }
                .buttonStyle(.plain)

                Button(
                    editingTagID == nil
                        ? "Create Tag"
                        : "Save Changes"
                ) {
                    saveTag()
                }
                .disabled(
                    tagName.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                )
                .buttonStyle(.plain)
                .padding(.horizontal, 17)
                .padding(.vertical, 10)
                .background(Noir.accent)
                .clipShape(
                    RoundedRectangle(cornerRadius: 9)
                )
            }
        }
        .padding(28)
        .frame(width: 460, height: 590)
        .background(Noir.surface)
        .foregroundStyle(Noir.pale)
    }

    // MARK: - Open Subtag Editors

    private func openNewSubtag(for tag: DaybookTag) {
        editingSubtagID = nil
        subtagName = ""
        selectedSubtagColor =
            tag.palette.colors.first ?? "#722F42"
        subtagParent = tag
    }

    private func openEditSubtag(
        _ subtag: DaybookSubtag,
        in tag: DaybookTag
    ) {
        editingSubtagID = subtag.id
        subtagName = subtag.name
        selectedSubtagColor = subtag.colorHex
        subtagParent = tag
    }

    private func saveSubtag(for tag: DaybookTag) {
        let name = subtagName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !name.isEmpty else { return }

        if let id = editingSubtagID {
            store.updateSubtag(
                tagID: tag.id,
                subtagID: id,
                name: name,
                colorHex: selectedSubtagColor
            )
        } else {
            store.addSubtag(
                to: tag.id,
                name: name,
                colorHex: selectedSubtagColor
            )
        }

        subtagParent = nil
    }

    // MARK: - Subtag Editor Sheet

    private func subtagEditorSheet(
        for tag: DaybookTag
    ) -> some View {
        VStack(alignment: .leading, spacing: 22) {

            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(
                        editingSubtagID == nil
                            ? "New Subtag"
                            : "Edit Subtag"
                    )
                    .font(.system(size: 24, weight: .semibold))

                    Text("Inside \(tag.name)")
                        .font(.system(size: 12))
                        .foregroundStyle(Noir.muted)
                }

                Spacer()

                Button {
                    subtagParent = nil
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("SUBTAG NAME")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Noir.muted)

                TextField(
                    "e.g. Math, English, Science",
                    text: $subtagName
                )
                .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("CHOOSE A SHADE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Noir.muted)

                HStack(spacing: 12) {
                    ForEach(
                        Array(tag.palette.colors.enumerated()),
                        id: \.offset
                    ) { _, hex in
                        Button {
                            selectedSubtagColor = hex
                        } label: {
                            RoundedRectangle(cornerRadius: 9)
                                .fill(Color(hex: hex))
                                .frame(width: 53, height: 53)
                                .overlay {
                                    if selectedSubtagColor == hex {
                                        Image(
                                            systemName: "checkmark"
                                        )
                                        .font(.system(
                                            size: 15,
                                            weight: .bold
                                        ))
                                        .foregroundStyle(.white)
                                    }
                                }
                                .overlay {
                                    RoundedRectangle(
                                        cornerRadius: 9
                                    )
                                    .stroke(
                                        selectedSubtagColor == hex
                                            ? Color.white
                                            : Color.clear,
                                        lineWidth: 2
                                    )
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }

                if editingSubtagID != nil &&
                    !tag.palette.colors.contains(
                        selectedSubtagColor
                    ) {
                    Text(
                        "This subtag uses a shade from its previous palette. Choose a new shade to update it."
                    )
                    .font(.system(size: 11))
                    .foregroundStyle(Noir.muted)
                }
            }

            Spacer()

            HStack {
                Spacer()

                Button("Cancel") {
                    subtagParent = nil
                }
                .buttonStyle(.plain)

                Button(
                    editingSubtagID == nil
                        ? "Create Subtag"
                        : "Save Changes"
                ) {
                    saveSubtag(for: tag)
                }
                .disabled(
                    subtagName.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                )
                .buttonStyle(.plain)
                .padding(.horizontal, 17)
                .padding(.vertical, 10)
                .background(Noir.accent)
                .clipShape(
                    RoundedRectangle(cornerRadius: 9)
                )
            }
        }
        .padding(28)
        .frame(width: 420, height: 380)
        .background(Noir.surface)
        .foregroundStyle(Noir.pale)
    }
}
