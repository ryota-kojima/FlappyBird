//
//  GameScene.swift
//  FlappyBird
//
//  Created by 小嶋暸太 on 2018/08/04.
//  Copyright © 2018年 小嶋暸太. All rights reserved.
//

import SpriteKit
import AVFoundation

var scrollNode:SKNode!
var wallNode:SKNode!
var itemNode:SKNode!
var bird:SKSpriteNode!

//soundの設定
var itemSE : AVAudioPlayer!
var gameOverSE:AVAudioPlayer!
var BGM:AVAudioPlayer!

//カテゴリーの設定
let birdCategory: UInt32=1<<0
let groundCategory: UInt32=1<<1
let wallCategory: UInt32=1<<2
let scoreCategory: UInt32=1<<3
let itemCategory: UInt32=1<<4

//スコア
var score = 0
var scoreLabelNode:SKLabelNode!
var bestScoreLabelNode:SKLabelNode!
let userDefaults:UserDefaults = UserDefaults.standard

var itemScore=0
var itemScoreLabelNode:SKLabelNode!

//シーンが表示された時に呼ばれるメソッド
class GameScene: SKScene,SKPhysicsContactDelegate {
    override func didMove(to view: SKView) {
        
        //効果音の設定
        //ファイルのパス
        let itemSEPath=Bundle.main.path(forResource: "switch1", ofType: "mp3")
        let itemURL=URL(fileURLWithPath: itemSEPath!)
        
        //インスタンスの生成
        itemSE=try! AVAudioPlayer(contentsOf: itemURL)
        //バッファに保存していつでも再生可能に
        itemSE.prepareToPlay()
        
        let gameOverPath=Bundle.main.path(forResource: "shock1", ofType: "mp3")
        let gameOverURL=URL(fileURLWithPath: gameOverPath!)
        
        gameOverSE=try! AVAudioPlayer(contentsOf: gameOverURL)
        gameOverSE.prepareToPlay()
        
        //BGMを設定
        let bgmpath=Bundle.main.path(forResource: "kougenwowatarukaze", ofType: "mp3")
        let bgmurl=URL(fileURLWithPath: bgmpath!)
        
        BGM=try! AVAudioPlayer(contentsOf: bgmurl)
        BGM.numberOfLoops = -1//永遠にループ
        BGM.prepareToPlay()
        BGM.play()
        
        //重力を指定
        physicsWorld.gravity=CGVector(dx: 0.0, dy: -4.0)
        //デリゲートの設定
        physicsWorld.contactDelegate=self
        //背景の色を表示
        backgroundColor=UIColor(red: 0.15, green: 0.75, blue: 0.9, alpha: 1)
        
        //親のノードを作って、スクロールを一括で止められるように
        scrollNode=SKNode()
        addChild(scrollNode)
        
        //壁用のノード
        wallNode=SKNode()
        scrollNode.addChild(wallNode)
        itemNode=SKNode()
        scrollNode.addChild(itemNode)
        
        
        //メソッドの中身を分割.roopのセットアップ
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        
        setupScore()
        setupItem()
    }
        
    func setupGround(){
        
        //画像テクスチャを指定
        let groundtexture=SKTexture(imageNamed: "ground")
        groundtexture.filteringMode = .nearest
        
        //必要なスプライトの枚数を計算
        let needNumber=Int(self.frame.size.width/groundtexture.size().width)+2
        
        //スクロールするアクションを生成
        //左に画像一枚分動かすアクション
        let moveGround=SKAction.moveBy(x: -groundtexture.size().width, y: 0, duration: 5.0)
        
        //元の位置に戻るアクションを生成
        let resetGround=SKAction.moveBy(x: groundtexture.size().width, y: 0, duration: 0.0)
        
        // 左にスクロール、元の位置に、左にスクロールと無限に繰り返してもらうアクション
        let repeatScrollGround=SKAction.repeatForever(SKAction.sequence([moveGround,resetGround]))
        
        for i in 0..<needNumber{
            //テクスチャを指定してスプライトを作る
            let groundsprite=SKSpriteNode(texture: groundtexture)
            //スプライトの座標を設定
            groundsprite.position=CGPoint(
                x: groundtexture.size().width*(CGFloat(i)+0.5),
                y: groundtexture.size().height*0.5
            )
            
            //地面カテゴリの追加
            groundsprite.physicsBody?.categoryBitMask=groundCategory
            
            //spriteにアクションを設定
            
            groundsprite.run(repeatScrollGround)
            
            //物理演算を設定する
            groundsprite.physicsBody=SKPhysicsBody(rectangleOf: groundtexture.size())
            groundsprite.physicsBody?.isDynamic=false
            
            //画像をシーンに表示する
            scrollNode.addChild(groundsprite)
        }
    }
    
    
    func setupCloud(){
        
        //画像テクスチャを設定
        let cloudTexture=SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        //必要な枚数を計算
        let needCloudNumber=Int(self.frame.size.width / cloudTexture.size().width)+2
        
        //スクロールするアクションを設定
        //画像一枚分左にスクロール
        let moveCloud = SKAction.moveBy(x: -(cloudTexture.size().width), y: 0, duration: 20)
        
        //元の位置に戻す
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        
        //上記二つの動きを永続的に繰り返す
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud,resetCloud]))
        
        //スプライトを生成する
        for i in 0..<needCloudNumber{
            let sprite=SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 //一番後ろに表示させるようにする
            
            //スプライトの表示する位置を決める
            sprite.position=CGPoint(x: cloudTexture.size().width*(CGFloat(i)+0.5),
                                    y: self.size.height-cloudTexture.size().height*0.5)
            
            //アニメーションを設定する
            sprite.run(repeatScrollCloud)
            
            //スプライトをノードに表示させる
            scrollNode.addChild(sprite)
            
        }
    }
    
    func setupWall(){
        //テクスチャを読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear
        
        //移動距離の計算
        let movingDistancce=CGFloat(self.frame.size.width+wallTexture.size().width)
        
        //画面外まで移動するアクションを設定
        let moveWall = SKAction.moveBy(x: -movingDistancce, y: 0, duration: 4.0)
        
        //自身を取り除くアクションを生成
        let removeWall = SKAction.removeFromParent()
        
        //2つのアニメーションを順にアクションを実行
        let wallAnimation = SKAction.sequence([moveWall,removeWall])
        
        let createWallAnimation = SKAction.run ({
            //壁関連を入れるノードを生成する
            let wall = SKNode()
            wall.position=CGPoint(x: self.frame.size.width+wallTexture.size().width/2, y: 0.0)
            wall.zPosition = -50 //地面より奥、雲より手前
            
            //画面のY軸の中心
            let centry_y = self.frame.size.height/2
            //壁のy座標を上下ランダムにする時の最大値
            let random_y_range = self.frame.size.height/4
            //下の壁のY軸の下限
            let under_wall_lowest_y = UInt32(centry_y - wallTexture.size().height/2 - random_y_range/2)
            //1~randomrange_yのランダムな整数を生成
            let random_y = arc4random_uniform(UInt32(random_y_range))
            //Y軸の下限にランダムにな値を足して、下の壁のY座標を決定
            let under_wall_y = CGFloat(under_wall_lowest_y+random_y)
            
            //キャラが通り抜ける隙間の長さ
            let slit_length = self.frame.size.height/6
            
            //下側の壁を生成
            let under = SKSpriteNode(texture: wallTexture)
            under.position=CGPoint(x: 0.0, y: under_wall_y)
            
            //物理演算の設定
            under.physicsBody=SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.isDynamic=false
            under.physicsBody?.categoryBitMask=wallCategory
            
            wall.addChild(under)
            
            //上側の壁を生成
            let upper=SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0.0, y: under_wall_y+wallTexture.size().height+slit_length)
            
            //物理演算を設定
            upper.physicsBody=SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.isDynamic=false
            upper.physicsBody?.categoryBitMask=wallCategory
            
            wall.addChild(upper)
            
            //スコア用のノードを作成
            let scoreNode=SKNode()
            scoreNode.position=CGPoint(x: upper.size.width+bird.size.width/2, y: self.frame.height/2)
            scoreNode.physicsBody=SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic=false
            scoreNode.physicsBody?.categoryBitMask=scoreCategory
            scoreNode.physicsBody?.contactTestBitMask=birdCategory
            wall.addChild(scoreNode)
            
            wall.run(wallAnimation)
            
            wallNode.addChild(wall)
        })
        
        //次の壁生成までの待ち時間を生成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        //壁を生成ー＞待ち時間ー＞壁を生成を無限に繰り返す
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation,waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
    }
    
    func setupBird(){
        let birdTextureA=SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB=SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        
        
        //2種類のテクスチャを交互に変更するアニメーションを設定する
        let textureAnimation = SKAction.animate(with: [birdTextureA,birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(textureAnimation)
        
        //スプライトを生成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position=CGPoint(x: self.frame.size.width*0.2, y: self.frame.size.height*0.7)
        
        //物理演算の設定
        bird.physicsBody=SKPhysicsBody(circleOfRadius: bird.size.height/2.0)
        
        //衝突時に回転させない
        bird.physicsBody?.allowsRotation=false
        
        //衝突カテゴリの設定
        bird.physicsBody?.categoryBitMask=birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory
        
        //アニメーションを設定する
        bird.run(flap)
        
        //スプライトを設定する
        addChild(bird)
    }
    
    func setupScore(){
        score=0
        scoreLabelNode=SKLabelNode()
        scoreLabelNode.fontColor=UIColor.black
        scoreLabelNode.position=CGPoint(x: 10, y: self.frame.size.height-60)
        scoreLabelNode.zPosition=100//一番手前側に設定
        scoreLabelNode.horizontalAlignmentMode=SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text="Score:\(score)"
        
        self.addChild(scoreLabelNode)
        
        bestScoreLabelNode=SKLabelNode()
        bestScoreLabelNode.fontColor=UIColor.black
        bestScoreLabelNode.position=CGPoint(x: 10, y: self.frame.size.height-90)
        bestScoreLabelNode.zPosition=100
        bestScoreLabelNode.horizontalAlignmentMode=SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text="Best Score:\(bestScore)"
        
        self.addChild(bestScoreLabelNode)
        
        itemScore=0
        itemScoreLabelNode=SKLabelNode()
        itemScoreLabelNode.fontColor=UIColor.black
        itemScoreLabelNode.position=CGPoint(x: 10, y: self.frame.size.height-120)
        itemScoreLabelNode.zPosition=100//一番手前側に設定
        itemScoreLabelNode.horizontalAlignmentMode=SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text="ItemScore:\(itemScore)"
        
        self.addChild(itemScoreLabelNode)
        
    }
    
    //画面をタッチした時に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if bird.speed > 0{
        //鳥の速度を０に
        bird.physicsBody?.velocity=CGVector.zero
        //鳥に縦方向に力を加える
        bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        }else{
            restart()
        }
    }
    //衝突した時に呼ばれるメソッド
    func didBegin(_ contact: SKPhysicsContact) {
        if scrollNode.speed <= 0{
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory)==scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory)==scoreCategory{
            //スコアと衝突した
            print("ScoreUp")
            score+=1
            scoreLabelNode.text="Score:\(score)"
            
            //ベストスコアかどうか確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score>bestScore{
                bestScore=score
                bestScoreLabelNode.text="Best Score:\(bestScore)"
                userDefaults.set(bestScore,forKey:"BEST")
                userDefaults.synchronize()
            }
            //アイテムと衝突した
        }else if (contact.bodyA.categoryBitMask & itemCategory)==itemCategory || (contact.bodyB.categoryBitMask & itemCategory)==itemCategory{
            
            print("ItemScoreUp")
            itemScore+=1
            itemScoreLabelNode.text="ItemScore:\(itemScore)"
            
            itemSE.play()
            
            if (contact.bodyA.categoryBitMask & itemCategory)==itemCategory{
                contact.bodyA.node?.removeFromParent()
            }else{
                contact.bodyB.node?.removeFromParent()
            }
            
        }else{
            //壁か地面に衝突した
            print("GameOver")
            
            gameOverSE.play()
            
            //スクロールを停止させる。Speedとはアクションのduaring（時間）つまり速さのこと
            scrollNode.speed=0
            
            bird.physicsBody?.collisionBitMask=groundCategory
            
            let roll=SKAction.rotate(byAngle: CGFloat(Double.pi)*CGFloat(bird.position.y)*0.01, duration: 1)
            bird.run(roll, completion:{
                bird.speed = 0})
        }
    }
    
    func restart(){
        
        score=0
        itemScore=0
        scoreLabelNode.text=String("Score:\(score)")
        itemScoreLabelNode.text=String("ItemScore:\(itemScore)")
        
        bird.position=CGPoint(x: self.frame.size.width*0.2, y: frame.size.height*0.7)
        bird.physicsBody?.velocity=CGVector.zero
        bird.physicsBody?.collisionBitMask=wallCategory | groundCategory
        bird.zRotation=0
        
        wallNode.removeAllChildren()
        itemNode.removeAllChildren()
        
        bird.speed=1
        scrollNode.speed=1
        
    }
    
    func setupItem(){
        //テクスチャを読み込む
        let itemTexture = SKTexture(imageNamed: "shortcake")
        itemTexture.filteringMode = .linear
        
        let wallTexture = SKTexture(imageNamed: "wall")
        
        //移動距離の計算
        let movingDistancce=CGFloat(self.frame.size.width+wallTexture.size().width)
        
        //画面外まで移動するアクションを設定
        let moveItem = SKAction.moveBy(x: -movingDistancce, y: 0, duration: 4.0)
//
        //自身を取り除くアクションを生成
        let removeItem = SKAction.removeFromParent()
        
//        2つのアニメーションを順にアクションを実行
        let itemAnimation = SKAction.sequence([moveItem,removeItem])
    
        let createItemAnimation = SKAction.run ({
        let item = SKNode()
            item.position=CGPoint(x: self.frame.size.width+wallTexture.size().width/2,y:0)
            item.zPosition = -50 //地面より奥、雲より手前
        
        //画面のY軸の中心
        let centry_y = self.frame.size.height/2
        //壁のy座標を上下ランダムにする時の最大値
        let random_y_range = self.frame.size.height/4
        //下の壁のY軸の下限
        let under_item_lowest_y = UInt32(centry_y - random_y_range/2)
        //1~randomrange_yのランダムな整数を生成
        let random_y = arc4random_uniform(UInt32(random_y_range))
        //Y軸の下限にランダムにな値を足して、下の壁のY座標を決定
        let under_item_y = CGFloat(under_item_lowest_y+random_y)
        
        //アイテムを生成
        let itemobje = SKSpriteNode(texture: itemTexture)
            
        itemobje.position=CGPoint(x: 0.0, y: under_item_y)
            itemobje.size=CGSize(width: 50, height: 50)
        
            itemobje.run(itemAnimation)
        
        //物理演算の設定
        itemobje.physicsBody=SKPhysicsBody(rectangleOf: itemobje.size)
        itemobje.physicsBody?.isDynamic=false
        itemobje.physicsBody?.categoryBitMask=itemCategory
        itemobje.physicsBody?.contactTestBitMask=birdCategory
        
        item.addChild(itemobje)
        itemNode.addChild(item)
        
        
    })
//
        
    //次の壁生成までの待ち時間を生成
    let waitsAnimation = SKAction.wait(forDuration: 2)
    
    //壁を生成ー＞待ち時間ー＞壁を生成を無限に繰り返す
    let repeatsForeverAnimation = SKAction.repeatForever(SKAction.sequence([createItemAnimation,waitsAnimation]))
    
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                itemNode.run(repeatsForeverAnimation)
        }
    }
}
