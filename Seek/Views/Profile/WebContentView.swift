import SwiftUI
import WebKit

struct WebContentView: View {
    let title: String
    let urlString: String

    var body: some View {
        Group {
            if let url = URL(string: urlString) {
                WebView(url: url)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Content unavailable")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.load(URLRequest(url: url))
    }
}

#Preview {
    NavigationStack {
        WebContentView(title: "Privacy Policy", urlString: "https://example.com")
    }
}
