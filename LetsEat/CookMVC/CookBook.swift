//
//  CookBook.swift
//  LetsEat
//
//  Created by Yi Cao on 5/24/18.
//  Copyright © 2018 Yi Cao. All rights reserved.
//

import Foundation

class CookBook: Codable {
    var name = [String]()
    var imageData = [Data]()
    var imageAspectRatio = [Double]()
    var description = [String]()
    var imageCellWidth = ScaleConstants.imageCellDefaultWidth
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }

    init?(json: Data) {
        if let newValue = try? JSONDecoder().decode(CookBook.self, from: json) {
            self.name = newValue.name
            self.imageData = newValue.imageData
            self.imageAspectRatio = newValue.imageAspectRatio
            self.description = newValue.description
            self.imageCellWidth = newValue.imageCellWidth
        } else {
            return nil
        }
    }
    
    // put back initializer
    init(name: [String], imageData: [Data], imageAspectRatio: [Double], description: [String], imageCellWidth: Double) {
        self.name = name
        self.imageData = imageData
        self.imageAspectRatio = imageAspectRatio
        self.description = description
        self.imageCellWidth = imageCellWidth
    }
    
    private struct ScaleConstants {
        static let imageCellDefaultWidth = 300.0
    }
}
