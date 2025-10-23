import SwiftUI

struct PrimaryCapsuleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 12)
            .background(
                Capsule().fill(.tint)
            )
            .foregroundStyle(.white)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SecondaryCapsuleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 12)
            .background(
                Capsule().fill(.ultraThinMaterial)
            )
            .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 1))
            .foregroundStyle(.white)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
