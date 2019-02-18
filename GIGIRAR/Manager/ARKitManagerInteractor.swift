//
//  ARKitManagerInteractor.swift
//  EjemploAR
//
//  Created by Eduardo Parada on 23/01/2019.
//  Copyright © 2019 Eduardo Parada. All rights reserved.
//

import Foundation
import GIGLibrary
import ARKit

protocol ARKitManagerInteractorOutput {
    func prepareImageRecognition(listImageReco: [UIImage])
    func returnError(error: Error)
    func print3DModel(node: SCNNode)
    func showAnimation3DModel(animation: CAAnimation)
}

protocol ARKitManagerInteractoInput {
    func start(id: String)
    func createReference(image: UIImage, idReco: String?) -> ARReferenceImage?
    func searchNode(id: String?) -> RecoModel?
    func userDidScanIdTo3DModel(action: ActionReco, idReco: String?)
    func recoverImage(id: String?) -> UIImage?
    func recoverListIdReco() -> [String]
}

class ARKitManagerInteractor {
    
    var output: ARKitManagerInteractorOutput?
    var dataManager: ARKitManagerDataInput
    
    private var listReco: [RecoModel] = []
    private var listImageReco: [UIImage] = []
    private var imageDownloadComplete = 0
    private var idReco: String?
    
    convenience init() {
        let dataManager = ARKitManagerData()
        self.init(dataManager: dataManager)
        dataManager.output = self
    }
    
    init (dataManager: ARKitManagerDataInput) {
        self.dataManager = dataManager
    }
    
    // MARK: - Private method
    
    private func downloadImages() {
        for reco in self.listReco {
            self.dataManager.downloadImages(url: reco.image, id: reco.idReco)
        }
    }
}

// MARK: - ARKitManagerInteractoInput

extension ARKitManagerInteractor: ARKitManagerInteractoInput {

    func start(id: String) {
        self.dataManager.getConfiguration(id: id)
    }
    
    func createReference(image: UIImage, idReco: String?) -> ARReferenceImage? {
        guard let cgImage = image.cgImage, let idReco = idReco else {
            logWarn("Error to recover cgImage and idReco is nil")
            return nil
        }
        
        let referenceImages = ARReferenceImage.init(cgImage, orientation: .up, physicalWidth: 0.595)
        referenceImages.name = idReco
        
        return referenceImages
    }
    
    func searchNode(id: String?) -> RecoModel? {
        let listElement = self.listReco.filter { reco -> Bool in
            return reco.idReco == id
        }
        return listElement.first
    }
    
    func userDidScanIdTo3DModel(action: ActionReco, idReco: String?) {
        self.idReco = idReco
        self.dataManager.recover3DModelWith(action: action)
    }
    
    func recoverImage(id: String?) -> UIImage? {
        for image in self.listImageReco {
            if image.accessibilityValue == id {
                return image
            }
        }
        return nil
    }
    
    func recoverListIdReco() -> [String] {
        var listId: [String] = []
        for reco in self.listReco {
            listId.append(reco.idReco)
        }
        return listId
    }
}

// MARK: - ARKitManagerServicesOutput

extension ARKitManagerInteractor: ARKitManagerDataOutput {
    
    func configurationDid(response: ResponseConfiguration) {
        switch response {
        case .success(let json):
            self.listReco = RecoModel.parse(json: json)
            self.downloadImages()
            
        case .error(let error):
            self.output?.returnError(error: error)
        }
    }
    
    func downloadImageDidFinish(response: ResposeDownloadImag) {
        switch response {
        case .success(let image):
            self.listImageReco.append(image)
            
        case .error(let error):
            self.output?.returnError(error: error)
        }
        
        self.imageDownloadComplete += 1
        if self.imageDownloadComplete == self.listReco.count {
            self.output?.prepareImageRecognition(listImageReco: self.listImageReco)
        }
    }
    
    func return3DModel(node: SCNNode) {
        node.name = self.idReco
        self.output?.print3DModel(node: node)
    }
    
    func return3DAnimation(animation: CAAnimation) {
        self.output?.showAnimation3DModel(animation: animation)
    }
    
    func download3DModelDidFinish(response: ResposeDownload3DModel) {
        switch response {
        case .error(let error):
            logWarn(error.localizedDescription)
        default:
            break
        }
    }
}
