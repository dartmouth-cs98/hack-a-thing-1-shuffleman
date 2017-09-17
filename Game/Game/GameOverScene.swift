//
//  GameOverScene.swift
//  Game
//
//  Created by Andrew Ogren on 9/17/17.
//  Copyright © 2017 Andrew Ogren. All rights reserved.
//

import Foundation
import SpriteKit

class GameOverScene: SKScene {
    let defaults:UserDefaults = UserDefaults.standard
    
    init(size: CGSize, won:Bool, score: Int) {
        
        super.init(size: size)
        
        if (score > defaults.integer(forKey: "HighScore")) {
            defaults.set(score, forKey: "HighScore")
        }
        
        // 1
        backgroundColor = SKColor.white
        
        // 2
        let message = won ? "You Won!" : "You Lose :["
        
        // 3
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = message
        label.fontSize = 40
        label.fontColor = SKColor.black
        label.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(label)
        
        // 4
        run(SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.run() {
                // 5
                let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
                let scene = GameScene(size: size)
                self.view?.presentScene(scene, transition:reveal)
            }
            ]))
        
    }
    
    // 6
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
