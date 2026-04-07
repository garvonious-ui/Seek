import SwiftUI
import SwiftData
import Photos

struct CardCreatorView: View {
    let verseReference: String
    let verseText: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var selectedTemplate = CardTemplate.all[0]
    @State private var isSaving = false
    @State private var showShareSheet = false
    @State private var renderedImage: UIImage?
    @State private var showSavedToast = false
    @State private var showPermissionAlert = false

    private var isPremium: Bool { profiles.first?.isPremium ?? false }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Card preview (scaled down)
                cardPreview
                    .padding(.top, 16)
                    .padding(.horizontal)

                // Template picker
                templatePicker
                    .padding(.top, 16)

                Spacer()

                // Actions
                actionButtons
                    .padding(.horizontal)
                    .padding(.bottom, 16)
            }
            .background(Color(hex: "FAFAF6"))
            .navigationTitle("Create Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if showSavedToast {
                    savedToast
                }
            }
            .alert("Photo Access Required", isPresented: $showPermissionAlert) {
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please allow photo library access in Settings to save verse cards.")
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = renderedImage {
                    ShareSheetView(image: image)
                }
            }
        }
    }

    // MARK: - Card Preview

    private var cardPreview: some View {
        VerseCardView(
            verseText: verseText,
            verseReference: verseReference,
            template: selectedTemplate
        )
        .scaleEffect(0.28)
        .frame(
            width: VerseCardView.renderWidth * 0.28,
            height: VerseCardView.renderHeight * 0.28
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
    }

    // MARK: - Template Picker

    private var templatePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose a style")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color(hex: "6B7280"))
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(CardTemplate.all) { tmpl in
                        Button {
                            if tmpl.isPremium && !isPremium {
                                // TODO: Show premium upgrade
                            } else {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTemplate = tmpl
                                }
                            }
                        } label: {
                            VStack(spacing: 4) {
                                VerseCardThumbnail(template: tmpl, isPremium: isPremium)
                                    .overlay {
                                        if tmpl.id == selectedTemplate.id {
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color(hex: "5B7B5E"), lineWidth: 2.5)
                                        }
                                    }
                                Text(tmpl.name)
                                    .font(.caption2)
                                    .foregroundStyle(tmpl.id == selectedTemplate.id ? Color(hex: "5B7B5E") : Color(hex: "9CA3AF"))
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button {
                Task { await saveToPhotos() }
            } label: {
                Label(isSaving ? "Saving..." : "Save", systemImage: "square.and.arrow.down")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(isSaving)

            Button {
                Task { await shareCard() }
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "5B7B5E"))
        }
        .controlSize(.large)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - Saved Toast

    private var savedToast: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Saved to Photos")
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(hex: "4CAF50"), in: Capsule())
            .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring, value: showSavedToast)
    }

    // MARK: - Rendering

    @MainActor
    private func renderCard() -> UIImage? {
        let renderer = ImageRenderer(
            content: VerseCardView(
                verseText: verseText,
                verseReference: verseReference,
                template: selectedTemplate
            )
        )
        renderer.scale = 2.0 // 2x for quality
        return renderer.uiImage
    }

    // MARK: - Save

    private func saveToPhotos() async {
        isSaving = true
        defer { isSaving = false }

        guard let image = await renderCard() else { return }

        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            showPermissionAlert = true
            return
        }

        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

        // Save to SwiftData
        saveCardToSwiftData()

        withAnimation {
            showSavedToast = true
        }
        try? await Task.sleep(for: .seconds(2))
        withAnimation {
            showSavedToast = false
        }
    }

    // MARK: - Share

    private func shareCard() async {
        guard let image = await renderCard() else { return }
        renderedImage = image

        // Save to SwiftData
        saveCardToSwiftData()

        showShareSheet = true
    }

    // MARK: - SwiftData Persistence

    private func saveCardToSwiftData() {
        let card = SavedCard(
            verseReference: verseReference,
            verseText: verseText,
            templateID: selectedTemplate.id
        )
        modelContext.insert(card)

        if let profile = profiles.first {
            profile.totalCardsCreated += 1
        }
        try? modelContext.save()
    }
}

// MARK: - Share Sheet

struct ShareSheetView: UIViewControllerRepresentable {
    let image: UIImage

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    CardCreatorView(
        verseReference: "Psalm 46:1",
        verseText: "God is our refuge and strength, a very present help in trouble."
    )
    .modelContainer(for: [SavedCard.self, UserProfile.self])
}
