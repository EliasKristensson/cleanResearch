//
//  ViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-04-04.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//


import UIKit
import CloudKit
import PDFKit
import MobileCoreServices
import Foundation
import CoreData
import QuickLook

var mainVC: ViewController?

protocol ExpenseCellDelegate {
    func didTapPDF(url: URL)
}


class categoryCell: UICollectionViewCell {
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var number: UILabel!
    var favoriteButton: UIButton!
}

class SectionHeaderView: UICollectionReusableView {
    @IBOutlet weak var mainHeaderTitle: UILabel!
    @IBOutlet weak var subHeaderTitle: UILabel!
}

class ListCell: UITableViewCell {
    @IBOutlet weak var listLabel: UILabel!
    @IBOutlet weak var listNumberOfItems: UILabel!
}

class FilesCell: UICollectionViewCell {
    
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var favoriteIcon: UIButton!
//    @IBOutlet weak var hiddenFilename: UILabel!
    @IBOutlet weak var deleteIcon: UIImageView!
    @IBOutlet weak var fileOffline: UIImageView!
    
}

class EconomyCell: UITableViewCell {
    
    var expenseItem: Expense!
    var delegate: ExpenseCellDelegate?
    
    @IBOutlet weak var expenseAmount: UILabel!
    @IBOutlet weak var overheadAmount: UILabel!
    @IBOutlet weak var referenceString: UILabel!
    @IBOutlet weak var commentString: UILabel!
    @IBOutlet weak var pdfButton: UIButton!
    
    
    @IBAction func pdfButtonTapped(_ sender: Any) {
        if expenseItem.pdfURL != nil {
            delegate?.didTapPDF(url: expenseItem.pdfURL!)
        }
    }
    
    func setExpense(expense: Expense) {
        expenseItem = expense
        expenseAmount.text = "\(expenseItem.amount)"
        overheadAmount.text = "\(expenseItem.overhead)"
        referenceString.text = "\(expenseItem.reference!)"
        commentString.text = "\(expenseItem.comment!)"
        if expenseItem.pdfURL == nil {
            pdfButton.alpha = 0.5
        } else {
            pdfButton.alpha = 1
        }
        
    }
}




//UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UIPopoverPresentationControllerDelegate, UIDocumentMenuDelegate, UIDocumentPickerDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate, UICollectionViewDragDelegate, UICollectionViewDropDelegate, UITableViewDropDelegate


class ViewController: UIViewController, UIPopoverPresentationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDataSource, UITableViewDelegate, UICollectionViewDragDelegate, UICollectionViewDropDelegate, UITableViewDropDelegate, QLPreviewControllerDataSource {
    
    
    

    // MARK: - Variables
    var appDelegate: AppDelegate!
//    var document: MyDocument?
    let container = CKContainer.default
    var privateDatabase: CKDatabase?
    var currentRecord: CKRecord?
    var recordZone: CKRecordZone?
    var recordID: CKRecordID?
    let previewController = QLPreviewController()
    
    // MARK: - Core data
    var context: NSManagedObjectContext!
    var publicationsCD: [Publication] = []
    var authorsCD: [Author] = []
    var journalsCD: [Journal] = []
    var publicationGroupsCD: [PublicationGroup] = []
    var manuscriptsCD: [Manuscript] = []
    var projectCD: [Project] = []
    var expensesCD: [Expense] = []
    
    var currentPublication: Publication!
    var currentIndexPath: IndexPath = IndexPath(row: 0, section: 0)

    
    // MARK: - iCloud variables
    var documentURL: URL!
    var documentPage = 0
    var iCloudURL: URL!
    var kvStorage: NSUbiquitousKeyValueStore!
    var publicationsURL: URL!
    var economyURL: URL!
    var manuscriptsURL: URL!
    var proposalsURL: URL!
    var presentationsURL: URL!
    var supervisionsURL: URL!
    var teachingURL: URL!
    var miscellaneousURL: URL!
    var patentsURL: URL!
    var metaDataQuery: NSMetadataQuery?
    var metaData: NSMetadataQuery!
    var publicationsIC: [PublicationFile] = []
    var projectsIC: [ProjectFile] = []
    var icloudAvailable: Bool? = nil
    
    // MARK: - UI variables
    let documentInteractionController = UIDocumentInteractionController()
    let categories: [String] = ["Publications", "Economy", "Manuscripts", "Presentations", "Proposals", "Supervision", "Teaching", "Patents", "Courses", "Miscellaneous"]
    var settingsCollectionViewBox = CGSize(width: 250, height: 180)
    var currentTheme: Int = 0
    var editingFilesCV = false
    var currentSelectedFilename: String? = nil
    var selectedInvoice: String? = nil
    var currentExpense: Expense!
    
    var sortTableListBox = CGSize(width: 348, height: 28)
    var selectedCategoryNumber = 0

    var localFiles: [[LocalFile]] = [[]]
    var filesCV: [[LocalFile]] = [[]] //Place files to be displayed in collection view here (ONLY PUBLICATIONS!)
    var docCV: [DocCV] = []
    let sortSubtableStrings = ["Tag", "Author", "Journal", "Year", "Rank"] //Only for publications
    let sortCVStrings: [String] = ["Filename", "Date"]
    var selectedSubtableNumber = 0
    var selectedSortingNumber = 0
    var selectedSortingCVNumber = 0
    var selectedFile: [SelectedFile] = []
    var previewFile: LocalFile!
    var sortTableTitles: [String] = [""]
    var sectionTitles: [[String]] = [[""]]

    var yearsString: [String] = [""]
    
    var currentFilename: String = ""
    var dateFormatter = DateFormatter()
    
    var PDFdocument: PDFDocument!
    var PDFfilename: String!
    var annotationSettings: [Int] = [0, 0, 0, 0]
    
    var manuscriptSections = [""]
    var proposalsSections = [""]
    
    var downloadTimer: Timer!
    var filesDownloading: [DownloadingFile]!
    
    var textColor: UIColor!
    var backgroundColor: UIColor!
    var barColor: UIColor!
    
    // MARK: - Outlets
    @IBOutlet var mainView: UIView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var economyView: UIView!
    @IBOutlet weak var economyHeader: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var listTableView: UITableView!
    @IBOutlet weak var filesCollectionView: UICollectionView!
    @IBOutlet weak var selectedCategoryTitle: UILabel!
    @IBOutlet weak var categoriesCV: UICollectionView!
    @IBOutlet weak var notesView: UIView!
    @IBOutlet weak var segmentedControllTablesOrNotes: UISegmentedControl!
    @IBOutlet weak var sortSTButton: UIButton!
    @IBOutlet weak var sortCVButton: UIButton!
    @IBOutlet weak var addNewGroupText: UIButton!
    @IBOutlet weak var editButton: UIButton!
    
    
    @IBOutlet weak var largeThumbnail: UIImageView!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var filenameString: UITextField!
    @IBOutlet weak var journalString: UITextField!
    @IBOutlet weak var notesString: UITextField!
    
    @IBOutlet weak var authorString: UITextField!
    @IBOutlet weak var yearString: UITextField!
    @IBOutlet weak var rankValue: UILabel!
    @IBOutlet weak var rankOutlet: UISlider!
    
    @IBOutlet weak var settingsButton: UIButton!
    
    @IBOutlet weak var amountReceivedString: UITextField!
    
    @IBOutlet weak var amountRemainingString: UITextField!
    
    @IBOutlet weak var currencyString: UILabel!
    @IBOutlet weak var expenseString: UITextField!
    @IBOutlet weak var overheadString: UITextField!
    @IBOutlet weak var referenceString: UITextField!
    @IBOutlet weak var commentString: UITextField!
    @IBOutlet weak var expensesTableView: UITableView!
    
    @IBOutlet weak var loadingString: UILabel!
    
    
    @IBAction func favoriteTapped(_ sender: Any) {
        let filename = filenameString.text
        var localFileIndex = Int()

        switch categories[selectedCategoryNumber] {
        case "Publications":

            let favoritesGroup = publicationGroupsCD.first(where: {$0.tag == "Favorites"})
            var localFileIndex = Int()

            for i in 0..<localFiles[0].count {
                if localFiles[0][i].filename == filename {
                    localFileIndex = i
                }
            }
            
            if localFiles[0][localFileIndex].favorite == "No" {
                favoriteButton.setImage(#imageLiteral(resourceName: "FavoriteOn"), for: .normal)
                localFiles[0][localFileIndex].favorite = "Yes"
                localFiles[0][localFileIndex].groups.append("Favorites")
                
                if let currentPublication = publicationsCD.first(where: {$0.filename == filename}) {
                    currentPublication.addToPublicationGroup(favoritesGroup!) // currentPublication exists
                    currentPublication.favorite = "Yes"
                    saveCoreData()
                    loadCoreData()

                } else {
                    addFileToCoreData(file: localFiles[0][localFileIndex])
                }
                
            } else {
                favoriteButton.setImage(#imageLiteral(resourceName: "FavoriteOff"), for: .normal)
                localFiles[0][localFileIndex].favorite = "No"
                let groups = localFiles[0][localFileIndex].groups
                let newGroups = groups.filter { $0 != "Favorites" }
                localFiles[0][localFileIndex].groups = newGroups //"FAVORITES" REMOVED

                if let currentPublication = publicationsCD.first(where: {$0.filename == filename}) {
                    currentPublication.removeFromPublicationGroup(favoritesGroup!)
                    currentPublication.favorite = "No"
                    saveCoreData()
                    loadCoreData()

                } else {
                    addFileToCoreData(file: localFiles[0][localFileIndex])
                }
            }
            
            updateIcloud(file: localFiles[0][localFileIndex])
            saveCoreData()
            loadCoreData()
            
            populateFilesCV()
            sortFiles()
            listTableView.reloadData()
            filesCollectionView.reloadData()
            
        default:
            print("Default 134")
        }
    }
    
    @IBAction func toggleTableNotes(_ sender: Any) {
        let selectedOption = segmentedControllTablesOrNotes.titleForSegment(at: segmentedControllTablesOrNotes.selectedSegmentIndex)
        switch selectedOption! {
        case "List":
            notesView.isHidden = true

        case "Notes":
            switch categories[selectedCategoryNumber] {
            case "Publications":
                notesView.isHidden = false
            default:
                notesView.isHidden = true
            }
            
        default:
            print("Default 140")
        }
    }
    
    @IBAction func rankSlider(_ sender: Any) {
        rankValue.text = "\(Int(rankOutlet.value))"
    }
    
    @IBAction func nextPDFPage(_ sender: Any) {
        
        let document = PDFDocument(url: documentURL)
        let pageCount = document?.pageCount
        let page: PDFPage!
        documentPage = documentPage + 1
        if documentPage >= pageCount! {
            documentPage = pageCount! - 1
        }
        page = document?.page(at: documentPage)!
        let pageThumbnail = page.thumbnail(of: CGSize(width: 210, height: 297), for: .artBox)

        largeThumbnail.image = pageThumbnail
    }
    
    @IBAction func prevPDFPage(_ sender: Any) {
        let document = PDFDocument(url: documentURL)
        let page: PDFPage!
        documentPage = documentPage - 1
        if documentPage < 0 {
            documentPage = 0
        }
        page = document?.page(at: documentPage)!
        let pageThumbnail = page.thumbnail(of: CGSize(width: 210, height: 297), for: .artBox)
        
        largeThumbnail.image = pageThumbnail

    }
    
    @IBAction func addExpenseTapped(_ sender: Any) {
        let currentProject = projectCD[selectedSubtableNumber]
        let newExpense = Expense(context: context)
        newExpense.amount = isStringAnInt(stringNumber: expenseString.text!)
        newExpense.overhead = Int16(isStringAnInt(stringNumber: overheadString.text!))
        newExpense.dateAdded = Date()
        newExpense.active = true
        if let comment = commentString.text {
            newExpense.comment = comment
        }
        if let reference = referenceString.text {
            newExpense.reference = reference
        }
        
        newExpense.project = currentProject
        expensesCD.append(newExpense)
        
        saveCoreData()
        loadCoreData()
        
        self.expensesTableView.reloadData()
    }
    
    @IBAction func addNewGroup(_ sender: Any) {
        switch categories[selectedCategoryNumber] {
        case "Publications":
            let inputNewGroup = UIAlertController(title: "New tag", message: "Enter name of new tag", preferredStyle: .alert)
            inputNewGroup.addTextField(configurationHandler: { (newGroup: UITextField) -> Void in
                newGroup.placeholder = "Enter tag"
            })
            inputNewGroup.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                let newGroup = inputNewGroup.textFields?[0]
                self.addNewItem(title: newGroup?.text, number: [""])
                inputNewGroup.dismiss(animated: true, completion: nil)
            }))
            inputNewGroup.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                inputNewGroup.dismiss(animated: true, completion: nil)
            }))
            self.present(inputNewGroup, animated: true, completion: nil)
            
        case "Economy":
            let inputNewProject = UIAlertController(title: "New project", message: "Enter name of new project", preferredStyle: .alert)
            inputNewProject.addTextField(configurationHandler: { (inputNewProject: UITextField) -> Void in
                inputNewProject.placeholder = "Enter project name"
            })
            inputNewProject.addTextField(configurationHandler: { (inputNewProject: UITextField) -> Void in
                inputNewProject.placeholder = "Input received amount"
            })
            inputNewProject.addTextField(configurationHandler: { (inputNewProject: UITextField) -> Void in
                inputNewProject.text = "Euro"
            })
            inputNewProject.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                let newProject = inputNewProject.textFields?[0]
                let amount = inputNewProject.textFields?[1]
                let currency = inputNewProject.textFields?[2]
                self.addNewItem(title: newProject?.text, number: [amount?.text, currency?.text])
                self.categoriesCV.reloadData()
                self.categoriesCV.selectItem(at: IndexPath(row: self.selectedCategoryNumber, section: 0), animated: true, scrollPosition: .top)
                inputNewProject.dismiss(animated: true, completion: nil)
            }))
            inputNewProject.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                inputNewProject.dismiss(animated: true, completion: nil)
            }))
            self.present(inputNewProject, animated: true, completion: nil)
            
        default:
            print("110")
        }
    }
    
    @IBAction func journalStringEditingEnded(_ sender: Any) {
        updateDatabasesWithNewFileInformation()
    }
    
    @IBAction func authorStringEditingEnded(_ sender: Any) {
        updateDatabasesWithNewFileInformation()
    }
    
    @IBAction func yearStringEditingEnded(_ sender: Any) {
        updateDatabasesWithNewFileInformation()
    }
    
    @IBAction func rankSliderEditingEnded(_ sender: Any) {
        updateDatabasesWithNewFileInformation()
    }
    
    @IBAction func rankSliderEditingEndedOutside(_ sender: Any) {
        updateDatabasesWithNewFileInformation()
    }
    
    @IBAction func notesStringEditingEnded(_ sender: Any) {
        updateDatabasesWithNewFileInformation()
    }
    
    @IBAction func editIconTapped(_ sender: Any) {
        editingFilesCV = !editingFilesCV
        filesCollectionView.reloadData()
    }
    
    @IBAction func amountReceivedEdited(_ sender: Any) {
        let currentProject = projectCD[selectedSubtableNumber]
        currentProject.amountReceived = isStringAnInt(stringNumber: amountReceivedString.text!)
        currentProject.amountRemaining = currentProject.amountReceived
        
        saveCoreData()
        loadCoreData()
        
        expensesTableView.reloadData()
    }
    
    @IBAction func sortCV(_ sender: Any) {
        
    }
    
    
    
    
    // MARK: - ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.startAnimating()
        loadingString.text = "Starting up..."

        //MARK: - AppDelegate
        let app = UIApplication.shared
        appDelegate = app.delegate as! AppDelegate
        icloudAvailable = appDelegate.iCloudAvailable!
        context = appDelegate.context
        notesView.isHidden = true

        self.categoriesCV.delegate = self
        self.categoriesCV.dataSource = self
        
        self.filesCollectionView.delegate = self
        self.filesCollectionView.dataSource = self
        self.filesCollectionView.dragDelegate = self
        self.filesCollectionView.dropDelegate = self
        
        self.expensesTableView.delegate = self
        self.expensesTableView.dataSource = self
        self.listTableView.delegate = self
        self.listTableView.dataSource = self
        self.listTableView.dropDelegate = self
        
        self.previewController.dataSource = self

        self.publicationsURL = self.appDelegate.publicationURL
        self.economyURL = self.appDelegate.economyURL
        self.manuscriptsURL = self.appDelegate.manuscriptURL
        self.proposalsURL = self.appDelegate.proposalsURL
        self.patentsURL = self.appDelegate.patentsURL
        self.supervisionsURL = self.appDelegate.supervisionURL
        self.teachingURL = self.appDelegate.teachingURL
        self.presentationsURL = self.appDelegate.presentationURL
        self.miscellaneousURL = self.appDelegate.miscellaneousURL
        
        self.iCloudURL = self.appDelegate.iCloudURL
        
        mainVC = self
        
        self.navigationController?.isNavigationBarHidden = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleSorttablePopupClosing), name: Notification.Name.sortSubtable, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleSettingsPopupClosing), name: Notification.Name.settingsCollectionView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handlePDFClosing), name: Notification.Name.closingPDF, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleInvoiceClosing), name: Notification.Name.closingInvoiceVC, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleSortCVClosing), name: Notification.Name.sortCollectionView, object: nil)
        
        // Touch gestures
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(self.doubleTapped))
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress))
        doubleTap.numberOfTapsRequired = 2
        longPress.minimumPressDuration = 2
        self.categoriesCV.addGestureRecognizer(longPress)
        self.filesCollectionView.addGestureRecognizer(doubleTap)
        
        self.listTableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .top)
        
        self.setupUI()
    }
    
    
    
    
    
    
    // MARK: - OBJECT C FUNCTIONS
    @objc func metadataQueryDidFinishGathering(notification: NSNotification) -> Void {
        let query: NSMetadataQuery = notification.object as! NSMetadataQuery
        query.disableUpdates()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: query)
        query.stop()
        print("metadataQueryDidFinishGathering")
        if query.resultCount > 0 {
            for res in query.results as! [NSMetadataItem] {
                print(res)
//                let name = res.value(forAttribute: NSMetadataItemFSNameKey) as! String
//                print(name)
            }
        }
//        if query.resultCount == 1 {
//            let resultsURL = query.value(ofAttribute: NSMetadataItemURLKey, forResultAt: 0) as! URL
//            document = MyDocument(fileURL: resultsURL as URL)
//            document?.open(completionHandler: { (success: Bool) -> Void in
//                if success {
//                    print("Success")
//                    self.textField.text = self.document?.userText
//                    self.iCloudURL = resultsURL as URL
//                } else {
//                    print("Could not open file")
//                }
//            })
//        } else {
//            if let url = iCloudURL {
//                document = MyDocument(fileURL: url)
//                document?.save(to: url, for: .forCreating, completionHandler: { (success: Bool) -> Void in
//                    if success {
//                        print("iCloud create ok!")
//                    } else {
//                        print("iCloud not created")
//                    }
//                })
//            }
//        }
    }
    
    @objc func handleSettingsPopupClosing(notification: Notification) {
        let settingsVC = notification.object as! SettingsViewController
        currentTheme = settingsVC.currentTheme!
        setThemeColor()
        
        kvStorage.set(currentTheme, forKey: "currentTheme")
        kvStorage.synchronize()

        self.categoriesCV.reloadData()
        self.categoriesCV.selectItem(at: IndexPath(row: selectedCategoryNumber, section: 0), animated: true, scrollPosition: .top)
        
    }
    
    @objc func handleSorttablePopupClosing(notification: Notification) {
        let sortingVC = notification.object as! SortSubtableViewController
        let sortValue = sortingVC.sortOptions.selectedSegmentIndex
        selectedSortingNumber = sortValue
        
        kvStorage.set(selectedSortingNumber, forKey: "sortSubtable")
        kvStorage.synchronize()

//        switch sortSubtableStrings[sortSubtableNumbers[selectedCategoryNumber]] {
//        case "Tag":
//            addNewGroupText.titleLabel?.text = "New tag"
//        case "Author":
//            addNewGroupText.titleLabel?.text = "New author"
//        case "Journal":
//            addNewGroupText.titleLabel?.text = "New journal"
//        default:
//            addNewGroupText.titleLabel?.text = "New tag"
//        }
        
        if sortSubtableStrings[selectedSortingNumber] == "Tag" {
            self.editButton.isHidden = false
        } else {
            self.editButton.isHidden = true
            editingFilesCV = false
        }

        populateListTable()
        populateFilesCV()
        sortFiles()

        self.listTableView.reloadData()
        self.filesCollectionView.reloadData()
        
        selectedFile[selectedCategoryNumber].category = categories[selectedCategoryNumber]
        selectedFile[selectedCategoryNumber].filename = currentSelectedFilename
        selectedFile[selectedCategoryNumber].indexPathCV = []

        if categories[selectedCategoryNumber] == "Publications" {
            for section in 0..<filesCV.count {
                for row in 0..<filesCV[section].count {
                    if filesCV[section][row].filename == currentSelectedFilename {
                        selectedFile[selectedCategoryNumber].indexPathCV.append(IndexPath(row: row, section: section))
                    }
                }
            }
        }
        
        if !selectedFile[selectedCategoryNumber].indexPathCV.isEmpty {
            self.filesCollectionView.scrollToItem(at: IndexPath(row: (selectedFile[selectedCategoryNumber].indexPathCV[0]?.row)!, section: (selectedFile[selectedCategoryNumber].indexPathCV[0]?.section)!), at: .top, animated: true)
            self.listTableView.scrollToRow(at: IndexPath(row: 0, section: (selectedFile[selectedCategoryNumber].indexPathCV[0]?.section)!), at: .top, animated: true)
            self.listTableView.selectRow(at: IndexPath(row: 0, section: (selectedFile[selectedCategoryNumber].indexPathCV[0]?.section)!), animated: true, scrollPosition: .top)
        }
        
    }
    
    @objc func handleSortCVClosing(notification: Notification) {
        let sortingVC = notification.object as! SortCVViewController
        let sortValue = sortingVC.sortOptions.selectedSegmentIndex
        selectedSortingCVNumber = sortValue
        print(selectedSortingCVNumber)
        
        kvStorage.set(selectedSortingNumber, forKey: "sortCV")
        kvStorage.synchronize()

        sortFiles()
        populateFilesCV()
        sortFiles()
        
        self.listTableView.reloadData()
        self.filesCollectionView.reloadData()

    }
    
    @objc func handlePDFClosing(notification: Notification) {
        let vc = notification.object as! PDFViewController
        annotationSettings = vc.annotationSettings!

        kvStorage.set(annotationSettings, forKey: "annotationSettings")
        kvStorage.synchronize()
        
        var update = false
        var index = 0
        for i in 0..<localFiles[selectedCategoryNumber].count {
            if localFiles[selectedCategoryNumber][i].filename == vc.PDFfilename {
                localFiles[selectedCategoryNumber][i].dateModified = Date()
                update = true
                index = i
            }
        }
        if update {
            updateIcloud(file: localFiles[selectedCategoryNumber][index])
            updateCoreData(file: localFiles[selectedCategoryNumber][index])
            populateFilesCV()
            sortFiles()
            filesCollectionView.reloadData()
        }
    }
    
    @objc func handleInvoiceClosing(notification: Notification) {
        let vc = notification.object as! InvoiceViewController
        selectedInvoice = vc.selectedInvoice
        currentExpense.pdfURL = economyURL.appendingPathComponent(selectedInvoice!)
        saveCoreData()
        loadCoreData()
        self.expensesTableView.reloadData()
    }
    
    @objc func doubleTapped(gesture: UITapGestureRecognizer) {
        
        let pointInCollectionView = gesture.location(in: self.filesCollectionView)
        switch categories[selectedCategoryNumber] {
        case "Publications":
            if let indexPath = self.filesCollectionView.indexPathForItem(at: pointInCollectionView) {
                let selectedCell = filesCV[indexPath.section][indexPath.row]
                let url = publicationsURL.appendingPathComponent((selectedCell.filename))
                PDFdocument = PDFDocument(url: url)
                PDFfilename = selectedCell.filename
                NotificationCenter.default.post(name: Notification.Name.sendPDFfilename, object: self)
                performSegue(withIdentifier: "seguePDFViewController", sender: self)
            }
        default:
            let pointInCollectionView = gesture.location(in: self.filesCollectionView)
            if let indexPath = self.filesCollectionView.indexPathForItem(at: pointInCollectionView) {
                let url = docCV[selectedSubtableNumber].files[indexPath.section][indexPath.row].url
                if url.lastPathComponent.range(of: ".pdf") != nil {
                    PDFdocument = PDFDocument(url: url)
                    PDFfilename = docCV[selectedSubtableNumber].files[indexPath.section][indexPath.row].filename
                    NotificationCenter.default.post(name: Notification.Name.sendPDFfilename, object: self)
                    performSegue(withIdentifier: "seguePDFViewController", sender: self)
                } else {
                    previewFile = docCV[selectedSubtableNumber].files[indexPath.section][indexPath.row]
                    previewController.reloadData()
                    navigationController?.pushViewController(previewController, animated: true)
                }
                
            }

        }
    }
    
    @objc func checkIfFileIsDownloaded() {
        var stillDownloading = false
        for i in 0..<filesDownloading.count {
            if !filesDownloading[i].downloaded {
                let fileManager = FileManager.default
                do {
                    let file = filesDownloading[i]
                    var filename = file.url.deletingPathExtension().lastPathComponent
                    filename.remove(at: filename.startIndex)
                    let folder = file.url.deletingLastPathComponent()
                    let filePath = folder.appendingPathComponent(filename).path
                    let exist = fileManager.fileExists(atPath: filePath)
                    
                    if !exist {
                        stillDownloading = true
                        loadingString.text = "Downloading " + filename
                    } else {
                        filesDownloading[i].downloaded = true
                        readIcloudDriveFolders()
                        compareLocalFilesWithDatabase()
                        populateListTable()
                        populateFilesCV()
                        sortFiles()
                        listTableView.reloadData()
                        filesCollectionView.reloadData()
                        
                    }
                }
            }

        }
        
        if !stillDownloading {
            activityIndicator.stopAnimating()
            loadingString.text = ""
            downloadTimer.invalidate()
        }
        
        
    }
    
    @objc func handleLongPress(gesture : UILongPressGestureRecognizer!) {

        let point = gesture.location(in: self.categoriesCV)
        
        if let indexPath = self.categoriesCV.indexPathForItem(at: point) {
            activityIndicator.startAnimating()
            loadingString.text = "Refreshing " + categories[indexPath.row] + " directory"

            selectedCategoryNumber = indexPath.row
            populateFilesCV()
            sortFiles()
            populateListTable()
            categoriesCV.reloadData()
            listTableView.reloadData()
            filesCollectionView.reloadData()

            localFiles[indexPath.row] = []
            switch categories[indexPath.row] {
            case "Publications":
                let fileManager = FileManager.default
                do {
                    let fileURLs = try fileManager.contentsOfDirectory(at: publicationsURL!, includingPropertiesForKeys: nil)
                    for file in fileURLs {
                        var thumbnail = UIImage()
                        var filename = String()
                        var available = true
                        if file.lastPathComponent.range(of:".icloud") != nil {
                            thumbnail = #imageLiteral(resourceName: "FileOffline")
                            available = false
                            filename = file.deletingPathExtension().lastPathComponent
                            filename.remove(at: filename.startIndex)
                        } else {
                            thumbnail = getThumbnail(url: file, pageNumber: 0)
                            filename = file.lastPathComponent
                        }
                        let newFile = LocalFile(label: file.lastPathComponent, thumbnail: thumbnail, favorite: "No", filename: filename, url: file, title: "No title", journal: "No journal", year: -2000, category: "Publication", rank: 50, note: "No notes", dateCreated: Date(), dateModified: Date(), author: "No author", groups: ["All publications"], parentFolder: nil, grandpaFolder: nil, available: available, filetype: nil)
                        localFiles[0].append(newFile)
                    }
                    compareLocalFilesWithDatabase()
                    
                } catch {
                    print("Error while enumerating files \(publicationsURL.path): \(error.localizedDescription)")
                    
                    activityIndicator.stopAnimating()
                    loadingString.text = ""
                }
                
            case "Economy":
                readFilesInFolders(url: economyURL, type: categories[indexPath.row], number: 1)
            case "Manuscripts":
                readFilesInFolders(url: manuscriptsURL, type: categories[indexPath.row], number: 2)
            case "Presentations":
                readFilesInFolders(url: presentationsURL, type: categories[indexPath.row], number: 3)
            case "Proposals":
                readFilesInFolders(url: proposalsURL, type: categories[indexPath.row], number: 4)
            case "Supervision":
                readFilesInFolders(url: supervisionsURL, type: categories[indexPath.row], number: 5)
            case "Teaching":
                readFilesInFolders(url: teachingURL, type: categories[indexPath.row], number: 6)
            case "Patents":
                readFilesInFolders(url: patentsURL, type: categories[indexPath.row], number: 7)
            case "Courses":
                readFilesInFolders(url: patentsURL, type: categories[indexPath.row], number: 8)
            case "Miscellaneous":
                readFilesInFolders(url: miscellaneousURL, type: categories[indexPath.row], number: 9)
            default:
                print("Default 122")
            }
            
            populateListTable()
            populateFilesCV()
            sortFiles()
            categoriesCV.reloadData()
            listTableView.reloadData()
            filesCollectionView.reloadData()
            
        } else {
            print("couldn't find index path")
        }
        
    }
    
    
    
    
    
    // MARK: - ICLOUD FUNCTIONS
    //WORK IN PROGRESS
    func saveToIcloud(url: URL) {
        activityIndicator.startAnimating()
        if let zoneID = recordZone?.zoneID {
            let myRecord = CKRecord(recordType: categories[selectedCategoryNumber], zoneID: zoneID)
            switch categories[selectedCategoryNumber] {
            case "Publications":
                // Saving default values
                let thumbnail = CKAsset(fileURL: url)
                let tag = ["All publications", "Unfiled"]
                myRecord.setObject(url.lastPathComponent as CKRecordValue?, forKey: "Filename")
                myRecord.setObject("No author" as CKRecordValue?, forKey: "Author")
                myRecord.setObject(thumbnail as CKRecordValue?, forKey: "Thumbnail")
                myRecord.setObject(tag as CKRecordValue?, forKey: "Group")
                myRecord.setObject(50 as CKRecordValue?, forKey: "Rank")
                myRecord.setObject(-2000 as CKRecordValue?, forKey: "Year")
                myRecord.setObject("No notes" as CKRecordValue?, forKey: "Note")
                myRecord.setObject("No title" as CKRecordValue?, forKey: "Title")
                myRecord.setObject("No" as CKRecordValue?, forKey: "Favorite")
                
                let modifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: [myRecord], recordIDsToDelete: nil)
                let configuration = CKOperationConfiguration()
                configuration.timeoutIntervalForRequest = 10
                configuration.timeoutIntervalForResource = 10
                
                modifyRecordsOperation.configuration = configuration
                modifyRecordsOperation.modifyRecordsCompletionBlock =
                    { records, recordIDs, error in
                        if let err = error {
                            print(err)
                        } else {
                            DispatchQueue.main.async {
                                print("Record saved successfully to icloud database")
                            }
                            self.currentRecord = myRecord
                        }
                }
                privateDatabase?.add(modifyRecordsOperation)
            default:
                print("101")
            }
        }
        activityIndicator.stopAnimating()
    }
    
    func updateIcloud(file: LocalFile) {
        activityIndicator.startAnimating()
        
        let predicate = NSPredicate(format: "Filename = %@", file.filename)
        let query = CKQuery(recordType: "Publications", predicate: predicate)
        
        privateDatabase?.perform(query, inZoneWith: recordZone?.zoneID) { (records, error) in
            guard let records = records else {return}
            DispatchQueue.main.async {
                // FOUND AT LEAST ONE RECORD
                if records.count > 0 {
                    for record in records {
                        if record.object(forKey: "Filename") as! String == file.filename {
                            
                            record.setObject(file.year as CKRecordValue?, forKey: "Year")
                            record.setObject(file.favorite as CKRecordValue?, forKey: "Favorite")
                            record.setObject(file.note as CKRecordValue?, forKey: "Note")
                            record.setObject(Int(file.rank!) as CKRecordValue?, forKey: "Rank")
                            record.setObject(file.author as CKRecordValue?, forKey: "Author")
                            record.setObject(file.journal as CKRecordValue?, forKey: "Journal")
                            record.setObject(file.groups as CKRecordValue?, forKey: "Group")
                            
                            self.privateDatabase?.save(record, completionHandler:( { savedRecord, error in
                                DispatchQueue.main.async {
                                    if let error = error {
                                        print("accountStatus error: \(error)")
                                    }
                                    print(file.filename + " successfully updated to icloud database")
                                    self.activityIndicator.stopAnimating()
                                    self.loadingString.text = ""
                                }
                            }))
                            
                        }
                    }
                } else {
                    // ADD FILE TO ICLOUD
                    if let zoneID = self.recordZone?.zoneID {
                        let myRecord = CKRecord(recordType: self.categories[self.selectedCategoryNumber], zoneID: zoneID)
                        switch self.categories[self.selectedCategoryNumber] {
                        case "Publications":
                            
                            myRecord.setObject(file.filename as CKRecordValue?, forKey: "Filename")
                            myRecord.setObject(file.author as CKRecordValue?, forKey: "Author")
                            myRecord.setObject(file.journal as CKRecordValue?, forKey: "Journal")
                            myRecord.setObject(file.groups as CKRecordValue?, forKey: "Group")
                            myRecord.setObject(Int(file.rank!) as CKRecordValue?, forKey: "Rank")
                            myRecord.setObject(file.year as CKRecordValue?, forKey: "Year")
                            myRecord.setObject(file.note as CKRecordValue?, forKey: "Note")
                            myRecord.setObject(file.favorite as CKRecordValue?, forKey: "Favorite")
                            
                            let modifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: [myRecord], recordIDsToDelete: nil)
                            let configuration = CKOperationConfiguration()
                            configuration.timeoutIntervalForRequest = 10
                            configuration.timeoutIntervalForResource = 10
                            
                            modifyRecordsOperation.configuration = configuration
                            modifyRecordsOperation.modifyRecordsCompletionBlock =
                                { records, recordIDs, error in
                                    if let err = error {
                                        print(err)
                                    } else {
                                        DispatchQueue.main.async {
                                            print(file.filename + " successfully added to icloud database")
                                            self.activityIndicator.stopAnimating()
                                            self.loadingString.text = ""
                                        }
                                        self.currentRecord = myRecord
                                    }
                            }
                            self.privateDatabase?.add(modifyRecordsOperation)
                        default:
                            print("101")
                        }
                    }
                }
            }
        }
    }
    
    func loadIcloudData() {
        if appDelegate.iCloudAvailable {
            // GET PUBLICATIONS
            let query = CKQuery(recordType: "Publications", predicate: NSPredicate(value: true))
            privateDatabase?.perform(query, inZoneWith: recordZone?.zoneID) { (records, error) in
                guard let records = records else {return}
                DispatchQueue.main.async {
                    self.activityIndicator.startAnimating()
                    self.loadingString.text = "Loading publications"
                    for record in records {
                        let thumbnail = self.getThumbnail(url: self.publicationsURL.appendingPathComponent(record.object(forKey: "Filename") as! String), pageNumber: 0)
                        let newPublication = PublicationFile(filename: record.object(forKey: "Filename") as! String, title: record.object(forKey: "Title") as? String, year: record.object(forKey: "Year") as? Int16, thumbnails: [thumbnail], category: "Publication", rank: record.object(forKey: "Rank") as? Float, note: record.object(forKey: "Note") as? String, dateCreated: record.creationDate, dateModified: record.modificationDate, favorite: record.object(forKey: "Favorite") as? String, author: record.object(forKey: "Author") as? String, journal: record.object(forKey: "Journal") as? String, groups: record.object(forKey: "Group") as! [String?])
                        self.publicationsIC.append(newPublication)
                    }
                    
                    self.compareLocalFilesWithDatabase()
                    self.populateListTable()
                    self.populateFilesCV()
                    self.sortFiles()

                    self.categoriesCV.reloadData()
//                    self.categoriesCV.selectItem(at: IndexPath(row: self.selectedCategoryNumber, section: 0), animated: true, scrollPosition: .top)
                    self.listTableView.reloadData()
                    self.filesCollectionView.reloadData()
                    
                    self.activityIndicator.stopAnimating()
                    self.loadingString.text = ""

                }
            }
            // GET PROJECTS
            let queryProjects = CKQuery(recordType: "Projects", predicate: NSPredicate(value: true))
            privateDatabase?.perform(queryProjects, inZoneWith: recordZone?.zoneID) { (records, error) in
                guard let records = records else {return}
                DispatchQueue.main.async {
                    self.activityIndicator.startAnimating()
                    self.loadingString.text = "Loading projects"
                    for record in records {
                        let newProject = ProjectFile(name: record.object(forKey: "Name") as! String, amountReceived: record.object(forKey: "AmountReceived") as! Int32, amountRemaining: record.object(forKey: "AmountRemaining") as! Int32, expenses: [])
                        self.projectsIC.append(newProject)
                    }
                    
//                    self.compareLocalFilesWithDatabase()
//                    self.populateListTable()
//                    self.populateFilesCV()
//                    //                    self.sortItems()
//
//                    self.categoriesCV.reloadData()
//                    self.listTableView.reloadData()
//                    self.filesCollectionView.reloadData()
                    
                    self.activityIndicator.stopAnimating()
                    self.loadingString.text = ""
                }
            }
        } else {
            print("Icloud not available")
            compareLocalFilesWithDatabase()
            populateListTable()
            populateFilesCV()
            sortFiles()
            
            self.categoriesCV.reloadData()
//            self.categoriesCV.selectItem(at: IndexPath(row: self.selectedCategoryNumber, section: 0), animated: true, scrollPosition: .top)
            listTableView.reloadData()
            filesCollectionView.reloadData()
            activityIndicator.stopAnimating()
            loadingString.text = ""

        }
    }

    func readIcloudDriveFolders() {
        localFiles = [[]]

        for type in categories{
            switch type {
            case "Publications":
                let fileManager = FileManager.default
                do {
                    let fileURLs = try fileManager.contentsOfDirectory(at: publicationsURL!, includingPropertiesForKeys: nil)
                    for file in fileURLs {
                        var thumbnail = UIImage()
                        var filename = String()
                        var available = true
                        if file.lastPathComponent.range(of:".icloud") != nil {
                            thumbnail = #imageLiteral(resourceName: "FileOffline")
                            available = false
                            filename = file.deletingPathExtension().lastPathComponent
                            filename.remove(at: filename.startIndex)
                        } else {
                            thumbnail = getThumbnail(url: file, pageNumber: 0)
                            filename = file.lastPathComponent
                        }
                        let newFile = LocalFile(label: file.lastPathComponent, thumbnail: thumbnail, favorite: "No", filename: filename, url: file, title: "No title", journal: "No journal", year: -2000, category: "Publication", rank: 50, note: "No notes", dateCreated: Date(), dateModified: Date(), author: "No author", groups: ["All publications"], parentFolder: nil, grandpaFolder: nil, available: available, filetype: nil)
                        localFiles[0].append(newFile)
                    }
                } catch {
                    print("Error while enumerating files \(publicationsURL.path): \(error.localizedDescription)")
                }
            case "Economy":
                readFilesInFolders(url: economyURL, type: type, number: 1)
            case "Manuscripts":
                readFilesInFolders(url: manuscriptsURL, type: type, number: 2)
            case "Presentations":
                readFilesInFolders(url: presentationsURL, type: type, number: 3)
            case "Proposals":
                readFilesInFolders(url: proposalsURL, type: type, number: 4)
            case "Supervision":
                readFilesInFolders(url: supervisionsURL, type: type, number: 5)
            case "Teaching":
                readFilesInFolders(url: teachingURL, type: type, number: 6)
            case "Patents":
                readFilesInFolders(url: patentsURL, type: type, number: 7)
            case "Courses":
                readFilesInFolders(url: patentsURL, type: type, number: 8)
            case "Miscellaneous":
                readFilesInFolders(url: miscellaneousURL, type: type, number: 9)
            default:
                print("Default 122")
            }
        }
    }
    
    func loadDefaultValues() {
        if let number = kvStorage.object(forKey: "sortCV") as? Int {
            selectedSortingCVNumber = number
        } else {
            selectedSortingCVNumber = 0
        }
        
        if let number = kvStorage.object(forKey: "sortST") as? Int {
            selectedSortingNumber = number
        } else {
            selectedSortingNumber = 0
        }

//        if let number = kvStorage.object(forKey: "selectedSubtableNumber") as? Int {
//            selectedSubtableNumber = number
//        } else {
//            selectedSubtableNumber = 0
//        }
        
        if let number = kvStorage.object(forKey: "currentTheme") as? Int {
            currentTheme = number
        } else {
            currentTheme = 0
        }
        print(currentTheme)
        if let settings = kvStorage.object(forKey: "annotationSettings") as? [Int] {
            annotationSettings = settings
            print(annotationSettings)
        } else {
            annotationSettings = [0, 0, 0, 0]
        }
        
    }
    
    func readFilesInFolders(url: URL, type: String, number: Int) {
        let fileManager = FileManager.default
        do {
            let folderURLs = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            localFiles.append([])
            for folder in folderURLs {
                if folder.isDirectory()! {
                    let subfoldersURLs = try fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
                    for subfolder in subfoldersURLs {
                        if subfolder.isDirectory()! {
                            let files = try fileManager.contentsOfDirectory(at: subfolder, includingPropertiesForKeys: nil)
                            for file in files {
                                var thumbnail = UIImage()
                                var filename = String()
                                var available = true
                                if file.lastPathComponent.range(of:".icloud") != nil {
                                    thumbnail = getThumbnail(url: file, pageNumber: 0)
                                    available = false
                                    filename = file.deletingPathExtension().lastPathComponent
                                    filename.remove(at: filename.startIndex)
                                } else {
                                    thumbnail = getThumbnail(url: file, pageNumber: 0)
                                    filename = file.lastPathComponent
                                }
                                let newFile = LocalFile(label: filename, thumbnail: thumbnail, favorite: "No", filename: filename, url: file, title: nil, journal: nil, year: nil, category: type, rank: nil, note: "No notes", dateCreated: Date(), dateModified: Date(), author: nil, groups: [nil], parentFolder: subfolder.lastPathComponent, grandpaFolder: folder.lastPathComponent, available: available, filetype: nil)
                                localFiles[number].append(newFile)
                            }
                        } else {
                            var thumbnail = UIImage()
                            var filename = String()
                            var available = true
                            if subfolder.lastPathComponent.range(of:".icloud") != nil {
                                thumbnail = getThumbnail(url: subfolder, pageNumber: 0)
                                available = false
                                filename = subfolder.deletingPathExtension().lastPathComponent
                                filename.remove(at: filename.startIndex)
                            } else {
                                thumbnail = getThumbnail(url: subfolder, pageNumber: 0)
                                filename = subfolder.lastPathComponent
                            }
                            let newFile = LocalFile(label: filename, thumbnail: thumbnail, favorite: "No", filename: filename, url: subfolder, title: nil, journal: nil, year: nil, category: type, rank: nil, note: "No notes", dateCreated: Date(), dateModified: Date(), author: nil, groups: [nil], parentFolder: "Uncategorized", grandpaFolder: folder.lastPathComponent, available: available, filetype: nil)
                            localFiles[number].append(newFile)
                        }
                    }
                } else {
                    var thumbnail = UIImage()
                    var filename = String()
                    var available = true
                    if folder.lastPathComponent.range(of:".icloud") != nil {
                        thumbnail = getThumbnail(url: folder, pageNumber: 0)
                        available = false
                        filename = folder.deletingPathExtension().lastPathComponent
                        filename.remove(at: filename.startIndex)
                    } else {
                        thumbnail = getThumbnail(url: folder, pageNumber: 0)
                        filename = folder.lastPathComponent
                    }
                    let newFile = LocalFile(label: filename, thumbnail: thumbnail, favorite: "No", filename: filename, url: folder, title: nil, journal: nil, year: nil, category: type, rank: nil, note: "No notes", dateCreated: Date(), dateModified: Date(), author: nil, groups: [nil], parentFolder: "Uncategorized", grandpaFolder: folder.lastPathComponent, available: available, filetype: nil)
                    localFiles[number].append(newFile)
                }
                
            }
        } catch {
            print("Error while reading " + type + " folders")
        }
        
    }
    
    
    
    
    // MARK: - STORYBOARD FUNCTIONS
    func updateLocalFiles() -> LocalFile? {
        switch categories[selectedCategoryNumber] {
        case "Publications":
            for i in 0..<localFiles[0].count {
                if localFiles[0][i].filename == filenameString.text {
                    
                    localFiles[0][i].dateModified = Date()
                    localFiles[0][i].rank = rankOutlet.value
                    
                    if (journalString.text?.isEmpty)! {
                        localFiles[0][i].journal = "No journal"
                    } else {
                        localFiles[0][i].journal = journalString.text
                    }
                    
                    if (yearString.text?.isEmpty)! {
                        localFiles[0][i].year = -2000
                    } else {
                        let year = Int16(isStringAnInt(stringNumber: yearString.text!))
                        localFiles[0][i].year = year
                    }
                    
                    if (notesString.text?.isEmpty)! {
                        localFiles[0][i].note = "No note"
                    } else {
                        localFiles[0][i].note = notesString.text
                    }
                    
                    if (authorString.text?.isEmpty)! {
                        localFiles[0][i].author = "No author"
                    } else {
                        localFiles[0][i].author = authorString.text
                    }
                    print("Updated local file: " + localFiles[0][i].filename)
                    return localFiles[0][i]
                }
            }
        default:
            return nil
        }
        return nil
    }
    
    func addNewItem(title: String?, number: [String?]) {
        switch categories[selectedCategoryNumber] {
        case "Publications":
            if let newTag = title {
                let newGroup = PublicationGroup(context: context)
                newGroup.tag = newTag
                newGroup.dateModified = Date()
                newGroup.sortNumber = "3"
                
                publicationGroupsCD.append(newGroup)

                saveCoreData()
                loadCoreData()
                
                populateListTable()
                populateFilesCV()
                sortFiles()
                
                self.listTableView.reloadData()
                self.filesCollectionView.reloadData()
            }
            
        case "Economy":
            if let newTitle = title {
                if let amount = number[0] {
                    if let currency = number[1] {
                        let amountReceived = isStringAnInt(stringNumber: amount)
                        let newProject = Project(context: context)
                        newProject.name = newTitle
                        newProject.dateModified = Date()
                        newProject.dateCreated = Date()
                        newProject.amountReceived = amountReceived
                        newProject.currency = currency
                        
                        projectCD.append(newProject)
                        
                        saveCoreData()
                        loadCoreData()
                        
                        amountReceivedString.text = "\(amountReceived)"
                        amountRemainingString.text = "0"
                        currencyString.text = currency
                        
                        
                        populateListTable()
                        self.listTableView.reloadData()
                    }
                }
            }
        default:
            print("Default 111")
            
        }
    }
    
    func setThemeColor() {
        
        switch currentTheme {
        case 0: //Blue
            backgroundColor = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
            textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
            barColor = UIColor(red: 146/255, green: 144/255, blue: 0, alpha: 1)
        case 1: //Red
            backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
            textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
            barColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        case 2: //Night
            backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
            textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
            barColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        default:
            backgroundColor = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
            textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
            barColor = UIColor(red: 146/255, green: 144/255, blue: 0, alpha: 1)
        }
        
        mainView.backgroundColor = barColor
        backgroundView.backgroundColor = backgroundColor
        categoriesCV.backgroundColor = backgroundColor
        filesCollectionView.backgroundColor = backgroundColor
        notesView.backgroundColor = backgroundColor
        selectedCategoryTitle.backgroundColor = barColor
        selectedCategoryTitle.textColor = textColor
        segmentedControllTablesOrNotes.tintColor = barColor
        segmentedControllTablesOrNotes.backgroundColor = textColor
        economyView.backgroundColor = backgroundColor
        economyHeader.backgroundColor = barColor
        listTableView.backgroundColor = backgroundColor
        listTableView.tintColor = textColor

        
        filesCollectionView.reloadData()
    }
    
    func populateListTable() {
        print("populateListTable")
        
        sortTableTitles = [String]()
        switch categories[selectedCategoryNumber] {
        case "Publications":
//            sortTableTitles = [String]()
            
            switch sortSubtableStrings[selectedSortingNumber] {
            case "Tag":
                let tmp = publicationGroupsCD.sorted(by: {($0.sortNumber!, $0.tag!) < ($1.sortNumber!, $1.tag!)})
                sortTableTitles = tmp.map { $0.tag! }
            case "Year":
                sortTableTitles = getArticlesYears()
            case "Author":
                let tmp = authorsCD.sorted(by: {($0.sortNumber!, $0.name!) < ($1.sortNumber!, $1.name!)})
                sortTableTitles = tmp.map { $0.name! }
            case "Journal":
                let tmp = journalsCD.sorted(by: {($0.sortNumber!, $0.name!) < ($1.sortNumber!, $1.name!)})
                sortTableTitles = tmp.map { $0.name! }
            case "Rank":
                sortTableTitles = ["0-9", "10-19", "20-29", "30-39", "40-49", "50-59", "60-69", "70-79", "80-89", "90-99", "100"]
            default:
                print("Default 125")
            }
            
            
        case "Manuscripts", "Presentations", "Proposals", "Supervision", "Teaching", "Patents", "Courses", "Miscellaneous":
//            sortTableTitles = []
            var number = 2
            if categories[selectedCategoryNumber] == "Presentations" {
                number = 3
            } else if categories[selectedCategoryNumber] == "Proposals" {
                number = 4
            } else if categories[selectedCategoryNumber] == "Supervision" {
                number = 5
            } else if categories[selectedCategoryNumber] == "Teaching" {
                number = 6
            } else if categories[selectedCategoryNumber] == "Patents" {
                number = 7
            } else if categories[selectedCategoryNumber] == "Courses" {
                number = 9
            } else if categories[selectedCategoryNumber] == "Miscellaneous" {
                number = 8
            }
            
            for file in localFiles[number] {
                sortTableTitles.append(file.grandpaFolder!)
            }
            
            if !sortTableTitles.isEmpty {
                let set = Set(sortTableTitles)
                sortTableTitles = Array(set)
                sortTableTitles = sortTableTitles.sorted()
            }
            
        case "Economy":
//            sortTableTitles = [String]()
            let tmp = projectCD.sorted(by: {$0.name! < $1.name!})
            sortTableTitles = tmp.map { $0.name! }
            
        default:
            print("Default 126")
        }
        
        print(sortTableTitles)
        
    }
    
    func populateFilesCV() {
        print("populateFilesCV")
        
        switch categories[selectedCategoryNumber] {
        case "Publications": //LocalFiles[0]
            filesCV = [[]]
            
            switch sortSubtableStrings[selectedSortingNumber] {
            case "Tag":
                for i in 0..<sortTableTitles.count {
                    for file in localFiles[0] {
                        if file.groups.first(where: {$0 == sortTableTitles[i]}) != nil {
                            filesCV[i].append(file)
                        }
                    }
                    filesCV[i] = filesCV[i].sorted(by: {($0.filename) < ($1.filename)})
                    if i < sortTableTitles.count {
                        filesCV.append([]) // ADD [] FOR THE NEXT ROUND
                    }
                }
            case "Author":
                for i in 0..<sortTableTitles.count {
                    for file in localFiles[0] {
                        if file.author == sortTableTitles[i] {
                            filesCV[i].append(file)
                        }
                    }
                    filesCV[i] = filesCV[i].sorted(by: {($0.filename) < ($1.filename)})
                    if i < sortTableTitles.count {
                        filesCV.append([]) // ADD [] FOR THE NEXT ROUND
                    }
                }
            case "Journal":
                for i in 0..<sortTableTitles.count {
                    for file in localFiles[0] {
                        if file.journal == sortTableTitles[i] {
                            filesCV[i].append(file)
                        }
                    }
                    filesCV[i] = filesCV[i].sorted(by: {($0.filename) < ($1.filename)})
                    if i < sortTableTitles.count {
                        filesCV.append([]) // ADD [] FOR THE NEXT ROUND
                    }
                }
            case "Year":
                for i in 0..<sortTableTitles.count {
                    for file in localFiles[0] {
                        if file.year == Int16(sortTableTitles[i]) {
                            filesCV[i].append(file)
                        }
                    }
                    filesCV[i] = filesCV[i].sorted(by: {($0.filename) < ($1.filename)})
                    if i < sortTableTitles.count {
                        filesCV.append([]) // ADD [] FOR THE NEXT ROUND
                    }
                }
            case "Rank":
                let rankIntervals = [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
                for i in 0..<rankIntervals.count {
                    for file in localFiles[0] {
                        if rankIntervals[i] != 100 {
                            if Int16(file.rank!) >= rankIntervals[i] && Int16(file.rank!) < rankIntervals[i+1] {
                                filesCV[i].append(file)
                            }
                        } else {
                            if Int16(file.rank!) == 100 {
                                filesCV[i].append(file)
                            }
                        }
                    }
                    filesCV[i] = filesCV[i].sorted(by: {($0.filename) < ($1.filename)})
                    if i < sortTableTitles.count {
                        filesCV.append([]) // ADD [] FOR THE NEXT ROUND
                    }
                }
            default:
                print("Default 132")
            }
            
        case "Manuscripts", "Presentations", "Proposals", "Supervision", "Teaching", "Patents", "Miscellaneous":
            var number = 2
            if categories[selectedCategoryNumber] == "Presentations" {
                number = 3
            } else if categories[selectedCategoryNumber] == "Proposals" {
                number = 4
            } else if categories[selectedCategoryNumber] == "Supervision" {
                number = 5
            } else if categories[selectedCategoryNumber] == "Teaching" {
                number = 6
            } else if categories[selectedCategoryNumber] == "Patents" {
                number = 7
            } else if categories[selectedCategoryNumber] == "Courses" {
                number = 8
            } else if categories[selectedCategoryNumber] == "Miscellaneous" {
                number = 9
            }
            
            docCV = []
            
            if !sortTableTitles.isEmpty {
                for i in 0..<sortTableTitles.count {
                    var subfolders: [String] = []
                    var tmp = DocCV(listTitle: sortTableTitles[i], sectionHeader: [], files: [[]])
                    for file in localFiles[number] {
                        if file.grandpaFolder == sortTableTitles[i] {
                            tmp.sectionHeader.append(file.parentFolder!)
                        }
                    }
                    subfolders = tmp.sectionHeader
                    if !subfolders.isEmpty {
                        let set = Set(subfolders)
                        let array = Array(set)
                        subfolders = array.sorted()
                    }
                    tmp.sectionHeader = subfolders
                    for j in 0..<subfolders.count {
                        for file in localFiles[number] {
                            if file.parentFolder == subfolders[j] && file.grandpaFolder == sortTableTitles[i] {
                                tmp.files[j].append(file)
                            }
                        }
                        if j < subfolders.count {
                            tmp.files.append([])
                        }
                    }
                    docCV.append(tmp)
                }
                
            }

        default:
            print("Default 133")
        }

    }
    
    func getArticlesYears() -> [String] {
        var tmp = [String]()
        for i in 0..<localFiles[selectedCategoryNumber].count {
            tmp.append("\(localFiles[selectedCategoryNumber][i].year!)")
        }
        yearsString = tmp.reduce([], {$0.contains($1) ? $0:$0+[$1]})
        yearsString = yearsString.sorted(by: {$0 < $1})
        return yearsString
    }

    func sortFiles() {
        switch categories[selectedCategoryNumber] {
        case "Publications":
            if !filesCV.isEmpty {
                switch selectedSortingCVNumber {
                case 1:
                    filesCV[selectedSubtableNumber] = filesCV[selectedSubtableNumber].sorted(by: {($0.dateModified)! > ($1.dateModified)!})
                default:
                    filesCV[selectedSubtableNumber] = filesCV[selectedSubtableNumber].sorted(by: {($0.filename) < ($1.filename)})
                }
            }
            
        default:
            if !docCV.isEmpty {
                switch selectedSortingCVNumber {
                case 1:
                    for i in 0..<docCV[selectedSubtableNumber].files.count {
                        docCV[selectedSubtableNumber].files[i] = docCV[selectedSubtableNumber].files[i].sorted(by: {($0.dateModified)! > ($1.dateModified)!})
                    }
                default:
                    for i in 0..<docCV[selectedSubtableNumber].files.count {
                        docCV[selectedSubtableNumber].files[i] = docCV[selectedSubtableNumber].files[i].sorted(by: {$0.filename < $1.filename})
                    }
                }
            }
        }
    }
    
    
    
    
    
    // MARK: - CORE DATA FUNCTIONS
    func saveCoreData() {
        do {
            try context.save()
            print("Saved to core data")
        } catch {
            alert(title: "Error saving", message: "Could not save core data")
        }
    }
    
    func loadCoreData() {

        let requestPublicationGroups: NSFetchRequest<PublicationGroup> = PublicationGroup.fetchRequest()
        requestPublicationGroups.sortDescriptors = [NSSortDescriptor(key: "tag", ascending: true)]
        do {
            publicationGroupsCD = try context.fetch(requestPublicationGroups)
        } catch {
            print("Error loading groups")
        }

        let requestAuthors: NSFetchRequest<Author> = Author.fetchRequest()
        requestAuthors.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            authorsCD = try context.fetch(requestAuthors)
        } catch {
            print("Error loading authors")
        }

        let requestJournals: NSFetchRequest<Journal> = Journal.fetchRequest()
        requestJournals.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            journalsCD = try context.fetch(requestJournals)
        } catch {
            print("Error loading journals")
        }

        let request: NSFetchRequest<Publication> = Publication.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "filename", ascending: true)]
        do {
            publicationsCD = try context.fetch(request)
        } catch {
            print("Error loading publications")
        }
        
        let requestProjects: NSFetchRequest<Project> = Project.fetchRequest()
        requestProjects.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            projectCD = try context.fetch(requestProjects)
        } catch {
            print("Error loading project")
        }

        let requestExpenses: NSFetchRequest<Expense> = Expense.fetchRequest()
        requestExpenses.sortDescriptors = [NSSortDescriptor(key: "dateAdded", ascending: true)]
        do {
            expensesCD = try context.fetch(requestExpenses)
        } catch {
            print("Error loading expenses")
        }
    }
    
    func setupDefaultCoreDataTypes() {
        
        // ADD "NO AUTHOR"
        let arrayAuthors = authorsCD
        if arrayAuthors.first(where: {$0.name == "No author"}) == nil {
            let newAuthor = Author(context: context)
            newAuthor.name = "No author"
            newAuthor.sortNumber = "0"
            saveCoreData()
        }
        
        // ADD "NO JOURNAL"
        let arrayJournals = journalsCD
        if arrayJournals.first(where: {$0.name == "No journal"}) == nil {
            let newJournal = Journal(context: context)
            newJournal.name = "No journal"
            newJournal.sortNumber = "0"
            saveCoreData()
        }

        // ADD "ALL PUBLICATIONS"
        let arrayPublicationGroups = publicationGroupsCD
        if arrayPublicationGroups.first(where: {$0.tag == "All publications"}) == nil {
            let newPublicationGroup = PublicationGroup(context: context)
            newPublicationGroup.tag = "All publications"
            newPublicationGroup.dateModified = Date()
            newPublicationGroup.sortNumber = "0"
            saveCoreData()
        }

        // ADD "FAVORITES"
        if publicationGroupsCD.first(where: {$0.tag == "Favorites"}) == nil {
            let favoriteGroup = PublicationGroup(context: context)
            favoriteGroup.tag = "Favorites"
            favoriteGroup.dateModified = Date()
            favoriteGroup.sortNumber = "1"
            saveCoreData()
        }

        loadCoreData()
    }

    func updateCoreData(file: LocalFile) {
        if let currentPublication = publicationsCD.first(where: {$0.filename == file.filename}) {
            
            currentPublication.filename = file.filename
            currentPublication.dateModified = Date()
            currentPublication.rank = file.rank!
            currentPublication.title = file.title
            currentPublication.year = file.year!
            currentPublication.note = file.note
            
            if authorsCD.first(where: {$0.name == file.author}) == nil {
                let newAuthor = Author(context: context)
                newAuthor.name = authorString.text
                newAuthor.sortNumber = "1"
                print("Added new author: " + newAuthor.name!)
                currentPublication.author = newAuthor
            } else {
                currentPublication.author = authorsCD.first(where: {$0.name == file.author})
            }
            
            if journalsCD.first(where: {$0.name == file.journal}) == nil {
                let newJournal = Journal(context: context)
                newJournal.name = journalString.text
                newJournal.sortNumber = "1"
                print("Added new journal: " + newJournal.name!)
                currentPublication.journal = newJournal
            } else {
                currentPublication.journal = journalsCD.first(where: {$0.name == file.journal})
                print("Added to journal: " + (currentPublication.journal?.name)!)
            }
            
            for group in file.groups {
                if let tmp = publicationGroupsCD.first(where: {$0.tag == group}) {
                    currentPublication.addToPublicationGroup(tmp) //Assume (for now) that all groups can be found in publicationGroupsCD
                } else {
                    let newGroup = PublicationGroup(context: context)
                    newGroup.tag = group
                    newGroup.sortNumber = "3"
                    newGroup.dateModified = Date()
                    print("Added new group: " + newGroup.tag!)
                    currentPublication.addToPublicationGroup(newGroup)
                }
            }
            
            saveCoreData()
            loadCoreData()
            
        } else {
            // A FILE FOUND IN FOLDER BUT NOT SAVED INTO CORE DATA
            addFileToCoreData(file: file)
        }
    }
    
    
    
    
    
    
    // MARK: - GENERAL FUNCTIONS
    func setupUI() {

        filesDownloading = []
        
        for _ in 0..<categories.count {
            let tmp = SelectedFile(category: nil, filename: nil, indexPathCV: [nil])
            selectedFile.append(tmp)
        }
        
        privateDatabase = container().privateCloudDatabase
        recordZone = CKRecordZone(zoneName: "CleanResearchZone")

        if let zone = recordZone {
            privateDatabase?.save(zone, completionHandler: { (recordzone, error) in
                if (error != nil) {
                    print(error!)
                    print("Failed to create custom record zone")
                } else {
                    print("Saved record zone ID")
                }
            })
        }
        
        kvStorage = NSUbiquitousKeyValueStore()
        loadDefaultValues()
        
        
        switch categories[selectedCategoryNumber] {
        case "Economy":
            economyView.isHidden = false
            filesCollectionView.isHidden = true
            segmentedControllTablesOrNotes.isHidden = true
            economyHeader.isHidden = false
            addNewGroupText.setTitle("New project", for: .normal)
            sortSTButton.isHidden = true
        default:
            economyView.isHidden = true
            segmentedControllTablesOrNotes.isHidden = false
            economyHeader.isHidden = true
            addNewGroupText.setTitle("New tag", for: .normal)
            filesCollectionView.isHidden = false
            sortSTButton.isHidden = false
        }
        
        readIcloudDriveFolders()
        
        loadCoreData()
        setupDefaultCoreDataTypes()
        loadIcloudData() // compareLocalFilesWithDatabase() runs here
        
        setThemeColor()
        
    }
    
    func updateDatabasesWithNewFileInformation() {
        activityIndicator.startAnimating()
        switch categories[selectedCategoryNumber] {
        case "Publications":
            
            // UPDATING LOCALFILES
            let currentFile = updateLocalFiles()
            loadingString.text = "Uploading " + (currentFile?.filename)!

            // UPDATING CORE DATA
            updateCoreData(file: currentFile!)
            
            // UPDATING ICLOUD
            updateIcloud(file: currentFile!)

            populateListTable()
            populateFilesCV()
            sortFiles()
            listTableView.reloadData()
            filesCollectionView.reloadData()

            activityIndicator.stopAnimating()
            loadingString.text = ""

        default:
            print("Default 137")
        }
    }
    
    func compareLocalFilesWithDatabase() {
        
        loadingString.text = "Comparing with databases"
        
        for i in 0..<localFiles[selectedCategoryNumber].count {
//            print("Searching for file: " + localFiles[selectedCategoryNumber][i].filename + " in databases.")

            var icloudMatch = false
            var icloudFile: PublicationFile!
            var coreDataMatch = false
            var coreDataFile: Publication!
            
            //SEARCH ICLOUD
            if let matchedIcloudFile = publicationsIC.first(where: {$0.filename == localFiles[0][i].filename}) {
                icloudFile = matchedIcloudFile
                icloudMatch = true
            }
            
            //SEARCH COREDATA
            if let matchedCoreDataFile = publicationsCD.first(where: {$0.filename == localFiles[0][i].filename}) {
                coreDataFile = matchedCoreDataFile
                coreDataMatch = true
//                print("File: " + localFiles[0][i].filename + " found in coredata")
            } else {
//                print("File: " + localFiles[0][i].filename + " not matched with coredata")
            }
            
            if icloudMatch && coreDataMatch {
                if coreDataFile.dateModified! > icloudFile.dateModified! {
//                    print("Load 1")
                    updateLocalFilesWithCoreData(index: i, category: selectedCategoryNumber, coreDataFile: coreDataFile)
                } else {
//                    print("Load 2")
                    updateLocalFilesWithIcloud(index: i, category: selectedCategoryNumber, icloudFile: icloudFile)
                }
            } else {
                if icloudMatch || coreDataMatch {
                    if icloudMatch {
//                        print("Load 3")
                        updateLocalFilesWithIcloud(index: i, category: selectedCategoryNumber, icloudFile: icloudFile)
                    } else {
//                        print("Load 4")
                        updateLocalFilesWithCoreData(index: i, category: selectedCategoryNumber, coreDataFile: coreDataFile)
                    }
                } else {
//                    print("Load 5")
                    addFileToCoreData(file: localFiles[0][i])
                }
            }

            
        }
        
        print("Comparison ended")
        activityIndicator.stopAnimating()
        loadingString.text = ""
    }
    
    func updateLocalFilesWithIcloud(index: Int, category: Int, icloudFile: Any) {
        switch category {
        case 0:
            let currentIcloudFile = icloudFile as! PublicationFile
            localFiles[category][index].year = currentIcloudFile.year
//            localFiles[category][index].title = currentIcloudFile.title!
            localFiles[category][index].rank = currentIcloudFile.rank
            localFiles[category][index].note = currentIcloudFile.note!
            localFiles[category][index].dateCreated = currentIcloudFile.dateCreated!
            localFiles[category][index].dateModified = currentIcloudFile.dateModified!
            localFiles[category][index].favorite = currentIcloudFile.favorite!
            
            if currentIcloudFile.author != nil {
                localFiles[category][index].author = currentIcloudFile.author!
                if authorsCD.first(where: {$0.name == currentIcloudFile.author}) == nil {
                    let newAuthor = Author(context: context)
                    newAuthor.name = currentIcloudFile.author
                    newAuthor.sortNumber = "1"
                    print("Added new author: " + newAuthor.name!)
                    saveCoreData()
                    loadCoreData()
                }
            } else {
                localFiles[category][index].author = "No author"
            }
            
            
            if currentIcloudFile.journal != nil {
                localFiles[category][index].journal = currentIcloudFile.journal!
                if journalsCD.first(where: {$0.name == currentIcloudFile.journal}) == nil {
                    let newJournal = Journal(context: context)
                    newJournal.name = currentIcloudFile.journal
                    newJournal.sortNumber = "1"
                    print("Added new journal: " + newJournal.name!)
                    saveCoreData()
                    loadCoreData()
                }
            } else {
                localFiles[category][index].journal = "No journal"
            }
            
            localFiles[category][index].groups = currentIcloudFile.groups
            print("Icloud file: " + localFiles[category][index].filename)
            
            //Update Core data with just updated localFiles
            updateCoreData(file: localFiles[category][index])
            
        default:
            print("Default 131")
        }
    }
    
    func updateLocalFilesWithCoreData(index: Int, category: Int, coreDataFile: Any) {
        //FIX: If "publications" isn't loaded first, the files are not correctly read.
        switch category {
        case 0:
            let currentCoreDataFile = coreDataFile as! Publication
            localFiles[category][index].year = currentCoreDataFile.year
            localFiles[category][index].title = currentCoreDataFile.title!
            localFiles[category][index].rank = currentCoreDataFile.rank
            localFiles[category][index].note = currentCoreDataFile.note!
            localFiles[category][index].dateCreated = currentCoreDataFile.dateCreated!
            localFiles[category][index].dateModified = currentCoreDataFile.dateModified!
            
            if localFiles[category][index].thumbnail == #imageLiteral(resourceName: "fileIcon.png") {
                if let thumbnail = currentCoreDataFile.thumbnail as? UIImage {
                    localFiles[category][index].thumbnail = thumbnail
                }
            }
            
            if let author = currentCoreDataFile.author?.name {
                localFiles[category][index].author = author
            } else {
                localFiles[category][index].author = "No author"
            }
            
            if let journal = currentCoreDataFile.journal?.name {
                localFiles[category][index].journal = journal
            } else {
                localFiles[category][index].journal = "No journal"
            }

            localFiles[category][index].favorite = "No"
            for group in currentCoreDataFile.publicationGroup?.allObjects as! [PublicationGroup] {
                localFiles[category][index].groups.append(group.tag)
                if group.tag == "Favorites" {
                    localFiles[category][index].favorite = "Yes"
                }
            }

        default:
            print("Default 130")
        }
    }
    
    func getURL() -> URL {
        let baseURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)
//        let fullURL = baseURL?.appendingPathComponent("Documents/test.txt")
        let fullURL = baseURL?.appendingPathComponent("Documents", isDirectory: true)

        return fullURL!
    }
    
    func isStringAnInt(stringNumber: String?) -> Int32 {
//        let trimmedString = stringNumber!.trimmingCharacters(in: .whitespaces)
        let number = stringNumber?.replacingOccurrences(of: "\"", with: "")
//        let intValue = (stringNumber! as NSString).intValue
//        print(intValue + 1)
//        return Int16(intValue)
//        print(number)
//        let intValue = Int16(number)
//        print(intValue)
        if let tmpValue = Int32(number!) {
            return tmpValue
        }
//        print(number)
        print("String number could not be converted")
        return -2000
    }

    func downloadFile(fileURL: URL) {
        
        print(fileURL)
        var newFileURL: URL!
        
        URLSession.shared.dataTask(with: fileURL) { data, response, error in
            guard let data = data, error == nil else {return}
            
            switch self.categories[self.selectedCategoryNumber] {
            case "Publications":
                newFileURL = self.publicationsURL.appendingPathComponent(fileURL.lastPathComponent)
            default:
                print("102")
            }
            
            // write temporary file to disk/icloud folder
            do {
                try data.write(to: newFileURL)
                print("Successfully saved file to iCloud Drive")
            } catch {
                print(error)
            }
            
            DispatchQueue.main.async {
                self.documentInteractionController.url = newFileURL
                self.documentInteractionController.uti = fileURL.typeIdentifier ?? "public.data, public.content"
                self.documentInteractionController.name = fileURL.localizedName ?? fileURL.lastPathComponent
                self.documentInteractionController.presentOptionsMenu(from: self.view.frame, in: self.view, animated: true)
            }
            }.resume()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "segueSortSubtable") {
            let destination = segue.destination as! SortSubtableViewController
            destination.sortValue = selectedSortingNumber
            destination.sortStrings = sortSubtableStrings
            destination.preferredContentSize = sortTableListBox
            destination.popoverPresentationController?.sourceRect = sortSTButton.bounds
        }
        if (segue.identifier == "segueSortCV") {
            let destination = segue.destination as! SortCVViewController
            destination.sortValue = selectedSortingCVNumber
            destination.sortStrings = sortCVStrings
            destination.preferredContentSize = sortTableListBox
            destination.popoverPresentationController?.sourceRect = sortCVButton.bounds
        }
        if (segue.identifier == "seguePDFViewController") {
            let destination = segue.destination as! PDFViewController
            destination.document = PDFdocument
            destination.PDFfilename = PDFfilename
            destination.pdfURL = publicationsURL
            destination.annotationSettings = annotationSettings
        }
        if (segue.identifier == "segueSettingsCV") {
            let destination = segue.destination as! SettingsViewController
            destination.currentTheme = currentTheme //UPDATE TO CURRENT VALUE
            destination.preferredContentSize = settingsCollectionViewBox
            destination.popoverPresentationController?.sourceRect = settingsButton.bounds
        }
        if (segue.identifier == "segueInvoiceVC") {
            let destination = segue.destination as! InvoiceViewController
            destination.invoiceURL = economyURL
        }
        
    }
    
    func addFileToCoreData(file: LocalFile) {
        switch categories[selectedCategoryNumber] {
        case "Publications":
            let newPublication = Publication(context: context)
            
            newPublication.filename = file.filename
            newPublication.thumbnail = getThumbnail(url: publicationsURL.appendingPathComponent(filenameString.text!), pageNumber: 0)
            newPublication.dateCreated = file.dateCreated
            newPublication.dateModified = file.dateModified
            newPublication.title = file.title
            newPublication.year = file.year!
            newPublication.note = file.note
            
            let favoriteGroup = publicationGroupsCD.first(where: {$0.tag == "Favorites"})
            if file.favorite == "Yes" {
                newPublication.favorite = "Yes"
                newPublication.addToPublicationGroup(favoriteGroup!)
            } else {
                newPublication.favorite = "No"
                newPublication.removeFromPublicationGroup(favoriteGroup!)
            }

            if authorsCD.first(where: {$0.name == file.author}) == nil {
                let newAuthor = Author(context: context)
                newAuthor.name = authorString.text
                newAuthor.sortNumber = "1"
                print("Added new author: " + newAuthor.name!)
                newPublication.author = newAuthor
                
                saveCoreData()
                loadCoreData()
            } else {
                newPublication.author = authorsCD.first(where: {$0.name == file.author})
            }
            
            if journalsCD.first(where: {$0.name == file.journal}) == nil {
                let newJournal = Journal(context: context)
                newJournal.name = journalString.text
                newJournal.sortNumber = "1"
                print("Added new journal: " + newJournal.name!)
                newPublication.journal = newJournal
                
                saveCoreData()
                loadCoreData()
            } else {
                newPublication.journal = journalsCD.first(where: {$0.name == file.journal})
            }

            for group in file.groups {
                if let tmp = publicationGroupsCD.first(where: {$0.tag == group}) {
                    newPublication.addToPublicationGroup(tmp)
                } else {
                    let newGroup = PublicationGroup(context: context)
                    newGroup.tag = group
                    newGroup.dateModified = Date()
                    newGroup.sortNumber = "3"
                    print("Added new group: " + newGroup.tag!)
                    newPublication.addToPublicationGroup(newGroup)
                    
                    saveCoreData()
                    loadCoreData()
                }
            }
            
            publicationsCD.append(newPublication)
            
            saveCoreData()
            loadCoreData()
            
            print("Saved " + newPublication.filename! + " to core data.")
            
        default:
            print("Error at saveFileToCoreData()")
        }
    }
    
    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func getThumbnail(url: URL, pageNumber: Int) -> UIImage {
        var pageThumbnail = #imageLiteral(resourceName: "FileOffline")
        if url.lastPathComponent.range(of:".jpg") != nil {
            pageThumbnail = #imageLiteral(resourceName: "JpgIcon")
            if url.lastPathComponent.range(of:".icloud") == nil {
                if let data = try? Data(contentsOf: url) {
                    pageThumbnail = UIImage(data: data)!
                }
            }

        } else if url.lastPathComponent.range(of:".pdf") != nil {
            if let document = PDFDocument(url: url) {
                let page: PDFPage!
                page = document.page(at: pageNumber)!
                pageThumbnail = page.thumbnail(of: CGSize(width: 210, height: 297), for: .artBox)
            }
        } else if url.lastPathComponent.range(of:".pptx") != nil || url.lastPathComponent.range(of:".ppt") != nil {
            pageThumbnail = #imageLiteral(resourceName: "PowerpointIcon")
        } else if url.lastPathComponent.range(of:".docx") != nil || url.lastPathComponent.range(of:".doc") != nil {
            pageThumbnail = #imageLiteral(resourceName: "WordIcon")
        } else if url.lastPathComponent.range(of:".xlsx") != nil {
            pageThumbnail = #imageLiteral(resourceName: "ExcelIcon")
        } else if url.lastPathComponent.range(of:".key") != nil {
            pageThumbnail = #imageLiteral(resourceName: "KeynoteIcon")
        }
        return pageThumbnail
    }
    
    func assignPublicationToAuthor(filename: String, authorName: String) {
        
        // LOCAL FILES
        for i in 0..<localFiles[0].count {
            if localFiles[0][i].filename == filename {
                localFiles[0][i].author = authorName
                updateIcloud(file: localFiles[0][i])
                updateCoreData(file: localFiles[0][i])
            }
        }
        
    }
    
    func assignPublicationToJournal(filename: String, journalName: String) {

        switch categories[selectedCategoryNumber] {
        case "Publications":

            // LOCAL FILES
            for i in 0..<localFiles[0].count {
                if localFiles[0][i].filename == filename {
                    localFiles[0][i].journal = journalName
                    
                    updateIcloud(file: localFiles[0][i])
                    updateCoreData(file: localFiles[0][i])
                }
            }
        default:
            print("Default 142")
        }
    }
    
    func addPublicationToGroup(filename: String, group: PublicationGroup) {
        // LOCAL FILES & iCLOUD
        for i in 0..<localFiles[0].count {
            if localFiles[0][i].filename == filename {
                localFiles[0][i].groups.append(group.tag)
                updateIcloud(file: localFiles[0][i])
                updateCoreData(file: localFiles[0][i])
            }
        }
    }
    
    func updateCurrentSelectedFile(indexPath: IndexPath) {
        
        print("updateCurrentSelectedFile")
        selectedFile[selectedCategoryNumber].category = categories[selectedCategoryNumber]
        selectedFile[selectedCategoryNumber].filename = currentSelectedFilename!
        selectedFile[selectedCategoryNumber].indexPathCV = [indexPath]

        print(selectedFile[selectedCategoryNumber])
    }
    
    func attemptScrolling() {
        print("attemptScrolling")
        print(selectedFile[selectedCategoryNumber])
        if selectedFile[selectedCategoryNumber].indexPathCV[0] != nil {
            selectedSubtableNumber = (selectedFile[selectedCategoryNumber].indexPathCV[0]?.section)!
            self.filesCollectionView.scrollToItem(at: IndexPath(row: (selectedFile[selectedCategoryNumber].indexPathCV[0]?.row)!, section: (selectedFile[selectedCategoryNumber].indexPathCV[0]?.section)!), at: .top, animated: true)
//            self.listTableView.scrollToRow(at: IndexPath(row: 0, section: (selectedFile[selectedCategoryNumber].indexPathCV[0]?.section)!), at: .top, animated: true)
//            self.listTableView.selectRow(at: IndexPath(row:0, section: (selectedFile[selectedCategoryNumber].indexPathCV[0]?.section)!), animated: true, scrollPosition: .top)
            selectedSubtableNumber = (selectedFile[selectedCategoryNumber].indexPathCV[0]?.section)!
        } else {
            selectedSubtableNumber = 0
            if !sortTableTitles.isEmpty {
                self.listTableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .top)
            }
        }

    }
    
    
    
    
    // MARK: - Table view
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == self.expensesTableView {
            if selectedSubtableNumber < projectCD.count {
                return (projectCD[selectedSubtableNumber].expense?.count)!
            } else {
                return 0
            }
        } else {
            return sortTableTitles.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 5
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        var number = 1
        if tableView == self.expensesTableView {
            number = 1
        } else if tableView == self.listTableView {
            switch categories[selectedCategoryNumber] {
            case "Publications":
                return 1
                
            case "Manuscripts", "Presentations", "Proposals", "Supervision", "Teaching", "Patents", "Courses", "Miscellaneous":
                if !sortTableTitles.isEmpty {
                    return 1
                } else {
                    return 0
                }

            case "Economy":
                number = 1
                
            default:
                print("Default 135")
                number = 1
            }
        }
        return number
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cellToReturn = UITableViewCell()
        
        if tableView == self.expensesTableView {
            let cell = expensesTableView.dequeueReusableCell(withIdentifier: "economyCell") as! EconomyCell
            let currentProject = projectCD[selectedSubtableNumber]
            
            if indexPath.section == 0 {
                currentProject.amountRemaining = currentProject.amountReceived
            }
            tableView.backgroundColor = UIColor.clear
            var expenses = currentProject.expense?.allObjects as! [Expense]
            expenses = expenses.sorted(by: {$0.dateAdded! > $1.dateAdded!})
            
            cell.setExpense(expense: expenses[indexPath.section])
            cell.delegate = self
            
            cell.backgroundColor = UIColor.clear
            cell.layer.borderColor = UIColor.black.cgColor
            cell.layer.borderWidth = 1
            cell.layer.cornerRadius = 8
            cell.clipsToBounds = true
            if expenses[indexPath.section].active {
                cell.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
                let overhead = Int32(0.01*Float(expenses[indexPath.section].amount)*Float(expenses[indexPath.section].overhead))
                currentProject.amountRemaining = currentProject.amountRemaining - expenses[indexPath.section].amount - overhead
            } else {
                cell.backgroundColor = #colorLiteral(red: 0.9568627477, green: 0.6588235497, blue: 0.5450980663, alpha: 1)
            }
            amountRemainingString.text = "\(currentProject.amountRemaining)"
            
            cellToReturn = cell

        } else if tableView == self.listTableView {
            
            let cell = listTableView.dequeueReusableCell(withIdentifier: "listTableCell") as! ListCell
            
            switch categories[selectedCategoryNumber] {
            case "Publications":
                cell.listLabel.text = sortTableTitles[indexPath.section]
                cell.listNumberOfItems.text = "\(filesCV[indexPath.section].count)"
                
                cell.backgroundColor = UIColor.white
                cell.layer.borderColor = UIColor.black.cgColor
                cell.layer.borderWidth = 1
                cell.layer.cornerRadius = 8
                cell.clipsToBounds = true
                
            case "Economy":
                cell.listLabel.text = sortTableTitles[indexPath.section]
                cell.listNumberOfItems.text = ""
                cell.backgroundColor = UIColor.white
                cell.layer.borderColor = UIColor.black.cgColor
                cell.layer.borderWidth = 1
                cell.layer.cornerRadius = 8
                cell.clipsToBounds = true
                
            case "Manuscripts", "Presentations", "Proposals", "Supervision", "Teaching", "Patents", "Courses", "Miscellaneous":
                cell.listLabel.text = sortTableTitles[indexPath.section]
                cell.listNumberOfItems.text = ""

            default:
                cell.listLabel.text = "Nothing yet..."
                cell.listNumberOfItems.text = "0 items"
            }
            cellToReturn = cell
        }
        
        return cellToReturn
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == self.listTableView {
            selectedSubtableNumber = indexPath.section
            
            switch categories[selectedCategoryNumber] {
            case "Publications":
                if filesCV[indexPath.section].count > 0 {
                    let cvIndexPath = IndexPath(item: 0, section: indexPath.section) //Is this correct?
                    self.filesCollectionView.scrollToItem(at: cvIndexPath, at: .top, animated: true)
                }
                
            case "Economy":
                let currentProject = projectCD[selectedSubtableNumber]
                currencyString.text = currentProject.currency
                amountReceivedString.text = "\(currentProject.amountReceived)"
                amountRemainingString.text = "\(currentProject.amountRemaining)"
                
                self.expensesTableView.reloadData()
                
            case "Manuscripts", "Presentations", "Proposals", "Supervision", "Teaching", "Patents", "Courses", "Miscellaneous":
                
                currentIndexPath = indexPath
                self.filesCollectionView.reloadData()
//                if filesCV[indexPath.section].count > 0 {
//                    let cvIndexPath = IndexPath(item: 0, section: indexPath.row)
//                    self.filesCollectionView.scrollToItem(at: cvIndexPath, at: .top, animated: true)
//                }
            default:
                print("Default 146")
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        print(coordinator.items[0].dragItem.localObject)
        if tableView == self.listTableView {
            switch categories[selectedCategoryNumber] {
            case "Publications":
                if let section = coordinator.destinationIndexPath?.section {
                    switch sortSubtableStrings[selectedSortingNumber] {
                    case "Tag":
                        let groupName = sortTableTitles[section]
                        if let filename = coordinator.items[0].dragItem.localObject {
                            if let dragedPublication = filesCV[selectedSubtableNumber].first(where: {$0.filename == filename as! String}) {
                                if let group = publicationGroupsCD.first(where: {$0.tag! == groupName}) {
                                    addPublicationToGroup(filename: (dragedPublication.filename), group: group)
                                }
                            }
                        }
                    case "Author":
                        let authorName = sortTableTitles[section]
                        if let filename = coordinator.items[0].dragItem.localObject {
                            if let dragedPublication = localFiles[0].first(where: {$0.filename == filename as! String}) {
                                assignPublicationToAuthor(filename: (dragedPublication.filename), authorName: authorName)
                            }
                        }
                    case "Journal":
                        let journalName = sortTableTitles[section]
                        if let filename = coordinator.items[0].dragItem.localObject {
                            if let dragedPublication = localFiles[0].first(where: {$0.filename == filename as! String}) {
                                assignPublicationToJournal(filename: (dragedPublication.filename), journalName: journalName)
                            }
                        }
                    case "Year":
                        let year = sortTableTitles[section]
                        if let filename = coordinator.items[0].dragItem.localObject {
                            for i in 0..<localFiles[0].count {
                                if localFiles[0][i].filename == filename as! String {
                                    localFiles[0][i].year = Int16(isStringAnInt(stringNumber: year))
                                    
                                    updateIcloud(file: localFiles[0][i])
                                    updateCoreData(file: localFiles[0][i])
                                }
                            }
                        }
                    default:
                        print("Default 141")
                    }
                }
            default:
                print("Default 142")
            }
            
            populateFilesCV()
            sortFiles()
            listTableView.reloadData()
            filesCollectionView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        var returnBool = false
        
        if tableView == self.listTableView {
            switch categories[selectedCategoryNumber] {
            case "Publications":
                switch sortSubtableStrings[selectedSortingNumber] {
                case "Tag":
                    if indexPath.section > 1 {
                        returnBool = true
                    } else {
                        returnBool = false
                    }
                case "Author":
                    if indexPath.section > 0 {
                        returnBool = true
                    } else {
                        returnBool = false
                    }
                case "Journal":
                    if indexPath.section > 0 {
                        returnBool = true
                    } else {
                        returnBool = false
                    }
                case "Year":
                    returnBool = false
                case "Rank":
                    returnBool = false
                default:
                    returnBool = false
                }
            
            case "Manuscripts":
                returnBool = false
            
            case "Economy":
                returnBool = true
                
            default:
                returnBool = false
            }
        } else if tableView == self.expensesTableView {
            returnBool = true
        }
        return returnBool
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            
            if tableView == self.listTableView {
                //UPDATE selectedItem and selectedItemName for correct selected row
                
                switch categories[selectedCategoryNumber] {
                case "Publications":
                    if sortSubtableStrings[selectedSortingNumber] == "Tag" {
                        let groupName = sortTableTitles[indexPath.section]
                        let groupToDelete = publicationGroupsCD.first(where: {$0.tag! == groupName})
                        context.delete(groupToDelete!)
                        
                        saveCoreData()
                        loadCoreData()
                        
                        populateListTable()
                        populateFilesCV()
                        sortFiles()
                        
                        listTableView.reloadData()
                        filesCollectionView.reloadData()
                        
                    } else if sortSubtableStrings[selectedSortingNumber] == "Author" {
                        let noAuthor = authorsCD.first(where: {$0.name == "No author"})
                        let authorName = sortTableTitles[indexPath.section]
                        let authorToDelete = authorsCD.first(where: {$0.name! == authorName})
                        let articlesBelongingToAuthor = authorToDelete?.publication
                        context.delete(authorToDelete!)
                        for item in articlesBelongingToAuthor! {
                            let tmp = item as! Publication
                            tmp.author = noAuthor
                        }
                        
                        saveCoreData()
                        loadCoreData()
                        
                        populateListTable()
                        populateFilesCV()
                        sortFiles()
                        
                        listTableView.reloadData()
                        filesCollectionView.reloadData()
                        
                    } else if sortSubtableStrings[selectedSortingNumber] == "Journal" {
                        
                        let noJournal = journalsCD.first(where: {$0.name == "No journal"})
                        let journalName = sortTableTitles[indexPath.section]
                        let journalsToDelete = journalsCD.first(where: {$0.name == journalName})
                        let articlesBelongingToJournal = journalsToDelete?.publication
                        context.delete(journalsToDelete!)
                        for item in articlesBelongingToJournal! {
                            let tmp = item as! Publication
                            tmp.journal = noJournal
                        }
                        
                        saveCoreData()
                        loadCoreData()
                        
                        populateListTable()
                        populateFilesCV()
                        sortFiles()
                        
                        listTableView.reloadData()
                        filesCollectionView.reloadData()
                    }

                    
                case "Economy":
                    let currentProject = sortTableTitles[indexPath.section]
                    let projectToDelete = projectCD.first(where: {$0.name! == currentProject})
                    context.delete(projectToDelete!)
                    
                    saveCoreData()
                    loadCoreData()

                    populateListTable()
                    categoriesCV.reloadData()
                    self.categoriesCV.selectItem(at: IndexPath(row: self.selectedCategoryNumber, section: 0), animated: true, scrollPosition: .top)
                    listTableView.reloadData()
                    expensesTableView.reloadData()
                    
                default:
                    print("Default 104")
                }
                
                
            } else if tableView == self.expensesTableView {
                let currentProject = projectCD[selectedSubtableNumber]
                var expenses = currentProject.expense?.allObjects as! [Expense]
                
                amountRemainingString.text = "\(currentProject.amountReceived)"
                
                let expenseToRemove = expensesCD.first(where: {$0.dateAdded! == expenses[indexPath.section].dateAdded!})
                context.delete(expenseToRemove!)
                
                saveCoreData()
                loadCoreData()
                
                expensesTableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        if tableView == self.expensesTableView {
            let currentProject = projectCD[selectedSubtableNumber]
            var expenses = currentProject.expense?.allObjects as! [Expense]
            expenses = expenses.sorted(by: {$0.dateAdded! > $1.dateAdded!})
            currentExpense = expenses[indexPath.section]
            
            var label = "Remove PDF"
            if self.currentExpense.pdfURL == nil {
                label = "Add PDF"
            }
            let handlePDFAction = UIContextualAction(style: .normal, title: label) { (action, view, nil) in
                if label == "Add PDF" {
                    self.performSegue(withIdentifier: "segueInvoiceVC", sender: self)
                } else {
                    self.currentExpense.pdfURL = nil
                    self.saveCoreData()
                    self.loadCoreData()
                    self.expensesTableView.reloadData()
                }
            }
            
            var activeText = "Include"
            if self.currentExpense.active {
                activeText = "Skip"
            }
            
            let skipAction = UIContextualAction(style: .normal, title: activeText) { (action, view, nil) in
                self.currentExpense.active = !self.currentExpense.active
                self.saveCoreData()
                self.loadCoreData()
                
                self.expensesTableView.reloadData()
            }
            
            let editAction = UIContextualAction(style: .normal, title: "Edit") { (action, view, nil) in
                let editExpense = UIAlertController(title: "Edit expense", message: "Edit expense data", preferredStyle: .alert)
                editExpense.addTextField(configurationHandler: { (editExpense: UITextField) -> Void in
                    editExpense.text = "\(self.currentExpense.amount)"
                })
                editExpense.addTextField(configurationHandler: { (inputNewProject: UITextField) -> Void in
                    inputNewProject.text = "\(self.currentExpense.overhead)"
                })
                editExpense.addTextField(configurationHandler: { (inputNewProject: UITextField) -> Void in
                    inputNewProject.text = self.currentExpense.reference
                })
                editExpense.addTextField(configurationHandler: { (inputNewProject: UITextField) -> Void in
                    inputNewProject.text = self.currentExpense.comment
                })
                editExpense.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                    let amount = editExpense.textFields?[0].text
                    let overhead = editExpense.textFields?[1].text
                    let reference = editExpense.textFields?[2].text
                    let comment = editExpense.textFields?[3].text
                    
                    self.currentExpense.amount = self.isStringAnInt(stringNumber: amount)
                    self.currentExpense.overhead = Int16(self.isStringAnInt(stringNumber: overhead))
                    self.currentExpense.reference = reference
                    self.currentExpense.comment = comment
                    
                    self.saveCoreData()
                    self.loadCoreData()
                    
                    self.expensesTableView.reloadData()
                    editExpense.dismiss(animated: true, completion: nil)
                }))
                editExpense.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                    editExpense.dismiss(animated: true, completion: nil)
                }))
                self.present(editExpense, animated: true, completion: nil)
            }
            
            editAction.backgroundColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
            handlePDFAction.backgroundColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
            skipAction.backgroundColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
            
            let configuration = UISwipeActionsConfiguration(actions: [editAction, handlePDFAction, skipAction])
            return configuration
           /*
        } else if tableView == self.listTableView {
            if categories[selectedCategoryNumber] == "Publications" {
                let editAction = UIContextualAction(style: .normal, title: "Edit") { (action, view, nil) in
                    var label = "Tag"
                    switch self.sortSubtableStrings[self.sortSubtableNumbers[self.selectedCategoryNumber]] {
                    case "Tag":
                        label = "tag"
                    case "Author":
                        label = "author"
                    case "Journal":
                        label = "journal"
                    default:
                        print("Default 149")
                    }
                    let editLabel = UIAlertController(title: "Edit " + label, message: nil, preferredStyle: .alert)
                    editLabel.addTextField(configurationHandler: { (editLabel: UITextField) -> Void in
                        editLabel.text = self.sortTableTitles[indexPath.section]
                    })
                    editLabel.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                        let newLabel = editLabel.textFields?[0].text
                        let oldLabel = self.sortTableTitles[indexPath.section]
                        switch self.sortSubtableStrings[self.sortSubtableNumbers[self.selectedCategoryNumber]] {
                        case "Tag":
                            for file in self.localFiles[0] {
                                if file.groups.first(where: {$0 == oldLabel}) != nil {
                                    print(file.filename)
                                    self.updateCoreData(file: file)
                                    self.updateIcloud(file: file)
                                    //WORK IN PROGRESS. HOW TO BEST UPDATE???
//                                    self.filesCV[indexPath.section].append(file)
                                }
//                                filesCV[indexPath.section] = filesCV[indexPath.section].sorted(by: {($0.filename) < ($1.filename)})
                            }
                        default:
                            print("Default 149")
                        }
             
                        editLabel.dismiss(animated: true, completion: nil)
                    }))
                    editLabel.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                        editLabel.dismiss(animated: true, completion: nil)
                    }))
                    self.present(editLabel, animated: true, completion: nil)
                }
             
                editAction.backgroundColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
             
                let configuration = UISwipeActionsConfiguration(actions: [editAction])
                return configuration
            }
            else {
                return nil
            }
            */
        } else {
            return nil
        }
        
    }
    
 
    
    
    // MARK: - Collection View
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == self.categoriesCV {
            return categories.count
        } else {
            switch categories[selectedCategoryNumber] {
            case "Publications":
                return filesCV[section].count
            case "Manuscripts", "Presentations", "Proposals", "Supervision", "Teaching", "Patents", "Courses", "Miscellaneous":
                return docCV[selectedSubtableNumber].files[section].count
            default:
                return 0
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == self.categoriesCV {
//            selectedSubtableNumber = 0 //When jumping between different categories, invalid values might be set to this
//            currentIndexPath = IndexPath(row: 0, section: 0)
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "categoryCell", for: indexPath) as! categoryCell
            switch categories[indexPath.row] {
                
            case "Publications":
                cell.icon.image = #imageLiteral(resourceName: "PublicationsIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "PublicationsIconSelected")
                cell.number.text = "\(localFiles[0].count)"

            case "Economy":
                cell.icon.image = #imageLiteral(resourceName: "EconomyIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "EconomyIconSelected")
                cell.number.text = "\(projectCD.count)"
                
            case "Manuscripts":
                cell.icon.image = #imageLiteral(resourceName: "ManuscriptsIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "ManuscriptsIconSelected")
                cell.number.text = "\(localFiles[2].count)"

            case "Presentations":
                cell.icon.image = #imageLiteral(resourceName: "PresentationsIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "PresentationsIconSelected")
                cell.number.text = "\(localFiles[3].count)"

            case "Proposals":
                cell.icon.image = #imageLiteral(resourceName: "ProposalsIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "ProposalsIconSelected")
                cell.number.text = "\(localFiles[4].count)"
                
            case "Supervision":
                cell.icon.image = #imageLiteral(resourceName: "SupervisionIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "SupervisionIconSelected")
                cell.number.text = "\(localFiles[5].count)"

            case "Teaching":
                cell.icon.image = #imageLiteral(resourceName: "TeachingIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "TeachingIconSelected")
                cell.number.text = "\(localFiles[6].count)"
                
            case "Patents":
                cell.icon.image = #imageLiteral(resourceName: "PatentsIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "PatentsIconSelected")
                cell.number.text = "\(localFiles[7].count)"

            case "Courses":
                cell.icon.image = #imageLiteral(resourceName: "CoursesIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "CoursesIconSelected")
                cell.number.text = "\(localFiles[8].count)"

            case "Miscellaneous":
                cell.icon.image = #imageLiteral(resourceName: "MiscellaneousIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "MiscellaneousIconSelected")
                cell.number.text = "\(localFiles[9].count)"
                
            default:
                print("Default 144")
                cell.icon.image = #imageLiteral(resourceName: "PublicationsIcon")
                cell.number.text = "0"
            }
            
            selectedCategoryTitle.text = categories[selectedCategoryNumber]
            
            switch currentTheme {
            case 0:
                cell.number.backgroundColor = UIColor(red: 146/255, green: 144/255, blue: 0, alpha: 1)
                cell.number.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
            case 1:
                cell.number.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
                cell.number.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
            case 2:
                cell.number.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
                cell.number.textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
            default:
                cell.number.backgroundColor = UIColor(red: 146/255, green: 144/255, blue: 0, alpha: 1)
            }

            return cell
            
        } else {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "filesCell", for: indexPath) as! FilesCell

            cell.backgroundColor = UIColor.white
            cell.layer.borderColor = UIColor.black.cgColor
            cell.layer.borderWidth = 1
            cell.layer.cornerRadius = 8
            cell.clipsToBounds = true

            switch categories[selectedCategoryNumber] {
            case "Publications":
                cell.thumbnail.image = filesCV[indexPath.section][indexPath.row].thumbnail
                cell.label.text = filesCV[indexPath.section][indexPath.row].filename

//                cell.backgroundColor = UIColor.white
//                cell.layer.borderColor = UIColor.black.cgColor
//                cell.layer.borderWidth = 1
//                cell.layer.cornerRadius = 8
//                cell.clipsToBounds = true

                if filesCV[indexPath.section][indexPath.row].favorite == "Yes" {
                    cell.favoriteIcon.isHidden = false
                } else {
                    cell.favoriteIcon.isHidden = true
                }

                if filesCV[indexPath.section][indexPath.row].available {
                    cell.fileOffline.isHidden = true
                } else {
                    cell.fileOffline.isHidden = false
                }
                
                if editingFilesCV {
                    cell.deleteIcon.isHidden = false
                } else {
                    cell.deleteIcon.isHidden = true
                }
                
                if cell.label.text == currentSelectedFilename {
                    cell.layer.borderColor = UIColor.yellow.cgColor
                    cell.layer.borderWidth = 3
                    
                } else {
                    cell.layer.borderColor = UIColor.black.cgColor
                    cell.layer.borderWidth = 1
                }

            case "Manuscripts", "Presentations", "Proposals", "Supervision", "Teaching", "Patents", "Courses", "Miscellaneous":
                cell.label.text = docCV[selectedSubtableNumber].files[indexPath.section][indexPath.row].filename
                cell.thumbnail.image = docCV[selectedSubtableNumber].files[indexPath.section][indexPath.row].thumbnail
                cell.favoriteIcon.isHidden = true
                cell.deleteIcon.isHidden = true
//                cell.backgroundColor = UIColor.white

                if cell.label.text == currentSelectedFilename {
                    cell.layer.borderColor = UIColor.yellow.cgColor
                    cell.layer.borderWidth = 3
                    
                } else {
                    cell.layer.borderColor = UIColor.black.cgColor
                    cell.layer.borderWidth = 1
                }
                
                if docCV[selectedSubtableNumber].files[indexPath.section][indexPath.row].available {
                    cell.fileOffline.isHidden = true
                } else {
                    cell.fileOffline.isHidden = false
                }
                

            default:
                print("Default 107")
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        if collectionView == self.categoriesCV {
            selectedCategoryTitle.text = categories[indexPath.row]
            selectedCategoryNumber = indexPath.row
            
            let selectedOption = segmentedControllTablesOrNotes.titleForSegment(at: segmentedControllTablesOrNotes.selectedSegmentIndex)
            
            switch selectedOption! {
            case "List":
                notesView.isHidden = true
            case "Notes":
                switch categories[selectedCategoryNumber] {
                case "Publications":
                    notesView.isHidden = false
                case "Economy", "Manuscripts", "Presentations", "Proposals", "Supervision", "Teaching", "Patents", "Courses", "Miscellaneous":
                    notesView.isHidden = true
                default:
                    notesView.isHidden = false
                }
            default:
                print("Default 141")
            }
            
            switch categories[selectedCategoryNumber] {
            case "Publications":
                self.economyView.isHidden = true
                self.filesCollectionView.isHidden = false
                self.segmentedControllTablesOrNotes.isHidden = false
                self.economyHeader.isHidden = true
                self.addNewGroupText.isHidden = false
                self.addNewGroupText.setTitle("New tag", for: .normal)
                self.sortSTButton.isHidden = false
                if sortSubtableStrings[selectedSortingNumber] == "Tag" {
                    self.editButton.isHidden = false
                } else {
                    self.editButton.isHidden = true
                }

            case "Economy":
                self.economyView.isHidden = false
                self.filesCollectionView.isHidden = true
                self.segmentedControllTablesOrNotes.isHidden = true
                self.economyHeader.isHidden = false
                self.addNewGroupText.setTitle("New project", for: .normal)
                self.sortSTButton.isHidden = true
                self.editButton.isHidden = true
            default:
                self.economyView.isHidden = true
                self.filesCollectionView.isHidden = false
                self.segmentedControllTablesOrNotes.isHidden = true
                self.economyHeader.isHidden = false
                self.economyHeader.text = categories[selectedCategoryNumber]
                self.addNewGroupText.isHidden = true
                self.sortSTButton.isHidden = true
                self.editButton.isHidden = true
            }
            
            populateListTable()
            populateFilesCV()
            sortFiles()
            listTableView.reloadData()
            filesCollectionView.reloadData()

            
        } else {
            
            let currentCell = collectionView.cellForItem(at: indexPath) as! FilesCell
            currentSelectedFilename = currentCell.label.text
            
            if categories[selectedCategoryNumber] == "Publications" && editingFilesCV {
                
                if sortTableTitles[indexPath.section] != "All publications" {
                    for i in 0..<localFiles[0].count {
                        if localFiles[0][i].filename == currentCell.label.text {
                            let newGroups = localFiles[0][i].groups.filter { $0 !=  sortTableTitles[indexPath.section]}
                            localFiles[0][i].groups = newGroups
                            updateIcloud(file: localFiles[0][i])
                        }
                    }
                    if let currentPublication = publicationsCD.first(where: {$0.filename == currentCell.label.text}) {
                        if let group = publicationGroupsCD.first(where: {$0.tag == sortTableTitles[indexPath.section]}) {
                            currentPublication.removeFromPublicationGroup(group)
                            saveCoreData()
                            loadCoreData()
                        }
                    }
                    
                }
                
                populateListTable()
                populateFilesCV()
                sortFiles()
                listTableView.reloadData()
                filesCollectionView.reloadData()
                
                
            } else {
                
                if currentCell.fileOffline.isHidden == false {
                    print("Downloading " + currentCell.label.text!)
                    let fileManager = FileManager.default
                    var fileURL = publicationsURL.appendingPathComponent("." + currentCell.label.text! + ".icloud")
                    if categories[selectedCategoryNumber] != "Publications" {
                        fileURL = docCV[selectedSubtableNumber].files[indexPath.section][indexPath.row].url
                    }
                    
                    do {
                        try fileManager.startDownloadingUbiquitousItem(at: fileURL)
                        let newDownload = DownloadingFile(filename: currentCell.label.text!, url: fileURL, downloaded: false)
                        filesDownloading.append(newDownload)
                        downloadTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(checkIfFileIsDownloaded), userInfo: nil, repeats: true)
                        activityIndicator.startAnimating()
                        loadingString.text = "Downloading " + currentCell.label.text!
                    } catch let error {
                        print(error)
                    }
                }
                
                //Update "Notes view" with information
                if categories[selectedCategoryNumber] == "Publications" {
                    for i in 0..<localFiles[0].count {
                        if localFiles[0][i].filename == currentCell.label.text {
                            
                            currentCell.layer.borderColor = UIColor.gray.cgColor
                            currentCell.layer.borderWidth = 4
                            journalString.text = localFiles[0][i].journal
                            rankOutlet.value = localFiles[0][i].rank!
                            rankValue.text = "\(Int(localFiles[0][i].rank!))"
                            yearString.text = "\(localFiles[0][i].year!)"
                            authorString.text = localFiles[0][i].author
                            notesString.text = localFiles[0][i].note
                            filenameString.text = localFiles[0][i].filename
                            largeThumbnail.image = localFiles[0][i].thumbnail
                            if localFiles[0][i].favorite == "Yes" {
                                favoriteButton.setImage(#imageLiteral(resourceName: "FavoriteOn"), for: .normal)
                            } else {
                                favoriteButton.setImage(#imageLiteral(resourceName: "FavoriteOff"), for: .normal)
                            }
                        }
                    }
                }
                
                filesCollectionView.reloadData() //Needed to show currently selected file
                documentPage = 0
                
                if self.categories[self.selectedCategoryNumber] == "Publications" {
                    documentURL = self.publicationsURL.appendingPathComponent(currentCell.label.text!)
                }
                
            }
            
            /*
            updateCurrentSelectedFile(indexPath: indexPath) //Only when a "file" is selected
            */
            
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        
        var item: String = ""
        switch categories[selectedCategoryNumber] {
        case "Publications":
            item = (filesCV[indexPath.section][indexPath.row].filename)
        case "Manuscripts":
            item = (filesCV[indexPath.section][indexPath.row].filename)
        default:
            item = (filesCV[indexPath.section][indexPath.row].filename)
        }
        
        let itemProvider = NSItemProvider(object: item as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = item
        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if session.localDragSession != nil
        {
            if collectionView.hasActiveDrag
            {
                return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            }
            else
            {
                return UICollectionViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
            }
        }
        else
        {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {

        if collectionView == self.categoriesCV {
            return 1
        } else {
            switch categories[selectedCategoryNumber] {
            case "Publications":
                return sortTableTitles.count
            case "Manuscripts", "Presentations", "Proposals", "Supervision", "Teaching", "Patents", "Courses", "Miscellaneous":
                if selectedSubtableNumber < docCV.count {
                    print(docCV[selectedSubtableNumber].sectionHeader.count)
                    return docCV[selectedSubtableNumber].sectionHeader.count
                } else {
                    return 0
                }
            default:
                return 0 //sortTableTitles.count
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let sectionHeaderView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "collectionViewHeader", for: indexPath) as! SectionHeaderView
        
        switch categories[selectedCategoryNumber] {
        case "Publications": //FIX: ADD here
            sectionHeaderView.mainHeaderTitle.text = sortTableTitles[indexPath[0]]
            sectionHeaderView.subHeaderTitle.text = "\(filesCV[indexPath[0]].count)" + " items"
        case "Manuscripts", "Presentations", "Proposals", "Supervision", "Teaching", "Patents", "Courses", "Miscellaneous":
            sectionHeaderView.mainHeaderTitle.text = docCV[selectedSubtableNumber].sectionHeader[indexPath.section]
            sectionHeaderView.subHeaderTitle.text = "\(docCV[selectedSubtableNumber].files[indexPath.section].count)" + " items"
        default:
            print("Default 136")
        }
        
        sectionHeaderView.backgroundColor = barColor
        sectionHeaderView.mainHeaderTitle.textColor = textColor
        sectionHeaderView.subHeaderTitle.textColor = textColor
        
        return sectionHeaderView
    }

    
    
    // MARK: - Quick look
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        print(previewFile.url)
        return previewFile.url as QLPreviewItem
    }

    
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


extension ViewController: ExpenseCellDelegate {
    func didTapPDF(url: URL) {
//        let url = mainVC?.economyURL.appendingPathComponent(selectedCell.filename)
        PDFdocument = PDFDocument(url: url)
        PDFfilename = url.lastPathComponent
        NotificationCenter.default.post(name: Notification.Name.sendPDFfilename, object: self)
        performSegue(withIdentifier: "seguePDFViewController", sender: self)
    }

}


@IBDesignable extension UIButton {
    
    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        set {
            //            layer.masksToBounds = true
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        set {
            guard let uiColor = newValue else { return }
            layer.borderColor = uiColor.cgColor
        }
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
    }
}

@IBDesignable extension UILabel {
    
    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.masksToBounds = true
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        set {
            guard let uiColor = newValue else { return }
            layer.borderColor = uiColor.cgColor
        }
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
    }
}



