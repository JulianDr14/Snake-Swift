import SwiftUI

struct HUDOverlay: View {
    let isPaused: Bool
    let isGameOver: Bool
    var onRestart: () -> Void

    var body: some View {
        ZStack {
            if isPaused {
                HUDBadge(text: "Paused", systemImage: "pause.circle.fill")
            }

            if isGameOver {
                VStack(spacing: 12) {
                    HUDBadge(text: "Game Over", systemImage: "xmark.octagon.fill", tint: .red)
                    Button(action: onRestart) {
                        Label("Restart", systemImage: "arrow.clockwise.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}
