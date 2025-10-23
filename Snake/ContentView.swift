//  ContentView.swift
//  Snake
//
//  Created by Julian David Rodriguez on 16/04/25.
//

import SwiftUI

struct ContentView: View {
    // MARK: - Game State
    @StateObject private var model = GameModel(
        rows: 17,
        columns: 17,
        initialSnake: [
            GridPosition(row: 0, col: 0),
            GridPosition(row: 0, col: 1),
            GridPosition(row: 0, col: 2)
        ]
    )

    // MARK: - UI State
    @State private var showIAPanel = false
    @State private var showVictoryAlert = false

    // Speed semantics (engine): smaller = faster
    let steps = 10
    let minVel = 0.01   // fastest (engine)
    let maxVel = 0.5    // slowest (engine)
    var step: Double { (maxVel - minVel) / Double(steps - 1) }

    private let swipeThreshold: CGFloat = 20

    // Tracks when user is dragging on the board (to disable parent scroll)
    @GestureState private var isDraggingBoard = false

    var body: some View {
        ZStack {
            animatedBackground
                .ignoresSafeArea()

            // Scrollable main content
            ScrollView {
                VStack(spacing: 16) {
                    header
                    scoreboard   // adaptive (LazyVGrid)

                    // MARK: - Board + Gestures (square & responsive)
                    ZStack {
                        GameBoard(model: model)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(.ultraThinMaterial)
                            )
                            .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 8)
                            .contentShape(Rectangle())
                            // Give board gesture high priority & disable parent scroll while dragging
                            .highPriorityGesture(
                                DragGesture(minimumDistance: swipeThreshold)
                                    .updating($isDraggingBoard) { _, state, _ in
                                        state = true
                                    }
                                    .onEnded { value in
                                        let dx = value.translation.width
                                        let dy = value.translation.height
                                        if abs(dx) > abs(dy) {
                                            model.changeDirection(to: dx > 0 ? .right : .left)
                                        } else {
                                            model.changeDirection(to: dy > 0 ? .down : .up)
                                        }
                                    }
                            )

                        // HUD: Pause / Game Over
                        if model.isPaused {
                            HUDBadge(text: "Paused", systemImage: "pause.circle.fill")
                        }
                        if model.isGameOver {
                            VStack(spacing: 12) {
                                HUDBadge(text: "Game Over", systemImage: "xmark.octagon.fill", tint: .red)
                                Button(action: model.resetGame) {
                                    Label("Restart", systemImage: "arrow.clockwise.circle.fill")
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: model.isPaused)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: model.isGameOver)

                    // MARK: - Bottom controls
                    bottomControls

                    // Spacer so it doesn't collide with panel when open
                    Color.clear.frame(height: showIAPanel ? 12 : 0)
                }
                .padding(.vertical, 20)
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
            .scrollDisabledCompat(isDraggingBoard)
        }
        .onDisappear { model.stopGameLoop() }
        .onReceive(NotificationCenter.default.publisher(for: .snakeDidWin)) { _ in
            showVictoryAlert = true
        }
        .alert("🎉 Victory!", isPresented: $showVictoryAlert) {
            Button("Restart", action: model.resetGame)
            Button("Close", role: .cancel) { }
        } message: {
            Text("The snake has filled the board.")
        }
        // Close AI panel if you switch back to Manual from anywhere
        .onChange(of: model.isIAMode) { newValue in
            if !newValue {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                    showIAPanel = false
                }
            }
        }
        // AI bottom sheet inside safe area + handle to reopen
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Group {
                if showIAPanel {
                    AIPanelSheet(
                        speed: $model.speed,
                        minVel: minVel,
                        maxVel: maxVel,
                        step: step,
                        steps: steps,
                        selectedAlgorithm: $model.selectedAlgorithm,
                        colorMode: $model.colorMode,
                        onClose: {
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                                showIAPanel = false
                            }
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if model.isIAMode {
                    // Handle to reopen panel without changing mode
                    IAPanelOpener {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                            showIAPanel = true
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
}

// MARK: - UI Sections
private extension ContentView {
    var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 6) {

                // Title row: Title + Los Andes logo
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("SNAKE")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Image("iconAndes")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 30)
                        .foregroundStyle(LinearGradient(
                            colors: [.white, .white.opacity(0.6)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
                        .accessibilityLabel("University of the Andes logo")

                }

                Text("Educational project · AI integration")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))

                Text("University of the Andes · 2025")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            // AI button: toggles panel; if AI is off, turns it on and opens panel
            Button {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    if showIAPanel {
                        showIAPanel = false
                    } else {
                        if !model.isIAMode { model.changeGameMode() }
                        showIAPanel = true
                    }
                }
            } label: {
                Label(model.isIAMode ? "AI" : "Manual", systemImage: "cpu")
                    .font(.headline)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(
                        Capsule().stroke(.white.opacity(0.12), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // Responsive scoreboard
    var scoreboard: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
            MetricCard(title: "Score", value: "\(model.score)", icon: "trophy.fill")
            MetricCard(title: "Speed", value: "Level \(currentSpeedLevel(model.speed))/\(steps)", icon: "speedometer")
            MetricCard(title: "Mode", value: model.isIAMode ? "AI" : "Manual", icon: model.isIAMode ? "cpu" : "gamecontroller.fill")
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: model.isIAMode)
    }

    var bottomControls: some View {
        HStack(spacing: 12) {
            // Play/Pause
            Button {
                if model.isPaused { model.resumeGame() } else { model.pauseGame() }
            } label: {
                Label(model.isPaused ? "Resume" : "Pause",
                      systemImage: model.isPaused ? "play.fill" : "pause.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryCapsuleStyle())

            // Restart
            Button(role: .none) { model.resetGame() } label: {
                Label("Restart", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryCapsuleStyle())
        }
    }

    var animatedBackground: some View {
        AngularGradient(colors: [
            Color(#colorLiteral(red: 0.133, green: 0.141, blue: 0.176, alpha: 1)), // deep gray
            Color(#colorLiteral(red: 0.035, green: 0.302, blue: 0.231, alpha: 1)), // dark green
            Color(#colorLiteral(red: 0.058, green: 0.447, blue: 0.304, alpha: 1)), // mid green
            Color(#colorLiteral(red: 0.0, green: 0.152, blue: 0.098, alpha: 1))   // near-black green
        ], center: .center)
        .opacity(0.9)
    }

    // Helper: Convert engine speed (smaller=faster) to UI level (1…steps, higher=faster)
    func currentSpeedLevel(_ engineSpeed: Double) -> Int {
        let raw = (maxVel - engineSpeed) / step
        let level = Int(round(raw)) + 1
        return min(max(level, 1), steps)
    }
}

// MARK: - Reusable components
private struct MetricCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .imageScale(.large)
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
                Text(value)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct HUDBadge: View {
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

private struct PrimaryCapsuleStyle: ButtonStyle {
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

private struct SecondaryCapsuleStyle: ButtonStyle {
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

// MARK: - Optional Control Pad (for accessibility)
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

// MARK: - AI Panel (bottom sheet)
private struct AIPanelSheet: View {
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
            // Grab handle
            Capsule()
                .fill(.white.opacity(0.25))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 6)

            // Scrollable panel content
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
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

                    Picker("Algorithm", selection: $selectedAlgorithm) {
                        ForEach(SearchAlgorithm.allCases, id: \.self) { algo in
                            Text(algo.rawValue).tag(algo)
                        }
                    }
                    .pickerStyle(.segmented)

                    Toggle("Color Mode", isOn: $colorMode)

                    // Speed Level UI (1…steps, higher = faster)
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Speed Level").font(.subheadline)
                            Spacer()
                            Text("Level \(uiLevel)/\(steps)")
                                .font(.subheadline).foregroundStyle(.white.opacity(0.8))
                        }

                        Slider(
                            value: Binding<Double>(
                                get: { Double(uiLevel) },
                                set: { newVal in
                                    let level = min(max(Int(newVal.rounded()), 1), steps)
                                    // Map UI level -> engine speed (smaller = faster)
                                    // level 1 (slowest) -> speed = maxVel
                                    // level steps (fastest) -> speed = minVel
                                    speed = maxVel - (Double(level - 1) * step)
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
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
                .padding(.top, 4)
            }
            .frame(maxHeight: 280) // Max sheet height
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.2), radius: 14, x: 0, y: 8)
        )
        .padding(.horizontal)
        .padding(.bottom, 8) // breathe over home indicator
    }

    // Derived UI level from engine speed
    private var uiLevel: Int {
        let raw = (maxVel - speed) / step
        let level = Int(raw.rounded()) + 1
        return min(max(level, 1), steps)
    }
}

// MARK: - Handle to open the AI panel when AI is active
private struct IAPanelOpener: View {
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

// MARK: - iOS 16 compatibility helper
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

// MARK: - Preview
#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}

