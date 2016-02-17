//
//  LocationDetailsViewController.swift
//  MyLocations
//
//  Created by liushun on 15/12/24.
//  Copyright © 2015年 liushun. All rights reserved.
//

import UIKit
import CoreLocation
import Dispatch
import CoreData

class LocationDetailsViewController: UITableViewController{
    
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    // 添加图片相关的两个控件
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var addPhotoLabel: UILabel!
    
    // 如果没选图片就是空的所以得是Optional
    var image: UIImage? {
        // 属性观察器
        didSet {
            if let image = image {
                imageView.image = image
                imageView.hidden = false
                imageView.frame = CGRect(x: 5, y: 5, width: 260, height: 260)
                addPhotoLabel.hidden = true
            }
        }
    }
    
    // 顶端的textView
    var descriptionText = ""
    
    // 坐标相关
    var coordinate = CLLocationCoordinate2D(latitude: 0,longitude: 0)
    var placemark: CLPlacemark?
    
    // 暂时存储选中的category
    var categoryName = "No Category"
    
    // 由AppDelegate一直传过来
    var managedObjectContext: NSManagedObjectContext!
    
    // 当前日期
    var date = NSDate()
    
    // 暂存一个引用，便于析构的时候销毁
    var observer: AnyObject!
    
    // 待编辑的Location，做一个属性观察器
    var locationToEdit: Location? {
        // 每次给locationToEdit赋值 且!=nil 时就会调用这段
        didSet {
            if let location = locationToEdit {
                descriptionText = location.locationDescription!
                categoryName = location.category!
                date = location.date
                coordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude)
                placemark = location.placemark
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let _ = locationToEdit {
            title = "Edit Location"
        }
        
        // 跳转完页面给页面标签赋值
        descriptionTextView.text = descriptionText
        categoryLabel.text = categoryName
        latitudeLabel.text = String(format: "%.8f", coordinate.latitude)
        longitudeLabel.text = String(format: "%.8f", coordinate.longitude)
        
        // 还是赋值，坐标转换成具体的地址(隐式解包)
        if let placemark = placemark {
            addressLabel.text = stringFromPlacemark(placemark)
            
        }else{
            addressLabel.text = "No Address Found"
        }
        dateLabel.text = formatDate(date)
        
        // 加个手势用于点空白处隐藏键盘
        // gesture 可以识别touches and finger movements
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: Selector("hideKeyboard:"))
        gestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(gestureRecognizer)
    }
    
    // 隐藏键盘
    func hideKeyboard(gr: UIGestureRecognizer){
        // 返回一个CGPoint，点的位置
        let point = gr.locationInView(tableView)
        let indexPath = tableView.indexPathForRowAtPoint(point)
        if indexPath != nil && indexPath!.section == 0 && indexPath!.row == 0 {
            return
        }
        descriptionTextView.resignFirstResponder()
    }
    
    // 跳转页面并传值和
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PickCategory" {
            let controller = segue.destinationViewController as! CategoryPickerViewController
            controller.selectedCategoryName = categoryName
        }
    }
    
    // 显示实际的地址，区/街道地址等信息
    func stringFromPlacemark(placemark: CLPlacemark) -> String {
        return "\(placemark.subThoroughfare) \(placemark.thoroughfare)\n \(placemark.locality) \(placemark.administrativeArea)  \(placemark.postalCode)"
    }
    
    // 选择完图片后显示图片
    func showImage(image: UIImage) {
        imageView.image = image
        imageView.hidden = false
        imageView.frame = CGRect(x: 5, y: 5, width: 260, height: 260)
        addPhotoLabel.hidden = true
    }
    
    /* 立即执行此闭包，并返回给变量  To create the object and */
    /* set its properties in one go you can use a closure */
    private let dateFormatter: NSDateFormatter = {
        // 第一步创建变量，主要是固定其类型
        let formatter = NSDateFormatter()
        // 第二步给赋值
        formatter.dateStyle = .MediumStyle
        formatter.timeStyle = .ShortStyle
        // 然后返回
        return formatter
    }()
    
    /* 日期转换成字符串，但是这是一个昂贵的操作,所以是懒加载的。*/
    /* In Swift globals are always created in a lazy fashion */
    func formatDate(date: NSDate) -> String {
        return dateFormatter.stringFromDate(date)
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.section == 0 || indexPath.section == 1 {
            return indexPath
        }else{
            return nil
        }
    }
    
    // 根据点的不同的section出不同的页面
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            descriptionTextView.becomeFirstResponder()
        }else if indexPath.section == 1 && indexPath.row == 0 {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            pickPhoto()
        }
    }
    
    // table view加载cell的时候调用设定每个cell高度
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch (indexPath.section,indexPath.row) {
            case (0,0):
                return 88
            case (1,_):
                return imageView.hidden ? 44 : 280
            case(2,2):
                addressLabel.frame.size = CGSize(width: view.bounds.size.width - 115, height: 10000)
                addressLabel.sizeToFit()
                addressLabel.frame.origin.x = view.bounds.size.width - addressLabel.frame.size.width - 15
                return addressLabel.frame.size.height + 20
            default:
                return 44
        }

/* 如果是有两个以上的条件判断，可以考虑用switch
        if indexPath.section == 0 && indexPath.row == 0{
            return 88
        }else if indexPath.section == 1{
            if imageView.hidden {
                return 44
            } else {
                return 280
            }
        }else if indexPath.section == 2 && indexPath.row == 2 {
            addressLabel.frame.size = CGSize(width: view.bounds.size.width - 115, height: 10000)
            // 适配宽度，而且会去右边的空格
            addressLabel.sizeToFit()
            addressLabel.frame.origin.x = view.bounds.size.width - addressLabel.frame.size.width - 15
            return addressLabel.frame.size.height + 20
        }else{
            return 44
        }*/
    }
    
    // 比较极端的情况下的提升用户体验，比如拍照的时候按Home键了再返回的时候隐藏已经打开的选择框框等
    func listenForBackgroundNotification() {
        observer = NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidEnterBackgroundNotification, object: nil,queue: NSOperationQueue.mainQueue()){
            [weak self] _ in
//            if self.presentationController != nil {
//                self.dismissViewControllerAnimated(false, completion: nil)
//            }
//            
//            self.descriptionTextView.resignFirstResponder()
            if let strongSelf = self {
                if strongSelf.presentedViewController != nil {
                    strongSelf.dismissViewControllerAnimated(false, completion: nil)
                }
                strongSelf.descriptionTextView.resignFirstResponder()
            }
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        descriptionTextView.frame.size.width = view.frame.size.width - 30
    }
    
    // 和prepareForSegue一起用，有一个特殊的参数UIStoryboardSegue
    @IBAction func categoryPickerDidPickCategory(segue: UIStoryboardSegue){
        let controller = segue.sourceViewController as! CategoryPickerViewController
        categoryName = controller.selectedCategoryName
        categoryLabel.text = categoryName
    }
    
    // 点完done了以后 save/update 并且弹出一个提示
    @IBAction func done() {
        let hudView = HudView.hudInView(navigationController!.view, animated: true)
        var location: Location
        if let temp = locationToEdit {
            hudView.text = "Updated"
            location = temp
        } else {
            hudView.text = "Tagged"
            location = NSEntityDescription.insertNewObjectForEntityForName("Location", inManagedObjectContext: managedObjectContext) as! Location
            location.photoID = nil
        }
        location.locationDescription = descriptionText
        location.category = categoryName
        location.latitude = coordinate.latitude
        location.longitude = coordinate.longitude
        location.date = date
        location.placemark = placemark
        if let image1 = image {
            if !location.hasPhoto {
                location.photoID = Location.nextPhotoID()
            }
            
            // swift处理异常的固定写法
            if let data = UIImageJPEGRepresentation(image1, 0.5) {
                do {
                    try data.writeToFile(location.photoPath, options: .DataWritingAtomic)
                } catch {
                    print("Error writing pictures file: \(error)")
                }
            }
        }
        
        do {
            try managedObjectContext.save()
        } catch {
            fatalError("save failed...")
        }
    
        // 本身应该是这样写:(0.6, closure: { closure body })
        afterDelay(1.1){
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func cancel() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    deinit {
        print("*** deinit \(self)")
        // removeObserver(observer)会报错
        //NSNotificationCenter.defaultCenter().removeObserver(observer)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}

// 用拓展监控每次输入将内容打印
extension LocationDetailsViewController: UITextViewDelegate {
    func textView(textView: UITextView,shouldChangeTextInRange range: NSRange,replacementText text: String) -> Bool {
        descriptionText = (textView.text as NSString).stringByReplacingCharactersInRange(range, withString: text)
        return true
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        descriptionText = textView.text
    }
}

// 用拓展的方式将照片相关的功能放到一起
extension LocationDetailsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func pickPhoto() {
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            takePhotoWithCamera()
        } else {
            showPhotoMenu()
        }
    }
    
    func showPhotoMenu() {
        // UIAlertController是从底部弹出的Alert
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        // 出现三个选择的选项
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        // 闭包里是处理点击后的逻辑
        let takePhotoAction = UIAlertAction(title: "Take Photo", style: .Default, handler: {
            _ in self.takePhotoWithCamera()
        })
        alertController.addAction(takePhotoAction)
        
        let chooseFromLibraryAction = UIAlertAction(title: "Choose From Library", style: .Default, handler: {
            _ in self.choosePhotoFromLibrary()
        })
        alertController.addAction(chooseFromLibraryAction)
        
        // 选择项的弹出方式
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    // 拍照
    func takePhotoWithCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .Camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    // 选照片
    func choosePhotoFromLibrary() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .PhotoLibrary
        imagePicker.delegate = self
        // 允许编辑照片
        imagePicker.allowsEditing = true
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    // 完成
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        // image = info[UIImagePickerControllerEditedImage] as! UIImage?
        self.image = info[UIImagePickerControllerEditedImage] as! UIImage?
//        if let image = image {
//            showImage(image)
//        }
        
        // 重载一下cell，适配有图时候的高度
        tableView.reloadData()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // 取消
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
