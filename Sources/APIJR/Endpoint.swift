//
//  Endpoint.swift
//  pipe
//
//  Created by Jonathan Rivera on 01/04/22.
//  Copyright © 2022 Jonathan Rivera. All rights reserved.
//

import Foundation

public protocol Endpoint {
    var scheme: String {get}
    var baseURL: String {get}
    var environment: String {get}
    var headers: [String: String] {get}
}
