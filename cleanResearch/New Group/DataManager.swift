//
//  localFileManager.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-10-22.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import Foundation
import UIKit
import CloudKit
import CoreData
import PDFKit



class DataManager {
    
    var localFiles: [[LocalFile]] = [[]]
    var hiringFiles: [LocalFile] = []
    var categories: [String] = [""]
    
    var publicationsURL: URL!
    var booksURL: URL!
    var economyURL: URL!
    var manuscriptsURL: URL!
    var proposalsURL: URL!
    var presentationsURL: URL!
    var supervisionsURL: URL!
    var teachingURL: URL!
    var patentsURL: URL!
    var coursesURL: URL!
    var meetingsURL: URL!
    var conferencesURL: URL!
    var reviewsURL: URL!
    var workDocsURL: URL!
    var hiringURL: URL!
    var travelURL: URL!
    var notesURL: URL!
    var miscellaneousURL: URL!
    var reportsURL: URL!
    var projectsURL: URL!
    var docsURL: URL!
    var localURL: URL!
    
    var privateDatabase: CKDatabase! = nil
    var recordZone: CKRecordZone! = nil
    
    var publicationsCD: [Publication] = []
    var authorsCD: [Author] = []
    var booksCD: [Book] = []
    var journalsCD: [Journal] = []
    var publicationGroupsCD: [PublicationGroup] = []
    var booksGroupsCD: [BooksGroup] = []
    var projectCD: [Project] = []
    var expensesCD: [Expense] = []
    var bookmarksCD: [Bookmarks] = []
    var fundCD: [FundingOrganisation] = []
    var categoriesCD: [Categories] = []
    var recentCD: [Recent] = []
    var applicantCD: [Applicant] = []
    var favoritesCD: [Favorites] = []
    var memosCD: [Memo] = []
    var gradesCD: [Grade] = []
    var readingListCD: [ReadingList] = []
    var bulletinCD: [BulletinBoard] = []
    var notesCD: [Notes] = []
    var fastFolderCD: FastFolder?
    var examsCD: [Exams] = []
    var studentCD: [Student] = []
    
    var copiedAnnotation: [PDFAnnotation] = []

    var iCloudLoaded = false
    
    var isSearching = false
    var searchString: String = ""
    var searchResult: [LocalFile] = []
    var fullSearch: [SearchResult] = []
    
    var pubOption: Int = 0
    var economyOption: Int = 0
    var workDocOption: Int = 0
    var fastFolders: [String] = []
    var fastFolderContent: FastFolderContent?
    
    var context: NSManagedObjectContext!

    var progressMonitor: ProgressMonitor!
    var mainView: UIView!
    
    private let fileManagerDefault = FileManager.default
    private let fileHandler = FileHandler()
    var navigator: Navigator!
    
    var progress: Float = 0
    var maxProgress: Float = 1
    let types = ["Publications", "Projects", "Expenses", "FundingOrganisation", "Bookmarks", "Memos", "Books", "Favorites"]
    
    func addExpense(amount: Int32, OH: Int16, comment: String, reference: String, type: String, year: Int16) {
        
        let currentProject = projectCD[navigator.selected.tableNumber]
        let newExpense = Expense(context: context)
        
        newExpense.type = type
        newExpense.amount = amount
        newExpense.overhead = OH
        newExpense.dateAdded = Date()
        newExpense.active = true
        newExpense.comment = comment
        newExpense.reference = reference
        newExpense.years = year
        newExpense.idNumber = Int64.random(in: 1...50000)
        newExpense.pdfURL = nil
        
        currentProject.addToExpense(newExpense)
        
        newExpense.project = currentProject
        expensesCD.append(newExpense)
        
        saveCoreData()
        loadCoreData()
        
        saveToIcloud(url: nil, type: "Expense", object: newExpense)
    }
    
    func addFileToCoreData(file: LocalFile) {
        print("addFileToCoreData: " + file.filename)
        
        if file.category == "Publications" {
            
            let newPublication = Publication(context: context)
            
            newPublication.filename = file.filename
            newPublication.thumbnail = fileHandler.getThumbnail(icloudURL: publicationsURL.appendingPathComponent(file.filename), localURL: file.localURL, localExist: file.downloaded, pageNumber: 0)
            newPublication.dateCreated = file.dateCreated
            newPublication.dateModified = file.dateModified
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
                newAuthor.name = file.author
                newAuthor.sortNumber = "1"
                newPublication.author = newAuthor
            } else {
                newPublication.author = authorsCD.first(where: {$0.name == file.author})
            }
            
            if journalsCD.first(where: {$0.name == file.journal}) == nil {
                let newJournal = Journal(context: context)
                newJournal.name = file.journal
                newJournal.sortNumber = "1"
                newPublication.journal = newJournal
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
                    newPublication.addToPublicationGroup(newGroup)
                }
            }
            
            publicationsCD.append(newPublication)
            
            saveCoreData()
            loadCoreData()
            
            print("Saved " + newPublication.filename! + " to core data.")
            
        } else if file.category == "Books" {
            
            let newBook = Book(context: context)
            
            newBook.filename = file.filename
            newBook.dateCreated = file.dateCreated
            newBook.dateModified = file.dateModified
            newBook.note = file.note
            newBook.favorite = file.favorite

            let favoriteGroup = booksGroupsCD.first(where: {$0.tag == "Favorites"})
            if file.favorite == "Yes" {
                newBook.favorite = "Yes"
                newBook.addToBooksGroup(favoriteGroup!)
            } else {
                newBook.favorite = "No"
                newBook.removeFromBooksGroup(favoriteGroup!)
            }
            
            for group in file.groups {
                if let tmp = booksGroupsCD.first(where: {$0.tag == group}) {
                    newBook.addToBooksGroup(tmp)
                } else {
                    let newGroup = BooksGroup(context: context)
                    newGroup.tag = group
                    newGroup.dateModified = Date()
                    newGroup.sortNumber = "3"
                    newBook.addToBooksGroup(newGroup)
                }
            }
            
            booksCD.append(newBook)
            
            saveCoreData()
            loadCoreData()
            
            print("Saved book " + newBook.filename! + " to core data.")
        }
    }
    
    func addFileToBulletin(bulletin: String, file: LocalFile) -> String {
        print("addFileToBulletin")
        
        var message = ""
        if let bulletinBoard = bulletinCD.first(where: { $0.bulletinName == bulletin }) {
            if bulletinBoard.filename?.first(where: {$0 == file.filename}) == nil {
                if bulletinBoard.filename == nil {
                    bulletinBoard.filename = [file.filename]
                } else {
                    bulletinBoard.filename?.append(file.filename)
                }
                if bulletinBoard.path == nil {
                    bulletinBoard.path = [file.path]
                } else {
                    bulletinBoard.path?.append(file.path)
                }
                if bulletinBoard.category == nil {
                    bulletinBoard.category = [file.category]
                } else {
                    bulletinBoard.category?.append(file.category)
                }
                bulletinBoard.dateModified = Date()
                
                message = "File added to " + bulletinBoard.bulletinName!
                
                saveCoreData()
                loadCoreData()
            } else {
                return "File already exists in bulletin board"
            }
        } else {
            return "Could not add bulletin board"
        }
        return message
    }
    
    func addNewItem(title: String?, number: [String?]) {
        
        if navigator.selected.category == "Publications" {
            if let newTag = title {
                let newGroup = PublicationGroup(context: context)
                newGroup.tag = newTag
                newGroup.dateModified = Date()
                newGroup.sortNumber = "3"
                
                publicationGroupsCD.append(newGroup)
                
                saveCoreData()
                loadCoreData()
                
            }
            
        } else if navigator.selected.category == "Books" {
            if let newTag = title {
                let newGroup = BooksGroup(context: context)
                newGroup.tag = newTag
                newGroup.dateModified = Date()
                newGroup.sortNumber = "3"
                
                booksGroupsCD.append(newGroup)
                
                saveCoreData()
                loadCoreData()
                
            }
        } else if navigator.selected.category == "Economy" {
            
            if let newTitle = title {
                if let amount = number[0] {
                    if let currency = number[1] {
                        
                        let formatter = DateFormatter()
                        formatter.dateFormat = "yyyy-MM-dd"
                        var dateComponents = DateComponents()
                        dateComponents.year = 1
                        var deadline = Calendar.current.date(byAdding: dateComponents, to: Date())
                        if let tmp = formatter.date(from: number[2]!) {
                            deadline = tmp
                        }
                        
                        if self.economyOption == 0 {
                        
                            let amountReceived = isStringAnInt(stringNumber: amount)
                            let newProject = Project(context: context)
                            newProject.name = newTitle
                            newProject.dateModified = Date()
                            newProject.dateCreated = Date()
                            newProject.amountReceived = amountReceived
                            newProject.amountRemaining = amountReceived
                            newProject.currency = currency
                            newProject.deadline = deadline
                            
                            saveToIcloud(url: nil, type: "Project", object: newProject)
                            
                            projectCD.append(newProject)
                            
                        } else if self.economyOption == 2 {
                            let approxAmount = isStringAnInt(stringNumber: amount)
                            let newFund = FundingOrganisation(context: context)
                            newFund.name = newTitle
                            newFund.amount = Int64(approxAmount)
                            newFund.currency = currency
                            newFund.deadline = deadline
                            
                            saveToIcloud(url: nil, type: "Fund", object: newFund)
                            
                            fundCD.append(newFund)
                            
                        }
                        saveCoreData()
                        loadCoreData()
                    }
                }
            }
        } else if navigator.selected.category == "Memos" {
            
            let newMemo = Memo(context: context)
            newMemo.color = "Yellow"
            newMemo.tag = title
            newMemo.dateCreated = Date()
            newMemo.dateModified = Date()
            newMemo.title = "Untitled"
            newMemo.text = "Here's your new note"
            newMemo.lines = [""]
            newMemo.id = Int64.random(in: 1...50000)
            
            memosCD.append(newMemo)
            
            saveCoreData()
            loadCoreData()
            
        } else if navigator.selected.category == "Bulletin board" {
            
            let newCategory: [String] = []
            let newBulletin = BulletinBoard(context: context)
            newBulletin.bulletinName = title
            newBulletin.dateModified = Date()
            newBulletin.category = newCategory
            newBulletin.filename = newCategory
            newBulletin.path = newCategory
            
            bulletinCD.append(newBulletin)
            
            saveCoreData()
            loadCoreData()

        }
        
        
    }
    
    func addBookToGroup(filename: String, group: BooksGroup) {
        print("addBookToGroup")
        
        let number = categories.index(where: { $0 == "Books" })
        if let index = localFiles[number!].index(where: {$0.filename == filename}) {
            localFiles[number!][index].groups.append(group.tag)
            updateIcloud(file: localFiles[number!][index], oldFilename: nil, newFilename: nil, expense: nil, project: nil, type: "Books", bookmark: nil, fund: nil)
            updateCoreData(file: localFiles[number!][index], oldFilename: nil, newFilename: nil)
        }
    }
    
    func addFileToRecent(file: LocalFile) {
        print("addFileToRecent()")
        
        let items = recentCD.filter{ $0.path! == file.path }
        
        if items.isEmpty {
            let newFile = Recent(context: context)
            newFile.filename = file.filename
            newFile.category = file.category
            newFile.dateOpened = Date()
            newFile.path = file.path
            newFile.timesOpened = 0
            newFile.favorite = false
            
            recentCD.append(newFile)
            
        } else {
            
            let oldFile = items.first!
            oldFile.dateOpened = Date()
            oldFile.timesOpened = oldFile.timesOpened + 1
            
            print("Updated file in recent")
        }
        
        saveCoreData()
        loadCoreData()
    }
    
    func addNewApplicant(name: String, path: String, announcement: String) {
        print("addNewApplicant")

        let newApplicant = Applicant(context: context)
        newApplicant.name = name
        newApplicant.path = path
        newApplicant.age = 0
        newApplicant.announcement = announcement
        newApplicant.grade = 5
        newApplicant.qualifies = true
        newApplicant.notes = "No notes yet"
        newApplicant.education = "Education not added yet"
        newApplicant.degree = "No degree added yet"
        
        applicantCD.append(newApplicant)
        
        print("Added file to applicant")
        
        saveCoreData()
        loadCoreData()
    }

    func addOrUpdateGradeFile(file: LocalFile, type: String, show: Bool) {
        if let gradeData = gradesCD.first(where: {$0.path == file.path}) {
            gradeData.type = type
            gradeData.show = show
            
        } else {
            let newGradeFile = Grade(context: context)
            newGradeFile.filename = file.filename
            newGradeFile.type = type
            newGradeFile.path = file.path
            newGradeFile.show = show
            newGradeFile.grade = 0 //ADD IN THE FUTURE
            
            gradesCD.append(newGradeFile)
        }
        
        for item in gradesCD {
            print(item)
        }
        
        saveCoreData()
        loadCoreData()
    }

    func addPublicationToGroup(filename: String, group: PublicationGroup) {
        print("addPublicationToGroup")
        
        let number = categories.index(where: { $0 == "Publications" })
        // LOCAL FILES & iCLOUD
        if let index = localFiles[number!].index(where: {$0.filename == filename}) {
            localFiles[number!][index].groups.append(group.tag)
            updateIcloud(file: localFiles[number!][index], oldFilename: nil, newFilename: nil, expense: nil, project: nil, type: "Publications", bookmark: nil, fund: nil)
            updateCoreData(file: localFiles[number!][index], oldFilename: nil, newFilename: nil)
        }
    }
    
    func addToBookmark(file: LocalFile, bookmark: Bookmarks) {
        if file.category == "Publications" {
            if let currentPublication = publicationsCD.first(where: {$0.filename == file.filename}) {
                currentPublication.bookmarks = bookmark
            }
        } else if file.category == "Books" {
            if let currentBook = booksCD.first(where: {$0.filename == file.filename}) {
                currentBook.bookmarks = bookmark
            }
        }
        
    }
    
    func addOrRemoveFileFromFavorite(file: LocalFile) {
        print("addOrRemoveFileFromFavorite")
        
        let items = favoritesCD.filter{ $0.path! == file.path }
        
        if items.isEmpty {
            let newFile = Favorites(context: context)
            newFile.filename = file.filename
            newFile.category = file.category
            newFile.dateModified = Date()
            newFile.path = file.path
            
            favoritesCD.append(newFile)
            
            print("Added file to favorites")
            
        } else {

            let oldFile = items.first!
            context.delete(oldFile)
            print("Removed file from favorites")

        }
        
        saveCoreData()
        loadCoreData()
        
        
    }
    
    func addOrRemoveFileFromReadingList(file: LocalFile) {
        print("addOrRemoveFileFromReadingList")
        
        let items = readingListCD.filter{ $0.path! == file.path }
        
        if items.isEmpty {
            let newFile = ReadingList(context: context)
            newFile.filename = file.filename
            newFile.category = file.category
            newFile.dateModified = Date()
            newFile.path = file.path
            
            readingListCD.append(newFile)
            
            print("Added file to reading list")
            
        } else {
            
            let oldFile = items.first!
            context.delete(oldFile)
            print("Removed file from reading list")
            
        }
        
        saveCoreData()
        loadCoreData()
    }
    
    func amountReceivedChanged(amountReceived: Int32) {
        if projectCD.count >= navigator.selected.tableNumber {
            let currentProject = projectCD[navigator.selected.tableNumber]
            currentProject.amountReceived = amountReceived
            currentProject.amountRemaining = currentProject.amountReceived
            
            saveCoreData()
            loadCoreData()
        }
    }
    
    func assignPublicationToAuthor(filename: String, authorName: String) {
        print("assignPublicationToAuthor")
        
        let number = categories.index(where: { $0 == "Publications" })
        // LOCAL FILES
        if let index = localFiles[number!].index(where: {$0.filename == filename}) {
            localFiles[number!][index].author = authorName
            localFiles[number!][index].dateModified = Date()
            
            updateIcloud(file: localFiles[number!][index], oldFilename: nil, newFilename: nil, expense: nil, project: nil, type: "Publications", bookmark: nil, fund: nil)
            updateCoreData(file: localFiles[number!][index], oldFilename: nil, newFilename: nil)
        }
        
    }
    
    func assignPublicationToJournal(filename: String, journalName: String) {
        print("assignPublicationToJournal")
        
        let number = categories.index(where: { $0 == "Publications" })
        if navigator.selected.category == "Publications" {
            
            // LOCAL FILES
            if let index = localFiles[number!].index(where: {$0.filename == filename}) {
                localFiles[number!][index].journal = journalName
                localFiles[number!][index].dateModified = Date()
                
                updateIcloud(file: localFiles[number!][index], oldFilename: nil, newFilename: nil, expense: nil, project: nil, type: "Publications", bookmark: nil, fund: nil)
                updateCoreData(file: localFiles[number!][index], oldFilename: nil, newFilename: nil)
            }
        }
    }

    func calcMaxProgress() {
        print("calcMaxProgress()")
        
        maxProgress = 0
        for type in types {
            self.cloudKitLoadRecords(type: type) { (records, error) -> Void in
                if let error = error {
                    print(error)
                } else {
                    if let records = records {
                        self.maxProgress = self.maxProgress + Float(records.count)
                        print(self.maxProgress)
                    }
                }
            }
            switch type {
            case "Bookmarks":
                maxProgress = maxProgress + Float(bookmarksCD.count)
            case "Books":
                maxProgress = maxProgress + Float(booksCD.count)
            case "Expenses":
                maxProgress = maxProgress + Float(expensesCD.count)
            case "Favorites":
                maxProgress = maxProgress + Float(favoritesCD.count)
            case "FundingOrganisation":
                maxProgress = maxProgress + Float(fundCD.count)
            case "Memos":
                maxProgress = maxProgress + Float(memosCD.count)
            case "Projects":
                maxProgress = maxProgress + Float(projectCD.count)
            case "Publications":
                maxProgress = maxProgress + Float(publicationsCD.count)
            default:
                print("Default 401")
            }
        }
    }
    
    func checkForNewFiles() {
        print("checkForNewFiles")
        
        var reload = 0
        for i in 0..<categories.count{
            if categories[i] != "Recently" {
                let (number, url) = getCategoryNumberAndURL(name: categories[i])
                reload += searchFolders(categoryURL: url!, categoryNumber: number)
            }
        }
        if reload > 0 {
            NotificationCenter.default.post(name: Notification.Name.reload, object: nil)
        }
    }
    
    func cleanOutEmptyDatabases() {
        print("cleanOutEmptyDatabases")

        for item in bulletinCD {
            context.delete(item)
        }
        
        saveCoreData()
        loadCoreData()
    }

    func cloudKitLoadRecords(type: String, result: @escaping (_ objects: [CKRecord]?, _ error: Error?) -> Void) {
        // predicate
        var predicate = NSPredicate(value: true)
        // query
        let cloudKitQuery = CKQuery(recordType: type, predicate: predicate)
        
        // records to store
        var records = [CKRecord]()
        
        //operation basis
        let publicDatabase = CKContainer.default().privateCloudDatabase
        
        // recurrent operations function
        var recurrentOperationsCounter = 101
        func recurrentOperations(cursor: CKQueryCursor?){
            let recurrentOperation = CKQueryOperation(cursor: cursor!)
            recurrentOperation.recordFetchedBlock = { (record:CKRecord!) -> Void in
                //                print("-> cloudKitLoadRecords - recurrentOperations - fetch \(recurrentOperationsCounter)")
                recurrentOperationsCounter += 1
                records.append(record)
            }
            recurrentOperation.queryCompletionBlock = { (cursor: CKQueryOperation.Cursor?, error: Error?) -> Void in
                if ((error) != nil) {
                    //                    print("-> cloudKitLoadRecords - recurrentOperations - error - \(String(describing: error))")
                    result(nil, error)
                } else {
                    if cursor != nil {
                        //                        print("-> cloudKitLoadRecords - recurrentOperations - records \(records.count) - cursor \(cursor!.description)")
                        recurrentOperations(cursor: cursor!)
                    } else {
                        //                        print("-> cloudKitLoadRecords - recurrentOperations - records \(records.count) - cursor nil - done")
                        result(records, nil)
                    }
                }
            }
            publicDatabase.add(recurrentOperation)
        }
        // initial operation
        var initialOperationCounter = 1
        let initialOperation = CKQueryOperation(query: cloudKitQuery)
        initialOperation.recordFetchedBlock = { (record:CKRecord!) -> Void in
            //            print("-> cloudKitLoadRecords - initialOperation - fetch \(initialOperationCounter)")
            initialOperationCounter += 1
            records.append(record)
        }
        initialOperation.queryCompletionBlock = { (cursor: CKQueryOperation.Cursor?, error: Error?) -> Void in
            if ((error) != nil) {
                //                print("-> cloudKitLoadRecords - initialOperation - error - \(String(describing: error))")
                result(nil, error)
            } else {
                if cursor != nil {
                    //                    print("-> cloudKitLoadRecords - initialOperation - records \(records.count) - cursor \(cursor!.description)")
                    recurrentOperations(cursor: cursor!)
                } else {
                    //                    print("-> cloudKitLoadRecords - initialOperation - records \(records.count) - cursor nil - done")
                    result(records, nil)
                }
            }
        }
        publicDatabase.add(initialOperation)
    }
    
    func compareLocalFilesWithCoreData() {
        print("compareLocalFilesWithCoreData()")
        
        if let number = categories.index(where: { $0 == "Publications" }) {
            for i in 0..<localFiles[number].count {
                if let matchedCoreDataFile = publicationsCD.first(where: {$0.filename == localFiles[number][i].filename}) {
                    updateLocalFilesWithCoreData(index: i, category: number, coreDataFile: matchedCoreDataFile)
                }
            }
        }
        
        if let number = categories.index(where: { $0 == "Books" }) {
            for i in 0..<localFiles[number].count {
                if let matchedCoreDataFile = booksCD.first(where: {$0.filename == localFiles[number][i].filename}) {
                    updateLocalFilesWithCoreData(index: i, category: number, coreDataFile: matchedCoreDataFile)
                }
            }
        }

    }

    func createBlankPDF(category: String) -> String {
        print("createBlankPDF")
        
        guard
            let url = Bundle.main.url(forResource: "BlankPDF", withExtension: "pdf"),
            let blankPDF = PDFDocument(url: url)
            else { fatalError() }
        
        let dateString = self.fileHandler.getDeadline(date: Date(), string: nil, option: "Seconds")
        let filename = dateString.string! + ".pdf"
        let iCloudURL = notesURL.appendingPathComponent(filename)
        blankPDF.write(to: iCloudURL)
        
        return filename
    }
    
    func createExam(viewController: UIViewController) {
        let newExam = UIAlertController(title: "New exam", message: "Enter information of exam", preferredStyle: .alert)
        newExam.addTextField(configurationHandler: { (name: UITextField) -> Void in
            name.placeholder = "Enter exam name"
        })
        newExam.addTextField(configurationHandler: { (problems: UITextField) -> Void in
            problems.placeholder = "Problems: 5"
        })
        newExam.addTextField(configurationHandler: { (date: UITextField) -> Void in
            date.placeholder = "Date: 2020-01-01"
        })
        newExam.addTextField(configurationHandler: { (maxScore: UITextField) -> Void in
            maxScore.placeholder = "Maxscore: 40"
        })
        newExam.addTextField(configurationHandler: { (passLimit: UITextField) -> Void in
            passLimit.placeholder = "Pass limit: 20"
        })
        newExam.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            let name = newExam.textFields?[0].text
            let problems = Int16((newExam.textFields?[1].text)!)
            let date = newExam.textFields?[2].text
            let maxSore = Int((newExam.textFields?[3].text)!)
            let passLimit = Double((newExam.textFields?[4].text)!)
            
            self.newExam(course: name!, date: date!, problems: problems!, maxScore: maxSore!, passLimit: passLimit!)
            
            newExam.dismiss(animated: true, completion: nil)
            NotificationCenter.default.post(name: Notification.Name.createdExam, object: self)
            
        }))
        newExam.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            newExam.dismiss(animated: true, completion: nil)
        }))
        viewController.present(newExam, animated: true, completion: nil)
    }
    
    func delay() {
        
    }
    
    func deleteAlliCloudRecords(type: String, trigg: Bool) {
        print("deleteAlliCloudRecords")

        self.cloudKitLoadRecords(type: type) { (records, error) -> Void in
            if let error = error {
                print(error)
            } else {
                if let records = records {
                    var count = 1
                    for recond in records {
                        self.privateDatabase.delete(withRecordID: recond.recordID) { (recordID, error) -> Void in
                            guard let recordID = recordID else {
                                print("Error deleting record. ", error.debugDescription)
                                return
                            }
                            print("\(count)" + ". Deleted record: ", recordID.recordName)
                        }
                        count += 1
                        sleep(1)
                    }
                    if trigg {
                        switch type{
                        case "Publications":
                            self.uploadPublications()
                        case "Books":
                            self.uploadBooks()
                        default:
                            print("Default 401")
                        }
                    }
                }
            }
        }
//
////        let pred = NSPredicate(value: true)
////        let sort = NSSortDescriptor(key: "creationDate", ascending: false)
////        let query = CKQuery(recordType: "Publications", predicate: pred)
////        query.sortDescriptors = [sort]
////
////        let operation = CKQueryOperation(query: query)
//////        operation.desiredKeys = ["filename"]
////        operation.resultsLimit = 50
////
////
////        operation.recordFetchedBlock = { record in
////            print(record)
////        }
////        print("Finished")
//
////        var request: CKQuery
////        request.fetchLimit = 1
////        request.predicate = NSPredicate(format: "name = %@", txtFieldName.text)
//
//
////        let title = "Berrocal2006.pdf"
////
////        let predicate = NSPredicate(format: "self contains %@", title)
////        let query = CKQuery(recordType: "Publications", predicate: predicate)
//
//        let query = CKQuery(recordType: "Publications", predicate: NSPredicate(value: true))
////        query.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: false)]
//        self.privateDatabase.perform(query, inZoneWith: self.recordZone.zoneID) { (records, error) in
//            guard let records = records else {return}
////            print(records.count)
//            for recond in records {
//                print(recond.object(forKey: "Filename") as! String)
//                self.privateDatabase.delete(withRecordID: recond.recordID) { (recordID, error) -> Void in
//                    guard let recordID = recordID else {
//                        print("Error deleting record: ", error)
//                        return
//                    }
//                    print("Successfully deleted record: ", recordID.recordName)
//                }
//            }
//        }
    }
    
    func deleteListItem(currentItem: String, type: String?) {
        switch navigator.selected.category {
        case "Publications":
            if type == "Tag" {
                let groupToDelete = publicationGroupsCD.first(where: {$0.tag! == currentItem})
                context.delete(groupToDelete!)
                
                saveCoreData()
                loadCoreData()
                
            } else if type == "Author" {
                let noAuthor = authorsCD.first(where: {$0.name == "No author"})
                let authorToDelete = authorsCD.first(where: {$0.name! == currentItem})
                let articlesBelongingToAuthor = authorToDelete?.publication
                context.delete(authorToDelete!)
                for item in articlesBelongingToAuthor! {
                    let tmp = item as! Publication
                    tmp.author = noAuthor
                }
                
                saveCoreData()
                loadCoreData()
                
            } else if type == "Journal" {
                
                let noJournal = journalsCD.first(where: {$0.name == "No journal"})
                let journalsToDelete = journalsCD.first(where: {$0.name == currentItem})
                let articlesBelongingToJournal = journalsToDelete?.publication
                context.delete(journalsToDelete!)
                for item in articlesBelongingToJournal! {
                    let tmp = item as! Publication
                    tmp.journal = noJournal
                }
                
                saveCoreData()
                loadCoreData()
            }
            
            
            
        case "Books":
            let groupToDelete = booksGroupsCD.first(where: {$0.tag! == currentItem})
            context.delete(groupToDelete!)
            
            saveCoreData()
            loadCoreData()
        default:
            print("Default 145")
        }
    }
    
    func deleteMemo(id: Int64) {
        if let currentMemo = memosCD.first(where: {$0.id == id}) {
            
            context.delete(currentMemo)
            
            saveCoreData()
            loadCoreData()
        }
    }
    
    func editExam(exam: Exams, viewController: UIViewController) {
        let editedExam = UIAlertController(title: "Edit exam", message: "Edit exam name", preferredStyle: .alert)
        editedExam.addTextField(configurationHandler: { (name: UITextField) -> Void in
            name.placeholder = exam.course
        })
        editedExam.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            let name = editedExam.textFields?[0].text
            exam.course = name

            self.saveCoreData()
            self.loadCoreData()

            editedExam.dismiss(animated: true, completion: nil)
            NotificationCenter.default.post(name: Notification.Name.createdExam, object: self)

        }))
        editedExam.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
            editedExam.dismiss(animated: true, completion: nil)
        }))
        viewController.present(editedExam, animated: true, completion: nil)
    }
    
    func findAuthorAndYear(filename: String) -> (author: String, year: Int32) {
        var author = ""
        var year: Int32 = -2000
        
        var index = filename.count
        for char in "0123456789" {
            if let idx = filename.indexes(of: String(char)).first {
                if idx < index {
                    index = idx
                }
            }
        }
        
        author = String(filename.prefix(index))
        let start = filename.index(filename.startIndex, offsetBy: index)
        if filename.count > index + 3 {
            let end = filename.index(filename.startIndex, offsetBy: index + 4)
            let range = start ..< end
            
            year = isStringAnInt(stringNumber: String(filename[range]))
        }
        
        return (author, year)
        
    }
    
    func isStringAnInt(stringNumber: String?) -> Int32 {
        let number = stringNumber?.replacingOccurrences(of: "\"", with: "")
        if let tmpValue = Int32(number!) {
            return tmpValue
        }
        print("String number could not be converted")
        return -2000
    }
    
    func getCategoryNumberAndURL(name: String) -> (number: Int, url: URL?) {
        print("getCategoryNumberAndURL: " + name)
        
        let number = categories.index(where: { $0 == name })
        var url: URL!
        
        if name == "Publications" {
            url = publicationsURL
        } else if name == "Recently" {
            url = nil
        } else if name == "Economy" {
            url = economyURL
        } else if name == "Books" {
            url = booksURL
        } else if name == "Manuscripts" {
            url = manuscriptsURL
        } else if name == "Presentations" {
            url = presentationsURL
        } else if name == "Proposals" {
            url = proposalsURL
        } else if name == "Supervision" {
            url = supervisionsURL
        } else if name == "Teaching" {
            url = teachingURL
        } else if name == "Patents" {
            url = patentsURL
        } else if name == "Courses" {
            url = coursesURL
        } else if name == "Meetings" {
            url = meetingsURL
        } else if name == "Conferences" {
            url = conferencesURL
        } else if name == "Reviews" {
            url = reviewsURL
        } else if name == "Work documents" {
            url = workDocsURL
        } else if name == "Travel" {
            url = travelURL
        } else if name == "Notes" {
            url = notesURL
        } else if name == "Miscellaneous" {
            url = miscellaneousURL
        } else if name == "Reports" {
            url = reportsURL
        } else if name == "Projects" {
            url = projectsURL
        }
        return (number!, url)
    }
    
    func getBookmark(file: LocalFile) -> Bookmarks? {
        if file.category == "Publications" {
            if let currentPublication = publicationsCD.first(where: {$0.filename == file.filename}) {
                return currentPublication.bookmarks
            }
            
        } else if file.category == "Books" {
            if let currentBook = booksCD.first(where: {$0.filename == file.filename}) {
                return currentBook.bookmarks
            }
            
        } else {
            
            return bookmarksCD.first(where: {$0.path == file.path})
        }
        return nil
    }
    
    func getDelimiter(str: String, max: Int) -> String {
        let diff = max - str.count
        let tab = "\t"
        var returnString = str
        
        if diff >= 0 && diff < 4 {
            returnString = returnString + tab
        } else if diff >= 4 && diff < 13 {
            returnString = returnString + tab + tab
        } else if diff >= 13 && diff < 16 {
            returnString = returnString + tab + tab + tab
//        }  else if diff >= 12 && diff < 16 {
//            returnString = returnString + tab + tab + tab + tab
        }
        
        return returnString
    }
    
    func getNote(file: LocalFile) -> String? {
        if let currentNote = notesCD.first(where: {$0.path == file.path}) {
            print("Note found using path")
            return currentNote.text
        }
//        else {
//            if let currentNote = notesCD.first(where: {$0.filename == file.filename && $0.category == file.category}) {
//                print("Note found using filename")
//                return currentNote.text
//            }
//        }
        return nil
    }
    
    func getSleep(type: String) -> UInt32 {
        switch type {
        case "Bookmarks":
            return UInt32(2*bookmarksCD.count)
        case "Books":
            return UInt32(2*booksCD.count)
        case "Expenses":
            return UInt32(2*expensesCD.count)
        case "Favorites":
            return UInt32(2*favoritesCD.count)
        case "FundingOrganisation":
            return UInt32(2*fundCD.count)
        case "Memos":
            return UInt32(2*memosCD.count)
        case "Projects":
            return UInt32(2*projectCD.count)
        case "Publications":
            return UInt32(2*publicationsCD.count)
        default:
            return UInt32(1)
        }
    }
    
    func getFolderStructure() {
        print("getFolderStructure()")
        
        navigator.folderStructure.subFolders = [[]]
        
        for category in categories {
            do {
                let (number, url) = self.getCategoryNumberAndURL(name: category)
                if url != nil {
                    let folderURLs = try fileManagerDefault.contentsOfDirectory(at: url!, includingPropertiesForKeys: nil)
                    navigator.folderStructure.categories[number] = category
                    navigator.folderStructure.mainFolders[number] = []
                    let folders = folderURLs.filter({$0.isDirectory() == true})
                    for folder in folders {
                        navigator.folderStructure.mainFolders[number].append(folder.lastPathComponent)
                    }
                    
                    navigator.folderStructure.mainFolders[number] = navigator.folderStructure.mainFolders[number].sorted(by: {$0 < $1})
                    
                    navigator.folderStructure.subFolders.append([[]])
                    navigator.folderStructure.subFolders[0].append([])
                    navigator.folderStructure.subURL.append([[]])
                    navigator.folderStructure.subURL[0].append([])

                    for i in 0..<navigator.folderStructure.mainFolders[number].count {
                        if i == 0 {
                            navigator.folderStructure.subFolders[number][i] = []
                            navigator.folderStructure.subURL[number][i] = []
                        } else {
                            navigator.folderStructure.subFolders[number].append([])
                            navigator.folderStructure.subURL[number].append([])
                        }
                        for folder in folders {
                            if folder.lastPathComponent == navigator.folderStructure.mainFolders[number][i] {
                                let subFolderULRs = try fileManagerDefault.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
                                let subfolders = subFolderULRs.filter({$0.isDirectory() == true})
                                for subfolder in subfolders {
                                    navigator.folderStructure.subFolders[number][i].append(subfolder.lastPathComponent)
                                    navigator.folderStructure.subURL[number][i].append(subfolder)
                                }
                            }
                        }
                    }
                } else {
                    navigator.folderStructure.subFolders.append([[]])
                    navigator.folderStructure.subURL.append([[]])
                }
            } catch {
                print(error)
            }
            
        }
    }
    
    func loadCoreData() {
        print("loadCoreData")
        
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
        
        let requestBooks: NSFetchRequest<Book> = Book.fetchRequest()
        requestBooks.sortDescriptors = [NSSortDescriptor(key: "filename", ascending: true)]
        do {
            booksCD = try context.fetch(requestBooks)
        } catch {
            print("Error loading books")
        }
        
        let requestBooksGroup: NSFetchRequest<BooksGroup> = BooksGroup.fetchRequest()
        requestBooksGroup.sortDescriptors = [NSSortDescriptor(key: "tag", ascending: true)]
        do {
            booksGroupsCD = try context.fetch(requestBooksGroup)
        } catch {
            print("Error loading book groups")
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
        
        let requestBookmarks: NSFetchRequest<Bookmarks> = Bookmarks.fetchRequest()
        requestBookmarks.sortDescriptors = [NSSortDescriptor(key: "filename", ascending: true)]
        do {
            bookmarksCD = try context.fetch(requestBookmarks)
        } catch {
            print("Error loading bookmarks")
        }
        
        let requestCategories: NSFetchRequest<Categories> = Categories.fetchRequest()
        requestCategories.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            categoriesCD = try context.fetch(requestCategories)
        } catch {
            print("Error loading categories")
        }
        
        let requestFunds: NSFetchRequest<FundingOrganisation> = FundingOrganisation.fetchRequest()
        requestFunds.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            fundCD = try context.fetch(requestFunds)
        } catch {
            print("Error loading funds")
        }
        
        let requestRecent: NSFetchRequest<Recent> = Recent.fetchRequest()
        requestRecent.sortDescriptors = [NSSortDescriptor(key: "filename", ascending: true)]
        do {
            recentCD = try context.fetch(requestRecent)
        } catch {
            print("Error loading recent")
        }
        
        let requestApplicant: NSFetchRequest<Applicant> = Applicant.fetchRequest()
        requestApplicant.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            applicantCD = try context.fetch(requestApplicant)
        } catch {
            print("Error loading applicants")
        }
        
        let requestFavorites: NSFetchRequest<Favorites> = Favorites.fetchRequest()
        requestFavorites.sortDescriptors = [NSSortDescriptor(key: "filename", ascending: true)]
        do {
            favoritesCD = try context.fetch(requestFavorites)
        } catch {
            print("Error loading favorites")
        }
        
        let requestMemos: NSFetchRequest<Memo> = Memo.fetchRequest()
        requestMemos.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: true)]
        do {
            memosCD = try context.fetch(requestMemos)
        } catch {
            print("Error loading memos")
        }

        let requestGrades: NSFetchRequest<Grade> = Grade.fetchRequest()
        requestMemos.sortDescriptors = [NSSortDescriptor(key: "path", ascending: true)]
        do {
            gradesCD = try context.fetch(requestGrades)
        } catch {
            print("Error loading grades")
        }
        
        let requestReadingList: NSFetchRequest<ReadingList> = ReadingList.fetchRequest()
        requestReadingList.sortDescriptors = [NSSortDescriptor(key: "path", ascending: true)]
        do {
            readingListCD = try context.fetch(requestReadingList)
        } catch {
            print("Error loading reading list")
        }
        
        let requestBulletin: NSFetchRequest<BulletinBoard> = BulletinBoard.fetchRequest()
        requestBulletin.sortDescriptors = [NSSortDescriptor(key: "bulletinName", ascending: true)]
        do {
            bulletinCD = try context.fetch(requestBulletin)
        } catch {
            print("Error loading bulletin board")
        }
        
        let requestNotes: NSFetchRequest<Notes> = Notes.fetchRequest()
        requestNotes.sortDescriptors = [NSSortDescriptor(key: "filename", ascending: true)]
        do {
            notesCD = try context.fetch(requestNotes)
        } catch {
            print("Error loading notes")
        }
        
        let requestFastFolder: NSFetchRequest<FastFolder> = FastFolder.fetchRequest()
        do {
            let tmp = try context.fetch(requestFastFolder)
            if !tmp.isEmpty {
                fastFolderCD = tmp.first!
            }
        } catch {
            print("Error loading fast folder")
        }
        
        let requestExams: NSFetchRequest<Exams> = Exams.fetchRequest()
        requestExams.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        do {
            examsCD = try context.fetch(requestExams)
//            for item in examsCD {
//                item.locked = false
//                context.delete(item)
//            }
        } catch {
            print("Error loading exams")
        }

        let requestStudents: NSFetchRequest<Student> = Student.fetchRequest()
        requestStudents.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            studentCD = try context.fetch(requestStudents)
//            for item in studentCD {
//                context.delete(item)
//            }
        } catch {
            print("Error loading scores")
        }
        
    }
    
    func modifyRecordsOperation(label: String, myRecord: CKRecord, progress: Bool) {
        print("modifyRecordsOperation()")
        
        var ok = true
        let modifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: [myRecord], recordIDsToDelete: nil)
        let configuration = CKOperationConfiguration()
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 10
        
        modifyRecordsOperation.configuration = configuration
        modifyRecordsOperation.modifyRecordsCompletionBlock =
            { records, recordIDs, error in
                if let error = error {
                    ok = false
                    print("Error uploading data: " + error.localizedDescription)
                } else {
                    print(label + " saved to icloud")
                    if progress {
                        NotificationCenter.default.post(name: Notification.Name.uploadProgress, object: self)
                        self.progress = self.progress + 1
                        sleep(1)
                    } else {
                        print("Not progress")
                    }
                }
        }
        self.privateDatabase?.add(modifyRecordsOperation)
        
        if !progress {
            if ok {
                progressMonitor.text = label + " saved to icloud"
                NotificationCenter.default.post(name: Notification.Name.postNotification, object: self)
            } else {
                progressMonitor.text = label + " not saved to icloud"
                NotificationCenter.default.post(name: Notification.Name.postNotification, object: self)
            }
        }
    }
    
    func newBookmark(file: LocalFile) -> Bookmarks {
        let newBookmark = Bookmarks(context: context)
        newBookmark.path = file.path
        newBookmark.filename = file.filename
        newBookmark.lastPageVisited = 0
        newBookmark.category = file.category
        newBookmark.label = [""]
        newBookmark.page = []
        
        if file.category == "Publications" {
            if let currentPublication = publicationsCD.first(where: {$0.filename == file.filename}) {
                newBookmark.publication = currentPublication
            }
        } else if file.category == "Books" {
            if let currentBook = booksCD.first(where: {$0.filename == file.filename}) {
                newBookmark.book = currentBook
            }
        }
        
        saveCoreData()
        loadCoreData()
        
        return newBookmark
    }
    
    func newExam(course: String, date: String, problems: Int16, maxScore: Int, passLimit: Double) {
        let newExam = Exams(context: context)
        newExam.course = course
        newExam.date = fileHandler.getDeadline(date: nil, string: date, option: nil).date
        newExam.maxScore = Double(maxScore)
        newExam.problems = problems
        newExam.subProblems = [Int](repeating: 1, count: Int(problems))
        newExam.path = ""
        newExam.id = Int64.random(in: 1...50000)
        newExam.locked = false
        newExam.passLimit = passLimit
        
        saveCoreData()
        loadCoreData()
    }
    
    func newScore(name: String, exam: Exams) -> Student? {
        print("newScore()")
        
        if let currentExam = examsCD.first(where: {$0.id == exam.id}) {
            let newScore = Student(context: context)
            newScore.name = name
            newScore.totalScore = 0
            newScore.score = [[Double()]]
            var i = 1
            for sub in exam.subProblems! {
                if i == 1 {
                    newScore.score![0] = [Double](repeating: Double(0), count: sub)
                    i = 2
                } else {
                    newScore.score?.append([Double](repeating: Double(0), count: sub))
                }
            }
            newScore.exam = currentExam
            saveCoreData()
            loadCoreData()

            return newScore
        } else {
            return nil
        }
    }
    
    func readAllIcloudDriveFolders() {
        print("readAllIcloudDriveFolders()")
        
        localFiles = [[]]
        for _ in 0...categories.count {
            localFiles.append([])
        }
        localFiles[0] = []
        
        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: .default)

        for type in self.categories {
            queue.async(group: group) {
                self.readCategory(category: type)
            }
        }

        group.notify(queue: .main) {
            NotificationCenter.default.post(name: Notification.Name.readingFilesFinished, object: self)
        }
    }
    
    func readBooks() {
        print("readBooks")
        
        do {
            let fileURLs = try fileManagerDefault.contentsOfDirectory(at: booksURL!, includingPropertiesForKeys: nil)
            for file in fileURLs {
                var available = true
                let icloudFileURL = file
                let filename = fileHandler.getFilenameFromURL(icloudURL: icloudFileURL)
                let path = "Books" + filename
                let localFileURL = localURL.appendingPathComponent("Books").appendingPathComponent(filename)
                let dates = fileHandler.getDates(url: icloudFileURL)
                let localCopy = fileManagerDefault.fileExists(atPath: localFileURL.path)
                
                let thumbnail = fileHandler.getThumbnail(icloudURL: icloudFileURL, localURL: localFileURL, localExist: localCopy, pageNumber: 0)
                
                if icloudFileURL.lastPathComponent.range(of:".icloud") != nil {
                    available = false
                }
                
                var groups = [String]()
                if let book = booksCD.first(where: {$0.filename == filename}) {
                    for group in book.booksGroup?.allObjects as! [BooksGroup] {
                        groups.append(group.tag!)
                    }
                    
                    var newFile = LocalFile(label: file.lastPathComponent, thumbnail: thumbnail, favorite: "No", filename: filename, journal: nil, year: -2000, category: "Books", rank: 50, note: "No notes", dateCreated: book.dateCreated, dateModified: book.dateModified, author: "No author", groups: groups, parentFolder: nil, grandpaFolder: nil, available: available, filetype: nil, iCloudURL: icloudFileURL, localURL: localFileURL, path: path, downloading: false, downloaded: localCopy, uploaded: nil, size: fileHandler.getSize(url: icloudFileURL), saving: false, views: 0)
                    
                    if let bookmark = getBookmark(file: newFile) {
                        newFile.views = bookmark.timesVisited
                    }
                    
                    let number = categories.index(where: { $0 == "Books" })
                    localFiles[number!].append(newFile)
                    
                } else {
                    // NOT FOUND ON CORE DATA, SET DEFAULT VALUES
                    let newFile = LocalFile(label: file.lastPathComponent, thumbnail: thumbnail, favorite: "No", filename: filename, journal: nil, year: -2000, category: "Books", rank: 50, note: "No notes", dateCreated: dates[0], dateModified: dates[1], author: "No author", groups: ["All books"], parentFolder: nil, grandpaFolder: nil, available: available, filetype: nil, iCloudURL: icloudFileURL, localURL: localFileURL, path: path, downloading: false, downloaded: localCopy, uploaded: nil, size: fileHandler.getSize(url: icloudFileURL), saving: false, views: 0)
                    
                    let number = categories.index(where: { $0 == "Books" })
                    localFiles[number!].append(newFile)
                }
                
            }
        } catch {
            print("Error while enumerating files \(booksURL.path): \(error.localizedDescription)")
        }
    }
    
    func readFastFolder() {
        print("readFastFolder()")
        
        if let folder = fastFolderCD {
            
            let (number, url) = getCategoryNumberAndURL(name: folder.category!)
            var tmp: [String] = []
            var tmp2 = [[LocalFile]]()
            var files = [LocalFile]()
            
            if folder.folderLevel == 0 {
                files = localFiles[number].filter{$0.grandpaFolder == folder.mainFolder}
                for file in files {
                    tmp.append(file.parentFolder!)
                }
                let subfolders = Array(Set(tmp)).sorted()
                for subfolder in subfolders {
                    tmp2.append(files.filter{$0.parentFolder == subfolder})
                }
                fastFolderContent = FastFolderContent(files: tmp2, folder: folder.mainFolder!, subfolders: subfolders, mainURL: url!, folderLevel: Int(folder.folderLevel))
            } else {
                files = localFiles[number].filter{$0.parentFolder == folder.subFolder}
                tmp2.append(files)
                fastFolderContent = FastFolderContent(files: tmp2, folder: folder.subFolder!, subfolders: [folder.subFolder!], mainURL: url!, folderLevel: Int(folder.folderLevel))
            }
        
        }
        
    }
    
    func readCategory(category: String) {
        print("readIcloudDriveFolder(" + category + ")")
        
        switch category {
        case "Recently":
            let number = self.categories.index(where: { $0 == "Recently" })
            self.localFiles[number!] = []
        case "Publications":
            self.readPublications()
        case "Books":
            self.readBooks()
        case "Work documents":
            let (number, url) = self.getCategoryNumberAndURL(name: category)
            self.readFilesInFolder(url: url!, type: category, number: number)
            self.readHiringFolder()
        case "Memos", "Settings", "Reading list", "Bulletin board", "Search":
            print("No folder to read")
        case "Fast folder":
            if let category = self.fastFolderCD?.category {
                let (number, url) = self.getCategoryNumberAndURL(name: category)
                if let folders = self.fastFolderCD?.folders {
                    self.readFilesInSubFolders(url: url!, subfolders: folders, type: category, number: number)
                }
            } else {
                print("No fast folder")
            }
        default:
            let (number, url) = self.getCategoryNumberAndURL(name: category)
            self.readFilesInFolder(url: url!, type: category, number: number)
        }
        
    }
    
    func readFilesInFolder(url: URL, type: String, number: Int) {
        print("readFilesInFolder: " + "\(number)" + " " + categories[number])
        
        localFiles[number] = []
        
        do {
            let folderURLs = try fileManagerDefault.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)

            for folder in folderURLs {
                if !folder.isDirectory()! {
                    //FILES DIRECTLY IN MAIN FOLDER
                    var available = true
                    let icloudFileURL = folder
                    let filename = fileHandler.getFilenameFromURL(icloudURL: icloudFileURL)
                    let path = type + filename
                    let localFileURL = localURL.appendingPathComponent(type).appendingPathComponent(folder.lastPathComponent).appendingPathComponent(filename)
                    let localCopy = fileManagerDefault.fileExists(atPath: localFileURL.path)
                    let dates = fileHandler.getDates(url: icloudFileURL)
                    
                    let thumbnail = fileHandler.getThumbnail(icloudURL: icloudFileURL, localURL: localFileURL, localExist: localCopy, pageNumber: 0)
                    
                    if icloudFileURL.lastPathComponent.range(of:".icloud") != nil {
                        available = false
                    }
                    
                    var newFile = LocalFile(label: filename, thumbnail: thumbnail, favorite: "No", filename: filename, journal: nil, year: nil, category: type, rank: nil, note: "No notes", dateCreated: dates[0], dateModified: dates[1], author: nil, groups: [nil], parentFolder: "Uncategorized", grandpaFolder: "Uncategorized", available: available, filetype: nil, iCloudURL: icloudFileURL, localURL: localFileURL, path: path, downloading: false, downloaded: localCopy, uploaded: nil, size: fileHandler.getSize(url: icloudFileURL), saving: false, views: 0)
                    
                    if let bookmark = getBookmark(file: newFile) {
                        newFile.views = bookmark.timesVisited
                    }

                    localFiles[number].append(newFile)
                    
                } else {
                    //FILES IN A SUB OR SUBSUBFOLDER
                    let subfoldersURLs = try fileManagerDefault.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)

                    for subfolder in subfoldersURLs {
                        if !subfolder.isDirectory()! {
                            //FILES IN A SUBFOLDER
                            var available = true
                            let icloudFileURL = subfolder
                            let filename = fileHandler.getFilenameFromURL(icloudURL: icloudFileURL)
                            let path = type + folder.lastPathComponent + filename
                            let localFileURL = localURL.appendingPathComponent(type).appendingPathComponent(folder.lastPathComponent).appendingPathComponent(filename)
                            let localCopy = fileManagerDefault.fileExists(atPath: localFileURL.path)
                            let dates = fileHandler.getDates(url: icloudFileURL)
                            
                            let thumbnail = fileHandler.getThumbnail(icloudURL: icloudFileURL, localURL: localFileURL, localExist: localCopy, pageNumber: 0)
                            
                            if icloudFileURL.lastPathComponent.range(of:".icloud") != nil {
                                available = false
                            }
                            
                            var newFile = LocalFile(label: filename, thumbnail: thumbnail, favorite: "No", filename: filename, journal: nil, year: nil, category: type, rank: nil, note: "No notes", dateCreated: dates[0], dateModified: dates[1], author: nil, groups: [nil], parentFolder: "Uncategorized", grandpaFolder: folder.lastPathComponent, available: available, filetype: nil, iCloudURL: icloudFileURL, localURL: localFileURL, path: path, downloading: false, downloaded: localCopy, uploaded: nil, size: fileHandler.getSize(url: icloudFileURL), saving: false, views: 0)
                            
                            if let bookmark = getBookmark(file: newFile) {
                                newFile.views = bookmark.timesVisited
                            }
                            
                            localFiles[number].append(newFile)
                            
                        } else {
                            //FILES IN A SUBSUBFOLDER
                            let files = try fileManagerDefault.contentsOfDirectory(at: subfolder, includingPropertiesForKeys: nil)
                            for file in files {
                                var available = true
                                let icloudFileURL = file
                                let filename = fileHandler.getFilenameFromURL(icloudURL: icloudFileURL)
                                
                                let path = type + folder.lastPathComponent + subfolder.lastPathComponent + filename
                                let localFileURL = localURL.appendingPathComponent(type).appendingPathComponent(folder.lastPathComponent).appendingPathComponent(subfolder.lastPathComponent).appendingPathComponent(filename)
                                
                                let localCopy = fileManagerDefault.fileExists(atPath: localFileURL.path)
                                let dates = fileHandler.getDates(url: icloudFileURL)
                                let thumbnail = fileHandler.getThumbnail(icloudURL: icloudFileURL, localURL: localFileURL, localExist: localCopy, pageNumber: 0)
                                
                                
                                if icloudFileURL.lastPathComponent.range(of:".icloud") != nil {
                                    available = false
                                }
                                
                                var newFile = LocalFile(label: filename, thumbnail: thumbnail, favorite: "No", filename: filename, journal: nil, year: nil, category: type, rank: nil, note: "No notes", dateCreated: dates[0], dateModified: dates[1], author: nil, groups: [nil], parentFolder: subfolder.lastPathComponent, grandpaFolder: folder.lastPathComponent, available: available, filetype: nil, iCloudURL: icloudFileURL, localURL: localFileURL, path: path, downloading: false, downloaded: localCopy, uploaded: nil, size: fileHandler.getSize(url: icloudFileURL), saving: false, views: 0)
                                
                                if let bookmark = getBookmark(file: newFile) {
                                    newFile.views = bookmark.timesVisited
                                }
                                
                                localFiles[number].append(newFile)
                            }
                        }
                    }
                }
            }
        } catch {
            print("Error while reading " + type + " folders")
        }
    }
    
    func readFilesInSubFolders(url: URL, subfolders: [String], type: String, number: Int) {
        print("readFilesInSubFolder: " + "\(number)" + " " + categories[number])
        
        var folderURLs: [URL] = []
        for i in 0..<subfolders.count {
            folderURLs.append(url.appendingPathComponent(subfolders[i], isDirectory: true))
        }
        do {
            for folder in folderURLs {
                print(folder)
                let files = try fileManagerDefault.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
                print(files)
                for file in files {
                    print(file.lastPathComponent)
                    if !file.isDirectory()! {
                        print(file.lastPathComponent)
                        //FILES DIRECTLY IN MAIN SUBFOLDER
//                        var available = true
//                        let icloudFileURL = folder
//                        let filename = fileHandler.getFilenameFromURL(icloudURL: icloudFileURL)
//                        let path = type + filename
//                        let localFileURL = localURL.appendingPathComponent(type).appendingPathComponent(folder.lastPathComponent).appendingPathComponent(filename)
//                        let localCopy = fileManagerDefault.fileExists(atPath: localFileURL.path)
//                        let dates = fileHandler.getDates(url: icloudFileURL)
//
//                        let thumbnail = fileHandler.getThumbnail(icloudURL: icloudFileURL, localURL: localFileURL, localExist: localCopy, pageNumber: 0)
//
//                        if icloudFileURL.lastPathComponent.range(of:".icloud") != nil {
//                            available = false
//                        }
//
//                        let newFile = LocalFile(label: filename, thumbnail: thumbnail, favorite: "No", filename: filename, journal: nil, year: nil, category: type, rank: nil, note: "No notes", dateCreated: dates[0], dateModified: dates[1], author: nil, groups: [nil], parentFolder: "Uncategorized", grandpaFolder: "Uncategorized", available: available, filetype: nil, iCloudURL: icloudFileURL, localURL: localFileURL, path: path, downloading: false, downloaded: localCopy, uploaded: nil, size: fileHandler.getSize(url: icloudFileURL), saving: false)
//                        localFiles[number].append(newFile)
                    }
                }
            }
        } catch {
            print(error)// "Error while reading " + type + " folders")
        }
        
    }
    
    func readHiringFolder() {
        print("readHiringFolder")
        
        hiringFiles = []
        
        let mainPath = "Work documentsHiring"
        
        do {
            let folderURLs = try fileManagerDefault.contentsOfDirectory(at: hiringURL, includingPropertiesForKeys: nil)
            for folder in folderURLs { // FOLDERS IN HIRINGURL (ANNOUNCEMENTS)
                if folder.isDirectory()! { // IS FOLDER

                    let subfoldersURLs = try fileManagerDefault.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
                    for subfolder in subfoldersURLs { //FOLDERS IN SUBFOLDERS (NAMES)
                        if subfolder.isDirectory()! { // IS FOLDER, ADD AS APPLICANT

                            let name = subfolder.lastPathComponent
                            let path = mainPath + folder.lastPathComponent + subfolder.lastPathComponent
                            let announcement = folder.lastPathComponent
                            
                            let filesURLs = try fileManagerDefault.contentsOfDirectory(at: subfolder, includingPropertiesForKeys: nil)
                            for file in filesURLs { // FILES IN SUBSUBFOLDERS (FILES)
                                if !file.isDirectory()! { // IS NOT A FOLDER
                                    let available = false
                                    let icloudFileURL = file
//                                    let filePath = mainPath + folder.lastPathComponent + subfolder.lastPathComponent + file.lastPathComponent
                                    let thumbnail = fileHandler.getThumbnail(icloudURL: icloudFileURL, localURL: icloudFileURL, localExist: false, pageNumber: 0)
                                    
                                    let dates = fileHandler.getDates(url: icloudFileURL)
                                    
                                    let newFile = LocalFile(label: file.lastPathComponent, thumbnail: thumbnail, favorite: "No", filename: file.lastPathComponent, journal: nil, year: nil, category: "Hiring", rank: 5, note: "No notes", dateCreated: dates[0], dateModified: dates[1], author: nil, groups: [nil], parentFolder: subfolder.lastPathComponent, grandpaFolder: folder.lastPathComponent, available: available, filetype: nil, iCloudURL: icloudFileURL, localURL: icloudFileURL, path: path, downloading: false, downloaded: false, uploaded: nil, size: fileHandler.getSize(url: icloudFileURL), saving: false, views: 0)
                                    hiringFiles.append(newFile)
                                }
                            }
                            
                            if applicantCD.first(where: {$0.name == name}) == nil {
                                addNewApplicant(name: name, path: path, announcement: announcement)
                            }
                        }
                    }
                }
            }
        } catch {
            print("Error while reading hiring folders")
        }
    }
    
    func readPublications() {
        print("readPublications")
        
        let number = categories.index(where: { $0 == "Publications" })
        do {
            navigator.folderStructure.categories[number!] = "Publications"
            let fileURLs = try fileManagerDefault.contentsOfDirectory(at: publicationsURL!, includingPropertiesForKeys: nil)
            for file in fileURLs {
                var available = true
                let icloudFileURL = file
                let filename = fileHandler.getFilenameFromURL(icloudURL: icloudFileURL)
                let path = "Publications" + filename
                let localFileURL = localURL.appendingPathComponent("Publications").appendingPathComponent(filename)
                let localCopy = fileManagerDefault.fileExists(atPath: localFileURL.path)
                let dates = fileHandler.getDates(url: icloudFileURL)
                let thumbnail = fileHandler.getThumbnail(icloudURL: icloudFileURL, localURL: localFileURL, localExist: localCopy, pageNumber: 0)

                if icloudFileURL.lastPathComponent.range(of:".icloud") != nil {
                    available = false
                }
                
                var groups = [String]()
                if let publication = publicationsCD.first(where: {$0.filename == filename}) {
                    for group in publication.publicationGroup!.allObjects as! [PublicationGroup] {
                        groups.append(group.tag!)
                    }
                    var journalName = "No journal"
                    if let journal = publication.journal?.name {
                        journalName = journal
                    }
                    var authorName = "No author"
                    if let author = publication.author?.name {
                        authorName = author
                    }
                    
                    var newFile = LocalFile(label: file.lastPathComponent, thumbnail: thumbnail, favorite: publication.favorite!, filename: filename, journal: journalName, year: publication.year, category: "Publications", rank: publication.rank, note: publication.note, dateCreated: publication.dateCreated, dateModified: publication.dateModified, author: authorName, groups: groups, parentFolder: nil, grandpaFolder: nil, available: available, filetype: nil, iCloudURL: icloudFileURL, localURL: localFileURL, path: path, downloading: false, downloaded: localCopy, uploaded: nil, size: fileHandler.getSize(url: icloudFileURL), saving: false, views: 0)
                    
                    if let bookmark = getBookmark(file: newFile) {
                        newFile.views = bookmark.timesVisited
                    }
                    
                    localFiles[number!].append(newFile)

                } else {
                    // PUBLICATION NOT FOUND IN CORE DATA, SET DEFAULT VALUES FOR EVERYTHING
                    let newFile = LocalFile(label: file.lastPathComponent, thumbnail: thumbnail, favorite: "No", filename: filename, journal: "No journal", year: -2000, category: "Publications", rank: 50, note: "No notes", dateCreated: dates[0], dateModified: dates[1], author: "No author", groups: ["All publications"], parentFolder: nil, grandpaFolder: nil, available: available, filetype: nil, iCloudURL: icloudFileURL, localURL: localFileURL, path: path, downloading: false, downloaded: localCopy, uploaded: nil, size: fileHandler.getSize(url: icloudFileURL), saving: false, views: 0)
                    
                    localFiles[number!].append(newFile)

                }
                
            }
        } catch {
            print("Error while enumerating files \(publicationsURL.path): \(error.localizedDescription)")
        }
    }
    
    func reloadLocalFiles(category: Int) {
        print("reloadLocalFiles")
        
        localFiles[category] = []
        switch categories[category] {
        case "Publications":
            readPublications()
            compareLocalFilesWithCoreData()
            
        case "Books":
            readBooks()
            compareLocalFilesWithCoreData()

        case "Fast folder":
            readFastFolder()
            
        case "Recently":
            print("Recently")
            
        default:
            let (number, url) = getCategoryNumberAndURL(name: categories[category])
            readFilesInFolder(url: url!, type: categories[category], number: number)
            
        }
    }
    
    func reloadDownloadedFile(file: DownloadingFile) {
        print("reloadLocalFile()")

        if let tmp = localFiles[file.category].index(where: {$0.filename == file.filename}) {
            
            let localFileURL = localFiles[file.category][tmp].localURL.deletingLastPathComponent().appendingPathComponent(file.filename)
            
            let thumbnail = fileHandler.getThumbnail(icloudURL: file.url, localURL: localFileURL, localExist: false, pageNumber: 0)
            localFiles[file.category][tmp].filename = file.filename
            localFiles[file.category][tmp].label = file.filename
            localFiles[file.category][tmp].thumbnail = thumbnail
            localFiles[file.category][tmp].available = true
            localFiles[file.category][tmp].size = fileHandler.getSize(url: file.url)
            localFiles[file.category][tmp].localURL = localFileURL
            localFiles[file.category][tmp].iCloudURL = file.url
            
        }
    }
    
    func removeFromBulletin(file: LocalFile, bulletin: String) {
        print("removeFromBulletin")
        
        if let bulletinBoard = bulletinCD.first(where: { $0.bulletinName == bulletin }) {
            if let number = bulletinBoard.path!.index(where: { $0 == file.path }) {
                bulletinBoard.path?.remove(at: number)
                bulletinBoard.category?.remove(at: number)
                bulletinBoard.filename?.remove(at: number)
                bulletinBoard.dateModified = Date()
                saveCoreData()
                loadCoreData()
            }
        }
    }
    
    func removeFromGroup(file: LocalFile, group: String) {
        print("removeFromGroup")
        
        switch file.category {
        case "Publications":
            let number = categories.index(where: { $0 == "Publications" })
            
            if let index = localFiles[number!].index(where: { $0.filename == file.filename } ) {
                let newGroups = localFiles[number!][index].groups.filter { $0 !=  group}
                localFiles[number!][index].groups = newGroups
                updateIcloud(file: localFiles[number!][index], oldFilename: nil, newFilename: nil, expense: nil, project: nil, type: "Publications", bookmark: nil, fund: nil)
            }
            
            if let currentPublication = publicationsCD.first(where: {$0.filename == file.filename}) {
                if let tag = publicationGroupsCD.first(where: {$0.tag == group}) {
                    currentPublication.removeFromPublicationGroup(tag)
                    saveCoreData()
                    loadCoreData()
                }
            }
        case "Books":
            let number = categories.index(where: { $0 == "Books" })
            
            if let index = localFiles[number!].index(where: { $0.filename == file.filename } ) {
                let newGroups = localFiles[number!][index].groups.filter { $0 !=  group}
                localFiles[number!][index].groups = newGroups
                updateIcloud(file: localFiles[number!][index], oldFilename: nil, newFilename: nil, expense: nil, project: nil, type: "Books", bookmark: nil, fund: nil)
            }
            
            if let currentBook = booksCD.first(where: {$0.filename == file.filename}) {
                if let tag = booksGroupsCD.first(where: {$0.tag == group}) {
                    currentBook.removeFromBooksGroup(tag)
                    saveCoreData()
                    loadCoreData()
                }
            }
        default:
            print("Default 140")
        }
        
    }
    
    func replaceLocalFileWithNew(newFile: LocalFile) {
        print("replaceLocalFileWithNew")

        let(number, _) = self.getCategoryNumberAndURL(name: newFile.category)
        //FIX: byt ut "navigator.selected.categoryNumber" nedanför
        if let index = localFiles[number].index(where: { $0.filename == newFile.filename } ) {
            localFiles[number][index] = newFile
        }
    }
    
    func saveCoreData() {
        do {
            try context.save()
            print("Saved to core data")
        } catch {
            print("Could not save core data")
        }
    }

    func saveBookmark(file: LocalFile, bookmark: Bookmarks) {
        print("saveBookmarks")
        
        if let currentBookmark = getBookmark(file: file) {
            currentBookmark.lastPageVisited = bookmark.lastPageVisited
            currentBookmark.page = bookmark.page
            saveCoreData()
            loadCoreData()
            updateIcloud(file: nil, oldFilename: nil, newFilename: nil, expense: nil, project: nil, type: "Bookmarks", bookmark: bookmark, fund: nil)
        } else {
            saveToIcloud(url: nil, type: "Bookmarks", object: bookmark)
        }
    }
    
    func saveMemo(id: Int64, text: String, title: String, color: String) {
        if let currentMemo = memosCD.first(where: {$0.id == id}) {
            currentMemo.color = color
            currentMemo.text = text
            currentMemo.title = title
            saveCoreData()
            loadCoreData()
        }
    }
    
    func savePDF(file: LocalFile, document: PDFDocument) {
        print("savePDF: " + file.filename)

        if let number = categories.index(where: { $0 == file.category }) {
            let index = localFiles[number].index(where: {$0.filename == file.filename})
            localFiles[number][index!].saving = true
            
            NotificationCenter.default.post(name: Notification.Name.updateView, object: nil)
            self.progressMonitor.text = "Autosaving " + file.filename
            NotificationCenter.default.post(name: Notification.Name.postNotification, object: self)
            
            let dispatchQueue = DispatchQueue(label: "QueueIdentification", qos: .background)
            dispatchQueue.async{
                
                if !document.write(to: file.iCloudURL) {
                    print("Failed to save PDF to iCloud drive")
                } else {
                    print("Save PDF to iCloud drive")
                    self.progressMonitor.text = "Saved " + file.filename + " to iCloud drive"
                    NotificationCenter.default.post(name: Notification.Name.postNotification, object: self)
                    if !self.localFiles[number][index!].downloaded {
                        NotificationCenter.default.post(name: Notification.Name.saveFinished, object: self)
                    }
                }
                if self.localFiles[number][index!].downloaded {
                    if !document.write(to: file.localURL) {
                        print("Failed to save PDF to local folder")
                    } else {
                        print("Save PDF locally")
                        self.progressMonitor.text = "Saved " + file.filename + " locally"
                        NotificationCenter.default.post(name: Notification.Name.postNotification, object: self)
                        NotificationCenter.default.post(name: Notification.Name.saveFinished, object: self)
                    }
                }
                self.localFiles[number][index!].saving = false
                NotificationCenter.default.post(name: Notification.Name.updateView, object: self)
            }
        } else { // "HIRING", which has the "wrong" category number
            
            NotificationCenter.default.post(name: Notification.Name.updateView, object: nil)
            self.progressMonitor.text = "Autosaving " + file.filename
            NotificationCenter.default.post(name: Notification.Name.postNotification, object: self)
            
            let dispatchQueue = DispatchQueue(label: "QueueIdentification", qos: .background)
            dispatchQueue.async{
                if !document.write(to: file.iCloudURL) {
                    print("Failed to save PDF to iCloud drive")
                } else {
                    self.progressMonitor.text = "Saved " + file.filename + " to iCloud drive"
                    NotificationCenter.default.post(name: Notification.Name.postNotification, object: self)
                }
                NotificationCenter.default.post(name: Notification.Name.updateView, object: self)
            }
        }
    }
    
    func saveRecord(record: CKRecord, progress: Bool, label: String, type: String) {
        print("saveRecord")
        
        if type == "Found" {
            self.privateDatabase?.save(record, completionHandler:( { savedRecord, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("accountStatus error: \(error)")
                    }
                    self.progressMonitor.text = label + " updated to icloud"
                    NotificationCenter.default.post(name: Notification.Name.postNotification, object: self)
                    
                }
            }))
        } else {
            self.modifyRecordsOperation(label: label, myRecord: record, progress: progress)
        }
    }
    
    func saveToIcloud(url: URL?, type: String, object: Any?) {
        print("saveToIcloud")
        
        if let zoneID = recordZone?.zoneID {
            DispatchQueue.main.async {
                
                if type == "Publications" {
                    
                    if object != nil {
                        let publication = object as! Publication
                    }
                    
                    let myRecord = CKRecord(recordType: "Publications", zoneID: zoneID)
                    myRecord.setObject(url?.lastPathComponent as CKRecordValue?, forKey: "Filename")
                    myRecord.setObject("No author" as CKRecordValue?, forKey: "Author")
                    myRecord.setObject(["All publications"] as CKRecordValue?, forKey: "Group")
                    myRecord.setObject(50 as CKRecordValue?, forKey: "Rank")
                    myRecord.setObject(-2000 as CKRecordValue?, forKey: "Year")
                    myRecord.setObject("No notes" as CKRecordValue?, forKey: "Note")
                    myRecord.setObject("No" as CKRecordValue?, forKey: "Favorite")
                    myRecord.setObject(Date() as CKRecordValue?, forKey: "dateModified")
                    
                    self.modifyRecordsOperation(label: "Publication", myRecord: myRecord, progress: false)
            
                } else if type == "Expense" {
                    
                    let myRecord = CKRecord(recordType: "Expenses", zoneID: zoneID)
                    let expense = object as! Expense
                    myRecord.setObject(expense.amount as CKRecordValue?, forKey: "Amount")
                    myRecord.setObject(expense.dateAdded as CKRecordValue?, forKey: "createdAt")
                    myRecord.setObject(expense.overhead as CKRecordValue?, forKey: "Overhead")
                    myRecord.setObject(expense.comment as CKRecordValue?, forKey: "Comment")
                    myRecord.setObject(expense.reference as CKRecordValue?, forKey: "Reference")
                    myRecord.setObject(expense.idNumber as CKRecordValue?, forKey: "idNumber")
                    myRecord.setObject(expense.years as CKRecordValue?, forKey: "years")
                    myRecord.setObject(expense.type as CKRecordValue?, forKey: "type")
                    
                    if let tmp = expense.project {
                        myRecord.setObject(tmp.name as CKRecordValue?, forKey: "BelongToProject")
                    }
                    
                    if expense.active {
                        myRecord.setObject("Yes" as CKRecordValue?, forKey: "Active")
                    } else {
                        myRecord.setObject("No" as CKRecordValue?, forKey: "Active")
                    }
                    
                    self.modifyRecordsOperation(label: "Expenses", myRecord: myRecord, progress: false)
                    
                } else if type == "Projects" {
                    
                    let myRecord = CKRecord(recordType: "Projects", zoneID: zoneID)
                    let project = object as! Project
                    myRecord.setObject(project.amountReceived as CKRecordValue?, forKey: "AmountReceived")
                    myRecord.setObject(project.amountRemaining as CKRecordValue?, forKey: "AmountRemaining")
                    myRecord.setObject(project.name as CKRecordValue?, forKey: "Name")
                    myRecord.setObject(project.dateCreated as CKRecordValue?, forKey: "createdAt")
                    
                    self.modifyRecordsOperation(label: "Projects", myRecord: myRecord, progress: false)
                    
                } else if type == "Bookmarks" {
                    
                    let myRecord = CKRecord(recordType: "Bookmarks", zoneID: zoneID)
                    let bookmark = object as! Bookmarks
                    
                    myRecord.setObject(bookmark.category as CKRecordValue?, forKey: "category")
                    myRecord.setObject(bookmark.filename as CKRecordValue?, forKey: "filename")
                    myRecord.setObject(bookmark.lastPageVisited as CKRecordValue?, forKey: "lastPageVisited")
                    myRecord.setObject(bookmark.page as CKRecordValue?, forKey: "page")
                    myRecord.setObject(bookmark.path as CKRecordValue?, forKey: "path")
                    
                    self.modifyRecordsOperation(label: "Bookmarks", myRecord: myRecord, progress: false)
                    
                } else if type == "Fund" {
                    
                    let myRecord = CKRecord(recordType: "FundingOrganisation", zoneID: zoneID)
                    let organisation = object as! FundingOrganisation
                    
                    myRecord.setObject(organisation.name as CKRecordValue?, forKey: "Name")
                    myRecord.setObject(organisation.amount as CKRecordValue?, forKey: "Amount")
                    myRecord.setObject(organisation.currency as CKRecordValue?, forKey: "Currency")
                    myRecord.setObject(organisation.deadline as CKRecordValue?, forKey: "Deadline")
                    myRecord.setObject("Proposal instructions" as CKRecordValue?, forKey: "Instructions")
                    myRecord.setObject("Website?" as CKRecordValue?, forKey: "Website")
                    
                    self.modifyRecordsOperation(label: "FundingOrganisation", myRecord: myRecord, progress: false)
                    
                }
            }
        }
    }
    
    func scanForNewFilesInFolder(categoryURL: URL, categoryNumber: Int) {
        
        let filesBefore = localFiles[categoryNumber].count
        
        var filesAfter = 0
        do {
            let fileURLs = try fileManagerDefault.contentsOfDirectory(at: categoryURL, includingPropertiesForKeys: nil)
            for file in fileURLs {
                if file.isDirectory() == false {
                    filesAfter = filesAfter + 1
                } else {
                    let subfoldersURLs = try fileManagerDefault.contentsOfDirectory(at: file, includingPropertiesForKeys: nil)
                    for subfiles in subfoldersURLs {
                        if subfiles.isDirectory() == false {
                            filesAfter = filesAfter + 1
                        } else {
                            let subsubfoldersURLs = try fileManagerDefault.contentsOfDirectory(at: subfiles, includingPropertiesForKeys: nil)
                            for subsubfiles in subsubfoldersURLs {
                                if subsubfiles.isDirectory() == false {
                                    filesAfter = filesAfter + 1
                                }
                            }
                        }
                    }
                }
                
            }
        } catch {
            print("Error searching for files")
        }
        
        if filesAfter != filesBefore {
            reloadLocalFiles(category: categoryNumber)
        } else {
            print(categories[categoryNumber] + " unchanged")
        }
    }
    
    func searchFolders(categoryURL: URL, categoryNumber: Int) -> Int {
        let filesBefore = localFiles[categoryNumber].count
        var reload = 0
        
        var filesAfter = 0
        do {
            let fileURLs = try fileManagerDefault.contentsOfDirectory(at: categoryURL, includingPropertiesForKeys: nil)
            for file in fileURLs {
                if file.isDirectory() == false {
                    filesAfter = filesAfter + 1
                } else {
                    let subfoldersURLs = try fileManagerDefault.contentsOfDirectory(at: file, includingPropertiesForKeys: nil)
                    for subfiles in subfoldersURLs {
                        if subfiles.isDirectory() == false {
                            filesAfter = filesAfter + 1
                        } else {
                            let subsubfoldersURLs = try fileManagerDefault.contentsOfDirectory(at: subfiles, includingPropertiesForKeys: nil)
                            for subsubfiles in subsubfoldersURLs {
                                if subsubfiles.isDirectory() == false {
                                    filesAfter = filesAfter + 1
                                }
                            }
                        }
                    }
                }
                
            }
        } catch {
            print("Error")
        }
        
        if filesAfter != filesBefore {
            print(categories[categoryNumber] + " changed")
            reloadLocalFiles(category: categoryNumber)
            reload = 1
        } else {
            print(categories[categoryNumber] + " unchanged")
        }
        return reload
    }
    
    func searchFiles() {
        print("searchFiles")
        
        if navigator.selected.category == "Publications" {
            if searchString.count > 0 {
                searchResult = localFiles[navigator.selected.categoryNumber].filter{ $0.filename.contains(searchString) || $0.author!.contains(searchString) || $0.journal!.contains(searchString) || $0.note!.contains(searchString) }
            } else {
                isSearching = false
            }
        } else if navigator.selected.category == "Books" {
            if searchString.count > 0 {
                searchResult = localFiles[navigator.selected.categoryNumber].filter{ $0.filename.contains(searchString) }
            } else {
                isSearching = false
            }
        } else if navigator.selected.category == "Teaching" {
            if searchString.count > 0 {
                searchResult = localFiles[navigator.selected.categoryNumber].filter{ $0.filename.contains(searchString) }
            } else {
                isSearching = false
            }
        } else if navigator.selected.category == "Manuscripts" {
            if searchString.count > 0 {
                searchResult = localFiles[navigator.selected.categoryNumber].filter{ $0.filename.contains(searchString) }
            } else {
                isSearching = false
            }
        } else if navigator.selected.category == "Miscellaneous" {
            if searchString.count > 0 {
                searchResult = localFiles[navigator.selected.categoryNumber].filter{ $0.filename.contains(searchString) }
            } else {
                isSearching = false
            }
        } else if navigator.selected.category == "Search" {
            if searchString.count > 0 {
                fullSearch = []
                for i in 0..<categories.count {
                    if categories[i] == "Publications" {
                        let files = SearchResult(files: localFiles[i].filter{ $0.filename.contains(searchString) || $0.author!.contains(searchString) || $0.journal!.contains(searchString) || $0.note!.contains(searchString) }, title: categories[i])
                        if !files.files.isEmpty {
                            if fullSearch.isEmpty {
                                fullSearch = [files]
                            } else {
                                fullSearch.append(files)
                            }
                        }
                    } else {
                        let files = SearchResult(files: localFiles[i].filter{ $0.filename.contains(searchString) }, title: categories[i])
                        if !files.files.isEmpty {
                            if fullSearch.isEmpty {
                                fullSearch = [files]
                            } else {
                                fullSearch.append(files)
                            }
                        }
                    }
                }
            } else {
                isSearching = false
            }
        }
    }
    
    func setApplicant(applicant: Applicant, record: CKRecord, type: String, count: Int) {
        
        var updateProgress = true
        var label = "\(count)" + "/" + "\(self.applicantCD.count)" + ": " + applicant.name!
        if count == 0 {
            label = applicant.name!
            updateProgress = false
        }
        
        var qualifies = 0
        if applicant.qualifies {
            qualifies = 1
        }
        
        record.setObject(applicant.name as CKRecordValue?, forKey: "name")
        record.setObject(applicant.age as CKRecordValue?, forKey: "age")
        record.setObject(applicant.announcement as CKRecordValue?, forKey: "announcement")
        record.setObject(applicant.degree as CKRecordValue?, forKey: "degree")
        record.setObject(applicant.education as CKRecordValue?, forKey: "education")
        record.setObject(applicant.grade as CKRecordValue?, forKey: "grade")
        record.setObject(applicant.notes as CKRecordValue?, forKey: "notes")
        record.setObject(applicant.path as CKRecordValue?, forKey: "path")
        record.setObject(qualifies as CKRecordValue?, forKey: "qualifies")
        
        saveRecord(record: record, progress: updateProgress, label: label, type: type)
    }
    
    func setBook(book: Book, record: CKRecord, type: String, count: Int) {
        
        var updateProgress = true
        var label = "\(count)" + "/" + "\(self.booksCD.count)" + ": " + book.filename!
        if count == 0 {
            label = book.filename!
            updateProgress = false
        }
        
        var groups: [String] = []
        for group in book.booksGroup!.allObjects as! [BooksGroup] {
            groups.append(group.tag!)
        }
        
        var favorite = "No"
        if self.favoritesCD.first(where: {$0.filename == book.filename}) != nil {
            favorite = "Yes"
        }
        
        record.setObject(book.filename as CKRecordValue?, forKey: "filename")
        record.setObject(favorite as CKRecordValue?, forKey: "favorite")
        record.setObject(groups as CKRecordValue?, forKey: "groups")
        
        saveRecord(record: record, progress: updateProgress, label: label, type: type)
    }
    
    func setBookmark(bookmark: Bookmarks, record: CKRecord, type: String, count: Int) {
        
        var updateProgress = true
        var label = "\(count)" + "/" + "\(self.bookmarksCD.count)" + ": " + bookmark.filename!
        if count == 0 {
            label = bookmark.filename!
            updateProgress = false
        }
        
        record.setObject(bookmark.category as CKRecordValue?, forKey: "category")
        record.setObject(bookmark.filename as CKRecordValue?, forKey: "filename")
        record.setObject(bookmark.lastPageVisited as CKRecordValue?, forKey: "lastPageVisited")
        record.setObject(bookmark.page as CKRecordValue?, forKey: "page")
        record.setObject(bookmark.path as CKRecordValue?, forKey: "path")
        record.setObject(bookmark.label as CKRecordValue?, forKey: "label")
        
        saveRecord(record: record, progress: updateProgress, label: label, type: type)
        
    }
    
    func setExpenses(expense: Expense, record: CKRecord, type: String, count: Int) {
        
        var updateProgress = true
        var label = "\(count)" + "/" + "\(self.expensesCD.count)" + ": " + "\(expense.idNumber)"
        if count == 0 {
            label = "\(expense.idNumber)"
            updateProgress = false
        }
        
        record.setObject(expense.amount as CKRecordValue?, forKey: "Amount")
        record.setObject(expense.overhead as CKRecordValue?, forKey: "Overhead")
        record.setObject(expense.comment as CKRecordValue?, forKey: "Comment")
        record.setObject(expense.reference as CKRecordValue?, forKey: "Reference")
        record.setObject(expense.years as CKRecordValue?, forKey: "years")
        record.setObject(expense.type as CKRecordValue?, forKey: "type")
        record.setObject(expense.idNumber as CKRecordValue?, forKey: "idNumber")
        
        if let tmp = expense.project {
            record.setObject(tmp.name as CKRecordValue?, forKey: "BelongToProject")
        }
        if expense.active {
            record.setObject("Yes" as CKRecordValue?, forKey: "Active")
        } else {
            record.setObject("No" as CKRecordValue?, forKey: "Active")
        }

        saveRecord(record: record, progress: updateProgress, label: label, type: type)
    }
    
    func setFavorites(favorite: Favorites, record: CKRecord, type: String, count: Int) {
        
        var updateProgress = true
        var label = "\(count)" + "/" + "\(self.favoritesCD.count)" + ": " + favorite.filename!
        if count == 0 {
            label = favorite.filename!
            updateProgress = false
        }
        
        record.setObject(favorite.category as CKRecordValue?, forKey: "category")
        record.setObject(favorite.filename as CKRecordValue?, forKey: "filename")
        record.setObject(favorite.path as CKRecordValue?, forKey: "path")
        
        saveRecord(record: record, progress: updateProgress, label: label, type: type)
    }
    
    func setFundingOrganisation(fundingOrganisation: FundingOrganisation, record: CKRecord, type: String, count: Int) {
        
        var updateProgress = true
        var label = "\(count)" + "/" + "\(self.fundCD.count)" + ": " + fundingOrganisation.name!
        if count == 0 {
            label = fundingOrganisation.name!
            updateProgress = false
        }
        
        if fundingOrganisation.name == nil {
            fundingOrganisation.name = "No name"
        }
        
        record.setObject(fundingOrganisation.name as CKRecordValue?, forKey: "Name")
        record.setObject(fundingOrganisation.amount as CKRecordValue?, forKey: "Amount")
        record.setObject(fundingOrganisation.currency as CKRecordValue?, forKey: "Currency")
        record.setObject(fundingOrganisation.deadline as CKRecordValue?, forKey: "Deadline")
        record.setObject(fundingOrganisation.instructions as CKRecordValue?, forKey: "Instructions")
        record.setObject(fundingOrganisation.website as CKRecordValue?, forKey: "Website")
        
        saveRecord(record: record, progress: updateProgress, label: label, type: type)
    }
    
    func setFastFolder(mainFolder: String, subFolder: String?) {
        print("setFastFolder")
        
        let requestFastFolder = NSFetchRequest<NSFetchRequestResult>(entityName: "FastFolder")
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: requestFastFolder)
        do {
            try context.execute(batchDeleteRequest)
            print("Deleted fast folders")
        } catch {
            print("Error deleting fast folder")
        }
        
        let newFolder = FastFolder(context: context)
        newFolder.category = navigator.selected.category
        newFolder.mainFolder = mainFolder
        newFolder.subFolder = subFolder
        newFolder.folderLevel = Int16(navigator.selected.folderLevel)
        
        saveCoreData()
        loadCoreData()
    }
        
    func setMemo(memo: Memo, record: CKRecord, type: String, count: Int) {
        
        var updateProgress = true
        var label = "\(count)" + "/" + "\(self.memosCD.count)" + ": " + memo.title!
        if count == 0 {
            label = memo.title!
            updateProgress = false
        }
        
        record.setObject(memo.color as CKRecordValue?, forKey: "color")
        record.setObject(memo.id as CKRecordValue?, forKey: "id")
        record.setObject(memo.tag as CKRecordValue?, forKey: "tag")
        record.setObject(memo.text as CKRecordValue?, forKey: "text")
        record.setObject(memo.title as CKRecordValue?, forKey: "title")
        record.setObject(memo.dateModified as CKRecordValue?, forKey: "modifiedAt")
        
        saveRecord(record: record, progress: updateProgress, label: label, type: type)
    }
    
    func setProject(project: Project, record: CKRecord, type: String, count: Int) {
        
        var updateProgress = true
        var label = "\(count)" + "/" + "\(self.projectCD.count)" + ": " + project.name!
        if count == 0 {
            label = project.name!
            updateProgress = false
        }
        
        record.setObject(project.amountReceived as CKRecordValue?, forKey: "AmountReceived")
        record.setObject(project.amountRemaining as CKRecordValue?, forKey: "AmountRemaining")
        record.setObject(project.name as CKRecordValue?, forKey: "Name")
        record.setObject(project.dateCreated as CKRecordValue?, forKey: "createdAt")
        record.setObject(project.currency as CKRecordValue?, forKey: "currency")
        record.setObject(project.deadline as CKRecordValue?, forKey: "deadline")
        
        saveRecord(record: record, progress: updateProgress, label: label, type: type)
    }
    
    func setPublication(publication: Publication, record: CKRecord, type: String, count: Int) {
        print("setPublication")
        
        var updateProgress = true
        var label = "\(count)" + "/" + "\(self.publicationsCD.count)" + ": " + publication.filename!
        if count == 0 {
            label = publication.filename!
            updateProgress = false
        }
        
        var groups: [String] = []
        for group in (publication.publicationGroup?.allObjects)! as! [PublicationGroup] {
            groups.append(group.tag!)
        }
        
        var favorite = "No"
        if self.favoritesCD.first(where: {$0.filename == publication.filename}) != nil {
            favorite = "Yes"
        }
        
        record.setObject(publication.filename as CKRecordValue?, forKey: "Filename")
        record.setObject(publication.year as CKRecordValue?, forKey: "Year")
        record.setObject(favorite as CKRecordValue?, forKey: "Favorite")
        record.setObject(publication.note as CKRecordValue?, forKey: "Note")
        record.setObject(Int(publication.rank) as CKRecordValue?, forKey: "Rank")
        record.setObject(publication.author?.name as CKRecordValue?, forKey: "Author")
        record.setObject(publication.journal?.name as CKRecordValue?, forKey: "Journal")
        record.setObject(groups as CKRecordValue?, forKey: "Group")
        record.setObject(publication.dateModified as CKRecordValue?, forKey: "dateModified")

        saveRecord(record: record, progress: updateProgress, label: label, type: type)
    }
    
    func setupDefaultCoreDataTypes() {
        print("setupDefaultCoreDataTypes")
        
        // ADD "NO AUTHOR"
        let arrayAuthors = authorsCD
        if arrayAuthors.first(where: {$0.name == "No author"}) == nil {
            let newAuthor = Author(context: context)
            newAuthor.name = "No author"
            newAuthor.sortNumber = "0"
        }
        
        // ADD "NO JOURNAL"
        let arrayJournals = journalsCD
        if arrayJournals.first(where: {$0.name == "No journal"}) == nil {
            let newJournal = Journal(context: context)
            newJournal.name = "No journal"
            newJournal.sortNumber = "0"
        }
        
        // ADD "ALL PUBLICATIONS"
        let arrayPublicationGroups = publicationGroupsCD
        if arrayPublicationGroups.first(where: {$0.tag == "All publications"}) == nil {
            let newPublicationGroup = PublicationGroup(context: context)
            newPublicationGroup.tag = "All publications"
            newPublicationGroup.dateModified = Date()
            newPublicationGroup.sortNumber = "0"
        }
        
        // ADD "FAVORITES" FOR PUBLICATIONS
        if publicationGroupsCD.first(where: {$0.tag == "Favorites"}) == nil {
            let favoriteGroup = PublicationGroup(context: context)
            favoriteGroup.tag = "Favorites"
            favoriteGroup.dateModified = Date()
            favoriteGroup.sortNumber = "1"
        }
        
        // ADD "RECENTLY ADDED"
        if publicationGroupsCD.first(where: {$0.tag == "Recently added/modified"}) == nil {
            let newPublicationGroup = PublicationGroup(context: context)
            newPublicationGroup.tag = "Recently added/modified"
            newPublicationGroup.dateModified = Date()
            newPublicationGroup.sortNumber = "2"
        }
        
        // ADD "ALL BOOKS"
        if booksGroupsCD.first(where: {$0.tag == "All books"}) == nil {
            let newBooksGroup = BooksGroup(context: context)
            newBooksGroup.tag = "All books"
            newBooksGroup.dateModified = Date()
            newBooksGroup.sortNumber = "0"
        }
        
        // ADD "FAVORITES" FOR BOOKS
        if booksGroupsCD.first(where: {$0.tag == "Favorites"}) == nil {
            let favoriteBooksGroup = BooksGroup(context: context)
            favoriteBooksGroup.tag = "Favorites"
            favoriteBooksGroup.dateModified = Date()
            favoriteBooksGroup.sortNumber = "1"
        }
        
        // ADD "RECENTLY" FOR BOOKS
        if booksGroupsCD.first(where: {$0.tag == "Recently added/modified"}) == nil {
            let favoriteBooksGroup = BooksGroup(context: context)
            favoriteBooksGroup.tag = "Recently added/modified"
            favoriteBooksGroup.dateModified = Date()
            favoriteBooksGroup.sortNumber = "2"
        }

        // SETUP CATEGORIES
        for category in categories {
            if categoriesCD.first(where: {$0.name == category}) == nil {
                let newCategory = Categories(context: context)
                let number = categories.index(where: { $0 == category })
                newCategory.name = category
                newCategory.originalOrder = Int16(number!)
                if newCategory.name == "Recently" {
                    newCategory.numberViews = Int64.max
                } else {
                    newCategory.numberViews = 0
                }
                newCategory.displayOrder = Int16(number!)
                saveCoreData()
            }
        }
        
        saveCoreData()
        loadCoreData()
        
    }
    
    func syncWithIcloud() {
        print("syncWithIcloud")
        
        
        // 0 DELETE OLD RECORDS
        for item in self.publicationsCD {
            self.context.delete(item)
        }
        for item in self.authorsCD {
            self.context.delete(item)
        }
        for item in self.publicationGroupsCD {
            self.context.delete(item)
        }
        for item in self.journalsCD {
            self.context.delete(item)
        }
        for item in self.projectCD {
            self.context.delete(item)
        }
        for item in self.fundCD {
            self.context.delete(item)
        }
        for item in self.bookmarksCD {
            self.context.delete(item)
        }
        for item in self.expensesCD {
            self.context.delete(item)
        }
        for item in self.memosCD {
            self.context.delete(item)
        }
        for item in self.booksCD {
            self.context.delete(item)
        }
        for item in self.favoritesCD {
            self.context.delete(item)
        }

        self.saveCoreData()
        self.loadCoreData()
        
        sleep(2)

        self.setupDefaultCoreDataTypes()

        let delay: UInt32 = 2
        self.cloudKitLoadRecords(type: "Publications") { (records, error) -> Void in
            if let error = error {
                print(error)
            } else {
                if let records = records {
                    
                    print("Publications: " + "\(records.count)")
                    var count = 0
                    for record in records {
                        
                        let newPublication = Publication(context: self.context)
                        newPublication.favorite = record.object(forKey: "Favorite") as? String
                        newPublication.filename = record.object(forKey: "Filename") as? String
                        newPublication.note = record.object(forKey: "Note") as? String
                        newPublication.rank = Float((record.object(forKey: "Rank") as? Int64)!)
                        newPublication.year = (record.object(forKey: "Year") as? Int16)!
                        newPublication.dateCreated = record.creationDate
                        newPublication.dateModified = record.modificationDate

                        let name = record.object(forKey: "Author") as? String
                        if let author = self.authorsCD.first(where: {$0.name == name }) {
                            newPublication.author = author
                        } else if name == nil {
                            newPublication.author = self.authorsCD.first(where: {$0.name == "No author"})
                        } else {
                            let newAuthor = Author(context: self.context)
                            newAuthor.name = name
                            newAuthor.sortNumber = "3"
                            self.authorsCD.append(newAuthor)
                            newPublication.author = newAuthor
                        }

                        if let journalName = record.object(forKey: "Journal") as? String {
                            if let journal = self.journalsCD.first(where: {$0.name == journalName }) {
                                newPublication.journal = journal
                            } else {
                                let newJournal = Journal(context: self.context)
                                newJournal.name = journalName
                                newJournal.sortNumber = "1"
                                self.journalsCD.append(newJournal)
                                newPublication.journal = newJournal
                            }
                        } else {
                            newPublication.journal = self.journalsCD.first(where: {$0.name == "No journal"})
                        }

                        if let tags = record.object(forKey: "Group") as? [String] {
                            for tag in tags {
                                if let group = self.publicationGroupsCD.first(where: {$0.tag == tag }) {
                                    newPublication.addToPublicationGroup(group)
                                } else {
                                    let newGroup = PublicationGroup(context: self.context)
                                    newGroup.tag = tag
                                    newGroup.sortNumber = "3"
                                    self.publicationGroupsCD.append(newGroup)
                                    newPublication.addToPublicationGroup(newGroup)
                                }
                            }
                        }

                        print(newPublication)

                        self.publicationsCD.append(newPublication)

                        count = count + 1
                        if count == records.count {
                            self.saveCoreData()
                            self.loadCoreData()
                            NotificationCenter.default.post(name: Notification.Name.syncCompleted, object: nil)
                            sleep(delay)
                        }
                    }
                    
                } else {
                    print("No records")
                }
            }
        }
        sleep(delay)


        // 2 PROJECTS
        self.cloudKitLoadRecords(type: "Projects") { (records, error) -> Void in
            if let error = error {
                print(error)
            } else {
                if let records = records {

                    print("Projects " + "\(records.count)")
                    var count = 0
                    for record in records {

                        if let project = self.projectCD.first(where: {$0.name == record.object(forKey: "Name") as? String }) {
                            project.amountReceived = record.object(forKey: "AmountReceived") as! Int32
                            project.amountRemaining = record.object(forKey: "AmountRemaining") as! Int32
                            project.currency = record.object(forKey: "currency") as? String
                            project.deadline = record.object(forKey: "deadline") as? Date
                            project.dateCreated = record.creationDate
                            project.dateModified = record.modificationDate

                            self.projectCD.append(project)

                        } else {
                            let newProject = Project(context: self.context)
                            newProject.name = record.object(forKey: "Name") as? String
                            newProject.amountReceived = record.object(forKey: "AmountReceived") as! Int32
                            newProject.amountRemaining = record.object(forKey: "AmountRemaining") as! Int32
                            newProject.currency = record.object(forKey: "currency") as? String
                            newProject.deadline = record.object(forKey: "deadline") as? Date
                            newProject.dateCreated = record.creationDate
                            newProject.dateModified = record.modificationDate

                            self.projectCD.append(newProject)

                            print(newProject)
                        }

                        count = count + 1
                        if count == records.count {
                            self.saveCoreData()
                            self.loadCoreData()
                            NotificationCenter.default.post(name: Notification.Name.syncCompleted, object: nil)
                            sleep(delay)
                        }
                    }

                } else {
                    print("No records")
                }
            }
        }
        sleep(delay)

        // 3 EXPENSES
        self.cloudKitLoadRecords(type: "Expenses") { (records, error) -> Void in
            if let error = error {
                print(error)
            } else {
                if let records = records {

                    print("Expenses " + "\(records.count)")
                    var count = 0
                    for record in records {

                        let newExpense = Expense(context: self.context)
                        newExpense.idNumber = record.object(forKey: "idNumber") as! Int64
                        newExpense.amount = record.object(forKey: "Amount") as! Int32
                        newExpense.comment = record.object(forKey: "Comment") as? String
                        newExpense.reference = record.object(forKey: "Reference") as? String
                        newExpense.type = record.object(forKey: "type") as? String
                        newExpense.overhead = record.object(forKey: "Overhead") as! Int16
                        newExpense.years = record.object(forKey: "years") as! Int16
                        newExpense.dateAdded = record.creationDate

                        let projectName = record.object(forKey: "BelongToProject") as? String
                        if let project = self.projectCD.first(where: {$0.name == projectName }) {
                            newExpense.project = project
                        } else {
                            let newProject = Project(context: self.context)
                            newProject.name = projectName
                        }

                        if record.object(forKey: "Active") as? String == "Yes" {
                            newExpense.active = true
                        } else {
                            newExpense.active = false
                        }

                        print(newExpense)

                        self.expensesCD.append(newExpense)

                        count = count + 1
                        if count == records.count {
                            self.saveCoreData()
                            self.loadCoreData()
                            NotificationCenter.default.post(name: Notification.Name.syncCompleted, object: nil)
                            sleep(delay)
                        }
                    }

                } else {
                    print("No records")
                }
            }
        }
        sleep(delay)


        // 4 FUNDING ORGANISATION
        self.cloudKitLoadRecords(type: "FundingOrganisation") { (records, error) -> Void in
            if let error = error {
                print(error)
            } else {
                if let records = records {

                    print("FundingOrganisation " + "\(records.count)")
                    var count = 0
                    for record in records {

                        let newFund = FundingOrganisation(context: self.context)
                        newFund.amount = record.object(forKey: "Amount") as! Int64
                        newFund.currency = record.object(forKey: "currency") as? String
                        newFund.deadline = record.object(forKey: "deadline") as? Date
                        newFund.instructions = record.object(forKey: "Instructions") as? String
                        newFund.name = record.object(forKey: "Name") as? String
                        newFund.website = record.object(forKey: "Website") as? String

                        print(newFund)

                        self.fundCD.append(newFund)

                        count = count + 1
                        if count == records.count {
                            self.saveCoreData()
                            self.loadCoreData()
                            NotificationCenter.default.post(name: Notification.Name.syncCompleted, object: nil)
                            sleep(delay)
                        }
                    }

                } else {
                    print("No records")
                }
            }
        }
        sleep(delay)


        // 5 BOOKMARKS
        self.cloudKitLoadRecords(type: "Bookmarks") { (records, error) -> Void in
            if let error = error {
                print(error)
            } else {
                if let records = records {

                    print("Bookmarks " + "\(records.count)")
                    var count = 0
                    for record in records {

                        let newBookmark = Bookmarks(context: self.context)
                        newBookmark.category = record.object(forKey: "category") as? String
                        newBookmark.lastPageVisited = record.object(forKey: "lastPageVisited") as! Int32
                        newBookmark.filename = record.object(forKey: "filename") as? String
                        newBookmark.page = record.object(forKey: "page") as? [Int]
                        newBookmark.path = record.object(forKey: "path") as? String
                        newBookmark.label = record.object(forKey: "label") as? [String]

                        if let book = self.booksCD.first(where: {$0.filename == newBookmark.filename }) {
                            newBookmark.book = book
                        }

                        if let publication = self.publicationsCD.first(where: {$0.filename == newBookmark.filename }) {
                            newBookmark.publication = publication
                        }

                        print(newBookmark)

                        self.bookmarksCD.append(newBookmark)

                        count = count + 1
                        if count == records.count {
                            self.saveCoreData()
                            self.loadCoreData()
                            NotificationCenter.default.post(name: Notification.Name.syncCompleted, object: nil)
                            sleep(delay)
                        }
                    }

                } else {
                    print("No records")
                }
            }
        }
        sleep(delay)


        // 6 MEMOS
        self.cloudKitLoadRecords(type: "Memos") { (records, error) -> Void in
            if let error = error {
                print(error)
            } else {
                if let records = records {

                    print("Memo " + "\(records.count)")
                    var count = 0
                    for record in records {

                        let newMemo = Memo(context: self.context)
                        newMemo.color = record.object(forKey: "color") as? String
                        newMemo.tag = record.object(forKey: "tag") as? String
                        newMemo.dateCreated = record.creationDate
                        newMemo.dateModified = record.modificationDate
                        newMemo.title = record.object(forKey: "title") as? String
                        newMemo.text = record.object(forKey: "text") as? String
                        newMemo.lines = [""]
                        newMemo.id = (record.object(forKey: "id") as? Int64)!

                        print(newMemo)

                        self.memosCD.append(newMemo)

                        count = count + 1
                        if count == records.count {
                            self.saveCoreData()
                            self.loadCoreData()
                            NotificationCenter.default.post(name: Notification.Name.syncCompleted, object: nil)
                            sleep(delay)
                        }
                    }

                } else {
                    print("No records")
                }
            }
        }
        sleep(delay)

        
        // 7 BOOKS
        self.cloudKitLoadRecords(type: "Books") { (records, error) -> Void in
            if let error = error {
                print(error)
            } else {
                if let records = records {

                    print("Books " + "\(records.count)")
                    var count = 0
                    for record in records {

                        let newBook = Book(context: self.context)
                        newBook.filename = record.object(forKey: "filename") as? String
                        newBook.favorite = record.object(forKey: "favorite") as? String
                        newBook.dateCreated = record.creationDate
                        newBook.dateModified = record.modificationDate

                        if let groups = record.object(forKey: "groups") as? [String] {
                            for group in groups {
                                if let tag = self.booksGroupsCD.first(where: {$0.tag == group }) {
                                    newBook.addToBooksGroup(tag)
                                } else {
                                    let newGroup = BooksGroup(context: self.context)
                                    newGroup.tag = group
                                    newGroup.sortNumber = "3"
                                    newGroup.dateModified = Date()
                                    self.booksGroupsCD.append(newGroup)
                                    newBook.addToBooksGroup(newGroup)
                                }
                            }
                        }

                        print(newBook)

                        self.booksCD.append(newBook)

                        count = count + 1
                        if count == records.count {
                            self.saveCoreData()
                            self.loadCoreData()
                            NotificationCenter.default.post(name: Notification.Name.syncCompleted, object: nil)
                            sleep(delay)
                        }
                    }

                } else {
                    print("No records")
                }
            }
        }
        sleep(delay)

        
        // 8 FAVORITES
        self.cloudKitLoadRecords(type: "Favorites") { (records, error) -> Void in
            if let error = error {
                print(error)
            } else {
                if let records = records {

                    print("Favorite " + "\(records.count)")
                    var count = 0
                    for record in records {

                        let newFavorite = Favorites(context: self.context)
                        newFavorite.filename = record.object(forKey: "filename") as? String
                        newFavorite.path = record.object(forKey: "path") as? String
                        newFavorite.category = record.object(forKey: "category") as? String
                        newFavorite.dateModified = record.modificationDate

                        print(newFavorite)

                        self.favoritesCD.append(newFavorite)

                        count = count + 1
                        if count == records.count {
                            self.saveCoreData()
                            self.loadCoreData()
                            NotificationCenter.default.post(name: Notification.Name.syncCompleted, object: nil)
                            sleep(delay)
                        }
                    }

                } else {
                    print("No records")
                }
            }
        }
        
        self.saveCoreData()
        self.loadCoreData()
    }
    
    func updateApplicants(announcement: String, name: String, grade: Int16, education: String?, note: String?, qualifies: Bool) {
        
        if let currentApplicant = applicantCD.first(where: {$0.name == name && $0.announcement == announcement}) {
            
            currentApplicant.education = education
            currentApplicant.grade = grade
            currentApplicant.notes = note
            currentApplicant.qualifies = qualifies
            
            saveCoreData()
            loadCoreData()
            
            print(currentApplicant)
            
        }
    }
    
    func updateCategoriesOrder(category: String) {
        print("updateCategoriesOrder")
        
        if let currentCategory = categoriesCD.first(where: {$0.name ==  category}) {
            if currentCategory.name == "Recently" {
                currentCategory.numberViews = Int64.max
            } else {
                currentCategory.numberViews = currentCategory.numberViews + 1
            }
            
            saveCoreData()
            loadCoreData()
        }
    }

    func updateCoreData(file: LocalFile, oldFilename: String?, newFilename: String?) {
        print("updateCoreData")
        
        if file.category == "Publications" {
            var filename = file.filename
            if oldFilename != nil {
                filename = oldFilename!
            }
            
            if let currentPublication = publicationsCD.first(where: {$0.filename == filename}) {
                
                if oldFilename != nil {
                    currentPublication.filename = newFilename!
                } else {
                    currentPublication.filename = filename
                }
                
                currentPublication.dateModified = file.dateModified
                currentPublication.rank = file.rank!
                currentPublication.year = file.year!
                currentPublication.note = file.note
                currentPublication.favorite = file.favorite
                
                if authorsCD.first(where: {$0.name == file.author}) == nil {
                    let newAuthor = Author(context: context)
                    newAuthor.name = file.author
                    newAuthor.sortNumber = "1"
                    print("Added new author: " + newAuthor.name!)
                    currentPublication.author = newAuthor
                } else {
                    currentPublication.author = authorsCD.first(where: {$0.name == file.author})
                }
                
                if journalsCD.first(where: {$0.name == file.journal}) == nil {
                    let newJournal = Journal(context: context)
                    newJournal.name = file.journal
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
                
            } else {
                // A FILE FOUND IN FOLDER BUT NOT SAVED INTO CORE DATA
                addFileToCoreData(file: file)
            }
            
        } else if file.category == "Books" {
            if let currentBook = booksCD.first(where: {$0.filename == file.filename}) {
                print(currentBook)
                currentBook.dateModified = file.dateModified
                currentBook.rank = file.rank!
                currentBook.note = file.note
                currentBook.favorite = file.favorite
                
                for group in file.groups {
                    if let tmp = booksGroupsCD.first(where: {$0.tag == group}) {
                        currentBook.addToBooksGroup(tmp)
                    } else {
                        let newGroup = BooksGroup(context: context)
                        newGroup.tag = group
                        newGroup.sortNumber = "3"
                        newGroup.dateModified = Date()
                        print("Added new group: " + newGroup.tag!)
                        currentBook.addToBooksGroup(newGroup)
                    }
                }
                
                saveCoreData()
                loadCoreData()
                
            } else {
                // A FILE FOUND IN FOLDER BUT NOT SAVED INTO CORE DATA
                addFileToCoreData(file: file)
            }
        }
    }
    
    func updateCoreDataFund(fund: FundingOrganisation) {
        if fundCD.first(where: {$0.name == fund.name}) != nil {
            saveCoreData()
            loadCoreData()
        }
    }
    
    func updateIcloud(file: LocalFile?, oldFilename: String?, newFilename: String?, expense: Expense?, project: Project?, type: String, bookmark: Bookmarks?, fund: FundingOrganisation?) {
    
        print("updateIcloud")
    
        if type == "Publications" {
            DispatchQueue.main.async {
                var filename = file!.filename
                if oldFilename != nil {
                    filename = oldFilename!
                }
                
                var favorite = "No"
                if self.favoritesCD.first(where: { $0.filename == file?.filename } ) != nil {
                    favorite = "Yes"
                }
                
                let predicate = NSPredicate(format: "Filename = %@", filename)
                let query = CKQuery(recordType: type, predicate: predicate)
                
                self.privateDatabase?.perform(query, inZoneWith: self.recordZone?.zoneID) { (records, error) in
                    guard let records = records else {return}
                    // FOUND AT LEAST ONE RECORD
                    if records.count > 0 {
                        for record in records {
                            print(record.object(forKey: "Filename") as! String + " found in iCloud records")
                            if record.object(forKey: "Filename") as! String == filename {
                                
                                if oldFilename != nil {
                                    record.setObject(newFilename! as CKRecordValue?, forKey: "Filename")
                                    print("Updating icloud filename for " + oldFilename!)
                                }
                                record.setObject(file!.year as CKRecordValue?, forKey: "Year")
                                record.setObject(favorite as CKRecordValue?, forKey: "Favorite")
                                record.setObject(file!.note as CKRecordValue?, forKey: "Note")
                                record.setObject(Int(file!.rank!) as CKRecordValue?, forKey: "Rank")
                                record.setObject(file!.author as CKRecordValue?, forKey: "Author")
                                record.setObject(file!.journal as CKRecordValue?, forKey: "Journal")
                                record.setObject(file!.groups as CKRecordValue?, forKey: "Group")
                                record.setObject(file!.dateModified as CKRecordValue?, forKey: "dateModified")
                                
                                self.privateDatabase?.save(record, completionHandler:( { savedRecord, error in
                                    if let error = error {
                                        print("accountStatus error: \(error)")
                                    }
                                    self.progressMonitor.text = filename + " updated to icloud"
                                    NotificationCenter.default.post(name: Notification.Name.postNotification, object: self)
                                    print(file!.filename + " successfully updated to icloud database")
                                } ))
                            }
                        }
                    } else {
                        if let zoneID = self.recordZone?.zoneID {
                            let myRecord = CKRecord(recordType: "Publications", zoneID: zoneID)
                            myRecord.setObject(file!.filename as CKRecordValue?, forKey: "Filename")
                            myRecord.setObject(file!.author as CKRecordValue?, forKey: "Author")
                            myRecord.setObject(file!.groups as CKRecordValue?, forKey: "Group")
                            myRecord.setObject(file!.rank as CKRecordValue?, forKey: "Rank")
                            myRecord.setObject(file!.year as CKRecordValue?, forKey: "Year")
                            myRecord.setObject(file!.note as CKRecordValue?, forKey: "Note")
                            myRecord.setObject(file!.favorite as CKRecordValue?, forKey: "Favorite")
                            myRecord.setObject(file!.dateModified as CKRecordValue?, forKey: "dateModified")
                            
                            self.modifyRecordsOperation(label: "Publication", myRecord: myRecord, progress: false)
                            
                            self.progressMonitor.text = filename + " updated to icloud"
                            NotificationCenter.default.post(name: Notification.Name.postNotification, object: self)
                        }
                    }
                }
//                if updated {
//                    self.progressMonitor.text = filename + " updated to icloud"
//                    NotificationCenter.default.post(name: Notification.Name.postNotification, object: self)
//                }
            }
            
        } else if type == "Expenses" {
            
            let predicate = NSPredicate(format: "Filename = %@", expense!.idNumber)
            let query = CKQuery(recordType: type, predicate: predicate)
            
            privateDatabase?.perform(query, inZoneWith: recordZone?.zoneID) { (records, error) in
                guard let records = records else {return}
                DispatchQueue.main.async {
                    // FOUND AT LEAST ONE RECORD
                    if records.count > 0 {
                        for record in records {
                            if record.object(forKey: "idNumber") as! Int64 == expense!.idNumber {
                                
                                record.setObject(expense!.amount as CKRecordValue?, forKey: "Amount")
                                record.setObject(expense!.overhead as CKRecordValue?, forKey: "Overhead")
                                record.setObject(expense!.comment as CKRecordValue?, forKey: "Comment")
                                record.setObject(expense!.reference as CKRecordValue?, forKey: "Reference")
                                if let tmp = expense!.project {
                                    record.setObject(tmp.name as CKRecordValue?, forKey: "BelongToProject")
                                }
                                if expense!.active {
                                    record.setObject("Yes" as CKRecordValue?, forKey: "Active")
                                } else {
                                    record.setObject("No" as CKRecordValue?, forKey: "Active")
                                }
                                
                                self.privateDatabase?.save(record, completionHandler:( { savedRecord, error in
                                    DispatchQueue.main.async {
                                        if let error = error {
                                            print("accountStatus error: \(error)")
                                        }
                                        print("Expense successfully updated to icloud database")
                                    }
                                }))
                                
                            }
                        }
                    } else {
                        self.saveToIcloud(url: file?.iCloudURL, type: "Publications", object: file)
                    }
                }
            }
        } else if type == "Projects" {
        
//            //DELETE ALL RECORDS AND REPLACE WITH LOCAL
//            for record in records {
//                print(record.object(forKey: "path") as? String)
//                self.privateDatabase.delete(withRecordID: record.recordID) { (recordID, error) -> Void in
//                    guard let recordID = recordID else {
//                        print("Error deleting record: ", error)
//                        return
//                    }
//                    print("Successfully deleted record: ", recordID.recordName)
//                }
//            }
            
        } else if type == "Favorites add" {
            
            if let favorite = self.favoritesCD.first(where: { $0.path == file?.path} ) {
                
                let predicate = NSPredicate(format: "path = %@", favorite.path!)
                let query = CKQuery(recordType: "Favorites", predicate: predicate)
                
                privateDatabase?.perform(query, inZoneWith: recordZone?.zoneID) { (records, error) in
                    guard let records = records else {return}
                    DispatchQueue.main.async {
                        if records.count > 0 {
                            var found = false
                            for record in records {
                                if record.object(forKey: "path") as? String == favorite.path! {
                                    found = true
                                    self.setFavorites(favorite: favorite, record: record, type: "Found", count: 0)
                                }
                            }
                            if !found {
                                print("Favorite record not found, adding it")
                                if let zoneID = self.recordZone?.zoneID {
                                    let record = CKRecord(recordType: "Favorites", zoneID: zoneID)
                                    self.setFavorites(favorite: favorite, record: record, type: "Not found", count: 0)
                                }
                            }
                        } else {
                            if let zoneID = self.recordZone?.zoneID {
                                let record = CKRecord(recordType: "Favorites", zoneID: zoneID)
                                self.setFavorites(favorite: favorite, record: record, type: "Not found", count: 0)
                            }
                        }
                    }
                }
            }
            
        } else if type == "Favorites remove" {
            
            let predicate = NSPredicate(format: "path = %@", file!.path)
            let query = CKQuery(recordType: "Favorites", predicate: predicate)
            
            privateDatabase?.perform(query, inZoneWith: recordZone?.zoneID) { (records, error) in
                guard let records = records else {return}
                DispatchQueue.main.async {
                    for record in records {
                        if record.object(forKey: "path") as? String == file!.path {
                            self.privateDatabase.delete(withRecordID: record.recordID) { (recordID, error) -> Void in
                                guard let recordID = recordID else {
                                    print("Error deleting record: ", error!)
                                    return
                                }
                                print("Successfully deleted record: ", recordID.recordName)
                            }
                        }
                    }
                }
            }
            
            
        } else if type == "Bookmarks" {
            
            let predicate = NSPredicate(format: "path = %@", bookmark!.path!)
            let query = CKQuery(recordType: type, predicate: predicate)
            
            privateDatabase?.perform(query, inZoneWith: recordZone?.zoneID) { (records, error) in
                guard let records = records else {return}
                DispatchQueue.main.async {
                    if records.count > 0 {
                        var found = false
                        for record in records {
                            if record.object(forKey: "path") as? String == bookmark!.path {
                                found = true
                                self.setBookmark(bookmark: bookmark!, record: record, type: "Found", count: 0)
                            }
                        }
                        if !found {
                            print("Bookmark record not found, adding it")
                            if let zoneID = self.recordZone?.zoneID {
                                let record = CKRecord(recordType: "Bookmarks", zoneID: zoneID)
                                self.setBookmark(bookmark: bookmark!, record: record, type: "Not found", count: 0)
                            }
                        }
                    } else {
                        if let zoneID = self.recordZone?.zoneID {
                            let record = CKRecord(recordType: "Bookmarks", zoneID: zoneID)
                            self.setBookmark(bookmark: bookmark!, record: record, type: "Not found", count: 0)
                        }
                    }
                }
            }

        } else if type == "Books" {
            print("Uploading " + file!.filename)
            
            if let book = self.booksCD.first(where: { $0.filename == file?.filename} ) {
                let predicate = NSPredicate(format: "filename = %@", book.filename!)
                let query = CKQuery(recordType: type, predicate: predicate)
                
                privateDatabase?.perform(query, inZoneWith: recordZone?.zoneID) { (records, error) in
                    guard let records = records else {return}
                    DispatchQueue.main.async {
                        if records.count > 0 {
                            var found = false
                            for record in records {
                                if record.object(forKey: "filename") as? String == book.filename! {
                                    found = true
                                    
                                    self.setBook(book: book, record: record, type: "Found", count: 0)
                                }
                            }
                            if !found {
                                print("Book record not found, adding it")
                                if let zoneID = self.recordZone?.zoneID {
                                    let record = CKRecord(recordType: "Books", zoneID: zoneID)
                                    self.setBook(book: book, record: record, type: "Not found", count: 0)
                                }
                            }
                        } else {
                            if let zoneID = self.recordZone?.zoneID {
                                let record = CKRecord(recordType: "Books", zoneID: zoneID)
                                self.setBook(book: book, record: record, type: "Not found", count: 0)
                            }
                        }
                    }
                }
            }
        }  else if type == "Fund" {
            
            let predicate = NSPredicate(format: "Name = %@", fund!.name!)
            let query = CKQuery(recordType: "FundingOrganisation", predicate: predicate)
            
            privateDatabase?.perform(query, inZoneWith: recordZone?.zoneID) { (records, error) in
                guard let records = records else {return}
                DispatchQueue.main.async {
                    // FOUND AT LEAST ONE RECORD
                    if records.count > 0 {
                        for record in records {
                            if (record.object(forKey: "Name") as! String) == fund!.name {
                                
                                record.setObject(fund!.amount as CKRecordValue?, forKey: "Amount")
                                record.setObject(fund!.currency as CKRecordValue?, forKey: "Currency")
                                record.setObject(fund!.deadline as CKRecordValue?, forKey: "Deadline")
                                record.setObject(fund!.instructions as CKRecordValue?, forKey: "Instructions")
                                record.setObject(fund!.website as CKRecordValue?, forKey: "Website")
                                
                                self.privateDatabase?.save(record, completionHandler:( { savedRecord, error in
                                    DispatchQueue.main.async {
                                        if let error = error {
                                            print("accountStatus error: \(error)")
                                        }
                                        print("Funding organisation successfully updated to icloud database")
                                    }
                                }))
                                
                            }
                        }
                    } else {
                        self.saveToIcloud(url: file?.iCloudURL, type: "Fund", object: fund)
                    }
                }
            }
        }
    }
    
    func updateLocalFile(file: LocalFile, bookmark: Bookmarks?, thumbnail: UIImage?) {
        print("updateLocalFile")
        
        let(number, _) = self.getCategoryNumberAndURL(name: navigator.selected.category)
        if let fileIndex = localFiles[number].index(where: {$0.path == file.path}) {
            localFiles[number][fileIndex].dateModified = Date()
            if bookmark != nil {
                localFiles[number][fileIndex].views = bookmark!.timesVisited
            }
            if thumbnail != nil {
                localFiles[number][fileIndex].thumbnail = thumbnail!
            }
        }
    }
    
    func updateLocalFilesWithCoreData(index: Int, category: Int, coreDataFile: Any) {
        //FIX: If "publications" isn't loaded first, the files are not correctly read.
        
        switch categories[category] {
        case "Publications":
            let currentCoreDataFile = coreDataFile as! Publication
            localFiles[category][index].year = currentCoreDataFile.year
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
                localFiles[category][index].journal = journal
            } else {
                localFiles[category][index].journal = "No journal"
            }
            
            localFiles[category][index].favorite = "No"
            for group in currentCoreDataFile.publicationGroup?.allObjects as! [PublicationGroup] {
                localFiles[category][index].groups.append(group.tag)
                if group.tag == "Favorites" {
                    localFiles[category][index].favorite = "Yes"
                }
            }
            
        case "Books":
            let currentCoreDataFile = coreDataFile as! Book
            localFiles[category][index].rank = currentCoreDataFile.rank
            localFiles[category][index].note = currentCoreDataFile.note
            localFiles[category][index].dateCreated = currentCoreDataFile.dateCreated!
            localFiles[category][index].dateModified = currentCoreDataFile.dateModified!
            localFiles[category][index].favorite = currentCoreDataFile.favorite!
            localFiles[category][index].favorite = "No"

            for group in currentCoreDataFile.booksGroup?.allObjects as! [BooksGroup] {
                localFiles[category][index].groups.append(group.tag)
                if group.tag == "Favorites" {
                    localFiles[category][index].favorite = "Yes"
                }
            }
            
        default:
            print("Default 130")
        }
    }
   
    func uploadApplicants() {
        var count = 1
        for applicant in self.applicantCD {
            
            print(applicant.name!)
            if let zoneID = self.recordZone?.zoneID {
                let record = CKRecord(recordType: "Applicants", zoneID: zoneID)
//                self.setBookmark(bookmark: bookmark, record: record, type: "Not found", count: count)
            }
            count = count + 1
        }
    }
    
    func uploadBookmarks() {
        var count = 1
        for bookmark in self.bookmarksCD {
            
            print(bookmark.filename!)
            if let zoneID = self.recordZone?.zoneID {
                let record = CKRecord(recordType: "Bookmarks", zoneID: zoneID)
                self.setBookmark(bookmark: bookmark, record: record, type: "Not found", count: count)
            }
            count = count + 1
        }
    }
    
    func uploadBooks() {
        var count = 1
        for book in self.booksCD {
            
            print(book.filename as Any)
            if let zoneID = self.recordZone?.zoneID {
                let record = CKRecord(recordType: "Books", zoneID: zoneID)
                self.setBook(book: book, record: record, type: "Not found", count: count)
            }
            count = count + 1
        }
    }
    
    func uploadExpenses() {
        var count = 1
        for expense in self.expensesCD {
            
            print(expense.idNumber)
            if let zoneID = self.recordZone?.zoneID {
                let record = CKRecord(recordType: "Expenses", zoneID: zoneID)
                self.setExpenses(expense: expense, record: record, type: "Not found", count: count)
            }
            count = count + 1
        }
    }
    
    func uploadFavorites() {
        var count = 1
        for favorite in self.favoritesCD {
            
            print(favorite.filename!)
            if let zoneID = self.recordZone?.zoneID {
                let record = CKRecord(recordType: "Favorites", zoneID: zoneID)
                self.setFavorites(favorite: favorite, record: record, type: "Not found", count: count)
            }
            count = count + 1
        }
    }
    
    func uploadFundingOrganisation() {
        var count = 1
        for fund in self.fundCD {
            
            print(fund.name!)
            if let zoneID = self.recordZone?.zoneID {
                let record = CKRecord(recordType: "FundingOrganisation", zoneID: zoneID)
                self.setFundingOrganisation(fundingOrganisation: fund, record: record, type: "Not found", count: count)
            }
            count = count + 1
        }
    }
    
    func uploadMemos() {
        var count = 1
        for memo in self.memosCD {
            
            print(memo.title!)
            if let zoneID = self.recordZone?.zoneID {
                let record = CKRecord(recordType: "Memos", zoneID: zoneID)
                self.setMemo(memo: memo, record: record, type: "Not found", count: count)
            }
            count = count + 1
        }
    }
    
    func updateNotes(file: LocalFile, text: String) {
        print("updateNotes")
        if let note = notesCD.first(where: {$0.path == file.path}) {
            note.text = text
            note.dateModified = Date()
        } else {
            let newNote = Notes(context: self.context)
            newNote.category = file.category
            newNote.dateModified = Date()
            newNote.filename = file.filename
            newNote.path = file.path
            newNote.idNumber = Int64.random(in: 1...50000)
            newNote.text = text
            
            notesCD.append(newNote)
            
            saveCoreData()
            loadCoreData()
        }
    }
    
//    func updateScore(score: Score) {
//
//    }
    
    func uploadProjects() {
        var count = 1
        for project in self.projectCD {
            
            print(project.name as Any)
            if let zoneID = self.recordZone?.zoneID {
                let record = CKRecord(recordType: "Projects", zoneID: zoneID)
                self.setProject(project: project, record: record, type: "Not found", count: count)
            }
            count = count + 1
        }
    }
    
    func uploadPublications() {
        print("uploadPublications()")
        var count = 1
        for file in self.publicationsCD {
            
            print(file.filename!)
            if let zoneID = self.recordZone?.zoneID {
                let record = CKRecord(recordType: "Publications", zoneID: zoneID)
                self.setPublication(publication: file, record: record, type: "Not found", count: count)
            }
            count = count + 1
        }
    }
    
    func uploadToIcloud() {
        print("uploadToIcloud()")
        
        progress = 1
        calcMaxProgress()
        DispatchQueue.global(qos: .background).async {
            for type in self.types {
                print("uploadToIcloud: " + type)
                self.cloudKitLoadRecords(type: type) { (records, error) -> Void in
                    if let error = error {
                        print(error)
                    } else {
                        if let records = records {
                            print(records.count)
                            var count = 1
                            for recond in records {
                                self.privateDatabase.delete(withRecordID: recond.recordID) { (recordID, error) -> Void in
                                    guard let recordID = recordID else {
                                        print("Error deleting record. ", error.debugDescription)
                                        return
                                    }
                                    print("\(count)" + ". Deleted record: ", recordID.recordName)
                                }
                                count += 1
                                NotificationCenter.default.post(name: Notification.Name.uploadProgress, object: self)
                                self.progress += 1
                                sleep(1) //THIS IS NEEDED!
                            }
                            switch type {
                            case "Bookmarks":
                                print("uploadToIcloud: " + type)
                                self.uploadBookmarks()
                            case "Books":
                                print("uploadToIcloud: " + type)
                                self.uploadBooks()
                            case "Expenses":
                                print("uploadToIcloud: " + type)
                                self.uploadExpenses()
                            case "Favorites":
                                print("uploadToIcloud: " + type)
                                self.uploadFavorites()
                            case "FundingOrganisation":
                                print("uploadToIcloud: " + type)
                                self.uploadFundingOrganisation()
                            case "Memos":
                                print("uploadToIcloud: " + type)
                                self.uploadMemos()
                            case "Projects":
                                print("uploadToIcloud: " + type)
                                self.uploadProjects()
                            case "Publications":
                                print("uploadToIcloud: " + type)
                                self.uploadPublications()
                            case "Applicants":
                                print("uploadToIcloud: " + type)
//                                self.uploadPublications()
                            default:
                                print("Default 501")
                            }
                        }
                    }
                }
                sleep(self.getSleep(type: type))
            }
        }
    }
    
    func writeExamResults(exam: Exams, files: [LocalFile]) -> Bool {
        print("writeExamResults()")

        let date = fileHandler.getDeadline(date: Date(), string: nil, option: "Seconds")
        let(number, url) = self.getCategoryNumberAndURL(name: navigator.selected.category)
        let files = localFiles[number]
        let subLabels = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p"]
        let students = exam.student as! Set<Student>
        let tab = "\t"
        var text = String()

        text.append(contentsOf: "Export complete on " + date.string! + "\n")
        text.append(contentsOf: exam.course! + tab)

        for i in 0..<Int(exam.problems) {
            for j in 0..<exam.subProblems![Int(i)] {
                if exam.subProblems![Int(i)] == 1 {
                    text.append(contentsOf: "|" + "\(i+1)" + "|" + tab)
                } else {
                    text.append(contentsOf: "|" + "\(i+1)" + subLabels[j] + "|" + tab)
                }
            }
        }
        text.append(contentsOf: "Sum")

        for file in files {
            let path = file.path.replacingOccurrences(of: file.filename, with: "")
            if path == exam.path && students.first(where: {$0.name == file.filename.replacingOccurrences(of: ".pdf", with: "")}) != nil {
                let student = students.first(where: {$0.name == file.filename.replacingOccurrences(of: ".pdf", with: "")})
                
                text.append(contentsOf: "\n" + student!.name! + tab)
                for i in 0..<Int(exam.problems) {
                    for j in 0..<exam.subProblems![Int(i)] {
                        if j < student!.score![i].count {
                            let score = student!.score![i][j]
                            text.append(contentsOf: "\(score)" + tab)
                        } else {
                            return false
                        }
                    }
                }
                text.append(contentsOf: "\(student!.totalScore)")
            }
        }
        
        var fileURL = url!.appendingPathComponent(navigator.selected.mainFolderName)
        if navigator.selected.folderLevel == 1 {
            fileURL = fileURL.appendingPathComponent(navigator.selected.subFolderName!)
        }

        fileURL = fileURL.appendingPathComponent(exam.course! + " results.txt")
        
        do {
            try text.write(to: fileURL, atomically: false, encoding: .utf8)
        }
        catch {
            print("Error writing to file")
            return false
        }
        
        return true

    }
   
}

