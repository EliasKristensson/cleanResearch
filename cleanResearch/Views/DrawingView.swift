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
    func didEndDrawLine(bezierPath: UIBezierPath)
}

class DrawingView: UIView {
    
    var annotationPath: UIBezierPath!
    var lastPoint: CGPoint!
    var lastPointPDF: CGPoint!
    var drawPath: UIBezierPath!
    var pointCounter: Int = 0
    let pointLimit: Int = 128
    var preRenderImage: UIImage!
    var pdfView: PDFView!
    var pdfPage: PDFPage!
    weak var delegate: DrawingViewDelegate?
    
    var thickness: CGFloat!
    var drawColor: UIColor!
    
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
        guard let currentPage = pdfView.currentPage else {return}
        
        if let touch = touches.first {
            annotationPath = UIBezierPath()
            
            lastPoint = touch.location(in: self)
            lastPointPDF = pdfView.convert(lastPoint, to: currentPage)
            pointCounter = 0
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let currentPage = pdfView.currentPage else {return}
        
        if let touch = touches.first {
            let newPoint = touch.location(in: self)
            let newPointPDF = pdfView.convert(newPoint, to: currentPage)
            
            drawPath.move(to: lastPoint)
            drawPath.addLine(to: newPoint)
            annotationPath.move(to: lastPointPDF)
            annotationPath.addLine(to: newPointPDF)
            
            lastPoint = newPoint
            lastPointPDF = newPointPDF
            
            pointCounter += 1
            
            if pointCounter == pointLimit {
                pointCounter = 0
                renderToImage()
                setNeedsDisplay()
                drawPath.removeAllPoints()
            } else {
                setNeedsDisplay()
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        pointCounter = 0
        renderToImage()
        setNeedsDisplay()
        delegate?.didEndDrawLine(bezierPath: annotationPath)
        clear()
        
    }
    
}


