//
//  MapSearchViewController.swift
//  LetsEat
//
//  Created by Yi Cao on 5/31/18.
//  Copyright © 2018 Yi Cao. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

protocol MapSearchDelegate: class {
    func locationSelected(location: CLLocationCoordinate2D?, place: String?)
}

class MapSearchViewController: UIViewController, UISearchBarDelegate, CLLocationManagerDelegate, MKMapViewDelegate {
    weak var delegate: MapSearchDelegate?
    @IBOutlet weak var locationSearchBar: UISearchBar!
    
    @IBOutlet weak var mapView: MKMapView!
    private let locationManager = CLLocationManager()
    private var currentCoordinate: CLLocationCoordinate2D!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationSearchBar.delegate = self
        mapView.showAnnotations(mapView.annotations, animated: true)
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }

    // if user is not connected to the internet: bring to system WIFI setting
    private func checkConnection() {
        if !Reachability.isConnectedToNetwork(){
            let alert = UIAlertController(
                title: AlertConstants.connectionAlertTitle,
                message: AlertConstants.connectionMessage,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: AlertConstants.gotoWIFI, style: .destructive, handler: {action in
                UIApplication.shared.open(URL(string:AlertConstants.wifiURL)!, options: [:], completionHandler: nil)
            }))
            alert.addAction(UIAlertAction(
                title: AlertConstants.actionTitle,
                style: .default
            ))
            self.present(alert, animated: true)
        }
    }
    
    // MARK:-MapSearch
    @IBAction func cancelLocationSelection(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func setUpDirectionButton()->UIButton {
        let directionButton = UIButton(type: .custom)
        let directionImage = UIImage(named: DisplayConstants.route)
        directionButton.frame = CGRect(x: DisplayConstants.buttonX, y: DisplayConstants.buttonY, width: DisplayConstants.buttonSize, height: DisplayConstants.buttonSize)
        directionButton.setImage(directionImage!, for: UIControlState())
        return directionButton
    }
    
    private func setUpSelectionButton()->UIButton {
        let selectionButton = UIButton(type: .custom)
        let selectionImage = UIImage(named: DisplayConstants.select)
        selectionButton.frame = CGRect(x: DisplayConstants.buttonX, y: DisplayConstants.buttonY, width: DisplayConstants.buttonSize, height: DisplayConstants.buttonSize)
        selectionButton.setImage(selectionImage!, for: UIControlState())
        return selectionButton
    }
    
    // set up custom pins
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // do not set pin for user location
        if annotation is MKUserLocation {
            return nil
        }
        var pin = mapView.dequeueReusableAnnotationView(withIdentifier: StoryboardConstants.customAnnotation)
        if pin == nil {
            pin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: StoryboardConstants.customAnnotation)
            pin!.canShowCallout = true
        } else {
            pin!.annotation = annotation
        }
        pin!.leftCalloutAccessoryView = setUpDirectionButton()
        pin!.rightCalloutAccessoryView = setUpSelectionButton()
        return pin
    }

    // set map to user region
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        currentCoordinate =  locations.first?.coordinate
        let region = MKCoordinateRegion(center: currentCoordinate, span: MKCoordinateSpan(latitudeDelta: MapConstants.directionDelta, longitudeDelta: MapConstants.directionDelta))
        mapView.setRegion(region, animated: true)
    }
    
    // perform search on map
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        checkConnection()
        self.mapView.removeAnnotations(self.mapView.annotations)
        locationSearchBar.endEditing(true)
        locationSearchBar.resignFirstResponder()
        if let query = searchBar.text {
            let searchRequest = MKLocalSearchRequest()
            searchRequest.naturalLanguageQuery = query
            searchRequest.region = MKCoordinateRegion(center: currentCoordinate, span: MKCoordinateSpan(latitudeDelta: MapConstants.directionDelta, longitudeDelta: MapConstants.directionDelta))
            let search = MKLocalSearch(request: searchRequest)
            search.start(completionHandler: {(response, error) in
                if let response = response {
                    if error != nil {
                        self.addGenericAlert(message: AlertConstants.searchErrorAlertMessage, alertTitle: AlertConstants.searchErrorAlertTitle, actionTitle: AlertConstants.actionTitle)
                    } else if response.mapItems.count == 0 {
                        self.addGenericAlert(message: AlertConstants.searchAlertMessage, alertTitle: AlertConstants.searchAlertTitle, actionTitle: AlertConstants.actionTitle)
                    } else {
                        // add annotation to found locations
                        for item in response.mapItems {
                            let annotation = CustomAnnotation(title: item.name!, subtitle: DisplayConstants.prompt, coordinate: item.placemark.coordinate)
                            self.mapView.addAnnotation(annotation)
                            self.mapView.showAnnotations(self.mapView.annotations, animated: true)
                        }
                    }
                }
            })
        }
    }
    // deal with when left or right callout accessory view is clicked on
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // click on left to get direction
        if control == view.leftCalloutAccessoryView {
            if let destinationCoordinate = view.annotation?.coordinate {
                drawDirection(coordinate : destinationCoordinate)
            }
        }
        // click on right to select the location and pass the location info to the view controller that presented this current one
        if control == view.rightCalloutAccessoryView {
            NotificationCenter.default.post(name: .saveDescription, object: self)
            delegate?.locationSelected(location: view.annotation?.coordinate, place: (view.annotation?.title)!)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    private func drawDirection(coordinate: CLLocationCoordinate2D) {
        let request = MKDirectionsRequest()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: self.mapView.userLocation.coordinate.latitude, longitude: self.mapView.userLocation.coordinate.longitude)))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        request.transportType = .automobile
        MKDirections(request: request).calculate { [unowned self] response, error in
            if let error = error {
                self.addGenericAlert(message: error.localizedDescription, alertTitle: AlertConstants.directionAlertTitle, actionTitle: AlertConstants.searchAlertTitle)
            }
            if let routeResponse = response {
                for route in routeResponse.routes {
                    self.mapView.removeOverlays(self.mapView.overlays)
                    self.mapView.add(route.polyline, level: .aboveRoads)
                }
            }
        }
    }
    
    // render overlay as driving route
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = DisplayConstants.routeColor
        renderer.lineWidth = DisplayConstants.routeLineWidth
        return renderer
    }
    
    // MARK: Constants
    private struct AlertConstants {
        static let connectionAlertTitle = "No Internet Connection"
        static let connectionMessage = "Please Check Your Internet Connection."
        static let actionTitle = "Dismiss"
        static let searchAlertTitle = "No Match"
        static let searchAlertMessage = "No Match Can Be Found On Map."
        static let searchErrorAlertTitle = "Search Error"
        static let searchErrorAlertMessage = "An Error Occurred During Search."
        static let directionAlertTitle = "Direction Request Failed"
        static let gotoWIFI = "Go to WIFI Settings"
        static let wifiURL = "App-Prefs:root=WIFI"
    }
    
    private struct StoryboardConstants {
        static let webSegue = "webSegue"
        static let customAnnotation = "customAnnotation"
    }
    
    private struct DisplayConstants {
        static let noMatchText = "Sorry, can't perform search."
        static let foundNearby = "Found Nearby "
        static let places = " Places"
        static let prompt = "Select This Location?"
        static let whiteSpace = " "
        static let select = "select"
        static let route = "route"
        static let buttonX = 0
        static let buttonY = 0
        static let buttonSize = 30
        static let routeColor = UIColor.green
        static let routeLineWidth = CGFloat(2.0)
    }
    
    private struct MapConstants {
        static let directionDelta = 0.1
    }
    
}
