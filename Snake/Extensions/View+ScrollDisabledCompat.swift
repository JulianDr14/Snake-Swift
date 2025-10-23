import SwiftUI

extension View {
    @ViewBuilder
    func scrollDisabledCompat(_ disabled: Bool) -> some View {
        if #available(iOS 16.0, *) {
            self.scrollDisabled(disabled)
        } else {
            self
        }
    }
}
