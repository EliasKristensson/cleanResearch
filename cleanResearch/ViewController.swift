//
//  ViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-04-04.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import UIKit
import CloudKit

var mainVC: ViewController?

class ViewController: UIViewController, UIDocumentPickerDelegate {

    // MARK: - Variables
    var document: MyDocument?
    
    var documentURL: URL?
    var ubiquityURL: URL?
    var metaDataQuery: NSMetadataQuery?
    let documentInteractionController = UIDocumentInteractionController()
    
    // MARK: - Outlets
    @IBOutlet weak var publicationIcon: UIButton!
    @IBOutlet weak var publicationsNumber: UILabel!
    @IBOutlet weak var manuscriptIcon: UIButton!
    @IBOutlet weak var presentationIcon: UIButton!
    @IBOutlet weak var proposalsIcon: UIButton!
    @IBOutlet weak var supervisionIcon: UIButton!
    @IBOutlet weak var teachingIcon: UIButton!
    @IBOutlet weak var patentsIcon: UIButton!
    @IBOutlet weak var selectedCategoryTitle: UILabel!
    @IBOutlet weak var selectedCategoryIcon: UIImageView!
    
    @IBOutlet weak var textField: UITextView!
    
    @IBAction func tappedSave(_ sender: Any) {
        document?.updateChangeCount(.done)
    }

    // MARK: - Categories IBActions
    @IBAction func publicationIconTapped(_ sender: Any) {
        selectedCategoryIcon.center = publicationIcon.center
        selectedCategoryTitle.text = "Publications"
    }
    @IBAction func manuscriptIconTapped(_ sender: Any) {
        selectedCategoryIcon.center = manuscriptIcon.center
        selectedCategoryTitle.text = "Manuscripts"
    }
    @IBAction func presentationIconTapped(_ sender: Any) {
        selectedCategoryIcon.center = presentationIcon.center
        selectedCategoryTitle.text = "Presentations"
    }
    @IBAction func proposalsIconTapped(_ sender: Any) {
        selectedCategoryIcon.center = proposalsIcon.center
        selectedCategoryTitle.text = "Proposals"
    }
    @IBAction func supervisionIconTapped(_ sender: Any) {
        selectedCategoryIcon.center = supervisionIcon.center
        selectedCategoryTitle.text = "Supervision"
    }
    @IBAction func teachingIconTapped(_ sender: Any) {
        selectedCategoryIcon.center = teachingIcon.center
        selectedCategoryTitle.text = "Teaching"
    }
    @IBAction func patentsIconTapped(_ sender: Any) {
        selectedCategoryIcon.center = patentsIcon.center
        selectedCategoryTitle.text = "Patents"
    }
    
    @IBAction func importTapped(_ sender: Any) {
    
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        mainVC = self
        document = MyDocument(fileURL: getURL())
        document?.open(completionHandler: nil)
        setupUI()
    }
    
    
    func getURL() -> URL {
        let baseURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)
        let fullURL = baseURL?.appendingPathComponent("Documents/test.txt")
        let tmp = baseURL?.appendingPathComponent("Documents", isDirectory: true)
        let dirURL = tmp?.appendingPathComponent("Articles", isDirectory: true)
        print(dirURL!)
        do {
            try FileManager.default.createDirectory(at: dirURL!, withIntermediateDirectories: false, attributes: nil)
            print("Success")
        } catch let error as NSError {
            print(error.localizedDescription);
        }

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

    func setupUI() {
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
        print(iCloudDocumentsURL)
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
    
    

    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

