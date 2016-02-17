//
//  LocationCell.swift
//  MyLocations
//
//  Created by liushun on 16/1/7.
//  Copyright © 2016年 liushun. All rights reserved.
//

import UIKit

class LocationCell: UITableViewCell {
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    // 专门用于创建Label的方法
    func configureForLocation(location: Location){
        if location.locationDescription!.isEmpty{
            descriptionLabel.text = "OMG"
        } else {
            descriptionLabel.text = location.locationDescription
        }
        
        if let placemark = location.placemark {
            addressLabel.text = "\(placemark.subThoroughfare) \(placemark.thoroughfare), \(placemark.locality)"
        } else {
            addressLabel.text = String(format: "Lat: %.8f, Long: %.8f", location.latitude, location.longitude)
        }
    }
}
