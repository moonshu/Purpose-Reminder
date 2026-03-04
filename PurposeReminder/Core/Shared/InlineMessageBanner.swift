import SwiftUI

enum InlineMessageStyle {
    case info
    case success
    case warning
    case error

    var iconName: String {
        switch self {
        case .info:
            return "info.circle.fill"
        case .success:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.octagon.fill"
        }
    }

    var tint: Color {
        switch self {
        case .info:
            return .blue
        case .success:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        }
    }
}

struct InlineMessageBanner: View {
    let text: String
    let style: InlineMessageStyle

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: style.iconName)
                .foregroundStyle(style.tint)
                .font(.subheadline)

            Text(text)
                .font(.footnote)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(style.tint.opacity(0.12))
        )
    }
}
