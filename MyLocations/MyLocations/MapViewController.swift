//
//  MapViewController.swift
//  MyLocations
//
//  Created by liushun on 16/1/13.
//  Copyright © 2016年 liushun. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    
    // 操作CoreData的manage，一步一步传递过来
    var managedObjectContext: NSManagedObjectContext!
    
    var locations = [Location]()
    
    @IBAction func showUser(){
        let region = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, 100, 100)
        mapView.setRegion(mapView.regionThatFits(region), animated: true)
    }
    
    @IBAction func showLocations(){
        let region = regionForAnnotations(locations)
        mapView.setRegion(region, animated: true)
    }
    
    func updateLocations(){
        mapView.removeAnnotations(locations)
        let entity = NSEntityDescription.entityForName("Location", inManagedObjectContext: managedObjectContext)
        let fetchRequest = NSFetchRequest()
        fetchRequest.entity = entity
        
        
        // locations = try! managedObjectContext.executeFetchRequest(fetchRequest) as! [Location]
        do {
            locations = try managedObjectContext.executeFetchRequest(fetchRequest) as! [Location]
            mapView.addAnnotations(locations)
        }catch{
            fatalCoreDataError(error)
        }
    }
    
    // 点那个小圆圈里面有个i的那个图标触发的事件，算作UIButton
    func showLocationDetails(sender: UIButton) {
        
    }
    
    func regionForAnnotations(annotations: [MKAnnotation]) -> MKCoordinateRegion {
        var region: MKCoordinateRegion
        
        switch annotations.count {
        case 0:
            region = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, 1000, 1000)
        case 1:
            let annotation = annotations[annotations.count - 1]
            region = MKCoordinateRegionMakeWithDistance(annotation.coordinate, 1000, 1000)
        default:
            var topLeftCoord = CLLocationCoordinate2D(latitude: -90, longitude: 180)
            var bottomRightCoord = CLLocationCoordinate2D(latitude: 90, longitude: -180)
            for annotaion in annotations {
                topLeftCoord.latitude = max(topLeftCoord.latitude,annotaion.coordinate.latitude)
                topLeftCoord.longitude = min(topLeftCoord.longitude,annotaion.coordinate.longitude)
                bottomRightCoord.latitude = min(bottomRightCoord.latitude,annotaion.coordinate.latitude)
                bottomRightCoord.longitude = max(bottomRightCoord.longitude, annotaion.coordinate.longitude)
            }
            
            let center = CLLocationCoordinate2D(latitude: topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) / 2,longitude: topLeftCoord.longitude - (topLeftCoord.longitude - bottomRightCoord.longitude) / 2)
            
            let extraSpace = 1.1
            let span = MKCoordinateSpan(latitudeDelta: abs(topLeftCoord.latitude - bottomRightCoord.latitude) * extraSpace, longitudeDelta: abs(topLeftCoord.longitude - bottomRightCoord.longitude) * extraSpace)
            
            region = MKCoordinateRegion(center: center, span: span)
        }
        return mapView.regionThatFits(region)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        //updateLocations()
        
        if !locations.isEmpty {
            showLocations()
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        // 1、判断annotation是否是一个Location对象
        guard annotation is Location else {
            return nil
        }
        
        // 2、创建annotationView
        let identifier = "Location"
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as! MKPinAnnotationView!
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            
            // 3、配置一下属性
            annotationView.enabled = true
            annotationView.canShowCallout = true
            annotationView.animatesDrop = false
            annotationView.pinTintColor = UIColor(red: 0.32, green: 0.82, blue: 0.4, alpha: 1)
            annotationView.tintColor = UIColor(white: 0.0, alpha: 0.5)
            
            // 4、地图上气泡右侧的按钮
            let rightButton = UIButton(type: .DetailDisclosure)
            rightButton.addTarget(self, action: Selector("showLocationDetails:"), forControlEvents: .TouchUpInside)
            annotationView.rightCalloutAccessoryView = rightButton
        } else {
            annotationView.annotation = annotation
        }
        
        // 5、设置按钮为tag
        let button = annotationView.rightCalloutAccessoryView as! UIButton
        if let index = locations.indexOf(annotation as! Location) {
            button.tag = index
        }
        return annotationView
    }
}