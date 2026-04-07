import SwiftUI

struct CardCreatorView: View {
    let verseReference: String
    let verseText: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Card preview
                VStack(spacing: 16) {
                    Text(verseText)
                        .font(.custom("Georgia", size: 20))
                        .lineSpacing(6)
                        .multilineTextAlignment(.center)

                    Text("— \(verseReference)")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color(hex: "2C5F7C"))
                }
                .padding(32)
                .frame(maxWidth: .infinity)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                .padding(.horizontal)

                // Template picker placeholder
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<6) { i in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "2C5F7C").opacity(Double(i + 1) / 8.0))
                                .frame(width: 60, height: 80)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()

                // Actions
                HStack(spacing: 16) {
                    Button {
                        // Save card
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        // Share card
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "2C5F7C"))
                }
                .padding(.horizontal)
            }
            .padding(.top)
            .background(Color(hex: "FAFAF8"))
            .navigationTitle("Create Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    CardCreatorView(
        verseReference: "Psalm 46:1",
        verseText: "God is our refuge and strength, a very present help in trouble."
    )
}
