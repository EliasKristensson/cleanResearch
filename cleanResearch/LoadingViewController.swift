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

    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
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
    var workDocsURL: URL!
    var hiringURL: URL!
    var travelURL: URL!
    var miscellaneousURL: URL!
    var patentsURL: URL!
    var reportsURL: URL!
    var projectsURL: URL!
    var docsURL: URL!
    var notesURL: URL!
    var localURL: URL!
    
    let categories: [String] = ["Recently", "Publications", "Books", "Economy", "Manuscripts", "Presentations", "Proposals", "Supervision", "Teaching", "Patents", "Courses", "Meetings", "Conferences", "Reviews", "Work documents", "Travel", "Notes", "Miscellaneous", "Reading list", "Memos", "Settings", "Bulletin board", "Search", "Reports", "Projects", "Fast folder"]

    let fileHandler = FileHandler()
    var dataManager = DataManager()
    var pdfViewManager = PDFViewManager()
    var navigator: Navigator!
    
    var localFiles: [[LocalFile]] = [[]]
    var orderedCategories: [Categories] = []
    
    var progressMonitor = ProgressMonitor()
    let progressMonitorSettings: [CGFloat] = [40, 300, 0.6, 0.8] //Height, Width, grayness, alpha

    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.isNavigationBarHidden = true
        
        loadingIndicator.startAnimating()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.readingFilesFinished), name: Notification.Name.readingFilesFinished, object: nil)
        
        let app = UIApplication.shared
        appDelegate = (app.delegate as! AppDelegate)
        icloudAvailable = appDelegate.iCloudAvailable!
        context = appDelegate.context
        
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
        self.workDocsURL = self.appDelegate.workDocsURL
        self.hiringURL = self.appDelegate.hiringURL
        self.travelURL = self.appDelegate.travelURL
        self.notesURL = self.appDelegate.notesURL
        self.miscellaneousURL = self.appDelegate.miscellaneousURL
        self.reportsURL = self.appDelegate.reportsURL
        self.projectsURL = self.appDelegate.projectsURL
        
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
        navigator = Navigator(categoryList: categories)
        navigator.selectedCategory = "Recently"
        setupProgressMonitor()
        
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
        dataManager.workDocsURL = workDocsURL
        dataManager.hiringURL = hiringURL
        dataManager.travelURL = travelURL 
        dataManager.miscellaneousURL = miscellaneousURL
        dataManager.reportsURL = reportsURL
        dataManager.notesURL = notesURL
        dataManager.projectsURL = projectsURL
        dataManager.categories = categories
        dataManager.navigator = navigator

        pdfViewManager.dataManager = dataManager
        
        if icloudAvailable {
            dataManager.loadCoreData()
            orderedCategories = dataManager.categoriesCD.sorted(by: {($0.numberViews, Int16.max - $0.originalOrder) > ($1.numberViews, Int16.max - $1.originalOrder)})
            dataManager.setupDefaultCoreDataTypes()
            dataManager.readAllIcloudDriveFolders()
        } else {
            alert(title: "iCloud Drive not available", message: "Log into your iCloud account and add iCloud Drive services")
        }
        
    }
    
    
    @objc func readingFilesFinished() {
        sendNotification(text: "Reading iCloud drive folders")
        performSegue(withIdentifier: "loadMainVC", sender: self)
    }
    
    func sendNotification(text: String) {
        DispatchQueue.main.async {
            self.progressMonitor.launchMonitor(displayText: text)
        }
    }
    
    func setupProgressMonitor() {
        print("setupProgressMonitor")
        
        if UIDevice.current.orientation.isLandscape {
            if self.view.bounds.maxX < self.view.bounds.maxY { //Works
                progressMonitor.frame = CGRect(x: self.view.bounds.maxY/2 - progressMonitorSettings[1]/2, y: self.view.bounds.size.height+progressMonitorSettings[0], width: progressMonitorSettings[1], height: progressMonitorSettings[0])
                progressMonitor.iPadDimension = [self.view.bounds.maxX, self.view.bounds.maxY] // [y,x]
            } else { //Normal
                progressMonitor.frame = CGRect(x: self.view.bounds.maxX/2 - progressMonitorSettings[1]/2, y: self.view.bounds.size.width+progressMonitorSettings[0], width: progressMonitorSettings[1], height: progressMonitorSettings[0])
                progressMonitor.iPadDimension = [self.view.bounds.maxY, self.view.bounds.maxX]
            }
        } else {
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
    
    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            exit(0)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        loadingIndicator.stopAnimating()
        
        let destination = segue.destination as! ViewController
        destination.dataManager = dataManager
        destination.navigator = navigator
        destination.pdfViewManager = pdfViewManager
        destination.categories = categories
        destination.progressMonitor = progressMonitor
        destination.orderedCategories = orderedCategories
        destination.progressMonitorSettings = progressMonitorSettings
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .all
    }
    
}

