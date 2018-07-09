//
//  FoodEntry.swift
//  LetsEat
//
//  Created by Yi Cao on 5/22/18.
//  Copyright © 2018 Yi Cao. All rights reserved.
//

import Foundation

class FoodEntry {
    var name: String
    var photo: String
    var category: String
    var description: String
    
    init?(name: String, photo: String, category: String, description: String) {
        self.name = name
        self.photo = photo
        self.category = category
        self.description = description
    }
}
