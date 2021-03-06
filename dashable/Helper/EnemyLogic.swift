//
//  EnemyLogic.swift
//  dashable
//
//  Created by Willie Johnson on 3/22/18.
//  Copyright © 2018 Willie Johnson. All rights reserved.
//

import Foundation
import SpriteKit
import GameplayKit

typealias EnemyLogic = (Enemy, Player, GameScene) -> ()

//TODO: Refactor code and clean up for easier read
struct Logic {
  /// Attempts to get ahead and stop the player by growing in size on blocking their way.
  static var chaserLogic: EnemyLogic = { enemy, player, scene in
    let moveSpeed: CGFloat = enemy.moveSpeed
    // Grab physics bodies.
    guard let physicsBody = enemy.physicsBody else { return }
    guard let playerPhysicsBody = player.physicsBody else { return }

    // Distance between the enemy and the player as CGPoint.
    let positionDifferenceToPlayer = Useful.differenceBetween(enemy, and: player)
    // The velocity of the enemy before any action is taken.
    let currentVelocity = enemy.physicsBody!.velocity

    // Analyze player.
    let isNearPlayer = abs(positionDifferenceToPlayer.x) < 100
    let isAbovePlayer = positionDifferenceToPlayer.x < 2
    let isAheadOfPlayer = playerPhysicsBody.velocity.dx * positionDifferenceToPlayer.x < 0
    // Analyze environment.
    let obstaclesAhead = scene.nodes(at: CGPoint(x: enemy.position.x + scene.frame.width + enemy.viewDistance.width, y: enemy.position.y + enemy.viewDistance.height))
    let isObstacleAhead = obstaclesAhead.first != nil
    // Analyze self.
    let hasStopped = abs(currentVelocity.dx) <= 80

    // TODO: Replace with collision contact detection rather than velocity.
    let hasHitObstacle = abs(currentVelocity.dx) - abs(enemy.previousVelocity.dx) > 10

    let yVelocityIsTooFast = abs(currentVelocity.dy) > 150
    let xVelocityIsTooFast = abs(currentVelocity.dx) > moveSpeed * 2
    let thinksPlayerTooFast = abs(currentVelocity.dx) > 2500

    // TODO: Replace with obstackle/ground contact detection
    let shouldJump = !yVelocityIsTooFast && ((hasHitObstacle) || isObstacleAhead) && !isAbovePlayer

    // Calculate forces to apply.
    let angle = atan2(positionDifferenceToPlayer.y, positionDifferenceToPlayer.x)
    let vx: CGFloat = cos(angle) * moveSpeed
    let vy: CGFloat = shouldJump ? moveSpeed : 0.0

    if shouldJump {
      enemy.run(SKAction.scale(to: 20, duration: 1))
    }

    // Capture player if the position to.
    if thinksPlayerTooFast && isAheadOfPlayer && !isNearPlayer {
      enemy.run(SKAction.scale(to: 6, duration: 0.2))
    } else if !isAheadOfPlayer {
      enemy.run(SKAction.scale(to: 1, duration: 0.2))
    }

    let moveForce = CGVector(dx: vx, dy: vy)
    let stopForce = CGVector(dx: -currentVelocity.dx / 10, dy: -currentVelocity.dy)

    // Stop accelerating once ahead of player.
    if xVelocityIsTooFast && isAheadOfPlayer && !isNearPlayer {
      physicsBody.applyForce(stopForce)
    }

    // Move towards player.
    physicsBody.applyForce(moveForce)
  }

  /// Flies above and ehead of the player and drops obstacles.
  static var flyerLogic: EnemyLogic = { yellowEnemy, player, scene in

    yellowEnemy.run(SKAction.move(to: CGPoint(x: player.position.x + player.physicsBody!.velocity.dx, y: player.position.y + 500), duration: 0.8))
    // Only run if there is no action(dropObstacle) already running
    let shouldDropObstacle = !yellowEnemy.isAbilityActionRunning
    guard shouldDropObstacle else { return }
    // Create an obstacle and launch it towards the player.
    let dropObstacle = SKAction.run {
      yellowEnemy.isAbilityActionRunning = true
      let randWidthModifier = GKRandomSource.sharedRandom().nextInt(upperBound: 100)
      let randHeightModifier = GKRandomSource.sharedRandom().nextInt(upperBound: 20)
      let randVelocityModifier = CGFloat(GKRandomSource.sharedRandom().nextUniform()) + 1

      let obstacleSize = CGSize(width: 100 + randWidthModifier, height: 100 + randHeightModifier)
      let obstaclePosition = CGPoint(x: yellowEnemy.position.x, y: yellowEnemy.position.y - obstacleSize.height)

      let obstacle = Obstacle(position: obstaclePosition, size: obstacleSize)
      obstacle.color = Style.FLYER_COLOR
      obstacle.name = "flyerDrop"
      scene.addChild(obstacle)

      obstacle.run(SKAction.repeatForever(SKAction.sequence([SKAction.colorize(with: Style.CHASER_COLOR, colorBlendFactor: 1, duration: 0.1), SKAction.colorize(with: Style.OBSTACLE_COLOR, colorBlendFactor: 1, duration: 0.1)])))
      obstacle.run(SKAction.scale(to: 5, duration: 2), completion: {
        scene.addChaser(position: obstacle.position)
        obstacle.die()
      })

      let difference = Useful.differenceBetween(obstacle, and: player)
      let angle = atan2(difference.y, difference.x)
      obstacle.physicsBody!.usesPreciseCollisionDetection = true
      obstacle.physicsBody!.applyImpulse(CGVector(dx: -cos(angle) * (300 * randVelocityModifier), dy: sin(angle) * (1000 * randVelocityModifier)))
    }

    let finishAbilityAction = SKAction.run {
      yellowEnemy.isAbilityActionRunning = false
    }

    yellowEnemy.run(SKAction.sequence([dropObstacle, .wait(forDuration: 2), finishAbilityAction]))
  }
}
