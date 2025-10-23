import SwiftUI

struct AIPanelSheet: View {
    @Binding var speed: Double        // engine speed (smaller = faster)
    let minVel: Double
    let maxVel: Double
    let step: Double                  // engine step size
    let steps: Int                    // number of UI levels
    @Binding var selectedAlgorithm: SearchAlgorithm
    @Binding var colorMode: Bool
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(.white.opacity(0.25))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 6)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    algorithmPicker
                    Toggle("Color Mode", isOn: $colorMode)
                    speedSlider
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
                .padding(.top, 4)
            }
            .frame(maxHeight: 280)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.2), radius: 14, x: 0, y: 8)
        )
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

private extension AIPanelSheet {
    var header: some View {
        HStack {
            Label("AI Settings", systemImage: "gearshape.2.fill")
                .font(.headline)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "chevron.down")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(6)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    var algorithmPicker: some View {
        Picker("Algorithm", selection: $selectedAlgorithm) {
            ForEach(SearchAlgorithm.allCases, id: \.self) { algo in
                Text(algo.rawValue).tag(algo)
            }
        }
        .pickerStyle(.segmented)
    }

    var speedSlider: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Speed Level").font(.subheadline)
                Spacer()
                Text("Level \(uiLevel)/\(steps)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Slider(
                value: Binding<Double>(
                    get: { Double(uiLevel) },
                    set: { newValue in
                        let level = min(max(Int(newValue.rounded()), 1), steps)
                        speed = SpeedLevelMapper.engineSpeed(
                            forLevel: level,
                            minVelocity: minVel,
                            maxVelocity: maxVel,
                            step: step,
                            steps: steps
                        )
                    }
                ),
                in: 1 ... Double(steps),
                step: 1
            ) {
                Text("Speed Level")
            } minimumValueLabel: {
                Text("Slow")
            } maximumValueLabel: {
                Text("Fast")
            }
        }
    }

    var uiLevel: Int {
        SpeedLevelMapper.level(
            for: speed,
            minVelocity: minVel,
            maxVelocity: maxVel,
            step: step,
            steps: steps
        )
    }
}
