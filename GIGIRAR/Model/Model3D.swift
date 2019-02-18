//
//  Model3D.swift
//  GIGIRAR
//
//  Created by eduardo parada pardo on 28/01/2019.
//  Copyright © 2019 Eduardo Parada. All rights reserved.
//

import Foundation
import GIGLibrary

struct Model3D {
    var styles: Styles?
    var idModel: String
    var idNodo: String
    var assetsFolder: String
    var idModelAnim: String?
    var idNodoAnim: String?
    
    // MARK: - Public method
    
    static func parse(json: JSON?) -> Model3D? {        
        if TypeAction.init(rawValue: json?["type"]?.toString() ?? "") == .model3D {            
            let parseFolder = json?["source"]?.toString()?.split(separator: "/").last
            guard let resultParse = parseFolder?.components(separatedBy: ".zip").first else { logWarn("Assets folder is nil"); return nil }
            
            return Model3D(
                styles: Styles.parse(json: json),
                idModel: json?["idModel"]?.toString() ?? "",
                idNodo: json?["idNodo"]?.toString() ?? "",
                assetsFolder: resultParse,
                idModelAnim: json?["idModelAnim"]?.toString(),
                idNodoAnim: json?["idNodoAnim"]?.toString()
            )
        }
        return nil
    }
}
