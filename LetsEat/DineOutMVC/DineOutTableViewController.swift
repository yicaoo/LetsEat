//
//  DineOutTableViewController.swift
//  LetsEat
//
//  Created by Yi Cao on 5/20/18.
//  Copyright © 2018 Yi Cao. All rights reserved.
//  Reading Citation: https://medium.com/@satindersingh71/uisearchcontroller-with-scope-filter-8195f6a11eff, https://www.raywenderlich.com/129059/self-sizing-table-view-cells
import UIKit
import AVFoundation

class DineOutTableViewController: UITableViewController, UISearchBarDelegate {
    
    var foodTableEntries = FoodTableEntries().setUpFoodTableEntries()
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    // MARK: -Search Control
    @IBOutlet weak var searchBar: UISearchBar! {
        didSet {
            searchBar.placeholder = StoryboardConstants.searchBarPlaceHolderText
            searchBar.scopeButtonTitles = FoodTableEntries().entryCategories()
        }
    }
    
    private var search = false

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.endEditing(true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // first check the category
        if let input = searchBar.text {
            var processedEntries = FoodTableEntries().setUpFoodTableEntries()
            let searchBarIndex = searchBar.selectedScopeButtonIndex
            if searchBar.scopeButtonTitles![searchBarIndex] != StoryboardConstants.allCategory {
                processedEntries = FoodTableEntries().setUpFoodTableEntries().filter( {FoodEntry -> Bool in
                    FoodEntry.category == searchBar.scopeButtonTitles![searchBarIndex]
                })
            }
            // then process search text
            if !input.isEmpty {
                foodTableEntries = processedEntries.filter( {FoodEntry -> Bool in
                        return FoodEntry.name.contains(input)
                })
            } else {
                foodTableEntries = processedEntries
            }
        }
        tableView.reloadData()
    }

    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        let selectedCategory = searchBar.scopeButtonTitles![selectedScope]
        if selectedCategory == StoryboardConstants.allCategory {
             foodTableEntries = FoodTableEntries().setUpFoodTableEntries()
        } else {
            foodTableEntries = FoodTableEntries().setUpFoodTableEntries().filter( {FoodEntry -> Bool in
                FoodEntry.category == selectedCategory
            })
        }
        tableView.reloadData()
    }
    
    // MARK: -Table
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return foodTableEntries.count
    }
    
    var maxImageAspectRatio = LayoutConstants.maxImageAspectRatio
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: StoryboardConstants.foodEntryIdentifier, for: indexPath) as! FoodCategoryTableViewCell
        let foodItem = foodTableEntries[indexPath.row].name
        cell.foodLabel.text = foodItem
        cell.foodPhoto.image = UIImage(named: foodTableEntries[indexPath.row].photo)
        let imageSize = UIImage(named: foodTableEntries[indexPath.row].photo)!.size
        let aspectRatio = imageSize.height/imageSize.width
        maxImageAspectRatio = (maxImageAspectRatio < aspectRatio) ? aspectRatio : maxImageAspectRatio
        cell.category.text = StoryboardConstants.category + foodTableEntries[indexPath.row].category
        cell.foodDescription.text = foodTableEntries[indexPath.row].description
        return cell
    }

    // Detecting shake motion does not require core motion: use UIEvent class
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            AudioServicesPlayAlertSound(SystemSoundID(MusicConstant.soundID))
            let row = (foodTableEntries.count - 1).arc4random
            // ***note here we can not directly access the table view cell with method cellForRow since it would return nil if the random row chosen is not visible!
            let chosenSearchName = foodTableEntries[row].name
            performSegue(withIdentifier: StoryboardConstants.mapSegue, sender: chosenSearchName)
        }
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
                if segue.identifier == StoryboardConstants.mapSegue {
                    // click on table view cell (thus visible, thus have cell) case
                     if let cell = sender as? FoodCategoryTableViewCell {
                        if let mapViewcontroller = segue.destination as? MapViewController {
                            mapViewcontroller.title = cell.foodLabel.text
                        }
                        // shake case
                     } else if let searchString = sender as? String {
                        if let mapViewcontroller = segue.destination as? MapViewController {
                            mapViewcontroller.title = searchString
                        }
                    }
            }
    }
    
    // MARK: Constants

    private struct StoryboardConstants {
        static let mapSegue = "mapSegue"
        static let foodEntryIdentifier = "foodEntry"
        static let searchBarPlaceHolderText = "Search Name"
        static let category = "Category: "
        static let allCategory = "All"
    }
    private struct LayoutConstants {
        static let imageViewMultipler = CGFloat(120)
        static let maxImageAspectRatio = CGFloat(0)
    }
    private struct MusicConstant{
        static let soundID = 1322
    }
}
