//
//  LastIntroPageViewController.swift
//  LetsEat
//
//  Created by Yi Cao on 6/5/18.
//  Copyright © 2018 Yi Cao. All rights reserved.
//

import UIKit
// custom class for the last intro page for animation 
class LastIntroPageViewController: UIViewController {
    
    @IBOutlet weak var bottomBlurView: UIVisualEffectView! {
        didSet{
            bottomBlurView.alpha = AnimationConstant.blurViewInitialAlpha
        }
    }
    
    @IBOutlet weak var getStartedButton: UIButton! {
        didSet {
            getStartedButton.alpha = AnimationConstant.buttonInitialAlpha
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateKeyDrop()
    }
    
    private func animateKeyDrop() {
        let originalFrame = getStartedButton.frame
        getStartedButton.frame = CGRect(x: self.view.frame.midX, y: -self.view.frame.height*AnimationConstant.half, width: getStartedButton.bounds.width, height: getStartedButton.bounds.height)
        getStartedButton.alpha = AnimationConstant.buttonAnimationAlpha
        UIViewPropertyAnimator.runningPropertyAnimator(
            withDuration: AnimationConstant.layoutDuration,
            delay: AnimationConstant.anmiationDelay,
            options: [.curveEaseIn],
            animations: {
                self.getStartedButton.frame = originalFrame
                self.getStartedButton.layoutIfNeeded()
        }, completion: { finished in
            self.bottomBlurView.alpha = AnimationConstant.blurViewAfterAlpha
            
        })
    }
    override func viewWillDisappear(_ animated: Bool) {
        bottomBlurView.alpha = AnimationConstant.blurViewInitialAlpha
        getStartedButton.alpha = AnimationConstant.buttonInitialAlpha
    }
    
    private struct AnimationConstant {
        static let layoutDuration = 2.0
        static let blurViewInitialAlpha = CGFloat(0.1)
        static let buttonInitialAlpha = CGFloat(0)
        static let buttonAnimationAlpha = CGFloat(1.0)
        static let half = CGFloat(0.5)
        static let anmiationDelay = 1.0
        static let blurViewAfterAlpha = CGFloat(0.9)
    }
}
