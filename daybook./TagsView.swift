//
//  TagsView.swift
//  daybook.
//
//  Created by Advita Rao on 11/20/26.
//


import SwiftUI

struct TagsView: View {

    @ObservedObject var store: TagStore

    @State private var showingNewTag = false
    @State private var newTagName = ""
    @State private var selectedPalette = DaybookPalettes.featured[0]
    @State private var showingAllPalettes = false

    @State private var subtagParent: DaybookTag?
    @State private var newSubtagName = ""
    @State private var selectedSubtagColor = ""

    private let columns = [
        GridItem(.adaptive(minimum: 260), spacing: 18)
    ]

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
                    showingNewTag = true
                } label: {
                    Label("New Tag", systemImage: "plus")
                        .font(.system(size: 13, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(Noir.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
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
        .sheet(isPresented: $showingNewTag) {
            newTagSheet
        }
        .sheet(item: $subtagParent) { tag in
            newSubtagSheet(for: tag)
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
                showingNewTag = true
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
                    Button("Delete Tag", role: .destructive) {
                        store.deleteTag(id: tag.id)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Noir.muted)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            HStack(spacing: 5) {
                ForEach(tag.palette.colors, id: \.self) { color in
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(hex: color))
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
                Text("S U B T A G S")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Noir.muted)

                Spacer()

                Button {
                    newSubtagName = ""
                    selectedSubtagColor =
                        tag.palette.colors.first ?? "#722F42"
                    subtagParent = tag
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
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay {
            RoundedRectangle(cornerRadius: 15)
                .stroke(Noir.grid, lineWidth: 1)
        }
    }

    // MARK: - New Subtag Sheet

    private func newSubtagSheet(for tag: DaybookTag) -> some View {
        VStack(alignment: .leading, spacing: 22) {

            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("New Subtag")
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
                    text: $newSubtagName
                )
                .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("CHOOSE A SHADE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Noir.muted)

                HStack(spacing: 12) {
                    ForEach(tag.palette.colors, id: \.self) { hex in
                        Button {
                            selectedSubtagColor = hex
                        } label: {
                            RoundedRectangle(cornerRadius: 9)
                                .fill(Color(hex: hex))
                                .frame(width: 53, height: 53)
                                .overlay {
                                    if selectedSubtagColor == hex {
                                        Image(systemName: "checkmark")
                                            .font(.system(
                                                size: 15,
                                                weight: .bold
                                            ))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .overlay {
                                    RoundedRectangle(cornerRadius: 9)
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
            }

            Spacer()

            HStack {
                Spacer()

                Button("Cancel") {
                    subtagParent = nil
                }
                .buttonStyle(.plain)

                Button("Create Subtag") {
                    let name = newSubtagName.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                    guard !name.isEmpty else { return }

                    store.addSubtag(
                        to: tag.id,
                        name: name,
                        colorHex: selectedSubtagColor
                    )

                    subtagParent = nil
                    newSubtagName = ""
                }
                .disabled(
                    newSubtagName.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                )
                .buttonStyle(.plain)
                .padding(.horizontal, 17)
                .padding(.vertical, 10)
                .background(Noir.accent)
                .clipShape(RoundedRectangle(cornerRadius: 9))
            }
        }
        .padding(28)
        .frame(width: 420, height: 360)
        .background(Noir.surface)
        .foregroundStyle(Noir.pale)
    }

    // MARK: - New Tag Sheet

    private var newTagSheet: some View {
        VStack(alignment: .leading, spacing: 22) {

            HStack {
                Text("Create a Tag")
                    .font(.system(size: 24, weight: .semibold))

                Spacer()

                Button {
                    showingNewTag = false
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

                TextField("e.g. Homework", text: $newTagName)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Text("CHOOSE A PALETTE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(Noir.muted)

                Spacer()

                Button(showingAllPalettes ? "Featured" : "Explore More") {
                    showingAllPalettes.toggle()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(Noir.accent)
            }

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(
                        showingAllPalettes
                            ? DaybookPalettes.library
                            : DaybookPalettes.featured
                    ) { palette in

                        Button {
                            selectedPalette = palette
                        } label: {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(palette.name)
                                        .font(.system(
                                            size: 13,
                                            weight: .medium
                                        ))

                                    HStack(spacing: 4) {
                                        ForEach(
                                            palette.colors,
                                            id: \.self
                                        ) { hex in
                                            RoundedRectangle(
                                                cornerRadius: 3
                                            )
                                            .fill(Color(hex: hex))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 19)
                                        }
                                    }
                                }

                                if selectedPalette.id == palette.id {
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

            Spacer(minLength: 0)

            HStack {
                Spacer()

                Button("Cancel") {
                    showingNewTag = false
                }
                .buttonStyle(.plain)

                Button("Create Tag") {
                    let name = newTagName.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                    guard !name.isEmpty else { return }

                    store.addTag(
                        name: name,
                        palette: selectedPalette
                    )

                    newTagName = ""
                    selectedPalette = DaybookPalettes.featured[0]
                    showingAllPalettes = false
                    showingNewTag = false
                }
                .disabled(
                    newTagName.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty
                )
                .buttonStyle(.plain)
                .padding(.horizontal, 17)
                .padding(.vertical, 10)
                .background(Noir.accent)
                .clipShape(RoundedRectangle(cornerRadius: 9))
            }
        }
        .padding(28)
        .frame(width: 460, height: 570)
        .background(Noir.surface)
        .foregroundStyle(Noir.pale)
    }
}
