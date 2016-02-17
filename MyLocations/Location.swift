//
//  Location.swift
//  MyLocations
//
//  Created by liushun on 16/1/5.
//  Copyright © 2016年 liushun. All rights reserved.
//

import Foundation
import CoreData
import MapKit

@objc(Location)
class Location: NSManagedObject, MKAnnotation{
    
    // MKAnnotaion 遵守这个Protocol必须要实现的三个属性
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2DMake(latitude, longitude)
    }
    
    var title: String? {
        if locationDescription!.isEmpty {
            return "(No Description)"
        } else {
            return locationDescription
        }
    }
    
    var subTitle: String? {
        return category
    }
    
    var hasPhoto: Bool {
        return photoID != nil
    }
    
    var photoPath: String {
        assert(photoID != nil, "No photo ID set")
        let filename = "Photo-\(photoID!.integerValue).jpg"
        return (applicationDocumentsDirectory as NSString).stringByAppendingPathComponent(filename)
    }
    let applicationDocumentsDirectory: String = {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        return paths[0]
    }()
    
    // 返回一个一个UIImage
    var photoImage: UIImage? {
        return UIImage(contentsOfFile: photoPath)
    }
    
    class func nextPhotoID() -> Int {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let currentID = userDefaults.integerForKey("PhotoID")
        userDefaults.setInteger(currentID + 1, forKey: "PhotoID")
        userDefaults.synchronize()
        return currentID
    }
}
