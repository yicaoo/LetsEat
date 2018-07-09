//
//  EventTableViewController.swift
//  LetsEat
//
//  Created by Yi Cao on 5/31/18.
//  Copyright © 2018 Yi Cao. All rights reserved.
//  Video Citation: https://www.youtube.com/watch?v=sSFzcvvs4Oc, https://stackoverflow.com/questions/38319116/trying-to-make-picker-view-input-for-several-textfields-separately?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa

import UIKit
import CoreLocation
import EventKit

class EventTableViewController: UITableViewController, MapSearchDelegate, UITextFieldDelegate{
    
    @IBOutlet weak var startTime: UITextField! {
        didSet {
            startTime.delegate = self
        }
    }
    @IBOutlet weak var endTime: UITextField! {
        didSet {
            endTime.delegate = self
        }
    }
    @IBOutlet weak var alarmTime: UITextField! {
        didSet {
            alarmTime.delegate = self
        }
    }
    @IBOutlet weak var eventName: UITextField!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var reminderButton: UIButton!
    @IBOutlet weak var eventButton: UIButton!
    private var activeTextField: UITextField?
    private let eventStore = EKEventStore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        eventName.delegate = self
        requestEventAuthorization()
        tableView.tableFooterView = UIView()
        configureDatePickerInput()
    }
    private var shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    private func configureDatePickerInput() {
        let datePicker = UIDatePicker()
        datePicker.addTarget(self, action: #selector(dateChanged(datePicker:)), for: .valueChanged)
        // set input view to date picker directly
        endTime.inputView = datePicker
        alarmTime.inputView = datePicker
        startTime.inputView = datePicker
        // tap outside to dismiss
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapToDismiss(_sender:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func tapToDismiss(_sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        activeTextField = textField
        // so that user can default to current time without changing the textfield
        if activeTextField != eventName {
            activeTextField?.text = shortDateFormatter.string(from: Date())
        }
        return true
    }
    
    // record the date picker date change action and enter the date
    @objc func dateChanged(datePicker: UIDatePicker) {
        activeTextField?.text = shortDateFormatter.string(from: datePicker.date)
        view.endEditing(true)
    }
    
    // request authorization for event and reminder
    private func requestEventAuthorization(){
        if EKEventStore.authorizationStatus(for: .event) != .authorized {
            eventStore.requestAccess(to: .event, completion: {
                (success, error) in
                guard success else {
                    self.addAlertCheckSettings(message: AlertConstants.eventAlertMessage, alertTitle: AlertConstants.accessDenied, actionTitle: AlertConstants.dismiss)
                    self.eventButton.isEnabled = false
                    return
                }
            })
        }
        if EKEventStore.authorizationStatus(for: .reminder) != .authorized {
            eventStore.requestAccess(to: .reminder, completion: {
                (success, error) in
                guard success else {
                    self.addAlertCheckSettings(message: AlertConstants.reminderAlertMessage, alertTitle: AlertConstants.accessDenied, actionTitle: AlertConstants.dismiss)
                    self.reminderButton.isEnabled = false
                    return
                }
                self.reminderButton.isEnabled = true
            })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let mapSearchViewController = segue.destination as? MapSearchViewController {
            mapSearchViewController.delegate = self
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let tableHeight = (tableView.bounds.height - tableView.contentInset.top - tableView.contentInset.bottom) / EventConstants.numEntry
        return tableHeight
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        textField.resignFirstResponder()
        return true
    }
    var selectedLocation: CLLocation?
    
    func locationSelected(location: CLLocationCoordinate2D?, place: String?) {
        if let fetchedLocation = location, let selectedPlace = place {
            selectedLocation = CLLocation(latitude: fetchedLocation.latitude, longitude: fetchedLocation.longitude)
            locationLabel.text = EventConstants.eventLocation + selectedPlace
        } else {
            locationLabel.text = EventConstants.noLocation
            selectedLocation = nil
        }
    }
    
    // add location based reminder
    @IBAction func addLocationReminderEventToCalendar(_ sender: UIButton) {
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = eventName.text ?? EventConstants.defaultText
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
        if let locationData = selectedLocation, let text = locationLabel.text {
            let location = EKStructuredLocation(title: text)
            location.geoLocation = locationData
            let alarm = EKAlarm()
            alarm.structuredLocation = location
            alarm.proximity = .enter
            reminder.addAlarm(alarm)
            do {
                try eventStore.save(reminder, commit: true)
                addGenericAlert(message:  AlertConstants.successAdded, alertTitle:  AlertConstants.successTitle, actionTitle:  AlertConstants.dismiss)
            } catch {
                addGenericAlert(message:  AlertConstants.failedToAdd, alertTitle:  AlertConstants.failureTitle, actionTitle:  AlertConstants.dismiss)
            }
        } else {
            addGenericAlert(message: AlertConstants.validLocationAlertMessage, alertTitle: AlertConstants.validLocationAlertMessage, actionTitle: AlertConstants.dismiss)
        }
    }
    
    // add event
    @IBAction func addAlarmReminder(_ sender: UIButton) {
        let event = EKEvent(eventStore: eventStore)
        event.title = eventName.text ?? EventConstants.defaultText
        if let eventStart = shortDateFormatter.date(from:startTime.text!), let eventEnd = shortDateFormatter.date(from:endTime.text!), let eventAlarm = shortDateFormatter.date(from:alarmTime.text!) {
            event.startDate = eventStart
            event.endDate = eventEnd
            event.calendar = eventStore.defaultCalendarForNewEvents
            let alarm = EKAlarm()
            alarm.absoluteDate = eventAlarm
            event.addAlarm(alarm)
            do {
                try eventStore.save(event, span: .thisEvent)
                addGenericAlert(message: AlertConstants.successAdded, alertTitle:  AlertConstants.successTitle, actionTitle:  AlertConstants.dismiss)
            } catch {
                addGenericAlert(message:  AlertConstants.failedToAdd, alertTitle:  AlertConstants.failureTitle, actionTitle:  AlertConstants.dismiss)
            }
        } else {
            addGenericAlert(message:  AlertConstants.validDateAlertMessage, alertTitle:  AlertConstants.validDateAlertTitle, actionTitle:  AlertConstants.dismiss)
        }
    }
    
    private struct EventConstants {
        static let eventLocation = "Use Location: "
        static let defaultText = "Untitled"
        static let noLocation = "No location Selected"
        static let numEntry = CGFloat(9)
    }
    private struct AlertConstants {
        static let successAdded = "Event Added To Calendar"
        static let successTitle = "Success"
        static let failedToAdd = "Unable To Add Event"
        static let failureTitle = "Failed"
        static let validDateAlertMessage = "Please enter valid dates"
        static let validDateAlertTitle = "Failed to Add Event"
        static let dismiss = "Dismiss"
        static let eventAlertMessage = "Can't access event"
        static let accessDenied = "Access Denied"
        static let reminderAlertMessage = "Can't access reminder"
        static let validLocationAlertMessage = "Please enter valid location"
        static let validLocationAlertTitle = "Failed to Add Reminder"
    }
}
