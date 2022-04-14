//
//  MockURLProtocol.swift
//  pipe
//
//  Created by Jonathan Rivera on 01/04/22.
//  Copyright © 2022 Jonathan Rivera. All rights reserved.
//

import Foundation

public class MockURLProtocol: URLProtocol {
    
    public override class func canInit(with request: URLRequest) -> Bool {
        //checar si este protocolo puede entregar un request
        return true
    }
    
    public override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    //1.- Handler para testear el request y devolver la respuesta mock
    public static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?, Error?))?
    
    public override func startLoading() {
        //2. LLamar al handler y capturar la tupla con el response, data y error
        let (response, data, error) = try! MockURLProtocol.requestHandler!(request)
        
        //3. Revisamos si el request tiene un error
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
        }
        
        //4. Enviamos al cliente la respuesta
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        
        //5. Validamos el data y se lo enviamos al cliente
        if let data = data {
            client?.urlProtocol(self, didLoad: data)
        }
        
        //6. notificacmos que la peticion ha terminado
        client?.urlProtocolDidFinishLoading(self)
    }
    
    public override func stopLoading() {
        
    }
}
