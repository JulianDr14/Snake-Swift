import SwiftUI

struct AnimatedBackground: View {
    var body: some View {
        AngularGradient(colors: [
            Color(#colorLiteral(red: 0.133, green: 0.141, blue: 0.176, alpha: 1)), // deep gray
            Color(#colorLiteral(red: 0.035, green: 0.302, blue: 0.231, alpha: 1)), // dark green
            Color(#colorLiteral(red: 0.058, green: 0.447, blue: 0.304, alpha: 1)), // mid green
            Color(#colorLiteral(red: 0.0, green: 0.152, blue: 0.098, alpha: 1))   // near-black green
        ], center: .center)
        .opacity(0.9)
    }
}
