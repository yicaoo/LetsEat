//
//  RootPageViewController.swift
//  LetsEat
//
//  Created by Yi Cao on 6/4/18.
//  Copyright © 2018 Yi Cao. All rights reserved.
//  Citation: https://www.youtube.com/watch?v=jVBtDH6jjl8

import UIKit

class RootPageViewController: UIPageViewController, UIPageViewControllerDataSource {
    lazy var viewControllerList: [UIViewController] = {
        let storyBoard = UIStoryboard(name:LaunchPageConstants.main, bundle: nil)
        let dineOutIntroViewController = storyBoard.instantiateViewController(withIdentifier: LaunchPageConstants.dineOutIntro)
        let cookIntroViewController = storyBoard.instantiateViewController(withIdentifier: LaunchPageConstants.cookIntro)
        let exerciseIntroViewController = storyBoard.instantiateViewController(withIdentifier: LaunchPageConstants.exerciseIntro)
        return [dineOutIntroViewController, cookIntroViewController, exerciseIntroViewController]
    }()
    
    // gives previous view controller
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let viewControllerIndex = viewControllerList.index(of: viewController) {
            let previousIndex = viewControllerIndex - 1
            if viewControllerList.count > previousIndex && previousIndex >= 0 {
                return viewControllerList[previousIndex]
            }
        }
        return nil
    }
    // gives next view controller
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let viewControllerIndex = viewControllerList.index(of: viewController) {
            let nextIndex = viewControllerIndex + 1
            if viewControllerList.count > nextIndex {
                return viewControllerList[nextIndex]
            }
        }
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        if let firstViewController = viewControllerList.first {
            self.setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // mark that user has launched the app for the first time
        let userDefaults = UserDefaults.standard
        userDefaults.set(true, forKey:LaunchPageConstants.appLaunch)
        userDefaults.synchronize()
    }
    
    private struct LaunchPageConstants{
        static let main = "Main"
        static let dineOutIntro = "dineOutIntro"
        static let cookIntro = "cookIntro"
        static let exerciseIntro = "exerciseIntro"
        static let appLaunch = "appLaunched"
    }
}
