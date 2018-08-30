//
//  ViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-04-04.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

//FIX: TOGGLING FAVORITES DOES NOT WORK

import UIKit
import CloudKit
import PDFKit
import MobileCoreServices
import Foundation
import CoreData

var mainVC: ViewController?

struct PublicationFile {
    var filename: String
    var title: String?
    var year: Int16?
    var thumbnails: [UIImage]
    var category: String
    var rank: Float?
    var note: String?
    var dateCreated: Date?
    var dateModified: Date?
    var favorite: String?
    var author: String?
    var journal: String?
    var groups: [String?]
//    var currentItems: [Any]
//    var currentItem: Int
}

struct ManuscriptFile {
    var filename: String
    var title: String?
    var year: Int16?
    var thumbnails: [UIImage]
    var category: String
    var rank: Float?
    var note: String?
    var dateCreated: Date?
    var dateModified: Date?
    var favorite: String?
    var author: String?
    var groups: [String?]
    //    var currentItems: [Any]
    //    var currentItem: Int
}

struct LocalFile {
    var label: String
    var thumbnail: UIImage
    var favorite: String
    var filename: String
    var url: URL
    var title: String?
    var journal: String?
    var year: Int16?
    var category: String
    var rank: Float?
    var note: String?
    var dateCreated: Date?
    var dateModified: Date?
    var author: String?
    var groups: [String?]
    var parentFolder: String?
    var available: Bool
    var filetype: String?
}

struct File {
    var thumbnail: UIImage
    var label: String
    var hiddenLabel: String
    var favorite: String
}

struct ProjectFile {
    var name: String
    var amountReceived: Int16
    var amountRemaining: Int16
    var expenses: [ExpenseFile]
}

struct ExpenseFile {
    var amount: Int16
    var reference: String?
    var overhead: Int16?
    var comment: String?
    var pdfURL: URL?
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
    @IBOutlet weak var hiddenFilename: UILabel!
    @IBOutlet weak var deleteIcon: UIImageView!
    @IBOutlet weak var selectedFileFrame: UIImageView!
    @IBOutlet weak var fileOffline: UIImageView!
    
}

class EconomyCell: UITableViewCell {
    @IBOutlet weak var expenseAmount: UILabel!
    @IBOutlet weak var overheadAmount: UILabel!
    @IBOutlet weak var referenceString: UILabel!
    @IBOutlet weak var commentString: UILabel!
    
}

struct DownloadingFile {
    var filename: String
    var url: URL
    var downloaded: Bool
}


//UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UIPopoverPresentationControllerDelegate, UIDocumentMenuDelegate, UIDocumentPickerDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate, UICollectionViewDragDelegate, UICollectionViewDropDelegate, UITableViewDropDelegate

class ViewController: UIViewController, UIDocumentPickerDelegate, UIPopoverPresentationControllerDelegate, UIDocumentMenuDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDataSource, UITableViewDelegate, UICollectionViewDragDelegate, UICollectionViewDropDelegate, UITableViewDropDelegate {
    

    // MARK: - Variables
    var appDelegate: AppDelegate!
//    var document: MyDocument?
    let container = CKContainer.default
    var privateDatabase: CKDatabase?
    var currentRecord: CKRecord?
    var recordZone: CKRecordZone?
    var recordID: CKRecordID?
    
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
    var currentIndexPath: IndexPath!

    
    // MARK: - iCloud variables
    var documentURL: URL!
    var documentPage = 0
    var iCloudURL: URL!
    var kvStorage: NSUbiquitousKeyValueStore!
    var publicationsURL: URL!
    var projectsURL: URL!
    var manuscriptsURL: URL!
    var proposalsURL: URL!
    var presentationsURL: URL!
    var supervisionsURL: URL!
    var miscellaneousURL: URL!
    var patentsURL: URL!
    var economyURL: URL!
    var metaDataQuery: NSMetadataQuery?
    var metaData: NSMetadataQuery!
    var publicationsIC: [PublicationFile] = []
    var icloudAvailable = false
    
    // MARK: - UI variables
    let documentInteractionController = UIDocumentInteractionController()
    let categories: [String] = ["Publications", "Economy", "Manuscripts", "Presentations", "Proposals", "Supervision", "Teaching", "Patents", "Miscellaneous"]
    var settingsCollectionViewBox = CGSize(width: 250, height: 300)
    var currentTheme: Int = 0
    var editingFilesCV = false
    var currentSelectedFilename: String? = nil
    
    var sortCollectionViewBox = CGSize(width: 348, height: 28)
    var sortCollectionViewNumbers: [Int] = [0, 0, 0, 0, 0, 0, 0]
    var sortCollectionViewStrings: [String] = [""]
    var selectedCategoryNumber = 0

    var localFiles: [[LocalFile]] = [[]]
    var filesCV: [[LocalFile]] = [[],[],[],[],[],[],[],[],[]] //Place files to be displayed in collection view here
    var sortSubtableStrings: [String] = [""]
    var sortSubtableNumbers: [Int] = [0, 0, 0, 0, 0, 0, 0, 0, 0]
    var selectedSubtableNumber = 0
    var sortTableTitles: [String] = [""]

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
    @IBOutlet weak var economyView: UIView!
    @IBOutlet weak var economyHeader: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var listTableView: UITableView!
    @IBOutlet weak var filesCollectionView: UICollectionView!
    @IBOutlet weak var selectedCategoryTitle: UILabel!
    @IBOutlet weak var categoriesCV: UICollectionView!
    @IBOutlet weak var notesView: UIView!
    @IBOutlet weak var filesView: UIView!
    @IBOutlet weak var segmentedControllTablesOrNotes: UISegmentedControl!
    @IBOutlet weak var sortCVButton: UIButton!
    @IBOutlet weak var sortSTButton: UIButton!
    @IBOutlet weak var addNewGroupText: UIButton!
    
    
    @IBOutlet weak var largeThumbnail: UIImageView!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var filenameString: UITextField!
    @IBOutlet weak var journalString: UITextField!
    @IBOutlet weak var notesString: UITextField!
    
//    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var authorString: UITextField!
    @IBOutlet weak var yearString: UITextField!
    @IBOutlet weak var rankValue: UILabel!
    @IBOutlet weak var rankOutlet: UISlider!
    @IBOutlet weak var fileTypePicker: UIPickerView!
    
    @IBOutlet weak var settingsButton: UIButton!
    
    @IBOutlet weak var amountReceivedString: UITextField!
    
    @IBOutlet weak var amountRemainingString: UITextField!
    
    @IBOutlet weak var currencyString: UILabel!
    @IBOutlet weak var expenseString: UITextField!
    @IBOutlet weak var overheadString: UITextField!
    @IBOutlet weak var referenceString: UITextField!
    @IBOutlet weak var commentString: UITextField!
    @IBOutlet weak var expensesTableView: UITableView!
    
    
    
    //MARK: - IBActions
    @IBAction func downloadFromIcloud(_ sender: Any) {
        
        for category in categories {
            switch category {
            case "Publications":
                let query = CKQuery(recordType: categories[selectedCategoryNumber], predicate: NSPredicate(value: true))
                privateDatabase?.perform(query, inZoneWith: nil) { (records, error) in
                    guard let records = records else {return}
                    for record in records {
                        let name = record.object(forKey: "Filename") as! String
                        if self.publicationsCD.first(where: {$0.filename == name}) == nil {
                            print(name + " does not exist")
                            
                            let newPublication = Publication(context: self.context)
                            newPublication.filename = name
                            newPublication.dateCreated = record.creationDate
                            newPublication.dateModified = record.modificationDate
                            newPublication.title = record.object(forKey: "Title") as? String
                            newPublication.year = record.object(forKey: "Year") as! Int16
                            newPublication.rank = record.object(forKey: "Rank") as! Float
                            newPublication.note = record.object(forKey: "Note") as? String
                            newPublication.favorite = record.object(forKey: "Favorite") as? String
                            let groups = record.object(forKey: "Group") as? [String]
                            let author = record.object(forKey: "Author") as? String
                            
                            for group in groups! {
                                if let groupName = self.publicationGroupsCD.first(where: {$0.tag == group}) {
                                    newPublication.addToPublicationGroup(groupName)
                                } else {
                                    let newPublicationGroup = PublicationGroup(context: self.context)
                                    newPublicationGroup.tag = group
                                    newPublicationGroup.dateModified = Date()
                                    newPublicationGroup.sortNumber = "3"
                                    self.publicationGroupsCD.append(newPublicationGroup)
                                    newPublication.addToPublicationGroup(newPublicationGroup)
                                }
                            }
                            
                            if let authorName = self.authorsCD.first(where: {$0.name == author}) {
                                newPublication.author = authorName
                            } else {
                                let newAuthor = Author(context: self.context)
                                newAuthor.name = author
                                newAuthor.sortNumber = "1"
                                self.authorsCD.append(newAuthor)
                                newPublication.author = newAuthor
                            }
                            
                            self.publicationsCD.append(newPublication)
                            self.saveCoreData()
                            
                        } else {
                            print(name + " exist")
                        }
                    }
                }
            default:
                print("122")
            }

        }
//        let query = CKQuery(recordType: categories[selectedCategoryNumber], predicate: NSPredicate(value: true))
//        privateDatabase?.perform(query, inZoneWith: nil) { (records, error) in
//            guard let records = records else {return}
//            for rec in records {
////                print(rec.recordID.recordName)
////                print(rec.object(forKey: "Filename"))
////                let keys = rec.allKeys()
//            }
////            DispatchQueue.main.async {
////                let thumbnail = record.object(forKey: "Thumbnail") as! CKAsset
////                self.largeThumbnail.image = UIImage(contentsOfFile: thumbnail.fileURL.path)
////            }
//        }
//    }
    }
    
    @IBAction func uploadToIcloud(_ sender: Any) {
        if let zoneID = recordZone?.zoneID {
            switch categories[selectedCategoryNumber] {
            case "Publications":
                
                for pub in publicationsCD {
                    let myRecord = CKRecord(recordType: categories[selectedCategoryNumber], zoneID: zoneID)
                    let tags = pub.publicationGroup?.allObjects as! [PublicationGroup]
                    var pubTags = [""]
                    if tags.isEmpty {
                        pubTags = ["Unfiled", "All publications"]
                    } else {
                        pubTags[0] = tags[0].tag!
                        for i in 1..<tags.count {
                            pubTags.insert(tags[i].tag!, at: i)
                        }
                    }
                    
                    let author = pub.author?.name
                    myRecord.setObject("No" as CKRecordValue?, forKey: "Favorite")
                    myRecord.setObject(author as CKRecordValue?, forKey: "Author")
                    myRecord.setObject(pub.filename as CKRecordValue?, forKey: "Filename")
                    myRecord.setObject(pubTags as CKRecordValue?, forKey: "Group")
                    myRecord.setObject(pub.rank as CKRecordValue?, forKey: "Rank")
                    myRecord.setObject(pub.year as CKRecordValue?, forKey: "Year")
                    myRecord.setObject(pub.note as CKRecordValue?, forKey: "Note")
                    myRecord.setObject(pub.title as CKRecordValue?, forKey: "Title")
                    
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
                                    print("Record successfully uploaded to icloud database")
                                }
                                self.currentRecord = myRecord
                            }
                    }
                    privateDatabase?.add(modifyRecordsOperation)
                }
            default:
                print("112")
            }
        }
    }
    
    //FIX: FAVORITES DOES NOT UPLOAD TO ICLOUD
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
                
                print(localFiles[0][localFileIndex].filename + " now favorite")
                
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
//            sortItems()
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
            filesView.isHidden = true

        case "Notes":
            switch categories[selectedCategoryNumber] {
            case "Publications":
                notesView.isHidden = false
                filesView.isHidden = true
            case "Manuscripts":
                notesView.isHidden = true
                filesView.isHidden = false
            default:
                notesView.isHidden = false
                filesView.isHidden = true
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
    
    @IBAction func tappedLoad(_ sender: Any) {

//        print(filenameString.text)
        let fileManager = FileManager.default
        let fileURL = publicationsURL.appendingPathComponent("." + filenameString.text! + ".icloud")
        do {
            try fileManager.startDownloadingUbiquitousItem(at: fileURL)
        } catch let error {
            print(error)
        }
//        :startDownloadingUbiquitousItemAtURL:error
//
//
////        iCloudURL = fileManager.url(forUbiquityContainerIdentifier: nil)
////        guard iCloudURL != nil else {
////            print("Unable to access iCloud account")
////            return
////        }
////        iCloudURL = iCloudURL?.appendingPathComponent("Documents/savefile.txt")
//        guard filenameString.text != nil else {
//            print("No file selected")
//            return
//        }
//        let fileURL = publicationsURL.appendingPathComponent(filenameString.text! + ".icloud")
//        print(fileURL)
//        metaDataQuery = NSMetadataQuery()
////        metaDataQuery?.predicate = NSPredicate(format: "name = %@", filenameString.text!)
//        metaDataQuery?.predicate = NSPredicate(format: "%K like '.Sedarsky2013.pdf.icloud'", NSMetadataItemFSNameKey)
////        metaDataQuery?.predicate = NSPredicate(format: "%K ENDSWITH '.pdf'", NSMetadataItemFSNameKey)
////        //        metaDataQuery?.predicate = NSPredicate(format: "%K.pathExtension = '.'", NSMetadataItemFSNameKey)
////
//        metaDataQuery?.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
////
//        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.metadataQueryDidFinishGathering), name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: metaDataQuery!)
//        metaDataQuery?.start()
        
        
        
//        let request: NSFetchRequest<Publication> = Publication.fetchRequest()
//        do {
//            let items = try context.fetch(request)
//            for item in items {
//                context.delete(item)
//            }
//        } catch {
//            print("Error deleting 1")
//        }
//
//        let request: NSFetchRequest<Journal> = Journal.fetchRequest()
//        do {
//            let items = try context.fetch(request)
//            for item in items {
//                context.delete(item)
//            }
//        } catch {
//            print("Error deleting 2")
//        }
//
//        let requestPublicationGroups: NSFetchRequest<PublicationGroup> = PublicationGroup.fetchRequest()
//        do {
//            let items = try context.fetch(requestPublicationGroups)
//            for item in items {
//                if item.tag == "Unfiled" {
//                    context.delete(item)
//                }
//            }
//        } catch {
//            print("Error deleting 3")
//        }
//        saveCoreData()

    }
    
    @IBAction func Refresh(_ sender: Any) {
        readIcloudDriveFolders()
        compareLocalFilesWithDatabase()
        populateFilesCV()
        populateListTable()
//        sortItems()
        listTableView.reloadData()
        filesCollectionView.reloadData()
    }
    
    //THIS UPDATES RECORD AND DOES NOT CREATE A NEW ONE
    @IBAction func tappedSave(_ sender: Any) {
        let privateDB = CKContainer.default().privateCloudDatabase
        let query = CKQuery(recordType: "Publications", predicate: NSPredicate(value: true))
        
        privateDB.perform(query, inZoneWith: nil) { records, error in
            guard let records = records else { return }
            let rec = records[0]
            print(rec.object(forKey: "Filename"))
            rec.setObject(0 as CKRecordValue?, forKey: "Rank")
            privateDB.save(rec) { _, error in
                if let err = error {
                    print(err)
                } else {
                    DispatchQueue.main.async {
                        print("Record successfully uploaded to icloud database")
                    }
                }
            }
        }
    }

    @IBAction func importTapped(_ sender: Any) {
        let types: [String] = ["public.content"]
        
        let documentPicker : UIDocumentPickerViewController = UIDocumentPickerViewController.init(documentTypes: types, in: .import)
        
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = UIModalPresentationStyle.popover
        
        if let popoverController = documentPicker.popoverPresentationController {
            let viewForSource = sender as! UIView
            popoverController.sourceView = viewForSource
            popoverController.sourceRect = viewForSource.bounds // the position of the popover where it's showed
            documentPicker.preferredContentSize = CGSize(width: 700, height: 700)
            popoverController.delegate = self
        }
        present(documentPicker, animated: true, completion:nil)
    }
    
    @IBAction func addReceiptPDF(_ sender: Any) {
    }
    
    @IBAction func addExpenseTapped(_ sender: Any) {
        let currentProject = projectCD[selectedSubtableNumber]
        let newExpense = Expense(context: context)
        newExpense.amount = isStringAnInt(stringNumber: expenseString.text!)
        newExpense.overhead = isStringAnInt(stringNumber: overheadString.text!)
        newExpense.dateAdded = Date()
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
            let inputNewGroup = UIAlertController(title: "New group", message: "Enter name of new group", preferredStyle: .alert)
            inputNewGroup.addTextField(configurationHandler: { (newGroup: UITextField) -> Void in
                newGroup.placeholder = "Enter group tag"
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
    
    
    
    
    
    // MARK: - ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.startAnimating()
        
        isIcloudAvailble()
        
        //MARK: - AppDelegate
        let app = UIApplication.shared
        appDelegate = app.delegate as! AppDelegate
        context = appDelegate.context
        
        publicationsURL = appDelegate.publicationURL
        projectsURL = appDelegate.projectURL
        manuscriptsURL = appDelegate.manuscriptURL
        proposalsURL = appDelegate.publicationURL
        patentsURL = appDelegate.patentsURL
        supervisionsURL = appDelegate.supervisionURL
        presentationsURL = appDelegate.presentationURL
        miscellaneousURL = appDelegate.miscellaneousURL
        
        iCloudURL = appDelegate.iCloudURL
        
        mainVC = self
//        document = MyDocument(fileURL: getURL())
//        document?.open(completionHandler: nil)
        
        setupUI()
        
//        loadFile()
        
        navigationController?.isNavigationBarHidden = true
        self.notesView.isHidden = true
        self.filesView.isHidden = true

        categoriesCV.delegate = self
        categoriesCV.dataSource = self

        filesCollectionView.delegate = self
        filesCollectionView.dataSource = self
        filesCollectionView.dragDelegate = self
        filesCollectionView.dropDelegate = self
        
        expensesTableView.delegate = self
        expensesTableView.dataSource = self
        listTableView.delegate = self
        listTableView.dataSource = self
        listTableView.dropDelegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleSorttablePopupClosing), name: Notification.Name.sortSubtable, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSortFilesPopupClosing), name: Notification.Name.sortCollectionView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSettingsPopupClosing), name: Notification.Name.settingsCollectionView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handlePDFClosing), name: Notification.Name.closingPDF, object: nil)

        // Touch gestures
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        doubleTap.numberOfTapsRequired = 2
        self.filesCollectionView.addGestureRecognizer(doubleTap)
        
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
        
    }
    
    @objc func handleSorttablePopupClosing(notification: Notification) {
        let sortingVC = notification.object as! SortSubtableViewController
        let sortValue = sortingVC.sortOptions.selectedSegmentIndex
        sortSubtableNumbers[selectedCategoryNumber] = sortValue
        
        kvStorage.set(sortSubtableNumbers, forKey: "sortSubtable")
        kvStorage.synchronize()

        populateListTable()
        populateFilesCV()
//        sortItems()

        self.listTableView.reloadData()
        self.filesCollectionView.reloadData()
    }

    @objc func handleSortFilesPopupClosing(notification: Notification) {
        let sortingVC = notification.object as! SortItemsViewController
        let sortValue = sortingVC.sortOptions.selectedSegmentIndex
        sortCollectionViewNumbers[selectedCategoryNumber] = sortValue
        
//        sortItems()
        
        kvStorage.set(sortSubtableNumbers, forKey: "sortCollectionView")
        kvStorage.synchronize()
        //        //        defaultValues.set(sortSubtableOption, forKey: "sortSubtable")
        //
        //        subTableArticles = [[Articles]]()
        //        populateSubtable()
        //
        self.filesCollectionView.reloadData()
        //
        //        let indexPath = IndexPath(row: 0, section: 0)
        //        subTableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
    }
    
    @objc func handlePDFClosing(notification: Notification) {
        let vc = notification.object as! PDFViewController
        annotationSettings = vc.annotationSettings!

        kvStorage.set(annotationSettings, forKey: "annotationSettings")
        kvStorage.synchronize()
    }
    
    @objc func doubleTapped(gesture: UITapGestureRecognizer) {
        //FIX: WRONG FILE OPENS
        switch categories[selectedCategoryNumber] {
        case "Publications":
            let pointInCollectionView = gesture.location(in: self.filesCollectionView)
            if let indexPath = self.filesCollectionView.indexPathForItem(at: pointInCollectionView) {
                let selectedCell = filesCV[indexPath.section][indexPath.row]
                let url = publicationsURL.appendingPathComponent((selectedCell.filename))
                PDFdocument = PDFDocument(url: url)
                PDFfilename = selectedCell.filename
                NotificationCenter.default.post(name: Notification.Name.sendPDFfilename, object: self)
                performSegue(withIdentifier: "seguePDFViewController", sender: self)
            }
        case "Manuscripts":
            print("")
        default:
            print("Default 110")
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
                    print(filename)
                    print(filePath)
                    print(exist)
                    
                    if !exist {
                        stillDownloading = true
                    } else {
                        filesDownloading[i].downloaded = true
                        readIcloudDriveFolders()
                        compareLocalFilesWithDatabase()
                        populateFilesCV()
                        populateListTable()
//                        sortItems()
                        listTableView.reloadData()
                        filesCollectionView.reloadData()
                    }
                }
            }

        }
        
        if !stillDownloading {
            downloadTimer.invalidate()
            activityIndicator.stopAnimating()
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
                            
//                            var groups = [String]()
//                            for group in currentPublication.publicationGroup?.allObjects as! [PublicationGroup] {
//                                groups.append(group.tag!)
//                            }
                            
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
                                    } else {
                                        print("1. Updated record: " + file.filename)
                                    }
                                    self.activityIndicator.stopAnimating()
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
                            
//                            var groups = [String]()
//                            for group in currentPublication.publicationGroup?.allObjects as! [PublicationGroup] {
//                                groups.append(group.tag!)
//                            }
                            
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
        if icloudAvailable {
            // GET PUBLICATIONS
            let query = CKQuery(recordType: "Publications", predicate: NSPredicate(value: true))
            privateDatabase?.perform(query, inZoneWith: recordZone?.zoneID) { (records, error) in
                guard let records = records else {return}
                DispatchQueue.main.async {
                    self.activityIndicator.startAnimating()
                    for record in records {
                        let thumbnail = self.getThumbnail(url: self.publicationsURL.appendingPathComponent(record.object(forKey: "Filename") as! String), pageNumber: 0)
                        let newPublication = PublicationFile(filename: record.object(forKey: "Filename") as! String, title: record.object(forKey: "Title") as? String, year: record.object(forKey: "Year") as? Int16, thumbnails: [thumbnail], category: "Publication", rank: record.object(forKey: "Rank") as? Float, note: record.object(forKey: "Note") as? String, dateCreated: record.creationDate, dateModified: record.modificationDate, favorite: record.object(forKey: "Favorite") as? String, author: record.object(forKey: "Author") as? String, journal: record.object(forKey: "Journal") as? String, groups: record.object(forKey: "Group") as! [String?])
                        self.publicationsIC.append(newPublication)
                        print(record.object(forKey: "Filename") as! String)
                    }
                    
                    self.compareLocalFilesWithDatabase()
                    self.populateListTable()
                    self.populateFilesCV()
//                    self.sortItems()
                    
                    self.categoriesCV.reloadData()
                    self.listTableView.reloadData()
                    self.filesCollectionView.reloadData()
                    
                    self.activityIndicator.stopAnimating()

                }
            }
        } else {
            print("Icloud not available")
            compareLocalFilesWithDatabase()
            populateListTable()
            populateFilesCV()
//            sortItems()
            
            self.categoriesCV.reloadData()
            listTableView.reloadData()
            filesCollectionView.reloadData()
            activityIndicator.stopAnimating()

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
                            print(file.lastPathComponent)
                            filename = file.deletingPathExtension().lastPathComponent
                            filename.remove(at: filename.startIndex)
                        } else {
                            thumbnail = getThumbnail(url: file, pageNumber: 0)
                            filename = file.lastPathComponent
                        }
                        let newFile = LocalFile(label: file.lastPathComponent, thumbnail: thumbnail, favorite: "No", filename: filename, url: file, title: "No title", journal: "No journal", year: -2000, category: "Publication", rank: 50, note: "No notes", dateCreated: Date(), dateModified: Date(), author: "No author", groups: ["All publications"], parentFolder: nil, available: available, filetype: nil)
                        localFiles[0].append(newFile)
                    }
                } catch {
                    print("Error while enumerating files \(publicationsURL.path): \(error.localizedDescription)")
                }
            case "Manuscripts":
                readFilesInFolders(url: manuscriptsURL, type: type, number: 1)
            case "Presentations":
                readFilesInFolders(url: presentationsURL, type: type, number: 2)
            case "Proposals":
                readFilesInFolders(url: proposalsURL, type: type, number: 3)
            case "Supervision":
                readFilesInFolders(url: proposalsURL, type: type, number: 4)
            case "Teaching":
                readFilesInFolders(url: proposalsURL, type: type, number: 5)
            case "Patents":
                readFilesInFolders(url: proposalsURL, type: type, number: 6)
            default:
                print("Default 122")
            }
        }
    }
    
    func getRecordNames() {
        switch categories[selectedCategoryNumber] {
        case "Publications":
            
            let query = CKQuery(recordType: "Publications", predicate: NSPredicate(value: true))
            privateDatabase?.perform(query, inZoneWith: recordZone?.zoneID) { (records, error) in
                guard let records = records else {return}
                DispatchQueue.main.async {
                    for record in records {
                        if let tmp = self.publicationsCD.first(where: {$0.filename == record.object(forKey: "Filename") as? String}) {
                            tmp.recordName = record.recordID.recordName
                        }
                    }
                    self.saveCoreData()
                }
            }
        default:
            print("Default 123")
        }
    }
    
    func isIcloudAvailble() {
        CKContainer.default().accountStatus{ status, error in
            guard status == .available else {
                self.icloudAvailable = false
                print("Icloud is not available")
                return
            }
            self.icloudAvailable = true
            print("Icloud is available")
        }
    }
    
    func loadDefaultValues() {
        if let numbers = kvStorage.array(forKey: "sortSubtable") as? [Int] {
            sortSubtableNumbers = numbers
        } else {
            sortSubtableNumbers = [0, 0, 0, 0, 0, 0, 0]
        }
        if let numbers = kvStorage.array(forKey: "sortCollectionView") as? [Int] {
            sortCollectionViewNumbers = numbers
        } else {
            sortCollectionViewNumbers = [0, 0, 0, 0, 0, 0, 0]
        }
        if let number = kvStorage.object(forKey: "currentTheme") as? Int {
            currentTheme = number
        } else {
            currentTheme = 0
        }
        if let settings = kvStorage.object(forKey: "annotationSettings") as? [Int] {
            annotationSettings = settings
        } else {
            annotationSettings = [0, 0, 0, 0]
        }
        
//        if let number = kvStorage.object(forKey: "selectedCategory") as? Int {
//            selectedCategoryNumber = number
//        } else {
//            selectedCategoryNumber = 0
//        }
        
        //        kvStorage.longLong(forKey: "selectedSubtable")
        //        if let number = kvStorage.array(forKey: "selectedSubtable") as? Int {
        //            selectedSubtableNumber = number
        //        } else {
        //            selectedSubtableNumber = 0
        //        }
        //        let indexPath = IndexPath(row: selectedSubtableNumber, section: 0)
        //        categoriesCV.selectItem(at: indexPath, animated: false, scrollPosition: .top)
        //        selectedCategoryTitle.text = categories[selectedSubtableNumber]
        
    }
    
    func readFilesInFolders(url: URL, type: String, number: Int) {
        let fileManager = FileManager.default
        do {
            let folderURLs = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            localFiles.append([])
            for folders in folderURLs {
                let fileURLs = try fileManager.contentsOfDirectory(at: folders, includingPropertiesForKeys: nil)
                for file in fileURLs {
                    var thumbnail = UIImage()
                    var filename = String()
                    var available = true
                    if file.lastPathComponent.range(of:".icloud") != nil {
                        thumbnail = #imageLiteral(resourceName: "fileIcon.png")
                        available = false
                        filename = file.deletingPathExtension().lastPathComponent
                        filename.remove(at: filename.startIndex)
                    } else {
                        thumbnail = getThumbnail(url: file, pageNumber: 0)
                    }
                    let newFile = LocalFile(label: file.lastPathComponent, thumbnail: thumbnail, favorite: "No", filename: file.lastPathComponent, url: file, title: nil, journal: nil, year: nil, category: type, rank: nil, note: "No notes", dateCreated: Date(), dateModified: Date(), author: nil, groups: [nil], parentFolder: folders.lastPathComponent, available: available, filetype: "Miscellaneous")
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
                        localFiles[0][i].year = isStringAnInt(stringNumber: yearString.text!)
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
            
            print(currentPublication.filename)
            print(currentPublication.journal?.name)
//            print(currentPublication.journal?.name)
            
        } else {
            // A FILE FOUND IN FOLDER BUT NOT SAVED INTO CORE DATA
            addFileToCoreData(file: file)
        }
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
//                sortItems()
                
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
        
        mainView.backgroundColor = backgroundColor
        categoriesCV.backgroundColor = backgroundColor
        notesView.backgroundColor = textColor
        notesView.tintColor = barColor
        selectedCategoryTitle.backgroundColor = barColor
        selectedCategoryTitle.textColor = textColor
        segmentedControllTablesOrNotes.tintColor = barColor
        segmentedControllTablesOrNotes.backgroundColor = backgroundColor
        economyView.backgroundColor = backgroundColor
        economyHeader.backgroundColor = barColor
        listTableView.backgroundColor = backgroundColor
        listTableView.tintColor = textColor

        
        filesCollectionView.reloadData()
    }
    
    func populateListTable() {
        switch categories[selectedCategoryNumber] {
        case "Publications":
            sortTableTitles = [String]()
            //FIX: selectedSubtableNumber is maybe not correctly selected when jumping between settings
            
            switch sortSubtableStrings[sortSubtableNumbers[selectedCategoryNumber]] {
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
        case "Manuscripts":
            sortTableTitles = []
            do {
                let folderURLs = try FileManager.default.contentsOfDirectory(at: manuscriptsURL!, includingPropertiesForKeys: nil)
                for folders in folderURLs {
                    sortTableTitles.append(folders.lastPathComponent)
                }
            } catch {
                print("Error while reading manuscript folders")
            }
        case "Economy":
            sortTableTitles = [String]()
            let tmp = projectCD.sorted(by: {$0.name! < $1.name!})
            sortTableTitles = tmp.map { $0.name! }
            
        default:
            print("Default 126")
        }
        
    }
    
    func populateFilesCV() {
        
        filesCV = [[]]
        
        switch categories[selectedCategoryNumber] {
        case "Publications": //LocalFiles[0]
            switch sortSubtableStrings[sortSubtableNumbers[selectedCategoryNumber]] {
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
            
        case "Manuscripts": //localFiles[2]
            filesCV = [[]]

            switch sortSubtableStrings[sortSubtableNumbers[selectedCategoryNumber]] {
            case "Normal view":
                for i in 0..<sortTableTitles.count {
                    for file in localFiles[2] {
                        if file.parentFolder == sortTableTitles[i] {
                            filesCV[i].append(file)
                        }
                    }
                    filesCV[i] = filesCV[i].sorted(by: {($0.filename) < ($1.filename)})
                    if i < sortTableTitles.count {
                        filesCV.append([]) // ADD [] FOR THE NEXT ROUND
                    }
                }
            case "Focused view":

                manuscriptSections = ["Microsoft word", "PDF documents", "Figures", "Presentations", "Matlab files", "Excel", "Miscellaneous"]
                
                for _ in 0..<manuscriptSections.count {
                    filesCV.append([])
                }

                //FIX: NOT FINISHED HERE
                for file in localFiles[2] {
                    if file.parentFolder == sortTableTitles[selectedSubtableNumber] {
                        let components = file.filename.components(separatedBy: ".")
                        
                        switch components.last {
                        case "doc", "docx": //Microsoft word
                            filesCV[0].append(file)
                        case "pdf": //PDFs
                            filesCV[1].append(file)
                        case "jpg", "ai", "png": //Figures
                            filesCV[2].append(file)
                        case "ppt": //Presentations
                            filesCV[3].append(file)
                        case "m": //Matlab
                            filesCV[4].append(file)
                        case "ppx": //Excel
                            filesCV[5].append(file)
                        default: //Miscellaneous
                            filesCV[6].append(file)
                        }
                    }
                }
            default:
                print("Default 138")
            }
            
        case "Proposals": //localFiles[3]
            filesCV = [[]]
            
            switch sortSubtableStrings[sortSubtableNumbers[selectedCategoryNumber]] {
            case "Normal view":
                for i in 0..<sortTableTitles.count {
                    for file in localFiles[3] {
                        if file.parentFolder == sortTableTitles[i] {
                            filesCV[i].append(file)
                        }
                    }
                    if i < sortTableTitles.count {
                        filesCV.append([]) // ADD [] FOR THE NEXT ROUND
                    }
                }
            case "Focused view":
                
                proposalsSections = ["Microsoft word", "PDF documents", "Figures", "Presentations", "Matlab files", "Excel", "Miscellaneous"]
                
                for _ in 0..<manuscriptSections.count {
                    filesCV.append([])
                }
                
                //FIX: NOT FINISHED HERE
                for file in localFiles[3] {
                    if file.parentFolder == sortTableTitles[selectedSubtableNumber] {
                        let components = file.filename.components(separatedBy: ".")
                        
                        switch components.last {
                        case "doc", "docx": //Microsoft word
                            filesCV[0].append(file)
                        case "pdf": //PDFs
                            filesCV[1].append(file)
                        case "jpg", "ai", "png": //Figures
                            filesCV[2].append(file)
                        case "ppt": //Presentations
                            filesCV[3].append(file)
                        case "m": //Matlab
                            filesCV[4].append(file)
                        case "ppx": //Excel
                            filesCV[5].append(file)
                        default: //Miscellaneous
                            filesCV[6].append(file)
                        }
                    }
                }
            default:
                print("Default 138")
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

    
    
    
    
    
    // MARK: - GENERAL FUNCTIONS
    func setupUI() {

        filesDownloading = []
        
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
            filesView.isHidden = true
            sortSTButton.isHidden = true
        default:
            economyView.isHidden = true
            segmentedControllTablesOrNotes.isHidden = false
            economyHeader.isHidden = true
            addNewGroupText.setTitle("New group", for: .normal)
            filesCollectionView.isHidden = false
            filesView.isHidden = false
            sortSTButton.isHidden = false
        }
        
//        journalString.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        
        readIcloudDriveFolders()
        
        setSortTableListStrings()
        setFilesCVSortingStrings()
        
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
            print(currentFile?.year)
            
            // UPDATING CORE DATA
            updateCoreData(file: currentFile!)
            
            // UPDATING ICLOUD
            updateIcloud(file: currentFile!)

            populateListTable()
            populateFilesCV()
//            sortItems()
            listTableView.reloadData()
            filesCollectionView.reloadData()
//        case "Manuscripts":
//            // UPDATING LOCALFILES
//            let currentFile = updateLocalFiles()

        default:
            print("Default 137")
        }
    }
    
    func compareLocalFilesWithDatabase() {
        for i in 0..<localFiles[selectedCategoryNumber].count {
            print("Searching for file: " + localFiles[selectedCategoryNumber][i].filename + " in databases.")

            var icloudMatch = false
            var icloudFile: PublicationFile!
            var coreDataMatch = false
            var coreDataFile: Publication!
            
            //SEARCH ICLOUD
            if icloudAvailable {
                if let matchedIcloudFile = publicationsIC.first(where: {$0.filename == localFiles[0][i].filename}) {
                    icloudFile = matchedIcloudFile
                    icloudMatch = true
                    print("File: " + localFiles[0][i].filename + " found on icloud")
                } else {
                    print("File: " + localFiles[0][i].filename + " not matched with icloud")
                }
            }
            
            //SEARCH COREDATA
            if let matchedCoreDataFile = publicationsCD.first(where: {$0.filename == localFiles[0][i].filename}) {
                coreDataFile = matchedCoreDataFile
                coreDataMatch = true
                print("File: " + localFiles[0][i].filename + " found in coredata")
            } else {
                print("File: " + localFiles[0][i].filename + " not matched with coredata")
            }
            
            if icloudMatch && coreDataMatch {
                if coreDataFile.dateModified! > icloudFile.dateModified! {
                    print("Load 1")
                    updateLocalFilesWithCoreData(index: i, category: selectedCategoryNumber, coreDataFile: coreDataFile)
                } else {
                    print("Load 2")
                    updateLocalFilesWithIcloud(index: i, category: selectedCategoryNumber, icloudFile: icloudFile)
                }
            } else {
                if icloudMatch || coreDataMatch {
                    if icloudMatch {
                        print("Load 3")
                        updateLocalFilesWithIcloud(index: i, category: selectedCategoryNumber, icloudFile: icloudFile)
                    } else {
                        print("Load 4")
                        updateLocalFilesWithCoreData(index: i, category: selectedCategoryNumber, coreDataFile: coreDataFile)
                    }
                } else {
                    print("Load 5")
                    addFileToCoreData(file: localFiles[0][i])
                }
            }

            
        }
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
                print(journal)
                localFiles[category][index].journal = journal
            } else {
                print("No journal found")
                localFiles[category][index].journal = "No journal"
            }

            localFiles[category][index].favorite = "No"
            for group in currentCoreDataFile.publicationGroup?.allObjects as! [PublicationGroup] {
                localFiles[category][index].groups.append(group.tag)
                if group.tag == "Favorites" {
                    localFiles[category][index].favorite = "Yes"
                }
            }
            
            
            
            print("Core data file: " + localFiles[category][index].filename)
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
    
    func loadFile() {
        let fileManager = FileManager.default
        iCloudURL = fileManager.url(forUbiquityContainerIdentifier: nil)
        guard iCloudURL != nil else {
            print("Unable to access iCloud account")
            return
        }
        iCloudURL = iCloudURL?.appendingPathComponent("Documents/savefile.txt")
        metaDataQuery = NSMetadataQuery()
//        metaDataQuery?.predicate = NSPredicate(format: "%K like 'savefile.txt'", NSMetadataItemFSNameKey)
        metaDataQuery?.predicate = NSPredicate(format: "%K ENDSWITH '.pdf'", NSMetadataItemFSNameKey)
//        metaDataQuery?.predicate = NSPredicate(format: "%K.pathExtension = '.'", NSMetadataItemFSNameKey)
        
        metaDataQuery?.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.metadataQueryDidFinishGathering), name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: metaDataQuery!)
        metaDataQuery?.start()
        
    }

    func copyDocumentsToiCloudDrive() {
        var error: NSError?
        let iCloudDocumentsURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents/myCloudTest")
        print(iCloudDocumentsURL!)
        do {
            //is iCloud working?
            if  iCloudDocumentsURL != nil {
                //Create the Directory if it doesn't exist
                if (!FileManager.default.fileExists(atPath: iCloudDocumentsURL!.path, isDirectory: nil)) {
                    //This gets skipped after initial run saying directory exists, but still don't see it on iCloud
                    try FileManager.default.createDirectory(at: iCloudDocumentsURL!, withIntermediateDirectories: true, attributes: nil)
                    print("Directory created")
                }
            } else {
                print("iCloud is NOT working!")
                //  return
            }
            
            if error != nil {
                print("Error creating iCloud DIR")
            }
//
//            //Set up directorys
//            let localDocumentsURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: .userDomainMask).last! as NSURL
//
//            //Add txt file to my local folder
//            let myTextString = NSString(string: "HELLO WORLD")
//            let myLocalFile = localDocumentsURL.appendingPathComponent("myTextFile.txt")
//            _ = try myTextString.write(to: myLocalFile!, atomically: true, encoding: String.Encoding.utf8.rawValue)
//
//            if ((error) != nil){
//                print("Error saving to local DIR")
//            }
//
//            //If file exists on iCloud remove it
//            var isDir:ObjCBool = false
//            if (FileManager.default.fileExists(atPath: iCloudDocumentsURL!.path, isDirectory: &isDir)) {
//                try FileManager.default.removeItem(at: iCloudDocumentsURL!)
//            }
//
//            //copy from my local to iCloud
//            if error == nil {
//                try FileManager.default.copyItem(at: localDocumentsURL as URL, to: iCloudDocumentsURL!)
//            }
        } catch {
            print("Error creating a file")
        }
        
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            currentFilename = url.lastPathComponent
            switch categories[selectedCategoryNumber] {
            case "Publications":
                if publicationsCD.first(where: {$0.filename == currentFilename}) == nil {
                    documentURL = url
                    
                    let thumbnail = getThumbnail(url: url, pageNumber: 0)
                    
                    largeThumbnail.image = thumbnail
                    filenameString.text = url.lastPathComponent
                    journalString.text = "No journal"
                    yearString.text = "-2000"
                    authorString.text = "No author"
                    notesString.text = "No notes yet"
                    rankOutlet.value = 0
                    rankValue.text = "0"
                    documentPage = 0
                    
                    downloadFile(fileURL: url)
//                    addFileToCoreData()
                    saveToIcloud(url: url)

                    filesCollectionView.reloadData()
                } else {
                    alert(title: "File already exists", message: "You have already imported " + currentFilename)
                }
            default:
                print("108")
            }

//            PDFdocument = PDFDocument(url: url)
//
////            performSegue(withIdentifier: "seguePDFViewController", sender: self)

        }
    }
    
    func isStringAnInt(stringNumber: String?) -> Int16 {
        let number = stringNumber!.replacingOccurrences(of: "\"", with: "")
        if let tmpValue = Int16(number) {
            return tmpValue
        }
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
        if (segue.identifier == "segueSortCV") {
            setFilesCVSortingStrings()
            let destination = segue.destination as! SortItemsViewController
            if sortCollectionViewNumbers[selectedCategoryNumber] > sortCollectionViewStrings.count {
                sortCollectionViewNumbers[selectedCategoryNumber] = 0
            }
            destination.sortValue = sortCollectionViewNumbers[selectedCategoryNumber]
            destination.sortStrings = sortCollectionViewStrings
            destination.preferredContentSize = sortCollectionViewBox
            destination.popoverPresentationController?.sourceRect = sortCVButton.bounds
        }
        if (segue.identifier == "segueSortSubtable") {
            setSortTableListStrings()
            let destination = segue.destination as! SortSubtableViewController
            if sortSubtableNumbers[selectedCategoryNumber] > sortSubtableStrings.count {
                sortSubtableNumbers[selectedCategoryNumber] = 0
            }
            destination.sortValue = sortSubtableNumbers[selectedCategoryNumber]
            destination.sortStrings = sortSubtableStrings
            destination.preferredContentSize = sortCollectionViewBox
            destination.popoverPresentationController?.sourceRect = sortSTButton.bounds
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
    }
    
    public func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        
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
        var pageThumbnail = #imageLiteral(resourceName: "fileIcon.png")
        if let document = PDFDocument(url: url) {
            let page: PDFPage!
            page = document.page(at: pageNumber)!
            pageThumbnail = page.thumbnail(of: CGSize(width: 210, height: 297), for: .artBox)
        }
        return pageThumbnail
    }
    
    func sortItems() {
        
        // New approach, always arrange alphabetically
        switch categories[selectedCategoryNumber] {
        case "Publications":
            filesCV[selectedSubtableNumber] = filesCV[selectedSubtableNumber].sorted(by: {($0.filename) < ($1.filename)})
        case "Manuscript":
            for i in 0..<filesCV.count {
                filesCV[i] = filesCV[i].sorted(by: {($0.filename) < ($1.filename)})
            }
        default:
            filesCV[selectedSubtableNumber] = filesCV[selectedSubtableNumber].sorted(by: {($0.filename) < ($1.filename)})
        }
//            //FIX: selectedSubtableNumber is maybe not correctly selected when jumping between settings
//            print("Sorting collectionView")
//            print(sortCollectionViewNumbers)
//            print(selectedCategoryNumber)
//            print(sortCollectionViewStrings[sortCollectionViewNumbers[selectedCategoryNumber]])
//
//            switch sortCollectionViewStrings[sortCollectionViewNumbers[selectedCategoryNumber]] {
//            case "Filename":
//                if !filesCV[selectedSubtableNumber].isEmpty {
//                    filesCV[selectedSubtableNumber] = filesCV[selectedSubtableNumber].sorted(by: {($0.filename) < ($1.filename)})
//                }
//            case "Title":
//                if !filesCV[selectedSubtableNumber].isEmpty {
//                    filesCV[selectedSubtableNumber] = filesCV[selectedSubtableNumber].sorted(by: {$0.title! < $1.title!})
//                }
//            case "Year":
//                if !filesCV[selectedSubtableNumber].isEmpty {
//                    filesCV[selectedSubtableNumber] = filesCV[selectedSubtableNumber].sorted(by: {$0.year! < $1.year!})
//                }
//            case "Author":
//                if !filesCV[selectedSubtableNumber].isEmpty {
//                    filesCV[selectedSubtableNumber] = filesCV[selectedSubtableNumber].sorted(by: {($0.author)! < ($1.author)!})
//                }
//            case "Date modified":
//                if !filesCV[selectedSubtableNumber].isEmpty {
//                    filesCV[selectedSubtableNumber] = filesCV[selectedSubtableNumber].sorted(by: {$0.dateModified! < $1.dateModified!})
//                }
//            case "Rank":
//                if !filesCV[selectedSubtableNumber].isEmpty {
//                    filesCV[selectedSubtableNumber] = filesCV[selectedSubtableNumber].sorted(by: {$0.rank! < $1.rank!})
//                }
//            default:
//                filesCV[selectedSubtableNumber] = filesCV[selectedSubtableNumber].sorted(by: {($0.filename) < ($1.filename)})
//            }
//        case "Manuscripts":
//            for i in 0..<filesCV.count {
//                filesCV[i] = filesCV[i].sorted(by: {($0.filename) < ($1.filename)})
//            }
//        default:
//            print("Default sortItems 102")
//        }

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
    
    func setSortTableListStrings() {
        switch categories[selectedCategoryNumber] {
        case "Publications":
            sortSubtableStrings = ["Tag", "Author", "Journal", "Year", "Rank"]
        case "Manuscripts":
            sortSubtableStrings = ["Normal view", "Focused view"]
        default:
            sortSubtableStrings = ["Normal view", "Focused view"]
        }

    }
    
    func setFilesCVSortingStrings() {
        switch categories[selectedCategoryNumber] {
        case "Publications":
            sortCollectionViewStrings = ["Filename", "Author", "Journal", "Year", "Rank"]
        case "Manuscripts":
            sortCollectionViewStrings = ["Filename", "Rank"]
        default:
            sortCollectionViewStrings = ["Filename", "Rank"]
        }
        
    }
    
    func populateExpenses() {
        let currentProject = projectCD[selectedSubtableNumber]

        let expenses = expensesCD.sorted(by: {$0.dateAdded! < $1.dateAdded!})
        expensesTableView.reloadData()
        
//        let currentExpenses = currentProject.expense
//        print(currentExpenses)
    }
    
    
    
    
    
    // MARK: - Table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        var number = 0
        if tableView == self.expensesTableView {
            if selectedSubtableNumber < projectCD.count {
                number = (projectCD[selectedSubtableNumber].expense?.count)!
            } else {
                number = 0
            }
            
        } else if tableView == self.listTableView {
            switch categories[selectedCategoryNumber] {
            case "Publications":
                number = sortTableTitles.count
                
            case "Economy":
                number = projectCD.count
                
            default:
                print("Default 135")
                number = 0
            }
        }
        return number
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cellToReturn = UITableViewCell()
        
        if tableView == self.expensesTableView {
            let cell = expensesTableView.dequeueReusableCell(withIdentifier: "economyCell") as! EconomyCell
            let currentProject = projectCD[selectedSubtableNumber]
            if indexPath.row == 0 {
                currentProject.amountRemaining = currentProject.amountReceived
            }
            let expenses = currentProject.expense?.allObjects as! [Expense]
            cell.expenseAmount.text = "\(expenses[indexPath.row].amount)"
            cell.overheadAmount.text = "\(expenses[indexPath.row].overhead)"
            cell.commentString.text = expenses[indexPath.row].comment
            cell.referenceString.text = expenses[indexPath.row].reference
            print(indexPath.row)
            print(currentProject.amountRemaining)
            currentProject.amountRemaining = currentProject.amountRemaining - expenses[indexPath.row].amount
            print(currentProject.amountRemaining)
            amountRemainingString.text = "\(currentProject.amountRemaining)"
            
            cellToReturn = cell
            
        } else if tableView == self.listTableView {

            let cell = listTableView.dequeueReusableCell(withIdentifier: "listTableCell") as! ListCell
            
            switch categories[selectedCategoryNumber] {
            case "Publications":
                cell.listLabel.text = sortTableTitles[indexPath.row]
                cell.listNumberOfItems.text = "\(filesCV[indexPath.row].count)"
                
            case "Economy":
                cell.listLabel.text = sortTableTitles[indexPath.row]
                cell.listNumberOfItems.text = ""
                
            case "ManuscriptsX": //FIX: Miss-spelled on purpose
                cell.listLabel.text = sortTableTitles[indexPath.row]
                cell.listNumberOfItems.text = "\(filesCV[indexPath.row].count)"
                
            default:
                cell.listLabel.text = "Nothing yet..."
                cell.listNumberOfItems.text = "0 items"
            }
            cellToReturn = cell
        }
        
        return cellToReturn
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        selectedSubtableNumber = indexPath.row
        
        if tableView == self.expensesTableView {
            print("Default 148")
        } else if tableView == self.listTableView {
            switch categories[selectedCategoryNumber] {
            case "Publications":
                if filesCV[indexPath.row].count > 0 {
                    let cvIndexPath = IndexPath(item: 0, section: indexPath.row)
                    self.filesCollectionView.scrollToItem(at: cvIndexPath, at: .top, animated: true)
                }
                
            case "Economy":
                let currentProject = projectCD[selectedSubtableNumber]
                currencyString.text = currentProject.currency
                amountReceivedString.text = "\(currentProject.amountReceived)"
                amountRemainingString.text = "\(currentProject.amountRemaining)"
                
                self.expensesTableView.reloadData()
                
            case "ManuscriptsX": //FIX: Miss-spelled on purpose
                if sortSubtableStrings[sortSubtableNumbers[selectedCategoryNumber]] == "Normal view" {
                    // FIX: IF NO FILES EXISTS IN SECTION, cvIndexPath CANNOT BE CREATED (FIXED?)
                    if filesCV[indexPath.row].count > 0 {
                        let cvIndexPath = IndexPath(item: 0, section: indexPath.row)
                        self.filesCollectionView.scrollToItem(at: cvIndexPath, at: .top, animated: true)
                    }
                } else {
                    populateFilesCV()
                    filesCollectionView.reloadData()
                }
            default:
                print("Default 146")
            }
        }
        
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        if tableView == self.listTableView {
            switch categories[selectedCategoryNumber] {
            case "Publications":
                if let row = coordinator.destinationIndexPath?.row {
                    switch sortSubtableStrings[sortSubtableNumbers[selectedSubtableNumber]] {
                    case "Tag":
                        let groupName = sortTableTitles[row]
                        if let filename = coordinator.items[0].dragItem.localObject {
                            if let dragedPublication = filesCV[selectedSubtableNumber].first(where: {$0.filename == filename as! String}) {
                                if let group = publicationGroupsCD.first(where: {$0.tag! == groupName}) {
                                    addPublicationToGroup(filename: (dragedPublication.filename), group: group)
                                }
                            }
                        }
                    case "Author":
                        let authorName = sortTableTitles[row]
                        if let filename = coordinator.items[0].dragItem.localObject {
                            if let dragedPublication = filesCV[selectedSubtableNumber].first(where: {$0.filename == filename as! String}) {
                                assignPublicationToAuthor(filename: (dragedPublication.filename), authorName: authorName)
                            }
                        }
                    case "Journal":
                        let journalName = sortTableTitles[row]
                        if let filename = coordinator.items[0].dragItem.localObject {
                            if let dragedPublication = filesCV[selectedSubtableNumber].first(where: {$0.filename == filename as! String}) {
                                assignPublicationToJournal(filename: (dragedPublication.filename), journalName: journalName)
                            }
                        }
                    case "Year":
                        let year = sortTableTitles[row]
                        if let filename = coordinator.items[0].dragItem.localObject {
                            if let dragedPublication = filesCV[selectedSubtableNumber].first(where: {$0.filename == filename as! String}) {
                                
                                //                            assignPublicationToJournal(filename: (dragedPublication.filename), journalName: journalName)
                            }
                        }
                    default:
                        print("Default 141")
                    }
                }
            case "Manuscripts":
                print("Manuscripts")
            default:
                print("Default 142")
            }
            
            
            populateFilesCV()
//            sortItems()
            listTableView.reloadData()
            filesCollectionView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        var returnBool = false
        
        if tableView == self.listTableView {
            switch categories[selectedCategoryNumber] {
            case "Publications":
                switch sortSubtableStrings[sortSubtableNumbers[selectedCategoryNumber]] {
                case "Tag":
                    if indexPath.row > 1 {
                        returnBool = true
                    } else {
                        returnBool = false
                    }
                case "Author":
                    if indexPath.row > 0 {
                        returnBool = true
                    } else {
                        returnBool = false
                    }
                case "Journal":
                    if indexPath.row > 1 {
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
                    switch sortSubtableStrings[sortSubtableNumbers[selectedSubtableNumber]] {
                    case "Tag":
                        let groupName = sortTableTitles[indexPath.row]
                        let groupToDelete = publicationGroupsCD.first(where: {$0.tag! == groupName})
                        context.delete(groupToDelete!)
                        saveCoreData()
                        loadCoreData()
                        
                    case "Author":
                        let noAuthor = authorsCD.first(where: {$0.name == "No author"})
                        let authorName = sortTableTitles[indexPath.row]
                        let authorToDelete = authorsCD.first(where: {$0.name! == authorName})
                        let articlesBelongingToAuthor = authorToDelete?.publication
                        context.delete(authorToDelete!)
                        for item in articlesBelongingToAuthor! {
                            let tmp = item as! Publication
                            tmp.author = noAuthor
                        }
                        
                        saveCoreData()
                        loadCoreData()
                        
                    default:
                        print("Default 103")
                    }
                    
                    populateListTable()
                    populateFilesCV()
                    //                sortItems()
                    
                    listTableView.reloadData()
                    filesCollectionView.reloadData()

                case "Economy":
                    let currentProject = sortTableTitles[indexPath.row]
                    let projectToDelete = projectCD.first(where: {$0.name! == currentProject})
                    context.delete(projectToDelete!)
                    
                    saveCoreData()
                    loadCoreData()

                    populateListTable()
                    categoriesCV.reloadData()
                    listTableView.reloadData()
                    expensesTableView.reloadData()
                    
                default:
                    print("Default 104")
                }
                
                
            } else if tableView == self.expensesTableView {
                let currentProject = projectCD[selectedSubtableNumber]
                var expenses = currentProject.expense?.allObjects as! [Expense]
                
                amountRemainingString.text = amountReceivedString.text
                
                let expenseToRemove = expensesCD.first(where: {$0.dateAdded! == expenses[indexPath.row].dateAdded!})
                context.delete(expenseToRemove!)
                
                saveCoreData()
                loadCoreData()
                
                expensesTableView.reloadData()
            }
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
//            case "Manuscripts":
//                return filesCV[section].count
            default:
                return 0
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.categoriesCV {
            print(categories[indexPath.row])
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

            case "Patents":
                cell.icon.image = #imageLiteral(resourceName: "PatentsIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "PatentsIconSelected")
                cell.number.text = "\(localFiles[3].count)"
                
            case "Proposals":
                cell.icon.image = #imageLiteral(resourceName: "ProposalsIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "ProposalsIconSelected")
                cell.number.text = "\(localFiles[4].count)"
                
            case "Presentations":
                cell.icon.image = #imageLiteral(resourceName: "PresentationsIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "PresentationsIconSelected")
                cell.number.text = "\(localFiles[5].count)"
                
            case "Teaching":
                cell.icon.image = #imageLiteral(resourceName: "TeachingIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "TeachingIconSelected")
                cell.number.text = "\(localFiles[6].count)"
                
            case "Supervision":
                cell.icon.image = #imageLiteral(resourceName: "SupervisionIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "SupervisionIconSelected")
                cell.number.text = "0" // FIX
                
            case "Miscellaneous":
                cell.icon.image = #imageLiteral(resourceName: "MiscellaneousIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "MiscellaneousIconSelected")
                cell.number.text = "0" // FIX
                
            default:
                print("Default 144")
                cell.icon.image = #imageLiteral(resourceName: "PublicationsIcon")
                cell.number.text = "0"
            }
            
            selectedCategoryTitle.text = categories[selectedCategoryNumber]
            
//            cell.number.text = "\(localFiles[indexPath.row].count)"
            
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
            switch categories[selectedCategoryNumber] {
            case "Publications":
                cell.hiddenFilename.text = filesCV[indexPath.section][indexPath.row].filename
                cell.thumbnail.image = filesCV[indexPath.section][indexPath.row].thumbnail
                cell.label.text = filesCV[indexPath.section][indexPath.row].filename

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
                
                if cell.hiddenFilename.text == currentSelectedFilename {
                    cell.selectedFileFrame.isHidden = false
                } else {
                    cell.selectedFileFrame.isHidden = true
                }

                
//                switch sortCollectionViewStrings[sortCollectionViewNumbers[selectedCategoryNumber]] {
//
//                case "Filename", "Year", "Author", "Date modified", "Rank":
//                    cell.label.text = filesCV[indexPath.section][indexPath.row].filename
//
//                case "Title":
//                    cell.label.text = filesCV[indexPath.section][indexPath.row].title
//
//                default:
//                    cell.label.text = "Error"
//                    cell.thumbnail.image = #imageLiteral(resourceName: "PublicationIcon@1x.png")
//                    cell.favoriteIcon.setImage(#imageLiteral(resourceName: "FavoriteOff"), for: .normal)
//
//                }
                
            case "ManuscriptsX": //FIX: Miss-spelled on purpose
                cell.label.text = filesCV[indexPath.section][indexPath.row].filename
                cell.hiddenFilename.text = filesCV[indexPath.section][indexPath.row].filename
                cell.thumbnail.image = filesCV[indexPath.section][indexPath.row].thumbnail

                if filesCV[indexPath.section][indexPath.row].available {
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
        currentIndexPath = indexPath
        if collectionView == self.categoriesCV {
            selectedCategoryTitle.text = categories[indexPath.row]
            selectedCategoryNumber = indexPath.row
            selectedSubtableNumber = 0 //FIX: Does this work? Maybe it should not be reset?
            
//            kvStorage.set(selectedCategoryNumber, forKey: "selectedCategory")
            kvStorage.set(selectedCategoryNumber, forKey: "selectedCategory")
            kvStorage.synchronize()
            
            let selectedOption = segmentedControllTablesOrNotes.titleForSegment(at: segmentedControllTablesOrNotes.selectedSegmentIndex)
            switch selectedOption! {
            case "List":
                notesView.isHidden = true
                filesView.isHidden = true
                
            case "Notes":
                switch categories[selectedCategoryNumber] {
                case "Publications":
                    notesView.isHidden = false
                    filesView.isHidden = true
                case "Manuscripts", "Proposals", "Presentations":
                    notesView.isHidden = true
                    filesView.isHidden = false
                case "Economy":
                    notesView.isHidden = true
                    filesView.isHidden = true
                default:
                    notesView.isHidden = false
                    filesView.isHidden = true
                }
                
            default:
                print("Default 141")
            }
            
            switch categories[selectedCategoryNumber] {
            case "Economy":
                self.economyView.isHidden = false
                self.filesCollectionView.isHidden = true
                self.segmentedControllTablesOrNotes.isHidden = true
                self.economyHeader.isHidden = false
                self.addNewGroupText.setTitle("New project", for: .normal)
                self.filesView.isHidden = true
                self.sortSTButton.isHidden = true
            default:
                self.economyView.isHidden = true
                self.filesCollectionView.isHidden = false
                self.segmentedControllTablesOrNotes.isHidden = false
                self.economyHeader.isHidden = true
                self.addNewGroupText.setTitle("New group", for: .normal)
                self.filesView.isHidden = false
                self.sortSTButton.isHidden = false
            }
            
            
            setSortTableListStrings()
            setFilesCVSortingStrings()
            
            populateListTable()
            populateFilesCV()
//            sortItems()
            listTableView.reloadData()
            filesCollectionView.reloadData()
            
        } else {
            let currentCell = collectionView.cellForItem(at: indexPath) as! FilesCell
            
            if editingFilesCV {
                
                if sortTableTitles[indexPath.section] != "All publications" {
                    for i in 0..<localFiles[0].count {
                        if localFiles[0][i].filename == currentCell.hiddenFilename.text {
                            let newGroups = localFiles[0][i].groups.filter { $0 !=  sortTableTitles[indexPath.section]}
                            localFiles[0][i].groups = newGroups
                            updateIcloud(file: localFiles[0][i])
                        }
                    }
                    if let currentPublication = publicationsCD.first(where: {$0.filename == currentCell.hiddenFilename.text}) {
                        if let group = publicationGroupsCD.first(where: {$0.tag == sortTableTitles[indexPath.section]}) {
                            currentPublication.removeFromPublicationGroup(group)
                            saveCoreData()
                            loadCoreData()
                        }
                    }
                    
                }
                
                populateFilesCV()
//                sortItems()
                
                listTableView.reloadData()
                filesCollectionView.reloadData()
                

            } else {
                
                if currentCell.fileOffline.isHidden == false {
                    print("Downloading " + currentCell.hiddenFilename.text!)
                    let fileManager = FileManager.default
                    let fileURL = publicationsURL.appendingPathComponent("." + currentCell.hiddenFilename.text! + ".icloud")
                    do {
                        try fileManager.startDownloadingUbiquitousItem(at: fileURL)
                        let newDownload = DownloadingFile(filename: currentCell.hiddenFilename.text!, url: fileURL, downloaded: false)
                        filesDownloading.append(newDownload)
                        downloadTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(checkIfFileIsDownloaded), userInfo: nil, repeats: true)
                        activityIndicator.startAnimating()
                    } catch let error {
                        print(error)
                    }
                }
                
                for i in 0..<localFiles[0].count {
                    if localFiles[0][i].filename == currentCell.hiddenFilename.text {
                        currentSelectedFilename = currentCell.hiddenFilename.text
                        currentCell.selectedFileFrame.isHidden = false
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
                filesCollectionView.reloadData() //Needed to show currently selected file
                
            }


            
            documentPage = 0

            switch self.categories[self.selectedCategoryNumber] {
            case "Publications":
                documentURL = self.publicationsURL.appendingPathComponent(currentCell.hiddenFilename.text!)
            default:
                print("103")
            }

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
            case "ManuscriptsX": //FIX: Miss-spelled on purpose
                switch sortSubtableStrings[sortSubtableNumbers[selectedCategoryNumber]] {
                case "Normal view":
                    return sortTableTitles.count
                case "Focused view":
                    return manuscriptSections.count
                default:
                    return sortTableTitles.count
                }
            default:
                return 0 //sortTableTitles.count
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let sectionHeaderView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "collectionViewHeader", for: indexPath) as! SectionHeaderView
        
        sectionHeaderView.backgroundColor = barColor
        sectionHeaderView.tintColor = textColor
        
        switch categories[selectedCategoryNumber] {
        case "Publications":
            sectionHeaderView.mainHeaderTitle.text = sortTableTitles[indexPath[0]]
            sectionHeaderView.subHeaderTitle.text = "\(filesCV[indexPath[0]].count)" + " items"
        case "Manuscripts":
            if sortSubtableStrings[sortSubtableNumbers[selectedCategoryNumber]] == "Normal view" {
                sectionHeaderView.mainHeaderTitle.text = sortTableTitles[indexPath[0]]
                sectionHeaderView.subHeaderTitle.text = "\(filesCV[indexPath[0]].count)" + " items"
            } else {
                sectionHeaderView.mainHeaderTitle.text = manuscriptSections[indexPath[0]]
                sectionHeaderView.subHeaderTitle.text = "\(filesCV[indexPath[0]].count)" + " items"
            }
        default:
            print("Default 136")
        }
        
        switch currentTheme {
        case 0:
            sectionHeaderView.backgroundColor = UIColor(red: 146/255, green: 144/255, blue: 0, alpha: 1)
            sectionHeaderView.tintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        case 1:
            sectionHeaderView.backgroundColor = UIColor(red: 146/255, green: 144/255, blue: 0, alpha: 1)
            sectionHeaderView.tintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        case 2:
            sectionHeaderView.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
            sectionHeaderView.tintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        default:
            sectionHeaderView.backgroundColor = UIColor(red: 146/255, green: 144/255, blue: 0, alpha: 1)
            sectionHeaderView.tintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        }

        
        
        return sectionHeaderView
    }
    
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}








extension UISegmentedControl {
    func replaceSegments(segments: Array<String>) {
        self.removeAllSegments()
        for segment in segments {
            self.insertSegment(withTitle: segment, at: self.numberOfSegments, animated: false)
        }
    }
}

extension URL {
    var typeIdentifier: String? {
        return (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier
    }
    var localizedName: String? {
        return (try? resourceValues(forKeys: [.localizedNameKey]))?.localizedName
    }
}



// MARK: - IBDesignables
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


//        let id = CKRecordID(recordName: "FRAME")
//        let newPublication = CKRecord(recordType: "Publications")//, recordID: id)
//        newPublication.setValue(publications, forKey: "test")
//        database.save(newPublication) { (record, error) in
//            print(error)
//            guard record != nil else {return}
//            print("Saved to icloud")
//        }

//        var authors = [String]()
//        authors.append("John")
//        authors.append("Elias")
//        authors.append("Edouard")
//
//        let id = CKRecordID(recordName: "FRAME")
//        let newPublication = CKRecord(recordType: "Authors", recordID: id)
//        newPublication.setValue(publications, forKey: "Author")
//        database.save(newPublication) { (record, error) in
//            guard record != nil else {return}
//            print("Saved to icloud")
//        }
//        newPublication.setObject(publications as NSArray, forKey: "content")



//        document?.updateChangeCount(.done)
//    }




//                            filesCV.append(newFile)
//                            var newFile = PublicationFile(filename: file.lastPathComponent, title: "", year: -2000, thumbnails: [thumbnail], category: "Publications", rank: 50, note: "No notes", dateCreated: Date(), dateModified: Date(), favorite: "No", author: "No author", groups: ["All publications", "Unfiled"])

// Reading from core data here
//                            if let publication = publicationsCD.first(where: {$0.filename == newFile.filename}) {
//                                newFile.year = publication.year
//                                newFile.title = publication.title
//                                newFile.rank = publication.rank
//                                newFile.note = publication.note
//                                newFile.dateCreated = publication.dateCreated!
//                                newFile.dateModified = publication.dateModified
//                                newFile.favorite = publication.favorite
//                                if let author = publication.author?.name {
//                                    newFile.author = author
//                                } else {
//                                    let noAuthor = authorsCD.first(where: {$0.name! == "No author"})
//                                    newFile.author = noAuthor?.name
//                                }
//                                for group in publication.publicationGroup?.allObjects as! [PublicationGroup] {
//                                    newFile.groups.append(group.tag)
//                                }
//                            }
//                            publicationFiles.append(newFile)


//func checkIfFileExists(filename: String, url: URL, category: String) {
//    let alertController = UIAlertController(title: "File " + filename + " already exists", message: nil, preferredStyle: .alert)
//
//    alertController.addTextField(configurationHandler: { (textField: UITextField) -> Void in
//        textField.placeholder = filename
//    })
//
//    let okAction = UIAlertAction(title: "Ok", style: .default ) { (_) in
//        self.currentFilename = self.textField.text
//        if self.publications.first(where: {$0.filename == self.currentFilename}) == nil {
//
//        } else {
//
//        }
//    }
//
//    let cancelAction = UIAlertAction(title: "Cancel", style: .default ) { (_) in }
//
//    alertController.addAction(okAction)
//    alertController.addAction(cancelAction)
//
//    self.present(alertController, animated: true, completion: nil)
//}


////THE PUBLICATION IS ADDED, NOT UPDATED
//func updateCoreDataWithLocalFiles(index: Int, category: Int) {
//    switch category {
//    case 0:
//        let newPublication = Publication(context: context)
//
//        newPublication.filename = localFiles[category][index].filename
//        newPublication.thumbnail = localFiles[category][index].thumbnail
//        newPublication.dateCreated = localFiles[category][index].dateCreated!
//        newPublication.dateModified = localFiles[category][index].dateModified!
//        newPublication.title = localFiles[category][index].title!
//        newPublication.year = localFiles[category][index].year!
//        newPublication.note = localFiles[category][index].note!
//
//        let noAuthor = authorsCD.first(where: {$0.name == "No author"})
//        if localFiles[category][index].author == "No author" {
//            newPublication.author = noAuthor
//        } else {
//            if authorsCD.first(where: {$0.name == localFiles[category][index].author}) == nil {
//                let newAuthor = Author(context: context)
//                newAuthor.name = localFiles[category][index].author!
//                newAuthor.sortNumber = "1"
//                print("Added new author: " + newAuthor.name!)
//                newPublication.author = newAuthor
//            } else {
//                newPublication.author = authorsCD.first(where: {$0.name == localFiles[category][index].author})
//            }
//        }
//
//        newPublication.favorite = localFiles[category][index].favorite
//
//        for group in localFiles[category][index].groups {
//            if publicationGroupsCD.first(where: {$0.tag == group}) == nil {
//                let newGroup = PublicationGroup(context: context)
//                newGroup.tag = group
//                newGroup.sortNumber = "3"
//                newGroup.dateModified = Date()
//                print("Added new group: " + newGroup.tag!)
//                newPublication.addToPublicationGroup(newGroup)
//            } else {
//                newPublication.addToPublicationGroup(publicationGroupsCD.first(where: {$0.tag == group})!)
//            }
//        }
//
//        publicationsCD.append(newPublication)
//
//        saveCoreData()
//        loadCoreData()
//
//        print("Saved " + newPublication.filename! + " to core data.")
//    default:
//        print("Default 132")
//    }
//}
