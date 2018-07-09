//
//  MapViewController.swift
//  LetsEat
//
//  Created by Yi Cao on 5/22/18.
//  Copyright © 2018 Yi Cao. All rights reserved.
// Reading Citation: https://www.spaceotechnologies.com/current-gps-location-ios-app-core-location-framework/, https://www.thorntech.com/2016/01/how-to-search-for-location-using-apples-mapkit/, https://stackoverflow.com/questions/28152526/how-do-i-open-phone-settings-when-a-button-is-clicked?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa
// Video Citation: Paul's iOS 9 Lecture #17

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate{
    
    private var foundRestaraunts = [MKMapItem]()
    private var setPins = [CustomAnnotation]()
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapLabel: UILabel!
    private let locationManager = CLLocationManager()
    private var currentCoordinate: CLLocationCoordinate2D!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapView.showAnnotations(mapView.annotations, animated: true)
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        checkConnection()
    }
    
    // check internet connection: if not connected: take user to wifi setting
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
            mapLabel.text = DisplayConstants.noMatchText
        }
    }
    
    //custome annotation button setup
    private func setUpDriveButton()->UIButton {
        let driveButton = UIButton(type: .custom)
        let driveImage = UIImage(named: DisplayConstants.drive)
        driveButton.frame = CGRect(x: DisplayConstants.buttonX, y: DisplayConstants.buttonY, width: DisplayConstants.buttonSize, height: DisplayConstants.buttonSize)
        driveButton.setImage(driveImage!, for: UIControlState())
        return driveButton
    }
    
    private func setUpSearchButton()->UIButton {
        let searchButton = UIButton(type: .custom)
        let searchImage = UIImage(named: DisplayConstants.search)
        searchButton.frame = CGRect(x: DisplayConstants.buttonX, y: DisplayConstants.buttonY, width: DisplayConstants.buttonSize, height: DisplayConstants.buttonSize)
        searchButton.setImage(searchImage!, for: UIControlState())
        return searchButton
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // do not replace user location with custom pin
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
        pin!.leftCalloutAccessoryView = setUpDriveButton()
        pin!.rightCalloutAccessoryView = setUpSearchButton()
        return pin
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        currentCoordinate =  locations.first?.coordinate
        let region = MKCoordinateRegion(center: currentCoordinate, span: MKCoordinateSpan(latitudeDelta: MapConstants.directionDelta, longitudeDelta: MapConstants.directionDelta))
        mapView.setRegion(region, animated: true)
        performSearch()
    }
    
    // search for nearby restaruants
    private func performSearch() {
        let searchRequest = MKLocalSearchRequest()
        searchRequest.naturalLanguageQuery = self.title
        searchRequest.region = MKCoordinateRegion(center: currentCoordinate, span: MKCoordinateSpan(latitudeDelta: MapConstants.directionDelta, longitudeDelta: MapConstants.directionDelta))
        let search = MKLocalSearch(request: searchRequest)
        search.start(completionHandler: {(response, error) in
            if let response = response {
                if error != nil {
                    self.addGenericAlert(message: AlertConstants.searchErrorAlertMessage, alertTitle: AlertConstants.searchErrorAlertTitle, actionTitle: AlertConstants.actionTitle)
                } else if response.mapItems.count == 0 {
                    self.addGenericAlert(message: AlertConstants.searchAlertMessage,alertTitle:AlertConstants.searchAlertTitle, actionTitle: AlertConstants.actionTitle)
                } else {
                    self.foundRestaraunts.removeAll()
                    self.mapView.removeAnnotations(self.setPins)
                    self.setPins.removeAll()
                    for item in response.mapItems {
                        print(item)
                        self.addItemAnnotation(item: item)
                    }
                    self.setUpLabel()
                }
            }
        })
    }
    
    // if the found restaruants have phone number and valid name, add to the list of found restaruants and add annotations
    private func addItemAnnotation(item: MKMapItem) {
        if let phone = item.phoneNumber, let name = item.name {
            self.foundRestaraunts.append(item)
            let annotation = CustomAnnotation(title: name, subtitle: phone, coordinate: item.placemark.coordinate)
            self.setPins.append(annotation)
            self.mapView.addAnnotation(annotation)
            self.mapView.showAnnotations(self.mapView.annotations, animated: true)
        }
    }
    
    private func setUpLabel() {
        let placeCount = String(foundRestaraunts.count)
        mapLabel.text = DisplayConstants.foundNearby + placeCount + DisplayConstants.whiteSpace + self.title! + DisplayConstants.places
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            performSegue(withIdentifier: StoryboardConstants.webSegue, sender: view)
        }
        if control == view.leftCalloutAccessoryView {
            if let destinationCoordinate = view.annotation?.coordinate, let destinationTitle = view.annotation?.title {
                goToNavigation(coordinate: destinationCoordinate, name: destinationTitle!)
            }
        }
    }
    
    // go to map driving naviation, prompt the user with alert
    private func goToNavigation(coordinate: CLLocationCoordinate2D, name: String) {
        let location = coordinate
        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving, MKLaunchOptionsShowsTrafficKey: true] as [String : Any]
        let placemark = MKPlacemark(coordinate: location)
        let item = MKMapItem(placemark: placemark)
        item.name = name
        let alert = UIAlertController(title: AlertConstants.directionAlertTitle, message: AlertConstants.directionAlertMessage, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: AlertConstants.yes, style: .destructive, handler: {action in
            item.openInMaps(launchOptions: launchOptions)
        }))
        alert.addAction(UIAlertAction(title: AlertConstants.cancel, style: .default, handler:nil))
        present(alert, animated: true)
    }
    
    // prepare for web search of restaurant
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == StoryboardConstants.webSegue {
            if let info = (sender as? MKAnnotationView)?.annotation as? CustomAnnotation {
                if let webVC = segue.destination as? WebViewController {
                    webVC.queryParameter = info.title!
                    webVC.phoneNumber = info.subtitle!
                    webVC.title = info.title!
                }
            }
        }
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
        static let gotoWIFI = "Go to WIFI Settings"
        static let wifiURL = "App-Prefs:root=WIFI"
        static let directionAlertTitle = "Leave For Direction"
        static let directionAlertMessage = "Are you sure to leave current page to go to driving direction"
        static let yes = "Yes"
        static let cancel = "Cancel"
    }
    
    private struct StoryboardConstants {
        static let webSegue = "webSegue"
        static let customAnnotation = "customAnnotation"
    }
    
    private struct DisplayConstants {
        static let noMatchText = "Sorry, can't perform search."
        static let foundNearby = "Found Nearby "
        static let places = " Places"
        static let whiteSpace = " "
        static let drive = "drive"
        static let search = "search"
        static let buttonX = 0
        static let buttonY = 0
        static let buttonSize = 30
    }
    
    private struct MapConstants {
        static let directionDelta = 0.1
    }
}
