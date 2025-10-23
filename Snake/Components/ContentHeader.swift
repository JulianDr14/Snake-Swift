import SwiftUI

struct ContentHeader: View {
    let isIAMode: Bool
    let isPanelOpen: Bool
    var onToggleAIPanel: () -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 6) {
                headerTitle
                subtitle
            }

            Spacer()

            AIToggleButton(
                isIAMode: isIAMode,
                isPanelOpen: isPanelOpen,
                action: onToggleAIPanel
            )
        }
    }
}

private extension ContentHeader {
    var headerTitle: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("SNAKE")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image("iconAndes")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 30)
                    .foregroundStyle(LinearGradient(
                        colors: [.white, .white.opacity(0.6)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
                    .accessibilityLabel("University of the Andes logo")
            }
        }
    }

    var subtitle: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Educational project · AI integration")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))

            Text("University of the Andes · 2025")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}

private struct AIToggleButton: View {
    let isIAMode: Bool
    let isPanelOpen: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(isIAMode ? "AI" : "Manual", systemImage: "cpu")
                .font(.headline)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule().stroke(.white.opacity(0.12), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPanelOpen ? "Close AI panel" : "Open AI panel")
    }
}
