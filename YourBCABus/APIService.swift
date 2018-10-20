//
//  APIService.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/19/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import Foundation

class APIService {
    static var shared = APIService()
    
    var url = URL(string: "https://db.yourbcabus.com")!
    
    func getBuses(schoolId: String, completion: ([Bus], Error) -> Void) {
        
    }
}
