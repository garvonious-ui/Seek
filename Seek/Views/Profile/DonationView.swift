import SwiftUI

struct DonationView: View {
    @Environment(\.openURL) private var openURL

    private let donationURL = URL(string: "https://buy.stripe.com/00w4gsfPm5whgJcbYJ0Ba00")!

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

                Button {
                    openURL(donationURL)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "heart")
                        Text("Support Seek")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "5B7B5E"))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
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
}

#Preview {
    NavigationStack {
        DonationView()
    }
}
