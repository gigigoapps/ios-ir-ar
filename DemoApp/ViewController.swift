//
//  ViewController.swift
//  DemoApp
//
//  Created by Eduardo Parada on 23/01/2019.
//  Copyright © 2019 Eduardo Parada. All rights reserved.
//

import UIKit
import GIGIRAR
import SceneKit
import ARKit

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    
    var irAr: IRAR?
    var lastReco: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.irAr = IRAR(id: "")
        self.irAr?.logLevel = .debug
        self.irAr?.output = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.irAr?.start(completion: { response in
            switch response {
            case .success:
                self.irAr?.launch(sceneView: self.sceneView)
            case .error(let error):
                print(error.localizedDescription)
            }
        })
    }
}

// MARK: - IRAROutPut

extension ViewController: IRAROutPut {
    
    func model3D(result: ResultGet3DModel) {
        
    }
    
    func idRecognition(id: String) {
        if self.lastReco != id {
            self.lastReco = id
            print("--------> \(id)")
        }
    }
}
