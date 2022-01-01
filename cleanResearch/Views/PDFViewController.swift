//
//  PDFViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-06-06.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import UIKit
import PDFKit
import Speech
import AVFoundation


internal class ScoreCellSettings: UICollectionViewCell {

    @IBOutlet weak var scoreNumber: UILabel!
    @IBOutlet weak var subScoreTV: UITableView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        subScoreTV.backgroundColor = UIColor.clear
    }

}

class PDFViewController: UIViewController, UISearchBarDelegate, UIPencilInteractionDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate, AVSpeechSynthesizerDelegate, SFSpeechRecognizerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDelegate, UITableViewDataSource {
    
    // CLASSES
    var fileHandler: FileHandler!
    var progressMonitor: ProgressMonitor!
    var dataManager: DataManager!
    var pdfViewManager: PDFViewManager!

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

    var currentAnnotation: PDFAnnotation!
    
    var saveTimer: Timer!
    var postTimer: Timer?

    var bookmarkPages: [Int]?
    var lastPageVisited: Int?
    
    let thumbnailPanelSize = CGFloat(80)
    let sidebarBackgroundColor = UIColor.lightGray.withAlphaComponent(0.75)

    var settingsBox = CGSize(width: 450, height: 550)
    var textSettingsBox = CGSize(width: 340, height: 100)
    var scoreSettingsBox = CGSize(width: 400, height: 500)
    var notesBox: CGSize!
    
    var highlighterColor = UIColor(red: 255/255.0, green: 255/255.0, blue: 0/255.0, alpha: 0.4)
    var highlighterThickness: CGFloat!
    let highlighterThicknesses: [CGFloat] = [6, 9, 12, 15, 19]
    var highlightScale: CGFloat = 0.5

    var penColor = UIColor(red: 0/255.0, green: 0/255.0, blue: 255/255.0, alpha: 1)
    var penThickness: CGFloat!
    let penThicknesses: [CGFloat] = [0.5, 1, 2, 3, 4]
    let penScale: CGFloat = 0.1
    
    var matches: [PDFSelection]!
    var searchMatches: [PDFAnnotation] = []
    var searchPages: [Int] = []

    var point: CGPoint!
    var pointOnTextbox: String!
    var pointOnRulerBox: String!
    var moveDeltaX: [CGFloat]!
    var moveDeltaY: [CGFloat]!
    var precision: CGFloat = 15
    var currentTextAnnotation: PDFAnnotation!
    var selectedAnnotations: [PDFAnnotation]?
    
    var annotationSettings: [Int]!
    
    let forceSensitivity: CGFloat = 4.0
    
    var tapCoordinates: [CGFloat]!
    
    let speechSynthesizer = AVSpeechSynthesizer()
    var speechText: String?
    var playing = false
    
    var isLandscape: Bool!
    
    let audioEngine: AVAudioEngine? = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    
    var bookmarkDown = false
    var textLength = 0
    
    var selectedStudent = SelectedScore(main: 0, sub: 0, value: 0)
    var student: Student? = nil
    var docIsExam: Bool = false
    var grading: Grading?
    var selectedExam: Exams? = nil
    var path: String = ""
    
    var initialLoad = true
    
    // MARK:- OUTLETS
    @IBOutlet weak var thumbnailIcon: UIBarButtonItem!
    @IBOutlet weak var pdfView: PDFView!
    @IBOutlet weak var hightlightIcon: UIBarButtonItem!
    @IBOutlet weak var settingsButton: UIBarButtonItem!
    @IBOutlet weak var penIcon: UIBarButtonItem!
    @IBOutlet weak var undoIcon: UIBarButtonItem!
    @IBOutlet weak var eraserIcon: UIBarButtonItem!
    @IBOutlet weak var searchField: UISearchBar!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var prevSearchResultButton: UIButton!
    @IBOutlet weak var nextSearchResultButton: UIButton!
    @IBOutlet weak var addTextButton: UIBarButtonItem!
    @IBOutlet weak var pageOptionsButton: UIBarButtonItem!
    @IBOutlet weak var saveIndicator: UILabel!
    @IBOutlet weak var bookmarkLabel: UITextField!
    @IBOutlet weak var readingRuler: UIView!
    @IBOutlet weak var topLeftIcon: UIImageView!
    @IBOutlet weak var bottomLeftIcon: UIImageView!
    @IBOutlet weak var topRightIcon: UIImageView!
    @IBOutlet weak var bottomRightIcon: UIImageView!
    @IBOutlet weak var centerIcon: UIImageView!
    @IBOutlet weak var audioView: UIView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var audioButton: UIBarButtonItem!
    @IBOutlet weak var notesButton: UIBarButtonItem!
    @IBOutlet weak var editPDFOptions: UIView!
    @IBOutlet weak var editColorCV: UICollectionView!
    @IBOutlet weak var interactiveArea: UIView!
    @IBOutlet weak var selectButton: UIBarButtonItem!
    @IBOutlet weak var bookmarkView: UIView!
    @IBOutlet weak var bookmarkButton: UIButton!
    @IBOutlet weak var prevBookmark: UIButton!
    @IBOutlet weak var nextBookmark: UIButton!
    @IBOutlet weak var bookmarksGrid: UIButton!
    @IBOutlet weak var hideOrShowBookmarksButton: UIButton!
    @IBOutlet weak var pageOptionsView: UIView!
    @IBOutlet weak var noteView: UIView!
    @IBOutlet weak var selectedOptionsView: UIView!
    @IBOutlet weak var textNotes: UITextView!
    @IBOutlet weak var takeNotesButton: UIBarButtonItem!
    @IBOutlet weak var pasteButton: UIButton!
    @IBOutlet weak var filenameLabel: UILabel!
    @IBOutlet weak var totalScore: UILabel!
    @IBOutlet weak var scoreCV: UICollectionView!
    @IBOutlet weak var scoreView: UIView!
    @IBOutlet weak var showHideScoreButton: UIButton!
    @IBOutlet weak var scoreValueStepper: UIStepper!
    @IBOutlet weak var scoreBGView: UIView!
    @IBOutlet weak var examLabel: UILabel!
    @IBOutlet weak var studentName: UILabel!
    
    
    // MARK:- IBActions
    @IBAction func audioTapped(_ sender: Any) {
        
        if audioView.frame.minY < 0 {
            speechText = pdfViewManager.getPageText()
            audioView.isHidden = false
            self.view.bringSubview(toFront: audioView)
            moveViewDown(view: audioView, offset: 10)
            audioButton.image = #imageLiteral(resourceName: "audio-filled")
        } else {
            let image = UIImage(named: "play-button-circled-filled.png")
            playButton.setImage(image, for: .normal)
            moveViewUp(view: audioView, offset: 10)
            audioButton.image = #imageLiteral(resourceName: "audio")
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    @IBAction func rewindTapped(_ sender: Any) {
        speechSynthesizer.stopSpeaking(at: .immediate)

        let speechUtterance = AVSpeechUtterance(string: speechText!)
        speechUtterance.voice = AVSpeechSynthesisVoice(language: pdfViewManager.voices[annotationSettings[20]].code)
        
        speechSynthesizer.speak(speechUtterance)
    }
    
    @IBAction func stopTapped(_ sender: Any) {
        playing = false
        
        let image = UIImage(named: "play-button-circled-filled.png")
        playButton.setImage(image, for: .normal)
        audioButton.image = #imageLiteral(resourceName: "audio")
        audioView.isHidden = true
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
    
    @IBAction func playTapped(_ sender: Any) {
        
        if !speechSynthesizer.isSpeaking {
            if speechText != nil {
                let speechUtterance = AVSpeechUtterance(string: speechText!)
                speechUtterance.voice = AVSpeechSynthesisVoice(language: pdfViewManager.voices[annotationSettings[20]].code)
                speechSynthesizer.speak(speechUtterance)
                playing = true
                let image = UIImage(named: "pause-button-filled.png")
                playButton.setImage(image, for: .normal)
            }
        } else {
            if playing {
                let image = UIImage(named: "play-button-circled-filled.png")
                playButton.setImage(image, for: .normal)
                speechSynthesizer.pauseSpeaking(at: .immediate)
            } else {
                let image = UIImage(named: "pause-button-filled.png")
                playButton.setImage(image, for: .normal)
                speechSynthesizer.continueSpeaking()
            }
            playing = !playing
        }
    }
    
    @IBAction func addTextTapped(_ sender: Any) {
        
        resetAllButtonsToDefaultState()
        drawView.isHidden = true
        
        guard let page = pdfView.currentPage else {return}

        switch pdfViewManager.action {
        case .addText:
            enableScroll(state: true)
            
            for annotation in page.annotations {
                if annotation.widgetFieldType == PDFAnnotationWidgetSubtype.text {
                    let text = annotation.widgetStringValue?.trimmingCharacters(in: .whitespaces)
                    if text == nil || (text?.isEmpty)! {
                        page.removeAnnotation(annotation) // REMOVE EMPTY ONES
                    } else {
                        annotation.backgroundColor = UIColor.clear
                    }
                }
            }
            
            pdfViewManager.action = .none
            
        default:
            enableScroll(state: false)

            addTextButton.image = #imageLiteral(resourceName: "AddTextFilled.png")
            addTextButton.tintColor = UIColor.red

            for annotation in page.annotations {
                if annotation.widgetFieldType == PDFAnnotationWidgetSubtype.text {
                    
                    annotation.backgroundColor = UIColor.blue.withAlphaComponent(0.1)
                }
            }
            
            pdfViewManager.action = .addText
        
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
        print("bookmarkTapped")
        
        if let number = pdfView.currentPage?.pageRef?.pageNumber {
            if !(bookmarks.page?.contains(number))! {
                
                //ADD BOOKMARK AND LABEL/BLANK
                let currentText = bookmarkLabel.text ?? ""
                
                bookmarks.page?.append(number)

                if let index = bookmarks.page?.index(where: { $0 == number }) {
                    if bookmarks.label == nil {
                        bookmarks.label = [currentText]
                    } else {
                        bookmarks.label?.insert(currentText, at: index)
                    }
                }
                
                bookmarkButton.setImage(UIImage(named: "Bookmark-filled"), for: .normal)
                
            } else {
                
                //CLEAR BOOKMARK AND LABEL
                if bookmarks.page?.first(where: {$0 == number}) != nil {
                    if let index = bookmarks.page?.index(where: { $0 == number }) {
                        bookmarks.label?.remove(at: index)
                    }
                }

                bookmarks.page = bookmarks.page?.filter{$0 != number}
                bookmarkButton.setImage(UIImage(named: "Bookmark"), for: .normal)
                
            }
        }
        
        self.bookmarksGrid.isHidden = !bookmarksExists()
        
    }
    
    @IBAction func undoTapped(_ sender: Any) {
        
        if let latestAnnotation = pdfViewManager.annotationsAltered?.last {
            switch latestAnnotation.action {
            case .erase:
                
                latestAnnotation.page?.addAnnotation(latestAnnotation.annotation)
                pdfViewManager.annotationsAltered!.removeLast()

            default:
                let latestAdded = latestAnnotation.annotation
                
                for i in 0..<pdfView.document!.pageCount {
                    if let annotation = pdfView.document?.page(at: i)?.annotations.first(where: {$0 == latestAdded}) {
                        pdfView.document?.page(at: i)!.removeAnnotation(annotation)
                    }
                }
                pdfViewManager.annotationsAltered!.removeLast()

            }
        }
        undoOrRedoActions()
    }
    
    @IBAction func togglePen(_ sender: Any) {
        
        pdfViewManager.prevAction = .pen
        
        if pdfViewManager.action != .pen {
            pdfViewManager.action = .pen
            activateDrawView()
        } else {
            drawView.isHidden = true
            pdfViewManager.action = .none
            enableScroll(state: true)
            resetAllButtonsToDefaultState()
        }

    }
    
    @IBAction func toggleThumbnails(_ sender: Any) {
        
        if thumbnailIcon.image == #imageLiteral(resourceName: "Layers") {
            thumbnailIcon.image = #imageLiteral(resourceName: "Layers-filled")
            pdfThumbnailView.isHidden = false
            moveViewLeft(view: pdfThumbnailView, offset: 0)
        } else {
            thumbnailIcon.image = #imageLiteral(resourceName: "Layers")
            moveViewRight(view: pdfThumbnailView, offset: 0)
        }
    }
    
    @IBAction func toggleHighlight(_ sender: Any) {
        
        pdfViewManager.prevAction = .highlight
        
        if pdfViewManager.action != .highlight {
            pdfViewManager.action = .highlight
            activateDrawView()
        } else {
            drawView.isHidden = true
            pdfViewManager.action = .none
            enableScroll(state: true)
            resetAllButtonsToDefaultState()
        }

    }
    
    @IBAction func toogleEraser(_ sender: Any) {
        
        resetAllButtonsToDefaultState()
        drawView.isHidden = true
        pdfView.bringSubview(toFront: pdfView)
        
        guard let page = pdfView.currentPage else {return}
        
        switch pdfViewManager.action {
        case .erase:
            enableScroll(state: true)
            pdfViewManager.action = .none
            
        default:
            enableScroll(state: false)
            
            eraserIcon.image = #imageLiteral(resourceName: "Erase-filled")
            eraserIcon.tintColor = UIColor.red
            
            for annotation in page.annotations {
                if annotation.widgetFieldType == PDFAnnotationWidgetSubtype.text {
                    annotation.backgroundColor = UIColor.blue.withAlphaComponent(0.1)
                }
            }
            
            pdfViewManager.action = .erase
            
        }
    }
    
    @IBAction func searchTapped(_ sender: Any) {
        if searchView.isHidden {
            searchView.isHidden = false
            self.view.bringSubview(toFront: searchView)
            pdfViewManager.searching = .on
        } else {
            searchView.isHidden = true
            pdfViewManager.searching = .off
            removeSearchResults()
            searchField.text = ""
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
    
    @IBAction func pageOptionsTapped(_ sender: Any) {
        
        if pageOptionsView.frame.minY < 0 {
            pageOptionsView.isHidden = false
            self.view.bringSubview(toFront: pageOptionsView)
            moveViewDown(view: pageOptionsView, offset: 10)
        } else {
            moveViewUp(view: pageOptionsView, offset: 10)
        }
        self.view.bringSubview(toFront: pageOptionsView)
    }
    
    @IBAction func bookmarkLabelTapped(_ sender: Any) {
        print("bookmarkLabelTapped")
        
        if let number = pdfView.currentPage?.pageRef?.pageNumber {
            if bookmarks.page?.first(where: {$0 == number}) != nil {
                if let index = bookmarks.page?.index(where: { $0 == number }) {
                    bookmarks.label?[index] = bookmarkLabel.text!
                }
            }
        }
    }
    
    @IBAction func openBookmarkGrid(_ sender: Any) {
        
    }
    
    @IBAction func rulerButtonTapped(_ sender: Any) {
        
        annotationSettings[7] = abs(annotationSettings[7] - 1)
        
        topLeftIcon.isHidden = true
        topRightIcon.isHidden = true
        bottomLeftIcon.isHidden = true
        bottomRightIcon.isHidden = true
        centerIcon.isHidden = true
    }
    
    @IBAction func closeEditColor(_ sender: Any) {
//        editPDFOptions.isHidden = true
        moveViewLeft(view: editPDFOptions, offset: 0)
    }
    
    @IBAction func selectAnnotationsTapped(_ sender: Any) {
        
        drawView.isHidden = true
        
        if pdfViewManager.action == .selectAnnotation {
            pdfViewManager.action = .none
            
            selectButton.image = #imageLiteral(resourceName: "select")
            interactiveArea.isHidden = true
            moveViewUp(view: selectedOptionsView, offset: 10)

            pdfView.isUserInteractionEnabled = true
            
        } else {
            
            pasteButton.isEnabled = !dataManager.copiedAnnotation.isEmpty
            
            pdfViewManager.action = .selectAnnotation
            selectedOptionsView.isHidden = false

            resetAllButtonsToDefaultState()
            selectButton.image = #imageLiteral(resourceName: "selecting")
            
            moveViewDown(view: selectedOptionsView, offset: 10)
            pdfView.isUserInteractionEnabled = false
        }
        
    }
    
    @IBAction func hideOrShowBookmarksTapped(_ sender: Any) {
        if bookmarkDown {
            moveBookmarksUp()
        } else {
            moveBookmarksDown()
        }
    }
    
    @IBAction func insertPageBefore(_ sender: Any) {
        guard
            let url = Bundle.main.url(forResource: "BlankPDF", withExtension: "pdf"),
            let blankPDF = PDFDocument(url: url)
            else { fatalError() }
        
        guard let page = pdfView.currentPage else {return}
        if page.pageRef!.pageNumber-1 >= 0 {
            document.insert(blankPDF.page(at: 0)!, at: page.pageRef!.pageNumber-1)
        } else {
            document.insert(blankPDF.page(at: 0)!, at: 0)
        }
        pdfView.layoutDocumentView()
        setupThumbnailView()
        
        pdfViewManager.pdfView = pdfView
        drawView.pdfView = pdfView
        
        pdfViewManager.changesMade = true
    }
    
    @IBAction func insertPageAfter(_ sender: Any) {
        guard
            let url = Bundle.main.url(forResource: "BlankPDF", withExtension: "pdf"),
            let blankPDF = PDFDocument(url: url)
            else { fatalError() }
        
        guard let page = pdfView.currentPage else {return}
        pdfView.document!.insert(blankPDF.page(at: 0)!, at: page.pageRef!.pageNumber)
        
        pdfView.layoutDocumentView()
        setupThumbnailView()
        
        pdfViewManager.pdfView = pdfView
        drawView.pdfView = pdfView
        
        undoOrRedoActions()
        pdfViewManager.changesMade = true
    }
    
    @IBAction func deletePage(_ sender: Any) {
        if pdfView.document!.pageCount > 1 {
            guard let page = pdfView.currentPage else {return}
            document.removePage(at: page.pageRef!.pageNumber-1)

            pdfView.layoutDocumentView()
            setupThumbnailView()

            pdfViewManager.pdfView = pdfView
            drawView.pdfView = pdfView
            
            pdfViewManager.changesMade = true
        }
    }
    
    @IBAction func takeNotesTapped(_ sender: Any) {
        pdfViewManager.takeNotes = !pdfViewManager.takeNotes
        if pdfViewManager.takeNotes {
            moveViewDown(view: noteView, offset: 0)
            pdfViewManager.notesDown = true
            takeNotesButton.image = #imageLiteral(resourceName: "takeNoteFilled")
            takeNotesButton.tintColor = UIColor.red

            textNotes.text = dataManager.getNote(file: currentFile)
        } else {
            moveViewUp(view: noteView, offset: 0)
            pdfViewManager.notesDown = false
            takeNotesButton.image = #imageLiteral(resourceName: "takeNote")
            takeNotesButton.tintColor = UIColor.black
            view.endEditing(true)
            dataManager.updateNotes(file: currentFile, text: textNotes.text) //FIX: EVEN WHEN CLOSING
        }
    }
    
    @IBAction func deleteSelectedTapped(_ sender: Any) {
        for annotation in selectedAnnotations! {
            annotation.page?.removeAnnotation(annotation)
            pdfViewManager.annotationsAltered?.append((annotation: annotation, action: .erase, page: annotation.page))
            undoOrRedoActions()
        }
    }
    
    @IBAction func pasteSelectedTapped(_ sender: Any) {
        if !dataManager.copiedAnnotation.isEmpty {
            for annotation in dataManager.copiedAnnotation {
                pdfView.currentPage?.addAnnotation(annotation)
            }
        }
    }
    
    @IBAction func copySelectedTapped(_ sender: Any) {
        
        dataManager.copiedAnnotation = []
        
        if !selectedAnnotations!.isEmpty {
            for annotation in selectedAnnotations! {
                dataManager.copiedAnnotation.append(annotation)
            }
        }
        
        pasteButton.isEnabled = !dataManager.copiedAnnotation.isEmpty
    }
    
    @IBAction func changeScore(_ sender: Any) {
        if !initialLoad {
            selectedStudent.value = scoreValueStepper.value
            student!.score![selectedStudent.main][selectedStudent.sub] = selectedStudent.value
            student!.totalScore = student!.score!.joined().reduce(0, +)
            totalScore.text = "\(student!.score!.joined().reduce(0, +))" + "/" + "\(selectedExam!.maxScore)"
            dataManager.saveCoreData()
            dataManager.loadCoreData()
            
            scoreCV.reloadData()
        }
    }
    
    @IBAction func hideShowScore(_ sender: Any) {
        if abs(scoreView.frame.maxY - self.view.frame.maxY) < 10 {
            self.view.bringSubview(toFront: scoreView)
            moveViewDown(view: scoreView, offset: Int(-self.showHideScoreButton.bounds.height))
            showHideScoreButton.setImage(UIImage(named: "ScoreUp"), for: .normal)
        } else {
            moveViewUp(view: scoreView, offset: Int(-self.showHideScoreButton.bounds.height))
            showHideScoreButton.setImage(UIImage(named: "ScoreDown"), for: .normal)
        }
    }
    
    @IBAction func scoreSettingsTapped(_ sender: Any) {
        performSegue(withIdentifier: "ScoreSegue", sender: self)
    }
    
    
    
    
    
    
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initialLoad = true
        
        navigationController?.isNavigationBarHidden = false
        navigationController?.navigationBar.barTintColor = UIColor.white
        navigationController?.navigationBar.tintColor = UIColor.black
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.backgroundColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 1)
        
        pdfView.document = document
        document.delegate = self
        currentPage = pdfView.currentPage
        
        pdfViewManager.currentFile = currentFile
        pdfViewManager.pdfView = pdfView
        
        // Views
        searchView.layer.cornerRadius = 8
        searchView.layer.borderWidth = 1
        searchView.layer.borderColor = UIColor.black.cgColor
        drawView = DrawingView()
        drawView.pdfView = self.pdfView
        drawView.pdfViewManager = pdfViewManager
        self.view.addSubview(drawView)
        drawView.isUserInteractionEnabled = true
        drawView.backgroundColor = UIColor.clear
        
        configureUI()

        updateSettings(oldTime: nil)
        
        // Add uimenuitems
        let highlightTextMenuItem = UIMenuItem(title: "Highlight", action: #selector(highlightText))
        let speakTextMenuItem = UIMenuItem(title: "Read aloud", action: #selector(speakText))
        let setTextAsJournal = UIMenuItem(title: "Journal", action: #selector(setJournal))
        let setTextAsAuthor = UIMenuItem(title: "Author", action: #selector(setAuthor))
        UIMenuController.shared.menuItems = [highlightTextMenuItem, speakTextMenuItem, setTextAsJournal, setTextAsAuthor]
        
        thumbnailIcon.image = #imageLiteral(resourceName: "Layers")
        
        if (pdfView.document?.pageCount)! >= Int(bookmarks.lastPageVisited) {
            let lastVisitedPage = pdfView.document?.page(at: Int(bookmarks.lastPageVisited)-1)
            if bookmarks.lastPageVisited > 0 {
                pdfView.go(to: lastVisitedPage!)
            }
        }
        
        bookmarksBeforeOrAfter()
        undoOrRedoActions()
        initiateTimer()
        
        // Delegates
        searchField.delegate = self
        speechSynthesizer.delegate = self
        editColorCV.delegate = self
        editColorCV.dataSource = self
        scoreCV.delegate = self
        scoreCV.dataSource = self
        bookmarkLabel.delegate = self
        drawView.delegate = self

        self.view.addSubview(progressMonitor)
        
        switch currentFile.category {
        case "Publications":
            self.notesButton.isEnabled = true
        default:
            self.notesButton.isEnabled = false
        }
        
        self.bookmarksGrid.isHidden = !bookmarksExists()
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(touchedRuler))
        self.readingRuler.addGestureRecognizer(gesture)
        
        if annotationSettings[8] != 0 && annotationSettings[9] != 0 && annotationSettings[10] != 0 && annotationSettings[11] != 0 {
            readingRuler.frame = CGRect(x: annotationSettings[8], y: annotationSettings[9], width: annotationSettings[10], height: annotationSettings[11])
        }
        
//        readingRuler.layer.borderWidth = CGFloat(annotationSettings[17])
//        readingRuler.layer.borderColor = UIColor.black.withAlphaComponent(CGFloat(annotationSettings[18])/100).cgColor
        
        textNotes.text = dataManager.getNote(file: currentFile)
        textLength = textNotes.text.count
        
        //HIDE STUFF
        audioView.isHidden = true
        selectedOptionsView.isHidden = true
        searchView.isHidden = true
        pageOptionsView.isHidden = true
        drawView.isHidden = true
        progressMonitor.isHidden = true
        saveIndicator.isHidden = true
        editPDFOptions.isHidden = true
        interactiveArea.layer.borderColor = UIColor.black.cgColor
        interactiveArea.layer.borderWidth = 1
        interactiveArea.isHidden = true
        scoreView.isHidden = !docIsExam
        
    }

    
    
    
    
    
    // MARK:- OBJECT C
    
//    @objc func handlePencilDrag(using recognizer: UIPanGestureRecognizer) {
//        print("handlePencilDrag")
//        let location = recognizer.location(in: view)
//        print(location)
//
//        freehand = !freehand
//        activateDrawView(type: "Pen", active: freehand)
//    }
    
    
    @objc func documentSaved() {
        print("documentSaved")
        
        DispatchQueue.main.async {
            self.saveIndicator.isHidden = true
        }
    }
    
    @objc private func handlePageChange(notification: Notification) {
        if (pdfView.currentPage?.pageRef?.pageNumber) != nil {
            isCurrentPageBookmarked()
        }
    }
    
    @objc func handleSettingsPopupClosing(notification: Notification) {
        let oldTime = pdfViewManager.saveTime!
        let settingsVC = notification.object as! AnnotationSettingsViewController
        annotationSettings = settingsVC.annotationSettings
        
        readingRuler.layer.borderWidth = CGFloat(annotationSettings[17])
        readingRuler.layer.borderColor = UIColor.black.withAlphaComponent(CGFloat(annotationSettings[18])/100).cgColor
        
        updateSettings(oldTime: oldTime)
        
        kvStorage.set(annotationSettings, forKey: "annotationSettings")
        kvStorage.synchronize()
        
        if settingsVC.saveNow {
            saveDocument()
        }
        
        if settingsVC.grade.add {
            dataManager.addOrUpdateGradeFile(file: currentFile, type: settingsVC.grade.type, show: settingsVC.grade.show)
        }

        if pdfViewManager.action == .pen {
            if annotationSettings[15] == 0 {
                drawView.spline = true
            } else {
                drawView.spline = false
            }
        }

        if pdfViewManager.action == .highlight {
            if annotationSettings[14] == 0 {
                drawView.spline = true
            } else {
                drawView.spline = false
            }
        }
        
        if pdfViewManager.action == .erase {
            drawView.spline = false
        }


    }
    
    @objc func handleNotesClosing(notification: Notification) {
        let vc = notification.object as! NotesViewController
        annotationSettings = vc.annotationSettings
        pdfViewManager.handleNotesClosing(vc: vc)
    }
    
    @objc func handleScoreClosing(notification: Notification) {
        let vc = notification.object as! ScoreViewController

        if vc.selectedExam != nil {
            selectedExam = vc.selectedExam!
            examLabel.text = selectedExam!.course

            selectedExam!.path = path
            dataManager.saveCoreData()
            dataManager.loadCoreData()
            scoreCV.reloadData()
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
            
            pdfViewManager.annotationsAltered?.append((annotation: highlight, action: .highlight, page: page))
            
            pdfViewManager.changesMade = true
        })
    }
    
    @objc func openBookmark(notification: Notification) {
        print("openBookmark - PDFview")
        let vc = notification.object as! BookmarksGridPDFViewController
        let selectedBookmark = vc.selectedBookmark
        
        if selectedBookmark != nil {
            let page = pdfView.document?.page(at: selectedBookmark!-1)
            pdfView.go(to: page!)
        }
        
    }

    @objc func postNotification() {
        DispatchQueue.main.async {
            print("postNotification")
            self.progressMonitor.isHidden = false
            self.view.addSubview(self.progressMonitor)
            self.view.bringSubview(toFront: self.progressMonitor)
            self.progressMonitor.launchMonitor(displayText: nil)
        }
    }
    
    @objc func saveDocument() {
        print("saveDocument")
        
        pdfViewManager.action = .save
        
        if pdfViewManager.changesMade {
            deactivateDrawing()
            pdfViewManager.saving = true
            saveIndicator.isHidden = false
            self.view.bringSubview(toFront: saveIndicator)
            removeSearchResults()
            
            self.view.bringSubview(toFront: progressMonitor)
            self.progressMonitor.isHidden = false
            dataManager.savePDF(file: currentFile, document: document)
            dataManager.updateNotes(file: currentFile, text: textNotes.text)
            pdfViewManager.changesMade = false
            
        } else {
            print("No changes made, not saving")
        }
    }
    
    @objc func sendNotification(text: String) {
        
        print("sendNotification - VC")
        self.progressMonitor.isHidden = false
//        self.view.addSubview(self.progressMonitor) //IS THIS NEEDED?
        self.view.bringSubview(toFront: self.progressMonitor)
        self.progressMonitor.launchMonitor(displayText: text)
        
////        self.view.addSubview(self.progressMonitor)
////        self.view.bringSubview(toFront: self.progressMonitor)
//        self.progressMonitor.isHidden = false
//        self.progressMonitor.bringSubview(toFront: self.view)
//        self.progressMonitor.launchMonitor(displayText: text)
    }
    
    @objc func setAuthor() {
        if let author = pdfView.currentSelection?.string {
            pdfViewManager.setJournal(author: author)
        }
    }
    
    @objc func setJournal() {
        if let journal = pdfView.currentSelection?.string {
            pdfViewManager.setJournal(journal: journal)
        }
    }
    
    @objc func speakText() {
        print("speakText()")
        
        audioView.isHidden = false
        self.view.bringSubview(toFront: audioView)
        playing = true
        
        playButton.setImage(UIImage(named: "pause-button-filled.png"), for: .normal)
        
        speechText = pdfView.currentSelection?.string
        
        let speechUtterance = AVSpeechUtterance(string: speechText!)
        speechUtterance.voice = AVSpeechSynthesisVoice(language: pdfViewManager.voices[annotationSettings[20]].code)
        
        speechSynthesizer.speak(speechUtterance)
    }
    
    @objc func touchedRuler(gestureRecognizer: UITapGestureRecognizer) {
        
        if gestureRecognizer.state == UIGestureRecognizerState.recognized
        {
            let point = gestureRecognizer.location(in: gestureRecognizer.view)
            if pdfViewManager.action == .moveRuler {
                if pointOnRulerBox == "withinBounds" {
                    pdfViewManager.action = .none
                    topLeftIcon.isHidden = true
                    topRightIcon.isHidden = true
                    bottomLeftIcon.isHidden = true
                    bottomRightIcon.isHidden = true
                    centerIcon.isHidden = true
                    readingRuler.layer.borderWidth = CGFloat(annotationSettings[17])
                    readingRuler.layer.borderColor = UIColor.black.withAlphaComponent(CGFloat(annotationSettings[18])/100).cgColor
                }
            } else {
                topLeftIcon.isHidden = false
                topRightIcon.isHidden = false
                bottomLeftIcon.isHidden = false
                bottomRightIcon.isHidden = false
                centerIcon.isHidden = false
                readingRuler.layer.borderColor = UIColor.black.cgColor
                readingRuler.layer.borderWidth = 0.25
            }
            pointOnRulerBox = pointOnRuler(bounds: self.readingRuler.bounds, point: point)
            
        }
    }
    
    @objc func widgetTapped(notification: Notification) {
        
        if let tmp = notification.userInfo?["PDFAnnotationHit"] as? PDFAnnotation {
            if tmp.type != "Widget" {
                currentAnnotation = tmp
                editPDFOptions.isHidden = false
                if editPDFOptions.frame.minX < 0 {
                    moveViewRight(view: editPDFOptions, offset: 0)
                }
            }
        }
    }


    
    
    
    
    
    // MARK: Functions
    
    func activateDrawView() {
        print("activateDrawView()")
        resetAllButtonsToDefaultState()
        
        //MAYBE FOR ALL ANNOTATIONS THROUGHOUT THE DOCUMENT?
        guard let page = pdfView.currentPage else {return}
        for annotation in page.annotations {
            if annotation.widgetFieldType == PDFAnnotationWidgetSubtype.text {
                annotation.backgroundColor = UIColor.clear
            }
        }
        
        enableScroll(state: false)
        
        switch pdfViewManager.action {
        case .none:
            enableScroll(state: true)
        case .pen:
            
            if annotationSettings[15] == 0 {
                drawView.spline = true
            } else {
                drawView.spline = false
            }
            penIcon.image = #imageLiteral(resourceName: "Pen-filled")
            penIcon.tintColor = UIColor.red
            
            drawView.pdfView = pdfView
            drawView.frame = pdfView.frame
            drawView.isHidden = false
            self.view.bringSubview(toFront: drawView)
            drawView.drawColor = penColor
            drawView.thickness = penThickness * getScale()

        case .highlight:
            
            if annotationSettings[14] == 0 {
                drawView.spline = true
            } else {
                drawView.spline = false
            }
            
            hightlightIcon.image = #imageLiteral(resourceName: "Marker-filled")
            hightlightIcon.tintColor = UIColor.red
            
            drawView.frame = pdfView.frame
            drawView.isHidden = false
            self.view.bringSubview(toFront: drawView)
            drawView.drawColor = highlighterColor
            drawView.thickness = highlighterThickness * getScale()
            
        default:
            print("Default 201")
        }
        
        
    }
    
    func bookmarksBeforeOrAfter() {
        let currentPage = pdfView.currentPage?.pageRef?.pageNumber
        let next = bookmarks.page?.filter({$0 > currentPage!})
        if next?.count != 0 {
            nextBookmark.isHidden = false
        } else {
            nextBookmark.isHidden = true
        }
        let prev = bookmarks.page?.filter({$0 < currentPage!})
        if prev?.count != 0 {
            prevBookmark.isHidden = false
        } else {
            prevBookmark.isHidden = true
        }
        
    }
    
    func bookmarksExists() -> Bool {
        if let currentBookmark = dataManager.getBookmark(file: currentFile) {
            let pages = currentBookmark.page!.count
            
            if pages > 0 {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    func configureUI() {
        
        if annotationSettings[19] <= 0 {
            pdfView.autoScales = true
            annotationSettings[19] = Int(100*pdfView.scaleFactor)
        } else {
            pdfView.scaleFactor = CGFloat(annotationSettings[19])/100
        }
        pdfView.displayMode = .singlePageContinuous
        pdfView.backgroundColor = UIColor.clear
        textNotes.text = pdfViewManager.notes
        
        audioView.layer.cornerRadius = 8
        audioView.layer.borderWidth = 1
        audioView.layer.borderColor = UIColor.black.cgColor

        selectedOptionsView.layer.cornerRadius = 8
        selectedOptionsView.layer.borderWidth = 1
        selectedOptionsView.layer.borderColor = UIColor.black.cgColor

        pageOptionsView.layer.cornerRadius = 16
        pageOptionsView.layer.borderWidth = 1
        pageOptionsView.layer.borderColor = UIColor.black.cgColor
        
        // SCORE VIEW
        scoreBGView.backgroundColor = UIColor(white: 0.5, alpha: 0.5)
        scoreBGView.layer.cornerRadius = 16
        scoreBGView.layer.borderWidth = 1
        scoreBGView.layer.borderColor = UIColor.black.cgColor

        let layoutScoreCV: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layoutScoreCV.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layoutScoreCV.itemSize = CGSize(width: scoreCV.bounds.width/10, height: scoreCV.bounds.height)
        layoutScoreCV.minimumInteritemSpacing = 0
        layoutScoreCV.scrollDirection = .horizontal
        scoreCV.collectionViewLayout = layoutScoreCV
        scoreCV.backgroundColor = UIColor.clear
        scoreCV.tag = 0
        examLabel.text = selectedExam?.course ?? "No exam selected"
        scoreValueStepper.layer.cornerRadius = 8

        studentName.text = student?.name ?? "No name"
        if docIsExam {
            totalScore.text = "\(student!.score!.joined().reduce(0, +))" + "/" + "\(selectedExam!.maxScore)"
        }
        
        setupThumbnailView()
        setupNotifications()
        setupPencilInteractions()
        setupBookmarkLabels()
        setupNoteView()
        isCurrentPageBookmarked()
        
        filenameLabel.text = currentFile.filename
        self.view.bringSubview(toFront: filenameLabel)
    }
    
    func deactivateDrawing() {
        print("deactivateDrawing")
        
        drawView.isHidden = true
//        self.view.bringSubview(toFront: pdfView)
//        self.bookmarkView.bringSubview(toFront: bookmarkView)
//        self.view.bringSubview(toFront: filenameLabel)
//        self.view.bringSubview(toFront: bookmarkView)
//        pdfViewManager.action = .none
        pdfViewManager.touchState = .inactive
        enableScroll(state: true)
        resetAllButtonsToDefaultState()
    }
    
    func enableScroll(state: Bool) {
        for subview in self.view.subviews {
            if let item = subview as? UIScrollView
            {
                item.isScrollEnabled = state
            }
        }
        pdfView.isUserInteractionEnabled = state
        
    }
    
    func getScale() -> CGFloat {
        let bounds = self.pdfView.currentPage?.bounds(for: .trimBox)
        return (self.pdfView?.documentView?.frame.width)! / (bounds?.width)!
    }
    
    func initiateTimer() {
        print("initiateTimer")
        if pdfViewManager.saveTime > 0 {
            saveTimer = Timer.scheduledTimer(timeInterval: Double(pdfViewManager.saveTime*60), target: self, selector: #selector(saveDocument), userInfo: nil, repeats: true)
        } else {
            saveTimer = Timer.scheduledTimer(timeInterval: 3600, target: self, selector: #selector(saveDocument), userInfo: nil, repeats: true)
        }
    }
    
    func initiatePostTimer() {
        print("Post timer")
        
        deactivateDrawing()
        
        postTimer = Timer.scheduledTimer(timeInterval: Double(2), target: self, selector: #selector(saveDocument), userInfo: nil, repeats: true)
    }
    
    func isCurrentPageBookmarked() {
        
        bookmarkLabel.text = ""
        var found = false
        if let number = pdfView.currentPage?.pageRef?.pageNumber {
            if bookmarks.page?.first(where: {$0 == number}) != nil {
                if let index = bookmarks.page?.index(where: { $0 == number }) {
                    bookmarkLabel.text = bookmarks.label![index]
                }
                
                bookmarkButton.setImage(UIImage(named: "Bookmark-filled"), for: .normal)
                found = true
            }
        }
        if !found {
            bookmarkButton.setImage(UIImage(named: "Bookmark"), for: .normal)
        }
        bookmarksBeforeOrAfter()
    }
    
    func lineWidthForDrawing(context: CGContext?, touch: UITouch) -> CGFloat {
        
        var lineWidth = penThickness!
        
        if touch.force > 0 {
            print(touch.force)
            lineWidth = touch.force * forceSensitivity
        }
        
        return lineWidth
    }
    
    func moveBookmarksUp() {
        print("moveBookmarksUp")
        bookmarkDown = false
        UIView.animate(withDuration: 0.25, animations: {
            self.bookmarkView.frame.origin.y -= 28
        })
        hideOrShowBookmarksButton.setImage(UIImage(named: "down"), for: .normal)
    }
    
    func moveBookmarksDown() {
        print("moveBookmarksDown")
        bookmarkDown = true
        UIView.animate(withDuration: 0.25, animations: {
            self.bookmarkView.frame.origin.y += 28
        })
        hideOrShowBookmarksButton.setImage(UIImage(named: "up"), for: .normal)
    }
    
    func moveViewDown(view: UIView, offset: Int) {
        print("moveViewDown")
        
        self.view.bringSubview(toFront: view)
        UIView.animate(withDuration: 0.5, animations: {
            view.frame.origin.y += view.frame.height + CGFloat(offset)
        })
    }
    
    func moveViewLeft(view: UIView, offset: Int) {
        print("moveViewLeft")
        self.view.bringSubview(toFront: view)
        UIView.animate(withDuration: 0.5, animations: {
            view.frame.origin.x -= (view.frame.width + CGFloat(offset))
        })
    }
    
    func moveViewRight(view: UIView, offset: Int) {
        print("moveViewRight")
        self.view.bringSubview(toFront: view)
        UIView.animate(withDuration: 0.5, animations: {
            view.frame.origin.x += (view.frame.width + CGFloat(offset))
        })
    }
    
    func moveViewUp(view: UIView, offset: Int) {
        print("moveViewUp")
        
        if textNotes.text.count != textLength {
            pdfViewManager.changesMade = true
        }

//        self.view.bringSubview(toFront: view)
        UIView.animate(withDuration: 0.5, animations: {
            view.frame.origin.y -= (view.frame.height + CGFloat(offset))
        })
    }
    
    func postponeSave() {
        // ADD A 1 MIN DELAY HERE
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "bookmarsGridSegue") {
            let destination = segue.destination as! BookmarksGridPDFViewController
            destination.currentFile = currentFile
            destination.dataManager = dataManager
            destination.fileHandler = fileHandler
        }
        if (segue.identifier == "AnnotationSettingsSegue") {
            let destination = segue.destination as! AnnotationSettingsViewController
            destination.preferredContentSize = settingsBox
            destination.pdfViewManager = pdfViewManager
            destination.currentFile = currentFile
            destination.dataManager = dataManager
            destination.annotationSettings = annotationSettings
        }
        if (segue.identifier == "segueNotesPDFView") {
            let destination = segue.destination as! NotesViewController
            destination.localFile = currentFile
            destination.dataManager = dataManager
            destination.annotationSettings = annotationSettings
            destination.preferredContentSize = notesBox
        }
        if (segue.identifier == "ScoreSegue") {
            let destination = segue.destination as! ScoreViewController
            destination.dataManager = dataManager
            destination.hideExport = true
            if selectedExam != nil {
                destination.selectedExam = selectedExam
            }
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
    
    func pointOnRuler(bounds: CGRect, point: CGPoint) -> String? {
        var pointOnText: String? = nil
        
        if abs(bounds.minX - point.x) < precision {
            if abs(bounds.maxY - point.y) < 4*precision {
                pointOnText = "bottomLeft"
            } else if abs(bounds.minY - point.y) < 4*precision {
                pointOnText = "topLeft"
            }
            
        } else if abs(bounds.maxX - point.x) < 4*precision {
            if abs(bounds.maxY - point.y) < 4*precision {
                pointOnText = "bottomRight"
            } else if abs(bounds.minY - point.y) < 4*precision {
                pointOnText = "topRight"
            }
            
        } else if abs(bounds.minX + bounds.center.x - point.x) < 4*precision && abs(bounds.minY + bounds.center.y - point.y) < 4*precision {
            pointOnText = "center"
            
        } else if bounds.minX < point.x && bounds.maxX > point.x && bounds.minY < point.y && bounds.maxY > point.y {
            pointOnText = "withinBounds"
        }
        
        return pointOnText
    }
    
    func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
        if pdfViewManager.action == .none {
            switch pdfViewManager.prevAction {
            case .pen:
                pdfViewManager.action = .pen
                activateDrawView()
            case .highlight:
                pdfViewManager.action = .highlight
                activateDrawView()
            case .erase:
                pdfViewManager.action = .erase
            default:
                print("Default 101")
            }
        } else {
            drawView.isHidden = true
//            self.view.bringSubview(toFront: pdfView)
            pdfViewManager.action = .none
            enableScroll(state: true)
            resetAllButtonsToDefaultState()
        }
    }
    
    func resetAllButtonsToDefaultState() {
        hightlightIcon.image = #imageLiteral(resourceName: "Marker")
        hightlightIcon.tintColor = UIColor.black
        eraserIcon.image = #imageLiteral(resourceName: "Erase")
        eraserIcon.tintColor = UIColor.black
        
        if selectButton.image != #imageLiteral(resourceName: "select") {
            moveViewUp(view: selectedOptionsView, offset: 10)
        }
        selectButton.image = #imageLiteral(resourceName: "select")
        
        selectButton.tintColor = UIColor.black
        addTextButton.image = #imageLiteral(resourceName: "AddText.png")
        addTextButton.tintColor = UIColor.black
        penIcon.image = #imageLiteral(resourceName: "Pen")
        penIcon.tintColor = UIColor.black
    }
    
    func recordAndRecognizeSpeech() {
        
        guard let node = audioEngine?.inputNode else {return}
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {buffer, _ in self.request.append(buffer)}
        audioEngine?.prepare()
        do {
            try audioEngine?.start()
        } catch {
            return print(error)
        }
        
        guard let myRecognizer = SFSpeechRecognizer() else {
            return
        }
        if !myRecognizer.isAvailable {
            return
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: {result, error in if let result = result {
            print(result.bestTranscription.formattedString)
        } else if let error = error {
            print(error)
            }
            
        })
        
    }
    
    func setupNoteView() {
        noteView.layer.cornerRadius = 16
        noteView.layer.borderWidth = 1
        noteView.layer.borderColor = UIColor.black.cgColor
        
        let navigationHeight = UIApplication.shared.statusBarFrame.size.height + (self.navigationController?.navigationBar.frame.height ?? 0.0)

        if pdfViewManager.notesDown {
            noteView.frame = CGRect(x: noteView.frame.minX, y: navigationHeight-noteView.layer.cornerRadius, width: noteView.frame.width, height: noteView.frame.height)
                takeNotesButton.image = #imageLiteral(resourceName: "takeNoteFilled")
                takeNotesButton.tintColor = UIColor.red

        } else {
            noteView.frame = CGRect(x: noteView.frame.minX, y: navigationHeight-noteView.frame.height-noteView.layer.cornerRadius, width: noteView.frame.width, height: noteView.frame.height)
            takeNotesButton.image = #imageLiteral(resourceName: "takeNote")
            takeNotesButton.tintColor = UIColor.black
        }

    }
    
    func setupThumbnailView() {
        print("setupThumbnailView")
        
        if UIApplication.shared.statusBarOrientation.isLandscape {
            
            if self.view.bounds.maxX > self.view.bounds.maxY {
                print("L1")
                pdfThumbnailView = PDFThumbnailView(frame: CGRect(x: self.view.bounds.maxX, y: 100, width: thumbnailPanelSize, height: self.view.bounds.size.height - 200))
            } else {
                print("L2")
                pdfThumbnailView = PDFThumbnailView(frame: CGRect(x: self.view.bounds.maxY, y: 100, width: thumbnailPanelSize, height: self.view.bounds.size.width - 200))
            }
        } else {
            
            if self.view.bounds.maxX < self.view.bounds.maxY {
                print("P1")
                pdfThumbnailView = PDFThumbnailView(frame: CGRect(x: self.view.bounds.maxX, y: 100, width: thumbnailPanelSize, height: self.view.bounds.size.height - 200))
            } else {
                print("P2") //HAMNAR HÄR FELAKTIGT
                pdfThumbnailView = PDFThumbnailView(frame: CGRect(x: self.view.bounds.maxY, y: 100, width: thumbnailPanelSize, height: self.view.bounds.size.width - 200))
            }
        }
        
        pdfThumbnailView.layoutMode = .vertical
        if document.pageCount > 300 {
            pdfThumbnailView.thumbnailSize = CGSize(width: 40.0, height: 40.0)
        } else {
            pdfThumbnailView.thumbnailSize = CGSize(width: 50.0, height: 50.0)
        }
        pdfThumbnailView.pdfView = pdfView
        pdfThumbnailView.backgroundColor = sidebarBackgroundColor
        pdfThumbnailView.alpha = 0.9
        self.view.addSubview(pdfThumbnailView)
        self.view.bringSubview(toFront: pdfThumbnailView)
        pdfThumbnailView.isHidden = true
    }
    
    func searchResultsBeforeOrAfter() {
        let currentPage = pdfView.currentPage?.pageRef?.pageNumber
        let commingSearchResults = searchPages.filter{$0 > currentPage!}
        if commingSearchResults.count != 0 {
            nextSearchResultButton.alpha = 1
        } else {
            nextSearchResultButton.alpha = 0.25
        }
        let pastSearchResults = searchPages.filter{$0 < currentPage!}
        print(pastSearchResults)
        if pastSearchResults.count != 0 {
            prevSearchResultButton.alpha = 1
        } else {
            prevSearchResultButton.alpha = 0.25
        }
    }
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleSettingsPopupClosing), name: Notification.Name.settingsHighlighter, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handlePageChange(notification:)), name: Notification.Name.PDFViewPageChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(widgetTapped(notification:)), name: Notification.Name.PDFViewAnnotationHit, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.postNotification), name: Notification.Name.postNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(documentSaved), name: Notification.Name.saveFinished, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.openBookmark), name: Notification.Name.openPDFAtBookmarkPDFView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotesClosing), name: Notification.Name.closingNotes, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleScoreClosing), name: Notification.Name.settingsScore, object: nil)
    }
    
    func setupBookmarkLabels() {
        print("setupBookmarkLabels")
        
        if bookmarks.label == nil {
            bookmarks.label = [""]
        }
        
        for i in 0..<bookmarks.page!.count {
            if bookmarks.label!.count < i+1 {
                bookmarks.label?.append("")
            }
        }
        
    }

    func setupPencilInteractions() {
        let interaction = UIPencilInteraction()
        interaction.delegate = self
        view.addInteraction(interaction)
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
        
        pdfViewManager.changesMade = true
        
    }

    func updateSettings(oldTime: Int?) {
        
        let colors = pdfViewManager.colors
        highlighterColor = UIColor(red: colors[annotationSettings[0]][0], green: colors[annotationSettings[0]][1], blue: colors[annotationSettings[0]][2], alpha: CGFloat(annotationSettings[4])/100)
        highlighterThickness = highlightScale*CGFloat(annotationSettings[1])
        
        penColor = UIColor(red: colors[annotationSettings[2]][0], green: colors[annotationSettings[2]][1], blue: colors[annotationSettings[2]][2], alpha: 1)
        penThickness = penScale*CGFloat(annotationSettings[3])
        
        pdfViewManager.saveTime = annotationSettings[5]
        
        if oldTime != nil {
            if oldTime != pdfViewManager.saveTime! {
                saveTimer.invalidate()
                if pdfViewManager.saveTime > 0 {
                    saveTimer = Timer.scheduledTimer(timeInterval: Double(pdfViewManager.saveTime!*60), target: self, selector: #selector(saveDocument), userInfo: nil, repeats: true)
                }
            }
        }
        
        if pdfViewManager.action == .highlight {
            drawView.thickness = highlighterThickness * getScale()
            drawView.drawColor = highlighterColor
        }
        if pdfViewManager.action == .pen {
            print(penThickness)
            drawView.thickness = penThickness * getScale()
            drawView.drawColor = penColor
        }
        
        if annotationSettings[7] == 1 {
            readingRuler.isHidden = false
        } else {
            readingRuler.isHidden = true
        }
        
    }
    
    func undoOrRedoActions() {
        if pdfViewManager.annotationsAltered?.isEmpty == true {
            undoIcon.isEnabled = false
        } else {
            undoIcon.isEnabled = true
        }
    }
    

    
    
    // MARK: - Search bar
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        pdfViewManager.searching = .on
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        pdfViewManager.searching = .off
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        matches = []
        pdfViewManager.searching = .off
        removeSearchResults()
        searchField.text = ""
//        searchField.isHidden = true
//        nextSearchResultButton.isEnabled = false
//        prevSearchResultButton.isEnabled = false
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        pdfViewManager.searching = .off
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if pdfViewManager.searching == .on {

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
        print("removeSearchResults")
        
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
//        nextSearchResultButton.isEnabled = false
//        prevSearchResultButton.isEnabled = false
    }

    
    
    
    // MARK: - Table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let tmp = selectedExam?.subProblems {
            return tmp[tableView.tag]
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let subLabels = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p"]
        let cell = tableView.dequeueReusableCell(withIdentifier: "subScoreCell") as! SubScoreCell
        
        if student!.score![tableView.tag].count < indexPath.row+1 {
            student?.score![tableView.tag].append(Double(0))
        }
        cell.scoreLabel.text = subLabels[indexPath.row] + ": " + "\(student!.score![tableView.tag][indexPath.row])"

        if selectedStudent.main == tableView.tag && selectedStudent.sub == indexPath.row && initialLoad != true {
            cell.scoreLabel.backgroundColor = UIColor.lightGray
        } else {
            cell.scoreLabel.backgroundColor = UIColor.white
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        initialLoad = false
        selectedStudent.main = tableView.tag
        selectedStudent.sub = indexPath.row
        selectedStudent.value = Double(student!.score![tableView.tag][indexPath.row])
        scoreValueStepper.value = selectedStudent.value
        scoreCV.reloadData()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 25
    }
    
    
    
    // MARK: - Collection view
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.editColorCV {
            return pdfViewManager.colors.count
        } else {
            return Int(selectedExam?.problems ?? 0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.editColorCV {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "colorCell", for: indexPath)
            
            cell.sizeToFit()
            var borderColor = UIColor.black.cgColor
            
            let colors = pdfViewManager.colors
            if colors[indexPath.row][0] == 0 && colors[indexPath.row][1] == 0 && colors[indexPath.row][2] == 0 {
                borderColor = UIColor.white.cgColor
            }
            cell.layer.borderWidth = 0.25
            cell.layer.borderColor = borderColor
            cell.layer.cornerRadius = cell.bounds.width/2
            
            cell.backgroundColor = UIColor(red: colors[indexPath.row][0], green: colors[indexPath.row][1], blue: colors[indexPath.row][2], alpha: 1)
            return cell
            
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "scoreCell", for: indexPath) as! ScoreCellSettings
            cell.scoreNumber.text = "Task: " + "\(indexPath.row + 1)"
            cell.subScoreTV.tag = indexPath.row
            cell.backgroundColor = UIColor.clear
            cell.subScoreTV.remembersLastFocusedIndexPath = true
            cell.subScoreTV.reloadData() //TRY REPLACING IN THE FUTURE WITH BELOW
//            cell.subScoreTV.reloadRows(at: [IndexPath(row: selectedScore.sub, section: 0)], with: .none)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.editColorCV {
            if currentAnnotation.type != "Widget" {
                let color = currentAnnotation.color.rgba
                currentAnnotation.color = UIColor(red: pdfViewManager.colors[indexPath.row][0], green: pdfViewManager.colors[indexPath.row][1], blue: pdfViewManager.colors[indexPath.row][2], alpha: color.alpha)
                pdfView.annotationsChanged(on: currentAnnotation.page!)
                pdfViewManager.changesMade = true
            }
        } else {
            selectedStudent.main = indexPath.row
        }
    }
    
    
    
    
    // MARK: - Touches
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesBegan")
        print(pdfViewManager.action)
        
        pdfViewManager.numberOfTouches = (event?.allTouches!.count)!
        if pdfViewManager.numberOfTouches == 1 {
            
            guard let touch = touches.first else { return }
            point = touch.location(in: pdfView)
            guard let page = pdfView.page(for: point, nearest: true) else {return}
            
            switch pdfViewManager.action {
                
            case .addText:
                point = pdfView.convert(point, to: page)
                tapCoordinates = [point.x]
                tapCoordinates.append(point.y)

                for annotation in page.annotations {
                    if annotation.widgetFieldType == PDFAnnotationWidgetSubtype.text {
                        let tmp = pointOnTextAnnotation(bounds: annotation.bounds, point: point)
                        if tmp != nil {
                            pointOnTextbox = tmp!
                            currentAnnotation = annotation
                            pdfViewManager.action = .moveText
                            addTextButton.image = #imageLiteral(resourceName: "Move.png")
                        }
                    }
                }

                point = touch.location(in: self.view!)
                tapCoordinates.append(point.x)
                tapCoordinates.append(point.y)
                
            case .erase:
                point = touch.location(in: pdfView)
                point = pdfView.convert(point, to: page)
                if let tmp = page.annotation(at: point) {
                    pdfView.page(for: point, nearest: true)?.removeAnnotation(tmp)
                    pdfViewManager.changesMade = true
//                    let number = page.pageRef?.pageNumber
                    pdfViewManager.annotationsAltered?.append((annotation: tmp, action: .erase, page: page))
                    undoOrRedoActions()
                }
                
            case .moveAnnotation:
                point = touch.location(in: self.view!)
                if interactiveArea.frame.contains(point) {
                    point = touch.location(in: pdfView)
                    point = pdfView.convert(point, to: page)
                    selectButton.image = #imageLiteral(resourceName: "Move")
                    moveDeltaX = [point.x]
                    moveDeltaY = [point.y]
                    point = touch.location(in: self.view!)
                    moveDeltaX.append(point.x)
                    moveDeltaY.append(point.y)
                } else {
                    pdfViewManager.action = .none
                    interactiveArea.isHidden = true
                    selectButton.image = #imageLiteral(resourceName: "select")
                    moveViewUp(view: selectedOptionsView, offset: 10)
                    pdfView.isUserInteractionEnabled = true
                }
                
            case .moveRuler:
                point = touch.location(in: pdfView)
                point = pdfView.convert(point, to: readingRuler)
                
                pointOnRulerBox = pointOnRuler(bounds: self.readingRuler.bounds, point: point)
                
            case .selectAnnotation:
                point = pdfView.convert(point, to: page)
                tapCoordinates = [point.x]
                tapCoordinates.append(point.y)
                point = touch.location(in: self.view!)
                tapCoordinates.append(point.x)
                tapCoordinates.append(point.y)
                
                interactiveArea.isHidden = false
                interactiveArea.backgroundColor = UIColor.clear
                interactiveArea.layer.borderWidth = 1
                interactiveArea.layer.borderColor = UIColor.lightGray.cgColor
                
            default:
                point = pdfView.convert(point, to: page)
                
                for annotation in page.annotations {
                    if annotation.widgetFieldType == PDFAnnotationWidgetSubtype.text {
                        let tmp = pointOnTextAnnotation(bounds: annotation.bounds, point: point)
                        if tmp != nil {
                            pointOnTextbox = tmp!
                            currentAnnotation = annotation
                            pdfViewManager.action = .moveText
                            addTextButton.image = #imageLiteral(resourceName: "Move.png")
                        }
                    }
                }
            }
        } else {
            print(pdfViewManager.numberOfTouches)
            enableScroll(state: true)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {

        if pdfViewManager.numberOfTouches == 1 {
            guard let touch = touches.first else { return }
            point = touch.location(in: pdfView)
            guard let page = pdfView.page(for: point, nearest: true) else {return}
            point = pdfView.convert(point, to: page)
            
            switch pdfViewManager.action {
            
            case .addText:
                point = touch.location(in: self.view!)
                
                interactiveArea.isHidden = false
                interactiveArea.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
                interactiveArea.layer.borderWidth = 1
                interactiveArea.layer.borderColor = UIColor.black.cgColor
                
                var x = point.x
                if x > tapCoordinates[2] {
                    x = tapCoordinates[2]
                }
                var y = point.y
                if y > tapCoordinates[3] {
                    y = tapCoordinates[3]
                }
                
                let width = abs(point.x - tapCoordinates[2])
                let height = abs(point.y - tapCoordinates[3])
                
                interactiveArea.frame = CGRect(x: x, y: y, width: width, height: height)
           
            case .erase:
                point = touch.location(in: pdfView)
                point = pdfView.convert(point, to: page)
                if let tmp = page.annotation(at: point) {
                    pdfView.page(for: point, nearest: true)?.removeAnnotation(tmp)
                    pdfViewManager.changesMade = true
//                    let number = page.pageRef?.pageNumber
                    pdfViewManager.annotationsAltered?.append((annotation: tmp, action: .erase, page: page))
                    undoOrRedoActions()
                }
                
            case .moveAnnotation:
                var dx = point.x - moveDeltaX[0]
                var dy = point.y - moveDeltaY[0]
                
                for annotation in selectedAnnotations! {
                    annotation.bounds.origin.x += dx
                    annotation.bounds.origin.y += dy
                }
                
                moveDeltaX[0] = point.x
                moveDeltaY[0] = point.y
                
                point = touch.location(in: self.view!)
                
                dx = point.x - moveDeltaX[1]
                dy = point.y - moveDeltaY[1]
                
                interactiveArea.frame.origin.x += dx
                interactiveArea.frame.origin.y += dy
                
                moveDeltaX[1] = point.x
                moveDeltaY[1] = point.y
                
            case .moveRuler:
                point = touch.location(in: self.view!)
                let oldFrame = readingRuler.frame
                
                if pointOnRulerBox == "topRight" {
                    readingRuler.frame = CGRect(x: oldFrame.origin.x, y: point.y, width: abs(oldFrame.origin.x - point.x), height: abs(oldFrame.maxY - point.y))
                } else if pointOnRulerBox == "bottomRight" {
                    readingRuler.frame = CGRect(x: oldFrame.origin.x, y: oldFrame.origin.y, width: abs(oldFrame.origin.x - point.x), height: abs(oldFrame.minY-point.y))
                } else if pointOnRulerBox == "topLeft" {
                    readingRuler.frame = CGRect(x: point.x, y: point.y, width: abs(oldFrame.maxX - point.x), height: abs(oldFrame.maxY - point.y))
                } else if pointOnRulerBox == "bottomLeft" {
                    readingRuler.frame = CGRect(x: point.x, y: oldFrame.origin.y, width: abs(oldFrame.maxX - point.x), height: abs(oldFrame.minY - point.y))
                } else if pointOnRulerBox == "center" {
                    readingRuler.frame = CGRect(x: point.x - oldFrame.width/2, y: point.y - oldFrame.height/2, width: oldFrame.width, height: oldFrame.height)
                }
                
                
                if readingRuler.frame.width < precision*2 {
                    readingRuler.frame = CGRect(x: self.view.bounds.maxX/2-self.view.bounds.maxX/4, y: self.view.bounds.maxY/2-self.view.bounds.maxY/4, width: self.view.bounds.width/2, height: self.view.bounds.height/2)
                    pdfViewManager.action = .none
                }
                if readingRuler.frame.height < precision*2 {
                    readingRuler.frame = CGRect(x: self.view.bounds.maxX/2-self.view.bounds.maxX/4, y: self.view.bounds.maxY/2-self.view.bounds.maxY/4, width: self.view.bounds.width/2, height: self.view.bounds.height/2)
                    pdfViewManager.action = .none
                }
                
            case .moveText:
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
                
            case .selectAnnotation:
                point = touch.location(in: self.view!)
                
                var x = point.x
                if x > tapCoordinates[2] {
                    x = tapCoordinates[2]
                }
                var y = point.y
                if y > tapCoordinates[3] {
                    y = tapCoordinates[3]
                }
                
                let width = abs(point.x - tapCoordinates[2])
                let height = abs(point.y - tapCoordinates[3])
                
                interactiveArea.frame = CGRect(x: x, y: y, width: width, height: height)
                
            default:
                print("Default 1906")
            }
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesEnded")
        
        if pdfViewManager.numberOfTouches == 1 {
            guard let touch = touches.first else { return }
            point = touch.location(in: pdfView)
            guard let page = pdfView.page(for: point, nearest: true) else {return}
            
            page.annotations.filter { $0.widgetFieldType == PDFAnnotationWidgetSubtype.text }.forEach { $0.shouldDisplay = true }
            pointOnTextbox = "outside"
            
            switch pdfViewManager.action {
            case .addText:
                point = pdfView.convert(point, to: page)
                let pageBounds = page.bounds(for: .cropBox)
                
                tapCoordinates.append(point.x)
                tapCoordinates.append(point.y)
                
                var x = point.x
                if x > tapCoordinates[0] {
                    x = tapCoordinates[0]
                }
                var y = point.y
                if y > tapCoordinates[1] {
                    y = tapCoordinates[1]
                }
                
                var width = abs(point.x - tapCoordinates[0])
                var height = abs(point.y - tapCoordinates[1])
                
                if width < pageBounds.size.width*0.025 {
                    width = pageBounds.size.width*0.025
                }
                if height < pageBounds.size.height*0.025 {
                    height = pageBounds.size.height*0.025
                }
                
                let textFieldBounds = CGRect(x: x, y: y, width: width, height: height)
                let textField = PDFAnnotation(bounds: textFieldBounds, forType: PDFAnnotationSubtype(rawValue: PDFAnnotationSubtype.widget.rawValue), withProperties: nil)
                textField.widgetFieldType = PDFAnnotationWidgetSubtype(rawValue: PDFAnnotationWidgetSubtype.text.rawValue)
                textField.backgroundColor = UIColor.blue.withAlphaComponent(0.1)
                
                var font: String!
                if annotationSettings[12] == 0 {
                    if annotationSettings[13] == 0 {
                        font = "ArialMT"
                    } else if annotationSettings[13] == 1 {
                        font = "Arial-BoldMT"
                    } else {
                        font = "Arial-ItalicMT"
                    }
                } else if annotationSettings[12] == 1 {
                    if annotationSettings[13] == 0 {
                        font = "HelveticaNeue-Light"
                    } else if annotationSettings[13] == 1 {
                        font = "HelveticaNeue-Bold"
                    } else {
                        font = "HelveticaNeue-LightItalic"
                    }
                } else {
                    if annotationSettings[13] == 0 {
                        font = "TimesNewRomanPSMT"
                    } else if annotationSettings[13] == 1 {
                        font = "TimesNewRomanPS-BoldMT"
                    } else {
                        font = "TimesNewRomanPS-ItalicMT"
                    }
                }
                
                textField.font = UIFont(name: font, size: CGFloat(annotationSettings![6]))
                textField.isMultiline = true
                page.addAnnotation(textField)
                
                textFieldAdded()
                interactiveArea.isHidden = true
                
            case .erase:
                point = touch.location(in: pdfView)
                point = pdfView.convert(point, to: page)
                if let tmp = page.annotation(at: point) {
                    pdfView.page(for: point, nearest: true)?.removeAnnotation(tmp)
                    pdfViewManager.changesMade = true
//                    let number = page.pageRef?.pageNumber
                    pdfViewManager.annotationsAltered?.append((annotation: tmp, action: .erase, page: page))
                    undoOrRedoActions()
                }
                
            case .moveText:
                pdfViewManager.changesMade = true
                
            case .moveAnnotation:
                pdfViewManager.changesMade = true
                
            case .moveRuler:
                annotationSettings[8] = Int(readingRuler.frame.origin.x)
                annotationSettings[9] = Int(readingRuler.frame.origin.y)
                annotationSettings[10] = Int(readingRuler.frame.width)
                annotationSettings[11] = Int(readingRuler.frame.height)
                
                pdfViewManager.action = .none
                topLeftIcon.isHidden = true
                topRightIcon.isHidden = true
                bottomLeftIcon.isHidden = true
                bottomRightIcon.isHidden = true
                centerIcon.isHidden = true
                
                readingRuler.layer.borderWidth = CGFloat(annotationSettings[17])
                readingRuler.layer.borderColor = UIColor.black.withAlphaComponent(CGFloat(annotationSettings[18])/100).cgColor
                
            case .selectAnnotation:
                selectedAnnotations = []
                
                point = pdfView.convert(point, to: page)
                
                tapCoordinates.append(point.x)
                tapCoordinates.append(point.y)
                
                var x = point.x
                if x > tapCoordinates[0] {
                    x = tapCoordinates[0]
                }
                var y = point.y
                if y > tapCoordinates[1] {
                    y = tapCoordinates[1]
                }
                
                let width = abs(point.x - tapCoordinates[0])
                let height = abs(point.y - tapCoordinates[1])
                
                let bounds = CGRect(x: x, y: y, width: width, height: height)
                
                for annotation in page.annotations {
                    if bounds.contains(annotation.bounds) && annotation.type != "Highlight" {
                        if selectedAnnotations!.isEmpty {
                            selectedAnnotations = [annotation]
                        } else {
                            selectedAnnotations?.append(annotation)
                        }
                    }
                }
                
                if selectedAnnotations!.count > 0 {
                    pdfViewManager.action = .moveAnnotation
                    interactiveArea.backgroundColor = UIColor.lightGray.withAlphaComponent(0.1)
                } else {
                    interactiveArea.isHidden = true
                    interactiveArea.backgroundColor = UIColor.clear
                }
            default:
                print("Default 2062")
            }
        } else {
            enableScroll(state: false)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("Touches cancelled")
    }
    
    
    func speechRecognitionTaskFinishedReadingAudio(_: SFSpeechRecognitionTask) {
        print("Speech recognition off")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        playing = false
        playButton.setImage(UIImage(named: "play-button-circled-filled.png"), for: .normal)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.pdfThumbnailView.removeFromSuperview()
            self.interactiveArea.isHidden = true
            self.setupThumbnailView()
            self.setupNoteView()
            self.thumbnailIcon.image = #imageLiteral(resourceName: "Layers")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillDisappear(_ animated: Bool) {
        
        if playing {
            let image = UIImage(named: "play-button-circled-filled.png")
            playButton.setImage(image, for: .normal)
            
            audioView.isHidden = true
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        
        annotationSettings[19] = Int(100*pdfView.scaleFactor)
        
        dataManager.updateNotes(file: currentFile, text: textNotes.text)
        saveTimer.invalidate()
        if let tmp = pdfView.currentPage?.pageRef?.pageNumber {
            bookmarks.lastPageVisited = Int32(tmp)
        }
        
        NotificationCenter.default.post(name: Notification.Name.closingPDF, object: self)
    }

    override func prefersHomeIndicatorAutoHidden() -> Bool {
        return true
    }
    
    override var keyCommands: [UIKeyCommand]? {
        return [
            UIKeyCommand(input: "s", modifierFlags: .command, action: #selector(saveDocument), discoverabilityTitle: "Save"),
            UIKeyCommand(input: "n", modifierFlags: .command, action: #selector(takeNotesTapped), discoverabilityTitle: "Hide/show notes"),
            UIKeyCommand(input: "b", modifierFlags: .command, action: #selector(bookmarkTapped), discoverabilityTitle: "Bookmark page")
            
        ]
    }
    
}



extension PDFViewController: DrawingViewDelegate {
    
    func didEndDrawLine(bezierPath: UIBezierPath, page: PDFPage) {
        print("didEndDrawLine")
        
        let annotationPath = UIBezierPath(cgPath: bezierPath.cgPath)
        
        let border = PDFBorder()
        if pdfViewManager.action == .pen {
            border.lineWidth = penThickness
        } else if pdfViewManager.action == .highlight {
            border.lineWidth = highlighterThickness
        }
        
        let rect = CGRect(x:annotationPath.bounds.minX-border.lineWidth/2, y:annotationPath.bounds.minY-border.lineWidth/2, width:annotationPath.bounds.maxX-annotationPath.bounds.minX+border.lineWidth, height:annotationPath.bounds.maxY-annotationPath.bounds.minY+border.lineWidth)
        
        annotationPath.moveCenter(to: rect.center)
        
        let annotation = PDFAnnotation(bounds: rect, forType: .ink, withProperties: nil)
        
        if pdfViewManager.action == .pen {
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
        
        pdfViewManager.annotationsAltered?.append((annotation: annotation, action: pdfViewManager.action, page: page))
        
        pdfViewManager.changesMade = true
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

extension UIColor {
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return (red, green, blue, alpha)
    }
}

extension PDFAnnotation {
    
    func contains(point: CGPoint) -> Bool {
        
        var hitPath: CGPath?
        
        if let path = paths?.first {
            hitPath = path.cgPath.copy(strokingWithWidth: 10, lineCap: .round, lineJoin: .round, miterLimit: 0)
        }
        return hitPath?.contains(point) ?? false
    }
}

extension PDFPage {
    func annotationWithHitTest(at: CGPoint) -> PDFAnnotation? {
        
        for annotation in annotations {
            if annotation.contains(point: at) {
                return annotation
            }
        }
        return nil
    }
}

extension PDFViewController: PDFDocumentDelegate {
    func classForPage() -> AnyClass {
        return PDFPage.self
    }
}

//extension UIViewController {
//    func hideKeyboardWhenTappedAround() {
//        let tap: UITapGestureRecognizer =     UITapGestureRecognizer(target: self, action:    #selector(UIViewController.dismissKeyboard))
//        tap.cancelsTouchesInView = false
//        view.addGestureRecognizer(tap)
//    }
//
//    @objc func dismissKeyboard() {
//        view.endEditing(true)
//    }
//}
