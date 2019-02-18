//
//  ArKitManagerServices.swift
//  EjemploAR
//
//  Created by Eduardo Parada on 23/01/2019.
//  Copyright © 2019 Eduardo Parada. All rights reserved.
//

import Foundation
import GIGLibrary

enum ResponseConfiguration {
    case success(json: JSON)
    case error(error: CustomError)
}

enum ResposeDownloadImag {
    case success(img: UIImage)
    case error(error: CustomError)
}

enum ResposeDownload3DModel {
    case success()
    case error(error: CustomError)
}

protocol ARKitManagerServicesOutput {
    func configurationDid(response: ResponseConfiguration)
    func downloadImageDidFinish(response: ResposeDownloadImag)
    func download3DModelDidFinish(response: ResposeDownload3DModel)
}

protocol ARKitManagerServicesInput {
    func getConfiguration(id: String)
    func downloadImages(url: String, id: String)
    func download3DModelWith(id: String, urlDisk: URL)
}

class ARKitManagerServices {
    var output: ARKitManagerServicesOutput?
    
    // MARK: - Private Method
    
    private func downloadZip(url: String, urlDisk: URL) {
        let request = Request(
            method: Constants.Get,
            baseUrl: url,
            endpoint: "",
            headers: nil,
            urlParams: nil,
            bodyParams: nil,
            verbose: ARKitLogger.logLevel >= .info,
            standard: .basic
        )
        request.fetch(withDownloadUrlFile: urlDisk) { response in
            switch response.status {
            case .success:
                self.output?.download3DModelDidFinish(response: .success())
                
            case .noInternet:
                self.output?.configurationDid(response: .error(error: .networkError))
                
            default:
                self.output?.configurationDid(response: .error(error: .apiError(message: response.error?.localizedDescription)))
            }
        }
    }
}

extension ARKitManagerServices: ARKitManagerServicesInput {
    
    func getConfiguration(id: String) {  // TODO falta enviar este id de proyecto
        let request = Request(
            method: Constants.Get,
            baseUrl: Constants.ConfigUrl,
            endpoint: "",
            headers: nil,
            urlParams: nil,
            bodyParams: nil,
            verbose: ARKitLogger.logLevel >= .info,
            standard: .basic
        )
        request.fetch { response in
            switch response.status {
            case .success:
                guard
                    let json = try? response.json(),
                    let recosJson = json["listReco"]
                    else {
                        logWarn("Recos is nil")
                        return
                }
                
                self.output?.configurationDid(response: .success(json: recosJson))
                
            case .noInternet:
                self.output?.configurationDid(response: .error(error: .networkError))
                
            default:
                self.output?.configurationDid(response: .error(error: .apiError(message: response.error?.localizedDescription)))
            }
        }
    }
    
    func downloadImages(url: String, id: String) {
        let request = Request(
            method: Constants.Get,
            baseUrl: url,
            endpoint: ""
        )
        request.fetch { response in
            switch response.status {
            case .success:
                guard let image = try? response.image() else { return }
                image.accessibilityValue = id
                self.output?.downloadImageDidFinish(response: .success(img: image))
                
            case .noInternet:
                self.output?.downloadImageDidFinish(response: .error(error: .networkError))
                
            default:
                self.output?.downloadImageDidFinish(response: .error(error: .apiError(message: response.error?.localizedDescription)))
            }
        }
    }
    
    func download3DModelWith(id: String, urlDisk: URL) {
        self.downloadZip(url: id, urlDisk: urlDisk)
    }
}
