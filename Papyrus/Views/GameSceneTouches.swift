//
//  GameSceneTouches.swift
//  Papyrus
//
//  Created by Chris Nevin on 13/07/2015.
//  Copyright © 2015 CJNevin. All rights reserved.
//

import SpriteKit
import PapyrusCore

extension GameScene {
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        do { try pickup(atPoint: point(inTouches: touches)) }
        catch { print("Error picking up sprite") }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        guard let point = point(inTouches: touches) else { return }
        heldTile?.resetPosition(point)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        do { try drop(atPoint: point(inTouches: touches)) }
        catch { print("Error dropping sprite") }
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        do { try dropInRack(false, atPoint: heldOrigin ?? point(inTouches: touches)) }
        catch { print("Error dropping in rack") }
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
    
}

extension GameScene {
    
    /// - returns: Point of held tile if available.
    var heldOrigin: CGPoint? {
        return heldTile?.origin
    }
    
    /// - returns: First point in touches set
    private func point(inTouches touches: Set<UITouch>?) -> CGPoint? {
        return touches?.first?.locationInNode(self)
    }
    
    /// - parameter point: Point to check for intersection with square sprites
    /// - returns: `SquareSprite` that best intersects the point passed in
    private func intersectedSquareSprite(point: CGPoint) -> SquareSprite? {
        // Check if we are holding a tile, if not return
        guard let tileSprite = heldTile else { return nil }
        // Function to calculate intersection
        func intersection(item: SquareSprite) -> CGFloat {
            let intersection = CGRectIntersection(item.frame, tileSprite.frame)
            return CGRectGetHeight(intersection) + CGRectGetWidth(intersection)
        }
        // Filter empty squares that intersect our tile
        let s = squareSprites.filter({ $0.isEmpty && $0.intersectsNode(tileSprite) })
        if s.count == 0 { return nil }
        return s.filter({ $0.frame.contains(point) }).first ??
            s.maxElement({ return intersection($0) < intersection($1) })
    }
    
    /// Drop a tile on the board, or if no squares are intersected back to the tile rack.
    /// Throws an error if either 'place' fails.
    private func drop(atPoint point: CGPoint?) throws {
        guard let point = point, sprite = heldTile, origin = heldOrigin else { return }
        guard let emptySquare = intersectedSquareSprite(point) else {
            try dropInRack(atPoint: origin)
            return
        }
        // Drop on board
        emptySquare.animateDropTileSprite(sprite, originalPoint: origin, completion: nil)
        let tile = sprite.tile
        tile.placement = .Board
        checkBoundary()
        if tile.value == 0 && tile.letter == "?" {
            actionDelegate?.pickLetter({ [weak self] (c) -> () in
                sprite.changeLetter(c)
                self?.checkBoundary()
            })
        }
    }
    
    /// Drop currently held tile into the rack.
    /// Throws an error if 'place' method fails.
    private func dropInRack(animated: Bool? = true, atPoint point: CGPoint?) throws {
        guard let point = point, sprite = heldTile else { return }
        animated == true ? sprite.animateDropToRack(point) : sprite.resetPosition(point)
        let tile = sprite.tile
        tile.placement = .Rack
        checkBoundary()
        if tile.value == 0 {
            sprite.changeLetter("?")
            checkBoundary()
        }
    }
    
    /// Pickup a tile from the rack or board.
    /// Throws an error if 'place' method fails.
    private func pickup(atPoint point: CGPoint?) throws {
        guard let point = point else { return }
        if let s = squareSprites.filter({ $0.containsPoint(point) && $0.tileSprite != nil }).first,
            t = s.pickupTileSprite() {
            // Pickup from board
            t.origin = s.origin
            t.tile.placement = .Held
            t.animateGrow()
            addChild(t)
        } else if let t = tileSprites.filter({ $0.containsPoint(point) && !$0.hasActions() }).first {
            // Pickup from rack
            t.origin = t.position
            t.tile.placement = .Held
            t.animatePickupFromRack(point)
        }
    }
}