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

