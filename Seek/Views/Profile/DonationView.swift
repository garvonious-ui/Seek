import SwiftUI

struct DonationView: View {
    @Environment(\.openURL) private var openURL

    /// Fixed-amount Stripe Payment Links. Each URL is a separate link in
    /// Stripe pinned to one price — no quantity field shown to the donor,
    /// they tap and pay exactly that amount. Six amounts fill a clean 2x3
    /// grid so no single tier (e.g. $500) reads as visually heavier than
    /// the others.
    private let presets: [(amount: Int, url: URL)] = [
        (10,  URL(string: "https://buy.stripe.com/5kQaEQ8mU1g13WqaUF0Ba06")!),
        (25,  URL(string: "https://buy.stripe.com/28E5kw6eM5wh3WqgeZ0Ba04")!),
        (50,  URL(string: "https://buy.stripe.com/14A9AMcDa9Mx1Oi2o90Ba03")!),
        (100, URL(string: "https://buy.stripe.com/5kQ6oA1Yw0bXcsWd2N0Ba02")!),
        (250, URL(string: "https://buy.stripe.com/eVq4gsgTq9Mx1OiaUF0Ba07")!),
        (500, URL(string: "https://buy.stripe.com/5kQ6oA5aI7Ep1Oi8Mx0Ba01")!),
    ]

    /// Fallback for power users who want to give a custom amount. Opens the
    /// original $1 + adjustable-quantity link, where donors can type any
    /// number between 1 and 1000 (= $1 to $1000).
    private let customURL = URL(string: "https://buy.stripe.com/00w4gsfPm5whgJcbYJ0Ba00")!

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color(hex: "5B7B5E"))
                    .padding(.top, 16)

                Text("Built for the people of God,\nnot for profit.")
                    .font(.custom("Georgia", size: 30))
                    .foregroundStyle(Color(hex: "1A1A1A"))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Seek runs on real costs — servers, AI, the infrastructure that gets verses to your phone in a moment. It's funded entirely by people who find it useful.")
                        .foregroundStyle(Color(hex: "1A1A1A"))

                    Text("If Seek has met you somewhere, even once, a small gift keeps the lights on for the next person who needs it.")
                        .foregroundStyle(Color(hex: "1A1A1A"))
                }
                .font(.body)
                .lineSpacing(3)

                VStack(spacing: 12) {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                    ], spacing: 12) {
                        ForEach(presets, id: \.amount) { preset in
                            presetButton(amount: preset.amount, url: preset.url)
                        }
                    }

                    Button {
                        openURL(customURL)
                    } label: {
                        Text("Other amount →")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color(hex: "5B7B5E"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
                .padding(.top, 8)

                Text("Donations are processed securely by Stripe. They are not tax-deductible. Thank you for keeping Seek free for everyone.")
                    .font(.footnote)
                    .foregroundStyle(Color(hex: "6B7280"))
                    .lineSpacing(2)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(Color(hex: "FAFAF6"))
        .navigationTitle("Support Seek")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func presetButton(amount: Int, url: URL) -> some View {
        Button {
            openURL(url)
        } label: {
            Text("$\(amount)")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "5B7B5E"))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

#Preview {
    NavigationStack {
        DonationView()
    }
}
