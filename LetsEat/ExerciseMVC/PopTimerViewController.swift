//
//  PopTimerViewController.swift
//  LetsEat
//
//  Created by Yi Cao on 5/31/18.
//  Copyright © 2018 Yi Cao. All rights reserved.
//

import UIKit

class PopTimerViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }
    private var timer = Timer()
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var stopButton: UIButton!

    private var stopWatch = StopWatch()
    @IBOutlet weak var timerView: UIStackView!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //adjust timer pop up size to fit
        if let fittedSize = timerView?.sizeThatFits(UILayoutFittingCompressedSize) {
            preferredContentSize = CGSize(width: fittedSize.width + TimerConstants.padding, height: fittedSize.height + TimerConstants.padding)
        }
    }
    
    @IBAction func startTimer(_ sender: UIButton) {
        startButton.isEnabled = false
        stopButton.isEnabled = true
        timer = Timer.scheduledTimer(withTimeInterval: TimerConstants.timerInterval, repeats: true) { timer in
            self.stopWatch.advanceTimer()
            self.setLabel()
        }
    }
    
    @IBAction func endTimer(_ sender: UIButton) {
        stopButton.isEnabled = false
        startButton.isEnabled = true
        timer.invalidate()
        stopWatch.resetTimer()
        setLabel()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // let the view controller that presents this popover know that the pop over is being dismissed
        NotificationCenter.default.post(name: NSNotification.Name.dismissTimerPopover, object: nil)
    }
    
    private func setLabel() {
        timerLabel.text = String(format: TimerConstants.timerFormat, stopWatch.hour, stopWatch.minute, stopWatch.second)
    }
    
    private struct TimerConstants {
        static let padding = CGFloat(20)
        static let timerFormat = "%02d:%02d:%02d"
        static let timerInterval = 1.0
    }
}
