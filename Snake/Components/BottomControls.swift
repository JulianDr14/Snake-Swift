import SwiftUI

struct BottomControls: View {
    let isPaused: Bool
    var onTogglePause: () -> Void
    var onRestart: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onTogglePause) {
                Label(isPaused ? "Resume" : "Pause",
                      systemImage: isPaused ? "play.fill" : "pause.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryCapsuleStyle())

            Button(action: onRestart) {
                Label("Restart", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryCapsuleStyle())
        }
    }
}
