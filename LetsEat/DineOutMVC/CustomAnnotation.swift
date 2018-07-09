//
//  CustomAnnotation.swift
//  LetsEat
//
//  Created by Yi Cao on 5/22/18.
//  Copyright © 2018 Yi Cao. All rights reserved.
//

import MapKit
//Custom annoation for mapview
class CustomAnnotation : NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(title: String, subtitle: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }
}
