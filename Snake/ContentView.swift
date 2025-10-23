//  ContentView.swift
//  Snake
//
//  Created by Julian David Rodriguez on 16/04/25.
//

import SwiftUI

struct ContentView: View {
    // MARK: - Estado del juego
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

    // Velocidad (usa semántica del modelo: menor = más rápido)
    let steps = 10
    let minVel = 0.01
    let maxVel = 0.5
    var step: Double { (maxVel - minVel) / Double(steps - 1) }

    private let swipeThreshold: CGFloat = 20

    var body: some View {
        ZStack {
            animatedBackground
                .ignoresSafeArea()

            VStack(spacing: 16) {
                header

                scoreboard

                // MARK: - Tablero + Gestos
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

                    // HUD: Pausa / Game Over
                    if model.isPaused {
                        HUDBadge(text: "Pausado", systemImage: "pause.circle.fill")
                    }
                    if model.isGameOver {
                        VStack(spacing: 12) {
                            HUDBadge(text: "Game Over", systemImage: "xmark.octagon.fill", tint: .red)
                            Button(action: model.resetGame) {
                                Label("Reiniciar", systemImage: "arrow.clockwise.circle.fill")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
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
                .frame(maxWidth: .infinity)
                .frame(height: 420)
                .padding(.horizontal)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: model.isPaused)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: model.isGameOver)

                // MARK: - Controles inferiores
                bottomControls

                // Panel IA
                if showIAPanel { aiPanel.transition(.move(edge: .bottom).combined(with: .opacity)) }
            }
            .padding(.vertical, 20)
            .padding(.horizontal)
        }
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

// MARK: - Secciones UI
private extension ContentView {
    var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("SNAKE")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(LinearGradient(colors: [.white, .white.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                Text("Educational project · AI Integration")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
                Text("Universidad de los Andes · 2025")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            // Botón modo IA (toggle)
            Button {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                    model.changeGameMode()
                    showIAPanel.toggle()
                }
            } label: {
                Label(model.isIAMode ? "IA" : "Manual", systemImage: "cpu")
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

    var scoreboard: some View {
        HStack(spacing: 12) {
            MetricCard(title: "Puntaje", value: "\(model.score)", icon: "trophy.fill")
            MetricCard(title: "Velocidad", value: String(format: "%.2f", model.speed), icon: "speedometer")
            MetricCard(title: "Modo", value: model.isIAMode ? "IA" : "Manual", icon: model.isIAMode ? "cpu" : "gamecontroller.fill")
        }
    }

    var bottomControls: some View {
        HStack(spacing: 12) {
            // Play/Pause
            Button {
                if model.isPaused { model.resumeGame() } else { model.pauseGame() }
            } label: {
                Label(model.isPaused ? "Reanudar" : "Pausar",
                      systemImage: model.isPaused ? "play.fill" : "pause.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryCapsuleStyle())

            // Reiniciar
            Button(role: .none) { model.resetGame() } label: {
                Label("Reiniciar", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryCapsuleStyle())
        }
    }

    var aiPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("AI Settings", systemImage: "gearshape.2.fill")
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                        showIAPanel = false
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(6)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .buttonStyle(.plain)
            }

            Picker("Algoritmo", selection: $model.selectedAlgorithm) {
                ForEach(SearchAlgorithm.allCases, id: \.self) { algo in
                    Text(algo.rawValue).tag(algo)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Color Mode", isOn: $model.colorMode)

            VStack(alignment: .leading) {
                HStack {
                    Text("Velocidad").font(.subheadline)
                    Spacer()
                    Text(model.speed, format: .number.precision(.fractionLength(2)))
                        .font(.subheadline).foregroundStyle(.white.opacity(0.8))
                }
                Slider(value: $model.speed,
                       in: minVel ... maxVel,
                       step: step) {
                    Text("Velocidad")
                } minimumValueLabel: {
                    Text("Rápida")
                } maximumValueLabel: {
                    Text("Lenta")
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.2), radius: 14, x: 0, y: 8)
        )
    }

    var animatedBackground: some View {
        // Degradado que se desplaza sutilmente (ligero parallax)
        AngularGradient(colors: [
            Color(#colorLiteral(red: 0.133, green: 0.141, blue: 0.176, alpha: 1)), // gris profundo
            Color(#colorLiteral(red: 0.035, green: 0.302, blue: 0.231, alpha: 1)), // verde oscuro
            Color(#colorLiteral(red: 0.058, green: 0.447, blue: 0.304, alpha: 1)), // verde medio
            Color(#colorLiteral(red: 0.0, green: 0.152, blue: 0.098, alpha: 1))   // verde casi negro
        ], center: .center)
        .opacity(0.9)
    }
}

// MARK: - Componentes reutilizables
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

// MARK: - Control Pad opcional (para accesibilidad)
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

// MARK: - Preview
#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}

