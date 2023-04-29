//
//  Network.swift
//  faer
//
//  Created by venus on 29.03.18.
//  Copyright © 2018 pluto. All rights reserved.
//

import Foundation
import SystemConfiguration

class Network {
    
    static let shared: Network = Network()
    
    func isReachable() -> Bool {
        
        guard let reachability = SCNetworkReachabilityCreateWithName(nil, "www.google.com") else { return true }
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags()
        
        SCNetworkReachabilityGetFlags(reachability, &flags)

        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
        let canConnectWithoutUserInteraction = canConnectAutomatically && !flags.contains(.interventionRequired)
        
        return isReachable && (!needsConnection || canConnectWithoutUserInteraction)
    }
    
}
