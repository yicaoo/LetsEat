//
//  HealthViewController.swift
//  LetsEat
//
//  Created by Yi Cao on 5/30/18.
//  Copyright © 2018 Yi Cao. All rights reserved.
//  Citation: https://crunchybagel.com/accessing-activity-rings-data-from-healthkit/, https://www.raywenderlich.com/169004/calayer-tutorial-ios-getting-started

import UIKit
import HealthKit

class HealthViewController: UIViewController, UIPopoverPresentationControllerDelegate, UITextFieldDelegate {
    private let healthKitStore = HKHealthStore()
    private let blurView = UIVisualEffectView(effect:UIBlurEffect(style: .extraLight))
    @IBOutlet weak var stepsImage: UIImageView!
    @IBOutlet weak var distanceImage: UIImageView!
    private var popDismissObserver: NSObjectProtocol?

 override func viewDidLoad() {
        super.viewDidLoad()
        healthKitAuthorization()
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapToDismiss(_sender:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        popDismissObserver = NotificationCenter.default.addObserver(forName:.dismissTimerPopover, object: nil, queue: OperationQueue.main) { (notification) in
            self.blurView.removeFromSuperview()
        }
    }
    
    // add blur view to the view controller's view that presents the popover
    private func addBlurEffect() {
        blurView.alpha = NumberConstants.blurViewAlpha
        blurView.frame = view.bounds
        let vibrancyEffect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: UIBlurEffectStyle.light))
        let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.contentView.addSubview(vibrancyView)
        view.addSubview(blurView)
    }
    
    @objc func tapToDismiss(_sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    // draw CAText on to the UIImage
    private func addTextToImage(text: String, view: UIImageView) {
        view.layer.sublayers?.removeLast()
        let textLayer = CATextLayer()
        textLayer.frame = view.bounds
        view.clipsToBounds = true
        textLayer.string = text
        textLayer.fontSize = NumberConstants.fontSize
        textLayer.foregroundColor = UIColor.gray.cgColor
        textLayer.isWrapped = true
        textLayer.alignmentMode = kCAAlignmentLeft
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.needsDisplayOnBoundsChange = true
        view.layer.addSublayer(textLayer)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination.contents as? PopTimerViewController {
            if let popController = destination.popoverPresentationController {
                popController.delegate = self
                addBlurEffect()
            }
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    //MARK: -HealthKit
    // query healthkit data when the user selects a new date
    @IBAction func changeDate(_ sender: UIDatePicker) {
        querySteps(on: sender.date)
        queryDistance(on: sender.date)
    }
    
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var caffineInput: UITextField!
    @IBOutlet weak var proteinInput: UITextField!
    
    // access to health kit requires extensive authorization
    private func healthKitAuthorization() {
        guard let distanceWalkRun = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning), let stepCount = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount), let caffineAmount = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryCaffeine), let proteinAmount = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryProtein)
            else {
                return
        }
        let readData: Set<HKObjectType> = [distanceWalkRun, stepCount]
        let writeData: Set<HKSampleType> = [caffineAmount, proteinAmount]
        if HKHealthStore.isHealthDataAvailable() {
            if healthKitStore.authorizationStatus(for: distanceWalkRun) == .sharingAuthorized && healthKitStore.authorizationStatus(for: stepCount) == .sharingAuthorized && healthKitStore.authorizationStatus(for: caffineAmount) == .sharingAuthorized && healthKitStore.authorizationStatus(for: proteinAmount) == .sharingAuthorized {
                self.querySteps(on: Date())
                self.queryDistance(on: Date())
                return
            }
            healthKitStore.requestAuthorization(toShare: writeData, read: readData, completion: {(success, error) in
                if success {
                    self.querySteps(on: Date())
                    self.queryDistance(on: Date())
                } else {
                    self.addAlertCheckSettings(message: AlertConstants.accessHealthKitAlertMessage, alertTitle: AlertConstants.accessHealthKitAlertTitle, actionTitle: AlertConstants.dismiss)
                }
                return
            })
        } else {
            addGenericAlert(message: AlertConstants.kitNotOnDeviceAlertMessage, alertTitle: AlertConstants.accessDined, actionTitle: AlertConstants.dismiss)
        }
    }
    
    // query the number of steps waked
    private func querySteps(on date: Date) {
        let predicate = getPredicate(on: date)
        let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let query = HKStatisticsQuery(quantityType: stepsQuantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_, result, error) in
            guard let result = result else {
                DispatchQueue.main.async {
                    self.addTextToImage(text: StringConstants.unknown, view: self.stepsImage)
                }
                return
            }
            var processedResult = Int(NumberConstants.initialProcessedResult)
            if let sum = result.sumQuantity() {
                processedResult = Int(sum.doubleValue(for: HKUnit.count()))
            }
            DispatchQueue.main.async {
                let displayText = StringConstants.walked + String(processedResult) + StringConstants.steps
                self.addTextToImage(text: displayText, view: self.stepsImage)
            }
        }
        healthKitStore.execute(query)
    }
    
    // query walking and running distance
    private func queryDistance(on date: Date) {
        let predicate = getPredicate(on: date)
        let distanceQuantityType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let query = HKStatisticsQuery(quantityType: distanceQuantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_, result, error) in
            guard let result = result else {
                DispatchQueue.main.async {
                    self.addTextToImage(text: StringConstants.unknown, view: self.distanceImage)
                }
                return
            }
            var processedResult = NumberConstants.initialProcessedResult
            if let sum = result.sumQuantity() {
                processedResult = (sum.doubleValue(for: HKUnit.mile()) * NumberConstants.roundMultiplier).rounded(.down)/NumberConstants.roundMultiplier
            }
            DispatchQueue.main.async {
                let displayText = StringConstants.runwalk + String(processedResult) + StringConstants.miles
                self.addTextToImage(text: displayText, view: self.distanceImage)
            }
        }
        healthKitStore.execute(query)
    }

    // form date predicate
    private func getPredicate(on date: Date)->NSPredicate {
        let startOfDay = Calendar.current.startOfDay(for: date)
        var components = DateComponents()
        components.day = NumberConstants.currentDay
        components.second = NumberConstants.subtractSecond
        let endOfTheSameDay = Calendar.current.date(byAdding: components, to: startOfDay)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfTheSameDay, options: .strictStartDate)
        return predicate
    }
    

    @IBAction func enterDataToHealthKit(_ sender: UIButton) {
        enterCaffineData()
        enterProteinData()
    }
    
    private func enterProteinData() {
        if let protein = proteinInput.text, let proteinField = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryProtein), let proteinAmount = Double(protein) {
            let quantity = HKQuantity(unit: HKUnit.gram(), doubleValue: proteinAmount)
            let data = HKQuantitySample(type: proteinField, quantity: quantity, start: datePicker.date, end: datePicker.date)
            self.healthKitStore.save(data, withCompletion: { (success, error) in
                guard success else {
                    self.addGenericAlert(message: AlertConstants.proteinDataSavingAlertMessage, alertTitle:AlertConstants.error , actionTitle: AlertConstants.dismiss)
                    return
                }
            })
        } else {
            addGenericAlert(message: AlertConstants.proteinValidIntputAlertMessage, alertTitle: AlertConstants.validIntputAlertTitle, actionTitle: AlertConstants.dismiss)
        }
    }
    
    private func enterCaffineData() {
        if let caffine = caffineInput.text, let caffineField = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.dietaryCaffeine), let caffineAmount = Double(caffine) {
            let quantity = HKQuantity(unit: HKUnit.gramUnit(with: .milli), doubleValue: caffineAmount)
            let data = HKQuantitySample(type: caffineField, quantity: quantity, start: datePicker.date, end: datePicker.date)
            self.healthKitStore.save(data, withCompletion: { (success, error) in
                guard success else {
                    self.addGenericAlert(message: AlertConstants.caffineDataSavingAlertMessage, alertTitle: AlertConstants.error, actionTitle: AlertConstants.dismiss)
                    return
                }
            })
        } else {
            addGenericAlert(message: AlertConstants.caffineValidIntputAlertMessage, alertTitle: AlertConstants.validIntputAlertTitle, actionTitle: AlertConstants.dismiss)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let observer = self.popDismissObserver{
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private struct StringConstants {
        static let walked = "Walked\n"
        static let steps = "\nsteps"
        static let runwalk = "Distance\n"
        static let miles = "\nmi"
        static let unknown = "No\nHealth\nData"
    }
    private struct NumberConstants {
        static let fontSize = CGFloat(20)
        static let roundMultiplier = Double(10)
        static let blurViewAlpha = CGFloat(0.5)
        static let currentDay = 1
        static let subtractSecond = -1
        static let initialProcessedResult = 0.0
    }
    private struct AlertConstants {
        static let accessHealthKitAlertMessage = "Can't access Health Kit"
        static let accessHealthKitAlertTitle = "Access Denied"
        static let dismiss = "Dismiss"
        static let kitNotOnDeviceAlertMessage = "Health kit is not available on this device"
        static let accessDined = "Access Denied"
        static let proteinDataSavingAlertMessage = "Failed to save protein data"
        static let error = "Error"
        static let proteinValidIntputAlertMessage = "Please enter protein amount"
        static let validIntputAlertTitle = "Invalid Input"
        static let caffineDataSavingAlertMessage = "Failed to save caffine data"
        static let caffineValidIntputAlertMessage = "Please enter caffine amount"
    }
}

