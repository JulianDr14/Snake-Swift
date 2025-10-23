import SwiftUI

struct IAPanelOpener: View {
    var onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 8) {
                Image(systemName: "cpu")
                Text("AI Controls")
                    .fontWeight(.semibold)
                Image(systemName: "chevron.up")
            }
            .font(.subheadline)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 12)
                .onEnded { value in
                    if value.translation.height < -8 { // swipe up
                        onOpen()
                    }
                }
        )
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}
