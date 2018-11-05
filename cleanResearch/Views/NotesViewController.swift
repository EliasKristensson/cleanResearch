//
//  NotesViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-10-04.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import UIKit

class NotesViewController: UIViewController {

    var originalShortName: String!
    var originalFilename: String!
//    var localFiles: [[LocalFile]]!
//    var publicationsURL: URL!
//    var docsURL: URL!
    var update = false
    var localFile: LocalFile!
    var index: Int?
    var filenameChanged = false
    var dataManager: DataManager!
    
    @IBOutlet weak var filenameString: UITextField!
    @IBOutlet weak var journalString: UITextField!
    @IBOutlet weak var notesString: UITextField!
    @IBOutlet weak var authorString: UITextField!
    @IBOutlet weak var yearString: UITextField!
    @IBOutlet weak var rankValue: UILabel!
    @IBOutlet weak var rankOutlet: UISlider!
    
    @IBAction func rankSlider(_ sender: Any) {
        rankValue.text = "\(Int(rankOutlet.value))"
        localFile.rank = rankOutlet.value
        update = true
    }
    
    @IBAction func filenameEditingStarting(_ sender: Any) {
        originalShortName = filenameString.text!
        originalFilename = filenameString.text! + ".pdf"
    }
    
    @IBAction func filenameEditing(_ sender: Any) {
        filenameChanged = true
        update = true
    }

    @IBAction func journalStringEditing(_ sender: Any) {
        
        if (journalString.text?.isEmpty)! {
            localFile.journal = "No journal"
        } else {
            localFile.journal = journalString.text
        }
        
        update = true
    }
    
    @IBAction func authorStringEditing(_ sender: Any) {

        if (authorString.text?.isEmpty)! {
            localFile.author = "No author"
        } else {
            localFile.author = authorString.text
        }
        
        update = true
    }
    
    @IBAction func yearStringEditing(_ sender: Any) {
        
        if (yearString.text?.isEmpty)! {
            localFile.year = -2000
        } else {
            let year = Int16(isStringAnInt(stringNumber: yearString.text!))
            localFile.year = year
        }
        
        update = true
    }
    
    @IBAction func rankSliderEditingEndedOutside(_ sender: Any) {
        
        localFile.rank = rankOutlet.value

        update = true
    }
    
    @IBAction func notesStringEditing(_ sender: Any) {
        
        if (notesString.text?.isEmpty)! {
            localFile.note = "No note"
        } else {
            localFile.note = notesString.text
        }
        
        update = true
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var components = localFile.filename.components(separatedBy: ".")
        if components.count > 1 {
            components.removeLast()
        }
        
        originalFilename = localFile.filename
        originalShortName = components.first!
        filenameString.text = components.first!
        journalString.text = localFile.journal!
        yearString.text = "\(localFile.year!)"
        authorString.text = localFile.author!
        rankValue.text = "\(Int(localFile.rank!))"
        rankOutlet.value = localFile.rank!
        notesString.text = localFile.note!
    }

    
    
    
    func checkIfFilenameIsOk() {
        
        if filenameChanged {
            
            let newFilename = filenameString.text! + ".pdf"
            
            if newFilename != originalFilename {
                var found = false
                
                print(newFilename)
                
                //Search for duplicates
                if dataManager.localFiles[0].index(where: { $0.filename == newFilename }) != nil {
                    found = true
                }

                if found {
                    if filenameString.text != originalShortName {
                        alert(title: newFilename + " already exists", message: "Keeping old filename")
                        filenameString.text = originalShortName
                        filenameChanged = false
                    }
                } else {
                    print("New filename ok")
                    
                    let newiURL = dataManager.publicationsURL.appendingPathComponent(newFilename, isDirectory: false)
                    let newlURL = dataManager.docsURL.appendingPathComponent("Publications").appendingPathComponent(newFilename, isDirectory: false)
                    localFile.filename = newFilename
                    localFile.iCloudURL = newiURL
                    localFile.localURL = newlURL
                    print(localFile)
                    
                    //updateIcloud(file: localFiles[0][index!], oldFilename: originalFilename, newFilename: filenameString.text!+".pdf")
                    //updateCoreData(file: localFiles[0][index!], oldFilename: originalFilename, newFilename: filenameString.text!+".pdf")
                    
                    let originiPath = dataManager.publicationsURL.appendingPathComponent(originalFilename)
                    print(originiPath)
                    print(newiURL)
                    do {
                        try FileManager.default.moveItem(at: originiPath, to: newiURL)
                        print("File moved on iCloud")
                    } catch {
                        print("Error moving on iCloud")
                        print(error)
                    }
                    
                    if localFile.downloaded {
                        let originlURL = dataManager.docsURL.appendingPathComponent("Publications").appendingPathComponent(originalFilename)
                        print(originlURL)
                        print(newlURL)
                        do {
                            try FileManager.default.moveItem(at: originlURL, to: newlURL)
                        } catch {
                            print("Error moving locally")
                            print(error)
                        }
                    }
                    
                    //
                    //                currentSelectedFilename = localFiles[0][index!].filename
                    //                populateFilesCV()
                    //                sortFiles()
                    //                filesCollectionView.reloadData()
                    //                attemptScrolling(filename: localFiles[0][index!].filename)
                }
            }
        }

        
    }
    
    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func isStringAnInt(stringNumber: String?) -> Int32 {
        let number = stringNumber?.replacingOccurrences(of: "\"", with: "")
        if let tmpValue = Int32(number!) {
            return tmpValue
        }
        print("String number could not be converted")
        return -2000
    }
    
    override func viewWillDisappear(_ animated: Bool) {

        checkIfFilenameIsOk()
        
        if let index = dataManager.localFiles[0].index(where: { $0.filename == originalFilename } ) {
            dataManager.localFiles[0][index] = localFile
            if update {
                dataManager.localFiles[0][index].dateModified = Date()
            }
        }
        
        NotificationCenter.default.post(name: Notification.Name.closingNotes, object: self)
    }
}
