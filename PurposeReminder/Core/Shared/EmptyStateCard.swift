import SwiftUI

struct EmptyStateCard: View {
    let iconName: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
