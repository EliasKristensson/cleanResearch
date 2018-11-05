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


