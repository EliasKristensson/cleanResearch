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
    func didTapPDF(item: Expense)
}


class categoryCell: UICollectionViewCell {
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var number: UILabel!
    @IBOutlet weak var saveNumber: UILabel!
//    var favoriteButton: UIButton!
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
    @IBOutlet weak var deleteIcon: UIImageView!
    @IBOutlet weak var fileOffline: UIImageView!
    @IBOutlet weak var downloadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var sizeLabel: UILabel!
    
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
            delegate?.didTapPDF(item: expenseItem)
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




class ViewController: UIViewController, UIPopoverPresentationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDataSource, UITableViewDelegate, UICollectionViewDragDelegate, UICollectionViewDropDelegate, UITableViewDropDelegate, QLPreviewControllerDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate {
    

    // MARK: - Variables
    var appDelegate: AppDelegate!
    let container = CKContainer.default
    let previewController = QLPreviewController()
    
    // MARK: - Core data
    var context: NSManagedObjectContext!
    
    var currentIndexPath: IndexPath = IndexPath(row: 0, section: 0)
    
    // MARK: - iCloud variables
    var documentURL: URL!
    var documentPage = 0
    var iCloudURL: URL!
    var kvStorage: NSUbiquitousKeyValueStore!
    var icloudAvailable: Bool? = nil
    var icloudFileURL: URL!
    var iCloudSynd = true
    var scanForFiles = false
    
    //MARK: - Custom classes/structs
    let fileHandler = FileHandler()
    var dataManager: DataManager!
    var progressMonitor: ProgressMonitor!
    
    //MARK: - Document directory
    var docsURL: URL!
    var localFileURL: URL!
    var folderURL: String!
    let fileManagerDefault = FileManager.default
    
    // MARK: - UI variables
    let documentInteractionController = UIDocumentInteractionController()
    var categories: [String] = [""]
    var settingsCollectionViewBox = CGSize(width: 250, height: 180)
    var notesBox = CGSize(width: 260, height: 300)
    var editingFilesCV = false
    var currentSelectedFilename: String? = nil
    var selectedInvoice: String? = nil
    var currentExpense: Expense!
    
    var sortTableListBox = CGSize(width: 348, height: 28)
    var sortCVBox = CGSize(width: 219, height: 28)
    var systemInfoBox = CGSize(width: 300, height: 50)
    var selectedCategoryNumber = 0

//    var localFiles: [[LocalFile]]!
    var filesCV: [[LocalFile]] = [[]] //Place files to be displayed in collection view here (ONLY PUBLICATIONS!)
    var docCV: [DocCV] = []
    let sortSubtableStrings = ["Tag", "Author", "Journal", "Year", "Rank"] //Only for publications
    let sortCVStrings: [String] = ["Filename", "Date"]
    var selectedSubtableNumber = 0
    var selectedSortingNumber = 0
    var selectedSortingCVNumber = 0
    var selectedFile: [SelectedFile] = []
    var selectedLocalFile: LocalFile!
    var previewFile: LocalFile!
    var sortTableTitles: [String] = [""]
    var sectionTitles: [[String]] = [[""]]

    var yearsString: [String] = [""]
    
    var currentFilename: String = ""
    var dateFormatter = DateFormatter()
    
    var PDFdocument: PDFDocument!
    var PDFfilename: String!
    var PDFPath: String?
    var annotationSettings: [Int] = [0, 0, 0, 0, 50, 0, 0, 0, 0]
    
    var downloadTimer: Timer!
    var searchForFilesTimer: Timer!
    var filesDownloading: [DownloadingFile]!
    
    var textColor: UIColor!
    var backgroundColor: UIColor!
    var barColor: UIColor!
    
    var searchHidden = true
//    var isSearching = false
    
    var originalFilename: String!
    var originalShortName: String!
    var newFilename: String!
    
    // MARK: - Outlets
    @IBOutlet var mainView: UIView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var economyView: UIView!
    @IBOutlet weak var mainHeader: UILabel!
    
    @IBOutlet weak var listTableView: UITableView!
    @IBOutlet weak var filesCollectionView: UICollectionView!
    @IBOutlet weak var selectedCategoryTitle: UILabel!
    @IBOutlet weak var categoriesCV: UICollectionView!
    @IBOutlet weak var sortSTButton: UIBarButtonItem!
    @IBOutlet weak var sortCVButton: UIBarButtonItem!
    @IBOutlet weak var editButton: UIBarButtonItem!
    @IBOutlet weak var addNew: UIBarButtonItem!
    @IBOutlet weak var downloadToLocalFileBUtton: UIBarButtonItem!
    @IBOutlet weak var favoriteButton: UIBarButtonItem!
    @IBOutlet weak var notesButton: UIBarButtonItem!
    @IBOutlet weak var amountReceivedString: UITextField!
    @IBOutlet weak var amountRemainingString: UITextField!
    @IBOutlet weak var currencyString: UILabel!
    @IBOutlet weak var expenseString: UITextField!
    @IBOutlet weak var overheadString: UITextField!
    @IBOutlet weak var referenceString: UITextField!
    @IBOutlet weak var commentString: UITextField!
    @IBOutlet weak var expensesTableView: UITableView!
    @IBOutlet weak var switchView: UISwitch!
    @IBOutlet weak var searchButton: UIBarButtonItem!
    @IBOutlet weak var searchBar: UISearchBar!
    
    
    // MARK: - IBActions
    @IBAction func switchViewChanged(_ sender: Any) {
        if switchView.isOn {
            self.economyView.isHidden = false
            self.filesCollectionView.isHidden = true
        } else {
            self.economyView.isHidden = true
            self.filesCollectionView.isHidden = false
            self.filesCollectionView.reloadData()
        }
    }
    
    @IBAction func favoriteTapped(_ sender: Any) {
        
        let filename = selectedLocalFile.filename
        
        if selectedLocalFile.favorite == "No" {
            favoriteButton.image = #imageLiteral(resourceName: "star-filled.png")
            favoriteButton.tintColor = UIColor.red
        } else {
            favoriteButton.image = #imageLiteral(resourceName: "star.png")
            favoriteButton.tintColor = UIColor.white
        }
        
        for i in 0..<dataManager.localFiles[0].count {
            if dataManager.localFiles[0][i].filename == filename {
                dataManager.localFiles[0][i] = selectedLocalFile
            }
        }
        
        selectedLocalFile = dataManager.addOrRemoveFromFavorite(file: selectedLocalFile)
        dataManager.replaceLocalFileWithNew(newFile: selectedLocalFile)
        dataManager.updateIcloud(file: selectedLocalFile, oldFilename: nil, newFilename: nil, expense: nil, project: nil, type: "Publications", bookmark: nil)
        
        populateListTable()
        populateFilesCV()
        sortFiles()
        listTableView.reloadData()
        filesCollectionView.reloadData()
        
    }
    
    @IBAction func downloadToLocalFileTapped(_ sender: Any) {
        
        DispatchQueue.main.async {
            if !self.selectedLocalFile.downloaded {
                
                let filename = self.selectedLocalFile.localURL.lastPathComponent
                let dir = self.selectedLocalFile.localURL.deletingLastPathComponent()
                
                do {
                    try self.fileManagerDefault.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("Error: \(error.localizedDescription)")
                }
                
                let fileURL = dir.appendingPathComponent(filename)
                
                if let document = PDFDocument(url: self.selectedLocalFile.iCloudURL) {
                    if !document.write(to: fileURL) {
                        self.alert(title: "Save issue", message: "Failed to save PDF locally")
                    } else {
                        self.selectedLocalFile.downloaded = true
                        self.dataManager.replaceLocalFileWithNew(newFile: self.selectedLocalFile)
                        self.downloadToLocalFileBUtton.image = #imageLiteral(resourceName: "HDD-filled")
                        self.sendNotification(text: self.selectedLocalFile.filename + " saved locally")

                    }
                } else {
                    self.alert(title: "Read issue", message: "Failed to read PDF")
                }
                
            } else {
                do {
                    try self.fileManagerDefault.removeItem(at: self.selectedLocalFile.localURL)
                    self.selectedLocalFile.downloaded = false
                    self.dataManager.replaceLocalFileWithNew(newFile: self.selectedLocalFile)
                    self.downloadToLocalFileBUtton.image = #imageLiteral(resourceName: "DownloadPDF")
                    self.sendNotification(text: self.selectedLocalFile.filename + " local save removed")
                } catch {
                    self.alert(title: "Delete issue", message: "Failed to delete PDF")
                    print("Error: \(error.localizedDescription)")
                }
            }
            
            self.populateListTable()
            self.populateFilesCV()
            self.sortFiles()
            
            self.listTableView.reloadData()
            self.filesCollectionView.reloadData()
        }
    }
    
    @IBAction func addExpenseTapped(_ sender: Any) {
        
        let amount = isStringAnInt(stringNumber: expenseString.text!)
        let OH = Int16(isStringAnInt(stringNumber: overheadString.text!))
        var comment = ""
        if let tmp = commentString.text {
            comment = tmp
        }
        var reference = ""
        if let tmp = referenceString.text {
            reference = tmp
        }
        
        dataManager.addExpense(amount: amount, OH: OH, comment: comment, reference: reference)
        
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
                self.dataManager.addNewItem(title: newGroup?.text, number: [""])
                inputNewGroup.dismiss(animated: true, completion: nil)
                
                self.populateListTable()
                self.populateFilesCV()
                self.sortFiles()
                
                self.listTableView.reloadData()
                self.filesCollectionView.reloadData()
                
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
                self.dataManager.addNewItem(title: newProject?.text, number: [amount?.text, currency?.text])
                
                inputNewProject.dismiss(animated: true, completion: nil)

                self.populateListTable()
                self.populateFilesCV()
                self.sortFiles()
                
                self.categoriesCV.reloadData()
                self.listTableView.reloadData()
                self.filesCollectionView.reloadData()
                
                self.categoriesCV.selectItem(at: IndexPath(row: self.selectedCategoryNumber, section: 0), animated: true, scrollPosition: .top)
            }))
            inputNewProject.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                inputNewProject.dismiss(animated: true, completion: nil)
            }))
            self.present(inputNewProject, animated: true, completion: nil)
            
        default:
            print("110")
        }
    }
    
    @IBAction func editIconTapped(_ sender: Any) {
        editingFilesCV = !editingFilesCV
        filesCollectionView.reloadData()
    }
    
    @IBAction func amountReceivedEdited(_ sender: Any) {
        
        let amountReceived = isStringAnInt(stringNumber: amountReceivedString.text!)
        dataManager.amountReceivedChanged(amountReceived: amountReceived)
        
        expensesTableView.reloadData()
    }
    
    @IBAction func sortCV(_ sender: Any) {
        
    }
    
    @IBAction func searchButtonTapped(_ sender: Any) {
        searchHidden = !searchHidden
        searchBar.isHidden = searchHidden
        dataManager.isSearching = !searchHidden
        searchBar.text = ""
        
        if !dataManager.isSearching {
            populateListTable()
            populateFilesCV()
            sortFiles()
            
            listTableView.reloadData()
            filesCollectionView.reloadData()
        }
    }
    
    
    
    
    
    // MARK: - ViewDidLoad
    override func viewDidLoad() {
        print("viewDidLoad - Main")
        super.viewDidLoad()
        
        //MARK: - AppDelegate
        let app = UIApplication.shared
        appDelegate = (app.delegate as! AppDelegate)
        icloudAvailable = appDelegate.iCloudAvailable!
        context = appDelegate.context
        
        //DATABASE MANAGER
        dataManager.context = context
        dataManager.progressMonitor = progressMonitor

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
        
        self.iCloudURL = self.appDelegate.iCloudURL
        self.docsURL = self.appDelegate.docsDir
        
        searchBar.delegate = self
        
        mainVC = self
        
        self.navigationController?.isNavigationBarHidden = false
        self.navigationItem.hidesBackButton = true
        navigationController?.navigationBar.barTintColor = UIColor.black
//        navigationController?.navigationBar.backgroundColor = UIColor.black
//        navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.orange]

        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleSorttablePopupClosing), name: Notification.Name.sortSubtable, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleSettingsPopupClosing), name: Notification.Name.settingsCollectionView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handlePDFClosing), name: Notification.Name.closingPDF, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleInvoiceClosing), name: Notification.Name.closingInvoiceVC, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleSortCVClosing), name: Notification.Name.sortCollectionView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotesClosing), name: Notification.Name.closingNotes, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.icloudFinishedLoading), name: Notification.Name.icloudFinished, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reload), name: Notification.Name.reload, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.closeNotification), name: Notification.Name.notifactionExit, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.postNotification), name: Notification.Name.sendNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateView), name: Notification.Name.updateView, object: nil)

        
        // Touch gestures
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(self.doubleTapped))
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress))
        doubleTap.numberOfTapsRequired = 2
        longPress.minimumPressDuration = 2
        self.categoriesCV.addGestureRecognizer(longPress)
        self.filesCollectionView.addGestureRecognizer(doubleTap)
        
        self.listTableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .top)
        
        backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        barColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        
        mainView.backgroundColor = barColor
        backgroundView.backgroundColor = backgroundColor
        categoriesCV.backgroundColor = backgroundColor
        filesCollectionView.backgroundColor = backgroundColor
        selectedCategoryTitle.backgroundColor = barColor
        selectedCategoryTitle.textColor = textColor
        economyView.backgroundColor = backgroundColor
        mainHeader.backgroundColor = barColor
        listTableView.backgroundColor = backgroundColor
        listTableView.tintColor = textColor
        
        self.setupUI()
        setNeedsStatusBarAppearanceUpdate()
        
        searchForFilesTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(checkForNewFiles), userInfo: nil, repeats: true)
        if !scanForFiles {
            searchForFilesTimer.invalidate()
        }
        
        self.view.addSubview(self.progressMonitor)
        
//        self.dataManager.deleteAlliCloudRecords()
        
        
    }
    
    
    
    
    
    
    
    // MARK: - OBJECT C FUNCTIONS
    @objc func checkForNewFiles() {
        dataManager.checkForNewFiles()
    }
    
    @objc func checkIfFileIsDownloaded() {
        var stillDownloading = false
        for i in 0..<filesDownloading.count {
            if !filesDownloading[i].downloaded {
                do {
                    let file = filesDownloading[i]
                    var filename = file.url.deletingPathExtension().lastPathComponent
                    filename.remove(at: filename.startIndex)
                    let folder = file.url.deletingLastPathComponent()
                    let filePath = folder.appendingPathComponent(filename).path
                    print(filePath)
                    let exist = fileManagerDefault.fileExists(atPath: filePath)
                    
                    if !exist {
                        stillDownloading = true
                    } else {
                        
                        sendNotification(text: filename + " downloaded")
                        
                        filesDownloading[i].downloaded = true
                        
                        dataManager.reloadLocalFiles(category: filesDownloading[i].category)
                        if categories[filesDownloading[i].category] == "Publications" {
                            dataManager.compareLocalFilesWithDatabase()
                        }
                        
                        NotificationCenter.default.post(name: Notification.Name.updateView, object: nil)
                        
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
            downloadTimer.invalidate()
        }
        
        
    }
    
    @objc func closeNotification() {
//        progressMonitor.removeFromSuperview()
    }

    @objc func doubleTapped(gesture: UITapGestureRecognizer) {
        
        let pointInCollectionView = gesture.location(in: self.filesCollectionView)
        if let indexPath = self.filesCollectionView.indexPathForItem(at: pointInCollectionView) {
            switch categories[selectedCategoryNumber] {
            case "Publications":
                selectedLocalFile = filesCV[indexPath.section][indexPath.row]
                
                if selectedLocalFile.downloaded {
                    PDFdocument = PDFDocument(url: selectedLocalFile.localURL)
                } else {
                    PDFdocument = PDFDocument(url: selectedLocalFile.iCloudURL)
                }
                
                performSegue(withIdentifier: "seguePDFViewController", sender: self)
                
            case "Books":
                selectedLocalFile = docCV[selectedSubtableNumber].files[indexPath.section][indexPath.row]
                
                if selectedLocalFile.downloaded {
                    PDFdocument = PDFDocument(url: selectedLocalFile.localURL)
                } else {
                    PDFdocument = PDFDocument(url: selectedLocalFile.iCloudURL)
                }
                
                if let currentBook = dataManager.booksCD.first(where: {$0.filename == selectedLocalFile.filename}) {
                    print("Book saved already to CD")
                } else {
                    dataManager.addFileToCoreData(file: selectedLocalFile)
                }
                
                performSegue(withIdentifier: "seguePDFViewController", sender: self)
                
            default:
                
                selectedLocalFile = docCV[selectedSubtableNumber].files[indexPath.section][indexPath.row]
                
                if selectedLocalFile.downloaded {
                    PDFdocument = PDFDocument(url: selectedLocalFile.localURL)
                    performSegue(withIdentifier: "seguePDFViewController", sender: self)
                } else if selectedLocalFile.iCloudURL.lastPathComponent.range(of: ".pdf") != nil {
                    PDFdocument = PDFDocument(url: selectedLocalFile.iCloudURL)
                    performSegue(withIdentifier: "seguePDFViewController", sender: self)
                } else {
                    previewFile = selectedLocalFile
                    previewController.reloadData()
                    navigationController?.pushViewController(previewController, animated: true)
                }
            }
        }
    }
    
    @objc func handleSettingsPopupClosing(notification: Notification) {
        let settingsVC = notification.object as! SettingsViewController
        iCloudSynd = settingsVC.syncWithIcloud.isOn
        scanForFiles = settingsVC.scanForNewFiles.isOn
        if settingsVC.scanForNewFiles.isOn {
            if !searchForFilesTimer.isValid {
                searchForFilesTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(checkForNewFiles), userInfo: nil, repeats: true)
            }
        } else {
            searchForFilesTimer.invalidate()
        }
        
        kvStorage.set(settingsVC.scanForNewFiles.isOn, forKey: "scanForFiles")
        kvStorage.set(iCloudSynd, forKey: "iCloudSynd")
        kvStorage.synchronize()
    }
    
    @objc func handlePDFClosing(notification: Notification) {
        
        self.navigationController?.isNavigationBarHidden = false
        self.navigationItem.hidesBackButton = true
        self.navigationController?.navigationBar.barTintColor = UIColor.black
        self.navigationController?.navigationBar.backgroundColor = UIColor.black
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        let vc = notification.object as! PDFViewController
        annotationSettings = vc.annotationSettings!
        
        kvStorage.set(annotationSettings, forKey: "annotationSettings")
        kvStorage.synchronize()
        
        if let index = dataManager.localFiles[selectedCategoryNumber].index(where: {$0.filename == vc.PDFfilename}) {
            dataManager.localFiles[selectedCategoryNumber][index].dateModified = Date()
            dataManager.localFiles[selectedCategoryNumber][index].thumbnail = fileHandler.getThumbnail(icloudURL: vc.document.documentURL!, localURL: dataManager.localFiles[selectedCategoryNumber][index].localURL, localExist: fileManagerDefault.fileExists(atPath: dataManager.localFiles[selectedCategoryNumber][index].localURL.path), pageNumber: 0)
            
            if vc.needsUploading {
                dataManager.savePDF(file: vc.currentFile, document: vc.document)
            }
            
            dataManager.saveBookmark(file: dataManager.localFiles[selectedCategoryNumber][index], bookmark: vc.bookmarks)
            
            if categories[selectedCategoryNumber] == "Publications" {
                dataManager.updateIcloud(file: dataManager.localFiles[selectedCategoryNumber][index], oldFilename: nil, newFilename: nil, expense: nil, project: nil, type: "Publications", bookmark: nil)
                dataManager.updateCoreData(file: dataManager.localFiles[selectedCategoryNumber][index], oldFilename: nil, newFilename: nil)
            }
            
            populateListTable()
            populateFilesCV()
            sortFiles()
            listTableView.reloadData()
            filesCollectionView.reloadData()
            
        } else {
            print("Not uploaded to iCloud")
            print(iCloudSynd)
        }
    }
    
    @objc func handleSorttablePopupClosing(notification: Notification) {
        let sortingVC = notification.object as! SortSubtableViewController
        let sortValue = sortingVC.sortOptions.selectedSegmentIndex
        selectedSortingNumber = sortValue
        
        kvStorage.set(selectedSortingNumber, forKey: "sortSubtable")
        kvStorage.synchronize()
        
        if sortSubtableStrings[selectedSortingNumber] == "Tag" {
            self.editButton.isEnabled = true
        } else {
            self.editButton.isEnabled = false
            editingFilesCV = false
        }

        populateListTable()
        populateFilesCV()
        sortFiles()

        self.listTableView.reloadData()
        self.filesCollectionView.reloadData()
        
        if currentSelectedFilename != nil {
            attemptScrolling(filename: currentSelectedFilename!)
        }
        
    }
    
    @objc func handleSortCVClosing(notification: Notification) {
        let sortingVC = notification.object as! SortCVViewController
        let sortValue = sortingVC.sortOptions.selectedSegmentIndex
        selectedSortingCVNumber = sortValue

        kvStorage.set(selectedSortingNumber, forKey: "sortCV")
        kvStorage.synchronize()

//        sortFiles()
        populateFilesCV()
        sortFiles()
        self.listTableView.reloadData()
        self.filesCollectionView.reloadData()

    }
    
    @objc func handleNotesClosing(notification: Notification) {
        let vc = notification.object as! NotesViewController
        
        if vc.update {
            let currentFile = vc.localFile
            
            if let index = dataManager.localFiles[0].index(where: {$0.filename == currentFile?.filename}) {
                dataManager.localFiles[0][index] = currentFile!
            }

            if vc.filenameChanged {
                print("Filename changed")
                currentSelectedFilename = currentFile?.filename
                
                dataManager.updateIcloud(file: currentFile!, oldFilename: vc.originalFilename, newFilename: currentFile?.filename, expense: nil, project: nil, type: "Publications", bookmark: nil)
                dataManager.updateCoreData(file: currentFile!, oldFilename: vc.originalFilename, newFilename: currentFile?.filename)
                
                populateListTable()
                populateFilesCV()
                sortFiles()
                
                listTableView.reloadData()
                filesCollectionView.reloadData()
                attemptScrolling(filename: (currentFile?.filename)!)
                
            } else {
               

                dataManager.updateIcloud(file: currentFile!, oldFilename: nil, newFilename: nil, expense: nil, project: nil, type: "Publications", bookmark: nil)
                dataManager.updateCoreData(file: currentFile!, oldFilename: nil, newFilename: nil)

                populateListTable()
                populateFilesCV()
                sortFiles()
                
                listTableView.reloadData()
                filesCollectionView.reloadData()
            }
        }
    }
    
    @objc func handleInvoiceClosing(notification: Notification) {
        let vc = notification.object as! InvoiceViewController
        selectedInvoice = vc.selectedInvoice
        currentExpense.pdfURL = dataManager.economyURL.appendingPathComponent(selectedInvoice!)
        dataManager.saveCoreData()
        dataManager.loadCoreData()
        self.expensesTableView.reloadData()
    }
    
    @objc func handleLongPress(gesture : UILongPressGestureRecognizer!) {
        
        let point = gesture.location(in: self.categoriesCV)
        
        if let indexPath = self.categoriesCV.indexPathForItem(at: point) {
            
            sendNotification(text: "Reloading " + categories[selectedCategoryNumber] + " folder")
            
            selectedCategoryNumber = indexPath.row
            dataManager.selectedCategoryNumber = selectedCategoryNumber
            dataManager.reloadLocalFiles(category: selectedCategoryNumber)
            
            populateListTable()
            populateFilesCV()
            sortFiles()
            
            categoriesCV.reloadData()
            listTableView.reloadData()
            filesCollectionView.reloadData()
            
            sendNotification(text: "Reload of " + categories[selectedCategoryNumber] + " folder finished")
            
        } else {
            print("couldn't find index path")
        }
        
    }
    
    @objc func icloudFinishedLoading() {
        
        print("icloudFinishedLoading")

        self.sendNotification(text: "Finished reading iCloud records")

        dataManager.compareLocalFilesWithIcloud()
        
        self.populateListTable()
        self.populateFilesCV()
        self.sortFiles()
        
        self.categoriesCV.reloadData()
        self.listTableView.reloadData()
        self.filesCollectionView.reloadData()
        
    }
    
    @objc func postNotification() {
        DispatchQueue.main.async {
            self.view.addSubview(self.progressMonitor)
            self.progressMonitor.launchMonitor(displayText: nil)
        }
    }
    
    @objc func reload() {
        
        self.populateListTable()
        self.populateFilesCV()
        self.sortFiles()
        
        self.categoriesCV.reloadData()
        self.listTableView.reloadData()
        self.filesCollectionView.reloadData()
        
    }
    
    @objc func sendNotification(text: String) {
        print("sendNotification")
        DispatchQueue.main.async {
            self.view.addSubview(self.progressMonitor)
            self.progressMonitor.launchMonitor(displayText: text)
        }
    }
    
    @objc func updateView() {
        print("udateView")
        self.categoriesCV.reloadData()
    }
    

    
    
    
    func addNewItem(title: String?, number: [String?]) {
        
        switch categories[selectedCategoryNumber] {
        case "Publications":
            if let newTag = title {
                let newGroup = PublicationGroup(context: context)
                newGroup.tag = newTag
                newGroup.dateModified = Date()
                newGroup.sortNumber = "3"
                
                dataManager.publicationGroupsCD.append(newGroup)
                
                dataManager.saveCoreData()
                dataManager.loadCoreData()
                
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
                        
                        dataManager.saveToIcloud(url: nil, type: "Project", object: newProject)
                        
                        dataManager.projectCD.append(newProject)
                        
                        dataManager.saveCoreData()
                        dataManager.loadCoreData()
                        
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
    
    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func attemptScrolling(filename: String) {
        
        if filename != nil {
            selectedFile[selectedCategoryNumber].category = categories[selectedCategoryNumber]
            selectedFile[selectedCategoryNumber].filename = filename
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
        
    }
    
    func getArticlesYears() -> [String] {
        var tmp = [String]()
        for i in 0..<dataManager.localFiles[selectedCategoryNumber].count {
            tmp.append("\(dataManager.localFiles[selectedCategoryNumber][i].year!)")
        }
        yearsString = tmp.reduce([], {$0.contains($1) ? $0:$0+[$1]})
        yearsString = yearsString.sorted(by: {$0 < $1})
        return yearsString
    }
    
    func isStringAnInt(stringNumber: String?) -> Int32 {
        let number = stringNumber?.replacingOccurrences(of: "\"", with: "")
        if let tmpValue = Int32(number!) {
            return tmpValue
        }
        print("String number could not be converted")
        return -2000
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
        
        if let sync = kvStorage.object(forKey: "iCloudSynd") as? Bool {
            iCloudSynd = sync
        } else {
            iCloudSynd = true
        }
        
        if let scan = kvStorage.object(forKey: "scanForFiles") as? Bool {
            scanForFiles = scan
        } else {
            scanForFiles = false
        }
        
        if let settings = kvStorage.object(forKey: "annotationSettings") as? [Int] {
            annotationSettings = settings
            if annotationSettings.count < 9 {
                annotationSettings = [3, 3, 3, 3, 50, 15, 0, 0, 0]
            }
        } else {
            annotationSettings = [3, 3, 3, 3, 50, 15, 0, 0, 0]
        }
        
    }
    
    func populateListTable() {

        sortTableTitles = [String]()
        switch categories[selectedCategoryNumber] {
        case "Publications":
            
            //Change to localFiles[0] instead of CD?
            switch sortSubtableStrings[selectedSortingNumber] {
            case "Tag":
                let tmp = dataManager.publicationGroupsCD.sorted(by: {($0.sortNumber!, $0.tag!) < ($1.sortNumber!, $1.tag!)})
                sortTableTitles = tmp.map { $0.tag! }
            case "Year":
                sortTableTitles = getArticlesYears()
            case "Author":
                let tmp = dataManager.authorsCD.sorted(by: {($0.sortNumber!, $0.name!) < ($1.sortNumber!, $1.name!)})
                sortTableTitles = tmp.map { $0.name! }
            case "Journal":
                let tmp = dataManager.journalsCD.sorted(by: {($0.sortNumber!, $0.name!) < ($1.sortNumber!, $1.name!)})
                sortTableTitles = tmp.map { $0.name! }
            case "Rank":
                sortTableTitles = ["0-9", "10-19", "20-29", "30-39", "40-49", "50-59", "60-69", "70-79", "80-89", "90-99", "100"]
            default:
                print("Default 125")
            }
        case "Economy":
            let tmp = dataManager.projectCD.sorted(by: {$0.name! < $1.name!})
            sortTableTitles = tmp.map { $0.name! }
            
        default:
            
            let (number, _) = dataManager.getCategoryNumberAndURL(name: categories[selectedCategoryNumber])
            
            for file in dataManager.localFiles[number] {
                sortTableTitles.append(file.grandpaFolder!)
            }
            
            if !sortTableTitles.isEmpty {
                let set = Set(sortTableTitles)
                sortTableTitles = Array(set)
                sortTableTitles = sortTableTitles.sorted()
            }
            
        }
        
    }
    
    func populateFilesCV() {

        switch categories[selectedCategoryNumber] {
        case "Publications": //LocalFiles[0]
            filesCV = [[]]
            
            var files: [LocalFile]
            if dataManager.isSearching && dataManager.searchString.count > 0 {
                files = dataManager.searchResult
            } else {
                files = dataManager.localFiles[selectedCategoryNumber]
            }
            
            switch sortSubtableStrings[selectedSortingNumber] {
            case "Tag":
                for i in 0..<sortTableTitles.count {
                    for file in files {
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
                    for file in files {
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
                    for file in files {
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
                    for file in files {
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
                    for file in files {
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
            
        case "Economy":
            
            docCV = []
            
            print(selectedCategoryNumber)
            let (number, _) = dataManager.getCategoryNumberAndURL(name: categories[selectedCategoryNumber])
            print(number)
            
            var tmp = DocCV(listTitle: "", sectionHeader: [], files: [[]])
            var folders = [String]()
            
            for file in dataManager.localFiles[number] {
                folders.append(file.grandpaFolder!)
            }
            
            if !folders.isEmpty {
                let set = Set(folders)
                folders = Array(set)
                folders = folders.sorted()
            }
            
            for i in 0..<folders.count {
                tmp.sectionHeader.append(folders[i])
                for file in dataManager.localFiles[number] {
                    if file.grandpaFolder == folders[i] {
                        tmp.files[i].append(file)
                    }
                }
                if i < folders.count {
                    tmp.files.append([])
                }
            }
            docCV.append(tmp)
            
        default:
            
            let (number, _) = dataManager.getCategoryNumberAndURL(name: categories[selectedCategoryNumber])
            
            docCV = []
            
            if !sortTableTitles.isEmpty {
                for i in 0..<sortTableTitles.count {
                    var subfolders: [String] = []
                    var tmp = DocCV(listTitle: sortTableTitles[i], sectionHeader: [], files: [[]])
                    for file in dataManager.localFiles[number] {
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
                        for file in dataManager.localFiles[number] {
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
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "segueSortSubtable") {
            let destination = segue.destination as! SortSubtableViewController
            destination.sortValue = selectedSortingNumber
            destination.sortStrings = sortSubtableStrings
            destination.preferredContentSize = sortTableListBox
        }
        if (segue.identifier == "segueSortCV") {
            let destination = segue.destination as! SortCVViewController
            destination.sortValue = selectedSortingCVNumber
            destination.sortStrings = sortCVStrings
            destination.preferredContentSize = sortCVBox
        }
        if (segue.identifier == "segueSystemInfo") {
            let destination = segue.destination as! SystemInfoViewController
            destination.preferredContentSize = systemInfoBox
        }
        if (segue.identifier == "segueNotes") {
            let destination = segue.destination as! NotesViewController
            destination.localFile = selectedLocalFile
            destination.dataManager = dataManager
            destination.preferredContentSize = notesBox
        }
        if (segue.identifier == "seguePDFViewController") {
            let destination = segue.destination as! PDFViewController
            destination.document = PDFdocument
            destination.PDFfilename = selectedLocalFile.filename
            destination.iCloudURL = selectedLocalFile.iCloudURL
            destination.localURL = selectedLocalFile.localURL
            destination.progressMonitor = progressMonitor
            destination.annotationSettings = annotationSettings
            destination.kvStorage = kvStorage
            destination.dataManager = dataManager
            destination.currentFile = selectedLocalFile
            
            //DOESNT WORK FOR INVOICES
//            if categories[selectedCategoryNumber] == "Publications" {
//                if let currentBookmark = dataManager.bookmarksCD.first(where: {$0.path! == PDFPath!}) {
//                }
//            }
            
            if let currentBookmark = dataManager.getBookmark(file: selectedLocalFile) {
                print("Bookmark found")
                destination.bookmarks = currentBookmark
            } else {
                print("No bookmark")
                let newBookmark = dataManager.newBookmark(file: selectedLocalFile)
                destination.bookmarks = newBookmark
            }
            
        }
        if (segue.identifier == "segueSettings") {
            let destination = segue.destination as! SettingsViewController
            destination.sync = iCloudSynd
            destination.scan = scanForFiles
            destination.dataManager = dataManager
            destination.preferredContentSize = settingsCollectionViewBox
        }
        if (segue.identifier == "segueInvoiceVC") {
            let destination = segue.destination as! InvoiceViewController
            destination.invoiceURL = dataManager.economyURL
        }
        
    }
    
    func setupUI() {
        
        print("setupUI")
        
        filesDownloading = []

        for _ in 0..<categories.count {
            let tmp = SelectedFile(category: nil, filename: nil, indexPathCV: [nil])
            selectedFile.append(tmp)
        }
        
        kvStorage = NSUbiquitousKeyValueStore()
        loadDefaultValues()
        
        //ALWAYS START WITH PUBLICATIONS
        economyView.isHidden = true
        filesCollectionView.isHidden = false
        sortSTButton.isEnabled = true
        switchView.isEnabled = false

        dataManager.progressMonitor = progressMonitor
        dataManager.loadCoreData()
        dataManager.setupDefaultCoreDataTypes()
        dataManager.compareLocalFilesWithCoreData()
        dataManager.initIcloudLoad()
        sendNotification(text: "Starting to load iCloud records")
        
        searchBar.isHidden = searchHidden

        self.populateListTable()
        self.populateFilesCV()
        self.sortFiles()
        
        self.categoriesCV.reloadData()
        self.listTableView.reloadData()
        self.filesCollectionView.reloadData()
        
        downloadToLocalFileBUtton.isEnabled = false
        notesButton.isEnabled = false
        favoriteButton.isEnabled = false
        
    }
    
    func sortFiles() {
        switch categories[selectedCategoryNumber] {
        case "Publications":
            if !filesCV.isEmpty {
                if selectedSubtableNumber >= filesCV.count {
                    selectedSubtableNumber = 0
                    dataManager.selectedSubtableNumber = selectedSubtableNumber
                }
                switch selectedSortingCVNumber {
                case 0:
                    filesCV[selectedSubtableNumber] = filesCV[selectedSubtableNumber].sorted(by: {($0.filename) < ($1.filename)})
                case 1:
                    filesCV[selectedSubtableNumber] = filesCV[selectedSubtableNumber].sorted(by: {($0.dateModified)! > ($1.dateModified)!})
                default:
                    filesCV[selectedSubtableNumber] = filesCV[selectedSubtableNumber].sorted(by: {($0.filename) < ($1.filename)})
                }
            }
            
        default:
            if !docCV.isEmpty {
                if selectedSubtableNumber >= docCV.count {
                    selectedSubtableNumber = 0
                    dataManager.selectedSubtableNumber = selectedSubtableNumber
                }
                switch selectedSortingCVNumber {
                case 0:
                    for i in 0..<docCV[selectedSubtableNumber].files.count {
                        docCV[selectedSubtableNumber].files[i] = docCV[selectedSubtableNumber].files[i].sorted(by: {$0.filename < $1.filename})
                    }
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
    
    func updateCurrentSelectedFile(indexPath: IndexPath) {
        
        print("updateCurrentSelectedFile")
        selectedFile[selectedCategoryNumber].category = categories[selectedCategoryNumber]
        selectedFile[selectedCategoryNumber].filename = currentSelectedFilename!
        selectedFile[selectedCategoryNumber].indexPathCV = [indexPath]


        print(selectedFile[selectedCategoryNumber])
    }
    
    
    
    
    
    // MARK: - Search bar
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        dataManager.isSearching = true;
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dataManager.isSearching = false
        
        populateListTable()
        populateFilesCV()
        sortFiles()
        
        listTableView.reloadData()
        filesCollectionView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if !searchBar.isHidden && searchText.count > 0 {
            dataManager.searchString = searchText
            print(searchText)
            dataManager.searchFiles()
        }
        
        populateListTable()
        populateFilesCV()
        sortFiles()
        
        listTableView.reloadData()
        filesCollectionView.reloadData()
    }
    
    
    
    
    // MARK: - Table view
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == self.expensesTableView {
            if selectedSubtableNumber < dataManager.projectCD.count {
                return (dataManager.projectCD[selectedSubtableNumber].expense?.count)!
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
                
            case "Economy":
                number = 1
                
            default:
                if !sortTableTitles.isEmpty {
                    return 1
                } else {
                    return 0
                }
            }
        }
        return number
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cellToReturn = UITableViewCell()
        
        if tableView == self.expensesTableView {
            
            let cell = expensesTableView.dequeueReusableCell(withIdentifier: "economyCell") as! EconomyCell
            let currentProject = dataManager.projectCD[selectedSubtableNumber]
            
            if indexPath.section == 0 {
                currentProject.amountRemaining = currentProject.amountReceived
            }
            tableView.backgroundColor = UIColor.clear
            var expenses = currentProject.expense?.allObjects as! [Expense]
            expenses = expenses.sorted(by: {$0.dateAdded! > $1.dateAdded!})
            
            cell.setExpense(expense: expenses[indexPath.section])
            cell.delegate = self
            
            cell.backgroundColor = UIColor.white
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
                
            default:
                cell.listLabel.text = sortTableTitles[indexPath.section]
                cell.listNumberOfItems.text = ""

            }
            cellToReturn = cell
        }
        
        return cellToReturn
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if tableView == self.listTableView {
            selectedSubtableNumber = indexPath.section
            dataManager.selectedSubtableNumber = selectedSubtableNumber
            
            switch categories[selectedCategoryNumber] {
            case "Publications":
                if filesCV[indexPath.section].count > 0 {
                    let cvIndexPath = IndexPath(item: 0, section: indexPath.section) //Is this correct?
                    self.filesCollectionView.scrollToItem(at: cvIndexPath, at: .top, animated: true)
                    
                }
                
            case "Economy":
                let currentProject = dataManager.projectCD[selectedSubtableNumber]
                currencyString.text = currentProject.currency
                amountReceivedString.text = "\(currentProject.amountReceived)"
                amountRemainingString.text = "\(currentProject.amountRemaining)"
                
                self.expensesTableView.reloadData()
                
            default:
                
                currentIndexPath = indexPath
                sortFiles()
                self.filesCollectionView.reloadData()
//                if filesCV[indexPath.section].count > 0 {
//                    let cvIndexPath = IndexPath(item: 0, section: indexPath.row)
//                    self.filesCollectionView.scrollToItem(at: cvIndexPath, at: .top, animated: true)
//                }
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        if tableView == self.listTableView {
            switch categories[selectedCategoryNumber] {
            case "Publications":
                if let section = coordinator.destinationIndexPath?.section {
                    switch sortSubtableStrings[selectedSortingNumber] {
                    case "Tag":
                        let groupName = sortTableTitles[section]
                        if let filename = coordinator.items[0].dragItem.localObject {
                            if let dragedPublication = filesCV[selectedSubtableNumber].first(where: {$0.filename == filename as! String}) {
                                if let group = dataManager.publicationGroupsCD.first(where: {$0.tag! == groupName}) {
                                    dataManager.addPublicationToGroup(filename: (dragedPublication.filename), group: group)
                                }
                            }
                        }
                    case "Author":
                        let authorName = sortTableTitles[section]
                        if let filename = coordinator.items[0].dragItem.localObject {
                            if let dragedPublication = dataManager.localFiles[0].first(where: {$0.filename == filename as! String}) {
                                dataManager.assignPublicationToAuthor(filename: (dragedPublication.filename), authorName: authorName)
                            }
                        }
                    case "Journal":
                        let journalName = sortTableTitles[section]
                        if let filename = coordinator.items[0].dragItem.localObject {
                            if let dragedPublication = dataManager.localFiles[0].first(where: {$0.filename == filename as! String}) {
                                dataManager.assignPublicationToJournal(filename: (dragedPublication.filename), journalName: journalName)
                            }
                        }
                    case "Year":
                        let year = sortTableTitles[section]
                        if let filename = coordinator.items[0].dragItem.localObject {
                            if let index = dataManager.localFiles[0].index(where: { $0.filename == filename as! String} ) {
                                dataManager.localFiles[0][index].year = Int16(isStringAnInt(stringNumber: year))
                                dataManager.updateIcloud(file: dataManager.localFiles[0][index], oldFilename: nil, newFilename: nil, expense: nil, project: nil, type: "Publications", bookmark: nil)
                                dataManager.updateCoreData(file: dataManager.localFiles[0][index], oldFilename: nil, newFilename: nil)
                            }
                        }
                    default:
                        print("Default 141")
                    }
                }
            default:
                print("Default 142")
            }
            
            populateListTable()
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
                        let groupToDelete = dataManager.publicationGroupsCD.first(where: {$0.tag! == groupName})
                        dataManager.context.delete(groupToDelete!)
                        
                        dataManager.saveCoreData()
                        dataManager.loadCoreData()
                        
                        populateListTable()
                        populateFilesCV()
                        sortFiles()
                        
                        listTableView.reloadData()
                        filesCollectionView.reloadData()
                        
                    } else if sortSubtableStrings[selectedSortingNumber] == "Author" {
                        let noAuthor = dataManager.authorsCD.first(where: {$0.name == "No author"})
                        let authorName = sortTableTitles[indexPath.section]
                        let authorToDelete = dataManager.authorsCD.first(where: {$0.name! == authorName})
                        let articlesBelongingToAuthor = authorToDelete?.publication
                        dataManager.context.delete(authorToDelete!)
                        for item in articlesBelongingToAuthor! {
                            let tmp = item as! Publication
                            tmp.author = noAuthor
                        }
                        
                        dataManager.saveCoreData()
                        dataManager.loadCoreData()
                        
                        populateListTable()
                        populateFilesCV()
                        sortFiles()
                        
                        listTableView.reloadData()
                        filesCollectionView.reloadData()
                        
                    } else if sortSubtableStrings[selectedSortingNumber] == "Journal" {
                        
                        let noJournal = dataManager.journalsCD.first(where: {$0.name == "No journal"})
                        let journalName = sortTableTitles[indexPath.section]
                        let journalsToDelete = dataManager.journalsCD.first(where: {$0.name == journalName})
                        let articlesBelongingToJournal = journalsToDelete?.publication
                        dataManager.context.delete(journalsToDelete!)
                        for item in articlesBelongingToJournal! {
                            let tmp = item as! Publication
                            tmp.journal = noJournal
                        }
                        
                        dataManager.saveCoreData()
                        dataManager.loadCoreData()
                        
                        populateListTable()
                        populateFilesCV()
                        sortFiles()
                        
                        listTableView.reloadData()
                        filesCollectionView.reloadData()
                    }

                    
                case "Economy":
                    let currentProject = sortTableTitles[indexPath.section]
                    let projectToDelete = dataManager.projectCD.first(where: {$0.name! == currentProject})
                    dataManager.context.delete(projectToDelete!)
                    
                    dataManager.saveCoreData()
                    dataManager.loadCoreData()

                    populateListTable()
                    categoriesCV.reloadData()
                    self.categoriesCV.selectItem(at: IndexPath(row: self.selectedCategoryNumber, section: 0), animated: true, scrollPosition: .top)
                    listTableView.reloadData()
                    expensesTableView.reloadData()
                    
                default:
                    print("Default 104")
                }
                
                
            } else if tableView == self.expensesTableView {
                let currentProject = dataManager.projectCD[selectedSubtableNumber]
                var expenses = currentProject.expense?.allObjects as! [Expense]
                
                amountRemainingString.text = "\(currentProject.amountReceived)"
                
                let expenseToRemove = dataManager.expensesCD.first(where: {$0.dateAdded! == expenses[indexPath.section].dateAdded!})
                context.delete(expenseToRemove!)
                
                dataManager.saveCoreData()
                dataManager.loadCoreData()
                
                expensesTableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        if tableView == self.expensesTableView {
            let currentProject = dataManager.projectCD[selectedSubtableNumber]
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
                    self.dataManager.saveCoreData()
                    self.dataManager.loadCoreData()
                    self.expensesTableView.reloadData()
                }
            }
            
            var activeText = "Include"
            if self.currentExpense.active {
                activeText = "Skip"
            }
            
            let skipAction = UIContextualAction(style: .normal, title: activeText) { (action, view, nil) in
                self.currentExpense.active = !self.currentExpense.active
                self.dataManager.saveCoreData()
                self.dataManager.loadCoreData()
                
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
                    
                    self.dataManager.saveCoreData()
                    self.dataManager.loadCoreData()
                    
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
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        if collectionView == self.categoriesCV {
            return 1
        } else {
            switch categories[selectedCategoryNumber] {
            case "Publications":
                return sortTableTitles.count
            case "Economy":
                return docCV[0].sectionHeader.count
            default:
                if selectedSubtableNumber < docCV.count {
                    return docCV[selectedSubtableNumber].sectionHeader.count
                } else {
                    return 0
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == self.categoriesCV {
            return categories.count
        } else {
            switch categories[selectedCategoryNumber] {
            case "Publications":
                return filesCV[section].count
            case "Economy":
                return docCV[0].files[section].count
            default:
                return docCV[selectedSubtableNumber].files[section].count
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == self.categoriesCV {
            
            searchBar.isHidden = true
            dataManager.isSearching = false
            
//            selectedSubtableNumber = 0 //When jumping between different categories, invalid values might be set to this
//            currentIndexPath = IndexPath(row: 0, section: 0)
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "categoryCell", for: indexPath) as! categoryCell
            let number = categories.index(where: { $0 == categories[indexPath.row] })
            let itemsSaving = dataManager.localFiles[number!].filter{ $0.saving == true }.count
            let itemsDownloading = dataManager.localFiles[number!].filter{ $0.downloading == true }.count
            let itemsDisplay = itemsSaving + itemsDownloading
            
            cell.number.text = "\(dataManager.localFiles[number!].count)"
            cell.saveNumber.text = "\(itemsDisplay)"
            
            if itemsDisplay == 0 {
                cell.saveNumber.isHidden = true
            } else {
                if cell.saveNumber.isHidden == true {
                    cell.saveNumber.isHidden = false
                    cell.saveNumber.grow()
                }
            }
            
            switch categories[indexPath.row] {
                
            case "Publications":
                cell.icon.image = #imageLiteral(resourceName: "PublicationsIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "PublicationsIconSelected")

            case "Books":
                cell.icon.image = #imageLiteral(resourceName: "BooksIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "BooksIconSelected")
                
            case "Economy":
                cell.icon.image = #imageLiteral(resourceName: "EconomyIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "EconomyIconSelected")
                if switchView.isOn {
                    cell.number.text = "\(dataManager.projectCD.count)"
                } else {
                    cell.number.text = "\(dataManager.localFiles[number!].count)"
                }
                
            case "Manuscripts":
                cell.icon.image = #imageLiteral(resourceName: "ManuscriptsIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "ManuscriptsIconSelected")

            case "Presentations":
                cell.icon.image = #imageLiteral(resourceName: "PresentationsIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "PresentationsIconSelected")

            case "Proposals":
                cell.icon.image = #imageLiteral(resourceName: "ProposalsIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "ProposalsIconSelected")
                
            case "Supervision":
                cell.icon.image = #imageLiteral(resourceName: "SupervisionIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "SupervisionIconSelected")

            case "Teaching":
                cell.icon.image = #imageLiteral(resourceName: "TeachingIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "TeachingIconSelected")
                
            case "Patents":
                cell.icon.image = #imageLiteral(resourceName: "PatentsIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "PatentsIconSelected")

            case "Courses":
                cell.icon.image = #imageLiteral(resourceName: "CoursesIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "CoursesIconSelected")

            case "Meetings":
                cell.icon.image = #imageLiteral(resourceName: "MeetingsIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "MeetingsIconSelected")

            case "Conferences":
                cell.icon.image = #imageLiteral(resourceName: "ConferenceIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "ConferenceIconSelected")

            case "Reviews":
                cell.icon.image = #imageLiteral(resourceName: "ReviewIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "ReviewIconSelected")
                
            case "Miscellaneous":
                cell.icon.image = #imageLiteral(resourceName: "MiscellaneousIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "MiscellaneousIconSelected")
                
            default:
                print("Default 144")
                cell.icon.image = #imageLiteral(resourceName: "PublicationsIcon")
            }
            
            selectedCategoryTitle.text = categories[selectedCategoryNumber]
            cell.number.backgroundColor = barColor
            cell.number.textColor = textColor

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

                //Indicator for downloading
                if filesCV[indexPath.section][indexPath.row].downloading && !filesCV[indexPath.section][indexPath.row].available {
                    if !cell.downloadingIndicator.isAnimating {
                        cell.downloadingIndicator.isHidden = false
                        cell.downloadingIndicator.startAnimating()
                    }
                } else {
                    if cell.downloadingIndicator.isAnimating {
                        cell.downloadingIndicator.stopAnimating()
                        cell.downloadingIndicator.isHidden = true
                    } else {
                        cell.downloadingIndicator.isHidden = true
                    }
                }
                
                cell.sizeLabel.text = filesCV[indexPath.section][indexPath.row].size
                
                if filesCV[indexPath.section][indexPath.row].favorite == "Yes" {
                    cell.favoriteIcon.isHidden = false
                } else {
                    cell.favoriteIcon.isHidden = true
                }

                if filesCV[indexPath.section][indexPath.row].downloaded {
                    cell.fileOffline.image = #imageLiteral(resourceName: "DownloadingPDF.png")
                    cell.fileOffline.isHidden = false
                } else {
                    if filesCV[indexPath.section][indexPath.row].available {
                    cell.fileOffline.isHidden = true
                    } else {
                        cell.fileOffline.image = #imageLiteral(resourceName: "FileNotAvailable")
                        cell.fileOffline.isHidden = false
                    }
                }
                
                if editingFilesCV {
                    cell.deleteIcon.isHidden = false
                } else {
                    cell.deleteIcon.isHidden = true
                }
                
                if cell.label.text == currentSelectedFilename {
                    selectedLocalFile = filesCV[indexPath.section][indexPath.row]
                    cell.layer.borderColor = UIColor.yellow.cgColor
                    cell.layer.borderWidth = 3
                    
                    if selectedLocalFile.downloaded {
                        downloadToLocalFileBUtton.isEnabled = true
                    } else {
                        downloadToLocalFileBUtton.isEnabled = selectedLocalFile.available
                    }
                    
                } else {
                    cell.layer.borderColor = UIColor.black.cgColor
                    cell.layer.borderWidth = 1
                }

            case "Economy":
                let number = 0 //[0] = "publications"
                
                cell.label.text = docCV[number].files[indexPath.section][indexPath.row].filename
                cell.thumbnail.image = docCV[number].files[indexPath.section][indexPath.row].thumbnail
                cell.favoriteIcon.isHidden = true
                cell.deleteIcon.isHidden = true
                cell.sizeLabel.text = docCV[number].files[indexPath.section][indexPath.row].size
                
                if docCV[number].files[indexPath.section][indexPath.row].downloading && !docCV[number].files[indexPath.section][indexPath.row].available {
                    if !cell.downloadingIndicator.isAnimating {
                        cell.downloadingIndicator.isHidden = false
                        cell.downloadingIndicator.startAnimating()
                    }
                } else {
                    if cell.downloadingIndicator.isAnimating {
                        cell.downloadingIndicator.stopAnimating()
                        cell.downloadingIndicator.isHidden = true
                    } else {
                        cell.downloadingIndicator.isHidden = true
                    }
                }

                if docCV[number].files[indexPath.section][indexPath.row].downloaded {
                    cell.fileOffline.isHidden = false
                    cell.fileOffline.image = #imageLiteral(resourceName: "DownloadingPDF.png")
                } else {
                    if docCV[number].files[indexPath.section][indexPath.row].available {
                        cell.fileOffline.isHidden = true
                    } else {
                        cell.fileOffline.isHidden = false
                        cell.fileOffline.image = #imageLiteral(resourceName: "FileNotAvailable")
                    }
                }

                if cell.label.text == currentSelectedFilename {
                    selectedLocalFile = docCV[number].files[indexPath.section][indexPath.row]
                    cell.layer.borderColor = UIColor.yellow.cgColor
                    cell.layer.borderWidth = 3

                    if selectedLocalFile.downloaded {
                        downloadToLocalFileBUtton.isEnabled = true
                    } else {
                        downloadToLocalFileBUtton.isEnabled = selectedLocalFile.available
                    }

                } else {
                    cell.layer.borderColor = UIColor.black.cgColor
                    cell.layer.borderWidth = 1
                }
                
            default:
                
                cell.label.text = docCV[selectedSubtableNumber].files[indexPath.section][indexPath.row].filename
                cell.thumbnail.image = docCV[selectedSubtableNumber].files[indexPath.section][indexPath.row].thumbnail
                cell.favoriteIcon.isHidden = true
                cell.deleteIcon.isHidden = true
                cell.sizeLabel.text = docCV[selectedSubtableNumber].files[indexPath.section][indexPath.row].size

                //Indicator for downloading
                if docCV[selectedSubtableNumber].files[indexPath.section][indexPath.row].downloading && !docCV[selectedSubtableNumber].files[indexPath.section][indexPath.row].available {
                    if !cell.downloadingIndicator.isAnimating {
                        cell.downloadingIndicator.isHidden = false
                        cell.downloadingIndicator.startAnimating()
                    }
                } else {
                    if cell.downloadingIndicator.isAnimating {
                        cell.downloadingIndicator.stopAnimating()
                        cell.downloadingIndicator.isHidden = true
                    } else {
                        cell.downloadingIndicator.isHidden = true
                    }
                }
                
                if docCV[selectedSubtableNumber].files[indexPath.section][indexPath.row].downloaded {
                    cell.fileOffline.isHidden = false
                    cell.fileOffline.image = #imageLiteral(resourceName: "DownloadingPDF.png")
                } else {
                    if docCV[selectedSubtableNumber].files[indexPath.section][indexPath.row].available {
                        cell.fileOffline.isHidden = true
                    } else {
                        cell.fileOffline.isHidden = false
                        cell.fileOffline.image = #imageLiteral(resourceName: "FileNotAvailable")
                    }
                }
                
                if cell.label.text == currentSelectedFilename {
                    selectedLocalFile = docCV[selectedSubtableNumber].files[indexPath.section][indexPath.row]
                    cell.layer.borderColor = UIColor.yellow.cgColor
                    cell.layer.borderWidth = 3
                    
                    if selectedLocalFile.downloaded {
                        downloadToLocalFileBUtton.isEnabled = true
                    } else {
                        downloadToLocalFileBUtton.isEnabled = selectedLocalFile.available
                    }
                    
                } else {
                    cell.layer.borderColor = UIColor.black.cgColor
                    cell.layer.borderWidth = 1
                }
                
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        if collectionView == self.categoriesCV {
            selectedCategoryTitle.text = categories[indexPath.row]
            selectedCategoryNumber = indexPath.row
            selectedSubtableNumber = 0
            
            dataManager.selectedSubtableNumber = selectedSubtableNumber
            dataManager.selectedCategoryNumber = selectedCategoryNumber

            downloadToLocalFileBUtton.image = #imageLiteral(resourceName: "DownloadPDF.png")
            downloadToLocalFileBUtton.isEnabled = false
            favoriteButton.isEnabled = false
            
            self.selectedCategoryTitle.text = categories[selectedCategoryNumber]
            
            switch categories[selectedCategoryNumber] {
            case "Publications":
                self.economyView.isHidden = true
                self.filesCollectionView.isHidden = false
                self.addNew.isEnabled = true
                self.sortSTButton.isEnabled = true
                self.sortCVButton.isEnabled = true
                if sortSubtableStrings[selectedSortingNumber] == "Tag" {
                    self.editButton.isEnabled = true
                } else {
                    self.editButton.isEnabled = false
                }
                self.notesButton.isEnabled = true
                self.switchView.isEnabled = false
                self.searchButton.isEnabled = true

            case "Economy":
                if switchView.isOn {
                    self.economyView.isHidden = false
                    self.filesCollectionView.isHidden = true
                } else {
                    self.economyView.isHidden = true
                    self.filesCollectionView.isHidden = false
                }
                self.sortSTButton.isEnabled = false
                self.sortCVButton.isEnabled = false
                self.editButton.isEnabled = false
                self.addNew.isEnabled = true
                self.notesButton.isEnabled = false
                self.switchView.isEnabled = true
                self.searchButton.isEnabled = false
                self.searchBar.isHidden = true
                
            default:
                self.economyView.isHidden = true
                self.filesCollectionView.isHidden = false
                self.addNew.isEnabled = false
                self.sortSTButton.isEnabled = false
                self.editButton.isEnabled = false
                self.sortCVButton.isEnabled = true
                self.notesButton.isEnabled = false
                self.switchView.isEnabled = false
                self.searchButton.isEnabled = false
                self.searchBar.isHidden = true
                
            }
            
            populateListTable()
            populateFilesCV()
            sortFiles()
            
            listTableView.reloadData()
            filesCollectionView.reloadData()
            
        } else {
            
            let currentCell = collectionView.cellForItem(at: indexPath) as! FilesCell
            favoriteButton.isEnabled = true
            
            switch categories[selectedCategoryNumber] {
            case "Publications":
                selectedLocalFile = filesCV[indexPath.section][indexPath.row]
                favoriteButton.isEnabled = true
                notesButton.isEnabled = true
            case "Economy":
                favoriteButton.isEnabled = false
                notesButton.isEnabled = false
                selectedLocalFile = docCV[0].files[indexPath.section][indexPath.row]
            default:
                selectedLocalFile = docCV[selectedSubtableNumber].files[indexPath.section][indexPath.row]
                favoriteButton.isEnabled = false
                notesButton.isEnabled = false
            }
            
            if selectedLocalFile.favorite == "Yes" {
                favoriteButton.image = #imageLiteral(resourceName: "star-filled.png")
                favoriteButton.tintColor = UIColor.red
            } else {
                favoriteButton.image = #imageLiteral(resourceName: "star.png")
                favoriteButton.tintColor = UIColor.white
            }
            
            if selectedLocalFile.downloaded {
                downloadToLocalFileBUtton.image = #imageLiteral(resourceName: "HDD-filled")
                downloadToLocalFileBUtton.isEnabled = true
                if categories[selectedCategoryNumber] == "Publications" {
                    notesButton.isEnabled = true
                } else {
                    notesButton.isEnabled = false
                }
            } else {
                downloadToLocalFileBUtton.image = #imageLiteral(resourceName: "DownloadPDF.png")
                downloadToLocalFileBUtton.isEnabled = selectedLocalFile.available
                if categories[selectedCategoryNumber] == "Publications" {
                    notesButton.isEnabled = selectedLocalFile.available
                } else {
                    notesButton.isEnabled = false
                }
            }
            currentSelectedFilename = selectedLocalFile.filename
            
            // Remove PDF from group. FIX: WILL NOT WORK. LET DATAMANAGER DEAL WITH IT
            if categories[selectedCategoryNumber] == "Publications" && editingFilesCV {
                
                if sortTableTitles[indexPath.section] != "All publications" {
                    dataManager.removeFromGroup(file: selectedLocalFile, group: sortTableTitles[indexPath.section])
                }
                
                populateListTable()
                populateFilesCV()
                sortFiles()
                
                listTableView.reloadData()
                filesCollectionView.reloadData()
                
            } else {
                
                if !selectedLocalFile.available && !selectedLocalFile.downloaded && !selectedLocalFile.downloading {
                    print("Downloading " + selectedLocalFile.filename)
                    let fileURL = selectedLocalFile.iCloudURL
                    let filePath = selectedLocalFile.path
                    
                    do {
                        try fileManagerDefault.startDownloadingUbiquitousItem(at: fileURL)
                        sendNotification(text: "Downloading " + selectedLocalFile.filename)
                        
                        let newDownload = DownloadingFile(filename: selectedLocalFile.filename, url: fileURL, downloaded: false, path: filePath, category: selectedCategoryNumber)
                        filesDownloading.append(newDownload)
                        downloadTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(checkIfFileIsDownloaded), userInfo: nil, repeats: true)
                        selectedLocalFile.downloading = true
                        if categories[selectedCategoryNumber] == "Publications" {
                            filesCV[indexPath.section][indexPath.row].downloading = true //FIX: ONLY IF CATEGORY == PUBLICATIONS
                        } else {
                            docCV[selectedSubtableNumber].files[indexPath.section][indexPath.row].downloading = true
                        }
                        dataManager.replaceLocalFileWithNew(newFile: selectedLocalFile)
                        NotificationCenter.default.post(name: Notification.Name.updateView, object: nil)
                    } catch let error {
                        print(error)
                    }
                }

                filesCollectionView.reloadData() //Needed to show currently selected file
                documentPage = 0
                
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
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let sectionHeaderView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "collectionViewHeader", for: indexPath) as! SectionHeaderView

        switch categories[selectedCategoryNumber] {
        case "Publications": //FIX: ADD here
            sectionHeaderView.mainHeaderTitle.text = sortTableTitles[indexPath[0]]
            if filesCV[indexPath[0]].count == 1 {
                sectionHeaderView.subHeaderTitle.text = "\(filesCV[indexPath[0]].count)" + " item"
            } else {
                sectionHeaderView.subHeaderTitle.text = "\(filesCV[indexPath[0]].count)" + " items"
            }
            
//        case "Economy":
//            sectionHeaderView.mainHeaderTitle.text = docCV[0].sectionHeader[indexPath.section]
            
        default:
            sectionHeaderView.mainHeaderTitle.text = docCV[selectedSubtableNumber].sectionHeader[indexPath.section]
            if docCV[selectedSubtableNumber].files[indexPath.section].count == 1 {
                sectionHeaderView.subHeaderTitle.text = "\(docCV[selectedSubtableNumber].files[indexPath.section].count)" + " item"
            } else {
                sectionHeaderView.subHeaderTitle.text = "\(docCV[selectedSubtableNumber].files[indexPath.section].count)" + " items"
            }
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
        print(previewFile.filename)
        if previewFile.downloaded {
            return previewFile.localURL as QLPreviewItem
        } else {
            return previewFile.iCloudURL as QLPreviewItem
        }
    }

    
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.progressMonitor.removeFromSuperview()
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

}


extension ViewController: ExpenseCellDelegate {
    func didTapPDF(item: Expense) {
//        PDFdocument = PDFDocument(url: url)
//        PDFfilename = url.lastPathComponent
//        PDFPath
//
//        icloudFileURL = docCV[selectedSubtableNumber].files[indexPath.section][indexPath.row].iCloudURL
//        localFileURL = docCV[selectedSubtableNumber].files[indexPath.section][indexPath.row].localURL
//
//        let currentFile = docCV[selectedSubtableNumber].files[indexPath.section][indexPath.row]
//        PDFfilename = currentFile.filename
//        PDFPath = currentFile.path
//        if docCV[selectedSubtableNumber].files[indexPath.section][indexPath.row].downloaded {
//            PDFdocument = PDFDocument(url: localFileURL)
//            NotificationCenter.default.post(name: Notification.Name.sendPDFfilename, object: self)
//            performSegue(withIdentifier: "seguePDFViewController", sender: self)
//        } else if icloudFileURL.lastPathComponent.range(of: ".pdf") != nil {
//            folderURL = currentFile.path
//            PDFdocument = PDFDocument(url: icloudFileURL)
//            NotificationCenter.default.post(name: Notification.Name.sendPDFfilename, object: self)
//            performSegue(withIdentifier: "seguePDFViewController", sender: self)
//        } else {
//            previewFile = docCV[selectedSubtableNumber].files[indexPath.section][indexPath.row]
//            previewController.reloadData()
//            navigationController?.pushViewController(previewController, animated: true)
//        }

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






/* MADE INTO MODEL
 
 //WORK IN PROGRESS: ICLOUD LOADING NOT FINISHED WHEN COMPARISON WITH CORE DATA STARTS
 func loadIcloudData() {
 if appDelegate.iCloudAvailable {
 
 // GET PUBLICATIONS
 let query = CKQuery(recordType: "Publications", predicate: NSPredicate(value: true))
 privateDatabase?.perform(query, inZoneWith: recordZone?.zoneID) { (records, error) in
 guard let records = records else {return}
 DispatchQueue.main.async {
 for record in records {
 let thumbnail = self.getThumbnail(url: self.publicationsURL.appendingPathComponent(record.object(forKey: "Filename") as! String), pageNumber: 0)
 let newPublication = PublicationFile(filename: record.object(forKey: "Filename") as! String, title: record.object(forKey: "Title") as? String, year: record.object(forKey: "Year") as? Int16, thumbnails: [thumbnail], category: "Publications", rank: record.object(forKey: "Rank") as? Float, note: record.object(forKey: "Note") as? String, dateCreated: record.creationDate, dateModified: record.modificationDate, favorite: record.object(forKey: "Favorite") as? String, author: record.object(forKey: "Author") as? String, journal: record.object(forKey: "Journal") as? String, groups: record.object(forKey: "Group") as! [String?])
 self.publicationsIC.append(newPublication)
 }
 NotificationCenter.default.post(name: Notification.Name.icloudFinished, object: nil)
 }
 }
 
 // GET PROJECTS
 let queryProjects = CKQuery(recordType: "Projects", predicate: NSPredicate(value: true))
 privateDatabase?.perform(queryProjects, inZoneWith: recordZone?.zoneID) { (records, error) in
 guard let records = records else {return}
 DispatchQueue.main.async {
 for record in records {
 let newProject = ProjectFile(name: record.object(forKey: "Name") as! String, amountReceived: record.object(forKey: "AmountReceived") as! Int32, amountRemaining: record.object(forKey: "AmountRemaining") as! Int32, expenses: [])
 self.projectsIC.append(newProject)
 }
 }
 }
 
 // GET EXPENSES
 let queryExpenses = CKQuery(recordType: "Expenses", predicate: NSPredicate(value: true))
 privateDatabase?.perform(queryExpenses, inZoneWith: recordZone?.zoneID) { (records, error) in
 guard let records = records else {return}
 DispatchQueue.main.async {
 for record in records {
 let newExpense = ExpenseFile(amount: record.object(forKey: "Amount") as! Int32, reference: record.object(forKey: "Reference") as? String, overhead: record.object(forKey: "Overhead") as? Int16, comment: record.object(forKey: "Comment") as? String, pdfURL: nil, localFile: nil, belongsToProject: record.object(forKey: "BelongsToProject") as! String)
 self.expensesIC.append(newExpense)
 }
 print(self.expensesIC)
 }
 }
 
 // GET BOOKMARKS FIX
 let queryBookmarks = CKQuery(recordType: "Bookmarks", predicate: NSPredicate(value: true))
 privateDatabase?.perform(queryBookmarks, inZoneWith: recordZone?.zoneID) { (records, error) in
 guard let records = records else {return}
 DispatchQueue.main.async {
 for record in records {
 let newBookmark = BookmarkFile(filename: (record.object(forKey: "filename") as? String)!, path: (record.object(forKey: "path") as? String)!, category: (record.object(forKey: "category") as? String)!, lastPageVisited: record.object(forKey: "lastPageVisited") as? Int32, page: record.object(forKey: "page") as? [Int])
 self.bookmarksIC.append(newBookmark)
 }
 print(self.bookmarksIC)
 }
 }
 
 } else {
 
 print("Icloud not available")
 
 }
 }
*/

