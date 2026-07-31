import SwiftUI

struct NavRow: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(GVColors.accent)
                .frame(width: 24)
            Text(title)
                .font(GVTypography.callout)
                .foregroundStyle(GVColors.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(GVColors.textSecondary)
        }
        .padding(.vertical, 14)
    }
}
