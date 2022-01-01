//
//  DrawView.swift
//  PDF_test
//
//  Created by Elias Kristensson on 2018-09-16.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import UIKit
import PDFKit

protocol DrawingViewDelegate: class {
    func didEndDrawLine(bezierPath: UIBezierPath, page: PDFPage)
}

class DrawingView: UIView {
    
    let splinePath = UIBezierPath()
    var interpolationPoints = [CGPoint]()
    var spline: Bool!
    
//    var annotationSettings: [Int]!
    var page: PDFPage!
//    var annotationPath: UIBezierPath!
    var annotationPath = UIBezierPath()
    var annotationPoints = [CGPoint]()
    
    var lastPoint: CGPoint!
    var lastPointPDF: CGPoint!
    var drawPath: UIBezierPath!
    var didDraw = false
//    var pointCounter: Int = 0
//    let pointLimit: Int = 256//128 IS THIS REQUIRED?
    var preRenderImage: UIImage!
    var pdfView: PDFView!
    var document: PDFDocument!
    weak var delegate: DrawingViewDelegate?
    
    var thickness: CGFloat!
    var drawColor: UIColor!
    
    var pdfViewManager: PDFViewManager!
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initBezierPath()
    }
    
    
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initBezierPath()
    }
    
    func initBezierPath() {
        drawPath = UIBezierPath()
        drawPath.lineCapStyle = CGLineCap.round
        drawPath.lineJoinStyle = CGLineJoin.round
    }
    
    func renderToImage() {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, 0.0)
        if preRenderImage != nil {
            preRenderImage.draw(in: self.bounds)
        }
        
        drawPath.lineWidth = thickness
        drawColor.setFill()
        drawColor.setStroke()
        drawPath.stroke()
        
        preRenderImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
    }
    
    func clear() {
        preRenderImage = nil
        drawPath.removeAllPoints()
        setNeedsDisplay()
    }
    
    func hasLines() -> Bool {
        return preRenderImage != nil || !drawPath.isEmpty
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if preRenderImage != nil {
            preRenderImage.draw(in: self.bounds)
        }
        
        drawPath.lineWidth = thickness
        drawColor.setFill()
        drawColor.setStroke()
        drawPath.stroke()
    }
    
    
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        pdfViewManager.touchState = .active
        didDraw = false
        
        if let touch = touches.first {
            annotationPath.removeAllPoints()
            annotationPoints.removeAll()
//            annotationPath = UIBezierPath()
//            interpolationPoints.removeAll()
            
//            lastPoint = touch.location(in: self)
            lastPoint = touch.location(in: pdfView)

            guard let nearest = pdfView.page(for: lastPoint, nearest: true) else {return}
            page = nearest
            
            lastPointPDF = pdfView.convert(lastPoint, to: page)
            annotationPoints.append(lastPointPDF)
//            interpolationPoints.append(lastPointPDF)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        didDraw = true
        
        if let coalescedTouches = event?.coalescedTouches(for: touch) {

            for point in coalescedTouches {
                let newPoint = point.location(in: self)
                let newPointPDF = pdfView.convert(newPoint, to: page)
                
                annotationPoints.append(newPointPDF)
//                interpolationPoints.append(newPointPDF)

                if spline {
                    annotationPath.removeAllPoints()
                    annotationPath.interpolatePointsWithHermite(interpolationPoints: annotationPoints)
                } else {
                    annotationPath.move(to: lastPointPDF)
                    annotationPath.addLine(to: newPointPDF)
                }
                
//                splinePath.removeAllPoints()
//                splinePath.interpolatePointsWithHermite(interpolationPoints: interpolationPoints)
                
                drawPath.move(to: lastPoint)
                drawPath.addLine(to: newPoint)
//                annotationPath.move(to: lastPointPDF)
//                annotationPath.addLine(to: newPointPDF)

                lastPoint = newPoint
                lastPointPDF = newPointPDF

            }
            
            setNeedsDisplay()
            
        } else {

            let newPoint = touch.location(in: self)
            let newPointPDF = pdfView.convert(newPoint, to: page)
            
            drawPath.move(to: lastPoint)
            drawPath.addLine(to: newPoint)
            annotationPath.move(to: lastPointPDF)
            annotationPath.addLine(to: newPointPDF)
            
            lastPoint = newPoint
            lastPointPDF = newPointPDF
            
            setNeedsDisplay()
            
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if didDraw {
            if spline {
                annotationPath.removeAllPoints()
                annotationPath.interpolatePointsWithHermite(interpolationPoints: annotationPoints)
            }
            renderToImage()
            setNeedsDisplay()
            delegate?.didEndDrawLine(bezierPath: annotationPath, page: page)
            clear()
        }
        pdfViewManager.touchState = .inactive
    }
    
}


