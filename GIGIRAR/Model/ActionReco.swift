//
//  ActionReco.swift
//  EjemploAR
//
//  Created by Eduardo Parada on 22/01/2019.
//  Copyright © 2019 Eduardo Parada. All rights reserved.
//

import Foundation
import GIGLibrary

enum TypeAction: String {
    case text
    case model3D
    case video
    case none
}

struct ActionReco {
    var type: TypeAction
    var source: String
    var model: Model3D?
    
    // MARK: - Public method
    
    static func parse(json: JSON?) -> ActionReco {
        return ActionReco(
            type: TypeAction.init(rawValue: json?["type"]?.toString() ?? "") ?? .none,
            source: json?["source"]?.toString() ?? "",
            model: Model3D.parse(json: json)
        )
    }
}
