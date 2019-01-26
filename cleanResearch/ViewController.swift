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




class ViewController: UIViewController, UIPopoverPresentationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDataSource, UITableViewDelegate, UICollectionViewDragDelegate, UICollectionViewDropDelegate, UITableViewDropDelegate, QLPreviewControllerDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate {
    

    // MARK: - Variables
    var appDelegate: AppDelegate!
    let container = CKContainer.default
    let previewController = QLPreviewController()
    
    // MARK: - Core data
    var context: NSManagedObjectContext!
    
    var currentIndexPath: IndexPath = IndexPath(row: 0, section: 0)
    
    // MARK: - iCloud variables
//    var iCloudURL: URL!
    var kvStorage: NSUbiquitousKeyValueStore!
    var icloudAvailable: Bool? = nil
    var icloudFileURL: URL!
    var iCloudSynd = true
    var scanForFiles = false
    
    //MARK: - Custom classes/structs
    let fileHandler = FileHandler()
    var dataManager: DataManager!
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
    var notesBox = CGSize(width: 260, height: 300)
    var editingFilesCV = false
    var currentSelectedFilename: String? = nil
    var selectedInvoice: String? = nil
    var currentExpense: Expense!
    var currentProject: Project!
    
    var sortTableListBox = CGSize(width: 348, height: 28)
    var sortCVBox = CGSize(width: 219, height: 28)
    var systemInfoBox = CGSize(width: 300, height: 50)
    var selectedCategoryNumber = 0
    var selectedCategory: String!
    var selectedApplicant = 0

    var filesCV: [[LocalFile]] = [[]] //Place files to be displayed in collection view here (ONLY PUBLICATIONS!)
    var docCV: [DocCV] = []
    let sortSubtableStrings = ["Tag", "Author", "Journal", "Year", "Rank"] //Only for publications
    let sortCVStrings: [String] = ["Filename", "Date"]
    let recentStrings = ["Last hour", "Last 8 hours", "Last day", "Last 2 days", "Last week", "Last month", "Favorites"]
    let economyStrings = ["Projects", "Invoices", "Grants"]
    let workDocStrings = ["Files", "Hiring"]
    
    var selectedSubtableNumber = 0
    var selectedSortingNumber = 0
    var selectedSortingCVNumber = 0
    var selectedFile: [SelectedFile] = []
    var selectedLocalFile: LocalFile!
    var previewFile: LocalFile!
    var sortTableTitles: [String] = [""]
    var applicantTableTitles: [String] = [""]
    var sectionTitles: [[String]] = [[""]]

    var yearsString: [String] = [""]
    
    var dateFormatter = DateFormatter()
    
    var PDFdocument: PDFDocument!
    var PDFfilename: String!
    var PDFPath: String?
    var annotationSettings: [Int] = [0, 0, 0, 0, 50, 0, 0, 0, 0]
    var orderedCategories: [Categories]!
    
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
    
    var recentDays: Int!
    
    // MARK: - Outlets
    @IBOutlet var mainView: UIView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var economyView: UIView!
    @IBOutlet weak var mainHeader: UILabel!
    @IBOutlet weak var scholarView: UIView!
    @IBOutlet weak var applicantView: UIView!
    @IBOutlet weak var applicantTableList: UITableView!
    @IBOutlet weak var listTableView: UITableView!
    @IBOutlet weak var filesCollectionView: UICollectionView!
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
    
    
    // MARK: - IBActions
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

        dataManager.option = optionsSegment.selectedSegmentIndex
        
        print(categories[selectedCategoryNumber])
        
        if categories[selectedCategoryNumber] == "Publications" {
            
            selectedSortingNumber = optionsSegment.selectedSegmentIndex
            
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
            
        } else if categories[selectedCategoryNumber] == "Economy" {
            
            if economyStrings[optionsSegment.selectedSegmentIndex] == "Projects" {
                self.economyView.isHidden = false
                self.filesCollectionView.isHidden = true
                self.scholarView.isHidden = true
            } else if economyStrings[optionsSegment.selectedSegmentIndex] == "Invoices" {
                self.economyView.isHidden = true
                self.filesCollectionView.isHidden = false
                self.filesCollectionView.reloadData()
                self.scholarView.isHidden = true
            } else if economyStrings[optionsSegment.selectedSegmentIndex] == "Grants" {
                self.scholarView.isHidden = false
                self.economyView.isHidden = true
                self.filesCollectionView.isHidden = true
            }
            self.populateListTable()
            self.populateFilesCV()
            self.listTableView.reloadData()
            
        }  else if categories[selectedCategoryNumber] == "Work documents" {
            
            print(workDocStrings[optionsSegment.selectedSegmentIndex])
            
            if workDocStrings[optionsSegment.selectedSegmentIndex] == "Files" {
                self.applicantView.isHidden = true
                self.filesCollectionView.isHidden = false
                
            } else if workDocStrings[optionsSegment.selectedSegmentIndex] == "Hiring" {
                
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
        
        print(path)
        
        if dataManager.favoritesCD.first(where: {$0.path == path}) != nil {
            favoriteButton.image = #imageLiteral(resourceName: "star-filled")
            favoriteButton.tintColor = UIColor.red
        } else {
            favoriteButton.image = #imageLiteral(resourceName: "star")
            favoriteButton.tintColor = UIColor.white
        }

        dataManager.addOrRemoveFileFromFavorite(file: selectedLocalFile)
        
        if dataManager.favoritesCD.first(where: {$0.path == selectedLocalFile.path}) != nil {
            favoriteButton.image = #imageLiteral(resourceName: "star-filled")
            favoriteButton.tintColor = UIColor.red
        } else {
            favoriteButton.image = #imageLiteral(resourceName: "star.png")
            favoriteButton.tintColor = UIColor.white
        }
        
//
//
//        selectedLocalFile = dataManager.addOrRemoveFromFavorite(file: selectedLocalFile) // ONLY BOOKS AND PUBLICATIONS
//        dataManager.replaceLocalFileWithNew(newFile: selectedLocalFile)
//        dataManager.updateIcloud(file: selectedLocalFile, oldFilename: nil, newFilename: nil, expense: nil, project: nil, type: categories[selectedCategoryNumber], bookmark: nil, fund: nil)
        
        populateListTable()
        populateFilesCV()
        sortFiles()
        listTableView.reloadData()
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
        
        switch selectedCategory {
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
            
            if economyStrings[optionsSegment.selectedSegmentIndex] == "Projects" {
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
                    
                    self.categoriesCV.selectItem(at: IndexPath(row: self.selectedCategoryNumber, section: 0), animated: true, scrollPosition: .top)
                }))
                inputNewProject.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                    inputNewProject.dismiss(animated: true, completion: nil)
                }))
                self.present(inputNewProject, animated: true, completion: nil)
                
            } else if economyStrings[optionsSegment.selectedSegmentIndex] == "Grants" {
                
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
                    self.populateFilesCV()
                    self.sortFiles()
                    
                    self.categoriesCV.reloadData()
                    self.listTableView.reloadData()
                    self.filesCollectionView.reloadData()
                    
                    self.categoriesCV.selectItem(at: IndexPath(row: self.selectedCategoryNumber, section: 0), animated: true, scrollPosition: .top)
                }))
                inputNewFund.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                    inputNewFund.dismiss(animated: true, completion: nil)
                }))
                self.present(inputNewFund, animated: true, completion: nil)
            }
            
        case "Notes":

            let filename = dataManager.createBlankPDF(category: "Notes")
            let number = categories.index(where: { $0 == selectedCategory })
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
            
        default:
            print("110")
        }
    }
    
    @IBAction func editIconTapped(_ sender: Any) {
        editingFilesCV = !editingFilesCV
        filesCollectionView.reloadData()
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
        }
    }
    
    @IBAction func saveFundingOrganisation(_ sender: Any) {
        let currentOrganisation = dataManager.fundCD[selectedSubtableNumber]
        currentOrganisation.amount = Int64(isStringAnInt(stringNumber: amountFunding.text))
        currentOrganisation.currency = currencyFunding.text
        currentOrganisation.deadline = organisationDeadline.date
        currentOrganisation.instructions = organisationInstructions.text
        currentOrganisation.website = internetAddressOrganisation.text
        
        dataManager.updateCoreDataFund(fund: currentOrganisation)
//        dataManager.updateIcloud(file: nil, oldFilename: nil, newFilename: nil, expense: nil, project: nil, type: "Fund", bookmark: nil, fund: currentOrganisation)
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
    
    
    
    
    
    // MARK: - ViewDidLoad
    override func viewDidLoad() {
        print("viewDidLoad - Main")
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

        selectedCategory = categories[0]
//        updateCategoriesOrder()
        
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
        self.applicantTableList.dataSource = self
        self.applicantTableList.delegate = self
        
        self.previewController.dataSource = self
        
        self.docsURL = self.appDelegate.docsDir
        
        searchBar.delegate = self
        
        mainVC = self
        
        self.navigationController?.isNavigationBarHidden = false
        self.navigationItem.hidesBackButton = true
        navigationController?.navigationBar.barTintColor = UIColor.black
        
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
//        listTableView.backgroundColor = backgroundColor
        listTableView.tintColor = textColor
        applicantHeader.backgroundColor = barColor
        listTableView.backgroundColor = UIColor.clear
        applicantTableList.backgroundColor = UIColor.clear
        
        self.setupUI()
        setNeedsStatusBarAppearanceUpdate()
        
        searchForFilesTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(checkForNewFiles), userInfo: nil, repeats: true)
        if !scanForFiles {
            searchForFilesTimer.invalidate()
        }
        
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
                        if categories[filesDownloading[i].category] == "Publications" || categories[filesDownloading[i].category] == "Books" || categories[filesDownloading[i].category] == "Recently" {
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

    @objc func doubleTapped(gesture: UITapGestureRecognizer) {
        print("doubleTapped")
        
        let pointInCollectionView = gesture.location(in: self.filesCollectionView)
        if let indexPath = self.filesCollectionView.indexPathForItem(at: pointInCollectionView) {
            switch selectedCategory {

            case "Recently":

                selectedLocalFile = filesCV[indexPath.section][indexPath.row]

                if selectedLocalFile.iCloudURL.lastPathComponent.range(of: ".pdf") != nil {
                    selectedLocalFile = filesCV[indexPath.section][indexPath.row]
                    
                    if selectedLocalFile.downloaded {
                        PDFdocument = PDFDocument(url: selectedLocalFile.localURL)
                    } else {
                        PDFdocument = PDFDocument(url: selectedLocalFile.iCloudURL)
                    }
                    
                    performSegue(withIdentifier: "seguePDFViewController", sender: self)
                } else {
                    previewFile = selectedLocalFile
                    previewController.reloadData()
                    navigationController?.pushViewController(previewController, animated: true)
                }
                
            case "Publications":
                selectedLocalFile = filesCV[indexPath.section][indexPath.row]
                
                if selectedLocalFile.downloaded {
                    PDFdocument = PDFDocument(url: selectedLocalFile.localURL)
                } else {
                    PDFdocument = PDFDocument(url: selectedLocalFile.iCloudURL)
                }
                
                if let currentPublication = dataManager.publicationsCD.first(where: {$0.filename == selectedLocalFile.filename}) {
                    print("Publications already saved to CD")
                } else {
                    dataManager.addFileToCoreData(file: selectedLocalFile)
                }
                
                performSegue(withIdentifier: "seguePDFViewController", sender: self)
                
            case "Books":
                selectedLocalFile = filesCV[indexPath.section][indexPath.row]
                
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
                    dataManager.addFileToRecent(file: selectedLocalFile)
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
        recentDays = settingsVC.recentDays
        if settingsVC.scanForNewFiles.isOn {
            if !searchForFilesTimer.isValid {
                searchForFilesTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(checkForNewFiles), userInfo: nil, repeats: true)
            }
        } else {
            searchForFilesTimer.invalidate()
        }
        
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
        
        setupProgressMonitor()
        
        self.navigationController?.isNavigationBarHidden = false
        self.navigationItem.hidesBackButton = true
        self.navigationController?.navigationBar.barTintColor = UIColor.black
        self.navigationController?.navigationBar.backgroundColor = UIColor.black
        self.navigationController?.navigationBar.tintColor = UIColor.white
        
        let vc = notification.object as! PDFViewController
        annotationSettings = vc.annotationSettings!
        
        progressMonitor = vc.progressMonitor
        dataManager.progressMonitor = vc.progressMonitor
        
        self.view.addSubview(self.progressMonitor)
        progressMonitor.superview?.bringSubview(toFront: progressMonitor)
        
        kvStorage.set(annotationSettings, forKey: "annotationSettings")
        kvStorage.synchronize()
        
        if vc.needsUploading {
            dataManager.savePDF(file: vc.currentFile, document: vc.document)
        }
        
        if let number = categories.index(where: { $0 == vc.currentFile.category }) {
            
            dataManager.addFileToRecent(file: vc.currentFile)
            
            if let index = dataManager.localFiles[number].index(where: {$0.filename == vc.PDFfilename}) {
                dataManager.localFiles[number][index].dateModified = Date()
                dataManager.localFiles[number][index].thumbnail = vc.document.page(at: 0)!.thumbnail(of: CGSize(width: 210, height: 297), for: .artBox)

                dataManager.saveBookmark(file: dataManager.localFiles[number][index], bookmark: vc.bookmarks)
                
                if categories[number] == "Publications" || categories[number] == "Books" {
                    dataManager.updateIcloud(file: dataManager.localFiles[number][index], oldFilename: nil, newFilename: nil, expense: nil, project: nil, type: categories[number], bookmark: nil, fund: nil)
                    dataManager.updateCoreData(file: dataManager.localFiles[number][index], oldFilename: nil, newFilename: nil)
                }
                
            } else {
                print("Not uploaded to iCloud")
                print(iCloudSynd)
            }
        } else { //E.G "HIRING" HAS NO INDEX
            
        }
        
        categoriesCV.reloadData()
        populateListTable()
        populateFilesCV()
        sortFiles()
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
            
            let number = categories.index(where: { $0 == categories[selectedCategoryNumber] })
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
    
    @objc func handleLongPress(gesture : UILongPressGestureRecognizer!) {
        
        let point = gesture.location(in: self.categoriesCV)
        
        if let indexPath = self.categoriesCV.indexPathForItem(at: point) {
            
            selectedCategoryNumber = categories.index(where: { $0 == orderedCategories[indexPath.row].name! })!
            
            sendNotification(text: "Reloading " + orderedCategories[indexPath.row].name! + " folder")

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
            print("postNotification")
            print(self.view.subviews.count)
            self.progressMonitor.isHidden = false
            self.view.addSubview(self.progressMonitor)
            self.view.bringSubview(toFront: self.progressMonitor)
            self.progressMonitor.launchMonitor(displayText: nil)
            print(self.view.subviews.count)
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
        print("sendNotification - VC")
        print(self.view.subviews.count)
        self.progressMonitor.isHidden = false
        self.view.addSubview(self.progressMonitor)
//            self.progressMonitor.bringSubview(toFront: self.view)
        self.view.bringSubview(toFront: self.progressMonitor)
        self.progressMonitor.launchMonitor(displayText: text)
        print(self.view.subviews.count)
    }
    
    @objc func updateView() {
        print("updateView")
        DispatchQueue.main.async {
            self.categoriesCV.reloadData()
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
    
    func getRecentDates() -> [Date] {
        var dateComponents = DateComponents()

        dateComponents.day = 0
        dateComponents.hour = -1
        let lastHour = Calendar.current.date(byAdding: dateComponents, to: Date())

        dateComponents.hour = -8
        let last8Hours = Calendar.current.date(byAdding: dateComponents, to: Date())

        dateComponents.hour = -24
        let lastDay = Calendar.current.date(byAdding: dateComponents, to: Date())

        dateComponents.hour = -48
        let last48Hours = Calendar.current.date(byAdding: dateComponents, to: Date())

        dateComponents.hour = 0
        dateComponents.day = -7
        let lastWeek = Calendar.current.date(byAdding: dateComponents, to: Date())

        dateComponents.day = -30
        let lastMonth = Calendar.current.date(byAdding: dateComponents, to: Date())

        return [lastHour!, last8Hours!, lastDay!, last48Hours!, lastWeek!, lastMonth!]

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
        
        if let days = kvStorage.object(forKey: "recentDays") as? Int {
            recentDays = days
        } else {
            recentDays = 7
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
    
    func openHiringFile(type: String) {
        
        let name = applicantTableTitles[selectedApplicant]
        let announcement = sortTableTitles[selectedSubtableNumber]
        
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
        
        let currentAnnouncement = sortTableTitles[selectedSubtableNumber]
        let applicants = dataManager.applicantCD.filter{$0.announcement == currentAnnouncement}
        applicantTableTitles = applicants.map{$0.name!}
        
        if !applicantTableTitles.isEmpty {
            let set = Set(applicantTableTitles)
            applicantTableTitles = Array(set).sorted()
        }
    }
    
    func populateListTable() {
        print("populateListTable")
        
        sortTableTitles = [String]()

        switch categories[selectedCategoryNumber] {
        case "Recently":
            sortTableTitles = recentStrings
            
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
            
        case "Books":
            let tmp = dataManager.booksGroupsCD.sorted(by: {($0.sortNumber!, $0.tag!) < ($1.sortNumber!, $1.tag!)})
            sortTableTitles = tmp.map { $0.tag! }

        case "Economy":
            if economyStrings[optionsSegment.selectedSegmentIndex] == "Projects" {
                let tmp = dataManager.projectCD.sorted(by: {$0.name! < $1.name!})
                sortTableTitles = tmp.map { $0.name! }
                
            } else if economyStrings[optionsSegment.selectedSegmentIndex] == "Invoices" {
                let (number, _) = dataManager.getCategoryNumberAndURL(name: categories[selectedCategoryNumber])
                
                for file in dataManager.localFiles[number] {
                    sortTableTitles.append(file.grandpaFolder!)
                }
                
                if !sortTableTitles.isEmpty {
                    let set = Set(sortTableTitles)
                    sortTableTitles = Array(set)
                    sortTableTitles = sortTableTitles.sorted()
                }
                
            } else if economyStrings[optionsSegment.selectedSegmentIndex] == "Grants" {
                let tmp = dataManager.fundCD.sorted(by: {$0.deadline! < $1.deadline!})
                sortTableTitles = tmp.map { $0.name! }
            }
            
        case "Work documents":
            
            if workDocStrings[optionsSegment.selectedSegmentIndex] == "Files" {
                let (number, _) = dataManager.getCategoryNumberAndURL(name: categories[selectedCategoryNumber])
                
                for file in dataManager.localFiles[number] {
                    sortTableTitles.append(file.grandpaFolder!)
                }
                
                if !sortTableTitles.isEmpty {
                    let set = Set(sortTableTitles)
                    sortTableTitles = Array(set)
                    sortTableTitles = sortTableTitles.sorted()
                }
                
            } else if workDocStrings[optionsSegment.selectedSegmentIndex] == "Hiring" {
                
                for file in dataManager.applicantCD {
                    sortTableTitles.append(file.announcement!)
                }
                
                if !sortTableTitles.isEmpty {
                    let set = Set(sortTableTitles)
                    sortTableTitles = Array(set)
                    sortTableTitles = sortTableTitles.sorted()
                }
                
                populateHiringTable()
                
                applicantTableList.reloadData()

            }
            
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
        print("populateFilesCV")

        filesCV = [[]]

        switch selectedCategory {
        case "Recently":
            let dates = getRecentDates()
            for i in 0..<sortTableTitles.count {
                filesCV[i] = []
                if sortTableTitles[i] != "Favorites" {
                    let items = dataManager.recentCD.filter{ $0.dateOpened! > dates[i] }
                    for item in items {
                        for j in 0..<dataManager.categories.count {
                            let file = dataManager.localFiles[j].filter{ $0.path == item.path }
                            if !file.isEmpty {
                                filesCV[i].append(file.first!)
                            }
                        }
                    }
                } else {
                    let items = dataManager.favoritesCD
                    for item in items {
                        print(item.filename)
                        for j in 0..<dataManager.categories.count {
                            let file = dataManager.localFiles[j].filter{ $0.path == item.path }
                            if !file.isEmpty {
                                filesCV[i].append(file.first!)
                            }
                        }
                    }
                }

                if i < sortTableTitles.count {
                    filesCV.append([]) // ADD [] FOR THE NEXT ROUND
                }
            }

            for item in dataManager.recentCD {
                if item.dateOpened! < dates.last! {
                    if let index = dataManager.recentCD.index(where: { $0.path == item.path! } ) {
                        print("Removing: " + dataManager.recentCD[index].filename!)
                        dataManager.recentCD.remove(at: index)
                        dataManager.saveCoreData()
                    }
                }
            }
        
        case "Publications":
            
            var files: [LocalFile]
            if dataManager.isSearching && dataManager.searchString.count > 0 {
                files = dataManager.searchResult
            } else {
                files = dataManager.localFiles[selectedCategoryNumber]
            }
            
            switch sortSubtableStrings[selectedSortingNumber] {
            case "Tag":
                var dateComponents = DateComponents()
                dateComponents.day = -recentDays
                let recent = Calendar.current.date(byAdding: dateComponents, to: Date())
                
                for i in 0..<sortTableTitles.count {
                    for file in files {
                        if file.groups.first(where: {$0 == sortTableTitles[i]}) != nil {
                            filesCV[i].append(file)
                        }
                        if sortTableTitles[i] == "Recently added/modified" && file.dateModified! > recent! {
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
            
        case "Books":
            filesCV = [[]]
            var dateComponents = DateComponents()
            dateComponents.day = -recentDays
            let recent = Calendar.current.date(byAdding: dateComponents, to: Date())

            var files: [LocalFile]
            
            files = dataManager.localFiles[selectedCategoryNumber]
            for i in 0..<sortTableTitles.count {
                for file in files {
                    if file.groups.first(where: {$0 == sortTableTitles[i]}) != nil {
                        filesCV[i].append(file)
                    }
                    if sortTableTitles[i] == "Recently added/modified" && file.dateModified! > recent! {
                        filesCV[i].append(file)
                    }
                }
                filesCV[i] = filesCV[i].sorted(by: {($0.filename) < ($1.filename)})
                if i < sortTableTitles.count {
                    filesCV.append([]) // ADD [] FOR THE NEXT ROUND
                }
            }
        case "Economy":

            docCV = []
            
            let (number, _) = dataManager.getCategoryNumberAndURL(name: selectedCategory)
            
            if economyStrings[optionsSegment.selectedSegmentIndex] == "Invoices" {
                if !sortTableTitles.isEmpty {
                    for i in 0..<sortTableTitles.count {
                        var tmp = DocCV(listTitle: sortTableTitles[i], sectionHeader: [], files: [[]])
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
            }
            
        default:
            
            let (number, _) = dataManager.getCategoryNumberAndURL(name: selectedCategory)
            
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
            destination.recentDays = recentDays
            destination.dataManager = dataManager
            destination.preferredContentSize = settingsCollectionViewBox
        }
        if (segue.identifier == "segueInvoiceVC") {
            let destination = segue.destination as! InvoiceViewController
            destination.invoiceURL = dataManager.economyURL
        }
        
    }
    
    func scrollToSection(_ section:Int)  {
        print("scrollToSection")
        
        if let cv = self.filesCollectionView {
            let indexPath = IndexPath(item: 0, section: section)
            if let attributes =  cv.layoutAttributesForSupplementaryElement(ofKind: UICollectionElementKindSectionHeader, at: indexPath) {
                
                let topOfHeader = CGPoint(x: 0, y: attributes.frame.origin.y - cv.contentInset.top)
                cv.setContentOffset(topOfHeader, animated:true)
            }
        }
    }
    
    func setupProgressMonitor() {
        print("setupProgressMonitor")

        progressMonitor.removeFromSuperview()
        
        if UIDevice.current.orientation.isLandscape {
            print("Landscape")
            if self.view.bounds.maxX < self.view.bounds.maxY { //Works
                print("L1")
                progressMonitor.frame = CGRect(x: self.view.bounds.maxY/2 - progressMonitorSettings[1]/2, y: self.view.bounds.size.height+progressMonitorSettings[0], width: progressMonitorSettings[1], height: progressMonitorSettings[0])
                progressMonitor.iPadDimension = [self.view.bounds.maxX, self.view.bounds.maxY] // [y,x]
            } else { //Normal
                print("L2")
                progressMonitor.frame = CGRect(x: self.view.bounds.maxX/2 - progressMonitorSettings[1]/2, y: self.view.bounds.size.width+progressMonitorSettings[0], width: progressMonitorSettings[1], height: progressMonitorSettings[0])
                progressMonitor.iPadDimension = [self.view.bounds.maxY, self.view.bounds.maxX]
            }
        } else {
            print("Portrait")
            if self.view.bounds.maxX < self.view.bounds.maxY { //Normal, doesn't work
                print("P1")
                progressMonitor.frame = CGRect(x: self.view.bounds.maxX/2 - progressMonitorSettings[1]/2, y: self.view.bounds.size.height+progressMonitorSettings[0], width: progressMonitorSettings[1], height: progressMonitorSettings[0])
                progressMonitor.iPadDimension = [self.view.bounds.maxY, self.view.bounds.maxX]
            } else { //Works
                print("P2")
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
        
        kvStorage = NSUbiquitousKeyValueStore()
        loadDefaultValues()
        
        //ALWAYS START WITH RECENTLY
        economyView.isHidden = true
        applicantView.isHidden = true
        filesCollectionView.isHidden = false
        scholarView.isHidden = true
        optionsSegment.isHidden = true
        notesButton.isEnabled = false
        searchButton.isEnabled = false
        downloadToLocalFileBUtton.isEnabled = false
        editButton.isEnabled = false
        favoriteButton.isEnabled = true //false
        sortCVButton.isEnabled = false
        
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

        dataManager.progressMonitor = progressMonitor
        dataManager.compareLocalFilesWithCoreData()
        dataManager.initIcloudLoad()
        
        sendNotification(text: "Starting to load iCloud records")
        
        searchBar.isHidden = searchHidden

        self.expenseBackgroundView.layer.cornerRadius = 15
        self.amountBackgroundView.layer.cornerRadius = 15
        self.organisationDeadline.setValue(UIColor.white, forKeyPath: "textColor")
        
        self.populateListTable()
        self.populateFilesCV()
        self.sortFiles()
        
        self.categoriesCV.reloadData()
        self.listTableView.reloadData()
        self.filesCollectionView.reloadData()

        setupProgressMonitor()
    }
    
    func sortFiles() {
        print("sortFiles() in " + selectedCategory)
        
        switch selectedCategory {
        case "Recently", "Publications", "Books":
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
    
    func updateApplicant() {
        let name = applicantTableTitles[selectedApplicant]
        let announcement = sortTableTitles[selectedSubtableNumber]
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
            
            print(selectedCategory)
            sendNotification(text: "Updating the order of categories")
            print("Updating order of categories")
            let number = categories.index(where: { $0 == selectedCategory })
            let index = orderedCategories.index(where: { $0.name == selectedCategory })
            selectedCategoryNumber = number!
            let indexPath = IndexPath(row: index!, section: 0)
            
            categoriesCV.reloadData()
            populateListTable()
            populateFilesCV()
            sortFiles()
            listTableView.reloadData()
            filesCollectionView.reloadData()
        }
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
        print("numberOfSections in tableView")
        
        if tableView == self.expensesTableView {
            if selectedSubtableNumber < dataManager.projectCD.count {
                return (dataManager.projectCD[selectedSubtableNumber].expense?.count)!
            } else {
                return 0
            }
            
        } else if tableView == self.applicantTableList {
            return applicantTableTitles.count
            
        } else {
            return sortTableTitles.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 5
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        print("viewForHeaderInSection in tableView")
        
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("numberOfRowsInSection in tableView")
        
        var number = 1
        if tableView == self.expensesTableView {
            number = 1
        } else if tableView == self.listTableView {
            switch selectedCategory {
            
            case "Recently", "Publications", "Books", "Economy", "Work documents":
                return 1
                
            default:
                if !sortTableTitles.isEmpty {
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
        print("cellForRowAt in tableView: " + selectedCategory)
        
        var cellToReturn = UITableViewCell()
        
        if tableView == self.expensesTableView {
            
            let cell = expensesTableView.dequeueReusableCell(withIdentifier: "economyCell") as! EconomyCell
            let currentProject = dataManager.projectCD[selectedSubtableNumber]
            
            if indexPath.section == 0 {
                currentProject.amountRemaining = currentProject.amountReceived
            }
            
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
            
            switch selectedCategory {
            case "Recently", "Publications", "Books":
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
        print("didSelectRowAt in tableView: " + selectedCategory)
        
        if tableView == self.listTableView {
            
            selectedSubtableNumber = indexPath.section
            dataManager.selectedSubtableNumber = selectedSubtableNumber
            
            switch selectedCategory {
            case "Recently", "Publications", "Books":
                if filesCV[indexPath.section].count > 0 {
                    scrollToSection(indexPath.section)
                }

            case "Work documents":
                if workDocStrings[optionsSegment.selectedSegmentIndex] == "Hiring" {
                    self.populateHiringTable()
                    self.applicantTableList.reloadData()
                    
                    //RELOAD APPLICANT WINDOW
                } else {
                    currentIndexPath = indexPath
                    self.sortFiles()
                    self.filesCollectionView.reloadData()
                }
                
            case "Economy":
                if economyStrings[optionsSegment.selectedSegmentIndex] == "Projects" {
                    let currentProject = dataManager.projectCD[selectedSubtableNumber]
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
                    
                } else if economyStrings[optionsSegment.selectedSegmentIndex] == "Invoices" {
                    if docCV[0].files[indexPath.section].count > 0 {
                        scrollToSection(indexPath.section)
                    }
                    
                } else if economyStrings[optionsSegment.selectedSegmentIndex] == "Grants" {
                    let currentFund = dataManager.fundCD[selectedSubtableNumber]
                    organisationDeadline.date = currentFund.deadline!
                    currencyFunding.text = currentFund.currency!
                    amountFunding.text = "\(currentFund.amount)"
                    internetAddressOrganisation.text = currentFund.website
                    organisationInstructions.text = currentFund.instructions
                    nameOrganisation.text = currentFund.name!
                }
                
            default:
                
                currentIndexPath = indexPath
                sortFiles()
                self.filesCollectionView.reloadData()
                
            }
            
        } else if tableView == self.applicantTableList {
            
            selectedApplicant = indexPath.section
            let name = applicantTableTitles[selectedApplicant]
            let announcement = sortTableTitles[selectedSubtableNumber]
            
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
            switch categories[selectedCategoryNumber] {
            case "Publications":
                let number = categories.index(where: { $0 == "Publications" })
                
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
                            if let dragedPublication = dataManager.localFiles[number!].first(where: {$0.filename == filename as! String}) {
                                dataManager.assignPublicationToAuthor(filename: (dragedPublication.filename), authorName: authorName)
                            }
                        }
                    case "Journal":
                        let journalName = sortTableTitles[section]
                        if let filename = coordinator.items[0].dragItem.localObject {
                            if let dragedPublication = dataManager.localFiles[number!].first(where: {$0.filename == filename as! String}) {
                                dataManager.assignPublicationToJournal(filename: (dragedPublication.filename), journalName: journalName)
                            }
                        }
                    case "Year":
                        let year = sortTableTitles[section]
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
                    let groupName = sortTableTitles[section]
                    print(groupName)
                    if let filename = coordinator.items[0].dragItem.localObject {
                        print(filename)
                        print(selectedSubtableNumber)
                        if let dragedBook = filesCV[selectedSubtableNumber].first(where: {$0.filename == filename as! String}) {
                            print(dragedBook)
                            if let group = dataManager.booksGroupsCD.first(where: {$0.tag! == groupName}) {
                                print(group)
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
        print("canEditRowAt")
        
        var returnBool = false
        
        if tableView == self.listTableView {
            switch categories[selectedCategoryNumber] {
                
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
                    
                case "Books":
                    let currentGroup = sortTableTitles[indexPath.section]
                    let groupToDelete = dataManager.booksGroupsCD.first(where: {$0.tag! == currentGroup})
                    dataManager.context.delete(groupToDelete!)
                    
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
                let currentProject = dataManager.projectCD[selectedSubtableNumber]
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
            
            if categories[selectedCategoryNumber] == "Economy" {
                currentProject = dataManager.projectCD[selectedSubtableNumber]

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
                
            } else {
                return nil
            }
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
            case "Recently", "Publications", "Books":
                return sortTableTitles.count
            case "Economy":
                if !docCV.isEmpty {
                    return docCV[0].sectionHeader.count
                } else {
                    return 0
                }
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
            switch selectedCategory {
            case "Recently", "Publications", "Books":
                return filesCV[section].count
            case "Economy":
                return docCV[0].files[section].count
            default:
                return docCV[selectedSubtableNumber].files[section].count
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("cellForItemAt: CV")
        
        if collectionView == self.categoriesCV {
            
            searchBar.isHidden = true
            dataManager.isSearching = false
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "categoryCell", for: indexPath) as! categoryCell
            let number = Int(orderedCategories[indexPath.row].originalOrder)

            let itemsSaving = dataManager.localFiles[number].filter{ $0.saving == true }.count
            let itemsDownloading = dataManager.localFiles[number].filter{ $0.downloading == true }.count
            let itemsDisplay = itemsSaving + itemsDownloading

            
            if orderedCategories[indexPath.row].name != "Recently" {
                cell.number.isHidden = false
                cell.saveNumber.isHidden = false
                cell.number.text = "\(dataManager.localFiles[number].count)"
                cell.saveNumber.text = "\(itemsDisplay)"
            } else {
                cell.number.isHidden = true
                cell.saveNumber.isHidden = true
            }
            
            if itemsDisplay == 0 {
                cell.saveNumber.isHidden = true
            } else {
                if cell.saveNumber.isHidden == true {
                    cell.saveNumber.isHidden = false
                    cell.saveNumber.grow()
                }
            }
            
            switch orderedCategories[indexPath.row].name {

            case "Recently":
                cell.icon.image = #imageLiteral(resourceName: "RecentlyIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "RecentlyIconSelected")
                
            case "Publications":
                cell.icon.image = #imageLiteral(resourceName: "PublicationsIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "PublicationsIconSelected")

            case "Books":
                cell.icon.image = #imageLiteral(resourceName: "BooksIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "BooksIconSelected")
                
            case "Economy":
                cell.icon.image = #imageLiteral(resourceName: "EconomyIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "EconomyIconSelected")

            case "Manuscripts":
                cell.icon.image = #imageLiteral(resourceName: "ManuscriptsIcon2")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "ManuscriptsIcon2Selected")

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

            case "Work documents":
                cell.icon.image = #imageLiteral(resourceName: "WorkDocumentIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "WorkDocumentIconSelected")

            case "Travel":
                cell.icon.image = #imageLiteral(resourceName: "TravelIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "TravelIconSelected")

            case "Notes":
                cell.icon.image = #imageLiteral(resourceName: "TakeNoteIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "TakeNoteIconSelected")

            case "Miscellaneous":
                cell.icon.image = #imageLiteral(resourceName: "MiscellaneousIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "MiscellaneousIconSelected")
                
            default:
                print("Default 144")
                cell.icon.image = #imageLiteral(resourceName: "PublicationsIcon")
            }
            
//            print(selectedCategory)
//            if orderedCategories[indexPath.row].name == selectedCategory {
//                print(orderedCategories[indexPath.row].name! + " true")
//                cell.icon.isHighlighted = true
//            } else {
//                print(orderedCategories[indexPath.row].name! + " false")
//                cell.icon.isHighlighted = false
//            }
            
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
            
            var path = ""
            
            switch categories[selectedCategoryNumber] {
                
            case "Recently":
                cell.thumbnail.image = filesCV[indexPath.section][indexPath.row].thumbnail
                cell.label.text = filesCV[indexPath.section][indexPath.row].filename
                cell.deleteIcon.isHidden = true
                
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
                
                path = filesCV[indexPath.section][indexPath.row].path
                
//                if filesCV[indexPath.section][indexPath.row].favorite == "Yes" {
//                    cell.favoriteIcon.isHidden = false
//                } else {
//                    cell.favoriteIcon.isHidden = true
//                }
                
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
                
                if cell.label.text == currentSelectedFilename {
                    selectedLocalFile = filesCV[indexPath.section][indexPath.row]
                    cell.layer.borderColor = UIColor.yellow.cgColor
                    cell.layer.borderWidth = 3
                } else {
                    cell.layer.borderColor = UIColor.black.cgColor
                    cell.layer.borderWidth = 1
                }
                
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
                
                path = filesCV[indexPath.section][indexPath.row].path
                
//                if filesCV[indexPath.section][indexPath.row].favorite == "Yes" {
//                    cell.favoriteIcon.isHidden = false
//                } else {
//                    cell.favoriteIcon.isHidden = true
//                }

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

            case "Books":
                cell.thumbnail.image = filesCV[indexPath.section][indexPath.row].thumbnail
                cell.label.text = filesCV[indexPath.section][indexPath.row].filename
                cell.deleteIcon.isHidden = true
                
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
                
                path = filesCV[indexPath.section][indexPath.row].path
//                if filesCV[indexPath.section][indexPath.row].favorite == "Yes" {
//                    cell.favoriteIcon.isHidden = false
//                } else {
//                    cell.favoriteIcon.isHidden = true
//                }
                
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
                let number = 0
                
                cell.label.text = docCV[number].files[indexPath.section][indexPath.row].filename
                cell.thumbnail.image = docCV[number].files[indexPath.section][indexPath.row].thumbnail
//                cell.favoriteIcon.isHidden = true
                cell.deleteIcon.isHidden = true
                cell.sizeLabel.text = docCV[number].files[indexPath.section][indexPath.row].size
                
                path = docCV[number].files[indexPath.section][indexPath.row].path
                
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
//                cell.favoriteIcon.isHidden = true
                cell.deleteIcon.isHidden = true
                cell.sizeLabel.text = docCV[selectedSubtableNumber].files[indexPath.section][indexPath.row].size

                path = docCV[selectedSubtableNumber].files[indexPath.section][indexPath.row].path
                
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
            
            if !path.isEmpty && dataManager.favoritesCD.first(where: {$0.path == path}) != nil {
                print(dataManager.favoritesCD.first(where: {$0.path == path}))
                cell.favoriteIcon.isHidden = false
            } else {
                print("False")
                cell.favoriteIcon.isHidden = true
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("didSelectItemAt - CV")
        
        if collectionView == self.categoriesCV {
            
            let currentCategory = orderedCategories[indexPath.row]
            let number = categories.index(where: { $0 == currentCategory.name })
            selectedCategoryTitle.text = "  " + currentCategory.name!
            selectedCategoryNumber = number!
            selectedCategory = currentCategory.name
            selectedSubtableNumber = 0

            dataManager.selectedSubtableNumber = selectedSubtableNumber
            dataManager.selectedCategoryNumber = selectedCategoryNumber

            downloadToLocalFileBUtton.image = #imageLiteral(resourceName: "DownloadPDF.png")
            downloadToLocalFileBUtton.isEnabled = false
//            favoriteButton.isEnabled = false
            
            switch selectedCategory {
            case "Recently":
                self.economyView.isHidden = true
                self.scholarView.isHidden = true
                self.applicantView.isHidden = true
                self.filesCollectionView.isHidden = false
                self.addNew.isEnabled = false
                self.sortCVButton.isEnabled = false
                self.editButton.isEnabled = false
                self.notesButton.isEnabled = false
                self.optionsSegment.isHidden = true
                self.searchButton.isEnabled = false
                self.downloadToLocalFileBUtton.isEnabled = false

            case "Publications":
                self.optionsSegment.replaceSegments(segments: sortSubtableStrings)
                self.optionsSegment.isHidden = false
                if optionsSegment.selectedSegmentIndex > 4 || optionsSegment.selectedSegmentIndex < 0 {
                    optionsSegment.selectedSegmentIndex = 0
                }
                self.economyView.isHidden = true
                self.scholarView.isHidden = true
                self.applicantView.isHidden = true
                self.filesCollectionView.isHidden = false
                self.addNew.isEnabled = true
                self.sortCVButton.isEnabled = true
                if sortSubtableStrings[optionsSegment.selectedSegmentIndex] == "Tag" {
                    self.editButton.isEnabled = true
                } else {
                    self.editButton.isEnabled = false
                }
                self.notesButton.isEnabled = true
                self.optionsSegment.isHidden = false
                self.searchButton.isEnabled = true

            case "Books":
                self.filesCollectionView.isHidden = false
                self.sortCVButton.isEnabled = true
                self.editButton.isEnabled = false
                self.addNew.isEnabled = true
                self.notesButton.isEnabled = false
                self.optionsSegment.isHidden = true
                self.searchButton.isEnabled = false
                self.searchBar.isHidden = true
                self.economyView.isHidden = true
                self.scholarView.isHidden = true
                self.applicantView.isHidden = true
                
            case "Economy":
                optionsSegment.replaceSegments(segments: economyStrings)
                self.optionsSegment.isHidden = false
                if optionsSegment.selectedSegmentIndex > 2 || optionsSegment.selectedSegmentIndex < 0 {
                   optionsSegment.selectedSegmentIndex = 0
                }
                self.sortCVButton.isEnabled = false
                self.editButton.isEnabled = false
                self.addNew.isEnabled = true
                self.notesButton.isEnabled = false
                self.optionsSegment.isHidden = false
                self.searchButton.isEnabled = false
                self.searchBar.isHidden = true
                self.applicantView.isHidden = true
                if economyStrings[optionsSegment.selectedSegmentIndex] == "Projects" {
                    self.economyView.isHidden = false
                    self.scholarView.isHidden = true
                    self.filesCollectionView.isHidden = true
                } else if economyStrings[optionsSegment.selectedSegmentIndex] == "Invoices" {
                    self.economyView.isHidden = true
                    self.scholarView.isHidden = true
                    self.filesCollectionView.isHidden = false
                } else if economyStrings[optionsSegment.selectedSegmentIndex] == "Grants" {
                    self.economyView.isHidden = true
                    self.scholarView.isHidden = false
                    self.filesCollectionView.isHidden = true
                }
                
            case "Notes":
                self.filesCollectionView.isHidden = false
                self.sortCVButton.isEnabled = true
                self.editButton.isEnabled = false
                self.addNew.isEnabled = true
                self.notesButton.isEnabled = false
                self.optionsSegment.isHidden = true
                self.searchButton.isEnabled = false
                self.searchBar.isHidden = true
                self.economyView.isHidden = true
                self.scholarView.isHidden = true
                self.applicantView.isHidden = true
                
            case "Work documents":
                optionsSegment.replaceSegments(segments: workDocStrings)
                
                self.optionsSegment.isHidden = false
                if optionsSegment.selectedSegmentIndex > 1 || optionsSegment.selectedSegmentIndex < 0 {
                    optionsSegment.selectedSegmentIndex = 0
                }
                
                if workDocStrings[optionsSegment.selectedSegmentIndex] == "Files" {
                    self.applicantView.isHidden = true
                    self.filesCollectionView.isHidden = false
                } else if workDocStrings[optionsSegment.selectedSegmentIndex] == "Hiring" {
                    self.applicantView.isHidden = false
                    self.filesCollectionView.isHidden = true
                }

                self.sortCVButton.isEnabled = false
                self.editButton.isEnabled = false
                self.addNew.isEnabled = true
                self.notesButton.isEnabled = false
                self.optionsSegment.isHidden = false
                self.searchButton.isEnabled = false
                self.searchBar.isHidden = true
                self.economyView.isHidden = true
                self.scholarView.isHidden = true
                
            default:
                self.economyView.isHidden = true
                self.scholarView.isHidden = true
                self.applicantView.isHidden = true
                self.filesCollectionView.isHidden = false
                self.addNew.isEnabled = false
                self.editButton.isEnabled = false
                self.sortCVButton.isEnabled = true
                self.notesButton.isEnabled = false
                self.optionsSegment.isHidden = true
                self.searchButton.isEnabled = false
                self.searchBar.isHidden = true
            }

            populateListTable()
            populateFilesCV()
            sortFiles()
            
            listTableView.reloadData()
            filesCollectionView.reloadData()
            
            //WILL THIS WORK?
            if dataManager.localFiles[number!].count > 0 {
                if self.filesCollectionView.numberOfSections > 0 {
                    self.filesCollectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
                    scrollToSection(0)
                }
            }
            
            dataManager.updateCategoriesOrder(category: categories[selectedCategoryNumber])
            updateCategoriesOrder()
            
        } else {
            
            let currentCell = collectionView.cellForItem(at: indexPath) as! FilesCell
            
            switch categories[selectedCategoryNumber] {
            case "Recently":
                selectedLocalFile = filesCV[indexPath.section][indexPath.row]
//                favoriteButton.isEnabled = false
                notesButton.isEnabled = false
                editButton.isEnabled = false
                searchButton.isEnabled = false
                sortCVButton.isEnabled = false
                downloadToLocalFileBUtton.isEnabled = false
                
            case "Publications":
                selectedLocalFile = filesCV[indexPath.section][indexPath.row]
                notesButton.isEnabled = true
//                favoriteButton.isEnabled = true
                searchButton.isEnabled = true

            case "Books":
                selectedLocalFile = filesCV[indexPath.section][indexPath.row]
                notesButton.isEnabled = false
//                favoriteButton.isEnabled = true
                searchButton.isEnabled = true
                
            case "Economy":
//                favoriteButton.isEnabled = false
                notesButton.isEnabled = false
                selectedLocalFile = docCV[0].files[indexPath.section][indexPath.row]
                
            default:
                selectedLocalFile = docCV[selectedSubtableNumber].files[indexPath.section][indexPath.row]
//                favoriteButton.isEnabled = false
                searchButton.isEnabled = true
                notesButton.isEnabled = false
            }
            
            if let tmp = dataManager.favoritesCD.first(where: {$0.path == selectedLocalFile.path}) { //selectedLocalFile.favorite == "Yes" { //} && favoriteButton.isEnabled {
                favoriteButton.image = #imageLiteral(resourceName: "star-filled")
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
            
            if categories[selectedCategoryNumber] == "Recently" {
                downloadToLocalFileBUtton.isEnabled = false
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
                        
                        let number = categories.index(where: { $0 == selectedLocalFile.category })
                        
                        let newDownload = DownloadingFile(filename: selectedLocalFile.filename, url: fileURL, downloaded: false, path: filePath, category: number!)
                        filesDownloading.append(newDownload)
                        downloadTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(checkIfFileIsDownloaded), userInfo: nil, repeats: true)
                        selectedLocalFile.downloading = true
                        if categories[selectedCategoryNumber] == "Publications" || categories[selectedCategoryNumber] == "Books" || categories[selectedCategoryNumber] == "Recently" {
                            filesCV[indexPath.section][indexPath.row].downloading = true
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
                
            }
            
            /*
            updateCurrentSelectedFile(indexPath: indexPath) //Only when a "file" is selected
            */
            
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        
        var item: String = ""
        if categories[selectedCategoryNumber] == "Publications" || categories[selectedCategoryNumber] == "Books" {
            selectedSubtableNumber = indexPath.section
            dataManager.selectedSubtableNumber = indexPath.section
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
        case "Recently", "Publications", "Books":
            sectionHeaderView.mainHeaderTitle.text = sortTableTitles[indexPath[0]]
            if filesCV[indexPath[0]].count == 1 {
                sectionHeaderView.subHeaderTitle.text = "\(filesCV[indexPath[0]].count)" + " item"
            } else {
                sectionHeaderView.subHeaderTitle.text = "\(filesCV[indexPath[0]].count)" + " items"
            }
        case "Economy":
            sectionHeaderView.mainHeaderTitle.text = docCV[selectedSubtableNumber].sectionHeader[indexPath.section]
            if docCV[selectedSubtableNumber].files[indexPath.section].count == 1 {
                sectionHeaderView.subHeaderTitle.text = "\(docCV[selectedSubtableNumber].files[indexPath.section].count)" + " item"
            } else {
                sectionHeaderView.subHeaderTitle.text = "\(docCV[selectedSubtableNumber].files[indexPath.section].count)" + " items"
            }
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

    
    
    
    override func prefersHomeIndicatorAutoHidden() -> Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
    override var shouldAutorotate: Bool {
        return true
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
        setupProgressMonitor()
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




