//
//  Location+CoreDataProperties.swift
//  MyLocations
//
//  Created by liushun on 16/1/5.
//  Copyright © 2016年 liushun. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData
import CoreLocation
extension Location {

    @NSManaged var category: String?
    @NSManaged var date: NSDate
    @NSManaged var latitude: Double
    @NSManaged var locationDescription: String?
    @NSManaged var longitude: Double
    @NSManaged var placemark: CLPlacemark?
    @NSManaged var photoID: NSNumber?
}
