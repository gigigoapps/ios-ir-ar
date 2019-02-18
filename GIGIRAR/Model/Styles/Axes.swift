//
//  Axes.swift
//  GIGIRAR
//
//  Created by eduardo parada pardo on 28/01/2019.
//  Copyright © 2019 Eduardo Parada. All rights reserved.
//

import Foundation
import GIGLibrary

struct Axes {
    var x: Float
    var y: Float
    var z: Float
    
    // MARK: - Public method
    
    static func parse(json: JSON?, key: String) -> Axes? {
        if let styles = json?[key] {
            return Axes(
                x: Float(styles["x"]?.toDouble() ?? 1),
                y: Float(styles["x"]?.toDouble() ?? 1),
                z: Float(styles["x"]?.toDouble() ?? 1)
            )
        }
        
        return nil
    }
}
