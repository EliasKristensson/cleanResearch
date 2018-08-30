//
//  PDFViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-06-06.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import UIKit
import PDFKit

class PDFViewController: UIViewController, PDFViewDelegate {

    // 1: VARIABLES
    //    var PDFurl: URL!
    var PDFfilename: String!
    var document: PDFDocument!
    var pdfThumbnailView: PDFThumbnailView!
    var selection: PDFSelection!
    var annotationPath: UIBezierPath!
    var highlightLine: [CGPoint]!
    var annotationsAdded: [PDFAnnotation]? = []
    var annotationsPages: [Int]? = []
    
    var highlightingMode = false
    
    let thumbnailPanelSize = CGFloat(80)
    let sidebarBackgroundColor = UIColor.lightGray

    var settingsBox = CGSize(width: 300, height: 350)
    var highlighterColor = UIColor.yellow
    var type = "Straight"
    var thickness: CGFloat = 10
    var pdfURL: URL!
    var highlighting = false
    var erasing = false
    var freehand = false
    var annotationSettings: [Int]!
    
    // 1: OUTLETS
    @IBOutlet weak var annotationView: UIView!
    @IBOutlet weak var pdfView: PDFView!
    @IBOutlet weak var hightlightIcon: UIBarButtonItem!
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    @IBOutlet weak var penIcon: UIBarButtonItem!
    @IBOutlet weak var undoIcon: UIBarButtonItem!
    @IBOutlet weak var eraserIcon: UIBarButtonItem!
    
    @IBAction func undoTapped(_ sender: Any) {
        if let latestAdded = annotationsAdded?.last {
            pdfView.document?.page(at: (annotationsPages?.last)!)?.removeAnnotation(latestAdded)
        }
    }
    
    @IBAction func togglePen(_ sender: Any) {
        erasing = false
        highlighting = false
        freehand = !freehand
        hightlightIcon.image = #imageLiteral(resourceName: "HighlightIcon")
        eraserIcon.image = #imageLiteral(resourceName: "EraserIcon")

        if freehand {
            annotationView.isHidden = false
            penIcon.image = #imageLiteral(resourceName: "PenIconSelected")
        } else {
            annotationView.isHidden = true
            penIcon.image = #imageLiteral(resourceName: "PenIcon")
        }
    }
    
    @IBAction func toggleThumbnails(_ sender: Any) {
        if pdfThumbnailView.isHidden {
            pdfThumbnailView.isHidden = false
        } else {
            pdfThumbnailView.isHidden = true
        }
    }
    
    @IBAction func toggleHighlight(_ sender: Any) {
        erasing = false
        freehand = false
        highlighting = !highlighting
        penIcon.image = #imageLiteral(resourceName: "PenIcon")
        eraserIcon.image = #imageLiteral(resourceName: "EraserIcon")

        if highlighting {
            annotationView.isHidden = false
            hightlightIcon.image = #imageLiteral(resourceName: "HighlightIconSelected")
        } else {
            annotationView.isHidden = true
            hightlightIcon.image = #imageLiteral(resourceName: "HighlightIcon")
        }
        
    }
    
    @IBAction func savePressed(_ sender: Any) {
        if !document.write(to: document.documentURL!) {
            print("Failed to save PDF")
        } else {
            print("Saved PDF")
        }
    }
    
    @IBAction func toogleEraser(_ sender: Any) {
        highlighting = false
        freehand = false
        erasing = !erasing
        
        hightlightIcon.image = #imageLiteral(resourceName: "HighlightIcon")
        penIcon.image = #imageLiteral(resourceName: "PenIcon")
        
        if erasing {
            annotationView.isHidden = false
            eraserIcon.image = #imageLiteral(resourceName: "EraserIconSelected")
        } else {
            annotationView.isHidden = true
            eraserIcon.image = #imageLiteral(resourceName: "EraserIcon")
        }

    }
    

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.barTintColor = UIColor.lightGray
        navigationController?.navigationBar.tintColor = UIColor.white
        
        
        configureUI()
        setupThumbnailView()
//        addButtons()
        pdfView.document = document
        pdfView.delegate = self
        
        annotationView.tag = 100
        annotationView.isUserInteractionEnabled = true
//        annotationView.alpha = 0.15
        annotationView.backgroundColor = UIColor.clear
        self.view.addSubview(annotationView)
        annotationView.isHidden = true
        
        self.navigationItem.title = PDFfilename
        
        // Add "highlight" as a uimenuitem
        let highlightTextMenuItem = UIMenuItem(title: "Highlight", action: #selector(highlightText))
        UIMenuController.shared.menuItems = [highlightTextMenuItem]

        NotificationCenter.default.addObserver(self, selector: #selector(handleSettingsPopupClosing), name: Notification.Name.settingsHighlighter, object: nil)
        
    }

    
    
    
    private func configureUI() {
        
        pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        pdfView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        pdfView.autoScales = true
        
        annotationView.isHidden = true
    }

    @objc func highlightText() {
        let selections = pdfView.currentSelection?.selectionsByLine()

        guard let page = selections?.first?.pages.first else { return }

        selections?.forEach({ selection in
            let highlight = PDFAnnotation(bounds: selection.bounds(for: page), forType: .highlight, withProperties: nil)
            highlight.endLineStyle = .square
            highlight.color = UIColor.yellow.withAlphaComponent(0.4)

            page.addAnnotation(highlight)
        })
    }
    
    @objc func handleSettingsPopupClosing(notification: Notification) {
        let settingsVC = notification.object as! PenSettingsViewController
        highlighterColor = settingsVC.color
        thickness = settingsVC.thickness
        type = settingsVC.type
        annotationSettings = settingsVC.selectedSettings
        print(type)
    }
    
    func setupThumbnailView() {
        pdfThumbnailView = PDFThumbnailView(frame: CGRect(x: self.view.bounds.maxX - thumbnailPanelSize, y: 100, width: thumbnailPanelSize, height: self.view.bounds.size.height - 200))
        pdfThumbnailView.layoutMode = .vertical
        pdfThumbnailView.thumbnailSize = CGSize(width: 50.0, height: 50.0)
        pdfThumbnailView.pdfView = pdfView
        pdfThumbnailView.backgroundColor = sidebarBackgroundColor
        pdfThumbnailView.alpha = 0.9
        self.view.addSubview(pdfThumbnailView)
        pdfThumbnailView.isHidden = true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "highlighterSettingsSegue") {
            let destination = segue.destination as! PenSettingsViewController
            destination.preferredContentSize = settingsBox
            destination.color = highlighterColor
            destination.thickness = thickness
            destination.type = type
            destination.selectedSettings = annotationSettings
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let currentPage = pdfView.currentPage else {return}
        
        if freehand {
            if let touch = touches.first {
                annotationPath = UIBezierPath()
                var position = touch.location(in: annotationView)
                position = pdfView.convert(position, to: currentPage)
                annotationPath.move(to: position)
                print("Pen")
            }
        }
        
        if highlighting {
            if let touch = touches.first {
                var position = touch.location(in: annotationView)
                position = pdfView.convert(position, to: currentPage)
                if type == "Straight" {
                    highlightLine = []
                    annotationPath = UIBezierPath()
                    highlightLine.append(position)
                    print("Highlighting")
                    annotationPath.move(to: position)
                } else {
                    let annotation = PDFAnnotation(bounds: CGRect(x: position.x, y: position.y, width: thickness-thickness/2, height: thickness-thickness/2), forType: .highlight, withProperties: nil)
                    annotation.color = highlighterColor
                    annotation.endLineStyle = .circle
                    annotation.color.withAlphaComponent(0.8)
                    annotation.add(annotationPath)
                    currentPage.addAnnotation(annotation)
                }
            }
        }
        
        if erasing {
            if let touch = touches.first {
                var position = touch.location(in: annotationView)
                position = pdfView.convert(position, to: currentPage)
                if let tmp = pdfView.currentPage?.annotation(at: position) {
                    pdfView.currentPage?.removeAnnotation(tmp)
                }
            }
        }
        
    }
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
     
        if freehand {
            guard let currentPage = pdfView.currentPage else {return}
            if let touch = touches.first {
                var position = touch.location(in: annotationView)
                position = pdfView.convert(position, to: currentPage)
                annotationPath.addLine(to: position)
                print(position)
            }
        }
        
        if highlighting {
            guard let currentPage = pdfView.currentPage else {return}
     
            if type == "Swiggly" {
                if let touch = touches.first {
                    var position = touch.location(in: annotationView)
                    position = pdfView.convert(position, to: currentPage)

                    let annotation = PDFAnnotation(bounds: CGRect(x: position.x, y: position.y, width: thickness-thickness/2, height: thickness-thickness/2), forType: .highlight, withProperties: nil)
                    annotation.color = highlighterColor
                    annotation.endLineStyle = .circle
                    annotation.color.withAlphaComponent(0.8)
                    annotation.add(annotationPath)
                    currentPage.addAnnotation(annotation)
                }

                /* ADDS A SQUARE WHEN HIGHLIGHTING
                let annotation = PDFAnnotation(bounds: CGRect(x: position.x, y: position.y, width: thickness, height: thickness), forType: .highlight, withProperties: nil)
                annotation.color = highlighterColor
                annotation.endLineStyle = .circle
                annotation.color.withAlphaComponent(0.8)
                page.addAnnotation(annotation)
                */
            }
        }
     
        if erasing {
            guard let page = pdfView.currentPage else {return}

            if let touch = touches.first {
                var position = touch.location(in: pdfView)
                position = pdfView.convert(position, to: page)

//                let tmp = pdfView.currentSelection
                if let tmp = pdfView.currentPage?.annotation(at: position) {
                    pdfView.currentPage?.removeAnnotation(tmp)
                }

            }
        }
     
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        
        if freehand {
            guard let currentPage = pdfView.currentPage else {return}
            
            if let touch = touches.first {
                var position = touch.location(in: annotationView)
                position = pdfView.convert(position, to: currentPage)
                annotationPath.addLine(to: position)
                
                let pageBounds = currentPage.bounds(for: .artBox)
                let inkAnnotation = PDFAnnotation(bounds: pageBounds, forType: .ink, withProperties: nil)
                inkAnnotation.add(annotationPath)
//                inkAnnotation.border = b
                inkAnnotation.color = .blue
//                inkAnnotation.color.withAlphaComponent(0.5)
                
                currentPage.addAnnotation(inkAnnotation)
                
            }
        }
        
        if highlighting {
            guard let currentPage = pdfView.currentPage else {return}
            if type == "Swiggly" {
                if let touch = touches.first {
                    var position = touch.location(in: annotationView)
                    position = pdfView.convert(position, to: currentPage)
                    let annotation = PDFAnnotation(bounds: CGRect(x: position.x, y: position.y-thickness/2, width: thickness-thickness/2, height: thickness), forType: .highlight, withProperties: nil)
                    annotation.color = highlighterColor
                    annotation.endLineStyle = .circle
                    annotation.color.withAlphaComponent(0.8)
                    annotation.add(annotationPath)
                    currentPage.addAnnotation(annotation)
                }
            } else {
                if let touch = touches.first {
                    var position = touch.location(in: annotationView)
                    position = pdfView.convert(position, to: currentPage)
                    highlightLine.append(position)
                    annotationPath.addLine(to: position)
                    annotationPath.close()
                    
                    var width = highlightLine[1].x-highlightLine[0].x
                    var start = 0
                    if true {
                        if highlightLine[1].x < highlightLine[0].x {
                            width = highlightLine[0].x-highlightLine[1].x
                            start = 1
                        }
                        
                        let rect = CGRect(x: highlightLine[start].x, y: highlightLine[0].y-thickness/2, width: width, height: thickness)
                        let annotation = PDFAnnotation(bounds: rect, forType: .highlight, withProperties: nil)
                        annotation.color = highlighterColor
                        annotation.endLineStyle = .circle
                        annotation.color.withAlphaComponent(0.8)
                        annotation.add(annotationPath)
                        currentPage.addAnnotation(annotation)
//                    annotationsAdded?.append(annotation)
//                    let page = pdfView.currentPage?.pageRef
//                    annotationsPages?.append(
                    } else {
                        
                        let annotation = PDFAnnotation(bounds: CGRect(x: position.x, y: position.y, width: thickness, height: thickness), forType: .highlight, withProperties: nil)
                        annotation.color = highlighterColor
                        annotation.endLineStyle = .circle
                        annotation.color.withAlphaComponent(0.8)
                        currentPage.addAnnotation(annotation)
                    }
                }
            }
            
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.post(name: Notification.Name.closingPDF, object: self)
//        if !document.write(toFile: (document.documentURL?.absoluteString)!) {
//            print("Failed to save")
//        } else {
//            print("Saved")
//        }
        
//        if let path = self.PDFurl, let document = self.document {
////            document.write(toFile: "Test.pdf")
//            if !document.write(toFile: path.absoluteString){
//                print("Failed to save PDF")
//            } else {
//                print("Saved PDF to " + path.absoluteString)
//            }
//        } else {
//            print("Nej")
//        }
//        NotificationCenter.default.post(name: Notification.Name.settingsCollectionView, object: self)
    }


}


/*
 p = UIBezierPath()
 //        p.move(to: CGPoint(x: 400, y: 200))
 //        p.addLine(to: CGPoint(x: 500, y: 100))
 //        p.addLine(to: CGPoint(x: 400, y: 0))
 //        p.close()
 
 //        let b = PDFBorder()
 //        b.lineWidth = 10.0
 
 let pageBounds = currentPage.bounds(for: .artBox)
 let inkAnnotation = PDFAnnotation(bounds: pageBounds, forType: .ink, withProperties: nil)
 //        let inkAnnotation = PDFAnnotation(bounds: pageBounds, forType: .highlight, withProperties: nil)
 inkAnnotation.add(p)
 inkAnnotation.border = b
 inkAnnotation.color = .green
 inkAnnotation.color.withAlphaComponent(0.5)
 
 currentPage.addAnnotation(inkAnnotation)
 */

