//
//  LoadingViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-09-09.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import UIKit
import PDFKit
import CoreData
import CloudKit

class LoadingViewController: UIViewController {

    var appDelegate: AppDelegate!
    var icloudAvailable: Bool!
    let fileManagerDefault = FileManager.default
    var context: NSManagedObjectContext!
    var privateDatabase: CKDatabase?
    let container = CKContainer.default
    var recordZone: CKRecordZone?
    
    var publicationsURL: URL!
    var booksURL: URL!
    var economyURL: URL!
    var manuscriptsURL: URL!
    var proposalsURL: URL!
    var presentationsURL: URL!
    var supervisionsURL: URL!
    var teachingURL: URL!
    var coursesURL: URL!
    var meetingsURL: URL!
    var conferenceURL: URL!
    var reviewsURL: URL!
    var miscellaneousURL: URL!
    var patentsURL: URL!
    var docsURL: URL!
    var iCloudURL: URL! //IS THIS NEEDED?
    var localURL: URL!
    
    let categories: [String] = ["Publications", "Books", "Economy", "Manuscripts", "Presentations", "Proposals", "Supervision", "Teaching", "Patents", "Courses", "Meetings", "Conferences", "Reviews", "Miscellaneous"]

    let fileHandler = FileHandler()
    var dataManager = DataManager()
    
    var localFiles: [[LocalFile]] = [[]]
    
    var progressMonitor = ProgressMonitor()
    let progressMonitorSettings: [CGFloat] = [40, 300, 0.6, 0.8] //Height, Width, grayness, alpha

    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        
        let app = UIApplication.shared
        appDelegate = (app.delegate as! AppDelegate)
        icloudAvailable = appDelegate.iCloudAvailable!
        context = appDelegate.context
        
        self.iCloudURL = self.appDelegate.iCloudURL
        self.docsURL = self.appDelegate.docURL
        self.localURL = self.appDelegate.localURL
        self.publicationsURL = self.appDelegate.publicationURL
        self.booksURL = self.appDelegate.booksURL
        self.economyURL = self.appDelegate.economyURL
        self.manuscriptsURL = self.appDelegate.manuscriptURL
        self.proposalsURL = self.appDelegate.proposalsURL
        self.patentsURL = self.appDelegate.patentsURL
        self.supervisionsURL = self.appDelegate.supervisionURL
        self.teachingURL = self.appDelegate.teachingURL
        self.presentationsURL = self.appDelegate.presentationURL
        self.coursesURL = self.appDelegate.coursesURL
        self.meetingsURL = self.appDelegate.meetingsURL
        self.conferenceURL = self.appDelegate.conferencesURL
        self.reviewsURL = self.appDelegate.reviewsURL
        self.miscellaneousURL = self.appDelegate.miscellaneousURL
        
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
        
        //CUSTOM CLASSES
        dataManager.context = context
        dataManager.recordZone = recordZone
        dataManager.privateDatabase = privateDatabase
        setupProgressMonitor()
        
//        dataManager.icloudURL = iCloudURL //iCloudURL
        dataManager.docsURL = docsURL
        dataManager.localURL = localURL
        dataManager.categories = categories
        dataManager.localFiles = localFiles
        dataManager.publicationsURL = publicationsURL
        dataManager.booksURL = booksURL
        dataManager.economyURL = economyURL
        dataManager.manuscriptsURL = manuscriptsURL
        dataManager.proposalsURL = proposalsURL
        dataManager.patentsURL = patentsURL
        dataManager.supervisionsURL = supervisionsURL
        dataManager.teachingURL = teachingURL
        dataManager.presentationsURL = presentationsURL
        dataManager.coursesURL = coursesURL
        dataManager.meetingsURL = meetingsURL
        dataManager.conferencesURL = conferenceURL
        dataManager.reviewsURL = reviewsURL
        dataManager.miscellaneousURL = miscellaneousURL
        dataManager.categories = categories

        if icloudAvailable {
            sendNotification(text: "Reading iCloud drive folders")
            dataManager.readAllIcloudDriveFolders()
            dataManager.loadCoreData()
//            dataManager.cleanOutEmptyDatabases()
        }
        
        if !icloudAvailable! {
            alert(title: "iCloud Drive not available", message: "Log into your iCloud account and add iCloud Drive services")
        } else {
            performSegue(withIdentifier: "loadMainVC", sender: self)
        }
        

    }
    
    
    func sendNotification(text: String) {
        
        self.view.addSubview(progressMonitor)
        self.view.bringSubview(toFront: progressMonitor)
        progressMonitor.launchMonitor(displayText: text)
        
    }
    
    func setupProgressMonitor() {
        progressMonitor.frame = CGRect(x: self.view.bounds.maxX/2 - progressMonitorSettings[1]/2, y: self.view.bounds.size.height+progressMonitorSettings[0], width: progressMonitorSettings[1], height: progressMonitorSettings[0])
        progressMonitor.settings = progressMonitorSettings
        progressMonitor.backgroundColor = UIColor(displayP3Red: progressMonitorSettings[2], green: progressMonitorSettings[2], blue: progressMonitorSettings[2], alpha: progressMonitorSettings[3])
        progressMonitor.layer.cornerRadius = 12
        progressMonitor.layer.borderWidth = 1
        progressMonitor.layer.borderColor = UIColor(red:255/255, green:255/255, blue:255/255, alpha: progressMonitorSettings[3]).cgColor
        progressMonitor.iPadDimension = [self.view.bounds.maxY, self.view.bounds.maxX]
    }
    
    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            exit(0)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination as! ViewController
        destination.dataManager = dataManager
        destination.categories = categories
        destination.progressMonitor = progressMonitor
//        destination.progressMonitorSettings = progressMonitorSettings
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}





//    func readFilesInFolders(url: URL, type: String, number: Int) {
//        do {
//            let folderURLs = try fileManagerDefault.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
//            localFiles.append([])
//            for folder in folderURLs {
//                if folder.isDirectory()! {
//                    let subfoldersURLs = try fileManagerDefault.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
//                    for subfolder in subfoldersURLs {
//                        if subfolder.isDirectory()! {
//                            let files = try fileManagerDefault.contentsOfDirectory(at: subfolder, includingPropertiesForKeys: nil)
//                            for file in files {
//                                var available = true
//                                let icloudFileURL = file
//                                let filename = handleFilename(icloudURL: icloudFileURL)
//
//
//
//                                let path = type + folder.lastPathComponent + subfolder.lastPathComponent + filename
//                                let localFileURL = docsURL.appendingPathComponent(type).appendingPathComponent(folder.lastPathComponent).appendingPathComponent(subfolder.lastPathComponent).appendingPathComponent(filename)
//
//                                let localCopy = fileManagerDefault.fileExists(atPath: localFileURL.path)
//
//                                let thumbnail = handleThumbnail(icloudURL: icloudFileURL, localURL: localFileURL, localExist: localCopy)
//
//                                if icloudFileURL.lastPathComponent.range(of:".icloud") != nil {
//                                    available = false
//                                }
//
//                                let newFile = LocalFile(label: filename, thumbnail: thumbnail, favorite: "No", filename: filename, journal: nil, year: nil, category: type, rank: nil, note: "No notes", dateCreated: Date(), dateModified: Date(), author: nil, groups: [nil], parentFolder: subfolder.lastPathComponent, grandpaFolder: folder.lastPathComponent, available: available, filetype: nil, iCloudURL: icloudFileURL, localURL: localFileURL, path: path, downloading: false, downloaded: localCopy, uploaded: nil, size: getSize(url: icloudFileURL))
//                                localFiles[number].append(newFile)
//
//                            }
//                        } else {
//                            var available = true
//                            let icloudFileURL = subfolder
//                            let filename = handleFilename(icloudURL: icloudFileURL)
//                            let path = type + folder.lastPathComponent + filename
//                            let localFileURL = docsURL.appendingPathComponent(type).appendingPathComponent(folder.lastPathComponent).appendingPathComponent(filename)
//                            let localCopy = fileManagerDefault.fileExists(atPath: localFileURL.path)
//
//                            let thumbnail = handleThumbnail(icloudURL: icloudFileURL, localURL: localFileURL, localExist: localCopy)
//
//                            if icloudFileURL.lastPathComponent.range(of:".icloud") != nil {
//                                available = false
//                            }
//
//                            let newFile = LocalFile(label: filename, thumbnail: thumbnail, favorite: "No", filename: filename, journal: nil, year: nil, category: type, rank: nil, note: "No notes", dateCreated: Date(), dateModified: Date(), author: nil, groups: [nil], parentFolder: "Uncategorized", grandpaFolder: folder.lastPathComponent, available: available, filetype: nil, iCloudURL: icloudFileURL, localURL: localFileURL, path: path, downloading: false, downloaded: localCopy, uploaded: nil, size: getSize(url: icloudFileURL))
//                            localFiles[number].append(newFile)
//
//                        }
//                    }
//                } else {
//                    var available = true
//                    let icloudFileURL = folder
//                    let filename = handleFilename(icloudURL: icloudFileURL)
//                    let path = type + folder.lastPathComponent + filename
//                    let localFileURL = docsURL.appendingPathComponent(type).appendingPathComponent(folder.lastPathComponent).appendingPathComponent(filename)
//                    let localCopy = fileManagerDefault.fileExists(atPath: localFileURL.path)
//
//                    let thumbnail = handleThumbnail(icloudURL: icloudFileURL, localURL: localFileURL, localExist: localCopy)
//
//                    if icloudFileURL.lastPathComponent.range(of:".icloud") != nil {
//                        available = false
//                    }
//
//                    let newFile = LocalFile(label: filename, thumbnail: thumbnail, favorite: "No", filename: filename, journal: nil, year: nil, category: type, rank: nil, note: "No notes", dateCreated: Date(), dateModified: Date(), author: nil, groups: [nil], parentFolder: "Uncategorized", grandpaFolder: folder.lastPathComponent, available: available, filetype: nil, iCloudURL: icloudFileURL, localURL: localFileURL, path: path, downloading: false, downloaded: localCopy, uploaded: nil, size: getSize(url: icloudFileURL))
//                    localFiles[number].append(newFile)
//
//                }
//
//            }
//        } catch {
//            print("Error while reading " + type + " folders")
//        }
//
//    }
//
//    func readIcloudDriveFolders() {
//        localFiles = [[]]
//
//        for type in categories{
//            switch type {
//            case "Publications":
//                do {
//                    let fileURLs = try fileManagerDefault.contentsOfDirectory(at: publicationsURL!, includingPropertiesForKeys: nil)
//                    for file in fileURLs {
//                        var available = true
//                        let icloudFileURL = file
//                        let filename = handleFilename(icloudURL: icloudFileURL)
//                        let path = type + filename
//                        let localFileURL = docsURL.appendingPathComponent("Publications").appendingPathComponent(filename)
//
//                        let localCopy = fileManagerDefault.fileExists(atPath: localFileURL.path)
//
//                        let thumbnail = handleThumbnail(icloudURL: icloudFileURL, localURL: localFileURL, localExist: localCopy)
//
//                        if icloudFileURL.lastPathComponent.range(of:".icloud") != nil {
//                            available = false
//                        }
//
//                        let newFile = LocalFile(label: file.lastPathComponent, thumbnail: thumbnail, favorite: "No", filename: filename, journal: "No journal", year: -2000, category: "Publications", rank: 50, note: "No notes", dateCreated: Date(), dateModified: Date(), author: "No author", groups: ["All publications"], parentFolder: nil, grandpaFolder: nil, available: available, filetype: nil, iCloudURL: icloudFileURL, localURL: localFileURL, path: path, downloading: false, downloaded: localCopy, uploaded: nil, size: getSize(url: icloudFileURL))
//                        localFiles[0].append(newFile)
//                    }
//                } catch {
//                    print("Error while enumerating files \(publicationsURL.path): \(error.localizedDescription)")
//                }
//            case "Economy":
//                readFilesInFolders(url: economyURL, type: type, number: 1)
//            case "Manuscripts":
//                readFilesInFolders(url: manuscriptsURL, type: type, number: 2)
//            case "Presentations":
//                readFilesInFolders(url: presentationsURL, type: type, number: 3)
//            case "Proposals":
//                readFilesInFolders(url: proposalsURL, type: type, number: 4)
//            case "Supervision":
//                readFilesInFolders(url: supervisionsURL, type: type, number: 5)
//            case "Teaching":
//                readFilesInFolders(url: teachingURL, type: type, number: 6)
//            case "Patents":
//                readFilesInFolders(url: patentsURL, type: type, number: 7)
//            case "Courses":
//                readFilesInFolders(url: coursesURL, type: type, number: 8)
//            case "Meetings":
//                readFilesInFolders(url: meetingsURL, type: type, number: 9)
//            case "Reviews":
//                readFilesInFolders(url: reviewsURL, type: type, number: 10)
//            case "Miscellaneous":
//                readFilesInFolders(url: miscellaneousURL, type: type, number: 11)
//            default:
//                print("Default 122")
//            }
//        }
//    }
//
//    func handleFilename(icloudURL: URL) -> String {
//        var filename = String()
//        if icloudURL.lastPathComponent.range(of:".icloud") != nil {
//            filename = icloudURL.deletingPathExtension().lastPathComponent
//            filename.remove(at: filename.startIndex)
//        } else {
//            filename = icloudURL.lastPathComponent
//        }
//        return filename
//    }
//
//    func handleThumbnail(icloudURL: URL, localURL: URL, localExist: Bool) -> UIImage {
//        var thumbnail = UIImage()
//
//        //        if icloudURL.lastPathComponent.range(of:".icloud") != nil {
//        //            thumbnail = getThumbnail(url: icloudURL, pageNumber: 0)
//        //        } else {
//        //            thumbnail = getThumbnail(url: icloudURL, pageNumber: 0)
//        //        }
//
//        thumbnail = getThumbnail(url: icloudURL, pageNumber: 0)
//        if localExist {
//            thumbnail = getThumbnail(url: localURL, pageNumber: 0)
//        }
//        return thumbnail
//    }
//
//    func getThumbnail(url: URL, pageNumber: Int) -> UIImage {
//        var pageThumbnail = #imageLiteral(resourceName: "FileOffline")
//        if url.lastPathComponent.range(of:".jpg") != nil {
//            pageThumbnail = #imageLiteral(resourceName: "JpgIcon")
//            if url.lastPathComponent.range(of:".icloud") == nil {
//                if let data = try? Data(contentsOf: url) {
//                    pageThumbnail = UIImage(data: data)!
//                }
//            }
//
//        } else if url.lastPathComponent.range(of:".pdf") != nil {
//            if let document = PDFDocument(url: url) {
//                let page: PDFPage!
//                page = document.page(at: pageNumber)!
//                pageThumbnail = page.thumbnail(of: CGSize(width: 210, height: 297), for: .artBox)
//            }
//        } else if url.lastPathComponent.range(of:".tiff") != nil {
//            pageThumbnail = #imageLiteral(resourceName: "TIFF")
//            if url.lastPathComponent.range(of:".icloud") == nil {
//                if let data = try? Data(contentsOf: url) {
//                    pageThumbnail = UIImage(data: data)!
//                }
//            }
//        } else if url.lastPathComponent.range(of:".png") != nil {
//            pageThumbnail = #imageLiteral(resourceName: "PNG")
//            if url.lastPathComponent.range(of:".icloud") == nil {
//                if let data = try? Data(contentsOf: url) {
//                    pageThumbnail = UIImage(data: data)!
//                }
//            }
//        } else if url.lastPathComponent.range(of:".m") != nil {
//            pageThumbnail = #imageLiteral(resourceName: "M")
//        } else if url.lastPathComponent.range(of:".ai") != nil {
//            pageThumbnail = #imageLiteral(resourceName: "AI")
//        } else if url.lastPathComponent.range(of:".eps") != nil {
//            pageThumbnail = #imageLiteral(resourceName: "EPS")
//        } else if url.lastPathComponent.range(of:".pptx") != nil || url.lastPathComponent.range(of:".ppt") != nil {
//            pageThumbnail = #imageLiteral(resourceName: "PowerpointIcon")
//        } else if url.lastPathComponent.range(of:".docx") != nil || url.lastPathComponent.range(of:".doc") != nil {
//            pageThumbnail = #imageLiteral(resourceName: "WordIcon")
//        } else if url.lastPathComponent.range(of:".xlsx") != nil || url.lastPathComponent.range(of:".xlsm") != nil {
//            pageThumbnail = #imageLiteral(resourceName: "ExcelIcon")
//        } else if url.lastPathComponent.range(of:".key") != nil {
//            pageThumbnail = #imageLiteral(resourceName: "KeynoteIcon")
//        } else if url.lastPathComponent.range(of:".txt") != nil {
//            pageThumbnail = #imageLiteral(resourceName: "TXT")
//        }
//        return pageThumbnail
//    }
//
//    func getSize(url: URL) -> String {
//        var fileSize: UInt64 = 0
//        var sizeString: String = "134 kb"
//
//        do {
//            let attr = try fileManagerDefault.attributesOfItem(atPath: url.path)
//            fileSize = attr[FileAttributeKey.size] as! UInt64
//
//        } catch {
//            print("Error: \(error)")
//        }
//
//        if fileSize < 1000 {
//            sizeString = "\(fileSize)" + " b"
//        } else if fileSize >= 1000 && fileSize < 1000000 {
//            //            let tmp = (Double(fileSize)/1000).rounded()
//            sizeString = "\(fileSize/1000)" + " kb"
//        } else if fileSize >= 1000000 && fileSize < 1000000000 {
//            let tmp = (Double(fileSize)/100000).rounded()/10
//            sizeString = "\(tmp)" + " Mb"
//        } else if fileSize >= 1000000000 {
//            let tmp = (Double(fileSize)/100000000).rounded()/10
//            sizeString = "\(tmp)" + " Gb"
//        }
//
//        return sizeString
//    }
