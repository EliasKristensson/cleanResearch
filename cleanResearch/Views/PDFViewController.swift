//
//  PDFViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-06-06.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import UIKit
import PDFKit

class PDFViewController: UIViewController, UISearchBarDelegate {

    // 1: VARIABLES
    var kvStorage: NSUbiquitousKeyValueStore!
    var drawView: DrawingView!
    var PDFfilename: String!
    var iCloudURL: URL? //ADD
    var localURL: URL? //ADD
    var document: PDFDocument!
    var pdfThumbnailView: PDFThumbnailView!
    var currentPage: PDFPage!
    var bookmarks: Bookmarks!
    var localCopy: Bool!
    var currentFile: LocalFile!

    var changesMade = false
    var needsUploading = false
    var annotationsAdded: [PDFAnnotation]? = []
    var annotationsPages: [Int]? = []
    var annotationsUndone: [PDFAnnotation]? = []
    var undonePages: [Int]? = []
    var currentAnnotation: PDFAnnotation!
    
    var saveTimer: Timer!
    var saveTime: Int!

    var bookmarkPages: [Int]?
    var lastPageVisited: Int?
    
    let thumbnailPanelSize = CGFloat(80)
    let sidebarBackgroundColor = UIColor.lightGray.withAlphaComponent(0.75)

    var settingsBox = CGSize(width: 300, height: 650)
    var textSettingsBox = CGSize(width: 340, height: 100)
    
    var highlighting = false
    var highlighterColor = UIColor(red: 255/255.0, green: 255/255.0, blue: 0/255.0, alpha: 0.4)
    var highlighterThickness: CGFloat!
    let highlighterThicknesses: [CGFloat] = [6, 9, 12, 15, 19]
    
    var freehand = false
    var penColor = UIColor(red: 0/255.0, green: 0/255.0, blue: 255/255.0, alpha: 1)
    var penThickness: CGFloat!
    let penThicknesses: [CGFloat] = [0.5, 1, 2, 3, 4]
    
    var erasing = false
    var searchActive : Bool = false
    var matches: [PDFSelection]!
    var searchMatches: [PDFAnnotation] = []
    var searchPages: [Int] = []
    
    var move = false
    var delete = false
    var addText = false
    var fontSize: Int!
    var font: UIFont!
    var counter = 0
    var point: CGPoint!
    var pointOnTextbox: String!
    var precision: CGFloat = 10
    var currentTextAnnotation: PDFAnnotation!
    
    var annotationSettings: [Int]!
    
    var progressMonitor: ProgressMonitor!
    var dataManager: DataManager!
    
    // 1: OUTLETS
    @IBOutlet weak var thumbnailIcon: UIBarButtonItem!
    @IBOutlet weak var bookmarkButton: UIBarButtonItem!
    @IBOutlet weak var pdfView: PDFView!
    @IBOutlet weak var hightlightIcon: UIBarButtonItem!
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    @IBOutlet weak var penIcon: UIBarButtonItem!
    @IBOutlet weak var undoIcon: UIBarButtonItem!
    @IBOutlet weak var redoIcon: UIBarButtonItem!
    @IBOutlet weak var eraserIcon: UIBarButtonItem!
    @IBOutlet weak var searchField: UISearchBar!
    @IBOutlet weak var nextBookmark: UIBarButtonItem!
    @IBOutlet weak var prevBookmark: UIBarButtonItem!
    @IBOutlet weak var nextSearchResultButton: UIBarButtonItem!
    @IBOutlet weak var prevSearchResultButton: UIBarButtonItem!
    @IBOutlet weak var addTextButton: UIBarButtonItem!
    
    
    @IBAction func addTextTapped(_ sender: Any) {
        
//        drawResizingControllers()
        
        guard let page = pdfView.currentPage else {return}

        if pdfView.isUserInteractionEnabled {
            
            erasing = false
            highlighting = false
            freehand = false
            addText = true
            move = false
            
            addTextButton.image = #imageLiteral(resourceName: "AddTextFilled.png")
            addTextButton.tintColor = UIColor.red
            hightlightIcon.image = #imageLiteral(resourceName: "Marker")
            hightlightIcon.tintColor = UIColor.black
            eraserIcon.image = #imageLiteral(resourceName: "Erase")
            eraserIcon.tintColor = UIColor.black
            penIcon.image = #imageLiteral(resourceName: "Pen")
            penIcon.tintColor = UIColor.black
            
            pdfView.isUserInteractionEnabled = false
            
            for annotation in page.annotations {
                if annotation.widgetFieldType == PDFAnnotationWidgetSubtype.text {
                    annotation.backgroundColor = UIColor.blue.withAlphaComponent(0.1)
                }
            }
            
        } else {
            
            addText = false
            move = false

            addTextButton.image = #imageLiteral(resourceName: "AddText.png")
            addTextButton.tintColor = UIColor.black
            
            pdfView.isUserInteractionEnabled = true

            for annotation in page.annotations {
                if annotation.widgetFieldType == PDFAnnotationWidgetSubtype.text {
                    let text = annotation.widgetStringValue?.trimmingCharacters(in: .whitespaces)
                    if text == nil || (text?.isEmpty)! {
                        annotation.backgroundColor = UIColor.blue.withAlphaComponent(0.1)
                    } else {
                        annotation.backgroundColor = UIColor.clear
                    }
                }
            }

        }
    }
    
    @IBAction func prevBookmarkTapped(_ sender: Any) {
        let currentPage = pdfView.currentPage?.pageRef?.pageNumber
        var pastBookmarks = bookmarks.page?.filter{$0 < currentPage!}
        pastBookmarks = pastBookmarks?.sorted()
        if let prevBookmark = pastBookmarks?.last {
            let page = pdfView.document?.page(at: prevBookmark-1)
            pdfView.go(to: page!)
        }
    }
    
    @IBAction func nextBookmarkTapped(_ sender: Any) {
        let currentPage = pdfView.currentPage?.pageRef?.pageNumber
        var commingBookmarks = bookmarks.page?.filter{$0 > currentPage!}
        commingBookmarks = commingBookmarks?.sorted()
        if let nextBookmark = commingBookmarks?.first {
            let page = pdfView.document?.page(at: nextBookmark-1)
            pdfView.go(to: page!)
        }
    }
    
    @IBAction func bookmarkTapped(_ sender: Any) {
        if let number = pdfView.currentPage?.pageRef?.pageNumber {
            if !(bookmarks.page?.contains(number))! {
                bookmarks.page?.append(number)
                bookmarkButton.image = #imageLiteral(resourceName: "Bookmark-filled")
                bookmarkButton.tintColor = UIColor.red
            } else {
                bookmarks.page = bookmarks.page?.filter{$0 != number}
                bookmarkButton.image = #imageLiteral(resourceName: "Bookmark")
                bookmarkButton.tintColor = UIColor.black
            }
        }
    }
    
    @IBAction func undoTapped(_ sender: Any) {
        undo()
    }
    
    @IBAction func redoTapped(_ sender: Any) {
        redo()
    }
    
    @IBAction func togglePen(_ sender: Any) {
        
        if move || addText {
            guard let page = pdfView.currentPage else {return}
            for annotation in page.annotations {
                if annotation.widgetFieldType == PDFAnnotationWidgetSubtype.text {
                    annotation.backgroundColor = UIColor.clear
                }
            }
        }
        
        if highlighting {
//            drawView.removeFromSuperview()
            pdfView.bringSubview(toFront: pdfView)
        }
        
        erasing = false
        highlighting = false
        move = false
        addText = false
        freehand = !freehand
        
        addTextButton.image = #imageLiteral(resourceName: "AddText.png")
        addTextButton.tintColor = UIColor.black
        
        hightlightIcon.image = #imageLiteral(resourceName: "Marker")
        hightlightIcon.tintColor = UIColor.black
        eraserIcon.image = #imageLiteral(resourceName: "Erase")
        eraserIcon.tintColor = UIColor.black

        if freehand {
            penIcon.image = #imageLiteral(resourceName: "Pen-filled")
            penIcon.tintColor = UIColor.red
            pdfView.isUserInteractionEnabled = false
        } else {
            penIcon.image = #imageLiteral(resourceName: "Pen")
            penIcon.tintColor = UIColor.black
            pdfView.isUserInteractionEnabled = true
        }
        
        if freehand {
//            drawView = DrawingView()
            drawView.frame = pdfView.frame
            drawView.isHidden = false
//            drawView.backgroundColor = UIColor.clear
            drawView.bringSubview(toFront: self.view)
//            drawView.delegate = self
//            drawView.pdfView = self.pdfView
            drawView.pdfPage = self.pdfView.currentPage
            drawView.drawColor = penColor
            drawView.thickness = penThickness * getScale()
//            drawView.isUserInteractionEnabled = true
//            self.view.addSubview(drawView)
        } else {
            drawView.isHidden = true
//            drawView.removeFromSuperview()
            pdfView.bringSubview(toFront: pdfView)
        }
        
        for subview in self.view.subviews {
            if let item = subview as? UIScrollView
            {
                item.isScrollEnabled = !freehand
            }
        }
    }
    
    @IBAction func toggleThumbnails(_ sender: Any) {
        if pdfThumbnailView.isHidden {
            thumbnailIcon.image = #imageLiteral(resourceName: "Layers-filled")
            pdfThumbnailView.isHidden = false
        } else {
            thumbnailIcon.image = #imageLiteral(resourceName: "Layers")
            pdfThumbnailView.isHidden = true
        }
    }
    
    @IBAction func toggleHighlight(_ sender: Any) {
        
        if move || addText {
            guard let page = pdfView.currentPage else {return}
            for annotation in page.annotations {
                if annotation.widgetFieldType == PDFAnnotationWidgetSubtype.text {
                    annotation.backgroundColor = UIColor.clear
                }
            }
        }
        
        if freehand {
//            drawView.removeFromSuperview()
            pdfView.bringSubview(toFront: pdfView)
        }
        
        erasing = false
        freehand = false
        move = false
        addText = false
        highlighting = !highlighting
        
        addTextButton.image = #imageLiteral(resourceName: "AddText.png")
        addTextButton.tintColor = UIColor.black
        
        penIcon.image = #imageLiteral(resourceName: "Pen")
        penIcon.tintColor = UIColor.black
        eraserIcon.image = #imageLiteral(resourceName: "Erase")
        eraserIcon.tintColor = UIColor.black

        if highlighting {
            hightlightIcon.image = #imageLiteral(resourceName: "Marker-filled")
            hightlightIcon.tintColor = UIColor.red
            pdfView.isUserInteractionEnabled = false
        } else {
            hightlightIcon.image = #imageLiteral(resourceName: "Marker")
            hightlightIcon.tintColor = UIColor.black
            pdfView.isUserInteractionEnabled = true
        }
        
        if highlighting {
//            drawView = DrawingView()
            drawView.frame = pdfView.frame
            drawView.isHidden = false
//            drawView.backgroundColor = UIColor.clear
            drawView.bringSubview(toFront: self.view)
//            drawView.delegate = self
//            drawView.pdfView = self.pdfView
            drawView.pdfPage = self.pdfView.currentPage
            drawView.drawColor = highlighterColor
            drawView.thickness = highlighterThickness * getScale()
//            drawView.isUserInteractionEnabled = true
//            self.view.addSubview(drawView)
        } else {
            drawView.isHidden = true
//            drawView.removeFromSuperview()
            pdfView.bringSubview(toFront: pdfView)
        }
        
        for subview in self.view.subviews {
            if let item = subview as? UIScrollView
            {
                item.isScrollEnabled = !highlighting
                print(item)
            }
        }
        
    }
    
    @IBAction func toogleEraser(_ sender: Any) {
        
        if move || addText {
            guard let page = pdfView.currentPage else {return}
            for annotation in page.annotations {
                if annotation.widgetFieldType == PDFAnnotationWidgetSubtype.text {
                    annotation.backgroundColor = UIColor.clear
                }
            }
        }
        
        if highlighting || freehand {
            drawView.isHidden = true
//            drawView.removeFromSuperview()
            pdfView.bringSubview(toFront: pdfView)
        }
        
        highlighting = false
        freehand = false
        move = false
        addText = false
        erasing = !erasing
        
        addTextButton.image = #imageLiteral(resourceName: "AddText.png")
        addTextButton.tintColor = UIColor.black
        
        hightlightIcon.image = #imageLiteral(resourceName: "Marker")
        hightlightIcon.tintColor = UIColor.black
        penIcon.image = #imageLiteral(resourceName: "Pen")
        penIcon.tintColor = UIColor.black
        
        if erasing {
            eraserIcon.image = #imageLiteral(resourceName: "Erase-filled")
            eraserIcon.tintColor = UIColor.red
            pdfView.isUserInteractionEnabled = false
        } else {
            eraserIcon.image = #imageLiteral(resourceName: "Erase")
            eraserIcon.tintColor = UIColor.black
            pdfView.isUserInteractionEnabled = true
        }
        
    }
    
    @IBAction func searchTapped(_ sender: Any) {
        if searchField.isHidden {
            searchField.isHidden = false
            pdfView.bringSubview(toFront: searchField)
            searchActive = true
        } else {
            searchField.isHidden = true
            searchActive = false
            removeSearchResults()
            searchField.text = ""
            nextSearchResultButton.isEnabled = false
            prevSearchResultButton.isEnabled = false
        }
    }
    
    @IBAction func nextSearchResult(_ sender: Any) {
        let currentPage = pdfView.currentPage?.pageRef?.pageNumber
        var commingSearchResults = searchPages.filter{$0 > currentPage!}
        commingSearchResults = commingSearchResults.sorted()
        if let nextSearchResult = commingSearchResults.first {
            let page = pdfView.document?.page(at: nextSearchResult-1)
            pdfView.go(to: page!)
        }
        searchResultsBeforeOrAfter()
    }
    
    @IBAction func prevSearchResult(_ sender: Any) {
        let currentPage = pdfView.currentPage?.pageRef?.pageNumber
        var prevSearchResults = searchPages.filter{$0 < currentPage!}
        prevSearchResults = prevSearchResults.sorted()
        if let prevSearchResult = prevSearchResults.last {
            let page = pdfView.document?.page(at: prevSearchResult-1)
            pdfView.go(to: page!)
        }
        searchResultsBeforeOrAfter()
    }
    
    
    
    
    override func viewDidLoad() {
        print("viewDidLoad - PDF")
        super.viewDidLoad()
        
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.barTintColor = UIColor.white
        navigationController?.navigationBar.tintColor = UIColor.black
        
        searchField.delegate = self
        
        pdfView.document = document
        currentPage = pdfView.currentPage
        isCurrentPageBookmarked()

        configureUI()
        setupThumbnailView()
        loadDefault()
        
        // Add "highlight" as a uimenuitem
        let highlightTextMenuItem = UIMenuItem(title: "Highlight", action: #selector(highlightText))
        UIMenuController.shared.menuItems = [highlightTextMenuItem]

        NotificationCenter.default.addObserver(self, selector: #selector(handleSettingsPopupClosing), name: Notification.Name.settingsHighlighter, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handlePageChange(notification:)), name: Notification.Name.PDFViewPageChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(widgetTapped(notification:)), name: Notification.Name.PDFViewAnnotationHit, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(closeNotification), name: Notification.Name.notifactionExit, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.postNotification), name: Notification.Name.sendNotification, object: nil)

        
        if saveTime > 0 {
            saveTimer = Timer.scheduledTimer(timeInterval: Double(saveTime*60), target: self, selector: #selector(saveDocument), userInfo: nil, repeats: true)
        } else {
            saveTimer = Timer.scheduledTimer(timeInterval: 600, target: self, selector: #selector(saveDocument), userInfo: nil, repeats: true)
        }
        
        thumbnailIcon.image = #imageLiteral(resourceName: "Layers")
        
        if (pdfView.document?.pageCount)! >= Int(bookmarks.lastPageVisited) {
            let lastVisitedPage = pdfView.document?.page(at: Int(bookmarks.lastPageVisited)-1)
            if bookmarks.lastPageVisited > 0 {
                pdfView.go(to: lastVisitedPage!)
            }
        }
        
        bookmarksBeforeOrAfter()
        undoOrRedoActions()
        nextSearchResultButton.isEnabled = false
        prevSearchResultButton.isEnabled = false
        
        drawView = DrawingView()
        drawView.delegate = self
        drawView.pdfView = self.pdfView
        self.view.addSubview(drawView)
        drawView.isHidden = true
        drawView.isUserInteractionEnabled = true
        drawView.backgroundColor = UIColor.clear
        
        self.view.addSubview(progressMonitor)
        progressMonitor.isHidden = true
        
    }

    
    
    
    
    // MARK:- OBJECT C
    @objc func closeNotification() {
//        progressMonitor.removeFromSuperview()
        progressMonitor.isHidden = true
    }
    
    @objc private func handlePageChange(notification: Notification)
    {
        if let _ = pdfView.currentPage?.pageRef?.pageNumber {
            isCurrentPageBookmarked()
        }
    }
    
    @objc func handleSettingsPopupClosing(notification: Notification) {
        let oldTme = saveTime!
        let settingsVC = notification.object as! PenSettingsViewController
        highlighterColor = settingsVC.highlighterColor
        highlighterThickness = settingsVC.highligherThickness
        penColor = settingsVC.penColor
        penThickness = settingsVC.penThickness
        fontSize = settingsVC.fontSize
        annotationSettings = settingsVC.selectedSettings
        
        if let number = settingsVC.autoSaveTime {
            saveTime = number
        } else {
            saveTime = oldTme
        }
        
        kvStorage.set(annotationSettings, forKey: "annotationSettings")
        kvStorage.synchronize()
        
        if oldTme == saveTime! {
            print("Time not changed")
        } else {
            saveTimer.invalidate()
            if saveTime > 0 {
                saveTimer = Timer.scheduledTimer(timeInterval: Double(saveTime!*60), target: self, selector: #selector(saveDocument), userInfo: nil, repeats: true)
            } else {
                print("Off")
            }
        }
        
        if highlighting {
            drawView.thickness = highlighterThickness * getScale()
            drawView.drawColor = highlighterColor
        }
        if freehand {
            drawView.thickness = penThickness * getScale()
            drawView.drawColor = penColor
        }
        
        if settingsVC.saveNow {
            saveDocument()
        }
        
    }
    
    @objc func highlightText() {
        let selections = pdfView.currentSelection?.selectionsByLine()
        
        guard let page = selections?.first?.pages.first else { return }
        
        selections?.forEach({ selection in
            let highlight = PDFAnnotation(bounds: selection.bounds(for: page), forType: .highlight, withProperties: nil)
            highlight.color = highlighterColor
            highlight.endLineStyle = .circle
            highlight.color.withAlphaComponent(CGFloat(annotationSettings[4])/100)
            
            page.addAnnotation(highlight)
            
            let number = pdfView.currentPage?.pageRef?.pageNumber
            annotationsAdded?.append(highlight)
            annotationsPages?.append(number!-1)
            
            changesMade = true
            needsUploading = true
        })
    }
    
    @objc func postNotification() {
        DispatchQueue.main.async {
            print("PDF VC")
//            self.view.addSubview(self.progressMonitor)
            self.progressMonitor.isHidden = false
            self.progressMonitor.bringSubview(toFront: self.view)
//            self.view.bringSubview(toFront: self.progressMonitor)
            self.progressMonitor.launchMonitor(displayText: nil)
        }
    }
    
    @objc func saveDocument() {
        if changesMade {
            removeSearchResults()
            
//            self.view.bringSubview(toFront: progressMonitor)
            self.progressMonitor.isHidden = false
            self.progressMonitor.bringSubview(toFront: self.view)
            dataManager.savePDF(file: currentFile, document: document)
//            print("Save started")
//            self.sendNotification(text: "Autosaving " + self.PDFfilename)
//
//            let dispatchQueue = DispatchQueue(label: "QueueIdentification", qos: .background)
//            dispatchQueue.async{
//                if self.iCloudURL != nil {
//                    if !self.document.write(to: self.iCloudURL!) {
//                        print("Failed to save PDF to iCloud drive")
//                    } else {
//                        self.changesMade = false
//                        print("Saved " + self.PDFfilename + " to iCloud drive")
//                        self.progressMonitor.text = "Saved " + self.PDFfilename + " to iCloud"
//                        self.postNotification()
//                    }
//                }
//                if self.localURL != nil {
//                    if !self.document.write(to: self.localURL!) {
//                        print("Failed to save PDF to local folder")
//                    } else {
//                        self.changesMade = false
//                        print("Saved " + self.PDFfilename + " locally")
//                        self.progressMonitor.text = "Saved " + self.PDFfilename + " locally"
//                        self.postNotification()
//                    }
//                }
//            }
        } else {
            print("No changes made, not saving")
        }
    }
    
    @objc func sendNotification(text: String) {
//        self.view.addSubview(self.progressMonitor)
//        self.view.bringSubview(toFront: self.progressMonitor)
        self.progressMonitor.isHidden = false
        self.progressMonitor.bringSubview(toFront: self.view)
        self.progressMonitor.launchMonitor(displayText: text)
    }
    
    @objc func widgetTapped(notification: Notification) {

        if let tmp = notification.userInfo?["PDFAnnotationHit"] as? PDFAnnotation {
            currentAnnotation = tmp
            currentAnnotation.backgroundColor = UIColor.clear
        }
    }

    
    
    
    private func configureUI() {
        
        searchField.isHidden = true
        pdfView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        pdfView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        pdfView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        pdfView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        
    }
    
    func loadDefault() {
        switch annotationSettings[0] {
        case 0:
            highlighterColor = UIColor(red: 0/255.0, green: 0/255.0, blue: 255/255.0, alpha: 0.4)
        case 1:
            highlighterColor = UIColor(red: 255/255.0, green: 0/255.0, blue: 0/255.0, alpha: 0.4)
        case 2:
            highlighterColor = UIColor(red: 0/255.0, green: 255/255.0, blue: 0/255.0, alpha: 0.4)
        case 3:
            highlighterColor = UIColor(red: 255/255.0, green: 255/255.0, blue: 0/255.0, alpha: 0.4)
        case 4:
            highlighterColor = UIColor(red: 85/255.0, green: 85/255.0, blue: 85/255.0, alpha: 0.4)
        default:
            highlighterColor = UIColor(red: 255/255.0, green: 255/255.0, blue: 0/255.0, alpha: 0.4)
        }
        highlighterThickness = highlighterThicknesses[annotationSettings[1]]
        
        switch annotationSettings[2] {
        case 0:
            penColor = UIColor(red: 0/255.0, green: 0/255.0, blue: 255/255.0, alpha: 1)
        case 1:
            penColor = UIColor(red: 255/255.0, green: 0/255.0, blue: 0/255.0, alpha: 1)
        case 2:
            penColor = UIColor(red: 0/255.0, green: 255/255.0, blue: 0/255.0, alpha: 1)
        case 3:
            penColor = UIColor(red: 0/255.0, green: 0/255.0, blue: 0/255.0, alpha: 1)
        case 4:
            penColor = UIColor(red: 85/255.0, green: 85/255.0, blue: 85/255.0, alpha: 1)
        default:
            penColor = UIColor(red: 0/255.0, green: 0/255.0, blue: 0/255.0, alpha: 1)
        }
        penThickness = penThicknesses[annotationSettings[3]]
        saveTime = annotationSettings[5]
        fontSize = annotationSettings[6]
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
    
    func undo() {
        if let latestAdded = annotationsAdded?.last {
            pdfView.document?.page(at: (annotationsPages?.last)!)?.removeAnnotation(latestAdded)
            
            annotationsUndone?.append((annotationsAdded?.last)!)
            undonePages?.append((annotationsPages?.last)!)
            
            annotationsAdded?.removeLast()
            annotationsPages?.removeLast()
            undoOrRedoActions()
        }
    }
    
    func redo() {
        if let latestRemoved = annotationsUndone?.last {
            
            pdfView.document?.page(at: (undonePages?.last)!)?.addAnnotation(latestRemoved)
            
            annotationsAdded?.append(latestRemoved)
            annotationsPages?.append((undonePages?.last)!)
            
            annotationsUndone?.removeLast()
            undonePages?.removeLast()
            undoOrRedoActions()
        }
    }
    
    func getScale() -> CGFloat {
        let bounds = self.pdfView.currentPage?.bounds(for: .trimBox)
        return (self.pdfView?.documentView?.frame.width)! / (bounds?.width)!
    }
    
    func bookmarksBeforeOrAfter() {
        let currentPage = pdfView.currentPage?.pageRef?.pageNumber
        let tmp = bookmarks.page?.filter({$0 > currentPage!})
        if tmp?.count != 0 {
            nextBookmark.isEnabled = true
        } else {
            nextBookmark.isEnabled = false
        }
        let tmp2 = bookmarks.page?.filter({$0 < currentPage!})
        if tmp2?.count != 0 {
            prevBookmark.isEnabled = true
        } else {
            prevBookmark.isEnabled = false
        }

    }
    
    func searchResultsBeforeOrAfter() {
        let currentPage = pdfView.currentPage?.pageRef?.pageNumber
        let commingSearchResults = searchPages.filter{$0 > currentPage!}
        if commingSearchResults.count != 0 {
            nextSearchResultButton.isEnabled = true
        } else {
            nextSearchResultButton.isEnabled = false
        }
        let pastSearchResults = searchPages.filter{$0 < currentPage!}
        if pastSearchResults.count != 0 {
            prevSearchResultButton.isEnabled = true
        } else {
            prevSearchResultButton.isEnabled = false
        }
    }
    
    func undoOrRedoActions() {
        if annotationsAdded?.isEmpty == true {
            undoIcon.isEnabled = false
        } else {
            undoIcon.isEnabled = true
        }
        if annotationsUndone?.isEmpty == true {
            redoIcon.isEnabled = false
        } else {
            redoIcon.isEnabled = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "highlighterSettingsSegue") {
            let destination = segue.destination as! PenSettingsViewController
            destination.preferredContentSize = settingsBox
            destination.highlighterColor = highlighterColor
            destination.highligherThickness = highlighterThickness
            destination.highlightThicknesses = highlighterThicknesses
            destination.penColor = penColor
            destination.penThickness = penThickness
            destination.penThicknesses = penThicknesses
            destination.selectedSettings = annotationSettings
        }
        
    }
    
    func pointOnTextAnnotation(bounds: CGRect, point: CGPoint) -> String? {
        var pointOnText: String? = nil
        
        if abs(bounds.minX - point.x) < precision {
            if abs(bounds.maxY - point.y) < precision {
                pointOnText = "topLeft"
            } else if abs(bounds.minY - point.y) < precision {
                pointOnText = "bottomLeft"
            }
            
        } else if abs(bounds.maxX - point.x) < precision {
            if abs(bounds.maxY - point.y) < precision {
                pointOnText = "topRight"
            } else if abs(bounds.minY - point.y) < precision {
                pointOnText = "bottomRight"
            }
            
        } else if abs(bounds.minX + bounds.center.x - point.x) < 2*precision && abs(bounds.minY + bounds.center.y - point.y) < 2*precision {
            pointOnText = "center"
            
        } else if bounds.minX < point.x && bounds.maxX > point.x && bounds.minY < point.y && bounds.maxY > point.y {
            pointOnText = "withinBounds"
        }
        
        return pointOnText
    }
    
    func isCurrentPageBookmarked() {
        
        var found = false
        if let number = pdfView.currentPage?.pageRef?.pageNumber {
            if bookmarks.page?.first(where: {$0 == number}) != nil {
                bookmarkButton.image = #imageLiteral(resourceName: "Bookmark-filled")
                bookmarkButton.tintColor = UIColor.red
                found = true
            }
        }
        if !found {
            bookmarkButton.image = #imageLiteral(resourceName: "Bookmark.png")
            bookmarkButton.tintColor = UIColor.black
        }
        bookmarksBeforeOrAfter()
    }
    
    func textFieldAdded() {
        
        guard let page = pdfView.currentPage else {return}
        
        addTextButton.image = #imageLiteral(resourceName: "AddText.png")
        addTextButton.tintColor = UIColor.black
        
        pdfView.isUserInteractionEnabled = true
        
        for annotation in page.annotations {
            if annotation.widgetFieldType == PDFAnnotationWidgetSubtype.text {
                let text = annotation.widgetStringValue?.trimmingCharacters(in: .whitespaces)
                if text == nil || (text?.isEmpty)! {
                    annotation.backgroundColor = UIColor.blue.withAlphaComponent(0.1)
                } else {
                    annotation.backgroundColor = UIColor.clear
                }
            }
        }
        
        changesMade = true
        
    }
    
    func drawResizingControllers() {
//        let topLeft = UIView()
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 50, height: 50))
        let img = renderer.image { ctx in
            ctx.cgContext.setFillColor(UIColor.red.cgColor)
            ctx.cgContext.setStrokeColor(UIColor.green.cgColor)
            ctx.cgContext.setLineWidth(10)
            
            let rectangle = CGRect(x: 10, y: 10, width: 10, height: 10)
            ctx.cgContext.addRect(rectangle)
            ctx.cgContext.drawPath(using: .fillStroke)
        }
    }
    
    
    
    
    // MARK: - Search bar
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true;
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        matches = []
        searchActive = false;
        removeSearchResults()
        searchField.text = ""
        searchField.isHidden = true
        nextSearchResultButton.isEnabled = false
        prevSearchResultButton.isEnabled = false
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchActive {

            removeSearchResults()
            
            var minString = 1
            if document.pageCount > 300 {
                minString = 3
            }

            if searchText.count > minString {
                matches = document.findString(searchText, withOptions: .caseInsensitive)
                
                for match in matches {
                    let page = match.pages.first
                    let highlight = PDFAnnotation(bounds: match.bounds(for: page!), forType: .highlight, withProperties: nil)
                    highlight.color = .yellow
                    highlight.color.withAlphaComponent(0.4)
                    
                    searchMatches.append(highlight)
                    searchPages.append((page?.pageRef?.pageNumber)!)
                    page?.addAnnotation(highlight)
                }
                if let firstSearchResult = searchPages.first {
                    let page = pdfView.document?.page(at: firstSearchResult-1)
                    pdfView.go(to: page!)
                }
                
                searchResultsBeforeOrAfter()
                
            }
        } else {
            removeSearchResults()
        }
    }
    
    func removeSearchResults() {
        if searchMatches.count > 0 {
            for i in 0..<searchMatches.count {
                let pageNumber = searchPages[i]
                let page = document.page(at: pageNumber-1)
                let annotation = searchMatches[i]
                page?.removeAnnotation(annotation)
            }
        }
        matches = []
        searchMatches = []
        searchPages = []
        nextSearchResultButton.isEnabled = false
        prevSearchResultButton.isEnabled = false
    }
    
    
    
    
    // MARK: - Touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let page = pdfView.currentPage else {return}
        
        if !erasing {
            if let touch = touches.first {
                point = touch.location(in: pdfView)
                point = pdfView.convert(point, to: page)
                for annotation in page.annotations {
                    print(annotation)
                    if annotation.widgetFieldType == PDFAnnotationWidgetSubtype.text {
                        let tmp = pointOnTextAnnotation(bounds: annotation.bounds, point: point)
                        if tmp != nil {
                            pointOnTextbox = tmp!
                            currentAnnotation = annotation
                            move = true
                            addTextButton.image = #imageLiteral(resourceName: "Move.png")
                            addText = false
                        }
                    }
                }
            }
        }

        if addText {
            
            let pageBounds = page.bounds(for: .cropBox)
            let textFieldBounds = CGRect(x: point.x, y: point.y, width: pageBounds.size.width*0.15, height: pageBounds.size.height*0.05)
            let textField = PDFAnnotation(bounds: textFieldBounds, forType: PDFAnnotationSubtype(rawValue: PDFAnnotationSubtype.widget.rawValue), withProperties: nil)
            textField.widgetFieldType = PDFAnnotationWidgetSubtype(rawValue: PDFAnnotationWidgetSubtype.text.rawValue)
            textField.backgroundColor = UIColor.blue.withAlphaComponent(0.1)
            textField.font = UIFont.systemFont(ofSize: CGFloat(fontSize))
            textField.isMultiline = true
            page.addAnnotation(textField)
            
            textFieldAdded()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let page = pdfView.currentPage else {return}
        
        if erasing {
            if let touch = touches.first {
                var position = touch.location(in: pdfView)
                position = pdfView.convert(position, to: page)
                if let tmp = pdfView.currentPage?.annotation(at: position) {
                    pdfView.currentPage?.removeAnnotation(tmp)
                    changesMade = true
                    needsUploading = true
                }
            }
        }
        
        if move {
            guard let page = pdfView.currentPage else {return}
            if let touch = touches.first {
                point = touch.location(in: pdfView)
                point = pdfView.convert(point, to: page)
                let oldBounds = currentAnnotation.bounds
                if pointOnTextbox == "topRight" {
                    currentAnnotation.bounds = CGRect(x: oldBounds.minX, y: oldBounds.minY, width: abs(oldBounds.minX - point.x), height: abs(oldBounds.minY - point.y))
                } else if pointOnTextbox == "bottomRight" {
                    currentAnnotation.bounds = CGRect(x: oldBounds.minX, y: point.y, width: abs(oldBounds.minX - point.x), height: abs(oldBounds.maxY - point.y))
                } else if pointOnTextbox == "topLeft" {
                    currentAnnotation.bounds = CGRect(x: point.x, y: oldBounds.minY, width: abs(oldBounds.maxX - point.x), height: abs(oldBounds.minY - point.y))
                } else if pointOnTextbox == "bottomLeft" {
                    currentAnnotation.bounds = CGRect(x: point.x, y: point.y, width: abs(oldBounds.maxX - point.x), height: abs(oldBounds.maxY - point.y))
                } else if pointOnTextbox == "center" {
                    currentAnnotation.bounds = CGRect(x: point.x - oldBounds.width/2, y: point.y - oldBounds.height/2, width: oldBounds.width, height: oldBounds.height)
                }

            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard let page = pdfView.currentPage else {return}
        page.annotations.filter { $0.widgetFieldType == PDFAnnotationWidgetSubtype.text }.forEach { $0.shouldDisplay = true }
        pointOnTextbox = "outside"
        if move {
            changesMade = true
        }
    }
    


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillDisappear(_ animated: Bool) {
        saveTimer.invalidate()
        bookmarks.lastPageVisited = Int32((pdfView.currentPage?.pageRef?.pageNumber)!)
        NotificationCenter.default.post(name: Notification.Name.closingPDF, object: self)
    }
        
}



extension PDFViewController: DrawingViewDelegate {
    
    func didEndDrawLine(bezierPath: UIBezierPath) {
        guard let page = pdfView.currentPage else {return}
        
        let annotationPath = UIBezierPath(cgPath: bezierPath.cgPath)
        
        let border = PDFBorder()
        if freehand {
            border.lineWidth = penThickness
        } else if highlighting{
            border.lineWidth = highlighterThickness
            print(border.lineWidth)
        }
        
        let rect = CGRect(x:annotationPath.bounds.minX-border.lineWidth/2, y:annotationPath.bounds.minY-border.lineWidth/2, width:annotationPath.bounds.maxX-annotationPath.bounds.minX+border.lineWidth, height:annotationPath.bounds.maxY-annotationPath.bounds.minY+border.lineWidth)
        
        annotationPath.moveCenter(to: rect.center)
        
        let annotation = PDFAnnotation(bounds: rect, forType: .ink, withProperties: nil)
        
        if freehand {
            annotation.color = penColor
            annotationPath.lineCapStyle = .round
            annotationPath.lineJoinStyle = .round
        } else {
            annotation.color = highlighterColor
            annotationPath.lineCapStyle = .round
            annotationPath.lineJoinStyle = .round
        }
        
        annotation.border = border
        annotation.add(annotationPath)
        page.addAnnotation(annotation)

        let number = pdfView.currentPage?.pageRef?.pageNumber
        annotationsAdded?.append(annotation)
        annotationsPages?.append(number!-1)

        changesMade = true
        needsUploading = true
        undoOrRedoActions()
        
    }
}

extension CGPoint{
    func vector(to p1:CGPoint) -> CGVector{
        return CGVector(dx: p1.x-self.x, dy: p1.y-self.y)
    }
}

extension UIBezierPath{
    func moveCenter(to:CGPoint) -> Self{
        let bound  = self.cgPath.boundingBox
        let center = bounds.center
        
        let zeroedTo = CGPoint(x: to.x-bound.origin.x, y: to.y-bound.origin.y)
        let vector = center.vector(to: zeroedTo)
        
        offset(to: CGSize(width: vector.dx, height: vector.dy))
        return self
    }
    
    func offset(to offset:CGSize) -> Self{
        let t = CGAffineTransform(translationX: offset.width, y: offset.height)
        applyCentered(transform: t)
        return self
    }
    
    func fit(into:CGRect) -> Self{
        let bounds = self.cgPath.boundingBox
        
        let sw     = into.size.width/bounds.width
        let sh     = into.size.height/bounds.height
        let factor = min(sw, max(sh, 0.0))
        
        return scale(x: factor, y: factor)
    }
    
    func scale(x:CGFloat, y:CGFloat) -> Self{
        let scale = CGAffineTransform(scaleX: x, y: y)
        applyCentered(transform: scale)
        return self
    }
    
    
    func applyCentered(transform: @autoclosure () -> CGAffineTransform ) -> Self{
        let bound  = self.cgPath.boundingBox
        let center = CGPoint(x: bound.midX, y: bound.midY)
        var xform  = CGAffineTransform.identity
        
        xform = xform.concatenating(CGAffineTransform(translationX: -center.x, y: -center.y))
        xform = xform.concatenating(transform())
        xform = xform.concatenating( CGAffineTransform(translationX: center.x, y: center.y))
        apply(xform)
        
        return self
    }
}

extension CGRect{
    var center: CGPoint {
        return CGPoint( x: self.size.width/2.0,y: self.size.height/2.0)
    }
}
