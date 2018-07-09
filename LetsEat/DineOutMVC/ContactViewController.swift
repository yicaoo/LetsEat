//
//  ContactViewController.swift
//  LetsEat
//
//  Created by Yi Cao on 6/4/18.
//  Copyright © 2018 Yi Cao. All rights reserved.
//  Citation: https://www.raywenderlich.com/97936/address-book-tutorial-swift-ios

import UIKit
import Contacts

class ContactViewController: UIViewController{
    private var contactStore = CNContactStore()
    var businessNumber: String!
    var name: String!
    private var keyboardObserver: NSObjectProtocol?
    private var hideKeyboardObserver: NSObjectProtocol?
    //default contact name and phone is the restruant's name and phone
    @IBOutlet weak var nameField: UITextField! {
        didSet{
            nameField.text = name
        }
    }
    @IBOutlet weak var phoneField: UITextField!{
        didSet{
            phoneField.text = businessNumber
        }
    }
    @IBOutlet weak var addContactButton: UIButton!
    @IBOutlet weak var contactStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkContactAccess()
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapToDismiss(_sender:)))
        view.addGestureRecognizer(tap)
    }
    
    private func checkContactAccess() {
        if CNContactStore.authorizationStatus(for: .contacts) != .authorized {
            contactStore.requestAccess(for: .contacts, completionHandler:{(success, error) in
                guard success else {
                    self.addAlertCheckSettings(message: AlertConstants.accessContactAlertMessage, alertTitle: AlertConstants.accessContactTitle, actionTitle: AlertConstants.dismiss)
                    self.addContactButton.isEnabled = false
                    return
                }
                return
            })
        }
    }
    
    @objc func tapToDismiss(_sender: UITapGestureRecognizer) {
        adjustViewSize()
        view.endEditing(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        adjustViewSize()
    }
    //adjust popover size to fit
    private func adjustViewSize() {
        if let fittedSize = contactStackView?.sizeThatFits(UILayoutFittingCompressedSize) {
            preferredContentSize = CGSize(width: fittedSize.width + ContactConstants.padding, height: fittedSize.height + ContactConstants.padding)
        }
    }
    
    // add phone and name to contact
    @IBAction func addContact(_ sender: UIButton) {
        let entry = CNMutableContact()
        // check valid organization name input
        if let organization = nameField.text {
            entry.organizationName = organization
        } else {
            addGenericAlert(message: AlertConstants.validNameAlertMessage, alertTitle: AlertConstants.validNameAlertTitle, actionTitle: AlertConstants.dismiss)
        }
        // check valid phone input
        if let phone = phoneField.text {
            entry.phoneNumbers = [CNLabeledValue(label: CNLabelWork,
                                                 value: CNPhoneNumber(stringValue: phone))]
        } else {
            addGenericAlert(message: AlertConstants.validPhoneAlertMessage, alertTitle: AlertConstants.validPhoneAlertTitle, actionTitle: AlertConstants.dismiss)
        }
        let request = CNSaveRequest()
        if checkForDuplicates(name: entry.organizationName) {
            request.add(entry, toContainerWithIdentifier: nil)
            do{
                try contactStore.execute(request)
                addGenericAlert(message: AlertConstants.contactSaveAlertMessage, alertTitle: AlertConstants.success, actionTitle: AlertConstants.dismiss)
                
            } catch {
                addGenericAlert(message: AlertConstants.contactSaveFailMessage, alertTitle: AlertConstants.contactSaveFailTitle, actionTitle: AlertConstants.dismiss)
            }
        }
    }
    
    // check for duplicate entry before input into contact
    private func checkForDuplicates(name: String)->Bool {
        let predicate: NSPredicate = CNContact.predicateForContacts(matchingName: name)
        do {
            let contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch:[CNContactOrganizationNameKey as CNKeyDescriptor])
            if contacts.isEmpty {
                return true
            } else {
                let message = name + AlertConstants.contactExistMessage
                addGenericAlert(message: message, alertTitle: AlertConstants.contactExistAlertTitle, actionTitle: AlertConstants.dismiss)
                return false
            }
        } catch {
            addGenericAlert(message: AlertConstants.unableSearchAlertMessage, alertTitle: AlertConstants.unableSearchAlertTitle, actionTitle: AlertConstants.dismiss)
        }
        return false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.post(name: NSNotification.Name.dismissContactPopover, object: nil)
    }

    private struct ContactConstants {
        static let padding = CGFloat(20)
    }
    
    private struct AlertConstants {
        static let accessContactAlertMessage = "Can't access contact"
        static let accessContactTitle = "Access Denied"
        static let dismiss = "Dismiss"
        static let contactExistAlertTitle = "Contact Already Exisit"
        static let contactExistMessage = " is already in your contact list."
        static let unableSearchAlertMessage = "Unable to search contact list"
        static let unableSearchAlertTitle = "Search Contact Failed"
        static let validNameAlertTitle = "Invalid Name"
        static let validNameAlertMessage = "Please Enter Valid Name"
        static let validPhoneAlertTitle = "Invalid Phone Number"
        static let validPhoneAlertMessage = "Please Enter Valid Phone Number"
        static let success = "Success"
        static let contactSaveAlertMessage = "Contact is Successfully Added"
        static let contactSaveFailMessage = "Unable to Save Contact"
        static let contactSaveFailTitle = "Contact Saving Failure"
    }
}
