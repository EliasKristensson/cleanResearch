//
//  Extensions.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-09-05.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import Foundation
import CoreData
import UIKit

extension URL {
    var typeIdentifier: String? {
        return (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier
    }
    var localizedName: String? {
        return (try? resourceValues(forKeys: [.localizedNameKey]))?.localizedName
    }
    
    func isDirectory() -> Bool? {
        var isDir: ObjCBool = ObjCBool(false)
        if FileManager.default.fileExists(atPath: self.path, isDirectory: &isDir) {
            return isDir.boolValue
        } else {
            return nil
        }
    }
}

extension UISegmentedControl {
    func replaceSegments(segments: Array<String>) {
        self.removeAllSegments()
        for segment in segments {
            self.insertSegment(withTitle: segment, at: self.numberOfSegments, animated: false)
        }
    }
}

extension UIBezierPath
{
    func interpolatePointsWithHermite(interpolationPoints : [CGPoint], alpha : CGFloat = 1.0/3.0)
    {
        guard !interpolationPoints.isEmpty else { return }
        self.move(to: interpolationPoints[0])
        
        let n = interpolationPoints.count - 1
        
        for index in 0..<n
        {
            var currentPoint = interpolationPoints[index]
            var nextIndex = (index + 1) % interpolationPoints.count
            var prevIndex = index == 0 ? interpolationPoints.count - 1 : index - 1
            var previousPoint = interpolationPoints[prevIndex]
            var nextPoint = interpolationPoints[nextIndex]
            let endPoint = nextPoint
            var mx : CGFloat
            var my : CGFloat
            
            if index > 0
            {
                mx = (nextPoint.x - previousPoint.x) / 2.0
                my = (nextPoint.y - previousPoint.y) / 2.0
            }
            else
            {
                mx = (nextPoint.x - currentPoint.x) / 2.0
                my = (nextPoint.y - currentPoint.y) / 2.0
            }
            
            let controlPoint1 = CGPoint(x: currentPoint.x + mx * alpha, y: currentPoint.y + my * alpha)
            currentPoint = interpolationPoints[nextIndex]
            nextIndex = (nextIndex + 1) % interpolationPoints.count
            prevIndex = index
            previousPoint = interpolationPoints[prevIndex]
            nextPoint = interpolationPoints[nextIndex]
            
            if index < n - 1
            {
                mx = (nextPoint.x - previousPoint.x) / 2.0
                my = (nextPoint.y - previousPoint.y) / 2.0
            }
            else
            {
                mx = (currentPoint.x - previousPoint.x) / 2.0
                my = (currentPoint.y - previousPoint.y) / 2.0
            }
            
            let controlPoint2 = CGPoint(x: currentPoint.x - mx * alpha, y: currentPoint.y - my * alpha)
            
            self.addCurve(to: endPoint, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
        }
    }
}

extension String {
    
    func indexes(of character: String) -> [Int] {
        
        precondition(character.count == 1, "Must be single character")
        
        return self.enumerated().reduce([]) { partial, element  in
            if String(element.element) == character {
                return partial + [element.offset]
            }
            return partial
        }
    }
    
}


extension UINavigationController {
    func setStatusBar(backgroundColor: UIColor) {
        let statusBarFrame: CGRect
        if #available(iOS 13.0, *) {
            statusBarFrame = view.window?.windowScene?.statusBarManager?.statusBarFrame ?? CGRect.zero
        } else {
            statusBarFrame = UIApplication.shared.statusBarFrame
        }
        let statusBarView = UIView(frame: statusBarFrame)
        statusBarView.backgroundColor = backgroundColor
        view.addSubview(statusBarView)
    }
}


//
//extension CGRect{
//    var center: CGPoint {
//        return CGPoint( x: self.size.width/2.0,y: self.size.height/2.0)
//    }
//}
//
//extension CGPoint{
//    func vector(to p1:CGPoint) -> CGVector{
//        return CGVector(dx: p1.x-self.x, dy: p1.y-self.y)
//    }
//}
//
//extension UIBezierPath{
//    func moveCenter(to:CGPoint) -> Self{
//        let bound  = self.cgPath.boundingBox
//        let center = bounds.center
//
//        let zeroedTo = CGPoint(x: to.x-bound.origin.x, y: to.y-bound.origin.y)
//        let vector = center.vector(to: zeroedTo)
//
//        offset(to: CGSize(width: vector.dx, height: vector.dy))
//        return self
//    }
//
//    func offset(to offset:CGSize) -> Self{
//        let t = CGAffineTransform(translationX: offset.width, y: offset.height)
//        applyCentered(transform: t)
//        return self
//    }
//
//    func fit(into:CGRect) -> Self{
//        let bounds = self.cgPath.boundingBox
//
//        let sw     = into.size.width/bounds.width
//        let sh     = into.size.height/bounds.height
//        let factor = min(sw, max(sh, 0.0))
//
//        return scale(x: factor, y: factor)
//    }
//
//    func scale(x:CGFloat, y:CGFloat) -> Self{
//        let scale = CGAffineTransform(scaleX: x, y: y)
//        applyCentered(transform: scale)
//        return self
//    }
//
//
//    func applyCentered(transform: @autoclosure () -> CGAffineTransform ) -> Self{
//        let bound  = self.cgPath.boundingBox
//        let center = CGPoint(x: bound.midX, y: bound.midY)
//        var xform  = CGAffineTransform.identity
//
//        xform = xform.concatenating(CGAffineTransform(translationX: -center.x, y: -center.y))
//        xform = xform.concatenating(transform())
//        xform = xform.concatenating( CGAffineTransform(translationX: center.x, y: center.y))
//        apply(xform)
//
//        return self
//    }
//}


