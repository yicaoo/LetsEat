//
//  DocumentBrowserViewController.swift
//  LetsEat
//
//  Created by Yi Cao on 5/20/18.
//  Copyright © 2018 Yi Cao. All rights reserved.
//

import UIKit

class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        allowsDocumentCreation = false
        allowsPickingMultipleItems = false
 
        // create a url to our template
        templateURL = try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
            ).appendingPathComponent(DocumentConstants.untitledCookBook)
        
        // try to create the template document if needed
        if templateURL != nil {
            // if the template document can be created, allow document creation
            allowsDocumentCreation = FileManager.default.createFile(atPath: templateURL!.path, contents: Data())
        } else {
            addGenericAlert(message: DocumentConstants.templateCreationAlertMessage, alertTitle: DocumentConstants.templateCreationTitle, actionTitle: DocumentConstants.dismiss)
        }
    }
    
    private struct DocumentConstants {
        static let untitledCookBook = "Untitled.cookbook"
        static let documentMVC = "DocumentMVC"
        static let main = "Main"
        static let templateCreationAlertMessage = "Couldn't create template"
        static let templateCreationTitle = "Template Creation Failure"
        static let dismiss = "Dismiss"
    }
    
    // template file
    private var templateURL: URL?
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        importHandler(templateURL, .copy)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentURLs documentURLs: [URL]) {
        guard let sourceURL = documentURLs.first else { return }
        
        // Present the Document View Controller for the first document that was picked.
        // If you support picking multiple items, make sure you handle them all.
        presentDocument(at: sourceURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        // Present the Document View Controller for the new newly created document
        presentDocument(at: destinationURL)
    }
    
    // this is called when an error occurred trying to open
    // a document from somewhere outside our app
    // we should put up an Alert here, but we don't know how to do that yet (next week!)
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
    }
    
    // MARK: Document Presentation
    func presentDocument(at documentURL: URL) {
        let storyBoard = UIStoryboard(name: DocumentConstants.main, bundle: nil)
        let mvc = storyBoard.instantiateViewController(withIdentifier: DocumentConstants.documentMVC)
        if let cookingCollectionViewController = mvc.contents as? CookingCollectionViewController {
            
            cookingCollectionViewController.document = CookBookDocument(fileURL: documentURL)
            present(mvc, animated: true)
        }
    }
}

