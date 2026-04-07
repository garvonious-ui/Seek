import SwiftUI

struct LibraryView: View {
    @State private var selectedTab: LibraryTab = .cards

    enum LibraryTab: String, CaseIterable {
        case cards = "Cards"
        case favorites = "Favorites"
        case history = "History"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Library", selection: $selectedTab) {
                    ForEach(LibraryTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                // Tab content
                switch selectedTab {
                case .cards:
                    emptyState(icon: "rectangle.on.rectangle", title: "No cards yet", subtitle: "Create your first verse card from a scripture chat")
                case .favorites:
                    emptyState(icon: "heart", title: "No favorites yet", subtitle: "Heart a verse to save it here")
                case .history:
                    emptyState(icon: "clock", title: "No conversations yet", subtitle: "Start a scripture chat to see your history")
                }

                Spacer()
            }
            .background(Color(hex: "FAFAF8"))
            .navigationTitle("Library")
        }
    }

    private func emptyState(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: "2C5F7C").opacity(0.3))
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 80)
    }
}

#Preview {
    LibraryView()
}
