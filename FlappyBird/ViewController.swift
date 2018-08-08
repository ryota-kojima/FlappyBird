//
//  ViewController.swift
//  FlappyBird
//
//  Created by 小嶋暸太 on 2018/08/04.
//  Copyright © 2018年 小嶋暸太. All rights reserved.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //skviewに型を変換
        let skView=self.view as! SKView
        
        //FPSを表示する
        skView.showsFPS=true
        //ノード数を表示する
        skView.showsNodeCount=true
        
        //sceneのサイズをviewと同じに
        let scene=GameScene(size: skView.frame.size)
        
        skView.presentScene(scene)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden: Bool{
        get{
            return true
        }
    }


}

