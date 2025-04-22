//
//  SnakeAI.swift
//  Snake
//
//  Created by Julian David Rodriguez on 22/04/25.
//

final class SnakeAI {
    let rows: Int
    let columns: Int
    
    init(rows: Int, columns: Int) {
        self.rows = rows
        self.columns = columns
    }
    
    func calculateMove(snake: [Position],
                       food: Position,
                       algorithm: SearchAlgorithm) -> AIResult {
        let head = snake.last!
        let tail = snake.first!
        
        // 1) Shortest path to food and visited nodes
        let (pathFood, visited): ([Position],[Position]) = {
            switch algorithm {
            case .astar:
                return astarPath(from: head, to: food, blocked: Set(snake).subtracting([tail]))
            case .dijkstra:
                return dijkstraPath(from: head, to: food, blocked: Set(snake).subtracting([tail]))
            }
        }()
        
        // If the snake occupies SO MANY squares that only food remains...
        let totalCells = rows * columns
        if snake.count == totalCells - 1 {
            // Goes straight to the food without further validation
            return AIResult(
                nextMove: step(in: pathFood),
                visited: visited,
                pathToFood: pathFood,
                pathToTail: [],
                activePath: pathFood
            )
        }
        
        // 2) If you can eat and then get to the queue, that is the active route
        if !pathFood.isEmpty, canEatAndReachTail(via: pathFood, snake: snake) {
            return AIResult(
                nextMove: step(in: pathFood),
                visited: visited,
                pathToFood: pathFood,
                pathToTail: [],
                activePath: pathFood
            )
        }
        
        // 3) If not, find the longest path to the queue
        let blockedForLongest = Set(snake).subtracting([head, tail])
        let pathLongest = longestPathDFS(from: head, to: tail, blocked: blockedForLongest)
        if pathLongest.count > 1 {
            return AIResult(
                nextMove: step(in: pathLongest),
                visited: visited,
                pathToFood: [],
                pathToTail: pathLongest,
                activePath: pathLongest
            )
        }
        
        // 4) Last resort: a free neighbor
        let freeNeighbors = head.neighbors(rows: rows, columns: columns)
            .filter { !snake.contains($0) }
        if let move = freeNeighbors.first {
            let active = [head, move]
            return AIResult(
                nextMove: move,
                visited: visited,
                pathToFood: [],
                pathToTail: [],
                activePath: active
            )
        }
        
        // 5) No possible move
        return AIResult(
            nextMove: nil,
            visited: visited,
            pathToFood: [],
            pathToTail: [],
            activePath: []
        )
    }
    
    private func step(in path: [Position]) -> Position? {
        guard path.count >= 2 else { return nil }
        return path[1]
    }
    
    private func canEatAndReachTail(via pathToFood: [Position], snake: [Position] ) -> Bool {
        var simSnake = snake
        for pos in pathToFood.dropFirst() { simSnake.append(pos) }
        let simTail = simSnake.first!
        let headAfter = simSnake.last!
        let blockedAfter = Set(simSnake).subtracting([simTail])
        let (pathAfter, _) = dijkstraPath(from: headAfter, to: simTail, blocked: blockedAfter)
        return !pathAfter.isEmpty
    }
    
    // MARK: - Search Algorithms
    // MARK: - Dijkstra Pathfinding
    private func dijkstraPath(from start: Position, to goal: Position, blocked: Set<Position>) -> ([Position], [Position]) {
        var dist: [Position: Int] = [start: 0]
        var prev: [Position: Position] = [:]
        var visited: [Position] = []
        var queue: [(Position, Int)] = [(start, 0)]
        
        while !queue.isEmpty {
            queue.sort { $0.1 < $1.1 }
            let (u, d) = queue.removeFirst()
            if visited.contains(u) { continue }
            visited.append(u)
            if u == goal { break }
            for v in u.neighbors(rows: rows, columns: columns) where !blocked.contains(v) {
                let nd = d + 1
                if nd < dist[v] ?? .max {
                    dist[v] = nd
                    prev[v] = u
                    queue.append((v, nd))
                }
            }
        }
        
        var path: [Position] = []
        var current = goal
        while let p = prev[current] {
            path.insert(current, at: 0)
            current = p
        }
        if current == start { path.insert(start, at: 0) }
        return (path, visited)
    }
    
    // MARK: - Pathfinding A*
    private func astarPath(from start: Position,
                           to goal: Position,
                           blocked: Set<Position>) -> ([Position], [Position]) {
        var openSet: Set<Position> = [start]
        var cameFrom: [Position: Position] = [:]
        var gScore: [Position: Int] = [start: 0]
        var fScore: [Position: Int] = [start: heuristic(start, goal)]
        var visited: [Position] = []
        
        while !openSet.isEmpty {
            // 1. Extract node with lowest fScore
            let current = openSet.min { (p1, p2) -> Bool in
                (fScore[p1] ?? .max) < (fScore[p2] ?? .max)
            }!
            
            visited.append(current)
            
            // 2. If we arrive, rebuild the path
            if current == goal {
                var path: [Position] = []
                var nodo = goal
                while let prev = cameFrom[nodo] {
                    path.insert(nodo, at: 0)
                    nodo = prev
                }
                path.insert(start, at: 0)
                return (path, visited)
            }
            
            openSet.remove(current)
            
            // 3. Examine neighbors
            for neighbor in current.neighbors(rows: rows, columns: columns) where !blocked.contains(neighbor) {
                let tentativeG = (gScore[current] ?? .max) + 1
                if tentativeG < (gScore[neighbor] ?? .max) {
                    // Best route found
                    cameFrom[neighbor] = current
                    gScore[neighbor] = tentativeG
                    fScore[neighbor] = tentativeG + heuristic(neighbor, goal)
                    openSet.insert(neighbor)
                }
            }
        }
        
        // If there is no way
        return ([], visited)
    }
    
    private func heuristic(_ a: Position, _ b: Position) -> Int {
        return abs(a.row - b.row) + abs(a.col - b.col)
    }
    
    // MARK: - Longer path via DFS and stretching
    private func longestPathDFS(from start: Position, to goal: Position, blocked: Set<Position>) -> [Position] {
        let (shortest, _) = dijkstraPath(from: start, to: goal, blocked: blocked)
        guard shortest.count > 1 else { return shortest }
        
        var path = shortest
        var occupied = blocked
        occupied.formUnion(path)
        
        func libre(_ p: Position) -> Bool {
            return p.row >= 0 && p.row < rows && p.col >= 0 && p.col < columns && !occupied.contains(p)
        }
        
        var inserted = true
        while inserted {
            inserted = false
            var i = 0
            while i < path.count - 1 {
                let u = path[i], v = path[i + 1]
                // Stretch straight segments
                if u.row == v.row {
                    let candidates = [
                        (GridPosition(row: u.row - 1, col: u.col), GridPosition(row: v.row - 1, col: v.col)),
                        (GridPosition(row: u.row + 1, col: u.col), GridPosition(row: v.row + 1, col: v.col))
                    ]
                    for (a, b) in candidates where libre(a) && libre(b) && abs(a.col - b.col) == 1 {
                        path.insert(a, at: i + 1); path.insert(b, at: i + 2)
                        occupied.insert(a); occupied.insert(b)
                        inserted = true; i += 2; break
                    }
                } else if u.col == v.col {
                    let candidates = [
                        (GridPosition(row: u.row, col: u.col - 1), GridPosition(row: v.row, col: v.col - 1)),
                        (GridPosition(row: u.row, col: u.col + 1), GridPosition(row: v.row, col: v.col + 1))
                    ]
                    for (a, b) in candidates where libre(a) && libre(b) && abs(a.row - b.row) == 1 {
                        path.insert(a, at: i + 1); path.insert(b, at: i + 2)
                        occupied.insert(a); occupied.insert(b)
                        inserted = true; i += 2; break
                    }
                }
                i += 1
            }
        }
        return path
    }
}
