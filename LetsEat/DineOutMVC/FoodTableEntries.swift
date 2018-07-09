//
//  FoodTableEntries.swift
//  LetsEat
//
//  Created by Yi Cao on 5/22/18.
//  Copyright © 2018 Yi Cao. All rights reserved.
//

import Foundation

class FoodTableEntries {
    func setUpFoodTableEntries()-> [FoodEntry] {
        var entries = [FoodEntry]()
        for name in DataBase.FoodCategory.name {
            let newFoodEntry = FoodEntry(name: name, photo: DataBase.FoodCategory.images[name]!, category: DataBase.FoodCategory.category[name]!, description: DataBase.FoodCategory.description[name]!)
            entries.append(newFoodEntry!)
        }
        return entries
    }
    
    func entryCategories() -> [String] {
        var category = [FoodConstant.all]
        for name in DataBase.FoodCategory.name {
            let newCategory = DataBase.FoodCategory.category[name]!
            if !category.contains(newCategory) {
                category.append(newCategory)
            }
        }
        return category
    }
    
    private struct FoodConstant {
        static let all = "All"
    }
}
