//
//  FoodCategory.swift
//  LetsEat
//
//  Created by Yi Cao on 5/21/18.
//  Copyright © 2018 Yi Cao. All rights reserved.
//  Database of constants for dine out table

import Foundation

struct DataBase {
    struct FoodCategory {
        static var name = ["Ramen", "Sushi", "Pizza", "Pasta", "Salad", "Coffee"]
        static var images = ["Ramen": "ramen", "Sushi":"sushi", "Pizza":"pizza", "Pasta": "pasta", "Salad": "salad", "Coffee": "coffee"]
        static var category = ["Ramen": "Main", "Sushi": "Main", "Pizza" : "Main", "Pasta" : "Main", "Salad": "Appetizer", "Coffee": "Dessert"]
        static var description = ["Ramen": "Ramen is a Japanese dish. It consists of Chinese-style wheat noodles served in a meat or (occasionally) fish-based broth, often flavored with soy sauce or miso.", "Sushi":"Sushi is a Japanese dish of specially prepared vinegared rice sushi-meshi), usually with some sugar and salt, combined with a variety of ingredients, such as seafood, vegetables, and occasionally tropical fruits.", "Pizza":"Pizza is a traditional Italian dish consisting of a yeasted flatbread typically topped with tomato sauce and cheese and baked in an oven. It can also be topped with additional vegetables, meats, and condiments, and can be made without cheese.", "Pasta":"Pasta is a staple food of traditional Italian cuisine, with the first reference dating to 1154 in Sicily." , "Salad": "A salad is a dish consisting of a mixture of small pieces of food, usually vegetables.", "Coffee": "Coffee is a brewed drink prepared from roasted coffee beans, which are the seeds of berries from the Coffea plant. The genus Coffea is native to tropical Africa (specifically having its origin in Ethiopia and Sudan) and Madagascar, the Comoros, Mauritius, and Réunion in the Indian Ocean."]
    }
}
