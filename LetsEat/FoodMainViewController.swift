//
//  FoodMainViewController.swift
//  LetsEat
//
//  Created by Yi Cao on 5/20/18.
//  Copyright © 2018 Yi Cao. All rights reserved.
//  Citation: https://stackoverflow.com/questions/39438008/how-can-i-repeat-animation-using-uiviewpropertyanimator-certain-number-of-time?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa

import UIKit
import AVFoundation

class FoodMainViewController: UIViewController {
    
    // @IBOutlet weak var cookView: UIVisualEffectView!
    
    @IBOutlet weak var exerciseView: UIView! {
        didSet{
            exerciseView.alpha = AnimationConstant.initialViewAlpha
        }
    }
    @IBOutlet weak var dineOutView: UIView! {
        didSet{
            dineOutView.alpha = AnimationConstant.initialViewAlpha
        }
    }
    @IBOutlet weak var cookView: UIView! {
        didSet{
            cookView.alpha = AnimationConstant.initialViewAlpha
        }
    }
  
    // show slide in only when first time entering the view
    private var firstTimeLoaded = true

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // for each view, animates its appearance sequencially
        let viewCollection = [dineOutView, cookView, exerciseView]
        for index in 0..<viewCollection.count {
            animateViewAppear(viewToAnimate: viewCollection[index]!, at: index)
        }
    }
    
    private func animateViewAppear(viewToAnimate: UIView, at index: Int) {
        if firstTimeLoaded {
            let originalFrame = viewToAnimate.frame
            viewToAnimate.frame = CGRect(x: self.view.bounds.width, y: originalFrame.midY - viewToAnimate.bounds.height*AnimationConstant.half, width: viewToAnimate.bounds.width, height: viewToAnimate.bounds.height)
            viewToAnimate.alpha = AnimationConstant.viewAnimationAlpha
            UIViewPropertyAnimator.runningPropertyAnimator(
                withDuration: AnimationConstant.layoutDuration,
                delay: TimeInterval(index),
                options: [.curveEaseIn],
                animations: {
                    viewToAnimate.frame = originalFrame
                    viewToAnimate.layoutIfNeeded()
            }, completion: { finished in
                self.animatePulsating(view: viewToAnimate)
            })
        } 
    }
    
    // repeatedly animate pulsating effect
    private func animatePulsating(view: UIView) {
        func repeatingAnimator(_ reversed: Bool = false) {
            let pulsating = UIViewPropertyAnimator(
                duration: AnimationConstant.pulsatingDuration, timingParameters: UICubicTimingParameters())
            pulsating.addAnimations {
                if reversed {
                    view.transform = CGAffineTransform.identity
                        .scaledBy(x: AnimationConstant.pulsatingScaleUp, y: AnimationConstant.pulsatingScaleUp)
                } else {
                    view.transform = CGAffineTransform.identity
                        .scaledBy(x: AnimationConstant.pulsatingSaleDown, y: AnimationConstant.pulsatingSaleDown)
                }
            }
            pulsating.addCompletion { _ in
                repeatingAnimator(!reversed)
            }
            pulsating.startAnimation()
        }
        repeatingAnimator()
    }
    
    // if not sure which view to enter: shake the phone
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            AudioServicesPlayAlertSound(SystemSoundID(MusicConstant.soundID))
           let chosenSegueIndex = StoryBoardConstant.segueGroup.count.arc4random
            performSegue(withIdentifier: StoryBoardConstant.segueGroup[chosenSegueIndex], sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        firstTimeLoaded = false
    }
    private struct AnimationConstant {
        static let layoutDuration = 1.5
        static let pulsatingDuration = 0.5
        static let pulsatingScaleUp = CGFloat(1.15)
        static let pulsatingSaleDown = CGFloat(0.95)
        static let initialViewAlpha = CGFloat(0)
        static let half = CGFloat(0.5)
        static let viewAnimationAlpha = CGFloat(1.0)
    }
    private struct StoryBoardConstant {
        static let segueGroup = ["showHealthSegue", "cookSegue", "dineOutSegue"]
    }
    private struct ShapeConstant {
        static let offset = CGFloat(0)
    }
    private struct MusicConstant{
        static let soundID = 1322
    }
}

