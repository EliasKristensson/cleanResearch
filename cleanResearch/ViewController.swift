//
//  ViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-04-04.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

//FIX! WHEN AUTHOR IS REMOVED, CANNOT SCROLL TO ITEM
//CANNOT SEARCH ALL CATEGORIES


import UIKit
import CloudKit
import PDFKit
import MobileCoreServices
import Foundation
import CoreData
import QuickLook
import AVKit
import AVFoundation
import AudioToolbox

var mainVC: ViewController?

protocol ExpenseCellDelegate {
    func didTapPDF(item: Expense)
}

class categoryCell: UICollectionViewCell {
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var number: UILabel!
    @IBOutlet weak var saveNumber: UILabel!
    @IBOutlet weak var progressCircle: CircularProgressView!

    override func awakeFromNib() {
        super.awakeFromNib()
        progressCircle.trackClr = UIColor.white
        progressCircle.progressClr = UIColor.red
    }
    
}

class SectionHeaderView: UICollectionReusableView {
    @IBOutlet weak var mainHeaderTitle: UILabel!
    @IBOutlet weak var subHeaderTitle: UILabel!
}

class ListCell: UITableViewCell {
    @IBOutlet weak var listLabel: UILabel!
    @IBOutlet weak var listNumberOfItems: UILabel!
}

class ApplicantListCell: UITableViewCell {
    @IBOutlet weak var applicantListName: UILabel!
    @IBOutlet weak var applicantListGrade: UILabel!
}

class FilesCell: UICollectionViewCell {
    
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var favoriteIcon: UIButton!
    @IBOutlet weak var deleteIcon: UIImageView!
    @IBOutlet weak var fileOffline: UIImageView!
    @IBOutlet weak var downloadingIndicator: UIActivityIndicatorView!
    @IBOutlet weak var sizeLabel: UILabel!
    
    @IBOutlet weak var gradeIcon: UIImageView!
    @IBOutlet weak var readListIcon: UIImageView!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var timesViewed: UILabel!
    
}

class EconomyCell: UITableViewCell {
    
    var expenseItem: Expense!
    var delegate: ExpenseCellDelegate?
    
    @IBOutlet weak var expenseAmount: UILabel!
    @IBOutlet weak var overheadAmount: UILabel!
    @IBOutlet weak var referenceString: UILabel!
    @IBOutlet weak var commentString: UILabel!
    @IBOutlet weak var pdfButton: UIButton!
    @IBOutlet weak var typeString: UILabel!
    
    
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


class MemoCell: UICollectionViewCell {

    var color: String!
    var id: Int64!
    
    @IBOutlet weak var memoImage: UIImageView!
    @IBOutlet weak var memoTitle: UITextField!
    @IBOutlet weak var noteText: UITextView!
    @IBOutlet weak var noteButton: UIButton!
    @IBOutlet weak var titleButton: UIButton!
    
    @IBAction func setYellow(_ sender: Any) {
        color = "Yellow"
        NotificationCenter.default.post(name: Notification.Name.saveAndUpdateMemos, object: self)
    }
    @IBAction func setBlue(_ sender: Any) {
        color = "Blue"
        NotificationCenter.default.post(name: Notification.Name.saveAndUpdateMemos, object: self)
    }
    @IBAction func setGreen(_ sender: Any) {
        color = "Green"
        NotificationCenter.default.post(name: Notification.Name.saveAndUpdateMemos, object: self)
    }
    @IBAction func setRed(_ sender: Any) {
        color = "Red"
        NotificationCenter.default.post(name: Notification.Name.saveAndUpdateMemos, object: self)
    }
    @IBAction func setWhite(_ sender: Any) {
        color = "White"
        NotificationCenter.default.post(name: Notification.Name.saveAndUpdateMemos, object: self)
    }
    @IBAction func startEditing(_ sender: Any) {
        noteText.becomeFirstResponder()
    }
    
    @IBAction func saveMemo(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name.saveAndUpdateMemos, object: self)
    }
    
    @IBAction func titleEditingEnded(_ sender: Any) {
        
        NotificationCenter.default.post(name: Notification.Name.saveAndUpdateMemos, object: self)
    }
    
    @IBAction func titleEditingBegan(_ sender: Any) {
        memoTitle.becomeFirstResponder()
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
    var kvStorage: NSUbiquitousKeyValueStore!
    var icloudAvailable: Bool? = nil
    var icloudFileURL: URL!
    var iCloudSynd = true
    var scanForFiles = false
    var scanIndex: Float = 0
    var scanFiles: Float = 0
    
    //MARK: - Custom classes/structs
    let fileHandler = FileHandler()
    var dataManager: DataManager!
    var navigator: Navigator!
    var pdfViewManager: PDFViewManager!
    var progressMonitor: ProgressMonitor!
    var progressMonitorSettings: [CGFloat]!
    
    //MARK: - Document directory
    var docsURL: URL!
    var localFileURL: URL!
    var folderURL: String!
    let fileManagerDefault = FileManager.default
    
    // MARK: - UI variables
    var categories: [String] = [""]
    var settingsCollectionViewBox = CGSize(width: 250, height: 230)
    var notesBox = CGSize(width: 260, height: 350)
    var editingFilesCV = false
    var currentSelectedFilename: String? = nil
    var currentSelectedMemo: MemoCell? = nil
    var selectedInvoice: String? = nil
    var currentExpense: Expense!
    var currentProject: Project!
    var currentFund: FundingOrganisation!
    
    var sortTableListBox = CGSize(width: 348, height: 28)
    var sortCVBox = CGSize(width: 219, height: 50) //50?
    var systemInfoBox = CGSize(width: 300, height: 50)
    var bookmarkBox = CGSize(width: 200, height: 450)
    var bulletinBox = CGSize(width: 250, height: 350)
    var selectedApplicant = 0

    var filesCV: [[LocalFile]] = [[]] //Place files to be displayed in collection view here (ONLY PUBLICATIONS!)
    var docCV: [DocCV] = []
    var memosCV: [Int64] = []
    let sortSubtableStrings = ["Tag", "Author", "Journal", "Year", "Rank"] //Only for publications
    let filelistOptions = ["Main", "Subfolder"]
    let sortCVStrings: [String] = ["Filename", "Date", "Views"]
    let recentStrings = ["Last hour", "Last 4 hours", "Last 8 hours", "Last day", "Last 2 days", "Last week", "Last 2 weeks", "Last month", "Favorites", "Fast folder"]
    let economyStrings = ["Projects", "Invoices", "Grants"]
    let workDocStrings = ["Files", "Hiring"]
    
    var isLandscape = UIApplication.shared.statusBarOrientation.isLandscape
    
    var selectedSortingNumber = 0
    var selectedEconomyNumber = 0
    var selectedWorkDocNumber = 0
    var selectedSortingCVNumber = 0
    var selectedFile: [SelectedFile] = []
    var selectedLocalFile: LocalFile!
    var previewFile: LocalFile!
    var subFoldersList: [[String]] = [[""]]
    var applicantTableTitles: [String] = [""]
    var sectionTitles: [[String]] = [[""]]

    var yearsString: [String] = [""]
    
    var dateFormatter = DateFormatter()
    
    var PDFdocument: PDFDocument!
    var PDFfilename: String!
    var PDFPath: String?
    var annotationSettings: [Int] = [2, 29, 9, 6, 41, 10, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    var orderedCategories: [Categories]!
    var uploadDate: Date? = nil
    
    var downloadTimer: Timer!
    var dimmerTimer: Timer!
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
    
    var recentDays: Int!
    var goToPage: Int32? = nil
    
    var keyboardSize: CGFloat = 415
    var keyboardVisible: Bool = false
    var memoPosition: CGFloat = 0
    var memoCVOrigin: CGFloat = 0
    
    let progressCircleTime = 0.75

    // MARK: - Outlets
    @IBOutlet var mainView: UIView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var economyView: UIView!
    @IBOutlet weak var mainHeader: UILabel!
    @IBOutlet weak var scholarView: UIView!
    @IBOutlet weak var applicantView: UIView!
    @IBOutlet weak var settingsView: UIView!
    @IBOutlet weak var searchCollectionView: UICollectionView!
    @IBOutlet weak var applicantTableList: UITableView!
    @IBOutlet weak var listTableView: UITableView!
    @IBOutlet weak var filesCollectionView: UICollectionView!
    @IBOutlet weak var memosCollectionView: UICollectionView!
    @IBOutlet weak var selectedCategoryTitle: UILabel!
    @IBOutlet weak var categoriesCV: UICollectionView!
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
    @IBOutlet weak var expenseBackgroundView: UIView!
    @IBOutlet weak var amountBackgroundView: UIView!
    @IBOutlet weak var deadlineString: UILabel!
    @IBOutlet weak var salaryYearString: UILabel!
    @IBOutlet weak var salaryYearStepper: UIStepper!
    @IBOutlet weak var expenseTypeControl: UISegmentedControl!
    
    //Scholar view
    @IBOutlet weak var nameOrganisation: UILabel!
    @IBOutlet weak var internetAddressOrganisation: UITextField!
    @IBOutlet weak var amountFunding: UITextField!
    @IBOutlet weak var currencyFunding: UITextField!
    @IBOutlet weak var organisationInstructions: UITextView!
    @IBOutlet weak var organisationDeadline: UIDatePicker!
    
    //Applicants view
    @IBOutlet weak var applicantName: UITextField!
    @IBOutlet weak var applicantEducation: UITextField!
    @IBOutlet weak var applicantQualify: UISegmentedControl!
    @IBOutlet weak var applicantGrade: UISlider!
    @IBOutlet weak var applicantGradeValue: UILabel!
    @IBOutlet weak var applicantNotes: UITextView!
    @IBOutlet weak var applicantHeader: UILabel!
    @IBOutlet weak var applicantCVicon: UIButton!
    @IBOutlet weak var applicantPLicon: UIButton!
    @IBOutlet weak var applicantLoRicon: UIButton!
    @IBOutlet weak var applicantGradesIcon: UIButton!
    @IBOutlet weak var activityCV: UIActivityIndicatorView!
    @IBOutlet weak var activityPL: UIActivityIndicatorView!
    @IBOutlet weak var activityGrades: UIActivityIndicatorView!
    @IBOutlet weak var activityLoR: UIActivityIndicatorView!
    @IBOutlet weak var searchButton: UIBarButtonItem!
    @IBOutlet weak var searchBar: UISearchBar!
    
    @IBOutlet weak var optionsSegment: UISegmentedControl!
    
    @IBOutlet weak var bookmarksButton: UIBarButtonItem!
    @IBOutlet weak var readingListBUtton: UIBarButtonItem!
    
    @IBOutlet weak var iCloudSyncProgress: UIProgressView!
    
    @IBOutlet weak var iCloudUploadProgress: UIProgressView!
    
    @IBOutlet weak var icloudProgressText: UILabel!
    
    @IBOutlet weak var lastUploadLabel: UILabel!
    
    @IBOutlet weak var scanFilesProgress: UIProgressView!
    
    @IBOutlet weak var addToBulletinButton: UIBarButtonItem!
    
    @IBOutlet weak var categoryIndicator: UILabel!
    
    
    
    
    // MARK: - IBActions
    
    @IBAction func readingListTapped(_ sender: Any) {
        print("readingListTapped")
        
        let path = selectedLocalFile.path
        
        if dataManager.readingListCD.first(where: {$0.path == path}) == nil {
            readingListBUtton.image = #imageLiteral(resourceName: "glasses-filled")
            readingListBUtton.tintColor = UIColor.red
        } else {
            readingListBUtton.image = #imageLiteral(resourceName: "glasses")
            readingListBUtton.tintColor = UIColor.white
        }
        
        dataManager.addOrRemoveFileFromReadingList(file: selectedLocalFile)
        
//        populateListTable()
//        populateFilesCV()
//        sortFiles()
//        listTableView.reloadData()
        categoriesCV.reloadData()
        filesCollectionView.reloadData()
        
    }
    
    @IBAction func applicationNotesTapped(_ sender: Any) {
        
    }
    
    @IBAction func saveApplicantInfo(_ sender: Any) {
        updateApplicant()
    }
    
    @IBAction func expenseTypeChanged(_ sender: Any) {
        let types = ["Expense", "Salary"]
        let type = types[expenseTypeControl.selectedSegmentIndex]
        if type == "Expense" {
            salaryYearString.isHidden = true
            salaryYearStepper.isHidden = true
        } else {
            salaryYearString.isHidden = false
            salaryYearStepper.isHidden = false
        }
    }
    
    @IBAction func salaryYearChanged(_ sender: Any) {
        if salaryYearStepper.value == 1 {
            salaryYearString.text = "\(Int(salaryYearStepper.value))" + " year"
        } else {
            salaryYearString.text = "\(Int(salaryYearStepper.value))" + " years"
        }
    }
    
    @IBAction func optionsChangedValue(_ sender: Any) {

        if navigator.selected.category == "Publications" {
            
            dataManager.pubOption = optionsSegment.selectedSegmentIndex
            
            selectedSortingNumber = optionsSegment.selectedSegmentIndex
            
            kvStorage.set(selectedSortingNumber, forKey: "selectedSortingNumber")
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
            
            if currentSelectedFilename != nil && selectedLocalFile.category == "Publications" {
                attemptScrolling(filename: currentSelectedFilename!)
            }
            
        }  else if navigator.selected.category == "Teaching" {
            
            navigator.selected.folderLevel = optionsSegment.selectedSegmentIndex
            
            if navigator.selected.folderLevel == 1 {
                navigator.list.sub = subFoldersList[navigator.selected.mainFolderNumber!] //selectedSubtableNumber]
//                navigator.list.main = subFoldersList[navigator.selected.mainFolderNumber!] //selectedSubtableNumber]
            } else {
                populateListTable()
                populateFilesCV()
                sortFiles()
            }
            
            self.listTableView.reloadData()
            self.filesCollectionView.reloadData()
            
        } else if navigator.selected.category == "Economy" {
            
            dataManager.economyOption = optionsSegment.selectedSegmentIndex
            selectedEconomyNumber = optionsSegment.selectedSegmentIndex
            
            kvStorage.set(selectedEconomyNumber, forKey: "selectedEconomyNumber")
            kvStorage.synchronize()

            if economyStrings[selectedEconomyNumber] == "Projects" {
                self.economyView.isHidden = false
                self.filesCollectionView.isHidden = true
                self.scholarView.isHidden = true
            } else if economyStrings[selectedEconomyNumber] == "Invoices" {
                self.economyView.isHidden = true
                self.filesCollectionView.isHidden = false
                self.filesCollectionView.reloadData()
                self.scholarView.isHidden = true
            } else if economyStrings[selectedEconomyNumber] == "Grants" {
                self.scholarView.isHidden = false
                self.economyView.isHidden = true
                self.filesCollectionView.isHidden = true
            }
            self.populateListTable()
            self.populateFilesCV()
            self.listTableView.reloadData()
            
        }  else if navigator.selected.category == "Work documents" {
            
            dataManager.workDocOption = optionsSegment.selectedSegmentIndex
            
            selectedWorkDocNumber = optionsSegment.selectedSegmentIndex
            
            kvStorage.set(selectedWorkDocNumber, forKey: "selectedWorkDocNumber")
            kvStorage.synchronize()
            
            if workDocStrings[selectedWorkDocNumber] == "Files" {
                self.applicantView.isHidden = true
                self.filesCollectionView.isHidden = false
                
            } else if workDocStrings[selectedWorkDocNumber] == "Hiring" {
                
                self.navigator.selected.tableNumber = 0
//                self.selectedSubtableNumber = 0
                self.applicantView.isHidden = false
                self.filesCollectionView.isHidden = true
            }
            self.populateListTable()
            self.populateFilesCV()
            self.listTableView.reloadData()
        }
    }
    
    @IBAction func favoriteTapped(_ sender: Any) {
        print("favoriteTapped")
        
        let path = selectedLocalFile.path
        let type = selectedLocalFile.category
        
        if dataManager.favoritesCD.first(where: {$0.path == path}) != nil {
            favoriteButton.image = #imageLiteral(resourceName: "star-filled")
            favoriteButton.tintColor = UIColor.red
            selectedLocalFile.favorite = "Yes"
        } else {
            favoriteButton.image = #imageLiteral(resourceName: "star")
            favoriteButton.tintColor = UIColor.white
            selectedLocalFile.favorite = "No"
        }

        dataManager.addOrRemoveFileFromFavorite(file: selectedLocalFile)
        
        if dataManager.favoritesCD.first(where: {$0.path == selectedLocalFile.path}) != nil {
            favoriteButton.image = #imageLiteral(resourceName: "star-filled")
            favoriteButton.tintColor = UIColor.red
            dataManager.updateIcloud(file: selectedLocalFile, oldFilename: nil, newFilename: nil, expense: nil, project: nil, type: "Favorites add", bookmark: nil, fund: nil)
        } else {
            favoriteButton.image = #imageLiteral(resourceName: "star.png")
            favoriteButton.tintColor = UIColor.white
            dataManager.updateIcloud(file: selectedLocalFile, oldFilename: nil, newFilename: nil, expense: nil, project: nil, type: "Favorites remove", bookmark: nil, fund: nil)
        }
        
        if type == "Publications" || type == "Books" {
            dataManager.updateIcloud(file: selectedLocalFile, oldFilename: nil, newFilename: nil, expense: nil, project: nil, type: type, bookmark: nil, fund: nil)
            dataManager.updateCoreData(file: selectedLocalFile, oldFilename: nil, newFilename: nil)
        }
        
        filesCollectionView.reloadData()
        
    }
    
    @IBAction func downloadToLocalFileTapped(_ sender: Any) {
        
        downloadToLocalFileBUtton.tintColor = UIColor.red
        if selectedLocalFile.downloaded {
            downloadToLocalFileBUtton.image = #imageLiteral(resourceName: "cancel-filled.png")
        } else {
            downloadToLocalFileBUtton.image = #imageLiteral(resourceName: "submit-progress.png")
        }
        
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
                        self.updateView()
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
            
            self.downloadToLocalFileBUtton.tintColor = UIColor.white
            
            self.populateListTable()
            self.populateFilesCV()
            self.sortFiles()
            
            self.listTableView.reloadData()
            self.filesCollectionView.reloadData()
        }
    }
    
    @IBAction func addExpenseTapped(_ sender: Any) {
        let types = ["Expense", "Salary"]
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
        let type = types[expenseTypeControl.selectedSegmentIndex]
        let year = Int16(salaryYearStepper.value)
        
        dataManager.addExpense(amount: amount, OH: OH, comment: comment, reference: reference, type: type, year: year)
        
        self.expensesTableView.reloadData()
    }
    
    @IBAction func addNewGroup(_ sender: Any) {
        
        switch navigator.selected.category {
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
            
        case "Books":
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
            
            if economyStrings[selectedEconomyNumber] == "Projects" {
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
                inputNewProject.addTextField(configurationHandler: { (inputNewProject: UITextField) -> Void in
                    var dateComponents = DateComponents()
                    dateComponents.year = 1
                    let deadlineOneYear = Calendar.current.date(byAdding: dateComponents, to: Date())
                    let deadline = self.fileHandler.getDeadline(date: deadlineOneYear, string: nil, option: nil)
                    inputNewProject.text = deadline.string!
                })
                inputNewProject.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                    let newProject = inputNewProject.textFields?[0]
                    let amount = inputNewProject.textFields?[1]
                    let currency = inputNewProject.textFields?[2]
                    let deadline = inputNewProject.textFields?[3]
                    self.dataManager.addNewItem(title: newProject?.text, number: [amount?.text, currency?.text, deadline?.text])
                    
                    inputNewProject.dismiss(animated: true, completion: nil)
                    
                    self.populateListTable()
                    self.populateFilesCV()
                    self.sortFiles()
                    
                    self.categoriesCV.reloadData()
                    self.listTableView.reloadData()
                    self.filesCollectionView.reloadData()
                    
                    self.categoriesCV.selectItem(at: IndexPath(row: (self.navigator.selected.categoryNumber)!, section: 0), animated: true, scrollPosition: .top)
                }))
                inputNewProject.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                    inputNewProject.dismiss(animated: true, completion: nil)
                }))
                self.present(inputNewProject, animated: true, completion: nil)
                
            } else if economyStrings[selectedEconomyNumber] == "Grants" {
                
                let inputNewFund = UIAlertController(title: "New organisation", message: "Enter name of new funding organisation", preferredStyle: .alert)
                inputNewFund.addTextField(configurationHandler: { (inputNewFund: UITextField) -> Void in
                    inputNewFund.placeholder = "Enter organisation name"
                })
                inputNewFund.addTextField(configurationHandler: { (inputNewFund: UITextField) -> Void in
                    inputNewFund.placeholder = "Input approximative amount"
                })
                inputNewFund.addTextField(configurationHandler: { (inputNewFund: UITextField) -> Void in
                    inputNewFund.text = "Euro"
                })
                inputNewFund.addTextField(configurationHandler: { (inputNewFund: UITextField) -> Void in
                    var dateComponents = DateComponents()
                    dateComponents.year = 1
                    let deadlineOneYear = Calendar.current.date(byAdding: dateComponents, to: Date())
                    let deadline = self.fileHandler.getDeadline(date: deadlineOneYear, string: nil, option: nil)
                    inputNewFund.text = deadline.string!
                })
                inputNewFund.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                    let newName = inputNewFund.textFields?[0]
                    let amount = inputNewFund.textFields?[1]
                    let currency = inputNewFund.textFields?[2]
                    let deadline = inputNewFund.textFields?[3]
                    self.dataManager.addNewItem(title: newName?.text, number: [amount?.text, currency?.text, deadline?.text])
                    
                    inputNewFund.dismiss(animated: true, completion: nil)
                    
                    self.populateListTable()
//                    self.populateFilesCV()
                    self.sortFiles()
                    
                    self.categoriesCV.reloadData()
                    self.listTableView.reloadData()
//                    self.filesCollectionView.reloadData()
                    
//                    self.categoriesCV.selectItem(at: IndexPath(row: self.navigator.selected.categoryNumber, section: 0), animated: true, scrollPosition: .top)
                }))
                inputNewFund.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                    inputNewFund.dismiss(animated: true, completion: nil)
                }))
                self.present(inputNewFund, animated: true, completion: nil)
            }
            
        case "Notes":

            let filename = dataManager.createBlankPDF(category: "Notes")
            let number = categories.index(where: { $0 == navigator.selected.category })
            dataManager.reloadLocalFiles(category: number!)
            
            populateListTable()
            populateFilesCV()
            
            var load = false
            for folder in docCV {
                if folder.listTitle == "Uncategorized" {
                    for i in 0..<folder.files.count {
                        for file in folder.files[i] {
                            if file.filename == filename {
                                load = true
                                selectedLocalFile = file
                            }
                        }
                    }
                }
            }
            
            if load {
                PDFdocument = PDFDocument(url: selectedLocalFile.iCloudURL)
                performSegue(withIdentifier: "seguePDFViewController", sender: self)
            }
            
        case "Memos":
            self.dataManager.addNewItem(title: navigator.list.main[navigator.selected.tableNumber], number: [""])
            self.populateFilesCV()
            self.memosCollectionView.reloadData()
            
        case "Teaching":
            performSegue(withIdentifier: "examSegue", sender: self)
            
        case "Bulletin board":
            
            let inputNewBulletin = UIAlertController(title: "New bulletin", message: "Enter name of new bulletin board", preferredStyle: .alert)
            inputNewBulletin.addTextField(configurationHandler: { (newBulletin: UITextField) -> Void in
                newBulletin.placeholder = "Enter name"
            })
            inputNewBulletin.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                let newName = inputNewBulletin.textFields?[0]
                if let title = newName?.text {
                    self.dataManager.addNewItem(title: title, number: [""])
                    self.populateListTable()
                    self.populateFilesCV()
                    self.sortFiles()

                    self.listTableView.reloadData()
                    self.filesCollectionView.reloadData()
                }
                inputNewBulletin.dismiss(animated: true, completion: nil)
                
            }))
            inputNewBulletin.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                inputNewBulletin.dismiss(animated: true, completion: nil)
            }))
            self.present(inputNewBulletin, animated: true, completion: nil)
            
        default:
            print("110")
        }
    }
    
    @IBAction func editIconTapped(_ sender: Any) {
        editingFilesCV = !editingFilesCV
        if navigator.selected.category != "Memos" {
            filesCollectionView.reloadData()
        } else {
            saveAndUpdateMemos()
            memosCollectionView.reloadData()
        }
    }
    
    @IBAction func amountReceivedEdited(_ sender: Any) {
        print("amountReceivedEdited")
        print(amountReceivedString.text!)
        
        let amountReceived = isStringAnInt(stringNumber: amountReceivedString.text!)
        print(amountReceived)
        dataManager.amountReceivedChanged(amountReceived: amountReceived)
        
        self.expensesTableView.reloadData()
    }
    
    @IBAction func sortCV(_ sender: Any) {
        
    }
    
    @IBAction func searchButtonTapped(_ sender: Any) {
        searchHidden = !searchHidden
        searchBar.isHidden = searchHidden
        dataManager.isSearching = !searchHidden
        dataManager.searchString = ""
        searchBar.text = ""
        
        if !dataManager.isSearching {
            populateListTable()
            populateFilesCV()
            sortFiles()
            
            listTableView.reloadData()
            filesCollectionView.reloadData()
        } else {
            searchBar.becomeFirstResponder()
        }
    }
    
    @IBAction func saveFundingOrganisation(_ sender: Any) {
        let currentOrganisation = dataManager.fundCD[navigator.selected.tableNumber]
        currentOrganisation.amount = Int64(isStringAnInt(stringNumber: amountFunding.text))
        currentOrganisation.currency = currencyFunding.text
        currentOrganisation.deadline = organisationDeadline.date
        currentOrganisation.instructions = organisationInstructions.text
        currentOrganisation.website = internetAddressOrganisation.text
        
        dataManager.updateCoreDataFund(fund: currentOrganisation)
        dataManager.updateIcloud(file: nil, oldFilename: nil, newFilename: nil, expense: nil, project: nil, type: "Fund", bookmark: nil, fund: currentOrganisation)
    }
    
    @IBAction func applicantQualifiesChangedValue(_ sender: Any) {
        updateApplicant()
        applicantTableList.reloadData()
    }
    
    @IBAction func applicantGradeChangedValue(_ sender: Any) {
        applicantGradeValue.text = "\(Int(applicantGrade.value))"
        updateApplicant()
        applicantTableList.reloadData()
    }
    
    @IBAction func applicantEducationChangedValue(_ sender: Any) {
        updateApplicant()
    }
    
    @IBAction func CViconTapped(_ sender: Any) {
        print("CV tapped")
        
        openHiringFile(type: "CV.pdf")
    }
    
    @IBAction func PLiconTapped(_ sender: Any) {
        print("PL tapped")
        
        openHiringFile(type: "PL.pdf")
    }
    
    @IBAction func GradesIconTapped(_ sender: Any) {
        print("Grades tapped")
        
        openHiringFile(type: "Grades.pdf")
    }
    
    @IBAction func LoRiconTapped(_ sender: Any) {
        print("LoR tapped")
        
        openHiringFile(type: "LoR.pdf")
    }
    
    @IBAction func applicantNotesTapped(_ sender: Any) {
        performSegue(withIdentifier: "hiringNotesSegue", sender: self)
    }
    
    @IBAction func uploadToIcloud(_ sender: Any) {
        iCloudUploadProgress.progress = 0
        iCloudUploadProgress.isHidden = false
        
        let alert = UIAlertController(title: "Upload to icloud", message: "Are you sure you want to upload current data to iCloud? All saved records will be erased and replaced with the local records.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            self.dataManager.uploadToIcloud()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func syncWithIcloud(_ sender: Any) {
        iCloudSyncProgress.progress = 0
        iCloudSyncProgress.isHidden = false
        
        let alert = UIAlertController(title: "Upload to icloud", message: "Are you sure you want to sync with iCloud? All local records will be erased and replaced with iCloud records.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            self.dataManager.syncWithIcloud()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func syncPublications(_ sender: Any) {
        dataManager.uploadToIcloud()
    }
    
    @IBAction func analyzeFilename(_ sender: Any) {

        scanIndex = 0
        scanFiles = Float(self.dataManager.localFiles[self.categories.index(where: { $0 == "Publications" })!].count)
        self.scanFilesProgress.isHidden = false

        let alert = UIAlertController(title: "Scan filenames", message: "Are you sure you want to scan ALL publication files and use their filenames to extract authors and publication year? Example Kristensson2015b", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            let indexC = self.categories.index(where: { $0 == "Publications" })
            let files = self.dataManager.localFiles[indexC!]
            
            for file in files {
                var newFile = file
                let fileData = self.dataManager.findAuthorAndYear(filename: newFile.filename)
                if file.author == "No author" || file.author == nil {
                    newFile.author = fileData.author
                }
                if file.year != -2000 {
                    newFile.year = Int16(fileData.year)
                }
                if let index = self.dataManager.localFiles[indexC!].index(where: {$0.filename == newFile.filename}) {
                    self.dataManager.localFiles[indexC!][index] = newFile
                }
                self.dataManager.updateCoreData(file: newFile, oldFilename: nil, newFilename: nil)
                
                print(file.filename)
                print(fileData.author)
                print(fileData.year)
                print("----")
                self.scanIndex = self.scanIndex + 1
                NotificationCenter.default.post(name: Notification.Name.updateScanProgress, object: self)
                if self.scanFilesProgress.progress >= 1 {
                    self.scanFilesProgress.isHidden = true
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            self.scanFilesProgress.isHidden = true
        }))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    
    
    
    
    
    // MARK: - ViewDidLoad
    override func viewDidLoad() {
        print("viewDidLoad")
        
        super.viewDidLoad()
        
        
        //MARK: - AppDelegate
        let app = UIApplication.shared
        appDelegate = (app.delegate as! AppDelegate)
        icloudAvailable = appDelegate.iCloudAvailable!
        context = appDelegate.context
        
        self.view.addSubview(progressMonitor)
        progressMonitor.superview?.bringSubview(toFront: progressMonitor)
        
        //DATABASE MANAGER
        dataManager.context = context
        dataManager.progressMonitor = progressMonitor
        dataManager.mainView = self.mainView

        navigator.selected.category = categories[0]
        
        self.categoriesCV.delegate = self
        self.categoriesCV.dataSource = self
        
        self.filesCollectionView.delegate = self
        self.filesCollectionView.dataSource = self
        self.filesCollectionView.dragDelegate = self
        self.filesCollectionView.dropDelegate = self
        self.searchCollectionView.delegate = self
        self.searchCollectionView.dataSource = self
        self.expensesTableView.delegate = self
        self.expensesTableView.dataSource = self
        self.listTableView.delegate = self
        self.listTableView.dataSource = self
        self.listTableView.dropDelegate = self
        self.applicantTableList.dataSource = self
        self.applicantTableList.delegate = self
        self.memosCollectionView.dataSource = self
        self.memosCollectionView.delegate = self
        
        self.previewController.dataSource = self
        self.searchBar.delegate = self
        
        self.docsURL = self.appDelegate.docsDir
        
        mainVC = self
        
        setupNotifications()
        setupNavigationBar()
        
        // Touch gestures
        let doubleTap1 = UITapGestureRecognizer(target: self, action: #selector(self.doubleTapped))
        let doubleTap2 = UITapGestureRecognizer(target: self, action: #selector(self.doubleTapped))
        let longPress1 = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPressCategories(press:)))
        let longPress2 = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPressFiles(press:)))
        doubleTap1.numberOfTapsRequired = 2
        doubleTap2.numberOfTapsRequired = 2
        longPress1.minimumPressDuration = 1
        longPress2.minimumPressDuration = 1
        self.categoriesCV.addGestureRecognizer(longPress1)
        self.filesCollectionView.addGestureRecognizer(doubleTap1)
        self.filesCollectionView.addGestureRecognizer(longPress2)
        self.searchCollectionView.addGestureRecognizer(doubleTap2)
        
//        backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        barColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        
        selectedCategoryTitle.backgroundColor = barColor
        selectedCategoryTitle.textColor = textColor
        mainHeader.backgroundColor = barColor
        listTableView.tintColor = textColor
        applicantHeader.backgroundColor = barColor
        listTableView.backgroundColor = UIColor.clear
        applicantTableList.backgroundColor = UIColor.clear
        
        dataManager.getFolderStructure()

        self.setupUI()
        setNeedsStatusBarAppearanceUpdate()
        
//        isLandscape = UIApplication.shared.statusBarOrientation.isLandscape
        isLandscape = UIDevice.current.orientation.isLandscape
        dataManager.economyOption = optionsSegment.selectedSegmentIndex
        
        self.listTableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .top)
        
    }
    
    
    
    
    
    // MARK: - OBJECT C FUNCTIONS
    @objc func checkForNewFiles() {
//        dataManager.checkForNewFiles()
    }
    
    @objc func checkIfFileIsDownloaded() {
        
        var stillDownloading = false
        for i in 0..<filesDownloading.count {
            if !filesDownloading[i].downloaded {
                do {
                    var file = filesDownloading[i]
                    var filename = file.url.deletingPathExtension().lastPathComponent
                    filename.remove(at: filename.startIndex)
                    let folder = file.url.deletingLastPathComponent()
                    let filePath = folder.appendingPathComponent(filename).path
                    let exist = fileManagerDefault.fileExists(atPath: filePath)
                    
                    if !exist {
                        stillDownloading = true
                    } else {
                        
                        sendNotification(text: filename + " downloaded")
                        file.filename = filename
                        file.url = URL(fileURLWithPath: filePath)
                        filesDownloading[i].downloaded = true
                        
                        dataManager.reloadDownloadedFile(file: file)
                        
                        if categories[filesDownloading[i].category] == "Publications" || categories[filesDownloading[i].category] == "Books" || categories[filesDownloading[i].category] == "Recently" {
                            dataManager.compareLocalFilesWithCoreData()
                        }

                        NotificationCenter.default.post(name: Notification.Name.updateView, object: nil)

                        dataManager.readFastFolder()
                        dataManager.searchFiles()
                        populateFilesCV()
                        sortFiles()

                        if searchCollectionView.isHidden {
                            listTableView.reloadData()
                            filesCollectionView.reloadData()
                        } else {
                            searchCollectionView.reloadData()
                        }
                        
                    }
                }
            }
            
        }
        
        if !stillDownloading {
            downloadTimer.invalidate()
        }
        
        
    }
    
    @objc func dimLabel() {
        UIView.animate(withDuration: 1.5) {
            self.categoryIndicator.alpha = 0
        }
//        categoryIndicator.isHidden = true
    }
        
    @objc func doubleTapped(gesture: UITapGestureRecognizer) {
        print("doubleTapped()")
        
        var indexPath: IndexPath?
        if navigator.selected.category == "Search" {
            let pointInCollectionView = gesture.location(in: self.searchCollectionView)
            if let tmp = self.searchCollectionView.indexPathForItem(at: pointInCollectionView) {
                indexPath = tmp
            }

        } else {
            let pointInCollectionView = gesture.location(in: self.filesCollectionView)
            if let tmp = self.filesCollectionView.indexPathForItem(at: pointInCollectionView) {
                indexPath = tmp
            }
        }

        if indexPath != nil {
            switch navigator.selected.category {

            case "Recently", "Reading list", "Bulletin board", "Search":

                selectedLocalFile = filesCV[indexPath!.section][indexPath!.row]
                
                if !selectedLocalFile.downloading {
                    if selectedLocalFile.iCloudURL.lastPathComponent.range(of: ".pdf") != nil || selectedLocalFile.iCloudURL.lastPathComponent.range(of: ".PDF") != nil {
                        selectedLocalFile = filesCV[indexPath!.section][indexPath!.row]
                        
                        if selectedLocalFile.downloaded {
                            PDFdocument = PDFDocument(url: selectedLocalFile.localURL)
                        } else {
                            PDFdocument = PDFDocument(url: selectedLocalFile.iCloudURL)
                        }
                        
                        performSegue(withIdentifier: "seguePDFViewController", sender: self)
                        
                    } else {
                        previewOrPlayFile()
                    }
                    dataManager.addFileToRecent(file: selectedLocalFile)
                }
                
            case "Publications":
                
                selectedLocalFile = filesCV[indexPath!.section][indexPath!.row]
                
                if !selectedLocalFile.downloading {
                    if selectedLocalFile.downloaded {
                        PDFdocument = PDFDocument(url: selectedLocalFile.localURL)
                    } else {
                        PDFdocument = PDFDocument(url: selectedLocalFile.iCloudURL)
                    }
                    
                    if dataManager.publicationsCD.first(where: {$0.filename == selectedLocalFile.filename}) == nil {
                        dataManager.addFileToCoreData(file: selectedLocalFile)
                    }
                    
                    performSegue(withIdentifier: "seguePDFViewController", sender: self)
                    dataManager.addFileToRecent(file: selectedLocalFile)
                }
                
            case "Books":
                
                selectedLocalFile = filesCV[indexPath!.section][indexPath!.row]
                
                if !selectedLocalFile.downloading {
                    if selectedLocalFile.iCloudURL.lastPathComponent.range(of: ".pdf") != nil || selectedLocalFile.iCloudURL.lastPathComponent.range(of: ".PDF") != nil {
                        if selectedLocalFile.downloaded {
                            PDFdocument = PDFDocument(url: selectedLocalFile.localURL)
                        } else {
                            PDFdocument = PDFDocument(url: selectedLocalFile.iCloudURL)
                        }
                        
                        if dataManager.booksCD.first(where: {$0.filename == selectedLocalFile.filename}) == nil {
                            dataManager.addFileToCoreData(file: selectedLocalFile)
                        }
                        
                        performSegue(withIdentifier: "seguePDFViewController", sender: self)
                    } else {
                        previewOrPlayFile()
                    }
                    dataManager.addFileToRecent(file: selectedLocalFile)
                }
                
            case "Fast folder":
                
                selectedLocalFile = filesCV[indexPath!.section][indexPath!.row]
                
                if !selectedLocalFile.downloading {
                    if selectedLocalFile.iCloudURL.lastPathComponent.range(of: ".pdf") != nil || selectedLocalFile.iCloudURL.lastPathComponent.range(of: ".PDF") != nil {
                        if selectedLocalFile.downloaded {
                            PDFdocument = PDFDocument(url: selectedLocalFile.localURL)
                        } else {
                            PDFdocument = PDFDocument(url: selectedLocalFile.iCloudURL)
                        }
                        
                        performSegue(withIdentifier: "seguePDFViewController", sender: self)
                    } else {
                        previewOrPlayFile()
                    }
                    dataManager.addFileToRecent(file: selectedLocalFile)
                }
            default:
                
                selectedLocalFile = docCV[navigator.selected.tableNumber].files[indexPath!.section][indexPath!.row]
                
                if !selectedLocalFile.downloading {
                    if selectedLocalFile.iCloudURL.lastPathComponent.range(of: ".pdf") != nil || selectedLocalFile.iCloudURL.lastPathComponent.range(of: ".PDF") != nil {
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
                    } else {
                        previewOrPlayFile()
                    }
                    dataManager.addFileToRecent(file: selectedLocalFile)
                }
            }
        }
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @objc func fileAddedToBulletin(notification: Notification) {
        let vc = notification.object as! BulletinListViewController
        
        if vc.selectedBulletin != nil {
            let message = dataManager.addFileToBulletin(bulletin: vc.selectedBulletin!, file: selectedLocalFile)
            sendNotification(text: message)
        }
    }
    
    @objc func handleApplicantNotesClosing(notification: Notification) {
        
        let vc = notification.object as! HiringNotesViewController
        
        applicantNotes.text = vc.notes.text
        updateApplicant()
    }
    
    @objc func handleExamClosing(notification: Notification) {
        let vc = notification.object as! ScoreViewController
        if vc.selectedExam != nil {
            let selectedExam = vc.selectedExam!
            let folderPath = navigator.path
            
            selectedExam.path = folderPath

            dataManager.saveCoreData()
            dataManager.loadCoreData()
            filesCollectionView.reloadData()
        }
    }
    
    @objc func handleSettingsPopupClosing(notification: Notification) {
        let settingsVC = notification.object as! SettingsViewController
        iCloudSynd = settingsVC.syncWithIcloud.isOn
        scanForFiles = settingsVC.scanForNewFiles.isOn
        recentDays = settingsVC.recentDays
//        if settingsVC.scanForNewFiles.isOn {
//            if !searchForFilesTimer.isValid {
//                searchForFilesTimer = Timer.scheduledTimer(timeInterval: 300, target: self, selector: #selector(checkForNewFiles), userInfo: nil, repeats: true)
//            }
//        } else {
//            searchForFilesTimer.invalidate()
//        }
        
        kvStorage.set(settingsVC.scanForNewFiles.isOn, forKey: "scanForFiles")
        kvStorage.set(iCloudSynd, forKey: "iCloudSynd")
        kvStorage.set(recentDays, forKey: "recentDays")
        kvStorage.synchronize()
        
        self.populateListTable()
        self.populateFilesCV()
        self.sortFiles()
        
        self.categoriesCV.reloadData()
        self.listTableView.reloadData()
        self.filesCollectionView.reloadData()
    }
    
    @objc func handlePDFClosing(notification: Notification) {
        print("handlePDFClosing()")
        
        isLandscape = UIDevice.current.orientation.isLandscape

        setupProgressMonitor()
        setupNavigationBar()
                
        let vc = notification.object as! PDFViewController
        annotationSettings = vc.annotationSettings!
        pdfViewManager = vc.pdfViewManager
        
        self.view.addSubview(self.progressMonitor) //BEHÖVS DETTA?
        progressMonitor.superview?.bringSubview(toFront: progressMonitor)
        
        kvStorage.set(annotationSettings, forKey: "annotationSettings")
        kvStorage.synchronize()
        
        print(pdfViewManager)
        
        if pdfViewManager.changesMade {
            dataManager.savePDF(file: vc.currentFile, document: vc.document)
            pdfViewManager.changesMade = false
        }
        
        dataManager.addFileToRecent(file: vc.currentFile)
        dataManager.saveBookmark(file: vc.currentFile, bookmark: vc.bookmarks)
        dataManager.updateLocalFile(file: vc.currentFile, bookmark: vc.bookmarks, thumbnail: vc.document.page(at: 0)!.thumbnail(of: CGSize(width: 210, height: 297), for: .artBox))

        if vc.currentFile.category == "Publications" || vc.currentFile.category == "Books" {
            dataManager.updateIcloud(file: vc.currentFile, oldFilename: nil, newFilename: nil, expense: nil, project: nil, type: vc.currentFile.category, bookmark: nil, fund: nil)
            dataManager.updateCoreData(file: vc.currentFile, oldFilename: nil, newFilename: nil)
        }

//        if let number = categories.index(where: { $0 == vc.currentFile.category }) {
//
//            if let index = dataManager.localFiles[number].index(where: {$0.filename == vc.PDFfilename}) {
////                dataManager.localFiles[number][index].dateModified = Date()
////                dataManager.localFiles[number][index].thumbnail = vc.document.page(at: 0)!.thumbnail(of: CGSize(width: 210, height: 297), for: .artBox)
//
////                dataManager.saveBookmark(file: dataManager.localFiles[number][index], bookmark: vc.bookmarks)
//
//
//            } else {
//                print("Not uploaded to iCloud")
//                print(iCloudSynd)
//            }
//        } else { //E.G "HIRING" HAS NO INDEX
//
//        }

//        populateListTable() //HAR VÄL INTE ÄNDRATS?
        populateFilesCV()
        sortFiles()
        categoriesCV.reloadData()
        
        listTableView.reloadData()
        filesCollectionView.reloadData()
        
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

        populateFilesCV()
        sortFiles()
        self.listTableView.reloadData()
        self.filesCollectionView.reloadData()

    }
    
    @objc func handleNotesClosing(notification: Notification) {
        let vc = notification.object as! NotesViewController
        
        if vc.update {
            let currentFile = vc.localFile
            
            let number = categories.index(where: { $0 == navigator.selected.category })
            if let index = dataManager.localFiles[number!].index(where: {$0.filename == currentFile?.filename}) {
                dataManager.localFiles[number!][index] = currentFile!
            }

            if vc.filenameChanged {
                print("Filename changed")
                currentSelectedFilename = currentFile?.filename
                
                dataManager.updateIcloud(file: currentFile!, oldFilename: vc.originalFilename, newFilename: currentFile?.filename, expense: nil, project: nil, type: "Publications", bookmark: nil, fund: nil)
                dataManager.updateCoreData(file: currentFile!, oldFilename: vc.originalFilename, newFilename: currentFile?.filename)
                
                populateListTable()
                populateFilesCV()
                sortFiles()
                
                listTableView.reloadData()
                filesCollectionView.reloadData()
                attemptScrolling(filename: (currentFile?.filename)!)
                
            } else {
               
                dataManager.updateIcloud(file: currentFile!, oldFilename: nil, newFilename: nil, expense: nil, project: nil, type: "Publications", bookmark: nil, fund: nil)
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
    
    @objc func handleLongPressCategories(press: UILongPressGestureRecognizer) {
        
        if press.state == .ended {

            let point = press.location(in: self.categoriesCV)
            
            if let indexPath = self.categoriesCV.indexPathForItem(at: point) {
                
                AudioServicesPlaySystemSound(1104)
                
                let tmp = categories.index(where: { $0 == orderedCategories[indexPath.row].name! })!
                
                sendNotification(text: "Reloading " + orderedCategories[indexPath.row].name! + " folder")
                
                dataManager.reloadLocalFiles(category: tmp)
                
                populateListTable()
                populateFilesCV()
                sortFiles()
                
                categoriesCV.reloadData()
                listTableView.reloadData()
                filesCollectionView.reloadData()
                
                sendNotification(text: "Reload of " + orderedCategories[indexPath.row].name! + " folder finished")
            
                
            } else {
                print("couldn't find index path")
            }
        } else if press.state == .began {
            print("began")
            let point = press.location(in: self.categoriesCV)
            
            if let indexPath = self.categoriesCV.indexPathForItem(at: point) {
                let cell = self.categoriesCV.dequeueReusableCell(withReuseIdentifier: "categoryCell", for: indexPath) as! categoryCell
                cell.progressCircle.progressClr = UIColor.red
                cell.progressCircle.setProgressWithAnimation(duration: 1, value: 1)
            }
        }
        
    }
    
    @objc func handleLongPressFiles(press: UILongPressGestureRecognizer) {
        
        if press.state == .ended {
            
            let point = press.location(in: self.filesCollectionView)
            if let indexPath = self.filesCollectionView.indexPathForItem(at: point) {
                switch navigator.selected.category {
                
                case "Recently", "Reading list", "Bulletin board", "Search", "Publications":
                    if let note = dataManager.getNote(file: filesCV[indexPath.section][indexPath.row]) {
                        navigator.note = note
                        navigator.longpress = filesCV[indexPath.section][indexPath.row]
                        
                        performSegue(withIdentifier: "PDFNotesSegue", sender: self)
                    }
//                case "Publications":
//                    if let note = dataManager.getNote(file: filesCV[indexPath.section][indexPath.row]) {
//                        navigator.note = note
//                        navigator.longpress = filesCV[indexPath.section][indexPath.row]
//                        performSegue(withIdentifier: "PDFNotesSegue", sender: self)
//                    }
                default:
                    print("123")
                }
            }
        }

//            if indexPath != nil {
//                switch navigator.selected.category {
//
//                case "Recently", "Reading list", "Bulletin board", "Search":
//
//                    selectedLocalFile = filesCV[indexPath!.section][indexPath!.row]
//
//                    if !selectedLocalFile.downloading {
//                        if selectedLocalFile.iCloudURL.lastPathComponent.range(of: ".pdf") != nil || selectedLocalFile.iCloudURL.lastPathComponent.range(of: ".PDF") != nil {
//                            selectedLocalFile = filesCV[indexPath!.section][indexPath!.row]
//
//                            if selectedLocalFile.downloaded {
//                                PDFdocument = PDFDocument(url: selectedLocalFile.localURL)
//                            } else {
//                                PDFdocument = PDFDocument(url: selectedLocalFile.iCloudURL)
//                            }
//
//                            performSegue(withIdentifier: "seguePDFViewController", sender: self)
//
//                        } else {
//                            previewOrPlayFile()
//                        }
//                        dataManager.addFileToRecent(file: selectedLocalFile)
//                    }
//
//                case "Publications":
//
//                    selectedLocalFile = filesCV[indexPath!.section][indexPath!.row]
//
//                    if !selectedLocalFile.downloading {
//                        if selectedLocalFile.downloaded {
//                            PDFdocument = PDFDocument(url: selectedLocalFile.localURL)
//                        } else {
//                            PDFdocument = PDFDocument(url: selectedLocalFile.iCloudURL)
//                        }
//
//                        if dataManager.publicationsCD.first(where: {$0.filename == selectedLocalFile.filename}) == nil {
//                            dataManager.addFileToCoreData(file: selectedLocalFile)
//                        }
//
//                        performSegue(withIdentifier: "seguePDFViewController", sender: self)
//                        dataManager.addFileToRecent(file: selectedLocalFile)
//                    }
                
    }
    
    @objc func icloudFinishedLoading() {
        
        print("icloudFinishedLoading - inactive")

//        self.sendNotification(text: "Finished reading iCloud records")
//
//        dataManager.compareLocalFilesWithIcloud()
//
//        self.populateListTable()
//        self.populateFilesCV()
//        self.sortFiles()
//
//        self.categoriesCV.reloadData()
//        self.listTableView.reloadData()
//        self.filesCollectionView.reloadData()
        
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        print("keyboardWillShow")
        if navigator.selected.category == "Memos" {
            if let keyboard = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
                keyboardSize = keyboard.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        print("keyboardWillHide")
        keyboardVisible = false
        if self.memosCollectionView.frame.origin.y != memoCVOrigin {
            self.memosCollectionView.frame.origin.y = memoCVOrigin
        }
        for cell in memosCollectionView.visibleCells as! [MemoCell] {
            cell.noteButton.isHidden = false
            cell.titleButton.isHidden = false
        }
    }
    
    @objc func openBookmark(notification: Notification) {
        let vc = notification.object as! BookmarkListViewController
        let selectedBookmark = vc.selectedBookmark
        
        if selectedBookmark != nil {
            if selectedLocalFile.iCloudURL.lastPathComponent.range(of: ".pdf") != nil {
                
                goToPage = Int32(selectedBookmark!)
                
                if selectedLocalFile.downloaded {
                    PDFdocument = PDFDocument(url: selectedLocalFile.localURL)
                } else {
                    PDFdocument = PDFDocument(url: selectedLocalFile.iCloudURL)
                }
                
                
                performSegue(withIdentifier: "seguePDFViewController", sender: self)
            }
        }
        
    }
    
    @objc func postNotification() {
        DispatchQueue.main.async {
            print("postNotification")
            self.progressMonitor.isHidden = false
//            self.view.addSubview(self.progressMonitor) //IS THIS NEEDED?
            self.view.bringSubview(toFront: self.progressMonitor)
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
    
    @objc func saveAndUpdateMemos() {
        print("saveAndUpdateMemos")
        
        for cell in memosCollectionView.visibleCells as! [MemoCell] {

            cell.noteButton.isHidden = false
            cell.titleButton.isHidden = false
            dataManager.saveMemo(id: cell.id, text: cell.noteText.text, title: cell.memoTitle.text!, color: cell.color)
        }
        populateFilesCV()
        memosCollectionView.reloadData()
    }
    
    @objc func scrollMemo(sender: UIButton) {
        if let selectedMemo = memosCollectionView.cellForItem(at: IndexPath(row: sender.tag, section: 0)) as? MemoCell {
            if selectedMemo.id != currentSelectedMemo?.id {
                currentSelectedMemo?.noteButton.isHidden = false
                currentSelectedMemo?.titleButton.isHidden = false
            }
            currentSelectedMemo = selectedMemo
            currentSelectedMemo?.noteButton.isHidden = true
            currentSelectedMemo?.titleButton.isHidden = true
            
            if !keyboardVisible {
                let attributes = memosCollectionView.layoutAttributesForItem(at: IndexPath(row: sender.tag, section: 0))!
                let cellRect = attributes.frame
                let rectOfCellInSuperview = memosCollectionView.convert(cellRect, to: memosCollectionView.superview)
                
                memoCVOrigin = self.memosCollectionView.frame.origin.y
                memoPosition = rectOfCellInSuperview.origin.y + cellRect.height
                
                if memosCollectionView.frame.height - keyboardSize + memosCollectionView.frame.origin.y < memoPosition {
                    self.memosCollectionView.frame.origin.y = self.memosCollectionView.frame.origin.y - keyboardSize + (self.memosCollectionView.frame.height - memoPosition)
                }
            }
            keyboardVisible = true
        }
    }
    
    @objc func sendNotification(text: String) {
        print("sendNotification - VC")
        
        self.progressMonitor.isHidden = false
        self.view.addSubview(self.progressMonitor)
        self.view.bringSubview(toFront: self.progressMonitor)
        self.progressMonitor.launchMonitor(displayText: text)
    }
    
    @objc func updateScanProgress() {
        print("updateScanProgress")
        
        self.scanFilesProgress.progress = self.scanIndex/self.scanFiles
        
    }
    
    @objc func updateSyncProgress() {
        print("updateSyncProgress")
        
        DispatchQueue.main.async {
            let increment = 1/8 + 0.01 //Different types of records we want to save
            
            self.iCloudSyncProgress.progress = self.iCloudSyncProgress.progress + Float(increment)
            
            print(self.iCloudSyncProgress.progress)
            
            if self.iCloudSyncProgress.progress >= 1 {
                self.iCloudSyncProgress.isHidden = true
            } else {
                self.iCloudSyncProgress.isHidden = false
            }
        }
    }
    
    @objc func updateUploadProgress() {
        print("updateUploadProgress")
        
        DispatchQueue.main.async {
            
            self.iCloudUploadProgress.progress = Float(self.dataManager.progress)/self.dataManager.maxProgress
            
            print(self.iCloudUploadProgress.progress)
            print(self.dataManager.progress)
            print(self.dataManager.maxProgress)
            
            if self.iCloudUploadProgress.progress >= 1 {
                self.iCloudUploadProgress.isHidden = true
                self.kvStorage.set(Date(), forKey: "uploadDate")
                self.kvStorage.synchronize()
                self.dateFormatter.dateFormat = "yyyy-MM-dd : HH:mm"
                self.lastUploadLabel.text = "Last uploaded: " + self.dateFormatter.string(from: Date())
            } else {
                self.iCloudUploadProgress.isHidden = false
            }
        }
    }
    
    @objc func updateView() {
        print("updateView()")
        
        DispatchQueue.main.async {
            self.categoriesCV.reloadData()
        }
    }
    
    
    
    
    // MARK:- FUNCTIONS
    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func attemptScrolling(filename: String) {
        
        if filename.count != 0 {
            selectedFile[navigator.selected.categoryNumber].category = categories[navigator.selected.categoryNumber]
            selectedFile[navigator.selected.categoryNumber].filename = filename
            selectedFile[navigator.selected.categoryNumber].indexPathCV = []
            
            if categories[navigator.selected.categoryNumber] == "Publications" {
                for section in 0..<filesCV.count {
                    for row in 0..<filesCV[section].count {
                        if filesCV[section][row].filename == currentSelectedFilename {
                            selectedFile[navigator.selected.categoryNumber].indexPathCV.append(IndexPath(row: row, section: section))
                        }
                    }
                }
            }
            
            if !selectedFile[navigator.selected.categoryNumber].indexPathCV.isEmpty {
                self.filesCollectionView.scrollToItem(at: IndexPath(row: (selectedFile[navigator.selected.categoryNumber].indexPathCV[0]?.row)!, section: (selectedFile[navigator.selected.categoryNumber].indexPathCV[0]?.section)!), at: .top, animated: true)
                self.listTableView.scrollToRow(at: IndexPath(row: 0, section: (selectedFile[navigator.selected.categoryNumber].indexPathCV[0]?.section)!), at: .top, animated: true)
                self.listTableView.selectRow(at: IndexPath(row: 0, section: (selectedFile[navigator.selected.categoryNumber].indexPathCV[0]?.section)!), animated: true, scrollPosition: .top)
            }
        }
        
    }
    
    func initiateDimmer() {
        categoryIndicator.alpha = 1
        categoryIndicator.isHidden = false
        if navigator.selected.category == "Fast folder" {
            categoryIndicator.text = navigator.selected.category + ": " + (dataManager.fastFolderCD?.mainFolder)!
        } else {
            categoryIndicator.text = navigator.selected.category
        }
        dimmerTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(dimLabel), userInfo: nil, repeats: false)
    }
    
    func getArticlesYears() -> [String] {
        var tmp = [String]()
        for i in 0..<dataManager.localFiles[navigator.selected.categoryNumber].count {
            tmp.append("\(dataManager.localFiles[navigator.selected.categoryNumber][i].year!)")
        }
        yearsString = tmp.reduce([], {$0.contains($1) ? $0:$0+[$1]})
        yearsString = yearsString.sorted(by: {$0 < $1})
        return yearsString
    }
    
    func getRecentDates() -> [Date] {
        var dateComponents = DateComponents()

        dateComponents.day = 0
        dateComponents.hour = -1
        let lastHour = Calendar.current.date(byAdding: dateComponents, to: Date())

        dateComponents.day = 0
        dateComponents.hour = -4
        let last4Hours = Calendar.current.date(byAdding: dateComponents, to: Date())
        
        dateComponents.hour = -8
        let last8Hours = Calendar.current.date(byAdding: dateComponents, to: Date())

        dateComponents.hour = -24
        let lastDay = Calendar.current.date(byAdding: dateComponents, to: Date())

        dateComponents.hour = -48
        let last48Hours = Calendar.current.date(byAdding: dateComponents, to: Date())

        dateComponents.hour = 0
        dateComponents.day = -7
        let lastWeek = Calendar.current.date(byAdding: dateComponents, to: Date())

        dateComponents.hour = 0
        dateComponents.day = -14
        let last2Weeks = Calendar.current.date(byAdding: dateComponents, to: Date())

        dateComponents.day = -30
        let lastMonth = Calendar.current.date(byAdding: dateComponents, to: Date())

        return [lastHour!, last4Hours!, last8Hours!, lastDay!, last48Hours!, lastWeek!, last2Weeks!, lastMonth!]

    }
    
    func getNumberFastFolderFiles() -> Int {
        dataManager.readFastFolder()
        var count = 0
        if let content = dataManager.fastFolderContent {
            for folder in content.files {
                for _ in folder {
                    count = count + 1
                }
            }
        }
        return count
    }
    
    func hideAndDisableAll(views: Bool, buttons: Bool) {
        
        if views {
            self.listTableView.isHidden = true
            self.searchCollectionView.isHidden = true
            self.settingsView.isHidden = true
            self.economyView.isHidden = true
            self.scholarView.isHidden = true
            self.applicantView.isHidden = true
            self.filesCollectionView.isHidden = true
            self.memosCollectionView.isHidden = true
        }
        
        self.optionsSegment.isHidden = true
        
        if buttons {
            notesButton.isEnabled = false
            editButton.isEnabled = false
            searchButton.isEnabled = false
            sortCVButton.isEnabled = false
            readingListBUtton.isEnabled = false
            downloadToLocalFileBUtton.isEnabled = false
            addToBulletinButton.isEnabled = false
            if navigator.selected.category == "Teaching" {
                addNew.image = #imageLiteral(resourceName: "exam")
                addNew.isEnabled = true
            } else {
                addNew.image = #imageLiteral(resourceName: "Add")
                addNew.isEnabled = false
            }
            favoriteButton.isEnabled = false
        }
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
        
        if let number = kvStorage.object(forKey: "selectedEconomyNumber") as? Int {
            selectedEconomyNumber = number
        } else {
            selectedEconomyNumber = 0
        }
        
        if let number = kvStorage.object(forKey: "selectedWorkDocNumber") as? Int {
            selectedWorkDocNumber = number
        } else {
            selectedWorkDocNumber = 0
        }
        
        if let number = kvStorage.object(forKey: "selectedSortingNumber") as? Int {
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
        
        if let days = kvStorage.object(forKey: "recentDays") as? Int {
            recentDays = days
        } else {
            recentDays = 24
        }
        
        if let settings = kvStorage.object(forKey: "annotationSettings") as? [Int] {
            annotationSettings = settings
            if annotationSettings.count < 26 {
                annotationSettings = [2, 29, 9, 6, 41, 10, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
            }
        } else {
            annotationSettings = [2, 29, 9, 6, 41, 10, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        }
        
        if let date = kvStorage.object(forKey: "uploadDate") as? Date {
            uploadDate = date
        }
        
//        if let folder = kvStorage.object(forKey: "hotFolder") as? String {
//            dataManager.hotFolder = folder
//        }
        
//        if let number = kvStorage.object(forKey: "publicationOption") as? Int {
//            publicationOption = number
//        } else {
//            publicationOption = 1
//        }
        
    }
    
    func openHiringFile(type: String) {
        
        let name = applicantTableTitles[selectedApplicant]
        let announcement = navigator.list.main[navigator.selected.tableNumber]
        
        for i in 0..<dataManager.hiringFiles.count {
            if dataManager.hiringFiles[i].parentFolder == name && dataManager.hiringFiles[i].grandpaFolder == announcement {
                let filename = fileHandler.getFilenameFromURL(icloudURL: dataManager.hiringFiles[i].iCloudURL)
                if filename == type {
                    selectedLocalFile = dataManager.hiringFiles[i]
                    
                    var fileURL = selectedLocalFile.iCloudURL
                    print(fileURL)
                    if selectedLocalFile.iCloudURL.lastPathComponent.range(of:".icloud") != nil {
                        var tmpname = selectedLocalFile.iCloudURL.deletingPathExtension().lastPathComponent
                        tmpname.remove(at: tmpname.startIndex)
                        let folder = selectedLocalFile.iCloudURL.deletingLastPathComponent()
                        fileURL = folder.appendingPathComponent(tmpname)
                    }
                    
                    let exist = fileManagerDefault.fileExists(atPath: fileURL.path)
                    
                    if exist {
                        dataManager.hiringFiles[i].iCloudURL = fileURL
                        PDFdocument = PDFDocument(url: fileURL)
                        performSegue(withIdentifier: "seguePDFViewController", sender: self)
                    } else {
                        do {
                            print("Downloading")
                            try fileManagerDefault.startDownloadingUbiquitousItem(at: selectedLocalFile.iCloudURL)
                            sendNotification(text: "Downloading " + type)
                        } catch let error {
                            print(error)
                        }
                    }
                }
            }
        }
    }
    
    func populateHiringTable() {
        print("populateHiringTable")
        
        applicantTableTitles = []
        
        if navigator.selected.tableNumber < navigator.list.main.count {
            let currentAnnouncement = navigator.list.main[navigator.selected.tableNumber]
            let applicants = dataManager.applicantCD.filter{$0.announcement == currentAnnouncement}
            applicantTableTitles = applicants.map{$0.name!}
            
            if !applicantTableTitles.isEmpty {
                let set = Set(applicantTableTitles)
                applicantTableTitles = Array(set).sorted()
            }
        }
    }
    
    func populateListTable() {
        print("populateListTable() " + navigator.selected.category)
        
        navigator.list.main = [String]()

        switch navigator.selected.category { //} categories[navigator.selected.categoryNumber] {
        case "Recently":
            
            navigator.list.main = recentStrings
        
        case "Teaching":

            if navigator.selected.folderLevel == 1 {
                navigator.list.sub = subFoldersList[navigator.selected.mainFolderNumber!] //selectedSubtableNumber]
            } else {

                let (number, _) = dataManager.getCategoryNumberAndURL(name: categories[navigator.selected.categoryNumber])
                
                for file in dataManager.localFiles[number] {
                    navigator.list.main.append(file.grandpaFolder!)
                }
                
                if !navigator.list.main.isEmpty {
                    let set = Set(navigator.list.main)
                    navigator.list.main = Array(set)
                    navigator.list.main = navigator.list.main.sorted()
                }
            }
        
        case "Fast folder":
            if let content = dataManager.fastFolderContent {
                navigator.list.main = content.subfolders
            }
            
        case "Bulletin board":
            let tmp = dataManager.bulletinCD.sorted(by: {$0.bulletinName! < $1.bulletinName!})
            
            for file in tmp {
                navigator.list.main.append(file.bulletinName!)
            }
            
            if !navigator.list.main.isEmpty {
                let set = Set(navigator.list.main)
                navigator.list.main = Array(set)
                navigator.list.main = navigator.list.main.sorted()
            }
            
        case "Reading list":
            let tmp = dataManager.readingListCD.sorted(by: {$0.category! < $1.category!})

            for file in tmp {
                navigator.list.main.append(file.category!)
            }
            
            if !navigator.list.main.isEmpty {
                let set = Set(navigator.list.main)
                navigator.list.main = Array(set)
                navigator.list.main = navigator.list.main.sorted()
            }
            
        case "Publications":
            switch sortSubtableStrings[selectedSortingNumber] {
            case "Tag":
                let tmp = dataManager.publicationGroupsCD.sorted(by: {($0.sortNumber!, $0.tag!) < ($1.sortNumber!, $1.tag!)})
                navigator.list.main = tmp.map { $0.tag! }
            case "Year":
                navigator.list.main = getArticlesYears()
            case "Author":
                let tmp = dataManager.authorsCD.sorted(by: {($0.sortNumber!, $0.name!) < ($1.sortNumber!, $1.name!)})
                navigator.list.main = tmp.map { $0.name! }
            case "Journal":
                let tmp = dataManager.journalsCD.sorted(by: {($0.sortNumber!, $0.name!) < ($1.sortNumber!, $1.name!)})
                navigator.list.main = tmp.map { $0.name! }
            case "Rank":
                navigator.list.main = ["0-9", "10-19", "20-29", "30-39", "40-49", "50-59", "60-69", "70-79", "80-89", "90-99", "100"]
            default:
                print("Default 125")
            }
            
        case "Books":
            let tmp = dataManager.booksGroupsCD.sorted(by: {($0.sortNumber!, $0.tag!) < ($1.sortNumber!, $1.tag!)})
            navigator.list.main = tmp.map { $0.tag! }

        case "Economy":
            if economyStrings[selectedEconomyNumber] == "Projects" {
                let tmp = dataManager.projectCD.sorted(by: {$0.name! < $1.name!})
                navigator.list.main = tmp.map { $0.name! }
                
            } else if economyStrings[selectedEconomyNumber] == "Invoices" {
                let (number, _) = dataManager.getCategoryNumberAndURL(name: categories[navigator.selected.categoryNumber])
                
                for file in dataManager.localFiles[number] {
                    navigator.list.main.append(file.grandpaFolder!)
                }
                
                if !navigator.list.main.isEmpty {
                    let set = Set(navigator.list.main)
                    navigator.list.main = Array(set)
                    navigator.list.main = navigator.list.main.sorted()
                }
                
            } else if economyStrings[selectedEconomyNumber] == "Grants" {
                let tmp = dataManager.fundCD.sorted(by: {$0.name! < $1.name!})
                navigator.list.main = tmp.map { $0.name! }
            }
            
        case "Work documents":
            
            if workDocStrings[selectedWorkDocNumber] == "Files" {
                let (number, _) = dataManager.getCategoryNumberAndURL(name: categories[navigator.selected.categoryNumber])
                
                for file in dataManager.localFiles[number] {
                    navigator.list.main.append(file.grandpaFolder!)
                }
                
                if !navigator.list.main.isEmpty {
                    let set = Set(navigator.list.main)
                    navigator.list.main = Array(set)
                    navigator.list.main = navigator.list.main.sorted()
                }
                
            } else if workDocStrings[selectedWorkDocNumber] == "Hiring" {
                
                for file in dataManager.applicantCD {
                    navigator.list.main.append(file.announcement!)
                }
                
                if !navigator.list.main.isEmpty {
                    let set = Set(navigator.list.main)
                    navigator.list.main = Array(set)
                    navigator.list.main = navigator.list.main.sorted()
                }
                
                populateHiringTable()
                
                applicantTableList.reloadData()

            }
            
        case "Memos":
            
            navigator.list.main.append("All memos")
            for memo in dataManager.memosCD {
                if !navigator.list.main.contains(memo.tag!) {
                    navigator.list.main.append(memo.tag!)
                }
            }
            navigator.list.main.append("+ New category")

        case "Settings":
            navigator.list.main = ["Nothing"]

        default:
            
            let (number, _) = dataManager.getCategoryNumberAndURL(name: categories[navigator.selected.categoryNumber])
            
            for file in dataManager.localFiles[number] {
                navigator.list.main.append(file.grandpaFolder!)
            }
            
            if !navigator.list.main.isEmpty {
                let set = Set(navigator.list.main)
                navigator.list.main = Array(set)
                navigator.list.main = navigator.list.main.sorted()
            }
            
        }
        
    }
    
    func populateFilesCV() {
        print("populateFilesCV")

        filesCV = [[]]

        switch navigator.selected.category {
        case "Recently":
            let dates = getRecentDates()
            for i in 0..<navigator.list.main.count { //} navigator.list.main.count {
                filesCV[i] = []

                if navigator.list.main[i] != "Favorites" && navigator.list.main[i] != "Fast folder" {
                    let items = dataManager.recentCD.filter{ $0.dateOpened! > dates[i] }
                    for item in items {
                        let cat = categories.index(where: { $0 == item.category })
                        if let index = dataManager.localFiles[cat!].index(where: {$0.path == item.path}) {
                            filesCV[i].append(dataManager.localFiles[cat!][index])
                        }
                    }
                }
                
                if navigator.list.main[i] == "Favorites" {
                    let items = dataManager.favoritesCD
                    for item in items {
                        for j in 0..<dataManager.categories.count {
                            if dataManager.categories[j] != "Memos" && dataManager.categories[j] != "Settings" && dataManager.categories[j] != "Reading list" && dataManager.categories[j] != "Bulletin board" {
                                let file = dataManager.localFiles[j].filter{ $0.path == item.path }
                                if !file.isEmpty {
                                    filesCV[i].append(file.first!)
                                }
                            }
                        }
                    }
                }

                if navigator.list.main[i] == "Fast folder" {
                    dataManager.readFastFolder()
                    if let content = dataManager.fastFolderContent {
                        for folder in content.files {
                            for file in folder {
                                filesCV[i].append(file)
                            }
                        }
                    }
                }
                
                if i < navigator.list.main.count {
                    filesCV.append([]) // ADD [] FOR THE NEXT ROUND
                }
            }

            for item in dataManager.recentCD {
                if item.dateOpened! < dates.last! {
                    if let index = dataManager.recentCD.index(where: { $0.path == item.path! } ) {
                        dataManager.recentCD.remove(at: index)
                        dataManager.saveCoreData()
                    }
                }
            }
           
        case "Fast folder":

            if let content = dataManager.fastFolderContent {
                filesCV = content.files
            }
            
        case "Reading list":
            
            for i in 0..<navigator.list.main.count {
                filesCV[i] = []
                for item in dataManager.readingListCD {
                    for j in 0..<dataManager.categories.count {
                        if dataManager.categories[j] == navigator.list.main[i] {
                            let files = dataManager.localFiles[j].filter{ $0.path == item.path }
                            if !files.isEmpty {
                                for file in files {
                                    filesCV[i].append(file)
                                }
                            }
                        }
                    }
                    if i < navigator.list.main.count {
                        filesCV.append([]) // ADD [] FOR THE NEXT ROUND
                    }
                }
            }
            
        case "Publications":
            
            var files: [LocalFile]
            if dataManager.isSearching && dataManager.searchString.count > 0 {
                files = dataManager.searchResult
            } else {
                files = dataManager.localFiles[navigator.selected.categoryNumber]
            }
            
            switch sortSubtableStrings[selectedSortingNumber] {
            case "Tag":
                var dateComponents = DateComponents()
                dateComponents.hour = -recentDays
                let recent = Calendar.current.date(byAdding: dateComponents, to: Date())
                
                for i in 0..<navigator.list.main.count {
                    for file in files {
                        if navigator.list.main[i] == "Favorites" {
                            if dataManager.favoritesCD.first( where: {$0.path == file.path } ) != nil {
                                filesCV[i].append(file)
                            }
                        }
                        if file.groups.first(where: {$0 == navigator.list.main[i]}) != nil {
                            filesCV[i].append(file)
                        }
                        if navigator.list.main[i] == "Recently added/modified" && file.dateModified! > recent! {
                            filesCV[i].append(file)
                        }
                    }
                    filesCV[i] = filesCV[i].sorted(by: {($0.filename) < ($1.filename)})
                    if i < navigator.list.main.count {
                        filesCV.append([]) // ADD [] FOR THE NEXT ROUND
                    }
                }
            case "Author":
                for i in 0..<navigator.list.main.count {
                    for file in files {
                        if file.author == navigator.list.main[i] {
                            filesCV[i].append(file)
                        }
                    }
                    filesCV[i] = filesCV[i].sorted(by: {($0.filename) < ($1.filename)})
                    if i < navigator.list.main.count {
                        filesCV.append([]) // ADD [] FOR THE NEXT ROUND
                    }
                }
            case "Journal":
                for i in 0..<navigator.list.main.count {
                    for file in files {
                        if file.journal == navigator.list.main[i] {
                            filesCV[i].append(file)
                        }
                    }
                    filesCV[i] = filesCV[i].sorted(by: {($0.filename) < ($1.filename)})
                    if i < navigator.list.main.count {
                        filesCV.append([]) // ADD [] FOR THE NEXT ROUND
                    }
                }
            case "Year":
                for i in 0..<navigator.list.main.count {
                    for file in files {
                        if file.year == Int16(navigator.list.main[i]) {
                            filesCV[i].append(file)
                        }
                    }
                    filesCV[i] = filesCV[i].sorted(by: {($0.filename) < ($1.filename)})
                    if i < navigator.list.main.count {
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
                    if i < navigator.list.main.count {
                        filesCV.append([]) // ADD [] FOR THE NEXT ROUND
                    }
                }
            default:
                print("Default 132")
            }
            
        case "Books":
            filesCV = [[]]
            var dateComponents = DateComponents()
            dateComponents.hour = -recentDays
            let recent = Calendar.current.date(byAdding: dateComponents, to: Date())

            var files: [LocalFile]
            if dataManager.isSearching && dataManager.searchString.count > 0 {
                files = dataManager.searchResult
            } else {
                files = dataManager.localFiles[navigator.selected.categoryNumber]
            }
            
            for i in 0..<navigator.list.main.count {
                for file in files {
                    if navigator.list.main[i] == "Favorites" {
                        if dataManager.favoritesCD.first( where: {$0.path == file.path } ) != nil {
                            filesCV[i].append(file)
                        }
                    }
                    if file.groups.first(where: {$0 == navigator.list.main[i]}) != nil {
                        filesCV[i].append(file)
                    }
                    if navigator.list.main[i] == "Recently added/modified" && file.dateModified! > recent! {
                        filesCV[i].append(file)
                    }
                }
                filesCV[i] = filesCV[i].sorted(by: {($0.filename) < ($1.filename)})
                if i < navigator.list.main.count {
                    filesCV.append([]) // ADD [] FOR THE NEXT ROUND
                }
            }
        case "Economy":

            docCV = []
            
            let (number, _) = dataManager.getCategoryNumberAndURL(name: navigator.selected.category)
            
            if economyStrings[selectedEconomyNumber] == "Invoices" {
                if !navigator.list.main.isEmpty {
                    for i in 0..<navigator.list.main.count {
                        var tmp = DocCV(listTitle: navigator.list.main[i], sectionHeader: [], files: [[]])
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
                    }
                }
            } else {
                print("Here 123")
            }
            
        case "Memos":
            
            memosCV = []
            
            let memos = dataManager.memosCD
            if navigator.list.main[navigator.selected.tableNumber] == "All memos" {
                for memo in memos {
                    memosCV.append(memo.id)
                }
            } else {
                let filteredMemos = memos.filter{$0.tag == navigator.list.main[navigator.selected.tableNumber]}
                for memo in filteredMemos {
                    memosCV.append(memo.id)
                }
            }
            
        case "Search":
            for i in 0..<dataManager.fullSearch.count {
                filesCV[i] = []
                if !dataManager.fullSearch[i].files.isEmpty {
                    for file in dataManager.fullSearch[i].files {
                        filesCV[i].append(file)
                    }
                }

                if i < dataManager.fullSearch.count {
                    filesCV.append([]) // ADD [] FOR THE NEXT ROUND
                }

            }

        case "Bulletin board":
            
            filesCV = [[]]
            
            for i in 0..<navigator.list.main.count {
                filesCV[i] = []
                if let bulletin = dataManager.bulletinCD.first(where: {$0.bulletinName == navigator.list.main[i]}) {
                    for j in 0..<bulletin.category!.count {
                        let cat = categories.index(where: { $0 == bulletin.category![j] })
                        if let index = dataManager.localFiles[cat!].index(where: {$0.path == bulletin.path![j]}) {
                            filesCV[i].append(dataManager.localFiles[cat!][index])
                        }
                    }
                    if i < navigator.list.main.count {
                        filesCV.append([]) // ADD [] FOR THE NEXT ROUND
                    }
                }
            }
            
        default:
            
            let (number, _) = dataManager.getCategoryNumberAndURL(name: navigator.selected.category)
            
            docCV = []
            
            subFoldersList = [[String]]()
            
            if !navigator.list.main.isEmpty {
                for i in 0..<navigator.list.main.count {
                    var subfolders: [String] = []
                    var tmp = DocCV(listTitle: navigator.list.main[i], sectionHeader: [], files: [[]])
                    let files = dataManager.localFiles[number].filter{$0.grandpaFolder == navigator.list.main[i]}
                    for file in files {
                        tmp.sectionHeader.append(file.parentFolder!)
                    }
                    
                    subfolders = tmp.sectionHeader
                    
                    if !subfolders.isEmpty {
                        let set = Set(subfolders)
                        let array = Array(set)
                        subfolders = array.sorted()
                    }
                    tmp.sectionHeader = subfolders
                    
                    subFoldersList.append(subfolders)

                    for j in 0..<subfolders.count {
                        for file in dataManager.localFiles[number] {
                            if file.parentFolder == subfolders[j] && file.grandpaFolder == navigator.list.main[i] {
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
        
        if (segue.identifier == "bulletinListSegue") {
            let destination = segue.destination as! BulletinListViewController
            destination.bulletinCD = dataManager.bulletinCD
            destination.preferredContentSize = bulletinBox
        }
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
        
        if (segue.identifier == "PDFNotesSegue") {
            let destination = segue.destination as! PDFNotesViewController
            destination.note = navigator.note
            destination.filename = navigator.longpress?.filename
        }
        
        if (segue.identifier == "segueNotes") {
            let destination = segue.destination as! NotesViewController
            destination.localFile = selectedLocalFile
            destination.dataManager = dataManager
            destination.annotationSettings = annotationSettings
            destination.preferredContentSize = notesBox
        }
        if (segue.identifier == "seguePDFViewController") {
            //DOESNT WORK FOR INVOICES
            
            AudioServicesPlaySystemSound(1104)
            
            let destination = segue.destination as! PDFViewController
            
            destination.document = PDFdocument
            destination.pdfViewManager = pdfViewManager
            destination.PDFfilename = selectedLocalFile.filename
            destination.iCloudURL = selectedLocalFile.iCloudURL
            destination.localURL = selectedLocalFile.localURL
            destination.progressMonitor = progressMonitor
            destination.annotationSettings = annotationSettings
            destination.kvStorage = kvStorage
            destination.dataManager = dataManager
            destination.fileHandler = fileHandler
            destination.currentFile = selectedLocalFile
            destination.isLandscape = isLandscape
            destination.notesBox = notesBox
            destination.docIsExam = false

            let folderPath = selectedLocalFile.path.replacingOccurrences(of: selectedLocalFile.filename, with: "")
            let name = selectedLocalFile.filename.replacingOccurrences(of: ".pdf", with: "")
            
            destination.path = folderPath

            for item in dataManager.examsCD {
                if item.path == folderPath {
                    destination.docIsExam = true
                    destination.selectedExam = item

                    let students = item.student as! Set<Student>
                    if let currentStudent = students.first(where: {$0.name == name}) {
                        destination.student = currentStudent
                    }
                    else {
                        let newStudent = dataManager.newScore(name: name, exam: item)
                        newStudent?.exam = item
                        destination.student = newStudent
                    }
                }
            }
            
            if let currentBookmark = dataManager.getBookmark(file: selectedLocalFile) {
                if goToPage != nil {
                    currentBookmark.lastPageVisited = goToPage!
                }
                destination.bookmarks = currentBookmark
            } else {
                let newBookmark = dataManager.newBookmark(file: selectedLocalFile)
                destination.bookmarks = newBookmark
            }
            
            destination.bookmarks.timesVisited = destination.bookmarks.timesVisited + 1
            selectedLocalFile.views = destination.bookmarks.timesVisited
            
            goToPage = nil
        }

        if (segue.identifier == "segueInvoiceVC") {
            let destination = segue.destination as! InvoiceViewController
            destination.invoiceURL = dataManager.economyURL
        }

        if (segue.identifier == "hiringNotesSegue") {
            let destination = segue.destination as! HiringNotesViewController
            destination.text = applicantNotes.text
        }
        if (segue.identifier == "bookmarkSegue") {
            let destination = segue.destination as! BookmarkListViewController
            destination.selectedLocalFile = selectedLocalFile
            destination.dataManager = dataManager
            destination.fileHandler = fileHandler
        }
        if (segue.identifier == "examSegue") {
            let destination = segue.destination as! ScoreViewController
            destination.dataManager = dataManager
            destination.hideExport = false
            destination.files = docCV[self.navigator.selected.tableNumber].files[navigator.selected.subFolderNumber!]
            
            let folderPath = navigator.path
            
            for item in dataManager.examsCD {
                if item.path == folderPath {
                    destination.selectedExam = item
                }
            }
        }
    }
    
    func previewOrPlayFile() {
        print("previewOrPlayFile")
        
        if selectedLocalFile.iCloudURL.lastPathComponent.range(of: ".mp4") != nil || selectedLocalFile.iCloudURL.lastPathComponent.range(of: ".MP4") != nil {
            
            let player = AVPlayer(url: selectedLocalFile.iCloudURL)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            self.present(playerViewController, animated: true) {
                player.play()
            }
        } else {
            previewFile = selectedLocalFile
            previewController.reloadData()
            navigationController?.pushViewController(previewController, animated: true)
        }
    }
    
    func scrollToSection(_ section:Int)  {
        print("scrollToSection")
        
        if let cv = self.filesCollectionView {
            let indexPath = IndexPath(item: 0, section: section)
            if let attributes = cv.layoutAttributesForSupplementaryElement(ofKind: UICollectionElementKindSectionHeader, at: indexPath) {
                
                let topOfHeader = CGPoint(x: 0, y: attributes.frame.origin.y - cv.contentInset.top) //FIX: ADD OFFSET (TEST 2*)
                cv.setContentOffset(topOfHeader, animated:true)
            }
        }
    }
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleSorttablePopupClosing), name: Notification.Name.sortSubtable, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleSettingsPopupClosing), name: Notification.Name.settingsCollectionView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handlePDFClosing), name: Notification.Name.closingPDF, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleInvoiceClosing), name: Notification.Name.closingInvoiceVC, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleSortCVClosing), name: Notification.Name.sortCollectionView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleNotesClosing), name: Notification.Name.closingNotes, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.icloudFinishedLoading), name: Notification.Name.icloudFinished, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reload), name: Notification.Name.reload, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.postNotification), name: Notification.Name.postNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateView), name: Notification.Name.updateView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleApplicantNotesClosing), name: Notification.Name.applicantNotesClosing, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.openBookmark), name: Notification.Name.openPDFAtBookmark, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.saveAndUpdateMemos), name: Notification.Name.saveAndUpdateMemos, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateSyncProgress), name: Notification.Name.syncCompleted, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateUploadProgress), name: Notification.Name.uploadProgress, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateScanProgress), name: Notification.Name.updateScanProgress, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.fileAddedToBulletin), name: Notification.Name.bulletinList, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleExamClosing), name: Notification.Name.settingsScore, object: nil)

    }
    
    func setupProgressMonitor() {
        print("setupProgressMonitor")

        progressMonitor.removeFromSuperview()

        if UIDevice.current.orientation.isLandscape { //UIApplication.shared.statusBarOrientation.isLandscape {
            print("Landscape")
            if self.view.bounds.maxX < self.view.bounds.maxY { //Works
                progressMonitor.frame = CGRect(x: self.view.bounds.maxY/2 - progressMonitorSettings[1]/2, y: self.view.bounds.size.height+progressMonitorSettings[0], width: progressMonitorSettings[1], height: progressMonitorSettings[0])
                progressMonitor.iPadDimension = [self.view.bounds.maxX, self.view.bounds.maxY] // [y,x]
            } else { //Works
                progressMonitor.frame = CGRect(x: self.view.bounds.maxX/2 - progressMonitorSettings[1]/2, y: self.view.bounds.size.width+progressMonitorSettings[0], width: progressMonitorSettings[1], height: progressMonitorSettings[0])
                progressMonitor.iPadDimension = [self.view.bounds.maxY, self.view.bounds.maxX]
            }
        } else {
            print("Portrait")
            if self.view.bounds.maxX < self.view.bounds.maxY { //Normal, doesn't work
                progressMonitor.frame = CGRect(x: self.view.bounds.maxX/2 - progressMonitorSettings[1]/2, y: self.view.bounds.size.height+progressMonitorSettings[0], width: progressMonitorSettings[1], height: progressMonitorSettings[0])
                progressMonitor.iPadDimension = [self.view.bounds.maxY, self.view.bounds.maxX]
            } else { //Works
                progressMonitor.frame = CGRect(x: self.view.bounds.maxY/2 - progressMonitorSettings[1]/2, y: self.view.bounds.size.width+progressMonitorSettings[0], width: progressMonitorSettings[1], height: progressMonitorSettings[0])
                progressMonitor.iPadDimension = [self.view.bounds.maxX, self.view.bounds.maxY]
            }
        }

        progressMonitor.settings = progressMonitorSettings
        progressMonitor.backgroundColor = UIColor(displayP3Red: progressMonitorSettings[2], green: progressMonitorSettings[2], blue: progressMonitorSettings[2], alpha: progressMonitorSettings[3])
        progressMonitor.layer.cornerRadius = 12
        progressMonitor.layer.borderWidth = 1
        progressMonitor.layer.borderColor = UIColor(red:255/255, green:255/255, blue:255/255, alpha: progressMonitorSettings[3]).cgColor
        self.view.addSubview(self.progressMonitor)
        self.view.bringSubview(toFront: progressMonitor)
    }
    
    func setupUI() {
        print("setupUI")
        
        filesDownloading = []

        for _ in 0..<categories.count {
            let tmp = SelectedFile(category: nil, filename: nil, indexPathCV: [nil])
            selectedFile.append(tmp)
        }
        
        updateCategoriesOrder()
        
        kvStorage = NSUbiquitousKeyValueStore()
        loadDefaultValues()
        
        //Setup memo collection view layout
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: 200, height: 200)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        self.memosCollectionView.collectionViewLayout = layout
        
        //ALWAYS START WITH RECENTLY
        self.settingsView.isHidden = true
        economyView.isHidden = true
        applicantView.isHidden = true
        filesCollectionView.isHidden = false
        memosCollectionView.isHidden = true
        searchCollectionView.isHidden = true
        expensesTableView.isHidden = true
        scholarView.isHidden = true
        optionsSegment.isHidden = true
        notesButton.isEnabled = false
        searchButton.isEnabled = false
        bookmarksButton.isEnabled = false
        favoriteButton.isEnabled = false
        readingListBUtton.isEnabled = false
        downloadToLocalFileBUtton.isEnabled = false
        editButton.isEnabled = false
        sortCVButton.isEnabled = false
        addNew.isEnabled = false
        scanFilesProgress.isHidden = true
        addToBulletinButton.isEnabled = false
        
        expenseTypeControl.selectedSegmentIndex = 0
        optionsSegment.selectedSegmentIndex = 0
        salaryYearString.isHidden = true
        salaryYearStepper.isHidden = true
        organisationInstructions.layer.borderColor = UIColor.lightGray.cgColor
        organisationInstructions.layer.borderWidth = 1
        organisationInstructions.layer.cornerRadius = 8
        applicantNotes.layer.borderColor = UIColor.lightGray.cgColor
        applicantNotes.layer.borderWidth = 1
        applicantNotes.layer.cornerRadius = 8
        iCloudSyncProgress.progress = 1
        iCloudSyncProgress.isHidden = true
        iCloudUploadProgress.progress = 0
        iCloudUploadProgress.isHidden = true
        categoryIndicator.isHidden = true

        dataManager.progressMonitor = progressMonitor
//        dataManager.compareLocalFilesWithCoreData()
//        dataManager.initIcloudLoad()
        
//        sendNotification(text: "Starting to load iCloud records")
        
        searchBar.isHidden = searchHidden

        self.expenseBackgroundView.layer.cornerRadius = 15
        self.amountBackgroundView.layer.cornerRadius = 15
        self.organisationDeadline.setValue(UIColor.white, forKeyPath: "textColor")
        
//        dataManager.readIcloudDriveFolder(category: "Recently")
        
        self.populateListTable()
        self.populateFilesCV()
        self.sortFiles()
        
        self.categoriesCV.reloadData()
        self.listTableView.reloadData()
        self.filesCollectionView.reloadData()

        setupProgressMonitor()
    }
    
    func setupNavigationBar() {
        extendedLayoutIncludesOpaqueBars = true
        self.navigationItem.hidesBackButton = true
        self.navigationController?.navigationBar.backgroundColor = UIColor.black
        self.navigationController?.navigationBar.tintColor = UIColor.white
    }
    
    func sortFiles() {
        print("sortFiles() in " + navigator.selected.category)
        
        switch navigator.selected.category {
        case "Recently", "Publications", "Books", "Fast folder":
            if !filesCV.isEmpty {
                if navigator.selected.tableNumber >= filesCV.count {
                    navigator.selected.tableNumber = 0
                }
                if selectedSortingCVNumber == 0 {
                    filesCV[navigator.selected.tableNumber] = filesCV[navigator.selected.tableNumber].sorted(by: {($0.filename) < ($1.filename)})
                } else if selectedSortingCVNumber == 1 {
                    filesCV[navigator.selected.tableNumber] = filesCV[navigator.selected.tableNumber].sorted(by: {($0.dateModified)! > ($1.dateModified)!})
                } else {
                    filesCV[navigator.selected.tableNumber] = filesCV[navigator.selected.tableNumber].sorted(by: {($0.views) > ($1.views)})
                }
            }
            
        default:
            if !docCV.isEmpty {
                if navigator.selected.tableNumber >= docCV.count {
                    navigator.selected.tableNumber = 0
                }
                if selectedSortingCVNumber == 0 {
                    for i in 0..<docCV[navigator.selected.tableNumber].files.count {
                        docCV[navigator.selected.tableNumber].files[i] = docCV[navigator.selected.tableNumber].files[i].sorted(by: {$0.filename < $1.filename})
                    }
                } else {
                    for i in 0..<docCV[navigator.selected.tableNumber].files.count {
                        docCV[navigator.selected.tableNumber].files[i] = docCV[navigator.selected.tableNumber].files[i].sorted(by: {($0.dateModified)! > ($1.dateModified)!})
                    }
                }
            }
        }
    }
    
    func updateApplicant() {
        let name = applicantTableTitles[selectedApplicant]
        let announcement = navigator.list.main[navigator.selected.tableNumber]
        var qualifies = false
        if applicantQualify.selectedSegmentIndex == 0 {
            qualifies = true
        }
        dataManager.updateApplicants(announcement: announcement, name: name, grade: Int16(applicantGrade.value), education: applicantEducation.text, note: applicantNotes.text, qualifies: qualifies)
    }
    
    func updateCategoriesOrder() {
        print("updateCategoriesOrder")
        
        let orderBefore = orderedCategories.map{ $0.displayOrder }
        orderedCategories = dataManager.categoriesCD.sorted(by: {($0.numberViews, Int16.max - $0.originalOrder) > ($1.numberViews, Int16.max - $1.originalOrder)})
        let orderAfter = orderedCategories.map{ $0.displayOrder }
        
        if orderBefore != orderAfter {
            
            print(navigator.selected.category)
            sendNotification(text: "Updating the order of categories")
            print("Updating order of categories")
            let number = categories.index(where: { $0 == navigator.selected.category })
//            let index = orderedCategories.index(where: { $0.name == navigator.selected.category })
            navigator.selected.categoryNumber = number!
//            let indexPath = IndexPath(row: index!, section: 0)
            
            categoriesCV.reloadData()
            populateListTable()
            populateFilesCV()
            sortFiles()
            listTableView.reloadData()
            filesCollectionView.reloadData()
        }
    }
    
    func setFilesCell(cell: FilesCell, file: LocalFile) -> FilesCell {
        
        cell.backgroundColor = UIColor.white
        cell.layer.borderColor = UIColor.black.cgColor
        cell.layer.borderWidth = 1
        cell.layer.cornerRadius = 8
        cell.clipsToBounds = true
        
        cell.thumbnail.image = file.thumbnail
        cell.label.text = file.filename
        cell.deleteIcon.isHidden = true
        cell.scoreLabel.isHidden = true
        
        //Indicator for downloading (ONLY PUBLICATIONS?)
        if file.downloading && !file.available {
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
        
        cell.sizeLabel.text = file.size
        
        if file.downloaded {
            cell.fileOffline.image = #imageLiteral(resourceName: "DownloadingPDF.png")
            cell.fileOffline.isHidden = false
        } else {
            if file.available {
                cell.fileOffline.isHidden = true
            } else {
                cell.fileOffline.image = #imageLiteral(resourceName: "FileNotAvailable")
                cell.fileOffline.isHidden = false
            }
        }
        
        if cell.label.text == currentSelectedFilename {
            selectedLocalFile = file
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
        
        let path = file.path
        
        if !path.isEmpty && dataManager.favoritesCD.first(where: {$0.path == path}) != nil {
            cell.favoriteIcon.isHidden = false
        } else {
            cell.favoriteIcon.isHidden = true
        }
        
        if !path.isEmpty && dataManager.readingListCD.first(where: {$0.path == path}) != nil {
            cell.readListIcon.isHidden = false
        } else {
            cell.readListIcon.isHidden = true
        }
        
        if let gradeData = dataManager.gradesCD.first(where: {$0.path == path} ) {
            if gradeData.show {
                cell.gradeIcon.isHidden = false
                switch gradeData.type {
                case "Approved":
                    cell.gradeIcon.image = #imageLiteral(resourceName: "Approved")
                case "Fail":
                    cell.gradeIcon.image = #imageLiteral(resourceName: "Fail")
                case "Warning":
                    cell.gradeIcon.image = #imageLiteral(resourceName: "Warning")
                case "Reading":
                    cell.gradeIcon.image = #imageLiteral(resourceName: "Read")
                default:
                    cell.gradeIcon.image = #imageLiteral(resourceName: "Approved")
                }
            } else {
                cell.gradeIcon.isHidden = true
            }
        } else {
            cell.gradeIcon.isHidden = true
        }
        
        cell.timesViewed.isHidden = true
        cell.timesViewed.text = "0"
        if let bookmark = dataManager.getBookmark(file: file) {
            if bookmark.timesVisited > 0 {
                cell.timesViewed.isHidden = false
                cell.timesViewed.text = "\(bookmark.timesVisited)"
            }
        }
        
        let folderPath = path.replacingOccurrences(of: file.filename, with: "")
        let name = file.filename.replacingOccurrences(of: ".pdf", with: "")
        for item in dataManager.examsCD {
            if item.path == folderPath {
                let students = item.student as! Set<Student>
                if let currentScore = students.first(where: {$0.name == name}) {
                    cell.scoreLabel.text = "\(currentScore.totalScore)"
                    cell.scoreLabel.isHidden = false
                    if currentScore.totalScore >= item.passLimit {
                        cell.scoreLabel.textColor = UIColor.black
                        cell.scoreLabel.backgroundColor = UIColor.green
                    } else {
                        cell.scoreLabel.textColor = UIColor.white
                        cell.scoreLabel.backgroundColor = UIColor.red
                    }
                }
            }
        }
        
        return cell
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
            dataManager.searchFiles()
        }
        
        if navigator.selected.category == "Search" {
            populateFilesCV()
            searchCollectionView.reloadData()
        } else {
            populateListTable()
            populateFilesCV()
            sortFiles()
            
            listTableView.reloadData()
            filesCollectionView.reloadData()
        }
    }
    
    
    
    
    
    // MARK: - Table view
    func numberOfSections(in tableView: UITableView) -> Int {
        
        if tableView == self.expensesTableView {
            if navigator.selected.tableNumber < dataManager.projectCD.count {
                return (dataManager.projectCD[navigator.selected.tableNumber].expense?.count)!
            } else {
                return 0
            }
            
        } else if tableView == self.applicantTableList {
            return applicantTableTitles.count
            
        } else {
            if navigator.selected.folderLevel == 0 {
                return navigator.list.main.count
            } else {
                return navigator.list.sub.count
            }
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
            switch navigator.selected.category {
            
            case "Recently", "Publications", "Books", "Economy", "Work documents", "Reading list":
                return 1
                
            default:
                if !navigator.list.main.isEmpty {
                    return 1
                } else {
                    return 0
                }
            }
        } else if tableView == self.applicantTableList {
            return 1
        }
        return number
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cellToReturn = UITableViewCell()
        
        if tableView == self.expensesTableView {
            
            let cell = expensesTableView.dequeueReusableCell(withIdentifier: "economyCell") as! EconomyCell
            let currentProject = dataManager.projectCD[navigator.selected.tableNumber]
            
            if indexPath.section == 0 {
                currentProject.amountRemaining = currentProject.amountReceived
            }
            
            let expenses = currentProject.expense?.allObjects as! [Expense]
            
            cell.setExpense(expense: expenses[indexPath.section])
            cell.delegate = self
            
            cell.backgroundColor = UIColor.white
            cell.layer.borderColor = UIColor.black.cgColor
            cell.layer.borderWidth = 1
            cell.layer.cornerRadius = 8
            cell.clipsToBounds = true
            
            if expenses[indexPath.section].active {
                if expenses[indexPath.section].type == "Expense" {
                    cell.typeString.text = "Expense"
                    cell.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
                    let overhead = Int32(0.01*Float(expenses[indexPath.section].amount)*Float(expenses[indexPath.section].overhead))
                    currentProject.amountRemaining = currentProject.amountRemaining - expenses[indexPath.section].amount - overhead
                    
                } else {
                    
                    cell.typeString.text = "Salary (" + "\(expenses[indexPath.section].years)" + ")"
                    cell.backgroundColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
                    let overhead = Int32(0.01*Float(expenses[indexPath.section].amount*Int32(expenses[indexPath.section].years))*Float(expenses[indexPath.section].overhead))
                    currentProject.amountRemaining = currentProject.amountRemaining - expenses[indexPath.section].amount*Int32(expenses[indexPath.section].years) - overhead
                }
            } else {
                cell.backgroundColor = #colorLiteral(red: 0.9568627477, green: 0.6588235497, blue: 0.5450980663, alpha: 1)
            }
            amountRemainingString.text = "\(currentProject.amountRemaining)"
            
            cellToReturn = cell

        } else if tableView == self.listTableView {
            
            let cell = listTableView.dequeueReusableCell(withIdentifier: "listTableCell") as! ListCell
            
            switch navigator.selected.category {
            case "Recently", "Publications", "Books", "Reading list":
                cell.listLabel.text = navigator.list.main[indexPath.section]
                cell.listNumberOfItems.text = "\(filesCV[indexPath.section].count)"
                
                cell.backgroundColor = UIColor.white
                cell.layer.borderColor = UIColor.black.cgColor
                cell.layer.borderWidth = 1
                cell.layer.cornerRadius = 8
                cell.clipsToBounds = true
                
            case "Economy":
                cell.listLabel.text = navigator.list.main[indexPath.section]
                cell.listNumberOfItems.text = ""
                cell.backgroundColor = UIColor.white
                cell.layer.borderColor = UIColor.black.cgColor
                cell.layer.borderWidth = 1
                cell.layer.cornerRadius = 8
                cell.clipsToBounds = true
                
            case "Memos":
                cell.listLabel.text = navigator.list.main[indexPath.section]
                let number = self.dataManager.memosCD.filter{ $0.tag == navigator.list.main[indexPath.section] }
                if navigator.list.main[indexPath.section] == "+ New category" {
                    cell.listNumberOfItems.text = ""
                } else if navigator.list.main[indexPath.section] == "All memos" {
                    cell.listNumberOfItems.text = "\(self.dataManager.memosCD.count)"
                } else {
                    cell.listNumberOfItems.text = "\(number.count)"
                }
                cell.backgroundColor = UIColor.white
                cell.layer.borderColor = UIColor.black.cgColor
                cell.layer.borderWidth = 1
                cell.layer.cornerRadius = 8
                cell.clipsToBounds = true
                
            case "Bulletin board":
                cell.listLabel.text = navigator.list.main[indexPath.section]
                let number = self.dataManager.bulletinCD.filter{ $0.bulletinName == navigator.list.main[indexPath.section] }
                cell.listNumberOfItems.text = "\(number.first!.filename!.count)"
                cell.backgroundColor = UIColor.white
                cell.layer.borderColor = UIColor.black.cgColor
                cell.layer.borderWidth = 1
                cell.layer.cornerRadius = 8
                cell.clipsToBounds = true
                
            default:
                if navigator.selected.folderLevel == 0 {
                    cell.listLabel.text = navigator.list.main[indexPath.section]
                } else {
                    cell.listLabel.text = navigator.list.sub[indexPath.section]
                }
                cell.listNumberOfItems.text = ""
                
                cell.backgroundColor = UIColor.white
                cell.layer.borderColor = UIColor.black.cgColor
                cell.layer.borderWidth = 1
                cell.layer.cornerRadius = 8
                cell.clipsToBounds = true

            }

            cellToReturn = cell

        } else if tableView == self.applicantTableList {
            
            let cell = applicantTableList.dequeueReusableCell(withIdentifier: "applicantListCell") as! ApplicantListCell
            
            cell.applicantListName.text = applicantTableTitles[indexPath.section]
            cell.backgroundColor = UIColor.white
            cell.layer.borderColor = UIColor.black.cgColor
            cell.layer.borderWidth = 1
            cell.layer.cornerRadius = 8
            cell.clipsToBounds = true
            
            
            if let applicant = dataManager.applicantCD.first(where: { $0.name == applicantTableTitles[indexPath.section] }) {
                cell.applicantListGrade.text = "\(applicant.grade)"
                if applicant.grade == 0 || !applicant.qualifies {
                    cell.backgroundColor = UIColor.red
                } else if applicant.grade > 0 && applicant.grade < 9 {
                    cell.backgroundColor = UIColor.white
                } else if applicant.grade == 10 {
                    cell.backgroundColor = UIColor.green
                }
            } else {
                cell.applicantListGrade.text = "0"
            }

            
            cellToReturn = cell
        }
        
        return cellToReturn
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("didSelectRowAt in tableView: " + navigator.selected.category)
        
//        let prevSubtableNumber = navigator.selected //selectedSubtableNumber
        if tableView == self.listTableView {
            
            if navigator.selected.folderLevel != 1 {
                navigator.selected.tableNumber = indexPath.section
            }
            
            switch navigator.selected.category {
            case "Recently", "Publications", "Books", "Reading list", "Bulletin board":
                navigator.selected.tableNumber = indexPath.section
                if filesCV[indexPath.section].count > 0 {
                    scrollToSection(indexPath.section)
                }

            case "Teaching":
                if navigator.selected.folderLevel == 1 {
                    navigator.selected.subFolderNumber = indexPath.section
                    navigator.selected.subFolderName = navigator.list.sub[indexPath.section]
                    scrollToSection(navigator.selected.subFolderNumber!)
                } else {
                    navigator.selected.tableNumber = indexPath.section
                    navigator.selected.mainFolderNumber = indexPath.section
                    navigator.selected.mainFolderName = navigator.list.main[indexPath.section]
                    
                    currentIndexPath = indexPath
                    sortFiles()
                    self.filesCollectionView.reloadData()
                }

            case "Work documents":
                if workDocStrings[selectedWorkDocNumber] == "Hiring" {
                    self.populateHiringTable()
                    self.applicantTableList.reloadData()
                    
                    //RELOAD APPLICANT WINDOW
                } else {
                    currentIndexPath = indexPath
                    self.sortFiles()
                    self.filesCollectionView.reloadData()
                }
                
            case "Economy":
                if economyStrings[selectedEconomyNumber] == "Projects" {
                    let currentProject = dataManager.projectCD[navigator.selected.tableNumber]
                    let deadline = self.fileHandler.getDeadline(date: currentProject.deadline, string: nil, option: nil)
                    
                    if deadline.string == nil {
                        deadlineString.text = "Deadline not specified"
                    } else {
                        deadlineString.text = "Deadline: " + deadline.string!
                    }
                    
                    currencyString.text = currentProject.currency
                    amountReceivedString.text = "\(currentProject.amountReceived)"
                    amountRemainingString.text = "\(currentProject.amountRemaining)"
                    
                    self.expensesTableView.reloadData()
                    
                } else if economyStrings[selectedEconomyNumber] == "Invoices" {
                    if docCV[0].files[indexPath.section].count > 0 {
                        scrollToSection(indexPath.section)
                    }
                    
                } else if economyStrings[selectedEconomyNumber] == "Grants" {
                    if navigator.selected.tableNumber <= dataManager.fundCD.count {
                        let currentFund = dataManager.fundCD[navigator.selected.tableNumber]
                        if let date = currentFund.deadline {
                            organisationDeadline.date = date
                        } else {
                            organisationDeadline.date = Date()
                        }
                        if let currency = currentFund.currency {
                            currencyFunding.text = currency
                        } else {
                            currencyFunding.text = "EUR"
                        }
                        amountFunding.text = "\(currentFund.amount)"
                        if let website = currentFund.website {
                            internetAddressOrganisation.text = website
                        }
                        if let instructions = currentFund.instructions {
                            organisationInstructions.text = instructions
                        }
                        nameOrganisation.text = currentFund.name!
                    }
                }
                
            case "Memos":
                
                if navigator.list.main[navigator.selected.tableNumber] == "+ New category" {
                    let inputNewCat = UIAlertController(title: "New memo category", message: "Enter name of new category", preferredStyle: .alert)
                    inputNewCat.addTextField(configurationHandler: { (newCat: UITextField) -> Void in
                        newCat.placeholder = "Enter category"
                    })
                    inputNewCat.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                        let newCat = inputNewCat.textFields?[0]
                        self.dataManager.addNewItem(title: newCat?.text, number: [""])
                        inputNewCat.dismiss(animated: true, completion: nil)
                        
                        self.populateListTable()
                        self.populateFilesCV()
                        self.sortFiles()
                        
                        self.listTableView.reloadData()
                        self.memosCollectionView.reloadData()

                    }))
                    inputNewCat.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                        inputNewCat.dismiss(animated: true, completion: nil)
                    }))
                    self.present(inputNewCat, animated: true, completion: nil)
                    
                } else {
                    self.saveAndUpdateMemos()
                    self.populateFilesCV()
                    self.memosCollectionView.reloadData()
                }
                
            default:
                
                currentIndexPath = indexPath
                sortFiles()
                self.filesCollectionView.reloadData()
                
            }
            
        } else if tableView == self.applicantTableList {
            
            selectedApplicant = indexPath.section
            let name = applicantTableTitles[selectedApplicant]
            let announcement = navigator.list.main[navigator.selected.tableNumber]
            
            if let currentApplicant = dataManager.applicantCD.first(where: {$0.name == name && $0.announcement == announcement}) {
                
                applicantName.text = currentApplicant.name
                applicantGrade.value = Float(currentApplicant.grade)
                applicantEducation.text = currentApplicant.education
                applicantNotes.text = currentApplicant.notes
                applicantCVicon.setImage(UIImage(named: "FileOffline.png"), for: .normal)
                applicantPLicon.setImage(UIImage(named: "FileOffline.png"), for: .normal)
                applicantLoRicon.setImage(UIImage(named: "FileOffline.png"), for: .normal)
                applicantGradesIcon.setImage(UIImage(named: "FileOffline.png"), for: .normal)
                activityCV.isHidden = true
                activityPL.isHidden = true
                activityLoR.isHidden = true
                activityGrades.isHidden = true
                
                if currentApplicant.qualifies {
                    applicantQualify.selectedSegmentIndex = 0
                } else {
                    applicantQualify.selectedSegmentIndex = 1
                }
                applicantGradeValue.text = "\(currentApplicant.grade)"
                
                do {
                    let fileURLs = try fileManagerDefault.contentsOfDirectory(at: dataManager.hiringURL.appendingPathComponent(currentApplicant.announcement!, isDirectory: true).appendingPathComponent(currentApplicant.name!, isDirectory: true), includingPropertiesForKeys: nil)
                    
                    for file in fileURLs {
                        let filename = fileHandler.getFilenameFromURL(icloudURL: file)
                        print(filename)
                        if filename == "CV.pdf" {
                                let thumbnail = fileHandler.getThumbnail(icloudURL: file, localURL: file, localExist: false, pageNumber: 0)
                            applicantCVicon.setImage(thumbnail, for: .normal)
                        } else if filename == "PL.pdf" {
                            let thumbnail = fileHandler.getThumbnail(icloudURL: file, localURL: file, localExist: false, pageNumber: 0)
                            applicantPLicon.setImage(thumbnail, for: .normal)
                        } else if filename == "LoR.pdf" {
                            let thumbnail = fileHandler.getThumbnail(icloudURL: file, localURL: file, localExist: false, pageNumber: 0)
                            applicantLoRicon.setImage(thumbnail, for: .normal)
                        } else if filename == "Grades.pdf" {
                            let thumbnail = fileHandler.getThumbnail(icloudURL: file, localURL: file, localExist: false, pageNumber: 0)
                            applicantGradesIcon.setImage(thumbnail, for: .normal)
                        }
                    }
                    
                } catch {
                    print("Here")
                }
                
            } else {
                if let index = dataManager.hiringFiles.index(where: {$0.parentFolder == name}) {
                    print(index)
                    applicantName.text = dataManager.hiringFiles[index].parentFolder
                    applicantGrade.value = dataManager.hiringFiles[index].rank!
                } else {
                    print("Here")
                }
            }
            
            applicantName.text = applicantTableTitles[selectedApplicant]
            
        }
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        print("performDropWith")
        
        if tableView == self.listTableView {
            switch categories[navigator.selected.categoryNumber] {
            case "Publications":
                let number = categories.index(where: { $0 == "Publications" })
                
                if let section = coordinator.destinationIndexPath?.section {
                    switch sortSubtableStrings[selectedSortingNumber] {
                    case "Tag":
                        let groupName = navigator.list.main[section]
                        if let filename = coordinator.items[0].dragItem.localObject {
                            if let dragedPublication = filesCV[navigator.selected.tableNumber].first(where: {$0.filename == filename as! String}) {
                                if let group = dataManager.publicationGroupsCD.first(where: {$0.tag! == groupName}) {
                                    dataManager.addPublicationToGroup(filename: (dragedPublication.filename), group: group)
                                }
                            }
                        }
                    case "Author":
                        let authorName = navigator.list.main[section]
                        if let filename = coordinator.items[0].dragItem.localObject {
                            if let dragedPublication = dataManager.localFiles[number!].first(where: {$0.filename == filename as! String}) {
                                dataManager.assignPublicationToAuthor(filename: (dragedPublication.filename), authorName: authorName)
                            }
                        }
                    case "Journal":
                        let journalName = navigator.list.main[section]
                        if let filename = coordinator.items[0].dragItem.localObject {
                            if let dragedPublication = dataManager.localFiles[number!].first(where: {$0.filename == filename as! String}) {
                                dataManager.assignPublicationToJournal(filename: (dragedPublication.filename), journalName: journalName)
                            }
                        }
                    case "Year":
                        let year = navigator.list.main[section]
                        if let filename = coordinator.items[0].dragItem.localObject {
                            if let index = dataManager.localFiles[number!].index(where: { $0.filename == filename as! String} ) {
                                dataManager.localFiles[number!][index].year = Int16(isStringAnInt(stringNumber: year))
                                dataManager.updateIcloud(file: dataManager.localFiles[number!][index], oldFilename: nil, newFilename: nil, expense: nil, project: nil, type: "Publications", bookmark: nil, fund: nil)
                                dataManager.updateCoreData(file: dataManager.localFiles[number!][index], oldFilename: nil, newFilename: nil)
                            }
                        }
                    default:
                        print("Default 141")
                    }
                }
                
            case "Books":
                if let section = coordinator.destinationIndexPath?.section {
                    let groupName = navigator.list.main[section]
                    if let filename = coordinator.items[0].dragItem.localObject {
                        if let dragedBook = filesCV[navigator.selected.tableNumber].first(where: {$0.filename == filename as! String}) {
                            if let group = dataManager.booksGroupsCD.first(where: {$0.tag! == groupName}) {
                                dataManager.addBookToGroup(filename: dragedBook.filename, group: group)
                            }
                        }
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
            switch categories[navigator.selected.categoryNumber] {
                
            case "Recently":
                returnBool = false
                
            case "Publications":
                switch sortSubtableStrings[selectedSortingNumber] {
                case "Tag":
                    if indexPath.section > 2 {
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
            
            case "Books":
                if indexPath.section > 2 {
                    returnBool = true
                } else {
                    returnBool = false
                }
            
            case "Economy":
                returnBool = true
                
            case "Bulletin board":
                returnBool = true

            case "Memos":
                returnBool = true
            
            case "Teaching":
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
                
                //FIX! WHEN AUTHOR IS REMOVED, CANNOT SCROLL TO ITEM
                switch categories[navigator.selected.categoryNumber] {
                case "Publications":
                    if sortSubtableStrings[selectedSortingNumber] == "Tag" {
                        let groupName = navigator.list.main[indexPath.section]
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
                        let authorName = navigator.list.main[indexPath.section]
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
                        let journalName = navigator.list.main[indexPath.section]
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
                if optionsSegment.selectedSegmentIndex == 0 {
                    
                    let currentProject = navigator.list.main[indexPath.section]
                    if let projectToDelete = dataManager.projectCD.first(where: {$0.name! == currentProject}) {
                        dataManager.context.delete(projectToDelete)
                        
                        dataManager.saveCoreData()
                        dataManager.loadCoreData()
                        
                        populateListTable()
                        categoriesCV.reloadData()
                        self.categoriesCV.selectItem(at: IndexPath(row: self.navigator.selected.categoryNumber, section: 0), animated: true, scrollPosition: .top)
                        listTableView.reloadData()
                        expensesTableView.reloadData()
                    }
                    
                } else if optionsSegment.selectedSegmentIndex == 2 {
                    
                    let currentFund = navigator.list.main[indexPath.section]
                    if let fundToDelete = dataManager.fundCD.first(where: {$0.name! == currentFund}) {
                        dataManager.context.delete(fundToDelete)
                        
                        dataManager.saveCoreData()
                        dataManager.loadCoreData()
                        
                        populateListTable()
                        categoriesCV.reloadData()
                        self.categoriesCV.selectItem(at: IndexPath(row: self.navigator.selected.categoryNumber, section: 0), animated: true, scrollPosition: .top)
                        listTableView.reloadData()
                        expensesTableView.reloadData()
                    }
                }
                    
                case "Books":
                    let currentGroup = navigator.list.main[indexPath.section]
                    let groupToDelete = dataManager.booksGroupsCD.first(where: {$0.tag! == currentGroup})
                    dataManager.context.delete(groupToDelete!)
                    
                    dataManager.saveCoreData()
                    dataManager.loadCoreData()
                    
                    populateListTable()
                    populateFilesCV()
                    sortFiles()
                    
                    listTableView.reloadData()
                    filesCollectionView.reloadData()
                
                case "Memos":
                    let currentGroup = navigator.list.main[indexPath.section]
                    
                    if currentGroup != "All memos" && currentGroup != "+ New category" {
                        for memo in dataManager.memosCD {
                            if memo.tag == currentGroup {
                                dataManager.context.delete(memo)
                            }
                        }
                    }
                    
                    dataManager.saveCoreData()
                    dataManager.loadCoreData()
                    
                    populateListTable()
                    populateFilesCV()
                    sortFiles()
                    
                    listTableView.reloadData()
                    memosCollectionView.reloadData()
                    
                case "Bulletin board":
                    let currentBoard = navigator.list.main[indexPath.section]
                    let boardToDelete = dataManager.bulletinCD.first(where: {$0.bulletinName == currentBoard})
                    dataManager.context.delete(boardToDelete!)
                    
                    dataManager.saveCoreData()
                    dataManager.loadCoreData()
                    
                    populateListTable()
                    populateFilesCV()
                    sortFiles()
                    
                    listTableView.reloadData()
                    filesCollectionView.reloadData()
                    
                default:
                    print("Default 104")
                }
                
                
            } else if tableView == self.expensesTableView {
                let currentProject = dataManager.projectCD[navigator.selected.tableNumber]
                var expenses = currentProject.expense?.allObjects as! [Expense]
                
                amountRemainingString.text = "\(currentProject.amountReceived)"
                
                let expenseToRemove = dataManager.expensesCD.first(where: {$0.dateAdded! == expenses[indexPath.section].dateAdded!})
                context.delete(expenseToRemove!)
                
                dataManager.saveCoreData()
                dataManager.loadCoreData()
                
                expensesTableView.reloadData()
            }
        } else {
            print("Other swipe")
        }
    }
    
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        if tableView == self.expensesTableView {
            let currentProject = dataManager.projectCD[navigator.selected.tableNumber]
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
                editExpense.addTextField(configurationHandler: { (inputNewProject: UITextField) -> Void in
                    inputNewProject.text = self.currentExpense.type
                })
                editExpense.addTextField(configurationHandler: { (inputNewProject: UITextField) -> Void in
                    inputNewProject.text = "\(self.currentExpense.years)"
                })
                editExpense.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                    let amount = editExpense.textFields?[0].text
                    let overhead = editExpense.textFields?[1].text
                    let reference = editExpense.textFields?[2].text
                    let comment = editExpense.textFields?[3].text
                    let type = editExpense.textFields?[4].text
                    let year = editExpense.textFields?[5].text
                    
                    self.currentExpense.amount = self.isStringAnInt(stringNumber: amount)
                    self.currentExpense.overhead = Int16(self.isStringAnInt(stringNumber: overhead))
                    self.currentExpense.reference = reference
                    self.currentExpense.comment = comment
                    self.currentExpense.type = type
                    self.currentExpense.years = Int16(self.isStringAnInt(stringNumber: year))
                    
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
            
        } else if tableView == self.listTableView {
            
            if categories[navigator.selected.categoryNumber] == "Economy" {
                
                if optionsSegment.selectedSegmentIndex == 0 {
                    currentProject = dataManager.projectCD[indexPath.section]
                    
                    let editAction = UIContextualAction(style: .normal, title: "Edit") { (action, view, nil) in
                        let editProject = UIAlertController(title: "Edit " + self.currentProject.name!, message: "Edit project data", preferredStyle: .alert)
                        editProject.addTextField(configurationHandler: { (editProject: UITextField) -> Void in
                            editProject.text = "\(self.currentProject.amountReceived)"
                        })
                        editProject.addTextField(configurationHandler: { (inputNewProject: UITextField) -> Void in
                            inputNewProject.text = self.currentProject.currency!
                        })
                        editProject.addTextField(configurationHandler: { (inputNewProject: UITextField) -> Void in
                            let deadline = self.fileHandler.getDeadline(date: self.currentProject.deadline!, string: nil, option: nil)
                            inputNewProject.text = deadline.string!
                        })
                        
                        editProject.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                            let amount = editProject.textFields?[0].text
                            let currency = editProject.textFields?[1].text
                            let deadlineTMP = editProject.textFields?[2].text
                            
                            self.dateFormatter.dateFormat = "yyyy-MM-dd"
                            var dateComponents = DateComponents()
                            dateComponents.year = 1
                            var deadline = Calendar.current.date(byAdding: dateComponents, to: Date())
                            if let tmp = self.dateFormatter.date(from: deadlineTMP!) {
                                deadline = tmp
                            }
                            
                            self.currentProject.amountReceived = self.isStringAnInt(stringNumber: amount)
                            self.currentProject.currency = currency
                            self.currentProject.deadline = deadline
                            
                            self.dataManager.saveCoreData()
                            self.dataManager.loadCoreData()
                            
                            self.expensesTableView.reloadData()
                            editProject.dismiss(animated: true, completion: nil)
                            self.listTableView.reloadData()
                        }))
                        
                        editProject.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                            editProject.dismiss(animated: true, completion: nil)
                        }))
                        self.present(editProject, animated: true, completion: nil)
                    }
                    
                    editAction.backgroundColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
                    
                    let configuration = UISwipeActionsConfiguration(actions: [editAction])
                    return configuration
                    
                } else if optionsSegment.selectedSegmentIndex == 2 {
                    
                    currentFund = dataManager.fundCD[indexPath.section]
                    
                    let editAction = UIContextualAction(style: .normal, title: "Edit") { (action, view, nil) in
                        let editFund = UIAlertController(title: "Edit " + self.currentFund.name!, message: "Edit project data", preferredStyle: .alert)
                        editFund.addTextField(configurationHandler: { (editFund: UITextField) -> Void in
                            editFund.text = "\(self.currentFund.amount)"
                        })
                        editFund.addTextField(configurationHandler: { (inputNewFund: UITextField) -> Void in
                            inputNewFund.text = self.currentFund.currency!
                        })
                        editFund.addTextField(configurationHandler: { (inputNewFund: UITextField) -> Void in
                            let deadline = self.fileHandler.getDeadline(date: self.currentFund.deadline!, string: nil, option: nil)
                            inputNewFund.text = deadline.string!
                        })
                        
                        editFund.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                            let amount = editFund.textFields?[0].text
                            let currency = editFund.textFields?[1].text
                            let deadlineTMP = editFund.textFields?[2].text
                            
                            self.dateFormatter.dateFormat = "yyyy-MM-dd"
                            var dateComponents = DateComponents()
                            dateComponents.year = 1
                            var deadline = Calendar.current.date(byAdding: dateComponents, to: Date())
                            if let tmp = self.dateFormatter.date(from: deadlineTMP!) {
                                deadline = tmp
                            }
                            
                            self.currentFund.amount = Int64(self.isStringAnInt(stringNumber: amount))
                            self.currentFund.currency = currency
                            self.currentFund.deadline = deadline
                            
                            self.dataManager.saveCoreData()
                            self.dataManager.loadCoreData()
                            
                            self.expensesTableView.reloadData()
                            editFund.dismiss(animated: true, completion: nil)
                            self.listTableView.reloadData()
                        }))
                        editFund.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                            editFund.dismiss(animated: true, completion: nil)
                        }))
                        self.present(editFund, animated: true, completion: nil)
                    }
                    
                    editAction.backgroundColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
                    
                    let configuration = UISwipeActionsConfiguration(actions: [editAction])
                    return configuration
                    
                } else {
                    return nil
                }
            
            } else if navigator.selected.category == "Teaching" {
                
                let updateHotFolderAction = UIContextualAction(style: .normal, title: "Fast folder") { (action, view, nil) in

                    if self.navigator.selected.folderLevel == 0 {
                        self.dataManager.setFastFolder(mainFolder: self.navigator.list.main[indexPath.section], subFolder: nil)
                    } else {
                        let mainFolder = self.navigator.folderStructure.mainFolders[self.navigator.selected.categoryNumber!][self.navigator.selected.mainFolderNumber!]
                        self.dataManager.setFastFolder(mainFolder: mainFolder, subFolder: self.navigator.list.sub[indexPath.section])
                    }
                    self.categoriesCV.reloadData()
                }
                
                let setAsExam = UIContextualAction(style: .normal, title: "Exams") { (action, view, nil) in
                    
                    
                    if self.navigator.selected.folderLevel == 0 {
                        let mainFolder = self.navigator.folderStructure.mainFolders[self.navigator.selected.categoryNumber!][indexPath.section]
                        self.navigator.path = self.navigator.selected.category + mainFolder
                        self.navigator.selected.mainFolderName = mainFolder
                    } else {
                        let mainFolder = self.navigator.folderStructure.mainFolders[self.navigator.selected.categoryNumber!][self.navigator.selected.mainFolderNumber!]
                        self.navigator.selected.mainFolderName = mainFolder
                        let subFolder = self.navigator.list.sub[indexPath.section]
                        self.navigator.selected.subFolderName = subFolder
                        self.navigator.path = self.navigator.selected.category + mainFolder + subFolder
                    }
                    print(self.navigator.path)
                    self.performSegue(withIdentifier: "examSegue", sender: self)
                }

                updateHotFolderAction.backgroundColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
                setAsExam.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
                
                let configuration = UISwipeActionsConfiguration(actions: [setAsExam, updateHotFolderAction])
                return configuration
                
            } else if navigator.selected.category == "Memos" {
                
                let currentMemo = self.navigator.list.main[indexPath.section]
                
                if currentMemo != "All memos" && currentMemo != "+ New category" {
                    let editAction = UIContextualAction(style: .normal, title: "Rename") { (action, view, nil) in
                        let editCategory = UIAlertController(title: "Edit " + currentMemo, message: "Edit category tag", preferredStyle: .alert)
                        editCategory.addTextField(configurationHandler: { (editCategory: UITextField) -> Void in
                            editCategory.text = currentMemo
                        })
                        
                        editCategory.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                            
                            if let newName = editCategory.textFields?[0].text {
                                
                                for memo in self.dataManager.memosCD {
                                    if memo.tag == currentMemo {
                                        memo.tag = newName
                                    }
                                }
                                
                                self.dataManager.saveCoreData()
                                self.dataManager.loadCoreData()
                                
                                editCategory.dismiss(animated: true, completion: nil)
                                
                                self.populateListTable()
                                self.populateFilesCV()
                                self.listTableView.reloadData()
                                self.memosCollectionView.reloadData()
                                
                            }
                        }))
                        editCategory.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                            editCategory.dismiss(animated: true, completion: nil)
                        }))
                        self.present(editCategory, animated: true, completion: nil)
                    }
                    
                    editAction.backgroundColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
                    
                    let configuration = UISwipeActionsConfiguration(actions: [editAction])
                    return configuration
                    
                } else {
                    return nil
                }
                
            } else if navigator.selected.category == "Bulletin board" {
                
                let currentBB = self.navigator.list.main[indexPath.section]
                
                let editAction = UIContextualAction(style: .normal, title: "Rename") { (action, view, nil) in
                    let editName = UIAlertController(title: "Edit " + currentBB, message: "Edit name tag", preferredStyle: .alert)
                    editName.addTextField(configurationHandler: { (editName: UITextField) -> Void in
                        editName.text = currentBB
                    })
                    
                    editName.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                        
                        if let newName = editName.textFields?[0].text {
                            
                            for bulletin in self.dataManager.bulletinCD {
                                if bulletin.bulletinName == currentBB {
                                    bulletin.bulletinName = newName
                                }
                            }
                            
                            self.dataManager.saveCoreData()
                            self.dataManager.loadCoreData()
                            
                            editName.dismiss(animated: true, completion: nil)
                            
                            self.populateListTable()
                            self.populateFilesCV()
                            self.listTableView.reloadData()
                            self.filesCollectionView.reloadData()
                            
                        }
                    }))
                    editName.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                        editName.dismiss(animated: true, completion: nil)
                    }))
                    self.present(editName, animated: true, completion: nil)
                }
                
                editAction.backgroundColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
                
                let configuration = UISwipeActionsConfiguration(actions: [editAction])
                return configuration
                
            } else if navigator.selected.category == "Books" {
                
                let currentTag = self.navigator.list.main[indexPath.section]
                
                let editAction = UIContextualAction(style: .normal, title: "Rename") { (action, view, nil) in
                    let editName = UIAlertController(title: "Edit " + currentTag, message: "Edit name tag", preferredStyle: .alert)
                    editName.addTextField(configurationHandler: { (editName: UITextField) -> Void in
                        editName.text = currentTag
                    })
                    
                    editName.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                        
                        if let newName = editName.textFields?[0].text {
                            let oldName = self.navigator.list.main[indexPath.section]
                            let number = self.categories.index(where: { $0 == "Books" })
                            // Create new group
                            self.dataManager.addNewItem(title: newName, number: [""])
                            let newGroup = self.dataManager.booksGroupsCD.first(where: {$0.tag == newName})
                            // Affected files
                            let files = self.dataManager.localFiles[number!].filter{ $0.groups.contains(oldName)}
                            // Remove affected files and add to new group
                            for file in files {
                                self.dataManager.removeFromGroup(file: file, group: oldName)
                                self.dataManager.addBookToGroup(filename: file.filename, group: newGroup!)
                            }
                            // Remove group
                            let oldGroup = self.dataManager.booksGroupsCD.first(where: {$0.tag == oldName})
                            self.dataManager.context.delete(oldGroup!)
                        }

                            self.dataManager.saveCoreData()
                            self.dataManager.loadCoreData()

                            editName.dismiss(animated: true, completion: nil)

                            self.populateListTable()
                            self.populateFilesCV()
                            self.listTableView.reloadData()
                            self.filesCollectionView.reloadData()
                        
                    }))
                    editName.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                        editName.dismiss(animated: true, completion: nil)
                    }))
                    self.present(editName, animated: true, completion: nil)
                }
                
                editAction.backgroundColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
                
                let configuration = UISwipeActionsConfiguration(actions: [editAction])
                return configuration
                
            } else if navigator.selected.category == "Publications" && sortSubtableStrings[selectedSortingNumber] == "Tag" {
                
                let currentTag = self.navigator.list.main[indexPath.section]
                
                let editAction = UIContextualAction(style: .normal, title: "Rename") { (action, view, nil) in
                    let editName = UIAlertController(title: "Edit " + currentTag, message: "Edit name tag", preferredStyle: .alert)
                    editName.addTextField(configurationHandler: { (editName: UITextField) -> Void in
                        editName.text = currentTag
                    })
                    
                    editName.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                        
                        if let newName = editName.textFields?[0].text {
                            let oldName = self.navigator.list.main[indexPath.section]
                            let number = self.categories.index(where: { $0 == "Publications" })
                            // Create new group
                            self.dataManager.addNewItem(title: newName, number: [""])
                            let newGroup = self.dataManager.publicationGroupsCD.first(where: {$0.tag == newName})
                            // Affected files
                            let files = self.dataManager.localFiles[number!].filter{ $0.groups.contains(oldName)}
                            // Remove affected files and add to new group
                            for file in files {
                                self.dataManager.removeFromGroup(file: file, group: oldName)
                                self.dataManager.addPublicationToGroup(filename: (file.filename), group: newGroup!)
                            }
                            // Remove group
                            let oldGroup = self.dataManager.publicationGroupsCD.first(where: {$0.tag == oldName})
                            self.dataManager.context.delete(oldGroup!)
                        }
                        
                        self.dataManager.saveCoreData()
                        self.dataManager.loadCoreData()
                        
                        editName.dismiss(animated: true, completion: nil)
                        
                        self.populateListTable()
                        self.populateFilesCV()
                        self.listTableView.reloadData()
                        self.filesCollectionView.reloadData()
                        
                    }))
                    editName.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                        editName.dismiss(animated: true, completion: nil)
                    }))
                    self.present(editName, animated: true, completion: nil)
                }
                
                editAction.backgroundColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
                
                let configuration = UISwipeActionsConfiguration(actions: [editAction])
                return configuration
                
            } else {
                return nil
            }
        } else {
            return nil
        }
        
    }
    
 
    
    
    // MARK: - Collection View
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        
        if collectionView == self.categoriesCV {
            return 1
        } else if collectionView == self.filesCollectionView {
            switch categories[navigator.selected.categoryNumber] {
            case "Recently", "Publications", "Books", "Reading list", "Bulletin board", "Fast folder":
                return navigator.list.main.count
                
            case "Economy":
                if !docCV.isEmpty {
                    return docCV[0].sectionHeader.count
                } else {
                    return 0
                }
                
            default:
                //Every docCV = one section
                if navigator.selected.tableNumber < docCV.count {
                    return docCV[navigator.selected.tableNumber].sectionHeader.count
                } else {
                    return 0
                }
            }
        } else if collectionView == self.memosCollectionView {
            return 1
        } else if collectionView == self.searchCollectionView {
            return dataManager.fullSearch.count
        }
        else {
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == self.categoriesCV {
            return categories.count
        } else if collectionView == self.filesCollectionView {
            switch navigator.selected.category {
            case "Recently", "Publications", "Books", "Reading list", "Bulletin board", "Fast folder":
                return filesCV[section].count
            case "Economy":
                return docCV[0].files[section].count
            default:
                return docCV[navigator.selected.tableNumber].files[section].count
            }
        } else if collectionView == self.memosCollectionView {
            return memosCV.count
        } else if collectionView == self.searchCollectionView {
            return dataManager.fullSearch[section].files.count
        } else {
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if collectionView == self.categoriesCV {
            
            if navigator.selected.category != "Search" {
                searchBar.isHidden = true
                dataManager.isSearching = false
            }
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "categoryCell", for: indexPath) as! categoryCell
            let number = Int(orderedCategories[indexPath.row].originalOrder)
            
            var itemsSaving = 0
            var itemsDownloading = 0
            var itemsDisplay = itemsSaving + itemsDownloading
            
            if orderedCategories[indexPath.row].name != "Memos" && orderedCategories[indexPath.row].name != "Settings" && orderedCategories[indexPath.row].name != "Reading list" && orderedCategories[indexPath.row].name != "Bulletin board" {
                itemsSaving = dataManager.localFiles[number].filter{ $0.saving == true }.count
                itemsDownloading = dataManager.localFiles[number].filter{ $0.downloading == true }.count
                itemsDisplay = itemsSaving + itemsDownloading
            }
            
            switch orderedCategories[indexPath.row].name {
            case "Recently", "Settings":
                cell.number.isHidden = true
                cell.saveNumber.isHidden = true
            case "Search":
                cell.number.isHidden = true
            case "Memos":
                cell.number.isHidden = false
                cell.number.text = "\(dataManager.memosCD.count)"
            case "Bulletin board":
                cell.number.isHidden = false
                cell.number.text = "\(dataManager.bulletinCD.count)"
            case "Reading list":
                cell.number.isHidden = false
                cell.number.text = "\(dataManager.readingListCD.count)"
            case "Fast folder":
                cell.number.isHidden = false
                cell.number.text = "\(getNumberFastFolderFiles())"
            default:
                cell.number.isHidden = false
                cell.saveNumber.isHidden = false
                cell.number.text = "\(dataManager.localFiles[number].count)"
                cell.saveNumber.text = "\(itemsDisplay)"
            }
            
            if itemsDisplay == 0 {
                cell.saveNumber.isHidden = true
            } else {
                if cell.saveNumber.isHidden == true {
                    cell.saveNumber.isHidden = false
                    cell.saveNumber.grow()
                }
            }
            
            cell.icon.layer.borderWidth = 0
            cell.progressCircle.setProgressWithAnimation(duration: 1.0, value: 1)
            cell.progressCircle.trackClr = UIColor.clear
            cell.progressCircle.progressClr = UIColor.clear
            
            switch orderedCategories[indexPath.row].name {

            case "Recently":
                if navigator.selected.category == "Recently" {
                    cell.icon.image = #imageLiteral(resourceName: "RecentlyIconSelected")
                    cell.progressCircle.progressClr = UIColor.red
                    cell.progressCircle.setProgressWithAnimation(duration: progressCircleTime, value: 1)
                } else {
                    cell.icon.image = #imageLiteral(resourceName: "RecentlyIcon")
                }
                
            case "Publications":
                if navigator.selected.category == "Publications" {
                    cell.icon.image = #imageLiteral(resourceName: "PublicationsIconSelected")
                    cell.progressCircle.progressClr = UIColor.red
                    cell.progressCircle.setProgressWithAnimation(duration: progressCircleTime, value: 1)
                } else {
                    cell.icon.image = #imageLiteral(resourceName: "PublicationsIcon")
                }

            case "Books":
                if navigator.selected.category == "Books" {
                    cell.icon.image = #imageLiteral(resourceName: "BooksIconSelected")
                    cell.progressCircle.progressClr = UIColor.red
                    cell.progressCircle.setProgressWithAnimation(duration: progressCircleTime, value: 1)
                } else {
                    cell.icon.image = #imageLiteral(resourceName: "BooksIcon")
                }
                
            case "Economy":
                if navigator.selected.category == "Economy" {
                    cell.icon.image = #imageLiteral(resourceName: "EconomyIconSelected")
                    cell.progressCircle.progressClr = UIColor.red
                    cell.progressCircle.setProgressWithAnimation(duration: progressCircleTime, value: 1)
                } else {
                    cell.icon.image = #imageLiteral(resourceName: "EconomyIcon")
                }

            case "Manuscripts":
                if navigator.selected.category == "Manuscripts" {
                    cell.icon.image = #imageLiteral(resourceName: "ManuscriptsIcon2Selected")
                    cell.progressCircle.progressClr = UIColor.red
                    cell.progressCircle.setProgressWithAnimation(duration: progressCircleTime, value: 1)
                } else {
                    cell.icon.image = #imageLiteral(resourceName: "ManuscriptsIcon2")
                }

            case "Presentations":
                if navigator.selected.category == "Presentations" {
                    cell.icon.image = #imageLiteral(resourceName: "PresentationsIconSelected")
                    cell.progressCircle.progressClr = UIColor.red
                    cell.progressCircle.setProgressWithAnimation(duration: progressCircleTime, value: 1)
                } else {
                    cell.icon.image = #imageLiteral(resourceName: "PresentationsIcon")
                }

            case "Proposals":
                if navigator.selected.category == "Proposals" {
                    cell.icon.image = #imageLiteral(resourceName: "ProposalsIconSelected")
                    cell.progressCircle.progressClr = UIColor.red
                    cell.progressCircle.setProgressWithAnimation(duration: progressCircleTime, value: 1)
                } else {
                    cell.icon.image = #imageLiteral(resourceName: "ProposalsIcon")
                }
                
            case "Supervision":
                if navigator.selected.category == "Supervision" {
                    cell.icon.image = #imageLiteral(resourceName: "SupervisionIconSelected")
                    cell.progressCircle.progressClr = UIColor.red
                    cell.progressCircle.setProgressWithAnimation(duration: progressCircleTime, value: 1)
                } else {
                    cell.icon.image = #imageLiteral(resourceName: "SupervisionIcon")
                }

            case "Teaching":
                if navigator.selected.category == "Teaching" {
                    cell.icon.image = #imageLiteral(resourceName: "TeachingIconSelected")
                    cell.progressCircle.progressClr = UIColor.red
                    cell.progressCircle.setProgressWithAnimation(duration: progressCircleTime, value: 1)
                } else {
                    cell.icon.image = #imageLiteral(resourceName: "TeachingIcon")
                }
                
            case "Patents":
                if navigator.selected.category == "Patents" {
                    cell.icon.image = #imageLiteral(resourceName: "PatentsIconSelected")
                    cell.progressCircle.progressClr = UIColor.red
                    cell.progressCircle.setProgressWithAnimation(duration: progressCircleTime, value: 1)
                } else {
                    cell.icon.image = #imageLiteral(resourceName: "PatentsIcon")
                }

            case "Courses":
                if navigator.selected.category == "Courses" {
                    cell.icon.image = #imageLiteral(resourceName: "CoursesIconSelected")
                    cell.progressCircle.progressClr = UIColor.red
                    cell.progressCircle.setProgressWithAnimation(duration: progressCircleTime, value: 1)
                } else {
                    cell.icon.image = #imageLiteral(resourceName: "CoursesIcon")
                }

            case "Meetings":
                if navigator.selected.category == "Meeings" {
                    cell.icon.image = #imageLiteral(resourceName: "MeetingsIconSelected")
                    cell.progressCircle.progressClr = UIColor.red
                    cell.progressCircle.setProgressWithAnimation(duration: progressCircleTime, value: 1)
                } else {
                    cell.icon.image = #imageLiteral(resourceName: "MeetingsIcon")
                }
                
            case "Conferences":
                if navigator.selected.category == "Conferences" {
                    cell.icon.image = #imageLiteral(resourceName: "ConferenceIconSelected")
                    cell.progressCircle.progressClr = UIColor.red
                    cell.progressCircle.setProgressWithAnimation(duration: progressCircleTime, value: 1)
                } else {
                    cell.icon.image = #imageLiteral(resourceName: "ConferenceIcon")
                }

            case "Reviews":
                if navigator.selected.category == "Reviews" {
                    cell.icon.image = #imageLiteral(resourceName: "ReviewIconSelected")
                    cell.progressCircle.progressClr = UIColor.red
                    cell.progressCircle.setProgressWithAnimation(duration: progressCircleTime, value: 1)
                } else {
                    cell.icon.image = #imageLiteral(resourceName: "ReviewIcon")
                }

            case "Work documents":
                if navigator.selected.category == "Work documents" {
                    cell.icon.image = #imageLiteral(resourceName: "WorkDocumentIconSelected")
                    cell.progressCircle.progressClr = UIColor.red
                    cell.progressCircle.setProgressWithAnimation(duration: progressCircleTime, value: 1)
                } else {
                    cell.icon.image = #imageLiteral(resourceName: "WorkDocumentIcon")
                }

            case "Travel":
                if navigator.selected.category == "Travel" {
                    cell.icon.image = #imageLiteral(resourceName: "TravelIconSelected")
                    cell.progressCircle.progressClr = UIColor.red
                    cell.progressCircle.setProgressWithAnimation(duration: progressCircleTime, value: 1)
                } else {
                    cell.icon.image = #imageLiteral(resourceName: "TravelIcon")
                }

            case "Notes":
                if navigator.selected.category == "Notes" {
                    cell.icon.image = #imageLiteral(resourceName: "TakeNoteIconSelected")
                    cell.progressCircle.progressClr = UIColor.red
                    cell.progressCircle.setProgressWithAnimation(duration: progressCircleTime, value: 1)
                } else {
                    cell.icon.image = #imageLiteral(resourceName: "TakeNoteIcon")
                }

            case "Miscellaneous":
                if navigator.selected.category == "Miscellaneous" {
                    cell.icon.image = #imageLiteral(resourceName: "MiscellaneousIconSelected")
                    cell.progressCircle.progressClr = UIColor.red
                    cell.progressCircle.setProgressWithAnimation(duration: progressCircleTime, value: 1)
                } else {
                    cell.icon.image = #imageLiteral(resourceName: "MiscellaneousIcon")
                }
                
            case "Memos":
                if navigator.selected.category == "Memos" {
                    cell.icon.image = #imageLiteral(resourceName: "MemoIconSelected")
                    cell.progressCircle.progressClr = UIColor.red
                    cell.progressCircle.setProgressWithAnimation(duration: progressCircleTime, value: 1)
                } else {
                    cell.icon.image = #imageLiteral(resourceName: "MemoIcon")
                }

            case "Settings":
                if navigator.selected.category == "Settings" {
                    cell.icon.image = #imageLiteral(resourceName: "SettingsIconLargeSelected")
                    cell.progressCircle.progressClr = UIColor.red
                    cell.progressCircle.setProgressWithAnimation(duration: progressCircleTime, value: 1)
                } else {
                    cell.icon.image = #imageLiteral(resourceName: "SettingsIconLarge")
                }

            case "Reading list":
                if navigator.selected.category == "Reading list" {
                    cell.icon.image = #imageLiteral(resourceName: "ReadingIconSelected")
                    cell.progressCircle.setProgressWithAnimation(duration: progressCircleTime, value: 1)
                } else {
                    cell.icon.image = #imageLiteral(resourceName: "ReadingIcon")
                }
                
            case "Bulletin board":
                if navigator.selected.category == "Bulletin board" {
                    cell.icon.image = #imageLiteral(resourceName: "BulletinBoardSelected")
                    cell.progressCircle.progressClr = UIColor.red
                    cell.progressCircle.setProgressWithAnimation(duration: progressCircleTime, value: 1)
                } else {
                    cell.icon.image = #imageLiteral(resourceName: "BulletinBoard")
                }
                
            case "Search":
                if navigator.selected.category == "Search" {
                    cell.icon.image = #imageLiteral(resourceName: "SearchLargeIconSelected")
                    cell.progressCircle.progressClr = UIColor.red
                    cell.progressCircle.setProgressWithAnimation(duration: progressCircleTime, value: 1)
                } else {
                    cell.icon.image = #imageLiteral(resourceName: "SearchLargeIcon")
                }
            
            case "Reports":
                if navigator.selected.category == "Reports" {
                    cell.icon.image = #imageLiteral(resourceName: "ReportsIconSelected")
                    cell.progressCircle.progressClr = UIColor.red
                    cell.progressCircle.setProgressWithAnimation(duration: progressCircleTime, value: 1)
                } else {
                    cell.icon.image = #imageLiteral(resourceName: "ReportsIcon")
                }
                
            case "Projects":
                if navigator.selected.category == "Projects" {
                    cell.icon.image = #imageLiteral(resourceName: "ProjectIconSelected")
                    cell.progressCircle.progressClr = UIColor.red
                    cell.progressCircle.setProgressWithAnimation(duration: progressCircleTime, value: 1)
                } else {
                    cell.icon.image = #imageLiteral(resourceName: "ProjectIcon")
                }
                
            case "Fast folder":
                if navigator.selected.category == "Fast folder" {
                    cell.icon.image = #imageLiteral(resourceName: "HotFolderSelected")
                    cell.progressCircle.progressClr = UIColor.red
                    cell.progressCircle.setProgressWithAnimation(duration: progressCircleTime, value: 1)
                } else {
                    cell.icon.image = #imageLiteral(resourceName: "HotFolder")
                }
                
            default:
                print("Default 144")
                cell.icon.image = #imageLiteral(resourceName: "PublicationsIcon")
            }
            
            cell.number.backgroundColor = barColor
            cell.number.textColor = textColor

            return cell
            
        } else if collectionView == self.filesCollectionView || collectionView == self.searchCollectionView {
            
            var cell = collectionView.dequeueReusableCell(withReuseIdentifier: "filesCell", for: indexPath) as! FilesCell

            switch navigator.selected.category {
                
            case "Recently","Reading list", "Bulletin board", "Search", "Fast folder":
                cell = setFilesCell(cell: cell, file: filesCV[indexPath.section][indexPath.row])
                
            case "Publications", "Books":
                cell = setFilesCell(cell: cell, file: filesCV[indexPath.section][indexPath.row])
                
                if editingFilesCV {
                    cell.deleteIcon.isHidden = false
                } else {
                    cell.deleteIcon.isHidden = true
                }

            case "Economy":
                
                if economyStrings[selectedEconomyNumber] == "Invoices" {
                    let number = 0
                    cell = setFilesCell(cell: cell, file: docCV[number].files[indexPath.section][indexPath.row])
                }
                
            default:
                
                cell = setFilesCell(cell: cell, file: docCV[navigator.selected.tableNumber].files[indexPath.section][indexPath.row])
                cell.deleteIcon.isHidden = true
            }

            return cell
            
        } else {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "memoCell", for: indexPath) as! MemoCell
            
            if let currentMemo = dataManager.memosCD.first(where: {$0.id == memosCV[indexPath.row]}) {
                cell.noteText.text = currentMemo.text
                cell.memoTitle.text = currentMemo.title
                cell.id = currentMemo.id
                cell.color = currentMemo.color
                cell.noteButton.tag = indexPath.row
                cell.noteButton.addTarget(self, action: #selector(self.scrollMemo), for: .touchUpInside)
                cell.titleButton.tag = indexPath.row
                cell.titleButton.addTarget(self, action: #selector(self.scrollMemo), for: .touchUpInside)

                switch currentMemo.color {
                case "Yellow":
                    if editingFilesCV {
                        cell.memoImage.image = #imageLiteral(resourceName: "YellowMemoDelete.png")
                    } else {
                        cell.memoImage.image = #imageLiteral(resourceName: "YellowMemo")
                    }
                case "Blue":
                    if editingFilesCV {
                        cell.memoImage.image = #imageLiteral(resourceName: "BlueMemoDelete.png")
                    } else {
                        cell.memoImage.image = #imageLiteral(resourceName: "BlueMemo")
                    }
                case "White":
                    if editingFilesCV {
                        cell.memoImage.image = #imageLiteral(resourceName: "WhiteMemoDelete.png")
                    } else {
                        cell.memoImage.image = #imageLiteral(resourceName: "WhiteMemo")
                    }
                case "Red":
                    if editingFilesCV {
                        cell.memoImage.image = #imageLiteral(resourceName: "RedMemoDelete.png")
                    } else {
                        cell.memoImage.image = #imageLiteral(resourceName: "RedMemo")
                    }
                case "Green":
                    if editingFilesCV {
                        cell.memoImage.image = #imageLiteral(resourceName: "GreenMemoDelete")
                    } else {
                        cell.memoImage.image = #imageLiteral(resourceName: "GreenMemo")
                    }
                default:
                    if editingFilesCV {
                        cell.memoImage.image = #imageLiteral(resourceName: "YellowMemoDelete.png")
                    } else {
                        cell.memoImage.image = #imageLiteral(resourceName: "YellowMemo.png")
                    }
                }
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView == self.categoriesCV {
            
            if navigator.selected.category == "Memos" {
                saveAndUpdateMemos()
            }
            
            let number = categories.index(where: { $0 == orderedCategories[indexPath.row].name! })
            navigator.selected = SelectedFolder(category: orderedCategories[indexPath.row].name!, categoryNumber: number, mainFolderNumber: 0, subFolderNumber: 0, filename: nil, folderLevel: 0, tableNumber: 0)
            selectedCategoryTitle.text = "  " + navigator.selected.category
            
            downloadToLocalFileBUtton.image = #imageLiteral(resourceName: "DownloadPDF.png")

            hideAndDisableAll(views: true, buttons: true)
            
            dataManager.searchString = ""
            searchBar.text = ""

            //READ FILES IN CATEGORY
            let info = ProcessInfo.processInfo
            let begin = info.systemUptime
            if dataManager.localFiles[number!].count == 0 {
                dataManager.readCategory(category: navigator.selected.category)
            }
            let diff = (info.systemUptime - begin)

            if navigator.selected.category != "Search" {
                //Reset search and dismiss keyboard
                self.searchHidden = true
                self.dataManager.isSearching = false
                self.searchBar.isHidden = searchHidden
                self.dataManager.isSearching = !searchHidden
                dismissKeyboard()
            }
            
            switch navigator.selected.category {
            case "Recently":
                self.listTableView.isHidden = false
                self.filesCollectionView.isHidden = false

            case "Teaching":
                self.optionsSegment.replaceSegments(segments: filelistOptions)
                self.listTableView.isHidden = false
                self.filesCollectionView.isHidden = false
                self.sortCVButton.isEnabled = true
                self.optionsSegment.isHidden = false
                self.addNew.image = #imageLiteral(resourceName: "exam")
                self.addNew.isEnabled = true
                optionsSegment.selectedSegmentIndex = 0

            case "Publications":
                self.listTableView.isHidden = false
                self.optionsSegment.replaceSegments(segments: sortSubtableStrings)
                self.optionsSegment.isHidden = false
                optionsSegment.selectedSegmentIndex = selectedSortingNumber
                
                if optionsSegment.selectedSegmentIndex > 4 || optionsSegment.selectedSegmentIndex < 0 {
                    optionsSegment.selectedSegmentIndex = 0
                    selectedSortingNumber = 0
                }
                
                if selectedLocalFile != nil && selectedLocalFile.category == "Publications" {
                    self.notesButton.isEnabled = true
                }

                self.filesCollectionView.isHidden = false
                self.addNew.isEnabled = true
                self.addNew.image = #imageLiteral(resourceName: "Add")
                self.sortCVButton.isEnabled = true
                if sortSubtableStrings[selectedSortingNumber] == "Tag" {
                    self.editButton.isEnabled = true
                } else {
                    self.editButton.isEnabled = false
                }
                self.optionsSegment.isHidden = false
                self.searchButton.isEnabled = true

            case "Books":
                self.listTableView.isHidden = false
                self.filesCollectionView.isHidden = false
                self.sortCVButton.isEnabled = true
                self.editButton.isEnabled = true
                self.addNew.isEnabled = true
                self.addNew.image = #imageLiteral(resourceName: "Add")
                self.searchButton.isEnabled = true
                
            case "Economy":
                self.listTableView.isHidden = false
                optionsSegment.replaceSegments(segments: economyStrings)
                self.optionsSegment.isHidden = false
                optionsSegment.selectedSegmentIndex = selectedEconomyNumber
                if optionsSegment.selectedSegmentIndex > 2 || optionsSegment.selectedSegmentIndex < 0 {
                    optionsSegment.selectedSegmentIndex = 0
                    selectedEconomyNumber = 0
                }
                self.addNew.isEnabled = true
                self.addNew.image = #imageLiteral(resourceName: "Add")
                self.optionsSegment.isHidden = false
                self.expensesTableView.isHidden = false
                
                if economyStrings[selectedEconomyNumber] == "Projects" {
                    self.economyView.isHidden = false
                    self.scholarView.isHidden = true
                    self.filesCollectionView.isHidden = true
                } else if economyStrings[selectedEconomyNumber] == "Invoices" {
                    self.economyView.isHidden = true
                    self.scholarView.isHidden = true
                    self.filesCollectionView.isHidden = false
                } else if economyStrings[selectedEconomyNumber] == "Grants" {
                    self.economyView.isHidden = true
                    self.scholarView.isHidden = false
                    self.filesCollectionView.isHidden = true
                }
                
            case "Notes":
                self.listTableView.isHidden = false
                self.filesCollectionView.isHidden = false
                self.sortCVButton.isEnabled = true
                self.addNew.isEnabled = true
                self.addNew.image = #imageLiteral(resourceName: "Add")
                
            case "Work documents":
                
                optionsSegment.replaceSegments(segments: workDocStrings)
                optionsSegment.selectedSegmentIndex = selectedWorkDocNumber
                
                self.optionsSegment.isHidden = false
                if optionsSegment.selectedSegmentIndex > 1 || optionsSegment.selectedSegmentIndex < 0 {
                    optionsSegment.selectedSegmentIndex = 0
                    selectedWorkDocNumber = 0
                }
                
                if workDocStrings[selectedWorkDocNumber] == "Files" {
                    self.applicantView.isHidden = true
                    self.filesCollectionView.isHidden = false
                    self.addToBulletinButton.isEnabled = true
                } else if workDocStrings[selectedWorkDocNumber] == "Hiring" {
                    self.applicantView.isHidden = false
                    self.filesCollectionView.isHidden = true
                    self.addToBulletinButton.isEnabled = false
                }

                self.listTableView.isHidden = false
                self.sortCVButton.isEnabled = false
                self.editButton.isEnabled = false
                
            case "Memos":
                self.listTableView.isHidden = false
                self.memosCollectionView.isHidden = false
                self.editButton.isEnabled = true
                self.addNew.isEnabled = true
                self.addNew.image = #imageLiteral(resourceName: "Add")

            case "Settings":
                self.settingsView.isHidden = false
                self.dateFormatter.dateFormat = "yyyy-MM-dd : HH:mm"
                if self.uploadDate != nil {
                    self.lastUploadLabel.text = "Last uploaded: " + self.dateFormatter.string(from: self.uploadDate!)
                } else {
                    self.lastUploadLabel.text = "No completed upload"
                }

            case "Bulletin board":
                self.listTableView.isHidden = false
                self.filesCollectionView.isHidden = false
                self.sortCVButton.isEnabled = true
                self.editButton.isEnabled = true
                self.addNew.isEnabled = true
                self.addNew.image = #imageLiteral(resourceName: "Add")
                
            case "Fast folder":
                dataManager.readFastFolder()
                self.sortCVButton.isEnabled = true
                self.editButton.isEnabled = false
                self.addNew.isEnabled = false
                self.listTableView.isHidden = false
                self.filesCollectionView.isHidden = false
                self.searchCollectionView.isHidden = true

            case "Search":
                self.searchCollectionView.isHidden = false
                self.searchButton.isEnabled = true
                
                // Enable search bar
                searchHidden = false
                searchBar.isHidden = false
                dataManager.isSearching = true
                dataManager.searchString = ""
                searchBar.text = ""
                searchBar.becomeFirstResponder()
                
            default:
                self.listTableView.isHidden = false
                self.filesCollectionView.isHidden = false
                self.sortCVButton.isEnabled = true
            }
            
            initiateDimmer()

            categoriesCV.reloadData() //Needed to show currently selected

            if navigator.selected.category != "Search" {
                populateListTable()
                populateFilesCV()
                sortFiles()
                
                listTableView.reloadData()
                filesCollectionView.reloadData()
            } else {
                populateFilesCV()
                searchCollectionView.reloadData()
            }
            
            if navigator.selected.category != "Memos" && navigator.selected.category != "Settings" && navigator.selected.category != "Reading list" && navigator.selected.category != "Bulletin board" && navigator.selected.category != "Fast folder"{
                if dataManager.localFiles[number!].count > 0 {
                    if self.filesCollectionView.numberOfSections > 0 {
                        self.filesCollectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                        scrollToSection(0)
                    }
                }
            } else if navigator.selected.category == "Memos" {
                memosCollectionView.reloadData()
            }
            
            dataManager.economyOption = optionsSegment.selectedSegmentIndex
            dataManager.updateCategoriesOrder(category: categories[navigator.selected.categoryNumber])
            updateCategoriesOrder()
            
        } else if collectionView == self.filesCollectionView || collectionView == self.searchCollectionView {
            
            hideAndDisableAll(views: false, buttons: true)
            
            switch categories[navigator.selected.categoryNumber] {
            case "Recently":
                selectedLocalFile = filesCV[indexPath.section][indexPath.row]
                addToBulletinButton.isEnabled = true
            
            case "Search":
                selectedLocalFile = filesCV[indexPath.section][indexPath.row]
                addToBulletinButton.isEnabled = true
                favoriteButton.isEnabled = true
                
            case "Reading list":
                selectedLocalFile = filesCV[indexPath.section][indexPath.row]
                readingListBUtton.isEnabled = true
                addToBulletinButton.isEnabled = true

            case "Bulletin board":
                selectedLocalFile = filesCV[indexPath.section][indexPath.row]
                notesButton.isEnabled = true
                editButton.isEnabled = true
                addToBulletinButton.isEnabled = true
                sortCVButton.isEnabled = true
                readingListBUtton.isEnabled = true
                addNew.isEnabled = true
                addNew.image = #imageLiteral(resourceName: "Add")
                
            case "Publications":
                selectedLocalFile = filesCV[indexPath.section][indexPath.row]
                notesButton.isEnabled = true
                optionsSegment.isHidden = false
                searchButton.isEnabled = true
                addToBulletinButton.isEnabled = true
                addNew.isEnabled = true
                addNew.image = #imageLiteral(resourceName: "Add")
                favoriteButton.isEnabled = true
                sortCVButton.isEnabled = true

            case "Books":
                selectedLocalFile = filesCV[indexPath.section][indexPath.row]
                searchButton.isEnabled = true
                addToBulletinButton.isEnabled = true
                addNew.isEnabled = true
                addNew.image = #imageLiteral(resourceName: "Add")
                favoriteButton.isEnabled = true
                sortCVButton.isEnabled = true
                
            case "Economy":
                selectedLocalFile = docCV[0].files[indexPath.section][indexPath.row]
                
            case "Teaching":
                optionsSegment.isHidden = false
                selectedLocalFile = docCV[navigator.selected.tableNumber].files[indexPath.section][indexPath.row]
                searchButton.isEnabled = true
                addToBulletinButton.isEnabled = true
                sortCVButton.isEnabled = true
                
            case "Fast folder":
                optionsSegment.isHidden = true
                selectedLocalFile = filesCV[indexPath.section][indexPath.row]
                searchButton.isEnabled = false
                addToBulletinButton.isEnabled = true
                sortCVButton.isEnabled = true
                
            default:
                selectedLocalFile = docCV[navigator.selected.tableNumber].files[indexPath.section][indexPath.row]
                
                searchButton.isEnabled = true
                addToBulletinButton.isEnabled = true
            }
            
            if dataManager.favoritesCD.first(where: {$0.path == selectedLocalFile.path}) != nil {
                favoriteButton.image = #imageLiteral(resourceName: "star-filled")
                favoriteButton.tintColor = UIColor.red
            } else {
                favoriteButton.image = #imageLiteral(resourceName: "star.png")
                favoriteButton.tintColor = UIColor.white
            }

            if dataManager.readingListCD.first(where: {$0.path == selectedLocalFile.path}) != nil {
                readingListBUtton.image = #imageLiteral(resourceName: "glasses-filled")
                readingListBUtton.tintColor = UIColor.red
            } else {
                readingListBUtton.image = #imageLiteral(resourceName: "glasses")
                readingListBUtton.tintColor = UIColor.white
            }

            if let currentBookmark = dataManager.getBookmark(file: selectedLocalFile) {
                if (currentBookmark.page?.count)! > 0 {
                    bookmarksButton.isEnabled = true
                } else {
                    bookmarksButton.isEnabled = false
                }
            } else {
                bookmarksButton.isEnabled = false
            }
            goToPage = nil
            
            favoriteButton.isEnabled = true
            readingListBUtton.isEnabled = true
            
            if selectedLocalFile.downloaded {
                downloadToLocalFileBUtton.image = #imageLiteral(resourceName: "HDD-filled")
                downloadToLocalFileBUtton.isEnabled = true
                if categories[navigator.selected.categoryNumber] == "Publications" {
                    notesButton.isEnabled = true
                } else {
                    notesButton.isEnabled = false
                }
            } else {
                downloadToLocalFileBUtton.image = #imageLiteral(resourceName: "DownloadPDF.png")
                downloadToLocalFileBUtton.isEnabled = selectedLocalFile.available
                if categories[navigator.selected.categoryNumber] == "Publications" {
                    notesButton.isEnabled = selectedLocalFile.available
                } else {
                    notesButton.isEnabled = false
                }
            }
            
            if categories[navigator.selected.categoryNumber] == "Recently" {
                downloadToLocalFileBUtton.isEnabled = false
            }
            currentSelectedFilename = selectedLocalFile.filename
            
            // Remove PDF from group.
            if categories[navigator.selected.categoryNumber] == "Publications" && editingFilesCV {
                
                if navigator.list.main[indexPath.section] != "All publications" {
                    dataManager.removeFromGroup(file: selectedLocalFile, group: navigator.list.main[indexPath.section])
                }
                
                populateListTable()
                populateFilesCV()
                sortFiles()
                
                listTableView.reloadData()
                filesCollectionView.reloadData()
                
            } else if categories[navigator.selected.categoryNumber] == "Books" && editingFilesCV {
                
                switch navigator.list.main[indexPath.section] {
                case "All books", "Favorites", "Recently added/modified":
                    print("Default 141")
                default: dataManager.removeFromGroup(file: selectedLocalFile, group: navigator.list.main[indexPath.section])
                }
                
                populateListTable()
                populateFilesCV()
                sortFiles()
                
                listTableView.reloadData()
                filesCollectionView.reloadData()
                
            } else if categories[navigator.selected.categoryNumber] == "Bulletin board" && editingFilesCV {
                
                let currentBoard = navigator.list.main[indexPath.section]
                dataManager.removeFromBulletin(file: selectedLocalFile, bulletin: currentBoard)
                
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
                        
                        let number = categories.index(where: { $0 == selectedLocalFile.category })
                        
                        let newDownload = DownloadingFile(filename: selectedLocalFile.filename, url: fileURL, downloaded: false, path: filePath, category: number!)
                        filesDownloading.append(newDownload)
                        downloadTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(checkIfFileIsDownloaded), userInfo: nil, repeats: true)
                        selectedLocalFile.downloading = true
                        
                        switch categories[navigator.selected.categoryNumber] {
                        case "Publications", "Books", "Recently", "Search", "Fast folder":
                            filesCV[indexPath.section][indexPath.row].downloading = true
                        default:
                            docCV[navigator.selected.tableNumber].files[indexPath.section][indexPath.row].downloading = true
                        }
                        // Vad gör nedan?
//                        dataManager.replaceLocalFileWithNew(newFile: selectedLocalFile)
                        
                        // Update categories CV to display number of downloading files
                        NotificationCenter.default.post(name: Notification.Name.updateView, object: nil)
                    } catch let error {
                        print(error)
                    }
                }

                if collectionView == self.filesCollectionView {
                    filesCollectionView.reloadData() //Needed to show currently selected file
                } else {
                    searchCollectionView.reloadData() //Needed to show currently selected file
                }
                
            }
            
        } else {
            let currentCell = collectionView.cellForItem(at: indexPath) as! MemoCell
            currentSelectedMemo = currentCell
            
            if editingFilesCV {
                dataManager.deleteMemo(id: currentCell.id)
                populateFilesCV()
                memosCollectionView.reloadData()
            }
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        
        var item: String = ""
        if categories[navigator.selected.categoryNumber] == "Publications" || categories[navigator.selected.categoryNumber] == "Books" {
            navigator.selected.tableNumber = indexPath.section
//            selectedSubtableNumber = indexPath.section
//            dataManager.selectedSubtableNumber = indexPath.section
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

        switch categories[navigator.selected.categoryNumber] {
        case "Recently", "Publications", "Books", "Reading list", "Bulletin board":
            sectionHeaderView.mainHeaderTitle.text = navigator.list.main[indexPath[0]]
            if filesCV[indexPath[0]].count == 1 {
                sectionHeaderView.subHeaderTitle.text = "\(filesCV[indexPath[0]].count)" + " item"
            } else {
                sectionHeaderView.subHeaderTitle.text = "\(filesCV[indexPath[0]].count)" + " items"
            }
            
        case "Fast folder":
            sectionHeaderView.mainHeaderTitle.text = navigator.list.main[indexPath[0]]
            
        case "Economy":
            if economyStrings[selectedEconomyNumber] == "Invoices" {
                sectionHeaderView.mainHeaderTitle.text = docCV[navigator.selected.tableNumber].sectionHeader[indexPath.section]
                if docCV[navigator.selected.tableNumber].files[indexPath.section].count == 1 {
                    sectionHeaderView.subHeaderTitle.text = "\(docCV[navigator.selected.tableNumber].files[indexPath.section].count)" + " item"
                } else {
                    sectionHeaderView.subHeaderTitle.text = "\(docCV[navigator.selected.tableNumber].files[indexPath.section].count)" + " items"
                }
            }
            
        case "Search":
            sectionHeaderView.mainHeaderTitle.text = dataManager.fullSearch[indexPath.section].title
            
        default:
            sectionHeaderView.mainHeaderTitle.text = docCV[navigator.selected.tableNumber].sectionHeader[indexPath.section]
            if docCV[navigator.selected.tableNumber].files[indexPath.section].count == 1 {
                sectionHeaderView.subHeaderTitle.text = "\(docCV[navigator.selected.tableNumber].files[indexPath.section].count)" + " item"
            } else {
                sectionHeaderView.subHeaderTitle.text = "\(docCV[navigator.selected.tableNumber].files[indexPath.section].count)" + " items"
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

    
    
    
    override func prefersHomeIndicatorAutoHidden() -> Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.progressMonitor.removeFromSuperview()
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.setupProgressMonitor()
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

}


extension ViewController: ExpenseCellDelegate {
    func didTapPDF(item: Expense) {
        NotificationCenter.default.post(name: Notification.Name.sendPDFfilename, object: self)
        if (item.pdfURL?.absoluteURL.isFileURL)! {
            
            // FIX: ADD FUNCTIONALITY SO THESE CAN BE VIEWED AS WELL
//            performSegue(withIdentifier: "seguePDFViewController", sender: self)
        } else {
            do {
                try fileManagerDefault.startDownloadingUbiquitousItem(at: item.pdfURL!.absoluteURL)
                sendNotification(text: "Downloading " + item.pdfURL!.absoluteString)
            } catch let error {
                print(error)
            }
        }
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

@IBDesignable public class Gradient: UIView {
    @IBInspectable var startColor:   UIColor = .black { didSet { updateColors() }}
    @IBInspectable var endColor:     UIColor = .white { didSet { updateColors() }}
    @IBInspectable var startLocation: Double =   0.05 { didSet { updateLocations() }}
    @IBInspectable var endLocation:   Double =   0.95 { didSet { updateLocations() }}
    @IBInspectable var horizontalMode:  Bool =  false { didSet { updatePoints() }}
    @IBInspectable var diagonalMode:    Bool =  false { didSet { updatePoints() }}

    override public class var layerClass: AnyClass { CAGradientLayer.self }

    var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }

    func updatePoints() {
        if horizontalMode {
            gradientLayer.startPoint = diagonalMode ? .init(x: 1, y: 0) : .init(x: 0, y: 0.5)
            gradientLayer.endPoint   = diagonalMode ? .init(x: 0, y: 1) : .init(x: 1, y: 0.5)
        } else {
            gradientLayer.startPoint = diagonalMode ? .init(x: 0, y: 0) : .init(x: 0.5, y: 0)
            gradientLayer.endPoint   = diagonalMode ? .init(x: 1, y: 1) : .init(x: 0.5, y: 1)
        }
    }
    func updateLocations() {
        gradientLayer.locations = [startLocation as NSNumber, endLocation as NSNumber]
    }
    func updateColors() {
        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
    }
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updatePoints()
        updateLocations()
        updateColors()
    }

}
