//
//  StopWatch.swift
//  LetsEat
//
//  Created by Yi Cao on 6/7/18.
//  Copyright © 2018 Yi Cao. All rights reserved.
//

import Foundation

class StopWatch {
    private (set) var hour = 0
    private (set) var minute = 0
    private (set) var second = 0
    
    func resetTimer() {
        hour = 0
        minute = 0
        second = 0
    }
    
    func advanceTimer() {
        second += 1
        if second == TimerConstants.timerAdvance {
            second = 0
            minute += 1
        }
        if minute == TimerConstants.timerAdvance {
            minute = 0
            hour += 1
        }
    }
    
    private struct TimerConstants {
        static let timerAdvance = 60
    }
}
