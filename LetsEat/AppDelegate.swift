//
//  AppDelegate.swift
//  FinalProject
//
//  Created by Yi Cao on 5/20/18.
//  Copyright © 2018 Yi Cao. All rights reserved.
//  Citation: set root view controlelr: https://stackoverflow.com/questions/22653993/programmatically-change-rootviewcontroller-of-storyboard/22656623?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch: if first time launch the app-show intro pages; otherwise cut directly to app
        let storyBoard = UIStoryboard(name: AppDelegateConstants.main, bundle: nil)
        let userDefaults = UserDefaults.standard
        window = UIWindow(frame: UIScreen.main.bounds)
        if userDefaults.bool(forKey: AppDelegateConstants.appLaunch) {
            self.window?.rootViewController = storyBoard.instantiateViewController(withIdentifier: AppDelegateConstants.content)
        } else {
            self.window?.rootViewController = storyBoard.instantiateViewController(withIdentifier: AppDelegateConstants.intro)
        }
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ app: UIApplication, open inputURL: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        // Ensure the URL is a file URL
        guard inputURL.isFileURL else { return false }
        
        // Reveal / import the document at the URL
        guard let documentBrowserViewController = window?.rootViewController as? DocumentBrowserViewController else { return false }
        
        documentBrowserViewController.revealDocument(at: inputURL, importIfNeeded: true) { (revealedDocumentURL, error) in
            if let error = error {
                print(AppDelegateConstants.failedOpenMessage+"\(error)")
                return
            }
            // Present the Document View Controller for the revealed URL
            documentBrowserViewController.presentDocument(at: revealedDocumentURL!)
        }
        
        return true
    }
    
    private struct AppDelegateConstants {
        static let main = "Main"
        static let appLaunch = "appLaunched"
        static let content = "appContent"
        static let intro = "intro"
        static let failedOpenMessage = "Failed to reveal the document: "
    }
    
}

