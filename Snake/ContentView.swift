//  ContentView.swift
//  Snake
//
//  Created by Julian David Rodriguez on 16/04/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var model = GameModel(
        rows: 17,
        columns: 17,
        initialSnake: [
            GridPosition(row: 0, col: 0),
            GridPosition(row: 0, col: 1),
            GridPosition(row: 0, col: 2)
        ]
    )
    
    @State private var showIAPanel = false
    @State private var showVictoryAlert = false
    
    let steps = 10
    let minVel = 0.01
    let maxVel = 0.5
    
    var step: Double {
        (maxVel - minVel) / Double(steps - 1)
    }
    
    
    private let swipeThreshold: CGFloat = 20
    
    var body: some View {
        VStack {
            cpuPanel
            
            ZStack {
                GameBoard(model: model)
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: swipeThreshold)
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
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            
            Button {
                if model.isPaused {
                    model.resumeGame()
                } else {
                    model.pauseGame()
                }
            } label: {
                Image(systemName: model.isPaused ? "play.fill" : "pause.fill")
                    .font(.largeTitle)
                    .padding()
            }
            
            if model.isGameOver {
                Text("¡Game Over!")
                    .font(.title)
                    .foregroundColor(.red)
                    .padding()
                Button("Reiniciar") { model.resetGame() }
                    .padding()
            }
        }
        .padding()
        .onAppear { model.startGameLoop() }
        .onDisappear { model.stopGameLoop() }
        .onReceive(NotificationCenter.default.publisher(for: .snakeDidWin)) { _ in
            showVictoryAlert = true
        }
        .alert("🎉 ¡Victoria!", isPresented: $showVictoryAlert) {
            Button("Reiniciar", action: model.resetGame)
            Button("Cerrar", role: .cancel) { }
        } message: {
            Text("La serpiente ha llenado todo el tablero.")
        }
    }
}

extension ContentView{
    var cpuPanel : some View {
        HStack(spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    model.changeGameMode()
                    showIAPanel.toggle()
                }
            } label: {
                Image(systemName: model.isIAMode ? "cpu" : "cpu")
                    .font(.system(size: 28))
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(
                                AnyShapeStyle(Color.gray.opacity(0.2))
                            )
                    )
                    .scaleEffect(model.isIAMode ? 1.1 : 1.0)
                    .animation(.easeInOut, value: model.isIAMode)
            }
            
            if showIAPanel {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("Algoritmo", selection: $model.selectedAlgorithm) {
                        ForEach(SearchAlgorithm.allCases) { algo in
                            Text(algo.rawValue).tag(algo)
                        }
                    }
                    .pickerStyle(.segmented)
                    Toggle("Color Mode", isOn: $model.colorMode)
                    Slider(value: $model.speed,
                           in: minVel ... maxVel,
                           step: step) {
                        Text("Velocidad")
                    } minimumValueLabel: {
                        Text("Rápido")
                    } maximumValueLabel: {
                        Text("Lento")
                    }
                }
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .transition(
                    .move(edge: .trailing)
                    .combined(with: .opacity)
                )
            }
        }
    }
}

#Preview{
    ContentView()
}
