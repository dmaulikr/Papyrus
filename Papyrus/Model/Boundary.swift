//
//  Boundary.swift
//  Papyrus
//
//  Created by Chris Nevin on 14/08/2015.
//  Copyright © 2015 CJNevin. All rights reserved.
//

import Foundation

typealias Boundaries = [Boundary]

struct Boundary: CustomDebugStringConvertible {
    let start: Position
    let end: Position
    var length: Int {
        return (end.iterable + 1) - start.iterable
    }
    var debugDescription: String {
        return "\(start.iterable),\(start.fixed) - \(end.iterable), \(end.fixed)"
    }
    /// - Returns: Whether this boundary appears to contain valid positions.
    var isValid: Bool {
        return start.fixed == end.fixed &&
            start.iterable <= end.iterable &&
            start.isHorizontal == end.isHorizontal
    }
    
    // TODO: Unit test this.
    /// - Returns: True if the axis and fixed values match and the iterable value intersects the given boundary.
    func iterableInsection(boundary: Boundary) -> Bool {
        // Check if same axis and same fixed value.
        if boundary.start.isHorizontal == start.isHorizontal &&
            boundary.start.fixed == start.fixed {
            // If they coexist on the same fixed line, check if there is any iterable intersection.
            return boundary.start.iterable < start.iterable && boundary.end.iterable >= end.iterable ||
                boundary.start.iterable <= start.iterable && boundary.end.iterable > end.iterable
        }
        return false
    }
    
    // TODO: Unit test this.
    /// - Returns: True if on adjacent fixed value and iterable seems to be in the same range.
    /// i.e. At least end position of the given boundary falls within the start-end range of this
    /// boundary. Or the start position of the given boundary falls within the start-end range
    /// of this boundary.
    func adjacentIntersection(boundary: Boundary) -> Bool {
        if boundary.start.isHorizontal == start.isHorizontal &&
            ((boundary.start.fixed + 1) == start.fixed ||
                (boundary.start.fixed - 1) == start.fixed) {
            return
                (boundary.start.iterable >= start.iterable &&
                    boundary.start.iterable <= end.iterable) ||
                (boundary.end.iterable > start.iterable &&
                    boundary.start.iterable <= start.iterable)
        }
        return false
    }
    
    // TODO: Unit test this.
    /// - Returns: True if the axis is different but the fixed or iterable values intersect.
    func oppositeIntersection(boundary: Boundary) -> Bool {
        if boundary.start.isHorizontal != start.isHorizontal {
            // TODO: Implement this.
        }
        return false
    }
    
    // TODO: Unit test this.
    /// - Returns: Whether the given row and column fall within this boundary.
    func encompasses(row: Int, column: Int) -> Bool {
        if start.isHorizontal {
            let sameRow = row == start.fixed && row == end.fixed
            let validColumn = column >= start.iterable && column <= end.iterable
            return sameRow && validColumn
        } else {
            let sameColumn = column == start.fixed && column == end.fixed
            let validRow = row >= start.iterable && row <= end.iterable
            return sameColumn && validRow
        }
    }
}

extension Papyrus {
    /// Get string value of letters in a given boundary.
    /// Does not currently check for gaps - use another method for gap checking and validation.
    func readable(boundary: Boundary) -> String? {
        let start = boundary.start, end = boundary.end
        if start.iterable >= end.iterable { return nil }
        return String((start.iterable...end.iterable).map({
            letterAt(start.isHorizontal, iterable: $0, fixed: start.fixed)}))
    }
    /// This method will be used by AI to determine location where play is allowed.
    /// - Parameter boundaries: Boundaries to use for intersection.
    /// - Returns: Areas where play may be possible intersecting the given boundaries.
    func findPlayableBoundaries(boundaries: Boundaries) -> Boundaries {
        var allBoundaries = Boundaries()
        for boundary in boundaries {
            assert(boundary.isValid)
            var currentBoundaries = Boundaries()
            let startPosition = getPositionLoop(boundary.start)
            let endPosition = getPositionLoop(boundary.end)
            let start = boundary.start
            let end = boundary.end
            for i in startPosition.iterable...endPosition.iterable {
                let s = i > start.iterable ? start.iterable : i
                let e = i < end.iterable ? end.iterable : i
                if e - s < 11 {
                    guard let iterationStart = Position.newPosition(boundary.start.axis, iterable: s, fixed: start.fixed),
                        iterationEnd = Position.newPosition(boundary.end.axis, iterable: e, fixed: end.fixed) else { continue }
                    let boundary = Boundary(start: iterationStart, end: iterationEnd)
                    if currentBoundaries.filter({$0.start == iterationStart && $0.end == iterationStart}).count == 0 {
                        currentBoundaries.append(boundary)
                    }
                }
            }
            
            let inverseAxisStart = boundary.start.axis.inverse(.Prev)
            let inverseAxisEnd = boundary.end.axis.inverse(.Next)
            
            for i in boundary.start.iterable...boundary.end.iterable {
                guard let startPosition = Position.newPosition(inverseAxisStart, iterable: start.fixed, fixed: i),
                    endPosition = Position.newPosition(inverseAxisEnd, iterable: end.fixed, fixed: i) else { continue }
                
                let iterationStart = getPositionLoop(startPosition)
                let iterationEnd = getPositionLoop(endPosition)
                let boundary = Boundary(start: iterationStart, end: iterationEnd)
                if currentBoundaries.filter({$0.start == iterationStart && $0.end == iterationEnd}).count == 0 {
                    currentBoundaries.append(boundary)
                }
            }
            
            allBoundaries.extend(currentBoundaries)
        }
        return allBoundaries
    }
}