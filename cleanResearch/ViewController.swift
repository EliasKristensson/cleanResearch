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
}

struct File {
    var thumbnail: UIImage
    var label: String
    var hiddenLabel: String
    var favorite: String
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
    @IBOutlet weak var icloudSync: UIButton!
    
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
    var publicationGroupsCD: [PublicationGroup] = []
    
    var currentPublication: Publication!
    var currentAuthor: Author!
    var currentGroup: PublicationGroup!
    var currentIndexPath: IndexPath!

    
//    let database = CKContainer.default().privateCloudDatabase
//    var articles = [CKRecord]()
    
    // MARK: - iCloud variables
    var documentURL: URL!
    var documentPage = 0
    var iCloudURL: URL!
    var kvStorage: NSUbiquitousKeyValueStore!
    var publicationsURL: URL!
    var manuscriptsURL: URL!
    var metaDataQuery: NSMetadataQuery?
    var metaData: NSMetadataQuery!
    var publicationsIC: [PublicationFile] = []
    var icloudAvailable = false
    
    // MARK: - UI variables
    let documentInteractionController = UIDocumentInteractionController()
    let categories: [String] = ["Publications", "Manuscripts", "Presentations", "Proposals", "Supervision", "Teaching", "Patents"]
    var settingsCollectionViewBox = CGSize(width: 250, height: 300)
    var currentTheme: Int = 0
    
    var sortCollectionViewBox = CGSize(width: 348, height: 28)
    var sortCollectionViewNumbers: [Int] = [0, 0, 0, 0, 0, 0, 0]
    var sortCollectionViewStrings: [String] = ["Filename", "Title", "Year", "Author", "Rank"]
    var selectedCategoryNumber = 0

    var localFiles: [[LocalFile]] = [[]]
    var filesCV: [[LocalFile]] = [[],[],[],[],[],[],[],[]] //Place files to be displayed in collection view here
    var sortSubtableStrings: [String] = ["Tag", "Author", "Year", "Rank"]
    var sortSubtableNumbers: [Int] = [0, 0, 0, 0, 0, 0, 0]
    var selectedSubtableNumber = 0
    var sortTableTitles: [String] = [""]

    var yearsString: [String] = [""]
    
    var currentFilename: String = ""
//    var publicationFiles = [PublicationFile]()
    var dateFormatter = DateFormatter()
    
    var PDFdocument: PDFDocument!
    var PDFfilename: String!
    
    var manuscriptSections = ["Manuscript files", "Figures", "Matlab files", "Miscellaneous"]
    
    // MARK: - Outlets
    @IBOutlet var mainView: UIView!
    
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
    @IBOutlet weak var focusedViewButton: UISwitch!
    @IBOutlet weak var focusedViewText: UILabel!
    
    @IBOutlet weak var largeThumbnail: UIImageView!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var filenameString: UITextField!
    @IBOutlet weak var titleString: UITextField!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var authorString: UITextField!
    @IBOutlet weak var yearString: UITextField!
    @IBOutlet weak var rankValue: UILabel!
    @IBOutlet weak var rankOutlet: UISlider!
    @IBOutlet weak var fileTypePicker: UIPickerView!
    
    @IBOutlet weak var settingsButton: UIButton!
    
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
        let cell = self.filesCollectionView.cellForItem(at: currentIndexPath!) as? FilesCell
        var localFileIndex = Int()

        switch categories[selectedCategoryNumber] {
        case "Publications":
            
            if (cell?.favoriteIcon.isHidden)! {
                cell?.favoriteIcon.isHidden = false
                cell?.favoriteIcon.setImage(#imageLiteral(resourceName: "FavoriteOn"), for: .normal)
                favoriteButton.setImage(#imageLiteral(resourceName: "FavoriteOn"), for: .normal)
                for i in 0..<localFiles[0].count {
                    if localFiles[0][i].filename == cell?.hiddenFilename.text {
                        localFileIndex = i
                        localFiles[0][i].favorite = "Yes"
                    }
                }
                //FIX: Localfiles have entries that are not in Core data.
                if let favoritesGroup = publicationGroupsCD.first(where: {$0.tag == "Favorites"}) {
                    if let currentPublication = publicationsCD.first(where: {$0.filename == cell?.hiddenFilename.text}) {
                        currentPublication.addToPublicationGroup(favoritesGroup) // currentPublication exists
                        currentPublication.favorite = "Yes"
                    } else {
                        addFileToCoreData(file: localFiles[0][localFileIndex])
                    }
                }
                
            } else {
                cell?.favoriteIcon.isHidden = true
                favoriteButton.setImage(#imageLiteral(resourceName: "FavoriteOff"), for: .normal)
                if let currentPublication = publicationsCD.first(where: {$0.filename == cell?.hiddenFilename.text}) {
                    currentPublication.favorite = "No"
                }
                if let favoritesGroup = publicationGroupsCD.first(where: {$0.tag == "Favorites"}) {
                    currentPublication.removeFromPublicationGroup(favoritesGroup)
                }
            }
            saveCoreData()
            loadCoreData()
            
            populateFilesCV()
            filesCollectionView.reloadData()
            
        default:
            print("Default 134")
        }
    }
    
    @IBAction func toggleFocusedView(_ sender: Any) {
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
            print("")
        }
    }
    
    @IBAction func rankSlider(_ sender: Any) {
        rankValue.text = "\(Int(rankOutlet.value))"
    }
    
    @IBAction func updateFile(_ sender: Any) {
        activityIndicator.startAnimating()
        switch categories[selectedCategoryNumber] {
        case "Publications":
            
            // UPDATING LOCALFILES
            let currentFile = updateLocalFiles()
            
            // UPDATING CORE DATA
            updateCoreData(file: currentFile!)

            // UPDATING ICLOUD. CORE DATA SHOULD BE UPDATED WITH LATEST CHANGES, USE THIS TO UPDATE ICLOUD
            if let currentPublication = publicationsCD.first(where: {$0.filename == filenameString.text}) {
                updateIcloud(file: currentPublication)
            }
            
            populateListTable()
            populateFilesCV()
            listTableView.reloadData()
            filesCollectionView.reloadData()

//            // UPDATING PUBLICATIONSIC
//            if let index = publicationsIC.index(where: {$0.filename == currentPublication.filename}) {
//
//                publicationsIC[index].dateModified = Date()
//                publicationsIC[index].rank = rankOutlet.value
//
//                if (titleString.text?.isEmpty)! {
//                    publicationsIC[index].title = "No title"
//                } else {
//                    publicationsIC[index].title = titleString.text
//                }
//                if (yearString.text?.isEmpty)! {
//                    publicationsIC[index].year = -2000
//                } else {
//                    publicationsIC[index].year = isStringAnInt(stringNumber: yearString.text!)
//                }
//
//                if (notesTextView.text?.isEmpty)! {
//                    publicationsIC[index].note = "No note"
//                } else {
//                    publicationsIC[index].note = notesTextView.text
//                }
//
//                if (authorString.text?.isEmpty)! {
//                    publicationsIC[index].author = "No author"
//                } else {
//                    publicationsIC[index].author = authorString.text
//                }
//
//                var groups = [String]()
//                for group in currentPublication.publicationGroup?.allObjects as! [PublicationGroup] {
//                    groups.append(group.tag!)
//                }
//                publicationsIC[index].groups = groups
//
//            } else {
//                // ADD NEW ITEM TO PUBLICATIONSIC
//                var groups = [String]()
//                for group in currentPublication.publicationGroup?.allObjects as! [PublicationGroup] {
//                    groups.append(group.tag!)
//                }
//                let thumbnail = self.getThumbnail(url: self.publicationsURL.appendingPathComponent(currentPublication.filename!), pageNumber: 0)
//
//                let newPublication = PublicationFile(filename: currentPublication.filename!, title: currentPublication.title, year: currentPublication.year, thumbnails: [thumbnail], category: "Publications", rank: currentPublication.rank, note: currentPublication.note, dateCreated: currentPublication.dateCreated, dateModified: currentPublication.dateModified, favorite: currentPublication.favorite, author: currentPublication.author?.name, groups: groups)
//
//                publicationsIC.append(newPublication)
//            }
            
            
            
        default:
            print("105")
        }
        
        listTableView.reloadData()
        
        activityIndicator.stopAnimating()
    }
    
    @IBAction func deleteFile(_ sender: Any) {
        
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
//        for item in publicationsCD {
//            print(item.filename)
//        }
        
        for items in filesCV {
            for item in items {
                print(item.filename)
            }
        }
//        for item in localFiles[0] {
//            print(item.filename)
//            print(item.groups)
//        }
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
//        let requestAuthors: NSFetchRequest<Author> = Author.fetchRequest()
//        do {
//            let items = try context.fetch(requestAuthors)
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
        compareLocalFilesWithDatabase()
        populateListTable()
        sortItems()
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
    
    @IBAction func addNewGroup(_ sender: Any) {
        switch categories[selectedCategoryNumber] {
        case "Publications":
            let inputNewGroup = UIAlertController(title: "New group", message: "Enter name of new group", preferredStyle: .alert)
            inputNewGroup.addTextField(configurationHandler: { (newGroup: UITextField) -> Void in
                newGroup.placeholder = "Enter group tag"
            })
            inputNewGroup.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                let newGroup = inputNewGroup.textFields?[0]
                self.addNewItem(title: newGroup?.text)
                inputNewGroup.dismiss(animated: true, completion: nil)
            }))
            inputNewGroup.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                inputNewGroup.dismiss(animated: true, completion: nil)
            }))
            self.present(inputNewGroup, animated: true, completion: nil)
            
        default:
            print("110")
        }
    }
    
    
    
    
    // MARK: - ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isIcloudAvailble()
        
        //MARK: - AppDelegate
        let app = UIApplication.shared
        appDelegate = app.delegate as! AppDelegate
        context = appDelegate.context
        publicationsURL = appDelegate.publicationURL
        manuscriptsURL = appDelegate.manuscriptURL
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

        listTableView.delegate = self
        listTableView.dataSource = self
        listTableView.dropDelegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(handleSorttablePopupClosing), name: Notification.Name.sortSubtable, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSortFilesPopupClosing), name: Notification.Name.sortCollectionView, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleSettingsPopupClosing), name: Notification.Name.settingsCollectionView, object: nil)
        
        // Touch gestures
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        doubleTap.numberOfTapsRequired = 2
        self.filesCollectionView.addGestureRecognizer(doubleTap)

        
//        getRecordNames()

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
                let name = res.value(forAttribute: NSMetadataItemFSNameKey) as! String
                print(name)
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

    }
    
    @objc func handleSorttablePopupClosing(notification: Notification) {
        let sortingVC = notification.object as! SortSubtableViewController
        let sortValue = sortingVC.sortOptions.selectedSegmentIndex
        sortSubtableNumbers[selectedCategoryNumber] = sortValue
        
        kvStorage.set(sortSubtableNumbers, forKey: "sortSubtable")
        kvStorage.synchronize()

        populateListTable()
        populateFilesCV()
        sortItems()

        self.listTableView.reloadData()
        self.filesCollectionView.reloadData()
    }

    @objc func handleSortFilesPopupClosing(notification: Notification) {
        let sortingVC = notification.object as! SortItemsViewController
        let sortValue = sortingVC.sortOptions.selectedSegmentIndex
        sortCollectionViewNumbers[selectedCategoryNumber] = sortValue
        
        sortItems()
        
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
    
    @objc func doubleTapped(gesture: UITapGestureRecognizer) {
        switch categories[selectedCategoryNumber] {
        case "Publications":
            let pointInCollectionView = gesture.location(in: self.filesCollectionView)
            if let indexPath = self.filesCollectionView.indexPathForItem(at: pointInCollectionView) {
                let selectedCell = filesCV[selectedSubtableNumber][indexPath.row]
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
    
    func updateIcloud(file: Any) {
        activityIndicator.startAnimating()
        let currentPublication = file as! Publication
        
        if let recName = currentPublication.filename {
            let predicate = NSPredicate(format: "Filename = %@", recName)
            let query = CKQuery(recordType: "Publications", predicate: predicate)

            privateDatabase?.perform(query, inZoneWith: recordZone?.zoneID) { (records, error) in
                guard let records = records else {return}
                DispatchQueue.main.async {
                    // FOUND AT LEAST ONE RECORD
                    if records.count > 0 {
                        for record in records {
                            if record.object(forKey: "Filename") as! String == recName {
                                print(record.object(forKey: "Filename") as! String)
                                
                                var groups = [String]()
                                for group in currentPublication.publicationGroup?.allObjects as! [PublicationGroup] {
                                    groups.append(group.tag!)
                                }
                                
                                record.setObject(currentPublication.year as CKRecordValue?, forKey: "Year")
                                record.setObject(currentPublication.title as CKRecordValue?, forKey: "Title")
                                record.setObject(currentPublication.favorite as CKRecordValue?, forKey: "Favorite")
                                record.setObject(currentPublication.note! as CKRecordValue?, forKey: "Note")
                                record.setObject(Int(currentPublication.rank) as CKRecordValue?, forKey: "Rank")
                                record.setObject(currentPublication.author?.name as CKRecordValue?, forKey: "Author")
                                record.setObject(groups as CKRecordValue?, forKey: "Group")
                                
                                self.privateDatabase?.save(record, completionHandler:( { savedRecord, error in
                                    DispatchQueue.main.async {
                                        if let error = error {
                                            print("accountStatus error: \(error)")
                                        } else {
                                            print("1. Updated record: " + recName)
                                        }
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
                                
                                var groups = [String]()
                                for group in currentPublication.publicationGroup?.allObjects as! [PublicationGroup] {
                                    groups.append(group.tag!)
                                }
                                
                                myRecord.setObject(currentPublication.filename as CKRecordValue?, forKey: "Filename")
                                myRecord.setObject(currentPublication.author?.name as CKRecordValue?, forKey: "Author")
                                myRecord.setObject(groups as CKRecordValue?, forKey: "Group")
                                myRecord.setObject(Int(currentPublication.rank) as CKRecordValue?, forKey: "Rank")
                                myRecord.setObject(currentPublication.year as CKRecordValue?, forKey: "Year")
                                myRecord.setObject(currentPublication.note as CKRecordValue?, forKey: "Note")
                                myRecord.setObject(currentPublication.title as CKRecordValue?, forKey: "Title")
                                myRecord.setObject(currentPublication.favorite as CKRecordValue?, forKey: "Favorite")
                                
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
                                                print(currentPublication.filename! + " successfully added to icloud database")
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
        
//        if recordFound == false {
//            // ADD FILE TO ICLOUD
//            if let zoneID = recordZone?.zoneID {
//                let myRecord = CKRecord(recordType: categories[selectedCategoryNumber], zoneID: zoneID)
//                switch categories[selectedCategoryNumber] {
//                case "Publications":
//
//                    var groups = [String]()
//                    for group in currentPublication.publicationGroup?.allObjects as! [PublicationGroup] {
//                        groups.append(group.tag!)
//                    }
//
//                    myRecord.setObject(currentPublication.filename as CKRecordValue?, forKey: "Filename")
//                    myRecord.setObject(currentPublication.author?.name as CKRecordValue?, forKey: "Author")
//                    myRecord.setObject(groups as CKRecordValue?, forKey: "Group")
//                    myRecord.setObject(currentPublication.rank as CKRecordValue?, forKey: "Rank")
//                    myRecord.setObject(currentPublication.year as CKRecordValue?, forKey: "Year")
//                    myRecord.setObject(currentPublication.note as CKRecordValue?, forKey: "Note")
//                    myRecord.setObject(currentPublication.title as CKRecordValue?, forKey: "Title")
//                    myRecord.setObject(currentPublication.favorite as CKRecordValue?, forKey: "Favorite")
//
//                    let modifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: [myRecord], recordIDsToDelete: nil)
//                    let configuration = CKOperationConfiguration()
//                    configuration.timeoutIntervalForRequest = 10
//                    configuration.timeoutIntervalForResource = 10
//
//                    modifyRecordsOperation.configuration = configuration
//                    modifyRecordsOperation.modifyRecordsCompletionBlock =
//                        { records, recordIDs, error in
//                            if let err = error {
//                                print(err)
//                            } else {
//                                DispatchQueue.main.async {
//                                    print(currentPublication.filename! + " successfully added to icloud database")
//                                }
//                                self.currentRecord = myRecord
//                            }
//                    }
//                    privateDatabase?.add(modifyRecordsOperation)
//                default:
//                    print("101")
//                }
//            }
//
//        }
        activityIndicator.stopAnimating()
    }
    
    func loadIcloudData() {
        if icloudAvailable {
            // GET PUBLICATIONS
            let query = CKQuery(recordType: "Publications", predicate: NSPredicate(value: true))
            privateDatabase?.perform(query, inZoneWith: nil) { (records, error) in
                guard let records = records else {return}
                DispatchQueue.main.async {
                    self.activityIndicator.startAnimating()
                    for record in records {
                        let thumbnail = self.getThumbnail(url: self.publicationsURL.appendingPathComponent(record.object(forKey: "Filename") as! String), pageNumber: 0)
                        let newPublication = PublicationFile(filename: record.object(forKey: "Filename") as! String, title: record.object(forKey: "Title") as? String, year: record.object(forKey: "Year") as? Int16, thumbnails: [thumbnail], category: "Publication", rank: record.object(forKey: "Rank") as? Float, note: record.object(forKey: "Note") as? String, dateCreated: record.creationDate, dateModified: record.modificationDate, favorite: record.object(forKey: "Favorite") as? String, author: record.object(forKey: "Author") as? String, groups: record.object(forKey: "Group") as! [String?])
                        self.publicationsIC.append(newPublication)
                        print(record.object(forKey: "Filename") as! String)
                    }
                    
                    self.compareLocalFilesWithDatabase()
                    self.populateListTable()
                    self.populateFilesCV()
                    self.sortItems()
                    
                    self.categoriesCV.reloadData()
                    self.listTableView.reloadData()
                    self.filesCollectionView.reloadData()
                    
                    self.activityIndicator.stopAnimating()

                }
            }
        } else {
            compareLocalFilesWithDatabase()
            populateListTable()
            populateFilesCV()
            sortItems()
            
            self.categoriesCV.reloadData()
            listTableView.reloadData()
            filesCollectionView.reloadData()
            activityIndicator.stopAnimating()

        }
    }

    func readIcloudDriveFolders() {
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
                            thumbnail = #imageLiteral(resourceName: "fileIcon.png")
                            available = false
                            filename = file.deletingPathExtension().lastPathComponent
                            filename.remove(at: filename.startIndex)
                        } else {
                            thumbnail = getThumbnail(url: file, pageNumber: 0)
                            filename = file.lastPathComponent
                        }
                        let newFile = LocalFile(label: file.lastPathComponent, thumbnail: thumbnail, favorite: "No", filename: filename, url: file, title: "No title", year: -2000, category: "Publication", rank: 50, note: "No notes", dateCreated: Date(), dateModified: Date(), author: "No author", groups: ["All publications"], parentFolder: nil, available: available)
                        localFiles[0].append(newFile)
                    }
                } catch {
                    print("Error while enumerating files \(publicationsURL.path): \(error.localizedDescription)")
                }
            case "Manuscripts":
                let fileManager = FileManager.default
                do {
                    let folderURLs = try fileManager.contentsOfDirectory(at: manuscriptsURL!, includingPropertiesForKeys: nil)
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
                            let newFile = LocalFile(label: file.lastPathComponent, thumbnail: thumbnail, favorite: "No", filename: file.lastPathComponent, url: file, title: nil, year: nil, category: "Manuscripts", rank: nil, note: "No notes", dateCreated: Date(), dateModified: Date(), author: nil, groups: [nil], parentFolder: folders.lastPathComponent, available: available)
                            localFiles[1].append(newFile)
                        }
                    }
                } catch {
                    print("Error while reading manuscript folders")
                }
//            case "Presentations":
//                print("Presentations 101")
//            case "Proposals":
//                print("Proposals 101")
//            case "Supervision":
//                print("Supervision 101")
//            case "Teaching":
//                print("Teaching 101")
//            case "Patents":
//                print("Patents 101")
            default:
                print("Default 122")
            }
        }
    }
    
    func getRecordNames() {
        switch categories[selectedCategoryNumber] {
        case "Publications":
            
            let query = CKQuery(recordType: "Publications", predicate: NSPredicate(value: true))
            privateDatabase?.perform(query, inZoneWith: nil) { (records, error) in
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
        print(currentTheme)
        
        //        if let number = kvStorage.array(forKey: "selectedCategory") as? Int {
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
    
    
    
    // MARK: - STORYBOARD FUNCTIONS
    
    func updateLocalFiles() -> LocalFile? {
        for i in 0..<localFiles[selectedCategoryNumber].count {
            if localFiles[selectedCategoryNumber][i].filename == filenameString.text {
                
                localFiles[selectedCategoryNumber][i].dateModified = Date()
                localFiles[selectedCategoryNumber][i].rank = rankOutlet.value
                
                if (titleString.text?.isEmpty)! {
                    localFiles[selectedCategoryNumber][i].title = "No title"
                } else {
                    localFiles[selectedCategoryNumber][i].title = titleString.text
                }
                if (yearString.text?.isEmpty)! {
                    localFiles[selectedCategoryNumber][i].year = -2000
                } else {
                    localFiles[selectedCategoryNumber][i].year = isStringAnInt(stringNumber: yearString.text!)
                }
                
                if (notesTextView.text?.isEmpty)! {
                    localFiles[selectedCategoryNumber][i].note = "No note"
                } else {
                    localFiles[selectedCategoryNumber][i].note = notesTextView.text
                }
                
                if (authorString.text?.isEmpty)! {
                    localFiles[selectedCategoryNumber][i].author = "No author"
                } else {
                    localFiles[selectedCategoryNumber][i].author = authorString.text
                }
                print("Updated local file: " + localFiles[selectedCategoryNumber][i].filename)
                return localFiles[selectedCategoryNumber][i]
            }
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
            
            for group in file.groups {
                if let tmp = publicationGroupsCD.first(where: {$0.tag == group}) {
                    currentPublication.addToPublicationGroup(tmp) //Assume (for now) that all groups can be found in publicationGroupsCD
                }
            }
            
            saveCoreData()
            loadCoreData()
            
        } else {
            // A FILE FOUND IN FOLDER BUT NOT SAVED INTO CORE DATA
            addFileToCoreData(file: file)
        }
    }
    
    func addNewItem(title: String?) {
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
                
                self.listTableView.reloadData()
                self.filesCollectionView.reloadData()
            }
            
        default:
            print("Default 111")
            
        }
    }
    
    func setThemeColor() {
        switch currentTheme {
        case 0:
            mainView.backgroundColor = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
            categoriesCV.backgroundColor = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
            notesView.backgroundColor = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
        case 1:
            mainView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
            categoriesCV.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
            notesView.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
        case 2:
            mainView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
            categoriesCV.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
            notesView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        default:
            mainView.backgroundColor = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
            categoriesCV.backgroundColor = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
            notesView.backgroundColor = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
        }
    }
    
    func populateListTable() {
        switch categories[selectedCategoryNumber] {
        case "Publications":
            sortTableTitles = [String]()
            switch sortSubtableStrings[sortSubtableNumbers[selectedSubtableNumber]] {
            case "Tag":
                let tmp = publicationGroupsCD.sorted(by: {($0.sortNumber!, $0.tag!) < ($1.sortNumber!, $1.tag!)})
                sortTableTitles = tmp.map { $0.tag! }
            case "Year":
                sortTableTitles = getArticlesYears()
            case "Author":
                let tmp = authorsCD.sorted(by: {($0.sortNumber!, $0.name!) < ($1.sortNumber!, $1.name!)})
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
        default:
            print("Default 126")
        }
        
    }
    
    func populateFilesCV() {
        
        filesCV = [[]]
        
        switch categories[selectedCategoryNumber] {
        case "Publications":
            switch sortSubtableStrings[sortSubtableNumbers[selectedSubtableNumber]] {
            case "Tag":
                for i in 0..<sortTableTitles.count {
                    for file in localFiles[0] {
                        if file.groups.first(where: {$0 == sortTableTitles[i]}) != nil {
                            filesCV[i].append(file)
                        }
                    }
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
                    if i < sortTableTitles.count {
                        filesCV.append([]) // ADD [] FOR THE NEXT ROUND
                    }
                }
            default:
                print("Default 132")
            }
            
        case "Manuscripts":
            filesCV = [[]]

            for i in 0..<sortTableTitles.count {
                for file in localFiles[1] {
                    if file.parentFolder == sortTableTitles[i] {
                        filesCV[i].append(file)
                    }
                }
                if i < sortTableTitles.count {
                    filesCV.append([]) // ADD [] FOR THE NEXT ROUND
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

    // MARK: - CORE DATA FUNCTIONS
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

        let request: NSFetchRequest<Publication> = Publication.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "filename", ascending: true)]
        do {
            publicationsCD = try context.fetch(request)
        } catch {
            print("Error loading publications")
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
        
        // ADD "ALL PUBLICATIONS"
        let arrayPublicationGroups = publicationGroupsCD
        if arrayPublicationGroups.first(where: {$0.tag == "All publications"}) == nil {
            let newPublicationGroup = PublicationGroup(context: context)
            newPublicationGroup.tag = "All publications"
            newPublicationGroup.dateModified = Date()
            newPublicationGroup.sortNumber = "0"
            saveCoreData()
        }
        
//        // ADD "UNFILED ARTICLES"
//        if publicationGroupsCD.first(where: {$0.tag == "Unfiled"}) == nil {
//            let unfiledGroup = PublicationGroup(context: context)
//            unfiledGroup.tag = "Unfiled"
//            unfiledGroup.dateModified = Date()
//            unfiledGroup.sortNumber = "1"
//            saveCoreData()
//        }

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

    func addOrRemoveFromUnfiledGroup() {
//        let unfiledGroup = publicationGroupsCD.first(where: {$0.tag! == "Unfiled"})
        
        let standardGroups = ["All publications", "Unfiled", "Favorites"]
        for file in localFiles[0] {
            var keep = true
            if (file.groups.contains(standardGroups[0]) && file.groups.contains(standardGroups[1]) && file.groups.count > 2) {
                for group in file.groups {
                    if group != "Favorites" {
                        keep = false
                        print(file.filename)
                    }
                }
            }
        }
        
        
//        if (article.articleGroup?.count)! > 1 {
//            if (article.articleGroup?.contains(unfiled))! {
//                article.removeFromArticleGroup(unfiled!)
//            }
//        }
//        if (article.articleGroup?.count)! == 1 {
//            article.addToArticleGroup(unfiled!)
//        }
    }
    
    
    
    // MARK: - GENERAL FUNCTIONS
    
    func setupUI() {

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
//        loadDefaultValues()
        
        self.focusedViewButton.isHidden = true
        self.focusedViewText.isHidden = true

        readIcloudDriveFolders()
        
        loadCoreData()
        setupDefaultCoreDataTypes()
        loadIcloudData() // compareLocalFilesWithDatabase() runs here
        
        setThemeColor()
        
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
                    updateLocalFilesWithCoreData(index: i, category: selectedCategoryNumber, coreDataFile: coreDataFile)
                } else {
                    updateLocalFilesWithIcloud(index: i, category: selectedCategoryNumber, icloudFile: icloudFile)
                }
            } else {
                if icloudMatch || coreDataMatch {
                    if icloudMatch {
                        updateLocalFilesWithIcloud(index: i, category: selectedCategoryNumber, icloudFile: icloudFile)
                    } else {
                        updateLocalFilesWithCoreData(index: i, category: selectedCategoryNumber, coreDataFile: coreDataFile)
                    }
                } else {
                    updateCoreDataWithLocalFiles(index: i, category: selectedCategoryNumber)
                }
            }

            
        }
    }
    
    func updateCoreDataWithLocalFiles(index: Int, category: Int) {
        switch category {
        case 0:
            let newPublication = Publication(context: context)
            
            newPublication.filename = localFiles[category][index].filename
            newPublication.thumbnail = localFiles[category][index].thumbnail
            newPublication.dateCreated = localFiles[category][index].dateCreated!
            newPublication.dateModified = localFiles[category][index].dateModified!
            newPublication.title = localFiles[category][index].title!
            newPublication.year = localFiles[category][index].year!
            newPublication.note = localFiles[category][index].note!
            
            let noAuthor = authorsCD.first(where: {$0.name == "No author"})
            if localFiles[category][index].author == "No author" {
                newPublication.author = noAuthor
            } else {
                if authorsCD.first(where: {$0.name == localFiles[category][index].author}) == nil {
                    let newAuthor = Author(context: context)
                    newAuthor.name = localFiles[category][index].author!
                    newAuthor.sortNumber = "1"
                    print("Added new author: " + newAuthor.name!)
                    newPublication.author = newAuthor
                } else {
                    newPublication.author = authorsCD.first(where: {$0.name == localFiles[category][index].author})
                }
            }

            newPublication.favorite = localFiles[category][index].favorite
            
            for group in localFiles[category][index].groups {
                if publicationGroupsCD.first(where: {$0.tag == group}) == nil {
                    let newGroup = PublicationGroup(context: context)
                    newGroup.tag = group
                    newGroup.sortNumber = "3"
                    newGroup.dateModified = Date()
                    print("Added new group: " + newGroup.tag!)
                    newPublication.addToPublicationGroup(newGroup)
                } else {
                    newPublication.addToPublicationGroup(publicationGroupsCD.first(where: {$0.tag == group})!)
                }
            }
            
            publicationsCD.append(newPublication)
            
            saveCoreData()
            loadCoreData()
            
            print("Saved " + newPublication.filename! + " to core data.")
        default:
            print("Default 132")
        }
    }
    
    func updateLocalFilesWithIcloud(index: Int, category: Int, icloudFile: Any) {
        switch category {
        case 0:
            let currentIcloudFile = icloudFile as! PublicationFile
            localFiles[category][index].year = currentIcloudFile.year
            localFiles[category][index].title = currentIcloudFile.title!
            localFiles[category][index].rank = currentIcloudFile.rank
            localFiles[category][index].note = currentIcloudFile.note!
            localFiles[category][index].dateCreated = currentIcloudFile.dateCreated!
            localFiles[category][index].dateModified = currentIcloudFile.dateModified!
            localFiles[category][index].favorite = currentIcloudFile.favorite!
            if authorsCD.first(where: {$0.name == currentIcloudFile.author}) == nil {
                let newAuthor = Author(context: context)
                newAuthor.name = currentIcloudFile.author
                newAuthor.sortNumber = "1"
                print("Added new author: " + newAuthor.name!)
                saveCoreData()
                loadCoreData()
            }
            localFiles[category][index].author = currentIcloudFile.author!
            localFiles[category][index].groups = currentIcloudFile.groups
            print("Icloud file: " + localFiles[category][index].filename)
        default:
            print("Default 131")
        }
    }
    
    func updateLocalFilesWithCoreData(index: Int, category: Int, coreDataFile: Any) {
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
            for group in currentCoreDataFile.publicationGroup?.allObjects as! [PublicationGroup] {
                localFiles[category][index].groups.append(group.tag)
                if group.tag == "Favorites" {
                    localFiles[category][index].favorite = "Yes"
                    print("Favorite" + currentCoreDataFile.filename!)
                } else {
                    localFiles[category][index].favorite = "No"
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
                    titleString.text = "No title"
                    yearString.text = "-2000"
                    authorString.text = "No author"
                    notesTextView.text = "No notes"
                    rankOutlet.value = 50
                    rankValue.text = "50"
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
    
    func isStringAnInt(stringNumber: String) -> Int16 {
        if let tmpValue = Int16(stringNumber) {
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
            let destination = segue.destination as! SortSubtableViewController
            if sortSubtableNumbers[selectedSubtableNumber] > sortSubtableStrings.count {
                sortSubtableNumbers[selectedSubtableNumber] = 0
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
            newPublication.favorite = file.favorite

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

            for group in file.groups {
                if let tmp = publicationGroupsCD.first(where: {$0.tag == group}) {
                    newPublication.addToPublicationGroup(tmp) //Assume (for now) that all groups can be found in publicationGroupsCD
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
    
    func saveCoreData() {
        do {
            try context.save()
            print("Saved to core data")
        } catch {
            alert(title: "Error saving", message: "Could not save core data")
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
        
        switch categories[selectedCategoryNumber] {
        case "Publications":
            switch sortCollectionViewStrings[sortCollectionViewNumbers[selectedCategoryNumber]] {
            case "Filename":
                if !filesCV[selectedSubtableNumber].isEmpty {
                    filesCV[selectedSubtableNumber] = filesCV[selectedSubtableNumber].sorted(by: {($0.filename) < ($1.filename)})
                }
            case "Title":
                if !filesCV[selectedSubtableNumber].isEmpty {
                    filesCV[selectedSubtableNumber] = filesCV[selectedSubtableNumber].sorted(by: {$0.title! < $1.title!})
                }
            case "Year":
                if !filesCV[selectedSubtableNumber].isEmpty {
                    filesCV[selectedSubtableNumber] = filesCV[selectedSubtableNumber].sorted(by: {$0.year! < $1.year!})
                }
            case "Author":
                if !filesCV[selectedSubtableNumber].isEmpty {
                    filesCV[selectedSubtableNumber] = filesCV[selectedSubtableNumber].sorted(by: {($0.author)! < ($1.author)!})
                }
            case "Date modified":
                if !filesCV[selectedSubtableNumber].isEmpty {
                    filesCV[selectedSubtableNumber] = filesCV[selectedSubtableNumber].sorted(by: {$0.dateModified! < $1.dateModified!})
                }
            case "Rank":
                if !filesCV[selectedSubtableNumber].isEmpty {
                    filesCV[selectedSubtableNumber] = filesCV[selectedSubtableNumber].sorted(by: {$0.rank! < $1.rank!})
                }
            default:
                print("Default sortItems 101")
            }
        case "Manuscripts":
            for i in 0..<filesCV.count {
                filesCV[i] = filesCV[i].sorted(by: {($0.filename) < ($1.filename)})
            }
        default:
            print("Default sortItems 102")
        }

    }
    
    func assignPublicationToAuthor(filename: String, authorName: String) {
        // PUBLICATIONS CORE DATA
        if let author = authorsCD.first(where: {$0.name == authorName}) {
            if let currentPublication = publicationsCD.first(where: {$0.filename == filename}) {
                currentPublication.author = author
                saveCoreData()
                loadCoreData()
                updateIcloud(file: currentPublication)
            }
        } else {
            let newAuthor = Author(context: context)
            newAuthor.name = authorName
            newAuthor.sortNumber = "1"
            print("Added new author: " + authorName)
        }
        
        // LOCAL FILES
        for i in 0..<localFiles[0].count {
            if localFiles[0][i].filename == filename {
                localFiles[0][i].author = authorName
            }
        }
    }
    
    func addPublicationToGroup(filename: String, group: PublicationGroup) {
        // PUBLICATIONS CORE DATA
        if let publication = publicationsCD.first(where: {$0.filename == filename}) {
            group.addToPublication(publication)
            saveCoreData()
            loadCoreData()
            updateIcloud(file: publication)
        }
        
        // LOCAL FILES
        for i in 0..<localFiles[0].count {
            if localFiles[0][i].filename == filename {
                localFiles[0][i].groups.append(group.tag)
            }
        }
        
    }
    
    
    
    
    // MARK: - Table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch categories[selectedCategoryNumber] {
        case "Publications":
            switch sortSubtableStrings[sortSubtableNumbers[selectedSubtableNumber]] {
            case "Tag":
                return sortTableTitles.count
            case "Author":
                return sortTableTitles.count
            case "Year":
                return sortTableTitles.count
            case "Rank":
                return sortTableTitles.count
            default:
                return 1
            }
            
        case "Manuscripts":
            return sortTableTitles.count
            
        default:
            print("Default 135")
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = listTableView.dequeueReusableCell(withIdentifier: "listTableCell") as! ListCell

        switch categories[selectedCategoryNumber] {
        case "Publications":
            cell.listLabel.text = sortTableTitles[indexPath.row]
            cell.listNumberOfItems.text = "\(filesCV[indexPath.row].count)"
            
        case "Manuscripts":
            cell.listLabel.text = sortTableTitles[indexPath.row]
            cell.listNumberOfItems.text = "\(filesCV[indexPath.row].count)"
            
        default:
            cell.listLabel.text = "Nothing yet"
            cell.listNumberOfItems.text = "0 items"
        }

        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // FIX: IF NO FILES EXISTS IN SECTION, cvIndexPath CANNOT BE CREATED
        if filesCV[indexPath.row].count > 0 {
            let cvIndexPath = IndexPath(item: 0, section: indexPath.row)
            self.filesCollectionView.scrollToItem(at: cvIndexPath, at: .top, animated: true)
            //        selectedSubtableNumber = indexPath.row
            //        sortItems()
            //        self.filesCollectionView.reloadData()
        }
        
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
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
                default:
                    print("")
                }
            }
        case "Manuscripts":
            print("Manuscripts")
        default:
            print("")
        }
        
        populateFilesCV()
        sortItems()
        listTableView.reloadData()
        filesCollectionView.reloadData()
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if tableView == self.listTableView {
            switch categories[selectedCategoryNumber] {
            case "Publications":
                switch sortSubtableStrings[sortSubtableNumbers[selectedSubtableNumber]] {
                case "Tag":
                    if indexPath.row > 2 {
                        return true
                    } else {
                        return false
                    }
                case "Author":
                    if indexPath.row > 0 {
                        return true
                    } else {
                        return false
                    }
                default:
                    return false
                }
            case "Manuscripts":
                return false
            default:
                return false
            }
        } else {
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == .delete) {
            print(sortTableTitles[indexPath.row])
            
            //UPDATE selectedItem and selectedItemName for correct selected row
            
            switch categories[selectedCategoryNumber] {
            case "Publications":
                switch sortSubtableStrings[sortSubtableNumbers[selectedSubtableNumber]] {
                case "Tag":
                    let groupName = sortTableTitles[indexPath.row]
                    let groupToDelete = publicationGroupsCD.first(where: {$0.tag! == groupName})
                    let articlesBelongingToGroup = groupToDelete?.publication
//                    context.delete(groupToDelete!)
//                    for item in articlesBelongingToGroup! {
//                        addOrRemoveFromUnfiledGroup(article: item as! Articles)
//                    }
//                    saveCoreData()
//                    loadCoreData()
//                    updateView(fileDeleted: false)
                    print(groupName)
                case "Author":
                    let noAuthor = authorsCD.first(where: {$0.name == "No author"})
                    let authorName = sortTableTitles[indexPath.row]
                    let authorToDelete = authorsCD.first(where: {$0.name! == authorName})
                    let articlesBelongingToAuthor = authorToDelete?.publication
//                    context.delete(authorToDelete!)
//                    for item in articlesBelongingToAuthor! {
//                        let tmp = item as! Articles
//                        tmp.author = noAuthor
//                    }
                    
                    saveCoreData()
                    loadCoreData()
                    
//                    updateView(fileDeleted: false)
                    print(authorName)
                default:
                    print("Default 103")
                }
                
            default:
                print("Default 104")
            }
        }
    }
    
    
    
    
    // MARK: - Collection View
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.categoriesCV {
            return 7
        } else {
            switch categories[selectedCategoryNumber] {
            case "Publications":
                return filesCV[section].count
            case "Manuscripts":
                return filesCV[section].count
            default:
                return 1
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.categoriesCV {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "categoryCell", for: indexPath) as! categoryCell
            switch categories[indexPath.row] {
            case "Publications":
                cell.icon.image = #imageLiteral(resourceName: "PublicationsIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "PublicationsIconSelected")
                cell.number.text = "\(filesCV[0].count)"
            case "Manuscripts":
                cell.icon.image = #imageLiteral(resourceName: "ManuscriptsIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "ManuscriptsIconSelected")
                cell.number.text = "\(filesCV[1].count)"
            case "Patents":
                cell.icon.image = #imageLiteral(resourceName: "PatentsIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "PatentsIconSelected")
                cell.number.text = "30"
            case "Proposals":
                cell.icon.image = #imageLiteral(resourceName: "ProposalsIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "ProposalsIconSelected")
                cell.number.text = "3"
            case "Presentations":
                cell.icon.image = #imageLiteral(resourceName: "PresentationsIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "PresentationsIconSelected")
                cell.number.text = "4"
            case "Teaching":
                cell.icon.image = #imageLiteral(resourceName: "TeachingIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "TeachingIconSelected")
                cell.number.text = "4"
            case "Supervision":
                cell.icon.image = #imageLiteral(resourceName: "SupervisionIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "SupervisionIconSelected")
                cell.number.text = "54"
            default:
                cell.icon.image = #imageLiteral(resourceName: "PublicationsIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "PublicationsIconSelected")
                cell.number.text = "0"
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "filesCell", for: indexPath) as! FilesCell
            switch categories[selectedCategoryNumber] {
            case "Publications":
                cell.hiddenFilename.text = filesCV[indexPath.section][indexPath.row].filename
                cell.thumbnail.image = filesCV[indexPath.section][indexPath.row].thumbnail

                if filesCV[indexPath.section][indexPath.row].favorite == "Yes" {
                    cell.favoriteIcon.isHidden = false
                    cell.favoriteIcon.setImage(#imageLiteral(resourceName: "FavoriteOn"), for: .normal)
                } else {
                    cell.favoriteIcon.isHidden = true
                }

                if filesCV[indexPath.section][indexPath.row].available {
                    cell.icloudSync.isHidden = true
                } else {
                    cell.icloudSync.isHidden = false
                }

                switch sortCollectionViewStrings[sortCollectionViewNumbers[selectedCategoryNumber]] {
                
                case "Filename", "Year", "Author", "Date modified", "Rank":
                    cell.label.text = filesCV[indexPath.section][indexPath.row].filename
                    
                case "Title":
                    cell.label.text = filesCV[indexPath.section][indexPath.row].title

                default:
                    cell.label.text = "Error"
                    cell.thumbnail.image = #imageLiteral(resourceName: "PublicationIcon@1x.png")
                    cell.favoriteIcon.setImage(#imageLiteral(resourceName: "FavoriteOff"), for: .normal)
                    
                }
                
            case "Manuscripts":
                cell.label.text = filesCV[indexPath.section][indexPath.row].filename
                cell.hiddenFilename.text = filesCV[indexPath.section][indexPath.row].filename
                cell.thumbnail.image = filesCV[indexPath.section][indexPath.row].thumbnail

                if filesCV[indexPath.section][indexPath.row].available {
                    cell.icloudSync.isHidden = true
                } else {
                    cell.icloudSync.isHidden = false
                }

            default:
                print("107")
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        currentIndexPath = indexPath
        if collectionView == self.categoriesCV {
            selectedCategoryTitle.text = categories[indexPath.row]
            selectedCategoryNumber = indexPath.row
            selectedSubtableNumber = 0
            kvStorage.set(selectedCategoryNumber, forKey: "selectedCategory")
            kvStorage.synchronize()
            
            switch categories[selectedCategoryNumber] {
            case "Publications":
                self.focusedViewButton.isHidden = true
                self.focusedViewText.isHidden = true
                self.filesView.isHidden = true
                self.notesView.isHidden = false
            case "Manuscripts":
                self.focusedViewButton.isHidden = false
                self.focusedViewText.isHidden = false
                self.filesView.isHidden = false
                self.notesView.isHidden = true
            default:
                self.filesView.isHidden = true
                self.notesView.isHidden = false
            }
            
            populateListTable()
            populateFilesCV()
            sortItems()
            listTableView.reloadData()
            filesCollectionView.reloadData()
            
        } else {
            let currentCell = collectionView.cellForItem(at: indexPath) as! FilesCell
            
            if let pub = publicationsCD.first(where: {$0.filename == currentCell.hiddenFilename.text}) {
                currentPublication = pub
                titleString.text = currentPublication.title
                rankOutlet.value = currentPublication.rank
                rankValue.text = "\(Int(rankOutlet.value))"
                yearString.text = "\(currentPublication.year)"
                authorString.text = currentPublication.author?.name
                notesTextView.text = currentPublication.note
                filenameString.text = currentPublication.filename
                largeThumbnail.image = currentCell.thumbnail.image
                if currentPublication.favorite == "Yes" {
                    favoriteButton.setImage(#imageLiteral(resourceName: "FavoriteOn"), for: .normal)
                } else {
                    favoriteButton.setImage(#imageLiteral(resourceName: "FavoriteOff"), for: .normal)
                }
            } else {
                // FIX: CHANGE TO READ FROM LOCALFILES
                filenameString.text = currentCell.hiddenFilename.text
                titleString.text = "No title"
                yearString.text = "-2000"
                authorString.text = "No author"
                notesTextView.text = "No notes"
                rankOutlet.value = 50
                rankValue.text = "50"
                documentPage = 0
                largeThumbnail.image = getThumbnail(url: publicationsURL.appendingPathComponent(currentCell.hiddenFilename.text!), pageNumber: 0)
                favoriteButton.setImage(#imageLiteral(resourceName: "FavoriteOff"), for: .normal)
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
        return sortTableTitles.count
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let sectionHeaderView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "collectionViewHeader", for: indexPath) as! SectionHeaderView
        
        switch categories[selectedCategoryNumber] {
        case "Publications":
            sectionHeaderView.mainHeaderTitle.text = sortTableTitles[indexPath[0]]
            sectionHeaderView.subHeaderTitle.text = "\(filesCV[indexPath[0]].count)" + " items"
        case "Manuscripts":
            sectionHeaderView.mainHeaderTitle.text = sortTableTitles[indexPath[0]]
            sectionHeaderView.subHeaderTitle.text = "\(filesCV[indexPath[0]].count)" + " items"
        default:
            print("Default 136")
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
