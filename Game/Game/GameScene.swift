//
//  GameScene.swift
//  Game
//
//  Created by Andrew Ogren on 9/14/17.
//  Copyright © 2017 Andrew Ogren. All rights reserved.
//

import SpriteKit

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}

func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}

#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
        return CGFloat(sqrtf(Float(a)))
    }
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}

struct PhysicsCategory {
    static let None      : UInt32 = 0
    static let All       : UInt32 = UInt32.max
    static let Monster   : UInt32 = 0b1       // 1
    static let Monster2: UInt32 = 0b10      // 2
    static let Projectile: UInt32 = 0b11      // 3
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // 1
    let player = SKSpriteNode(imageNamed: "player")
    var monstersDestroyed = 0
    let scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
    
    
    override func didMove(to view: SKView) {
        // 2
        backgroundColor = SKColor.white
        
        let background = SKSpriteNode(imageNamed: "lava")
        background.size = frame.size
        background.position = CGPoint(x: frame.width/2, y: frame.height/2)
        background.zPosition = 0
        addChild(background)
        
        // 3
        player.position = CGPoint(x: size.width * 0.1, y: size.height * 0.5)
        // 4
        addChild(player)
        addScore()
        
        physicsWorld.gravity = CGVector.zero
        physicsWorld.contactDelegate = self
        
        run(SKAction.repeatForever(
            SKAction.sequence([
                SKAction.run(addMonster),
                SKAction.wait(forDuration: 1.0)
                ])
        ))
        
        let backgroundMusic = SKAudioNode(fileNamed: "background-music-aac.caf")
        backgroundMusic.autoplayLooped = true
        addChild(backgroundMusic)
    }
    
    func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    func random(min: CGFloat, max: CGFloat) -> CGFloat {
        return random() * (max - min) + min
    }
    
    func addScore() {
        scoreLabel.text = NSLocalizedString("Score: \(monstersDestroyed)", comment: "")
        scoreLabel.fontSize = 40
        scoreLabel.fontColor = SKColor.black
        scoreLabel.position = CGPoint(x: scoreLabel.frame.size.width/2, y: self.frame.size.height-scoreLabel.frame.size.height)
        scoreLabel.zPosition = 1
        addChild(scoreLabel)
    }
    
    func createMonster2() -> SKSpriteNode {
        // creat sprite
        let monster2 = MegaMonster(imageNamed: "creature")
        monster2.zPosition = 1
        monster2.physicsBody = SKPhysicsBody(rectangleOf: monster2.size)
        monster2.physicsBody?.isDynamic = true
        monster2.physicsBody?.categoryBitMask = PhysicsCategory.Monster2
        monster2.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile
        monster2.physicsBody?.collisionBitMask = PhysicsCategory.None
        monster2.setScale(0.2)
        monster2.hitsRemaining = 2
        return monster2
    }
    
    func createMonster() -> SKSpriteNode {
        // Create sprite
        let monster = MegaMonster(imageNamed: "monster")
        monster.zPosition = 1
        monster.physicsBody = SKPhysicsBody(rectangleOf: monster.size) // 1
        monster.physicsBody?.isDynamic = true // 2
        monster.physicsBody?.categoryBitMask = PhysicsCategory.Monster // 3
        monster.physicsBody?.contactTestBitMask = PhysicsCategory.Projectile // 4
        monster.physicsBody?.collisionBitMask = PhysicsCategory.None // 5
        monster.hitsRemaining = 1
        return monster
    }
    
    func addMonster() {
        var monster: SKSpriteNode? = nil
        if (random(min: 0, max: 10) <= 5) {
            monster = createMonster()
        } else {
            monster = createMonster2()
        }
        if let monster = monster {
            // Determine where to spawn the monster along the Y axis
            let actualY = random(min: monster.size.height/2, max: size.height - monster.size.height/2)
            
            // Position the monster slightly off-screen along the right edge,
            // and along a random position along the Y axis as calculated above
            monster.position = CGPoint(x: size.width + monster.size.width/2, y: actualY)
            
            // Add the monster to the scene
            addChild(monster)
            
            // Determine speed of the monster
            let actualDuration = random(min: CGFloat(2.0), max: CGFloat(4.0))
            
            let loseAction = SKAction.run() {
                let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
                let gameOverScene = GameOverScene(size: self.size, won: false)
                self.view?.presentScene(gameOverScene, transition: reveal)
            }
            
            // Create the actions
            let actionMove = SKAction.move(to: CGPoint(x: -monster.size.width/2, y: actualY), duration: TimeInterval(actualDuration))
            let actionMoveDone = SKAction.removeFromParent()
            
            monster.run(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        run(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))
        
        // 1 - Choose one of the touches to work with
        guard let touch = touches.first else {
            return
        }
        let touchLocation = touch.location(in: self)
        
        // 2 - Set up initial location of projectile
        let projectile = SKSpriteNode(imageNamed: "projectile")
        projectile.position = player.position
        projectile.zPosition = 1
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
        projectile.physicsBody?.isDynamic = true
        projectile.physicsBody?.categoryBitMask = PhysicsCategory.Projectile
        projectile.physicsBody?.contactTestBitMask = PhysicsCategory.Monster
        projectile.physicsBody?.collisionBitMask = PhysicsCategory.None
        projectile.physicsBody?.usesPreciseCollisionDetection = true
        
        // 3 - Determine offset of location to projectile
        let offset = touchLocation - projectile.position
        
        // 4 - Bail out if you are shooting down or backwards
        if (offset.x < 0) { return }
        
        // 5 - OK to add now - you've double checked position
        addChild(projectile)
        
        // 6 - Get the direction of where to shoot
        let direction = offset.normalized()
        
        // 7 - Make it shoot far enough to be guaranteed off screen
        let shootAmount = direction * 1000
        
        // 8 - Add the shoot amount to the current position
        let realDest = shootAmount + projectile.position
        
        // 9 - Create the actions
        let actionMove = SKAction.move(to: realDest, duration: 2.0)
        let actionMoveDone = SKAction.removeFromParent()
        projectile.run(SKAction.sequence([actionMove, actionMoveDone]))
        
    }
    
    func projectileDidCollideWithMonster(projectile: SKSpriteNode, monster: MegaMonster) {
        print("Hit")
        print("projectile collided")
        monster.hitsRemaining = monster.hitsRemaining - 1
        projectile.removeFromParent()
        
        if (monster.hitsRemaining == 0) {
            monster.removeFromParent()
            
            monstersDestroyed += 1
            scoreLabel.text = NSLocalizedString("Score: \(monstersDestroyed)", comment: "")
            if (monstersDestroyed > 30) {
                let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
                let gameOverScene = GameOverScene(size: self.size, won: true)
                self.view?.presentScene(gameOverScene, transition: reveal)
            }
        }
        
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        // 1
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        // 2
        if ((firstBody.categoryBitMask & PhysicsCategory.Monster != 0 || firstBody.categoryBitMask & PhysicsCategory.Monster2 != 0) &&
            (secondBody.categoryBitMask & PhysicsCategory.Projectile != 0)) {
            print("\(firstBody.node)")
            if let monster = firstBody.node as? MegaMonster, let
                projectile = secondBody.node as? SKSpriteNode {
                projectileDidCollideWithMonster(projectile: projectile, monster: monster)
            }
        }
        
    }
}


