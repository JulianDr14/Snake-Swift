//
//  GameModel.swift
//  Snake
//
//  Created by Julian David Rodriguez on 16/04/25.
//

import Foundation
import Combine
import UIKit

// MARK: - Position in the grid
typealias Position = GridPosition

enum Directions {
    case up, down, left, right
    
    func isOpposite(of other: Directions) -> Bool {
        switch (self, other) {
        case (.left,  .right),
            (.right, .left),
            (.up,    .down),
            (.down,  .up):
            return true
        default:
            return false
        }
    }
}

extension Notification.Name {
    static let snakeDidWin = Notification.Name("snakeDidWin")
}

struct AIResult {
    let nextMove: Position?
    let visited: [Position]
    let pathToFood: [Position]
    let pathToTail: [Position]
}

enum SearchAlgorithm: String, CaseIterable, Identifiable {
    case astar   = "A*"
    case dijkstra = "Dijkstra"
    
    var id: String { rawValue }
}

// MARK: - Game model
final class GameModel: NSObject, ObservableObject {
    // MARK: – Configuración de la cuadrícula
    let rows: Int
    let columns: Int
    
    // MARK: – State of the game
    @Published private(set) var snake: [Position]
    @Published private(set) var food: Position
    @Published private(set) var isGameOver: Bool = false
    @Published private(set) var currentDirection: Directions = .right
    
    // MARK: – Control parameters
    @Published var speed: TimeInterval = 0.2
    @Published var isPaused: Bool = true
    @Published var isIAMode: Bool = false
    @Published var selectedAlgorithm: SearchAlgorithm = .astar
    
    // MARK: – Color mode (IA debug)
    @Published var colorMode: Bool = true
    @Published private(set) var colorVisited: [Position] = []
    @Published private(set) var colorToFood: [Position] = []
    @Published private(set) var colorToTail: [Position] = []
    
    // MARK: – AI and timer
    private let ai: SnakeAI
    
    // MARK: – Game loop
    private var displayLink: CADisplayLink?
    private var accumulator: TimeInterval = 0
    private var tick: TimeInterval { speed }
    
    // MARK: – Initialization/destruction
    init(rows: Int, columns: Int, initialSnake: [Position]) {
        self.rows = rows
        self.columns = columns
        self.snake = initialSnake
        self.food = GameModel.placeRandomFood(
            rows: rows,
            columns: columns,
            excluding: initialSnake
        )
        self.ai = SnakeAI(rows: rows, columns: columns)
    }
    
    deinit {
        stopGameLoop()
    }
    
    // MARK: - Game loop
    func startGameLoop() {
        if let link = displayLink {
            link.isPaused = false
            return
        }
        // If there is no link, create it
        accumulator = 0
        displayLink = CADisplayLink(target: self, selector: #selector(step(link:)))
        displayLink?.preferredFrameRateRange = .init(minimum: 30,
                                                     maximum: 120,
                                                     preferred: 60)
        displayLink?.add(to: .main, forMode: .default)
    }
    
    func stopGameLoop() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    // MARK: - Internal logic
    @objc private func step(link: CADisplayLink) {
        accumulator += link.targetTimestamp - link.timestamp
        while accumulator >= tick {
            if isIAMode {
                advanceSnakeIA()
            } else {
                manualMovementSnake()
            }
            accumulator -= tick
        }
    }
    
    // MARK: – Pause/Continue Control
    func pauseGame() {
        isPaused = true
        displayLink?.isPaused = true
    }
    
    func resumeGame() {
        isPaused = false
        // If it already exists, just resume it; if not, create it again
        if let link = displayLink {
            link.isPaused = false
        } else {
            startGameLoop()
        }
    }
    
    func resetGame() {
        snake = [Position(row: 0, col: 0), Position(row: 0, col: 1), Position(row: 0, col: 2)]
        food = GameModel.placeRandomFood(rows: rows, columns: columns, excluding: snake)
        isGameOver = false
        currentDirection = .right
        clearColor()
        startGameLoop()
    }
    
    func changeGameMode() {
        isIAMode.toggle()
        
        // If we just exited AI mode, we adjust the direction
        if !isIAMode {
            // 1) Make sure we have at least two segments
            guard snake.count >= 2 else {
                clearColor()
                return
            }
            
            // 2) Get the head and "neck" (second-to-last segment)
            let head = snake.last!
            let neck = snake[snake.count - 2]
            
            // 3) Calculate actual direction based on row/column difference
            let actualDir: Directions
            if head.row > neck.row {
                actualDir = .down
            } else if head.row < neck.row {
                actualDir = .up
            } else if head.col > neck.col {
                actualDir = .right
            } else {
                actualDir = .left
            }
            
            // 4) Sync it: if currentDirection was opposite, adjust it
            if currentDirection.isOpposite(of: actualDir) {
                currentDirection = actualDir
            }
            
            // 5) Clear debug colors
            clearColor()
        }
    }
    
    func changeDirection(to newDir: Directions) {
        // Ignore the change if it is 180°
        guard !newDir.isOpposite(of: currentDirection) else { return }
        currentDirection = newDir
    }
    
    // MARK: - Movimiento de la serpiente
    private func manualMovementSnake() {
        // 1. Get the current head of the snake
        let head = snake.last!
        let newHead: Position
        
        // 2. Calculate the new head position based on the current direction
        switch currentDirection {
        case .up:
            newHead = Position(row: head.row - 1, col: head.col)
        case .down:
            newHead = Position(row: head.row + 1, col: head.col)
        case .left:
            newHead = Position(row: head.row, col: head.col - 1)
        case .right:
            newHead = Position(row: head.row, col: head.col + 1)
        }
        
        // 3. Check for collisions
        guard newHead.row >= 0, newHead.row < rows,
              newHead.col >= 0, newHead.col < columns,
              !snake.contains(newHead)
        else {
            gameOver()
            return
        }
        
        // 4. Add the new head to the snake
        snake.append(newHead)
        
        // 5. Check if the snake eats food
        if newHead == food {
            food = GameModel.placeRandomFood(rows: rows, columns: columns, excluding: snake)
        } else {
            snake.removeFirst()
        }
    }
    
    // MARK: - Snake movement with pathfinding
    private func advanceSnakeIA() {
        let result = ai.calculateMove(
            snake: snake,
            food: food,
            algorithm: selectedAlgorithm
        )
        
        // Assign @Published so that the UI is painted
        colorVisited    = result.visited
        colorToFood     = result.pathToFood
        colorToTail     = result.pathToTail
        
        // Move the snake
        guard let next = result.nextMove else {
            gameOver()
            return
        }
        
        let grows = (next == food)
        let oldTail = snake.first!
        
        if snake.contains(next) && !(next == oldTail && !grows) {
            gameOver()
            return
        }
        
        snake.append(next)
        if grows {
            food = GameModel.placeRandomFood(rows: rows, columns: columns, excluding: snake)
            clearColor()
        } else {
            snake.removeFirst()
        }
    }
    
    private func gameOver() {
        isGameOver = true
        isPaused = true
        stopGameLoop()
    }
    
    // MARK: - Random Food
    private static func placeRandomFood(
        rows: Int,
        columns: Int,
        excluding snake: [Position]
    ) -> Position {
        // All cells
        let all = (0..<rows).flatMap { r in
            (0..<columns).map { c in Position(row: r, col: c) }
        }
        // Those not occupied by the snake
        let free = all.filter { !snake.contains($0) }
        
        // If none are free: victory!
        guard let next = free.randomElement() else {
            // Post notification
            NotificationCenter.default.post(name: .snakeDidWin, object: nil)
            // Returns any valid value
            return snake.last!
        }
        
        return next
    }
    
    // MARK: - Color
    private func clearColor() {
        colorVisited = []
        colorToFood = []
        colorToTail = []
    }
}
