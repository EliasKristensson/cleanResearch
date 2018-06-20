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

struct File {
    var filename: String
    var title: String
    var year: Int32
    var thumbnails: [UIImage]
    var category: String
    var rank: Int16
    var note: String
    var dateCreated: Date
    var dateModified: Date
//    var currentItems: [Any]
//    var currentItem: Int
}

class categoryCell: UICollectionViewCell {
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var number: UILabel!
    var favoriteButton: UIButton!
}

class ListCell: UITableViewCell {
    @IBOutlet weak var listLabel: UILabel!
    @IBOutlet weak var listNumberOfItems: UILabel!
}

class filesCell: UICollectionViewCell {
    
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var label: UILabel!
    
}

//UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UIPopoverPresentationControllerDelegate, UIDocumentMenuDelegate, UIDocumentPickerDelegate, QLPreviewControllerDataSource, QLPreviewControllerDelegate, UICollectionViewDragDelegate, UICollectionViewDropDelegate, UITableViewDropDelegate

class ViewController: UIViewController, UIDocumentPickerDelegate, UIPopoverPresentationControllerDelegate, UIDocumentMenuDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDataSource, UITableViewDelegate {
    

    // MARK: - Variables
    var appDelegate: AppDelegate!
    var document: MyDocument?
    let container = CKContainer.default
    var privateDatabase: CKDatabase?
    var currentRecord: CKRecord?
    var recordZone: CKRecordZone?
    var recordID: CKRecordID?
    
    // MARK: - Core data
    var context: NSManagedObjectContext!
    var publications: [Publication] = []
    var authors: [Author] = []
    var publicationGroups: [PublicationGroup] = []
    
    var currentPublication: Publication!
    var currentAuthor: Author!
    var currentGroup: PublicationGroup!

    
//    let database = CKContainer.default().privateCloudDatabase
//    var articles = [CKRecord]()
    
    // MARK: - iCloud variables
    var documentURL: URL!
    var documentPage = 0
    var iCloudURL: URL!
    var kvStorage: NSUbiquitousKeyValueStore!
    var publicationsURL: URL!
    var metaDataQuery: NSMetadataQuery?
    
    // MARK: - UI variables
    let documentInteractionController = UIDocumentInteractionController()
    let categories: [String] = ["Publications", "Manuscripts", "Presentations", "Proposals", "Supervision", "Teaching", "Patents"]
    var sortCollectionViewBox = CGSize(width: 348, height: 28)
    var selectedCategoryNumber = 0
    var selectedSubtableNumber = 0
    var sortCollectionViewNumbers: [Int] = [0, 0, 0, 0, 0, 0, 0]
    var sortCollectionViewStrings: [String] = ["Filename", "Title", "Year", "Author", "Modified", "Rank"]
    var sortSubtableStrings: [String] = ["Tag", "Author", "Year", "Modified", "Rank"]
    var sortSubtableNumbers: [Int] = [0, 0, 0, 0, 0, 0, 0]

    var currentFilename: String = ""
    var files = [File]()
//    var publications = [String]()
    
    var PDFdocument: PDFDocument!
    var PDFfilename: String!
    
    // MARK: - Outlets
    
    @IBOutlet weak var listTableView: UITableView!
    @IBOutlet weak var filesCollectionView: UICollectionView!
    @IBOutlet weak var selectedCategoryTitle: UILabel!
    @IBOutlet weak var categoriesCV: UICollectionView!
    @IBOutlet weak var notesView: UIView!
    @IBOutlet weak var segmentedControllTablesOrNotes: UISegmentedControl!
    @IBOutlet weak var sortCVButton: UIButton!
    @IBOutlet weak var sortSTButton: UIButton!
    
    @IBOutlet weak var largeThumbnail: UIImageView!
    @IBOutlet weak var filenameString: UITextField!
    @IBOutlet weak var titleString: UITextField!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var authorString: UITextField!
    @IBOutlet weak var yearString: UITextField!
    @IBOutlet weak var rankValue: UILabel!
    @IBOutlet weak var rankOutlet: UISlider!
    
    @IBOutlet weak var textField: UITextView!
    
    //MARK: - IBActions
    
    @IBAction func downloadFromIcloud(_ sender: Any) {
        let query = CKQuery(recordType: categories[selectedCategoryNumber], predicate: NSPredicate(value: true))
        privateDatabase?.perform(query, inZoneWith: nil) { (records, error) in
            guard let records = records else {return}
            for rec in records {
                print(rec)
            }
//            DispatchQueue.main.async {
//                let thumbnail = record.object(forKey: "Thumbnail") as! CKAsset
//                self.largeThumbnail.image = UIImage(contentsOfFile: thumbnail.fileURL.path)
//            }
        }
    }
    
    @IBAction func uploadToIcloud(_ sender: Any) {
        if let zoneID = recordZone?.zoneID {
            switch categories[selectedCategoryNumber] {
            case "Publications":
                
                for pub in publications {
                    let myRecord = CKRecord(recordType: categories[selectedCategoryNumber], zoneID: zoneID)
                    //                    let thumbnail = pub.thumbnail as! CKAsset
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
                    
                    //                    print(pub.filename)
                    //                    print(tag)
                    //                    print(pub.author?.name)
                    let author = pub.author?.name
                    myRecord.setObject("0" as CKRecordValue?, forKey: "Favorite")
                    myRecord.setObject(author as CKRecordValue?, forKey: "Author")
                    myRecord.setObject(pub.filename as CKRecordValue?, forKey: "Filename")
                    //                    myRecord.setObject(thumbnail as CKRecordValue?, forKey: "Thumbnail")
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
    
    @IBAction func favoriteTapped(_ sender: Any) {
//        let pointInCollectionView =  //gesture.location(in: self.filesCollectionView)
    }
    
    @IBAction func toggleTableNotes(_ sender: Any) {
        let selectedOption = segmentedControllTablesOrNotes.titleForSegment(at: segmentedControllTablesOrNotes.selectedSegmentIndex)
        switch selectedOption! {
        case "List":
            notesView.isHidden = true
        case "Notes":
            notesView.isHidden = false
        default:
            print("")
        }
    }
    
    @IBAction func rankSlider(_ sender: Any) {
        rankValue.text = "\(Int(rankOutlet.value))"
    }
    
    @IBAction func updateFile(_ sender: Any) {
        switch categories[selectedCategoryNumber] {
        case "Publications":
            if let pub = publications.first(where: {$0.filename == filenameString.text}) {
                currentPublication = pub
                currentPublication.dateModified = Date()
                currentPublication.rank = rankOutlet.value
                
                if (titleString.text?.isEmpty)! {
                    currentPublication.title = "No title"
                } else {
                    currentPublication.title = titleString.text
                }
                if (yearString.text?.isEmpty)! {
                    currentPublication.year = -2000
                } else {
                    currentPublication.year = isStringAnInt(stringNumber: yearString.text!)
                }
                if (notesTextView.text?.isEmpty)! {
                    currentPublication.note = notesTextView.text
                } else {
                    currentPublication.note = "No note"
                }
                
                let arrayAuthors = authors
                let noAuthor = authors.first(where: {$0.name == "No author"})
                if (authorString.text?.isEmpty)! {
                    currentPublication.author = noAuthor
                } else {
                    if arrayAuthors.first(where: {$0.name == authorString.text}) == nil {
                        let newAuthor = Author(context: context)
                        newAuthor.name = authorString.text
                        newAuthor.sortNumber = "1"
                        print(newAuthor)
                        currentPublication.author = newAuthor
                    } else {
                        currentPublication.author = arrayAuthors.first(where: {$0.name == authorString.text})
                    }
                }
                
                saveCoreData()
            }
        default:
            print("105")
        }
        
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
        for pubs in publications {
            print(pubs.filename)
            print(pubs.title)
            print(pubs.dateModified)
            print(pubs.year)
        }
        for aut in authors {
            print(aut.name)
        }
        for groups in publicationGroups {
            print(groups.tag)
        }
        
//        let requestPublicationGroups: NSFetchRequest<PublicationGroup> = PublicationGroup.fetchRequest()
//        if let result = try? context.fetch(requestPublicationGroups) {
//            for object in result {
//                if object.tag == "All articles" {
//                    context.delete(object)
//                }
////                context.delete(object)
//            }
//        }
//        saveCoreData()
//        let query = CKQuery(recordType: "Publication", predicate: NSPredicate(value: true))
//        privateDatabase?.perform(query, inZoneWith: nil) { (records, error) in
//            guard let records = records else {return}
//            let record = records[0]
//            DispatchQueue.main.async {
//                let thumbnail = record.object(forKey: "Thumbnail") as! CKAsset
//                self.largeThumbnail.image = UIImage(contentsOfFile: thumbnail.fileURL.path)
//            }
//        }
        
    }
    
    @IBAction func tappedSave(_ sender: Any) {

        if let id = self.recordID {
            let record = CKRecord(recordType: "Publication", recordID: id)
            record.setObject("SLIPI - 2018" as CKRecordValue?, forKey: "Title")
            privateDatabase?.save(record, completionHandler: { (returnRecord, error) in
                if let err = error {
                    DispatchQueue.main.async {
                        print(err)
                    }
                } else {
                    DispatchQueue.main.async {
                        print("Success")
                    }
                }
            })
        }

//        publications = [String]()
//        publications.append("test10.doc")
//        publications.append("test11.doc")
//        publications.append("test12.doc")
//
//        let tag = ["My papers", "All papers", "Spectroscopy"]
//
//        if let zoneID = recordZone?.zoneID {
//            let myRecord = CKRecord(recordType: "Publication", zoneID: zoneID)
//            myRecord.setObject("FRAME - 2018" as CKRecordValue?, forKey: "Title")
//            myRecord.setObject("Kristensson" as CKRecordValue?, forKey: "Author")
//            myRecord.setObject(tag as CKRecordValue?, forKey: "Group")
//            myRecord.setObject(25 as CKRecordValue?, forKey: "Rank")
//
//            let modifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: [myRecord], recordIDsToDelete: nil)
//            let configuration = CKOperationConfiguration()
//            configuration.timeoutIntervalForRequest = 10
//            configuration.timeoutIntervalForResource = 10
//
//            modifyRecordsOperation.configuration = configuration
//            modifyRecordsOperation.modifyRecordsCompletionBlock =
//                { records, recordIDs, error in
//                    if let err = error {
//                        print(err)
//                    } else {
//                        DispatchQueue.main.async {
//                            print("Record saved successfully")
//                        }
//                        self.currentRecord = myRecord
//                    }
//            }
//            privateDatabase?.add(modifyRecordsOperation)
//        }
        
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
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //MARK: - AppDelegate
        let app = UIApplication.shared
        appDelegate = app.delegate as! AppDelegate
        context = appDelegate.context
        publicationsURL = appDelegate.publicationURL
        iCloudURL = appDelegate.iCloudURL
//        publicationsURL = iCloudURL.appendingPathComponent("Publications")
        
        mainVC = self
//        document = MyDocument(fileURL: getURL())
//        document?.open(completionHandler: nil)
        
        setupUI()
        loadCoreData()
        setupDefaultCoreDataTypes()
        
//        readIcloudDriveFolders()
        
        categoriesCV.delegate = self
        categoriesCV.dataSource = self
        
        filesCollectionView.delegate = self
        filesCollectionView.dataSource = self
        
        listTableView.delegate = self
        listTableView.dataSource = self

        NotificationCenter.default.addObserver(self, selector: #selector(handleSorttablePopupClosing), name: Notification.Name.sortSubtable, object: nil)

    }
    
    
    
    
    // MARK: - OBJECT C FUNCTIONS
    @objc func metadataQueryDidFinishGathering(notification: NSNotification) -> Void {
        let query: NSMetadataQuery = notification.object as! NSMetadataQuery
        query.disableUpdates()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: query)
        query.stop()
        
        if query.resultCount == 1 {
            let resultsURL = query.value(ofAttribute: NSMetadataItemURLKey, forResultAt: 0) as! URL
            document = MyDocument(fileURL: resultsURL as URL)
            document?.open(completionHandler: { (success: Bool) -> Void in
                if success {
                    print("Success")
                    self.textField.text = self.document?.userText
                    self.iCloudURL = resultsURL as URL
                } else {
                    print("Could not open file")
                }
            })
        } else {
            if let url = iCloudURL {
                document = MyDocument(fileURL: url)
                document?.save(to: url, for: .forCreating, completionHandler: { (success: Bool) -> Void in
                    if success {
                        print("iCloud create ok!")
                    } else {
                        print("iCloud not created")
                    }
                })
            }
        }
    }
    
    @objc func handleSorttablePopupClosing(notification: Notification) {
        let sortingVC = notification.object as! SortSubtableViewController
        let sortValue = sortingVC.sortOptions.selectedSegmentIndex
        sortSubtableNumbers[selectedCategoryNumber] = sortValue
        print(sortSubtableNumbers)
        
        kvStorage.set(sortSubtableNumbers, forKey: "sortSubtable")
        kvStorage.synchronize()
        //        //        defaultValues.set(sortSubtableOption, forKey: "sortSubtable")
        //
        //        subTableArticles = [[Articles]]()
        //        populateSubtable()
        //
        self.listTableView.reloadData()
        //        self.filesCollectionView.reloadData()
        //
        //        let indexPath = IndexPath(row: 0, section: 0)
        //        subTableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
    }

    @objc func handleSortFilesPopupClosing(notification: Notification) {
        let sortingVC = notification.object as! SortItemsViewController
        let sortValue = sortingVC.sortOptions.selectedSegmentIndex
        sortCollectionViewNumbers[selectedCategoryNumber] = sortValue
        print(sortSubtableNumbers)
        
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
    
    
    // MARK: - FUNCTIONS
    
    func addNewItem(title: String?) {
        switch categories[selectedCategoryNumber] {
        case "Publications":
            if let newTag = title {
                let newGroup = PublicationGroup(context: context)
                newGroup.tag = newTag
                newGroup.dateModified = Date()
                newGroup.sortNumber = "2"
                
                saveCoreData()
                
                publicationGroups.append(newGroup)
//                populateSubtable()
                self.listTableView.reloadData()
            }
            
        default:
            print("Default 111")
            
        }
    }
    
    func loadCoreData() {

        let requestPublicationGroups: NSFetchRequest<PublicationGroup> = PublicationGroup.fetchRequest()
        requestPublicationGroups.sortDescriptors = [NSSortDescriptor(key: "sortNumber", ascending: true)]
        do {
            publicationGroups = try context.fetch(requestPublicationGroups)
        } catch {
            print("Error loading groups")
        }

        let requestAuthors: NSFetchRequest<Author> = Author.fetchRequest()
        requestAuthors.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            authors = try context.fetch(requestAuthors)
        } catch {
            print("Error loading authors")
        }
        
        let request: NSFetchRequest<Publication> = Publication.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "filename", ascending: true)]
        do {
            publications = try context.fetch(request)
        } catch {
            print("Error loading publications")
        }
    }
    
    func readIcloudDriveFolders() {
        print(publicationsURL!)
        let fileManager = FileManager.default
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: publicationsURL!, includingPropertiesForKeys: nil)
            for file in fileURLs {
                if file.lastPathComponent.range(of:".icloud") != nil {
                    print(file.lastPathComponent)
                } else {
                    let thumbnails = getThumbnail(url: file, pageNumber: 0)
                    let newFile = File(filename: file.lastPathComponent, title: "", year: -2000, thumbnails: [thumbnails], category: "Publications", rank: 50, note: "No notes", dateCreated: Date(), dateModified: Date())

                    files.append(newFile)
                }
            }
        } catch {
            print("Error while enumerating files \(publicationsURL.path): \(error.localizedDescription)")
        }
        print(files)
    }
    
    func setupDefaultCoreDataTypes() {
        
        // ADD "NO AUTHOR"
        let arrayAuthors = authors
        if arrayAuthors.first(where: {$0.name == "No author"}) == nil {
            let newAuthor = Author(context: context)
            newAuthor.name = "No author"
            newAuthor.sortNumber = "0"
            saveCoreData()
        }
        
        // ADD "ALL ARTICLES"
        let arrayPublicationGroups = publicationGroups
        if arrayPublicationGroups.first(where: {$0.tag == "All publications"}) == nil {
            let newPublicationGroup = PublicationGroup(context: context)
            newPublicationGroup.tag = "All publications"
            newPublicationGroup.dateModified = Date()
            newPublicationGroup.sortNumber = "0"
            saveCoreData()
        }
        
        // ADD "UNFILED ARTICLES"
        if publicationGroups.first(where: {$0.tag == "Unfiled"}) == nil {
            let unfiledGroup = PublicationGroup(context: context)
            unfiledGroup.tag = "Unfiled"
            unfiledGroup.dateModified = Date()
            unfiledGroup.sortNumber = "1"
            saveCoreData()
        }
        loadCoreData()
    }
    
    func setupUI() {
        
//        noAuthor
        
//        publicationsURL = appDelegate.publicationURL!
        
        privateDatabase = container().privateCloudDatabase
        recordZone = CKRecordZone(zoneName: "PublicationZone")
        
        if let zone = recordZone {
            privateDatabase?.save(zone, completionHandler: { (recordzone, error) in
                if (error != nil) {
                    print(error!)
                    print("Failed to create custom record zone")
                } else {
                    print("Saved record zone")
                }
            })
        }
        
        kvStorage = NSUbiquitousKeyValueStore()
        loadDefaultValues()
        
        navigationController?.isNavigationBarHidden = true
        self.notesView.isHidden = true
        
    }
    
    func getURL() -> URL {
        let baseURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)
//        let fullURL = baseURL?.appendingPathComponent("Documents/test.txt")
        let fullURL = baseURL?.appendingPathComponent("Documents", isDirectory: true)

        return fullURL!
    }
    
    //WORK IN PROGRESS
    func loadIcloudData() {
        let query = CKQuery(recordType: "Publications", predicate: NSPredicate(value: true))
        privateDatabase?.perform(query, inZoneWith: nil) { (records, error) in
            guard let records = records else {return}
            let record = records[0]
            DispatchQueue.main.async {
                let thumbnail = record.object(forKey: "Thumbnail") as! CKAsset
                self.largeThumbnail.image = UIImage(contentsOfFile: thumbnail.fileURL.path)
            }
        }
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
        metaDataQuery?.predicate = NSPredicate(format: "%K like 'savefile.txt'", NSMetadataItemFSNameKey)
        metaDataQuery?.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.metadataQueryDidFinishGathering), name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: metaDataQuery!)
        metaDataQuery?.start()
        
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

    func copyDocumentsToiCloudDrive() {
        var error: NSError?
        let iCloudDocumentsURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents/myCloudTest")
        print(iCloudDocumentsURL!)
        do{
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
                print(currentFilename)
                if publications.first(where: {$0.filename == currentFilename}) == nil {
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
                    saveFileToCoreData()
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
            destination.sortCollectionViewValue = sortCollectionViewNumbers[selectedCategoryNumber]
            destination.sortCollectionViewStrings = sortCollectionViewStrings
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
    }
    
    public func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        
    }
    
    func saveFileToCoreData() {
        switch categories[selectedCategoryNumber] {
        case "Publications":
            let newPublication = Publication(context: context)
            newPublication.filename = filenameString.text
            newPublication.thumbnail = largeThumbnail.image
            newPublication.dateCreated = Date()
            newPublication.title = titleString.text
            newPublication.year = Int16(yearString.text!)!
            newPublication.rank = rankOutlet.value
            newPublication.note = notesTextView.text
            
            let allPublications = publicationGroups.first(where: {$0.tag == "All publications"})
            newPublication.addToPublicationGroup(allPublications!)
            let unfiledGroup = publicationGroups.first(where: {$0.tag == "Unfiled"})
            newPublication.addToPublicationGroup(unfiledGroup!)
            
            let noAuthor = authors.first(where: {$0.name == "No author"})
            newPublication.author = noAuthor
            
            publications.append(newPublication)
            
            saveCoreData()
            
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
    
    
//    func checkIfFileExists(filename: String, url: URL, category: String) {
//        let alertController = UIAlertController(title: "File " + filename + " already exists", message: nil, preferredStyle: .alert)
//
//        alertController.addTextField(configurationHandler: { (textField: UITextField) -> Void in
//            textField.placeholder = filename
//        })
//
//        let okAction = UIAlertAction(title: "Ok", style: .default ) { (_) in
//            self.currentFilename = self.textField.text
//            if self.publications.first(where: {$0.filename == self.currentFilename}) == nil {
//
//            } else {
//
//            }
//        }
//
//        let cancelAction = UIAlertAction(title: "Cancel", style: .default ) { (_) in }
//
//        alertController.addAction(okAction)
//        alertController.addAction(cancelAction)
//
//        self.present(alertController, animated: true, completion: nil)
//    }
    
    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func saveToIcloud(url: URL) {
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
    }
    
    func getThumbnail(url: URL, pageNumber: Int) -> UIImage {
        let document = PDFDocument(url: url)
        let page: PDFPage!
        page = document?.page(at: pageNumber)!
        let pageThumbnail = page.thumbnail(of: CGSize(width: 210, height: 297), for: .artBox)
        return pageThumbnail
    }
    
    
    
    // MARK: - Table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sortSubtableStrings[sortSubtableNumbers[selectedSubtableNumber]] {
        case "Tag":
            return publicationGroups.count
        case "Author":
            return authors.count
        case "Year":
            return 1
        case "Modified":
            return 1
        case "Rank":
            return 1
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = listTableView.dequeueReusableCell(withIdentifier: "listTableCell") as! ListCell

        switch categories[selectedCategoryNumber] {
        case "Publications":
            switch sortSubtableStrings[sortSubtableNumbers[selectedSubtableNumber]] {
            case "Tag":
                cell.listLabel.text = publicationGroups[indexPath.row].tag
                cell.listNumberOfItems.text = "0 items"
            case "Author":
                print(indexPath.row)
                cell.listLabel.text = authors[indexPath.row].name
                cell.listNumberOfItems.text = "0 items"
            case "Year":
                cell.listLabel.text = "Nothing yet"
                cell.listNumberOfItems.text = "0 items"
            case "Modified":
                cell.listLabel.text = "Nothing yet"
                cell.listNumberOfItems.text = "0 items"
            case "Rank":
                cell.listLabel.text = "Nothing yet"
                cell.listNumberOfItems.text = "0 items"
            default:
                cell.listLabel.text = "Nothing yet"
                cell.listNumberOfItems.text = "0 items"
            }
            
        default:
            cell.listLabel.text = "Nothing yet"
            cell.listNumberOfItems.text = "0 items"
        }

        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    
    
    // MARK: - Collection View
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.categoriesCV {
            return 7
        } else {
            return publications.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.categoriesCV {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "categoryCell", for: indexPath) as! categoryCell
            switch categories[indexPath.row] {
            case "Publications":
                cell.icon.image = #imageLiteral(resourceName: "PublicationsIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "PublicationsIconSelected")
                cell.number.text = "0"
            case "Manuscripts":
                cell.icon.image = #imageLiteral(resourceName: "ManuscriptsIcon")
                cell.icon.highlightedImage = #imageLiteral(resourceName: "ManuscriptsIconSelected")
                cell.number.text = "10"
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
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "filesCell", for: indexPath) as! filesCell
            switch categories[selectedCategoryNumber] {
            case "Publications":
                cell.label.text = publications[indexPath.row].filename
                cell.thumbnail.image = publications[indexPath.row].thumbnail as! UIImage
            default:
                print("107")
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.categoriesCV {
            selectedCategoryTitle.text = categories[indexPath.row]
            selectedCategoryNumber = indexPath.row
            kvStorage.set(selectedCategoryNumber, forKey: "selectedCategory")
            kvStorage.synchronize()
        } else {
            let currentCell = collectionView.cellForItem(at: indexPath) as! filesCell
            
            if let pub = publications.first(where: {$0.filename == currentCell.label.text}) {
                currentPublication = pub
                titleString.text = currentPublication.title
                rankOutlet.value = currentPublication.rank
                rankValue.text = "\(Int(rankOutlet.value))"
                yearString.text = "\(currentPublication.year)"
                authorString.text = currentPublication.author?.name
                currentPublication.note = notesTextView.text
            }

            filenameString.text = currentCell.label.text
            largeThumbnail.image = currentCell.thumbnail.image
            documentPage = 0

            switch self.categories[self.selectedCategoryNumber] {
            case "Publications":
                documentURL = self.publicationsURL.appendingPathComponent(currentCell.label.text!)
            default:
                print("103")
            }

        }
        

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
