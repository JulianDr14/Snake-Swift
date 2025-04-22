//
//  ExtensionGrid.swift
//  Snake
//
//  Created by Julian David Rodriguez on 16/04/25.
//

import Foundation

// MARK: - GridPosition
struct GridPosition: Hashable {
    let row: Int
    let col: Int
}

extension GridPosition {
    func neighbors(rows: Int, columns: Int) -> [GridPosition] {
        var v: [GridPosition] = []
        if row > 0 { v.append(GridPosition(row: row - 1, col: col)) }
        if row < rows - 1 { v.append(GridPosition(row: row + 1, col: col)) }
        if col > 0 { v.append(GridPosition(row: row, col: col - 1)) }
        if col < columns - 1 { v.append(GridPosition(row: row, col: col + 1)) }
        return v
    }
}
