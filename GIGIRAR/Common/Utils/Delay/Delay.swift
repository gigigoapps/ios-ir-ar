//
//  Delay.swift
//  GIGIRAR
//
//  Created by Eduardo Parada on 29/01/2019.
//  Copyright © 2019 Eduardo Parada. All rights reserved.
//

import Foundation

func delay(_ delay: Double, closure: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(
        deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure
    )
}

func async(closure: @escaping () -> Void) {
    delay(0, closure: closure)
}
