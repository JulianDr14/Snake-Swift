import SwiftUI

struct ControlPad: View {
    let onUp: () -> Void
    let onDown: () -> Void
    let onLeft: () -> Void
    let onRight: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button(action: onUp) { Image(systemName: "arrow.up") }
            HStack(spacing: 10) {
                Button(action: onLeft) { Image(systemName: "arrow.left") }
                Circle().fill(.clear).frame(width: 32, height: 32)
                Button(action: onRight) { Image(systemName: "arrow.right") }
            }
            Button(action: onDown) { Image(systemName: "arrow.down") }
        }
        .buttonStyle(.bordered)
        .labelStyle(.iconOnly)
        .controlSize(.large)
        .tint(.white.opacity(0.9))
    }
}
