//
//  ProgressMonitor.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-11-08.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import UIKit
import Foundation

class ProgressMonitor: UIView {
    
    var textWidth: CGFloat = 200
    var textHeight: CGFloat = 20
    var exitTimer: Timer!
    var moveDownTimer: Timer!
    var time: Double = 4
    var text = "Test label"
    var label = InfoLabel()
    var settings: [CGFloat]!
    var iPadDimension: [CGFloat]! //Height, width
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func launchMonitor(displayText: String?) {
        print("launchMonitor")
        
        self.isHidden = false
        self.bringSubview(toFront: self) //MAIN THREAD ONLY
        self.center.y = iPadDimension[0] + settings[0]/2 //MAIN THREAD ONLY
        self.center.x = iPadDimension[1]/2  //MAIN THREAD ONLY
        self.textHeight = settings[0]*0.8
        self.textWidth = settings[1]*0.8
        
        if moveDownTimer != nil {
            print("valid")
            if moveDownTimer.isValid {
                self.moveDownTimer.invalidate()
            }
        }
        self.moveDownTimer = Timer.scheduledTimer(timeInterval: self.time-0.5, target: self, selector: #selector(moveDown), userInfo: nil, repeats: false)
        self.label.frame = CGRect(x: self.frame.size.width / 2 - textWidth/2, y: self.frame.size.height / 2 - textHeight/2, width: textWidth, height: textHeight)
        if displayText != nil {
            self.label.text = displayText
        } else {
            self.label.text = text
        }
        self.label.adjustsFontSizeToFitWidth = true
        self.addSubview(label)
        moveUp()
    }
    
    func moveUp() {
        print("moveUp")
        self.center.y = iPadDimension[0] + settings[0]/2
        UIView.animate(withDuration: 0.5) {
            self.center.y -= self.settings[0]*1.15
        }
        print(self.center.y)
    }
    
    @objc func moveDown() {
        print("moveDown")
        UIView.animate(withDuration: 0.5) {
            self.center.y += self.settings[0]*1.15
        }
        print(self.center.y)
    }
    
    @objc func close() {
        print("close")
        exitTimer.invalidate()
    }

    

}


class InfoLabel: UILabel {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initializeLabel()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initializeLabel()
    }
    
    func initializeLabel() {
        
        self.textAlignment = .center
        self.font = UIFont(name: "HelveticaNeue-Light", size: 15.0)
        self.textColor = UIColor.white
        
    }
    
}
