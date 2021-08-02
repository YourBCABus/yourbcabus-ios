//
//  ApolloClient.swift
//  YourBCABus
//
//  Created by Anthony Li on 8/2/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import Apollo
import Foundation

class Network {
    static let shared = Network()
    
    private(set) lazy var apollo = ApolloClient(url: URL(string: "https://api.yourbcabus.com/graphql")!)
}
