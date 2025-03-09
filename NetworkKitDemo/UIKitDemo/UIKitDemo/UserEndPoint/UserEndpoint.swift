//
//  UserEndpoint.swift
//  UIKitDemo
//
//  Created by Zuhaib Imtiaz on 09/03/2025.
//

import ZBNetworkKit

struct UserEndpoint: ZBEndpointProvider {
    
    var path: String { "/users" }
    var method: RequestMethod { .GET }
}
