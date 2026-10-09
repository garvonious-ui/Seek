import SwiftUI

/// "Your week is ready" card on Home — Sunday noon through Tuesday.
struct WeeklyRecapTile: View {
    let summary: WeeklySummary
    let onOpen: () -> Void
    let onDismiss: () -> Void

    private let sage = Color(hex: "5B7B5E")

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            miniCard

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text("YOUR WEEK IS READY")
                        .font(.caption2.weight(.semibold))
                        .tracking(1.5)
                        .foregroundStyle(Color(hex: "7A5C17"))
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color(hex: "9CA3AF"))
                            .frame(width: 28, height: 28)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, -6)
                    .padding(.trailing, -6)
                    .accessibilityLabel("Dismiss weekly recap")
                }

                Text(headline)
                    .font(.headline)
                    .foregroundStyle(Color(hex: "1A1A1A"))
                    .fixedSize(horizontal: false, vertical: true)

                Text(summary.dateRange)
                    .font(.footnote)
                    .foregroundStyle(Color(hex: "6B7280"))

                Button(action: onOpen) {
                    Label("View & share", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .frame(minHeight: 36)
                        .foregroundStyle(.white)
                        .background(sage, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    private var headline: String {
        let days = "\(summary.daysActive) \(summary.daysActive == 1 ? "day" : "days") in the Word"
        guard summary.versesExplored > 0 else { return days }
        return "\(days), \(summary.versesExplored) \(summary.versesExplored == 1 ? "verse" : "verses") explored"
    }

    private var miniCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(summary.daysActive)")
                .font(.custom("Georgia", size: 26))
                .foregroundStyle(Color(hex: "1A1A1A"))
            Text(summary.daysActive == 1 ? "day" : "days")
                .font(.system(size: 9))
                .foregroundStyle(Color(hex: "6B7280"))
            Spacer(minLength: 0)
            HStack(spacing: 2) {
                ForEach(Array(summary.activeDays.enumerated()), id: \.offset) { _, active in
                    Capsule()
                        .fill(active ? sage : Color(hex: "DDE1D8"))
                        .frame(height: 5)
                }
            }
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 8)
        .frame(width: 66, height: 104, alignment: .leading)
        .background(Color(hex: "FAF7F0"))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color(hex: "ECE6D6"), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityHidden(true)
    }
}

#Preview {
    WeeklyRecapTile(summary: .sample, onOpen: {}, onDismiss: {})
        .padding()
        .background(Color(hex: "FAFAF6"))
}
