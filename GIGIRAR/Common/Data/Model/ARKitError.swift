//
//  ARKitError.swift
//  EjemploAR
//
//  Created by Eduardo Parada on 23/01/2019.
//  Copyright © 2019 Eduardo Parada. All rights reserved.
//

import Foundation

import Foundation


enum CustomError: Error {
    case unexpectedJSONFormat
    case networkError
    case unknown
    case apiError(message: String?)
}

extension Error {
    
    static func jsonBadFormat() -> Error {
        return NSError(domain: "", code: -1, message: "Json is bad format")
    }
}
