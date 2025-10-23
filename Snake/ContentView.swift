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
            AnimatedBackground()
                .ignoresSafeArea()

            // Scrollable main content
            ScrollView {
                VStack(spacing: 16) {
                    ContentHeader(
                        isIAMode: model.isIAMode,
                        isPanelOpen: showIAPanel,
                        onToggleAIPanel: handleAIPanelToggle
                    )

                    ScoreboardView(
                        score: model.score,
                        speedLevel: currentSpeedLevel(for: model.speed),
                        totalSpeedLevels: steps,
                        isIAMode: model.isIAMode
                    )

                    gameBoardSection

                    BottomControls(
                        isPaused: model.isPaused,
                        onTogglePause: handlePauseResume,
                        onRestart: model.resetGame
                    )

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

// MARK: - Private helpers
private extension ContentView {
    var gameBoardSection: some View {
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
                .highPriorityGesture(boardDragGesture)

            HUDOverlay(
                isPaused: model.isPaused,
                isGameOver: model.isGameOver,
                onRestart: model.resetGame
            )
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: model.isPaused)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: model.isGameOver)
    }

    var boardDragGesture: some Gesture {
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
    }

    func handlePauseResume() {
        if model.isPaused {
            model.resumeGame()
        } else {
            model.pauseGame()
        }
    }

    func handleAIPanelToggle() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            if showIAPanel {
                showIAPanel = false
            } else {
                if !model.isIAMode { model.changeGameMode() }
                showIAPanel = true
            }
        }
    }

    func currentSpeedLevel(for engineSpeed: Double) -> Int {
        SpeedLevelMapper.level(
            for: engineSpeed,
            minVelocity: minVel,
            maxVelocity: maxVel,
            step: step,
            steps: steps
        )
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
