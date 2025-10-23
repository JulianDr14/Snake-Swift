import SwiftUI

struct ScoreboardView: View {
    let score: Int
    let speedLevel: Int
    let totalSpeedLevels: Int
    let isIAMode: Bool

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            MetricCard(title: "Score", value: "\(score)", icon: "trophy.fill")
            MetricCard(title: "Speed", value: "Level \(speedLevel)/\(totalSpeedLevels)", icon: "speedometer")
            MetricCard(title: "Mode", value: modeTitle, icon: modeIcon)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: isIAMode)
    }
}

private extension ScoreboardView {
    var modeTitle: String { isIAMode ? "AI" : "Manual" }
    var modeIcon: String { isIAMode ? "cpu" : "gamecontroller.fill" }
}
