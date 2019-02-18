//
//  ARKitManager.swift
//  EjemploAR
//
//  Created by Eduardo Parada on 23/01/2019.
//  Copyright © 2019 Eduardo Parada. All rights reserved.
//

import Foundation
import SceneKit
import ARKit
import GIGLibrary

public enum ResultGet3DModel {
    case susccess(node: SCNNode)
    case error(error: Error)
}

protocol ARKitManagerOutPut {
    func idRecognition(id: String)
    func get3DModelDidFinish(result: ResultGet3DModel)
}

protocol ARKitManagerInPut {
    func start(completion:@escaping (StartDidFinish) -> Void)
    func launch(sceneView: ARSCNView, arActive: Bool)
    func get3DModel(id: String)
    func getListId() -> [String]?
}

class ARKitManager: NSObject {
    
    private var targetAnchor: ARAnchor?
    private var hideNodes = false
    private var configuration: ARWorldTrackingConfiguration?
    private var id: String
    private var nodePrint: SCNNode?
    private var nodeModel: SCNNode?
    private var scene: SCNScene?
    private var completionHandler: (StartDidFinish) -> Void = {_ in }
    private var isArActive: Bool = true
    
    var sceneView: ARSCNView?
    var interactor: ARKitManagerInteractor?
    var output: ARKitManagerOutPut?

    init(id: String) {
        self.id = id
        
        super.init()
                
        // Create a new scene
        let scene = SCNScene()
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        cameraNode.position = SCNVector3(0, 0, 15)
        
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = SCNLight.LightType.omni
        lightNode.position = SCNVector3(0, 10, 10)
        scene.rootNode.addChildNode(lightNode)
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = SCNLight.LightType.ambient
        ambientLightNode.light?.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        self.scene = scene
        
        self.interactor = ARKitManagerInteractor()
        self.interactor?.output = self
    }
    
    // MARK: - Actions
    
    @objc func handleTap(rec: UITapGestureRecognizer) {
        if rec.state == .ended {
            let location: CGPoint = rec.location(in: self.sceneView)
            
            if let hits = self.sceneView?.hitTest(location, options: nil), !hits.isEmpty {
                let animPlayer = self.nodePrint?.animationPlayer(forKey: self.nodePrint?.childNodes.last?.name ?? "") 
                
                guard let animationPlayer = animPlayer else {
                    animPlayer?.play()
                    return
                }
                
                if animationPlayer.paused {
                    animationPlayer.play()
                } else {
                    animationPlayer.stop()
                }
            }
        }
    }
    
    // MARK: - Private Method
    
    private func launchAction(id: String?, node: SCNNode, anchor: ARAnchor) {
        if let reco = self.interactor?.searchNode(id: id), let action = reco.action {
            switch action.type {
            case .model3D:
                self.nodePrint = node
                self.addPreview(node: node, anchor: anchor)
                delay(0.5) {
                    self.interactor?.userDidScanIdTo3DModel(action: action, idReco: id)
                    self.removePreview(node: node)
                }
                
            case .text:
                let title = SCNText(string: action.source, extrusionDepth: 0.6)
                let titleNode = SCNNode(geometry: title)
                titleNode.scale = SCNVector3(0.005, 0.005, 0.01)
                titleNode.position = SCNVector3(-0.15, 0.25, 0)
                node.addChildNode(titleNode)
                
            case .video:
                break
                
            case .none:
                break
            }
        }
    }
    
    private func hideNode(node: SCNNode) {
        node.enumerateChildNodes { (node, _) in
            node.isHidden  = true
        }
    }
    
    private func showNode(node: SCNNode) {
        node.enumerateChildNodes { (node, _) in
            node.isHidden  = false
        }
    }
    
    private func addPreview(node: SCNNode, anchor: ARAnchor) {
        if let imageAnchor = anchor as? ARImageAnchor {
            let plane = SCNPlane(
                width: imageAnchor.referenceImage.physicalSize.width,
                height: imageAnchor.referenceImage.physicalSize.height
            )
            plane.firstMaterial?.diffuse.contents = UIColor(white: 1, alpha: 0.8)
            let planeNode = SCNNode(geometry: plane)
            planeNode.eulerAngles.x = -.pi / 2
            node.addChildNode(planeNode)
        }
    }
   
    private func removePreview(node: SCNNode) {
        let nodePreview = node.childNodes.first
        nodePreview?.removeFromParentNode()
    }
    
    private func recoverNameReference(anchor: ARAnchor) -> String {
        var name = ""
        
        if let imageAnchor = anchor as? ARImageAnchor, let nameImage = imageAnchor.referenceImage.name {
            name = nameImage
        }
        
        if #available(iOS 12.0, *) {
            if let objectAnchor = anchor as? ARObjectAnchor, let nameObject = objectAnchor.referenceObject.name {
                name = nameObject
            }
        }
        return name
    }
}

// MARK: - ARKitManagerInPut

extension ARKitManager: ARKitManagerInPut {
    
    func start(completion:@escaping (StartDidFinish) -> Void) {
        self.completionHandler = completion
        self.interactor?.start(id: self.id)
    }
    
    func launch(sceneView: ARSCNView, arActive: Bool) {
        self.isArActive = arActive
        self.sceneView = sceneView
        self.sceneView?.delegate = self
        
        guard let scene = self.scene else { return logWarn("scene is nil") }
        self.sceneView?.scene = scene
        self.sceneView?.session.delegate = self
        
        // Add Actions
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(rec:)))
        self.sceneView?.addGestureRecognizer(tap)
        
        guard let config = self.configuration else { return logWarn("Configuration is nil") }
        self.sceneView?.session.run(config)
    }
    
    func get3DModel(id: String) {
        if let reco = self.interactor?.searchNode(id: id), let action = reco.action {
            switch action.type {
            case .model3D:
                self.interactor?.userDidScanIdTo3DModel(action: action, idReco: id)
                
            default:
                self.output?.get3DModelDidFinish(result: .error(error: CustomError.apiError(message: "Model with id: \(id) doesn't exist")))
            }
        }
    }
    
    func getListId() -> [String]? {
        return self.interactor?.recoverListIdReco()
    }
}

// MARK: - ARKitManagerInteractorOutput

extension ARKitManager: ARKitManagerInteractorOutput {
    
    func prepareImageRecognition(listImageReco: [UIImage]) {
        self.configuration = ARWorldTrackingConfiguration()
        
        var listReferences: Set <ARReferenceImage> = []
        for image in listImageReco {
            if let reference = self.interactor?.createReference(image: image, idReco: image.accessibilityValue) {
                listReferences.insert(reference)
            }
        }
        
        self.configuration?.detectionImages = listReferences
        
        if #available(iOS 12.0, *) {
            self.configuration?.maximumNumberOfTrackedImages = 1
        }
        
        self.completionHandler(.success)
    }
    
    func returnError(error: Error) {
        self.completionHandler(.error(error: error))
    }
    
    func print3DModel(node: SCNNode) {
        self.output?.get3DModelDidFinish(result: .susccess(node: node))
        
        self.nodePrint?.addChildNode(node)
    }
    
    func showAnimation3DModel(animation: CAAnimation) {
        animation.repeatCount = 1
        animation.fadeInDuration = CGFloat(1)
        animation.fadeOutDuration = CGFloat(0.5)
        let animPlayer = SCNAnimationPlayer(animation: SCNAnimation(caAnimation: animation))
        animPlayer.paused = true
        self.nodePrint?.addAnimationPlayer(
            animPlayer,
            forKey: self.nodePrint?.childNodes.last?.name
        )
    }
}

// MARK: - ARSCNViewDelegate

extension ARKitManager: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if self.isArActive {
            self.targetAnchor = anchor
            let name = self.recoverNameReference(anchor: anchor)
            self.launchAction(id: name, node: node, anchor: anchor)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        //-- Image Recognition --
        let name = self.recoverNameReference(anchor: anchor)
        self.output?.idRecognition(id: name)
        
        //-- Control AR model --
        if #available(iOS 12.0, *) {
            if self.hideNodes == true {
                self.hideNode(node: node)
                self.hideNodes = false
            } else {
                self.showNode(node: node)
            }
        }
    }
}

// MARK: - ARSessionDelegate

extension ARKitManager: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {        
        if #available(iOS 12.0, *) {
            for anchor in anchors {
                if let imageAnchor = anchor as? ARImageAnchor, imageAnchor == self.targetAnchor {
                    if !imageAnchor.isTracked {
                        self.hideNodes = true
                    }
                }
            }
        }
    }
}
