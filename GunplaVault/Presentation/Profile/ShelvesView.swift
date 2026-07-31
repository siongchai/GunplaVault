import SwiftUI
import PhotosUI

struct ShelvesView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var shelfStore: ShelfStore
    @EnvironmentObject private var profileStore: ProfileStore

    @State private var newShelfName = ""
    @State private var showAddShelf = false
    @State private var showPhotoPicker = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var targetShelf: VirtualShelf?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenHeader(
                    title: "Virtual Shelves",
                    subtitle: shelfSubtitle
                )

                if shelfStore.shelves.isEmpty {
                    GVCard {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.largeTitle)
                                .foregroundStyle(GVColors.accent.opacity(0.5))
                            Text("No shelves yet")
                                .font(GVTypography.headline)
                            Text("Create a shelf and add photos of your physical display.")
                                .font(GVTypography.callout)
                                .foregroundStyle(GVColors.textSecondary)
                                .multilineTextAlignment(.center)
                            GVPrimaryButton(title: "Create Shelf") { showAddShelf = true }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                } else {
                    ForEach(shelfStore.shelves) { shelf in
                        shelfCard(shelf)
                    }
                }

                if shelfStore.canAddShelf {
                    Button {
                        showAddShelf = true
                    } label: {
                        Label("Add Shelf", systemImage: "plus")
                            .font(GVTypography.callout)
                            .foregroundStyle(GVColors.accent)
                    }
                }
            }
            .padding(20)
        }
        .background(GVColors.background)
        .navigationTitle("Shelves")
        .navigationBarTitleDisplayMode(.inline)
        .alert("New Shelf", isPresented: $showAddShelf) {
            TextField("Shelf name", text: $newShelfName)
            Button("Create") { createShelf() }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $shelfStore.showPaywall) {
            PaywallView().environmentObject(appState)
        }
        .onChange(of: selectedPhoto) { _, item in
            guard let item, let targetShelf else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    try? shelfStore.addPhoto(image, to: targetShelf)
                }
                selectedPhoto = nil
                self.targetShelf = nil
            }
        }
    }

    private var shelfSubtitle: String {
        if profileStore.tier == .pro {
            return "\(shelfStore.shelves.count) shelves"
        }
        return "Free plan: 1 shelf · Pro: unlimited"
    }

    private func shelfCard(_ shelf: VirtualShelf) -> some View {
        GVCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(shelf.name)
                        .font(GVTypography.headline)
                    Spacer()
                    Button(role: .destructive) {
                        try? shelfStore.deleteShelf(shelf)
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                    }
                }

                if shelf.photoFilenames.isEmpty {
                    Text("No photos yet")
                        .font(GVTypography.caption)
                        .foregroundStyle(GVColors.textSecondary)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(shelf.photoFilenames, id: \.self) { filename in
                                if let image = ShelfPhotoStorage.load(filename: filename) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                }

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Label("Add Photo", systemImage: "camera.fill")
                        .font(GVTypography.callout)
                        .foregroundStyle(GVColors.accent)
                }
                .onTapGesture {
                    targetShelf = shelf
                }
            }
        }
    }

    private func createShelf() {
        let name = newShelfName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        do {
            try shelfStore.addShelf(name: name)
            newShelfName = ""
        } catch {
            shelfStore.errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        ShelvesView()
    }
    .environmentObject(AppState.makeDefault())
    .environmentObject(ShelfStore(context: PersistenceController.shared.mainContext, profileStore: ProfileStore()))
    .environmentObject(ProfileStore())
}
