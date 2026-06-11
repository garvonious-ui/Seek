import SwiftUI
import SwiftData
import Photos

struct CardCreatorView: View {
    let verseReference: String
    let verseText: String
    /// The AI "interpretation" of the verse (the context line shown in chat).
    /// Optional — present only when a card is created from a chat verse. When
    /// set, the user can toggle it onto the card.
    let verseContext: String?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var selectedTemplate = CardTemplate.all[0]
    @State private var isSaving = false
    @State private var showShareSheet = false
    @State private var renderedImage: UIImage?
    @State private var showSavedToast = false
    @State private var showPermissionAlert = false
    /// Whether to print the interpretation on the card. Defaults OFF so the
    /// card stays verse-first; the user opts in.
    @State private var includeInterpretation = false

    init(verseReference: String, verseText: String, verseContext: String? = nil, initialTemplateID: String? = nil) {
        self.verseReference = verseReference
        self.verseText = verseText
        self.verseContext = verseContext
        // Preselect the template the user originally picked when re-editing
        // a saved card from the library. Falls back to the first template if
        // the ID no longer exists or none was passed.
        let starting = initialTemplateID.flatMap { id in CardTemplate.all.first { $0.id == id } } ?? CardTemplate.all[0]
        self._selectedTemplate = State(initialValue: starting)
    }

    /// Creates a card from a prayer instead of a scripture verse. Reuses the
    /// verse-card templates with "A Prayer" as the reference line.
    init(prayerText: String) {
        self.verseReference = "A Prayer"
        self.verseText = prayerText
        self.verseContext = nil
        self._selectedTemplate = State(initialValue: CardTemplate.all[0])
    }

    /// The interpretation actually drawn on the card — nil unless the user has
    /// a context available and has toggled it on.
    private var activeInterpretation: String? {
        guard let verseContext, !verseContext.isEmpty, includeInterpretation else { return nil }
        return verseContext
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Card preview
                    cardPreview
                        .padding(.horizontal)
                        .padding(.top, 16)

                    // Template picker
                    templatePicker

                    // Interpretation toggle (only for chat verses)
                    interpretationToggle

                    // Actions
                    actionButtons
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                }
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
    //
    // Shares VerseCardView with the renderer + library thumbnail. Preview
    // size is computed to fit ~480pt tall while preserving 9:16 aspect.
    // Because VerseCardView scales all internals off renderSize.width, the
    // preview, the Library grid thumbnail, and the 1080x1920 PNG export are
    // all visually consistent — picking a template here = exactly what
    // saves to Photos.

    private var cardPreview: some View {
        let height: CGFloat = 480
        let width = height * (9.0 / 16.0)
        return VerseCardView(
            verseText: verseText,
            verseReference: verseReference,
            template: selectedTemplate,
            interpretation: activeInterpretation,
            renderSize: CGSize(width: width, height: height)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
    }

    // MARK: - Interpretation Toggle
    //
    // Only meaningful when the card came from a chat verse (we have the AI's
    // interpretation). Lets the user add that context line onto the card.

    @ViewBuilder
    private var interpretationToggle: some View {
        if let verseContext, !verseContext.isEmpty {
            Toggle(isOn: $includeInterpretation.animation(.easeInOut(duration: 0.2))) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Include interpretation")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color(hex: "1A1A1A"))
                    Text(verseContext)
                        .font(.caption)
                        .foregroundStyle(Color(hex: "6B7280"))
                        .lineLimit(2)
                }
            }
            .tint(Color(hex: "5B7B5E"))
            .padding(.horizontal)
        }
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
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTemplate = tmpl
                            }
                        } label: {
                            VStack(spacing: 4) {
                                VerseCardThumbnail(template: tmpl)
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
                template: selectedTemplate,
                interpretation: activeInterpretation
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
        // Remember the interpretation only when it was actually printed on the
        // card, so a Library re-render reproduces the same card.
        card.contextNote = activeInterpretation
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
