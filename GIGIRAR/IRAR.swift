//
//  IRAR.swift
//  GIGIRAR
//
//  Created by Eduardo Parada on 23/01/2019.
//  Copyright © 2019 Eduardo Parada. All rights reserved.
//

import Foundation
import ARKit
import GIGLibrary

public enum StartDidFinish {
    case success
    case error(error: Error)
}

public protocol IRAROutPut {
    func idRecognition(id: String)
    func model3D(result: ResultGet3DModel)
}

open class IRAR {
    
    // MARK: - var
    private var manager: ARKitManager
    public var output: IRAROutPut?
    public var logLevel: LogLevel {
        didSet {
            ARKitLogger.logLevel = self.logLevel
            ARKitLogger.logStyle = .funny
        }
    }
    
    // MARK: - Method
    
    public init(id: String) {
        self.logLevel = .none
        self.manager = ARKitManager(id: id)
        self.manager.output = self
    }
    
    open func start(completion:@escaping (StartDidFinish) -> Void) {
        self.manager.start { startDidFinish in
            completion(startDidFinish)
        }
    }
    
    open func launch(sceneView: ARSCNView, arActive: Bool = true) {
        self.manager.launch(sceneView: sceneView, arActive: arActive)
    }
    
    open func getListID() -> [String]? {
       return self.manager.getListId()
    }
    
    open func get3DModel(id: String) {
        self.manager.get3DModel(id: id)
    }
}

// MARK: - ARKitManagerOutPut

extension IRAR: ARKitManagerOutPut {
    
    func get3DModelDidFinish(result: ResultGet3DModel) {
        self.output?.model3D(result: result)
    }
        
    func idRecognition(id: String) {
        self.output?.idRecognition(id: id)
    }
}
