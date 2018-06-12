//
//  PDFViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-06-06.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import UIKit
import PDFKit

class PDFViewController: UIViewController {

    // 1: VARIABLES
    var PDFurl: URL!
    var PDFfilename: String!
    var pdfView: PDFView!
    var document: PDFDocument!
    var pdfThumbnailView: PDFThumbnailView!
    var selection: PDFSelection!
    
    var annotationView: UIView!
    var highlightingMode = false
    
    let thumbnailPanelSize = CGFloat(80)
    let sidebarBackgroundColor = UIColor.lightGray

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.isNavigationBarHidden = false
        configureUI()
        setupThumbnailView()
        addButtons()
        pdfView.document = document
        
        // Add "highlight" as a uimenuitem
        let highlightTextMenuItem = UIMenuItem(title: "Highlight", action: #selector(highlightText))
        UIMenuController.shared.menuItems = [highlightTextMenuItem]

        // Do any additional setup after loading the view.
    }

    private func configureUI() {
        pdfView = PDFView()
        pdfView.frame = view.frame
        self.view.addSubview(pdfView)
        
        pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        pdfView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        pdfView.autoScales = true
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
    
    func addButtons() {
        let toggleThumbnailImage = UIImage(named: "ToogleThumbnails.png")
        
//        let optionsButton = UIBarButtonItem(title: "Options", style: UIBarButtonItemStyle.done, target: self, action: #selector(toogleHighlightMode))
        let toggleThumbnailButton = UIBarButtonItem(title: "Options", style: .plain, target: self, action: #selector(toggleSidebar))
//
//        optionsButton.image = optionsButtonImage
        toggleThumbnailButton.image = toggleThumbnailImage
//
        self.navigationItem.rightBarButtonItem = toggleThumbnailButton
//        s = [optionsButton, toggleThumbnailButton]
//
//        //        let toggleThumbnailViews = UIBarButtonItem(image: #imageLiteral(resourceName: "ToggleThumbnail"), style: .plain, target: self, action: #selector(toggleSidebar))
//        //        self.navigationItem.rightBarButtonItem = toggleThumbnailViews
//        //        let toggleOptionsButton = UIBarButtonItem(image: UIImage(named: "SettingsIcons.png"), style: .plain, target: self, action: #selector(toogleHighlightMode))
//        //        let toggleThumbnailViews = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(toggleSidebar))
//        //        let toggleHighlightModeButton = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(toogleHighlightMode))
//        //        self.navigationItem.rightBarButtonItems = [toggleOptionsButton, toggleThumbnailViews, toggleHighlightModeButton]
        
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
    
    @objc func toggleSidebar() {
        if pdfThumbnailView.isHidden {
            pdfThumbnailView.isHidden = false
        } else {
            pdfThumbnailView.isHidden = true
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}


//
////
////  PDFViewController.swift
////  myOrganizer
////
////  Created by Elias Kristensson on 2018-02-26.
////  Copyright © 2018 Elias Kristensson. All rights reserved.
////
//
//import UIKit
//import PDFKit
//import CoreData
//
//class PDFViewController: UIViewController, PDFViewDelegate {
//
//    // 1. VARIABLES
//    var PDFurl: URL!
//    var PDFfilename: String!
//    var pdfView: PDFView!
//    var document: PDFDocument!
//    var pdfThumbnailView: PDFThumbnailView!
//    var selection: PDFSelection!
//
//    var annotationView: UIView!
//    var highlightingMode = false
//
//    let thumbnailPanelSize = CGFloat(80)
//    let sidebarBackgroundColor = UIColor.lightGray
//
//    @IBAction func toggleThumbnails(_ sender: Any) {
//        if pdfThumbnailView.isHidden {
//            pdfThumbnailView.isHidden = false
//        } else {
//            pdfThumbnailView.isHidden = true
//        }
//    }
//
//
//    override func viewDidLoad() {
//
//        super.viewDidLoad()
//
//        navigationController?.isNavigationBarHidden = false
//        //        navigationController?.title = PDFfilename
//        navigationItem.title = PDFfilename
//
//        configureUI()
//        pdfView.document = document
//        //        loadPDF()
//        setupThumbnailView()
//    }
//
//    private func configureUI() {
//        pdfView = PDFView()
//        pdfView.frame = view.frame
//        self.view.addSubview(pdfView)
//
//        pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
//        pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
//        pdfView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
//        pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
//        pdfView.autoScales = true
//    }
//
//    private func loadPDF() {
//        print(PDFurl)
//        document = PDFDocument(url: PDFurl)
//        pdfView.document = document
//    }
//
//    func setupThumbnailView() {
//        pdfThumbnailView = PDFThumbnailView(frame: CGRect(x: self.view.bounds.maxX - thumbnailPanelSize, y: 100, width: thumbnailPanelSize, height: self.view.bounds.size.height - 200))
//        pdfThumbnailView.layoutMode = .vertical
//        pdfThumbnailView.thumbnailSize = CGSize(width: 50.0, height: 50.0)
//        pdfThumbnailView.pdfView = pdfView
//        pdfThumbnailView.backgroundColor = sidebarBackgroundColor
//        pdfThumbnailView.alpha = 0.9
//        self.view.addSubview(pdfThumbnailView)
//        pdfThumbnailView.isHidden = true
//    }
//
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//    }
//
//    override var canBecomeFirstResponder: Bool {
//        return true
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        self.navigationController?.isNavigationBarHidden = false
//    }
//
//
//}

