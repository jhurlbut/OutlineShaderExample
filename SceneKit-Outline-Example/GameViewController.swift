//
//  GameViewController.swift
//  testScn
//
//  Created by james hurlbut on 7/25/21.
//

import SceneKit
import QuartzCore

let highlightedBitMask = 2
let unHighlightedBitMask = 4

//extend SCNNode to have highlighted func
extension SCNNode {
    func setHighlighted( _ highlighted : Bool = true) {
        if(highlighted == true){
            categoryBitMask = highlightedBitMask
        }
        else {
            categoryBitMask = unHighlightedBitMask
        }
        for child in self.childNodes {
            child.setHighlighted()
        }
    }
    func getHighlighted() -> Bool {
        if(categoryBitMask == highlightedBitMask){
            return true;
        }
        else {
            return false;
        }
    }
}

class GameViewController: NSViewController, NSWindowDelegate {
    
    var technique : SCNTechnique!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        let scene = SCNScene()
        let shipScene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = NSColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)//
        
        // show the ship
        let ship = shipScene.rootNode.childNode(withName: "ship", recursively: true)!
        scene.rootNode.addChildNode(ship)
        ship.setHighlighted()
        
        // animate the ship
        ship.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 1, z: 0, duration: 1)))
        
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // configure the view. make sure it has empty alpha channel
        scnView.backgroundColor = NSColor.init(deviceRed: 0, green: 0, blue: 0, alpha: 0)
        
        //add some test objects. use chamfered box to make sure model doesn't have sharp edges
        let sphere = SCNBox(width: 1.5, height: 1.5, length: 1.5, chamferRadius: 0.2)
        sphere.firstMaterial?.diffuse.contents = NSColor.blue
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = SCNVector3(2.8, 1.2, 0.0)
        scene.rootNode.addChildNode(sphereNode)
        sphereNode.setHighlighted()
        
        let sphereNode2 = SCNNode(geometry: sphere)
        sphereNode2.position = SCNVector3(4.8, 1.2, 0.0)
        scene.rootNode.addChildNode(sphereNode2)
        sphereNode2.setHighlighted()
        
        let sphereNode3 = SCNNode(geometry: sphere)
        sphereNode3.position = SCNVector3(-3.8, 1.2, -10.0)
        scene.rootNode.addChildNode(sphereNode3)
        sphereNode3.setHighlighted()
        
        //add a cube to show where the outline shader breaks. won't work on cube because of the sharp edges
        //since we are using normal direction to offset outline from object
        let cube = SCNBox(width: 1.5, height: 1.5, length: 1.5, chamferRadius: 0.0)
        let cubeNode = SCNNode(geometry: cube)
        cubeNode.position = SCNVector3(-0.5, -2.5, 0.0)
        scene.rootNode.addChildNode(cubeNode)
        cubeNode.setHighlighted()
        
        if let path = Bundle.main.path(forResource: "NodeTechnique", ofType: "plist") {
            if let dict = NSDictionary(contentsOfFile: path)  {
                let dict2 = dict as! [String : AnyObject]
                technique = SCNTechnique(dictionary:dict2)

                // set the outline color to red
                let color = SCNVector3(1.0, 0.0, 0.0)
                //outline width in screen pixels (just x value is used)
                let outlineWidth = SCNVector3(14.0, 0.0, 0.0)
                technique?.setValue(NSValue(scnVector3: color), forKeyPath: "outlineColorSymbol")
                technique?.setValue(NSValue(scnVector3: outlineWidth), forKeyPath: "outlineWidthSymbol")

                scnView.technique = technique
            }
        }
        
        // Add a click gesture recognizer
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick(_:)))
        var gestureRecognizers = scnView.gestureRecognizers
        gestureRecognizers.insert(clickGesture, at: 0)
        scnView.gestureRecognizers = gestureRecognizers

    }
    @objc
    func handleClick(_ gestureRecognizer: NSGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are clicked
        let p = gestureRecognizer.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]
            
            if(result.node.getHighlighted()){
                result.node.setHighlighted(false)
            }
            else {
                result.node.setHighlighted(true)
            }
        }
    }

}
