import SwiftUI

/// Remote box art with a shipping-box placeholder while loading / on failure.
struct BoxArtImage: View {
    let urlString: String?
    var cornerRadius: CGFloat = 8

    var body: some View {
        Group {
            if let urlString, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    case .empty:
                        ZStack {
                            GVColors.surfaceSecondary
                            ProgressView()
                        }
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var placeholder: some View {
        ZStack {
            GVColors.surfaceSecondary
            Image(systemName: "shippingbox.fill")
                .foregroundStyle(GVColors.accent.opacity(0.5))
        }
    }
}
