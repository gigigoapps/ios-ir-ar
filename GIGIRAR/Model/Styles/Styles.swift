//
//  Styles.swift
//  GIGIRAR
//
//  Created by eduardo parada pardo on 28/01/2019.
//  Copyright © 2019 Eduardo Parada. All rights reserved.
//

import Foundation
import GIGLibrary

struct Styles {
    var scale: Axes?
    var position: Axes?
    
    // MARK: - Public method
    
    static func parse(json: JSON?) -> Styles? {
        if let styles = json?["styles"] {
            return Styles(
                scale: Axes.parse(json: styles, key: "scale"),
                position: Axes.parse(json: styles, key: "position")
            )
        }
        
        return nil
    }
}
