import SwiftUI

struct HUDBadge: View {
    let text: String
    let systemImage: String
    var tint: Color = .white

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.title3.weight(.semibold))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.25), lineWidth: 1))
            .foregroundStyle(tint)
            .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}
