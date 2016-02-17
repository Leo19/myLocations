//
//  CategoryPickerViewController.swift
//  MyLocations
//
//  Created by liushun on 15/12/25.
//  Copyright © 2015年 liushun. All rights reserved.
//

import UIKit

class CategoryPickerViewController: UITableViewController {
    var selectedCategoryName = ""
    
    // 要展示到table上的数组元素
    let categories = [
        "No Category",
        "Apple Store",
        "Bar",
        "Bookstore",
        "Club",
        "Grocery Store",
        "Historic Building",
        "House",
        "Icecream Vendor",
        "Landmark",
        "Park"
    ]
    
    // 所选择的序号
    var selectedIndexPath = NSIndexPath()
    
    // MARK: - UITableViewDataSource
    // 确定table有几个row
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        // 复用一个id==Cell的cell
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell")! as UITableViewCell
        
        // 给cell赋值
        let categoryName = categories[indexPath.row]
        cell.textLabel!.text = categoryName
        
        // 点一下选中，再点取消选中。同时记录选中的indexPath
        if categoryName == selectedCategoryName {
            cell.accessoryType = .Checkmark
            selectedIndexPath = indexPath
        }else{
            cell.accessoryType = .None
        }
        
        return cell
    }
    
    // 点右上角Exit触发unwind的方式segue，并且要和另外一个并用，最简单的页面传值
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PickedCategory" {
            let cell = sender as! UITableViewCell
            if let indexPath = tableView.indexPathForCell(cell){
                selectedCategoryName = categories[indexPath.row]
            }
        }
    }
    
    // MARK: UITableViewDelegate
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row != selectedIndexPath.row {
            
            if let newCell = tableView.cellForRowAtIndexPath(indexPath){
                newCell.accessoryType = .Checkmark
            }
            
            if let oldCell = tableView.cellForRowAtIndexPath(selectedIndexPath){
                oldCell.accessoryType = .None
            }
            
            selectedIndexPath = indexPath
        }
    }
}
