//
//  GameBoard.swift
//  Snake
//
//  Created by Julian David Rodriguez on 16/04/25.
//

import SwiftUI

struct GameBoard: View {
    @ObservedObject var model: GameModel
    private let spacing: CGFloat = 8
    private let padding: CGFloat = 17
    
    var body: some View {
        GeometryReader { geo in
            let totalSpacing = spacing * CGFloat(model.columns - 1)
            let availableWidth = geo.size.width - 2 * padding
            let cellSize = (availableWidth - totalSpacing) / CGFloat(model.columns)
            let totalHeight = cellSize * CGFloat(model.rows) + spacing * CGFloat(model.rows - 1)
            
            ZStack {
                // —— Static layer ——
                StaticGridView(rows: model.rows,
                               columns: model.columns,
                               spacing: spacing,
                               padding: padding)
                
                // —— Dynamic Layer ——
                Canvas { ctx, size in
                    
                    // Helper to convert GridPosition → CGPoint
                    func center(_ g: GridPosition) -> CGPoint {
                        let x = padding + CGFloat(g.col) * (cellSize + spacing) + cellSize / 2
                        let y = padding + CGFloat(g.row) * (cellSize + spacing) + cellSize / 2
                        return .init(x: x, y: y)
                    }
                    
                    if model.colorMode {
                        for pos in model.colorVisited {
                            let c = center(pos)
                            let rect = CGRect(x: c.x - cellSize/2,
                                              y: c.y - cellSize/2,
                                              width: cellSize,
                                              height: cellSize)
                            ctx.fill(Path(ellipseIn: rect),
                                     with: .color(Color.blue.opacity(0.30)))
                        }
                    }
                    
                    // 1. Draw snake
                    for pos in model.snake {
                        let p = center(pos)
                        let rect = CGRect(x: p.x - cellSize/2,
                                          y: p.y - cellSize/2,
                                          width: cellSize,
                                          height: cellSize)
                        let color: Color =
                        pos == model.snake.last ? .green :
                        pos == model.snake.first ? .orange :
                            .green.opacity(0.5)
                        ctx.fill(Path(ellipseIn: rect), with: .color(color))
                    }
                    
                    // 2. Draw food
                    let foodCenter = center(model.food)
                    let foodRect = CGRect(x: foodCenter.x - cellSize/2,
                                          y: foodCenter.y - cellSize/2,
                                          width: cellSize,
                                          height: cellSize)
                    ctx.fill(Path(ellipseIn: foodRect), with: .color(.red))
                    
                    // 3. Paths
                    if model.colorMode {
                        func strokePath(_ positions: [GridPosition],
                                        color: Color) {
                            guard let first = positions.first else { return }
                            var path = Path()
                            path.move(to: center(first))
                            positions.dropFirst().forEach { path.addLine(to: center($0)) }
                            ctx.stroke(path,
                                       with: .color(color),
                                       style: .init(lineWidth: cellSize*0.4,
                                                    lineCap: .round))
                        }
                        strokePath(model.colorToFood,  color: .yellow.opacity(0.7))
                        strokePath(model.colorToTail,  color: .purple.opacity(0.6))
                    }
                }
            }
            .frame(width: geo.size.width, height: totalHeight + 2 * padding)
        }
    }
}

struct StaticGridView: View {
    let rows: Int
    let columns: Int
    let spacing: CGFloat
    let padding: CGFloat
    var body: some View {
        GeometryReader { geo in
            Canvas { ctx, size in
                let totalSpacing = spacing * CGFloat(columns - 1)
                let availableWidth = geo.size.width - 2 * padding
                let cellSize = (availableWidth - totalSpacing) / CGFloat(columns)
                let totalHeight = cellSize * CGFloat(rows) + spacing * CGFloat(rows - 1)
                
                let boardRect = CGRect(x: 0,
                                       y: 0,
                                       width: size.width,
                                       height: totalHeight + 2 * padding)
                ctx.fill(Path(roundedRect: boardRect,
                              cornerSize: CGSize(width: 12, height: 12)),
                         with: .color(Color.gray.opacity(0.1)))
                
                let dx = padding, dy = padding
                for row in 0..<rows {
                    for col in 0..<columns {
                        let origin = CGPoint(
                            x: dx + CGFloat(col) * (cellSize + spacing),
                            y: dy + CGFloat(row) * (cellSize + spacing))
                        let cell = CGRect(origin: origin,
                                          size: .init(width: cellSize, height: cellSize))
                        ctx.fill(Path(ellipseIn: cell), with: .color(.white))
                    }
                }
            }
        }
        .drawingGroup(opaque: true)
    }
}
