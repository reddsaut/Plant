//
//  HomeView.swift
//  Plant
//
//  Created by redding sauter on 3/10/25.
//

import SwiftUI
import SpriteKit
import Oklch
import Metal


class PlantGrow: SKScene {
    private var leafNodes: [SKSpriteNode] = []
    private var potNode: SKSpriteNode!
    private var stemNode: SKSpriteNode!
    
    override init() {
        super.init(size: .zero)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // automatically called when the scene is fully presented by its SKView
    override func didMove(to view: SKView) {
        self.backgroundColor = .clear
        // Static pot
        potNode = SKSpriteNode(imageNamed: "pot")
        potNode.size = CGSize(width: 180, height: 180)
        potNode.position = CGPoint(x: size.width / 2, y: size.width / 2)
        addChild(potNode)
        
        // Static Stem
        stemNode = SKSpriteNode(imageNamed: "stem")
        stemNode.size = CGSize(width: 200, height: 200)
        stemNode.position = CGPoint(x:100, y: 75)
        addChild(stemNode)
        
        let anchorJSON = NSDataAsset(name: "leaf_anchors")!
        let anchors = try! JSONDecoder().decode([CGPoint].self, from: anchorJSON.data)
        
        for (leafNum, anchor) in anchors.enumerated() {
            let leafNode = SKSpriteNode(imageNamed: "leaf_\(leafNum)")
            leafNode.size = CGSize(width: 150, height: 150)
            leafNode.position = CGPoint(
                x: self.size.width * 0.5 + leafNode.size.width * (anchor.x - 0.5),
                y: self.size.height * 0.5 + leafNode.size.height * (anchor.y - 0.5)
            )
            leafNode.anchorPoint = anchor
            leafNode.setScale(0)
            addChild(leafNode)
            leafNodes.append(leafNode)

        }
    }
    
    
    
    func setPlantHealth(_ health: CGFloat) {
        
        
        
        let leafGrowthTime = 0.5
        let maxLeafStartTime = 1 - leafGrowthTime
        for (leafNum, leafNode) in leafNodes.enumerated() {
            let leafStartTime = maxLeafStartTime * CGFloat(leafNum) / CGFloat(leafNodes.count - 1)
            let growthTimeElapsed = health - leafStartTime
            let growthLine = growthTimeElapsed / leafGrowthTime
            let newScale = min(1, max(0, growthLine)) //pinning growthline between 0 and 1
            
            let scale = SKAction.scale(to: newScale, duration: 0.5)
            scale.timingMode = .easeInEaseOut
            leafNode.run(scale)
        }
    }
    
    func startSwayingLeaves() {
        
        for leafNode in leafNodes {
                let angle = CGFloat.random(in: 0.005...0.015)
                let duration = Double.random(in: 0.8...1.6)
                let rotateLeft = SKAction.rotate(toAngle: angle, duration: duration)
                let rotateRight = SKAction.rotate(toAngle: -angle, duration: duration)
                rotateLeft.timingMode = .easeInEaseOut
                rotateRight.timingMode = .easeInEaseOut
                let swaySequence = SKAction.sequence([rotateLeft, rotateRight])
                let swayForever = SKAction.repeatForever(swaySequence)
                leafNode.run(swayForever)

        }
    }
}

func makePlantScene() -> PlantGrow {
    let scene = PlantGrow()
    scene.size = CGSize(width: 180, height: 180)
    scene.scaleMode = .fill
    scene.setScale(1)
    return scene
}

let plantScene = makePlantScene()

struct HomeView: View {
    @EnvironmentObject var hd: HydrationData
    @State var isPresentingConf: Bool = false
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(
                            colors: [PlantApp.colors.tan, PlantApp.colors.brown]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing)
                .ignoresSafeArea()

            
            VStack(spacing: 20) {
                
                SpriteView(scene: plantScene, options: [.allowsTransparency])
                    .frame(width: 400, height: 400)
                    .onChange(of: hd.waterIntake) {
                        plantScene.setPlantHealth(hd.waterIntake / hd.dailyGoal)
                        plantScene.startSwayingLeaves()
        
                        
                    }

                Text("Have you had water today?")
                    .font(.system(.title, design: .serif))
                    .fontWidth(.compressed)
                    .fontWeight(.bold)
                    .foregroundColor(PlantApp.colors.darkbrown)
                
                ProgressView(value: Double(hd.waterIntake), total: Double(hd.dailyGoal))
                    .frame(width: 200)
                    .scaleEffect(x: 1, y: 3, anchor: .center)
                
                             
                let intake = hd.unit.format(amountInMilliliters: hd.waterIntake)
                let goal = String(format: "%.1f", hd.unit.roundForDisplay(amountInMilliliters: hd.dailyGoal, ounceRound: 8, literRound: 0.25))
                Text("\(intake) / \(goal) oz")
                    .font(.system(.headline, design:.default))
                    .foregroundColor(PlantApp.colors.darkbrown)
                
                HStack {
                    Button(action: {
                        hd.logGlassOfWater()
                    }) {
                        Text("Log a Glass of Water")
                            .padding()
                            .frame(width: 150, height: 75)
                            .background(PlantApp.colors.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .fontDesign(.default)
                    }
                    .padding(.top, 10)
                    
                    Button(action: {
                        isPresentingConf = true
                    }) {
                        Text("Reset")
                            .padding()
                            .frame(width: 150, height: 75)
                            .background(PlantApp.colors.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .fontDesign(.default)
                    }
                    .padding(.top, 10)
                    .confirmationDialog("Are you sure?", isPresented: $isPresentingConf) {
                           Button("Reset today's intake?", role: .destructive) {
                               hd.resetDailyIntake()
                           }
                       } message: {
                           Text("You cannot undo this action.")
                       }
                }

            }
            .padding()
            
        }
    }
}
