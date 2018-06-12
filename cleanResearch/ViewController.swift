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

var mainVC: ViewController?

struct File {
    var filename: String
//    var titles: [String]
    var year: Int32
//    var thumbnails: [UIImage]
//    var sectionTitle: String
//    var rank: [Int16]
//    var notes: [String]
//    var dateCreated: [Date]
//    var dateModified: [Date]
//    var currentItems: [Any]
//    var currentItem: Int
}

class categoryCell: UICollectionViewCell {
    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var number: UILabel!
    var favoriteButton: UIButton!
}

class filesCell: UICollectionViewCell {
    
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var label: UILabel!
    
}

class ViewController: UIViewController, UIDocumentPickerDelegate, UIPopoverPresentationControllerDelegate, UIDocumentMenuDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    

    // MARK: - Variables
    var appDelegate: AppDelegate!
    var document: MyDocument?
    let container = CKContainer.default
    var privateDatabase: CKDatabase?
    var currentRecord: CKRecord?
    var recordZone: CKRecordZone?
    var recordID: CKRecordID?
    
    @IBOutlet weak var filesCollectionView: UICollectionView!
    
    
//    let database = CKContainer.default().privateCloudDatabase
//    var articles = [CKRecord]()
    
    var documentURL: URL!
    var documentPage = 0
    var ubiquityURL: URL!
    var kvStorage: NSUbiquitousKeyValueStore!
    var publicationsURL: URL!
    var metaDataQuery: NSMetadataQuery?
    let documentInteractionController = UIDocumentInteractionController()
    let categories: [String] = ["Publications", "Manuscripts", "Presentations", "Proposals", "Supervision", "Teaching", "Patents"]
    var sortCollectionViewBox = CGSize(width: 348, height: 28)
    var selectedCategoryNumber = 0
    var selectedSubtableNumber = 0
    var sortCollectionViewOption: [Int] = [0, 0, 0, 0, 0, 0, 0]
    var sortCollectionViewOptions: [String] = [""]
    var sortSubtableOptions: [String] = [""]
    var sortSubtableOption: [Int] = [0, 0, 0, 0, 0, 0, 0]

    var files = [File]()
    var publications = [String]()
    
    var PDFdocument: PDFDocument!
    var PDFfilename: String!
    
    // MARK: - Outlets
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
        let query = CKQuery(recordType: "Publication", predicate: NSPredicate(value: true))
        privateDatabase?.perform(query, inZoneWith: nil) { (records, error) in
            guard let records = records else {return}
            let record = records[0]
            DispatchQueue.main.async {
                let thumbnail = record.object(forKey: "Thumbnail") as! CKAsset
                self.largeThumbnail.image = UIImage(contentsOfFile: thumbnail.fileURL.path)
            }
        }
        
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
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        mainVC = self
//        document = MyDocument(fileURL: getURL())
//        document?.open(completionHandler: nil)
        
        let app = UIApplication.shared
        appDelegate = app.delegate as! AppDelegate
        
        categoriesCV.delegate = self
        categoriesCV.dataSource = self
        
        setupUI()
        
    }
    
    
    
    
    func setupUI() {
        publicationsURL = appDelegate.pubURL!
        
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
    
    func loadFile() {
        let fileManager = FileManager.default
        ubiquityURL = fileManager.url(forUbiquityContainerIdentifier: nil)
        guard ubiquityURL != nil else {
            print("Unable to access iCloud account")
            return
        }
        ubiquityURL = ubiquityURL?.appendingPathComponent("Documents/savefile.txt")
        metaDataQuery = NSMetadataQuery()
        metaDataQuery?.predicate = NSPredicate(format: "%K like 'savefile.txt'", NSMetadataItemFSNameKey)
        metaDataQuery?.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.metadataQueryDidFinishGathering), name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: metaDataQuery!)
        metaDataQuery?.start()
        
    }
    
    func loadDefaultValues() {
        if let numbers = kvStorage.array(forKey: "sortSubtable") as? [Int] {
            sortSubtableOption = numbers
        } else {
            sortSubtableOption = [0, 0, 0, 0, 0, 0, 0]
        }
        if let numbers = kvStorage.array(forKey: "sortCollectionView") as? [Int] {
            sortCollectionViewOption = numbers
        } else {
            sortCollectionViewOption = [0, 0, 0, 0, 0, 0, 0]
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
                    self.ubiquityURL = resultsURL as URL
                } else {
                    print("Could not open file")
                }
            })
        } else {
            if let url = ubiquityURL {
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
            documentURL = url
            let thumbnail = getThumbnail(url: url)
            largeThumbnail.image = thumbnail
            documentPage = 0
            filenameString.text = url.lastPathComponent
            titleString.text = "Not specified"
            yearString.text = "-2000"
            authorString.text = "No author"
            PDFdocument = PDFDocument(url: url)
            print(url.lastPathComponent)
            
//            performSegue(withIdentifier: "seguePDFViewController", sender: self)
            
            saveToIcloud(url: url)
            downloadFile(fileURL: url)
        }
    }
    
    func isStringAnInt(stringNumber: String) -> Int {
        if let tmpValue = Int(stringNumber) {
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
            sortCollectionViewOptions = ["Filename", "Title", "Year", "Author", "Modified", "Rank"]
            let destination = segue.destination as! SortItemsViewController
            if sortCollectionViewOption[selectedCategoryNumber] > sortCollectionViewOptions.count {
                sortCollectionViewOption[selectedCategoryNumber] = 0
            }
            destination.sortCollectionViewValue = sortCollectionViewOption[selectedCategoryNumber]
            destination.sortCollectionViewStrings = sortCollectionViewOptions
            destination.preferredContentSize = sortCollectionViewBox
            destination.popoverPresentationController?.sourceRect = sortCVButton.bounds
        }
        if (segue.identifier == "segueSortSubtable") {
            sortSubtableOptions = ["Tag", "Year", "Author", "Modified"]
            let destination = segue.destination as! SortSubtableViewController
            if sortSubtableOption[selectedSubtableNumber] > sortSubtableOptions.count {
                sortSubtableOption[selectedSubtableNumber] = 0
            }
            destination.sortValue = 0//sortSubtableOption[selectedSubtableNumber]
            destination.sortStrings = sortSubtableOptions
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
    
    func saveToCoreData() {
//        let newArticle = Articles(context: context)
//
//        let unfiledGroup = articleGroups.first(where: {$0.tag == "Unfiled"})
//        let allArticles = articleGroups.first(where: {$0.tag == "All articles"})
    }
    
    
    func saveToIcloud(url: URL) {
        if let zoneID = recordZone?.zoneID {
            let myRecord = CKRecord(recordType: categories[selectedCategoryNumber], zoneID: zoneID)
            switch categories[selectedCategoryNumber] {
            case "Publications":
                // Saving default values
                let thumbnail = CKAsset(fileURL: url)
                let tag = ["All papers", "Unfiled"]
                myRecord.setObject(url.lastPathComponent as CKRecordValue?, forKey: "Filename")
                myRecord.setObject("No author" as CKRecordValue?, forKey: "Author")
                myRecord.setObject(thumbnail as CKRecordValue?, forKey: "Thumbnail")
                myRecord.setObject(tag as CKRecordValue?, forKey: "Group")
                myRecord.setObject(50 as CKRecordValue?, forKey: "Rank")
                myRecord.setObject("No notes" as CKRecordValue?, forKey: "Note")
                
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
    
    func getThumbnail(url: URL) -> UIImage {
        let document = PDFDocument(url: url)
        let page: PDFPage!
        page = document?.page(at: 0)!
        let pageThumbnail = page.thumbnail(of: CGSize(width: 210, height: 297), for: .artBox)
        return pageThumbnail
    }
    
    // MARK: - Collection View
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.categoriesCV {
            return 7
        } else {
            return 1
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
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedCategoryTitle.text = categories[indexPath.row]
        selectedCategoryNumber = indexPath.row
        kvStorage.set(selectedCategoryNumber, forKey: "selectedCategory")
        kvStorage.synchronize()

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
