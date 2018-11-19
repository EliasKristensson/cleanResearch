//
//  UILabelExtensions.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-11-18.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import Foundation
import UIKit

extension UILabel {
    
    func disappear() {
        
        let opacityDown = CABasicAnimation(keyPath: "opacity")
        opacityDown.duration = 0.8
        opacityDown.fromValue = 1
        opacityDown.toValue = 0
        
        layer.add(opacityDown, forKey: nil)
    }
    
    func grow() {
        
        let scaleUp = CABasicAnimation(keyPath: "transform.scale")
        scaleUp.fromValue = 0
        scaleUp.toValue = 1
        scaleUp.duration = 0.5
        
        layer.add(scaleUp, forKey: nil)
    }

    func shrink() {
        
        let scaleDown = CABasicAnimation(keyPath: "transform.scale")
        scaleDown.fromValue = 1
        scaleDown.toValue = 0
        scaleDown.duration = 0.8
        
        layer.add(scaleDown, forKey: nil)
    }

    
}
