//
//  RecoModel.swift
//  EjemploAR
//
//  Created by Eduardo Parada on 22/01/2019.
//  Copyright © 2019 Eduardo Parada. All rights reserved.
//

import Foundation
import GIGLibrary

enum TypeReco: String {
    case ir
    case obj
}

struct RecoModel {
    
    var image: String
    var idReco: String
    var type: TypeReco
    var action: ActionReco?
    
    // MARK: - Public method
    
    static func parse(json: JSON) -> [RecoModel] {
        return json.map(parseElement)
    }
    
    static func parseElement(json: JSON) -> RecoModel {
        
        let reco = RecoModel(
            image: json["image"]?.toString() ?? "",
            idReco: json["idReco"]?.toString() ?? "",
            type: TypeReco.init(rawValue: json["type"]?.toString() ?? "") ?? .ir,
            action: ActionReco.parse(json: json["action"])
        )
        
        return reco
    }
}
