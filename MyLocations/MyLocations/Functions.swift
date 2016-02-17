//
//  Functions.swift
//  MyLocations
//
//  Created by liushun on 16/1/4.
//  Copyright © 2016年 Leo)Xcode 7.2. All rights reserved.
//

import Foundation
import Dispatch

// this is a free function not method
func afterDelay(seconds: Double, closure: () -> ()){
    let when = dispatch_time(DISPATCH_TIME_NOW,Int64(seconds * Double(NSEC_PER_SEC)))
    dispatch_after(when,dispatch_get_main_queue(), closure)
}

