//
//  Controls.swift
//  dashable
//
//  Created by Willie Liwa Johnson on 12/11/21.
//  Copyright © 2021 Willie Johnson. All rights reserved.
//

import Foundation
import SpriteKit

struct Controls: Component {
    var type: ComponentType = .CONTROLS
    var entityId: UUID
    
    var dx: CGFloat
    var dy: CGFloat
    var vectorWithAccel: CGVector {
        CGVector(dx: self.dx * acceleration, dy: self.dy * acceleration)
    }
    var acceleration: CGFloat = 2
    var moving: Bool {
        return dx != 0 || dy != 0
    }
    
    init(_ entity: Entity) {
        entityId = entity.id
    }
    
    mutating func move(dx: CGFloat, dy: CGFloat) {
        self.dx = dx
        self.dy = dy
    }
}
