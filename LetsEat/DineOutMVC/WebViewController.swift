//
//  WebViewController.swift
//  LetsEat
//
//  Created by Yi Cao on 5/23/18.
//  Copyright © 2018 Yi Cao. All rights reserved.
//  Reading Citation: https://www.raywenderlich.com/158106/urlsession-tutorial-getting-started, https://www.appcoda.com/webkit-framework-intro/

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate, UIPopoverPresentationControllerDelegate {
    var queryParameter: String!
    var phoneNumber: String!
    private let blurView = UIVisualEffectView(effect:UIBlurEffect(style: .extraLight))
    @IBOutlet weak var webView: WKWebView!
    private var popDismissObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if var urlComponents = URLComponents(string: WebConstants.googleImageURL) {
            //set current view controller to observe the estimatedProgress
            webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
            urlComponents.query = WebConstants.queryPrefix + queryParameter
            guard let url = urlComponents.url else { return }
            checkConnection()
            let urlRequest: URLRequest = URLRequest(url: url)
            print(url)
            webView.load(urlRequest)
            popDismissObserver = NotificationCenter.default.addObserver(forName:.dismissContactPopover, object: nil, queue: OperationQueue.main) { (notification) in
                self.blurView.removeFromSuperview()
            }
        }
    }

    @IBAction func backButtonAction(_ sender: UIButton) {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    @IBAction func forwardButtonAction(_ sender: UIButton) {
        if webView.canGoForward {
            webView.goForward()
        }
    }
    
    @IBOutlet weak var progressDisplay: UIProgressView!
    // progress view
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == WebConstants.estimatedProgress {
            progressDisplay.progress = Float(webView.estimatedProgress)
        }
    }
    
    // error alert: when an error occurs while the web view is loading content.
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        addGenericAlert(message: AlertConstants.loadPageAlertMessage, alertTitle: AlertConstants.loadPageAlertTitle, actionTitle: AlertConstants.actionTitle)
    }
    
    private func checkConnection() {
        if !Reachability.isConnectedToNetwork(){
            let alert = UIAlertController(
                title: AlertConstants.connectionAlertTitle,
                message: AlertConstants.connectionMessage,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: AlertConstants.wifiAlertTitle, style: .destructive, handler: {action in
                UIApplication.shared.open(URL(string:WebConstants.wifiURLString)!, options: [:], completionHandler: nil)
            }))
            alert.addAction(UIAlertAction(
                title: AlertConstants.actionTitle,
                style: .default
            ))
            self.present(alert, animated: true)
        }
    }
    
    // when user clicks the contact button, present pop over and blur the rest
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ViewConstants.contactSegue {
            if let destination = segue.destination as? ContactViewController {
                destination.businessNumber = phoneNumber
                destination.name = queryParameter
                if let contactVC = destination.popoverPresentationController {
                    contactVC.delegate = self
                    addBlurEffect()
                }
            }
        }
    }
    
    private func addBlurEffect() {
        blurView.alpha = ViewConstants.blurEffectAlpha
        blurView.frame = view.bounds
        let vibrancyEffect = UIVibrancyEffect(blurEffect: UIBlurEffect(style: UIBlurEffectStyle.light))
        let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.contentView.addSubview(vibrancyView)
        view.addSubview(blurView)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let observer = self.popDismissObserver{
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    @IBAction func callRestaurant(_ sender: UIButton) {
        let parsedNum = (phoneNumber).phoneNumberParser(inputString: phoneNumber)
        let callString = WebConstants.telURLPrefix + parsedNum
        let phoneURL = URL(string: callString)!
        let application = UIApplication.shared
        if application.canOpenURL(phoneURL) {
            application.open(phoneURL, options: [:], completionHandler: nil)
        } else {
            addGenericAlert(message: AlertConstants.callAlertMessage, alertTitle:AlertConstants.callAlertTitle, actionTitle: AlertConstants.actionTitle)
        }
    }
    
    // MARK: Constants
    private struct AlertConstants {
        static let connectionAlertTitle = "No Internet Connection"
        static let connectionMessage = "Please Check Your Internet Connection."
        static let actionTitle = "Dismiss"
        static let loadPageAlertTitle = "Page Loading Failure"
        static let loadPageAlertMessage = "Couldn't load the google image page."
        static let callAlertMessage =  "Phone call is not an option on this device"
        static let callAlertTitle = "Can't Call"
        static let wifiAlertTitle = "Go to WIFI Settings"
    }
    
    private struct WebConstants {
        static let googleImageURL = "http://www.google.com/images"
        static let queryPrefix = "q="
        static let estimatedProgress = "estimatedProgress"
        static let wifiURLString = "App-Prefs:root=WIFI"
        static let telURLPrefix = "tel:"
    }
    
    private struct ViewConstants {
        static let contactSegue = "contactSegue"
        static let blurEffectAlpha = CGFloat(0.4)
    }
}
