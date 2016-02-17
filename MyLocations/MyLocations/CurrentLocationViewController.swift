//
//  FirstViewController.swift
//  MyLocations
//
//  Created by liushun on 15/12/21.
//  Copyright © 2015年 liushun. All rights `reserved.
//

import UIKit
import CoreLocation
import CoreData
class CurrentLocationViewController: UIViewController,CLLocationManagerDelegate {
    
    @IBOutlet weak var messageLabel: UILabel!
    
    // 经纬度和地址的label
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    // 获取和显示位置的按钮
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    
    // location manager
    let locationManager = CLLocationManager()
    
    // 位置变量
    var location: CLLocation?
    
    // 正在更新标识和位置错误变量
    var updatingLocation = false
    var lastLocationError: NSError?
    
    // 将经纬度解析成具体地理位置相关变量
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: NSError?
    
    // 给一个定位超时
    var timer: NSTimer?
    
    // 操作CoreData的manage，一步一步传递过来
    var managedObjectContext: NSManagedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureGetButton()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // 设置获取位置代理
    @IBAction func getLocation(sender: UIButton) {
        // 这两段会弹出一个消息，询问是否允许使用位置信息
        let authStatus: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
        if authStatus == .NotDetermined{
            locationManager.requestWhenInUseAuthorization()
            return
        }
        // 如果用户选择禁用位置信息展示一下提示信息
        if authStatus == .Denied || authStatus == .Restricted{
            showLocationServicesDeniedAlert()
        }
        // 如果正在获取位置就显示STOP
        if updatingLocation {
            stopLocationManager()
        }else{
            location = nil
            lastLocationError = nil
            placemark = nil
            lastGeocodingError = nil
            startLocationManager()
        }
        updateLabels()
        configureGetButton()
    }
    
    // 如果禁用位置信息，要显示一个提示消息
    func showLocationServicesDeniedAlert(){
        let alert = UIAlertController(title: "Location Services Disabled", message: "enable location service please", preferredStyle: UIAlertControllerStyle.Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(okAction)
        presentViewController(alert,animated: true,completion: nil)
    }
    
    // MARK:this is my house
    // TODO:this is my home
    // FIXME: fix me later
    // NSLocationWhenInUseUsageDescription
    // 一些定位失败后和重新定位后打印信息
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("didFailWithError \(error)")
        if error.code == CLError.LocationUnknown.rawValue{
            return
        }
        lastLocationError = error
        stopLocationManager()
        updateLabels()
        configureGetButton()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last! as CLLocation
        print("didUpdateLocations \(newLocation)")
        //lastLocationError = nil
        //location = newLocation
        // 1、两次定位之间的间隔<5秒就不重新定位
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        // 2、有时候返回的精确度是负数，舍弃
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        var distance = CLLocationDistance(DBL_MAX)
        if let location = location{
            distance = newLocation.distanceFromLocation(location)
            print("distance: \(distance)")
        }
        print(location)
        // 3、理论上来说每一次定位会比上一次更精确，如果不是则舍弃
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
            // 4、
            lastLocationError = nil
            location = newLocation
            updateLabels()
            // 5、如果是比预设的精度要高则结束定位
            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy{
                print("*** We're done!")
                stopLocationManager()
                configureGetButton()
                if distance > 0 {
                    performingReverseGeocoding = false
                }
            }
            if !performingReverseGeocoding{
                print("*** Going to geocode")
                performingReverseGeocoding = true
                // 不多做解释，trailling closure 挂尾闭包
                geocoder.reverseGeocodeLocation(location!, completionHandler: {
                    placemarks, error in
                    print("*** Found placemarks: \(placemarks), error: \(error)")
                    self.lastGeocodingError = error
                    if (error == nil && !placemarks!.isEmpty) {
                        print("placemarks")
                        self.placemark = (placemarks?.last)! 
                    }else{
                        self.placemark = nil
                    }
                    self.performingReverseGeocoding = false
                    self.updateLabels()
                })
            }
        }else if distance < 1.0 {
            let timeInterval = newLocation.timestamp.timeIntervalSinceDate(location!.timestamp)
            if timeInterval > 10 {
                print("*** Force done!")
                stopLocationManager()
                updateLabels()
                configureGetButton()
            }
        }
    }
    
    // 开始定位
    func startLocationManager(){
        if CLLocationManager.locationServicesEnabled(){
            locationManager.delegate = self
            //locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
            locationManager.startUpdatingLocation()
            updatingLocation = true
            // 设置一下超时信息
            timer = NSTimer.scheduledTimerWithTimeInterval(20, target: self, selector: Selector("didTimeOut"), userInfo: nil, repeats: false)
        }
    }
    
    // 更新坐标信息到label中
    func updateLabels(){
        if let location = location{
            print("location")
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            tagButton.hidden = false
            messageLabel.text = ""
            if let placemark = placemark {
                print("placemark")
                addressLabel.text = stringFromPlacemark(placemark)
            }else if performingReverseGeocoding {
                addressLabel.text = "Searching for Address..."
            }else if lastGeocodingError != nil {
                addressLabel.text = "Error Finding Address"
            }else{
                addressLabel.text = "No Address Found"
            }
        }else{
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            addressLabel.text = ""
            tagButton.hidden = true
            
            // 展示各种不同情况之下的错误信息
            var statusMessage: String
            if let error = lastLocationError{
                if error.domain == kCLErrorDomain && error.code == CLError.Denied.rawValue{
                    statusMessage = "Location Services Disabled"
                }else{
                    statusMessage = "Error Getting Location"
                }
            }else if !CLLocationManager.locationServicesEnabled(){
                statusMessage = "Location Services Disabled"
            }else if updatingLocation{
                statusMessage = "Searching..."
            }else{
                statusMessage = "Tap 'Get My Location' to Start"
            }
            messageLabel.text = statusMessage
        }
    }
    
    // 跳转到下一个页面:TagLocation的方法
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "TagLocation" {
            let navigationController = segue.destinationViewController as! UINavigationController
            let controller = navigationController.topViewController as! LocationDetailsViewController
            // 有值的时候跳转按钮才可用，所以可以强制解包
            controller.coordinate = location!.coordinate
            controller.placemark = placemark
            controller.managedObjectContext = managedObjectContext
        }
    }
    
    // 停止获取位置
    func stopLocationManager(){
        if updatingLocation{
            if let timer = timer {
                timer.invalidate()
            }
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
        }
    }
    
    // 改变获取位置按钮的文字
    func configureGetButton(){
        if updatingLocation {
            getButton.setTitle("Stop", forState: .Normal)
        }else{
            getButton.setTitle("Get My Location", forState: .Normal)
        }
    }
    
    // 显示实际的地址，区/街道地址等信息
    func stringFromPlacemark(placemark: CLPlacemark) -> String {
        return "\(placemark.subThoroughfare) \(placemark.thoroughfare)\n \(placemark.locality) \(placemark.administrativeArea)  \(placemark.postalCode)"
    }
    
    // 处理超时的函数
    func didTimeOut(){
        print("*** Time Out")
        if location == nil {
            stopLocationManager()
            lastLocationError = NSError(domain: "MyLocationsErrorDomain", code: 1, userInfo: nil)
            updateLabels()
            configureGetButton()
        }
    }
}

