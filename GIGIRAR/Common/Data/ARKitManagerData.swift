//
//  ARKitDataManager.swift
//  GIGIRAR
//
//  Created by eduardo parada pardo on 25/01/2019.
//  Copyright © 2019 Eduardo Parada. All rights reserved.
//

import Foundation
import ARKit
import GIGLibrary
import Zip

protocol ARKitManagerDataOutput {
    func configurationDid(response: ResponseConfiguration)
    func downloadImageDidFinish(response: ResposeDownloadImag)
    func return3DModel(node: SCNNode)
    func return3DAnimation(animation: CAAnimation)
    func download3DModelDidFinish(response: ResposeDownload3DModel)
}

protocol ARKitManagerDataInput {
    func getConfiguration(id: String)
    func downloadImages(url: String, id: String)
    func recover3DModelWith(action: ActionReco)
}

class ARKitManagerData {
    
    var output: ARKitManagerDataOutput?
    var service: ARKitManagerServicesInput
    
    private var action: ActionReco?
    
    convenience init() {
        let service = ARKitManagerServices()
        self.init(service: service)
        service.output = self
    }
    
    init (service: ARKitManagerServicesInput) {
        self.service = service
    }
    
    // MARK: - Private Method
    
    private func exist3DModelInCache(id: String) -> Bool {
        let sceneSource = self.recoverSceneSource(id: id)  // Format: nameFolder.scnassets/nameNode.dae
        return sceneSource?.identifiersOfEntries(withClass: SCNNode.self).count == 0 ? false : true
    }
    
    private func recover3DModel(id: String, idNode: String) {
        let sceneSource = self.recoverSceneSource(id: id)
        if let model3D = sceneSource?.entryWithIdentifier(idNode, withClass: SCNNode.self) { // Name identifier of ID object in model
            if let scale = self.action?.model?.styles?.scale {
                model3D.scale = SCNVector3(x: scale.x, y: scale.y, z: scale.z)
            }
            if let position = self.action?.model?.styles?.position {
                model3D.position = SCNVector3(x: position.x, y: position.y, z: position.z)
            }
            self.output?.return3DModel(node: model3D)
        } else if let animationObj = sceneSource?.entryWithIdentifier(idNode, withClass: CAAnimation.self) {
            self.output?.return3DAnimation(animation: animationObj)
        } else {
            logWarn("Model 3D can't be loaded")
        }
    }
    
    private func recoverSceneSource(id: String) -> SCNSceneSource? {
        var documentsDirectoryURL = try? FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        
        documentsDirectoryURL = documentsDirectoryURL?.appendingPathComponent(id)
        guard let url = documentsDirectoryURL else { return nil }
        let sceneSource = SCNSceneSource(url: url, options: nil)
        return sceneSource
    }
    
    private func searchPath(id: String?) -> String {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard let documentDirectory = path.first else {
            self.output?.download3DModelDidFinish(response: .error(error: .apiError(message: "Document directory error")))
            return ""
        }
        
        if let id = id {
            return documentDirectory + "/" + id
        } else {
            return documentDirectory
        }
    }
    
    private func download3DModel(action: ActionReco, model: Model3D) {
        do {
            var documentsDirectoryURL: URL = try FileManager.default.url(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask, appropriateFor: nil, create: false)
            documentsDirectoryURL.appendPathComponent(model.assetsFolder + ".zip")
            self.service.download3DModelWith(id: action.source, urlDisk: documentsDirectoryURL)
        } catch {
            self.output?.download3DModelDidFinish(response: .error(error: .apiError(message: "Error when get document directory")))
        }
    }
}

// MARK: - ARKitManagerServicesOutput

extension ARKitManagerData: ARKitManagerDataInput {
    
    func getConfiguration(id: String) {
        self.service.getConfiguration(id: id)
    }
    
    func downloadImages(url: String, id: String) {
        self.service.downloadImages(url: url, id: id)
    }
    
    func recover3DModelWith(action: ActionReco) {
        self.action = action
        guard let model = action.model else { return logWarn("3DModel is nil") }
        
        if self.exist3DModelInCache(id: model.assetsFolder + "/" + model.idModel) {
            self.recover3DModel(id: model.assetsFolder + "/" + model.idModel, idNode: model.idNodo)
            // Animation
            if let idNodoAnim = model.idNodoAnim, let idModelAnim = model.idModelAnim {
                self.recover3DModel(id: model.assetsFolder + "/" + idModelAnim, idNode: idNodoAnim)
            }
        } else {
            self.download3DModel(action: action, model: model)
        }
    }
}

// MARK: - ARKitManagerServicesOutput

extension ARKitManagerData: ARKitManagerServicesOutput {
    
    func configurationDid(response: ResponseConfiguration) {
        self.output?.configurationDid(response: response)
    }
    
    func downloadImageDidFinish(response: ResposeDownloadImag) {
        self.output?.downloadImageDidFinish(response: response)
    }
    
    func download3DModelDidFinish(response: ResposeDownload3DModel) {
        switch response {
        case .success:
            
            do {
                // 1º Unzip file
                guard let model = self.action?.model else { return logWarn("3DModel is nil") }
                guard let url = URL(string: String(self.searchPath(id: model.assetsFolder + ".zip"))) else { return logWarn("url is nil") }
                guard let documentsDirectory = URL(string: self.searchPath(id: nil)) else { return logWarn("Document directory is nil") }
                
                try Zip.unzipFile(url, destination: documentsDirectory, overwrite: true, password: nil, progress: { progress -> Void in
                    if progress == 1 {
                        // 2º Recover 3D model
                        self.recover3DModel(id: model.assetsFolder + "/" + model.idModel, idNode: model.idNodo)
                        
                        // 3º Animation
                        if let idNodoAnim = model.idNodoAnim, let idModelAnim = model.idModelAnim {
                            self.recover3DModel(id: model.assetsFolder + "/" + idModelAnim, idNode: idNodoAnim)
                        }
                    }
                })
                
            } catch let error {
                logWarn(error.localizedDescription)
                self.output?.download3DModelDidFinish(response: .error(error: .apiError(message: "Zip not found")))
            }
            
        case .error(let error):
            self.output?.download3DModelDidFinish(response: .error(error: error))
        }
    }
}
