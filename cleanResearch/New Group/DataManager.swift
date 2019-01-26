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
    var docsURL: URL!
//    var icloudURL: URL! // IS THIS NEEDED??
    var localURL: URL!
    
    var privateDatabase: CKDatabase! = nil
    var recordZone: CKRecordZone! = nil
    
    var publicationsLF: [LocalFile] = []
    
    var publicationsIC: [PublicationFile] = []
    var expensesIC: [ExpenseFile] = []
    var projectsIC: [ProjectFile] = []
    var bookmarksIC: [BookmarkFile] = []
    
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

    var iCloudLoaded = false
    
    var isSearching = false
    var searchString: String = ""
    var searchResult: [LocalFile] = []
    
    var selectedCategoryNumber: Int = 0
    var selectedSubtableNumber: Int = 0
    var option: Int = 0
    
    var context: NSManagedObjectContext!

    var progressMonitor: ProgressMonitor!
    var mainView: UIView!
    
    private let fileManagerDefault = FileManager.default
    private let fileHandler = FileHandler()
    
    
    
    func addExpense(amount: Int32, OH: Int16, comment: String, reference: String, type: String, year: Int16) {
        
        let currentProject = projectCD[selectedSubtableNumber]
        let newExpense = Expense(context: context)
        
        newExpense.type = type
        newExpense.amount = amount
        newExpense.overhead = OH
        newExpense.dateAdded = Date()
        newExpense.active = true
        newExpense.comment = comment
        newExpense.reference = reference
        newExpense.years = year
        
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
    
    func addNewItem(title: String?, number: [String?]) {
        
        if categories[selectedCategoryNumber] == "Publications" {
            if let newTag = title {
                let newGroup = PublicationGroup(context: context)
                newGroup.tag = newTag
                newGroup.dateModified = Date()
                newGroup.sortNumber = "3"
                
                publicationGroupsCD.append(newGroup)
                
                saveCoreData()
                loadCoreData()
                
            }
            
        } else if categories[selectedCategoryNumber] == "Books" {
            if let newTag = title {
                let newGroup = BooksGroup(context: context)
                newGroup.tag = newTag
                newGroup.dateModified = Date()
                newGroup.sortNumber = "3"
                
                booksGroupsCD.append(newGroup)
                
                saveCoreData()
                loadCoreData()
                
            }
        } else if categories[selectedCategoryNumber] == "Economy" {
            
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
                        
                        if self.option == 0 {
                        
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
                            
                        } else if self.option == 2 {
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
        print("addFileToRecent")
        
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
            
            print("Added file to recent")
            
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
            print("Removed file to favorites")

        }
        
        for item in favoritesCD {
            print(item.filename)
        }
        
        saveCoreData()
        loadCoreData()
        
    }
    
    func amountReceivedChanged(amountReceived: Int32) {
        if projectCD.count >= selectedSubtableNumber {
            let currentProject = projectCD[selectedSubtableNumber]
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
        if categories[selectedCategoryNumber] == "Publications" {
            
            // LOCAL FILES
            if let index = localFiles[number!].index(where: {$0.filename == filename}) {
                localFiles[number!][index].journal = journalName
                localFiles[number!][index].dateModified = Date()
                
                updateIcloud(file: localFiles[number!][index], oldFilename: nil, newFilename: nil, expense: nil, project: nil, type: "Publications", bookmark: nil, fund: nil)
                updateCoreData(file: localFiles[number!][index], oldFilename: nil, newFilename: nil)
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
        
        for item in publicationGroupsCD {
//            let records = publicationGroupsCD.index(where: {$0.tag == item.tag})
            if item.publication?.count == 0 {
                print(item.tag)
//                context.delete(item)
            }
        }
        
        for item in bookmarksCD {
//            context.delete(item)
        }

        for item in categoriesCD {
            context.delete(item)
        }
        
        for item in authorsCD {
//            let records = authorsCD.index(where: {$0.name == item.name})
            if item.publication?.count == 0 {
                print(item.name)
//                context.delete(item)
            }
        }
        
        for item in journalsCD {
//            let records = journalsCD.index(where: {$0.name == item.name})
            if item.publication?.count == 0 {
                print(item.name)
//                context.delete(item)
            }

        }
        saveCoreData()
        loadCoreData()
    }

    func compareLocalFilesWithCoreData() {
        print("compareLocalFilesWithCoreData")
        
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
    
    func compareLocalFilesWithIcloud() {
        print("compareLocalFilesWithIcloud")
        
        let number = categories.index(where: { $0 == "Publications" })
        
        for i in 0..<localFiles[number!].count {
            print(localFiles[number!][i].filename)
            if let matchedIcloudFile = publicationsIC.first(where: {$0.filename == localFiles[number!][i].filename}) {
                print("Updating " + matchedIcloudFile.filename + " using iCloud record")
                updateLocalFilesWithIcloud(index: i, category: number!, icloudFile: matchedIcloudFile, updateCD: true)
            }
        }
    }
    
    func compareLocalFilesWithDatabase() {
        print("compareLocalFilesWithDatabase")
        
        let number = categories.index(where: { $0 == "Publications" })
        for i in 0..<localFiles[number!].count {
            if let matchedIcloudFile = publicationsIC.first(where: {$0.filename == localFiles[number!][i].filename}) {
                print("Updating " + matchedIcloudFile.filename + " using iCloud record")
                updateLocalFilesWithIcloud(index: i, category: number!, icloudFile: matchedIcloudFile, updateCD: true)
            } else if let matchedCoreDataFile = publicationsCD.first(where: {$0.filename == localFiles[number!][i].filename}) {
                updateLocalFilesWithCoreData(index: i, category: number!, coreDataFile: matchedCoreDataFile)
            } else {
                print("File: " + localFiles[number!][i].filename + " not found in any databases.")
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
    
    func deleteAlliCloudRecords() {
        print("deleteAlliCloudRecords")

//        let pred = NSPredicate(value: true)
//        let sort = NSSortDescriptor(key: "creationDate", ascending: false)
//        let query = CKQuery(recordType: "Publications", predicate: pred)
//        query.sortDescriptors = [sort]
//
//        let operation = CKQueryOperation(query: query)
////        operation.desiredKeys = ["filename"]
//        operation.resultsLimit = 50
//
//
//        operation.recordFetchedBlock = { record in
//            print(record)
//        }
//        print("Finished")
        
//        var request: CKQuery
//        request.fetchLimit = 1
//        request.predicate = NSPredicate(format: "name = %@", txtFieldName.text)
        
        
//        let title = "Berrocal2006.pdf"
//
//        let predicate = NSPredicate(format: "self contains %@", title)
//        let query = CKQuery(recordType: "Publications", predicate: predicate)
        
        let query = CKQuery(recordType: "Publications", predicate: NSPredicate(value: true))
//        query.sortDescriptors = [NSSortDescriptor(key: "modificationDate", ascending: false)]
        self.privateDatabase.perform(query, inZoneWith: self.recordZone.zoneID) { (records, error) in
            guard let records = records else {return}
//            print(records.count)
            for recond in records {
                print(recond.object(forKey: "Filename") as! String)
                self.privateDatabase.delete(withRecordID: recond.recordID) { (recordID, error) -> Void in
                    guard let recordID = recordID else {
                        print("Error deleting record: ", error)
                        return
                    }
                    print("Successfully deleted record: ", recordID.recordName)
                }
            }
        }
    }
    
    func deleteListItem(currentItem: String, type: String?) {
        switch categories[selectedCategoryNumber] {
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
    
    func initIcloudLoad() {
        print("initIcloudLoad")
        
        // GET PUBLICATIONS
        let query = CKQuery(recordType: "Publications", predicate: NSPredicate(value: true))
        self.privateDatabase.perform(query, inZoneWith: self.recordZone.zoneID) { (records, error) in
            
            DispatchQueue.main.async {
                guard let records = records else {return}
                print(records.count)
                for record in records {
                    var load = true
                    print(record.object(forKey: "Filename") as? String)
                    if let dateModified = record.object(forKey: "dateModified") as? Date {
                        let filename = record.object(forKey: "Filename") as! String
                        
                        if let matchedCDFile = self.publicationsCD.first(where: {$0.filename == filename}) {
                            print("Matched CD file: " + matchedCDFile.filename!)
                            print(matchedCDFile.dateModified!)
                            
                            if matchedCDFile.dateModified! > dateModified - 300 {
                                print("Don't load IC")
                                load = false
                            } else {
                                print("Adding: " + filename)
                            }
                        }
                        
                        if load {
                            let newPublication = PublicationFile(filename: record.object(forKey: "Filename") as! String, title: record.object(forKey: "Title") as? String, year: record.object(forKey: "Year") as? Int16, thumbnails: nil, category: "Publications", rank: record.object(forKey: "Rank") as? Float, note: record.object(forKey: "Note") as? String, dateCreated: record.creationDate, dateModified: record.object(forKey: "dateModified") as? Date, favorite: record.object(forKey: "Favorite") as? String, author: record.object(forKey: "Author") as? String, journal: record.object(forKey: "Journal") as? String, groups: record.object(forKey: "Group") as! [String?])
                            self.publicationsIC.append(newPublication)
                        }
                    }
                }
                
                NotificationCenter.default.post(name: Notification.Name.icloudFinished, object: nil)
                self.iCloudLoaded = true
                
            }
        }
        
        // GET PROJECTS
        let queryProjects = CKQuery(recordType: "Projects", predicate: NSPredicate(value: true))
        privateDatabase.perform(queryProjects, inZoneWith: recordZone.zoneID) { (records, error) in
            guard let records = records else {return}
            DispatchQueue.main.async {
                for record in records {
                    let newProject = ProjectFile(name: record.object(forKey: "Name") as! String, amountReceived: record.object(forKey: "AmountReceived") as! Int32, amountRemaining: record.object(forKey: "AmountRemaining") as! Int32, expenses: [])
                    self.projectsIC.append(newProject)
                }
            }
        }
        
        // GET EXPENSES
        let queryExpenses = CKQuery(recordType: "Expenses", predicate: NSPredicate(value: true))
        privateDatabase.perform(queryExpenses, inZoneWith: recordZone.zoneID) { (records, error) in
            guard let records = records else {return}
            DispatchQueue.main.async {
                for record in records {
                    let newExpense = ExpenseFile(amount: record.object(forKey: "Amount") as! Int32, reference: record.object(forKey: "Reference") as? String, overhead: record.object(forKey: "Overhead") as? Int16, comment: record.object(forKey: "Comment") as? String, pdfURL: nil, localFile: nil, belongsToProject: record.object(forKey: "BelongToProject") as! String, idNumber: -1)
                    self.expensesIC.append(newExpense)
                }
            }
        }
        
        // GET BOOKMARKS FIX
        let queryBookmarks = CKQuery(recordType: "Bookmarks", predicate: NSPredicate(value: true))
        privateDatabase.perform(queryBookmarks, inZoneWith: recordZone.zoneID) { (records, error) in
            guard let records = records else {return}
            DispatchQueue.main.async {
                for record in records {
                    let newBookmark = BookmarkFile(filename: (record.object(forKey: "filename") as? String)!, path: (record.object(forKey: "path") as? String)!, category: (record.object(forKey: "category") as? String)!, lastPageVisited: record.object(forKey: "lastPageVisited") as? Int32, page: record.object(forKey: "page") as? [Int])
                    self.bookmarksIC.append(newBookmark)
                }
            }
        }
        
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
            
            return bookmarksCD.first(where: {$0.path! == file.path})
        }
        return nil
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

    }
    
    func modifyRecordsOperation(label: String, myRecord: CKRecord) {
        var ok = true
        let modifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: [myRecord], recordIDsToDelete: nil)
        let configuration = CKOperationConfiguration()
        configuration.timeoutIntervalForRequest = 10
        configuration.timeoutIntervalForResource = 10
        
        modifyRecordsOperation.configuration = configuration
        modifyRecordsOperation.modifyRecordsCompletionBlock =
            { records, recordIDs, error in
                if let err = error {
                    ok = false
                    print(err)
                } else {
                    print(label + " record saved successfully to icloud database")
                }
        }
        self.privateDatabase?.add(modifyRecordsOperation)
        
        if ok {
            progressMonitor.text = label + " record saved to icloud"
            NotificationCenter.default.post(name: Notification.Name.postNotification, object: self)
        } else {
            progressMonitor.text = label + " record not saved to icloud"
            NotificationCenter.default.post(name: Notification.Name.postNotification, object: self)
        }
    }
    
    func newBookmark(file: LocalFile) -> Bookmarks {
        let newBookmark = Bookmarks(context: context)
        newBookmark.path = file.path
        newBookmark.filename = file.filename
        newBookmark.lastPageVisited = 0
        newBookmark.category = file.category
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
    
    func readAllIcloudDriveFolders() {
        print("readAllIcloudDriveFolders")
        
        localFiles = [[]]
        
        for type in categories {
            switch type {
            case "Recently":
                print("Recently folder")
                let number = categories.index(where: { $0 == "Recently" })
                localFiles[number!] = []
                localFiles.append([])
            case "Publications":
                readPublications()
            case "Books":
                readBooks()
            case "Work documents":
                let (number, url) = getCategoryNumberAndURL(name: type)
                readFilesInFolder(url: url!, type: type, number: number)
                readHiringFolder()
            default:
                let (number, url) = getCategoryNumberAndURL(name: type)
                readFilesInFolder(url: url!, type: type, number: number)
            }
        }
    }
    
    func readBooks() {
        print("readBooks")
        
        localFiles.append([])
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
                
                let newFile = LocalFile(label: file.lastPathComponent, thumbnail: thumbnail, favorite: "No", filename: filename, journal: nil, year: -2000, category: "Books", rank: 50, note: "No notes", dateCreated: dates[0], dateModified: dates[1], author: "No author", groups: ["All books"], parentFolder: nil, grandpaFolder: nil, available: available, filetype: nil, iCloudURL: icloudFileURL, localURL: localFileURL, path: path, downloading: false, downloaded: localCopy, uploaded: nil, size: fileHandler.getSize(url: icloudFileURL), saving: false)
                let number = categories.index(where: { $0 == "Books" })
                localFiles[number!].append(newFile)
                
            }
        } catch {
            print("Error while enumerating files \(booksURL.path): \(error.localizedDescription)")
        }
    }
    
    func readFilesInFolder(url: URL, type: String, number: Int) {
        print("readFilesInFolder: " + categories[number])
        
        do {
            let folderURLs = try fileManagerDefault.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            localFiles.append([])

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
                    
                    let newFile = LocalFile(label: filename, thumbnail: thumbnail, favorite: "No", filename: filename, journal: nil, year: nil, category: type, rank: nil, note: "No notes", dateCreated: dates[0], dateModified: dates[1], author: nil, groups: [nil], parentFolder: "Uncategorized", grandpaFolder: "Uncategorized", available: available, filetype: nil, iCloudURL: icloudFileURL, localURL: localFileURL, path: path, downloading: false, downloaded: localCopy, uploaded: nil, size: fileHandler.getSize(url: icloudFileURL), saving: false)
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
                            
                            let newFile = LocalFile(label: filename, thumbnail: thumbnail, favorite: "No", filename: filename, journal: nil, year: nil, category: type, rank: nil, note: "No notes", dateCreated: dates[0], dateModified: dates[1], author: nil, groups: [nil], parentFolder: "Uncategorized", grandpaFolder: folder.lastPathComponent, available: available, filetype: nil, iCloudURL: icloudFileURL, localURL: localFileURL, path: path, downloading: false, downloaded: localCopy, uploaded: nil, size: fileHandler.getSize(url: icloudFileURL), saving: false)
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
                                
                                let newFile = LocalFile(label: filename, thumbnail: thumbnail, favorite: "No", filename: filename, journal: nil, year: nil, category: type, rank: nil, note: "No notes", dateCreated: dates[0], dateModified: dates[1], author: nil, groups: [nil], parentFolder: subfolder.lastPathComponent, grandpaFolder: folder.lastPathComponent, available: available, filetype: nil, iCloudURL: icloudFileURL, localURL: localFileURL, path: path, downloading: false, downloaded: localCopy, uploaded: nil, size: fileHandler.getSize(url: icloudFileURL), saving: false)
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
                                    let filePath = mainPath + folder.lastPathComponent + subfolder.lastPathComponent + file.lastPathComponent
                                    let thumbnail = fileHandler.getThumbnail(icloudURL: icloudFileURL, localURL: icloudFileURL, localExist: false, pageNumber: 0)
                                    
                                    let dates = fileHandler.getDates(url: icloudFileURL)
                                    
                                    let newFile = LocalFile(label: file.lastPathComponent, thumbnail: thumbnail, favorite: "No", filename: file.lastPathComponent, journal: nil, year: nil, category: "Hiring", rank: 5, note: "No notes", dateCreated: dates[0], dateModified: dates[1], author: nil, groups: [nil], parentFolder: subfolder.lastPathComponent, grandpaFolder: folder.lastPathComponent, available: available, filetype: nil, iCloudURL: icloudFileURL, localURL: icloudFileURL, path: path, downloading: false, downloaded: false, uploaded: nil, size: fileHandler.getSize(url: icloudFileURL), saving: false)
                                    hiringFiles.append(newFile)
                                }
                            }
                            
                            if let currentApplicant = applicantCD.first(where: {$0.name == name}) {
                                print("Applicant already stored in CD")
                            } else {
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
                
                let newFile = LocalFile(label: file.lastPathComponent, thumbnail: thumbnail, favorite: "No", filename: filename, journal: "No journal", year: -2000, category: "Publications", rank: 50, note: "No notes", dateCreated: dates[0], dateModified: dates[1], author: "No author", groups: ["All publications"], parentFolder: nil, grandpaFolder: nil, available: available, filetype: nil, iCloudURL: icloudFileURL, localURL: localFileURL, path: path, downloading: false, downloaded: localCopy, uploaded: nil, size: fileHandler.getSize(url: icloudFileURL), saving: false)
                localFiles[number!].append(newFile)
                
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
            compareLocalFilesWithDatabase()
            
        case "Books":
            readBooks()
            compareLocalFilesWithCoreData()
            
        case "Recently":
            print("Recently")
            
        default:
            let (number, url) = getCategoryNumberAndURL(name: categories[category])
            readFilesInFolder(url: url!, type: categories[category], number: number)
            
        }
    }
    
    func removeFromGroup(file: LocalFile, group: String) {
        print("removeFromGroup")
        
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
            }
        }
        
    }
    
    func replaceLocalFileWithNew(newFile: LocalFile) {
        print("replaceLocalFileWithNew")
        
        if let index = localFiles[selectedCategoryNumber].index(where: { $0.filename == newFile.filename } ) {
            localFiles[selectedCategoryNumber][index] = newFile
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
                    
                    self.modifyRecordsOperation(label: "Publication", myRecord: myRecord)
            
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
                    
                    self.modifyRecordsOperation(label: "Expense", myRecord: myRecord)
                    
                } else if type == "Projects" {
                    
                    let myRecord = CKRecord(recordType: "Projects", zoneID: zoneID)
                    let project = object as! Project
                    myRecord.setObject(project.amountReceived as CKRecordValue?, forKey: "AmountReceived")
                    myRecord.setObject(project.amountRemaining as CKRecordValue?, forKey: "AmountRemaining")
                    myRecord.setObject(project.name as CKRecordValue?, forKey: "Name")
                    myRecord.setObject(project.dateCreated as CKRecordValue?, forKey: "createdAt")
                    
                    self.modifyRecordsOperation(label: "Project", myRecord: myRecord)
                    
                } else if type == "Bookmarks" {
                    
                    let myRecord = CKRecord(recordType: "Bookmarks", zoneID: zoneID)
                    let bookmark = object as! Bookmarks
                    
                    myRecord.setObject(bookmark.category as CKRecordValue?, forKey: "category")
                    myRecord.setObject(bookmark.filename as CKRecordValue?, forKey: "filename")
                    myRecord.setObject(bookmark.lastPageVisited as CKRecordValue?, forKey: "lastPageVisited")
                    myRecord.setObject(bookmark.page as CKRecordValue?, forKey: "page")
                    myRecord.setObject(bookmark.path as CKRecordValue?, forKey: "path")
                    
                    self.modifyRecordsOperation(label: "Bookmarks", myRecord: myRecord)
                    
                } else if type == "Fund" {
                    
                    let myRecord = CKRecord(recordType: "FundingOrganisation", zoneID: zoneID)
                    let organisation = object as! FundingOrganisation
                    
                    myRecord.setObject(organisation.name as CKRecordValue?, forKey: "Name")
                    myRecord.setObject(organisation.amount as CKRecordValue?, forKey: "Amount")
                    myRecord.setObject(organisation.currency as CKRecordValue?, forKey: "Currency")
                    myRecord.setObject(organisation.deadline as CKRecordValue?, forKey: "Deadline")
                    myRecord.setObject("Proposal instructions" as CKRecordValue?, forKey: "Instructions")
                    myRecord.setObject("Website?" as CKRecordValue?, forKey: "Website")
                    
                    self.modifyRecordsOperation(label: "FundingOrganisation", myRecord: myRecord)
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
        
        if categories[selectedCategoryNumber] == "Publications" {
            if searchString.count > 0 {
                searchResult = localFiles[selectedCategoryNumber].filter{ $0.filename.contains(searchString) || $0.author!.contains(searchString) || $0.journal!.contains(searchString) || $0.note!.contains(searchString) }
            } else {
                isSearching = false
            }
        } else if categories[selectedCategoryNumber] == "Teaching" {
            if searchString.count > 0 {
                searchResult = localFiles[selectedCategoryNumber].filter{ $0.filename.contains(searchString) }
            } else {
                isSearching = false
            }
        }
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
        if let currentFund = fundCD.first(where: {$0.name == fund.name}) {
            saveCoreData()
            loadCoreData()
        }
    }
    
    func updateIcloud(file: LocalFile?, oldFilename: String?, newFilename: String?, expense: Expense?, project: Project?, type: String, bookmark: Bookmarks?, fund: FundingOrganisation?) {
    
        print("updateIcloud")
        
        var updated = true
    
        if type == "Publications" {
            DispatchQueue.main.async {
                var filename = file!.filename
                if oldFilename != nil {
                    filename = oldFilename!
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
                                record.setObject(file!.favorite as CKRecordValue?, forKey: "Favorite")
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
                            
                            self.modifyRecordsOperation(label: "Publication", myRecord: myRecord)
                        }
                    }
                }
                if updated {
                    print("posted")
                    self.progressMonitor.text = filename + " updated to icloud"
                    NotificationCenter.default.post(name: Notification.Name.postNotification, object: self)
                }
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
            
        } else if type == "Bookmarks" {
            
            let predicate = NSPredicate(format: "path = %@", bookmark!.path!)
            let query = CKQuery(recordType: type, predicate: predicate)
            
            privateDatabase?.perform(query, inZoneWith: recordZone?.zoneID) { (records, error) in
                guard let records = records else {return}
                DispatchQueue.main.async {
                    // FOUND AT LEAST ONE RECORD
                    if records.count > 0 {
                        for record in records {
                            if record.object(forKey: "path") as! String == bookmark?.path {
                                record.setObject(bookmark!.category as CKRecordValue?, forKey: "category")
                                record.setObject(bookmark!.filename as CKRecordValue?, forKey: "filename")
                                record.setObject(bookmark!.lastPageVisited as CKRecordValue?, forKey: "lastPageVisited")
                                record.setObject(bookmark!.page as CKRecordValue?, forKey: "page")
                                record.setObject(bookmark!.path as CKRecordValue?, forKey: "path")
                                
                                self.privateDatabase?.save(record, completionHandler:( { savedRecord, error in
                                    DispatchQueue.main.async {
                                        if let error = error {
                                            print("accountStatus error: \(error)")
                                        }
                                        print("Bookmark successfully updated to icloud database")
                                    }
                                }))
                            }
                        }
                    } else {
                        self.saveToIcloud(url: nil, type: "Bookmarks", object: bookmark!)
                    }
                }
            }

        }  else if type == "Fund" {
            
            let predicate = NSPredicate(format: "Name = %@", fund!.name!)
            let query = CKQuery(recordType: type, predicate: predicate)
            
            privateDatabase?.perform(query, inZoneWith: recordZone?.zoneID) { (records, error) in
                guard let records = records else {return}
                DispatchQueue.main.async {
                    // FOUND AT LEAST ONE RECORD
                    if records.count > 0 {
                        for record in records {
                            if record.object(forKey: "Name") as! String == fund!.name {
                                
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
                        self.saveToIcloud(url: file?.iCloudURL, type: "Fund", object: file)
                    }
                }
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
            localFiles[category][index].note = currentCoreDataFile.note!
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

    func updateLocalFilesWithIcloud(index: Int, category: Int, icloudFile: Any, updateCD: Bool) {
        print("updateLocalFilesWithIcloud")
        
        if categories[category] == "Publications" {
            
            let currentIcloudFile = icloudFile as! PublicationFile
            localFiles[category][index].year = currentIcloudFile.year
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
            
            if updateCD {
                //Update Core data with just updated localFiles
                updateCoreData(file: localFiles[category][index], oldFilename: nil, newFilename: nil)
            }
        } else if categories[category] == "Books" {
            print("Books")
        }
    }
    
    
    
}


//    func addOrRemoveFromFavorite(file: LocalFile) -> LocalFile {
//        print("addOrRemoveFromFavorite")
//
//        var selectedFile = file
//        if selectedFile.category == "Publications" {
//            let favoritesGroup = publicationGroupsCD
//
//            if selectedFile.favorite == "No" {
//                selectedFile.favorite = "Yes"
//                selectedFile.groups.append("Favorites")
//                if let currentPublication = publicationsCD.first(where: {$0.filename == selectedFile.filename}) {
//
//                    currentPublication.addToPublicationGroup(favoritesGroup!)
//
//                    saveCoreData()
//                    loadCoreData()
//                } else {
//                    addFileToCoreData(file: selectedFile)
//                }
//            } else {
//
//                let groups = selectedFile.groups
//                let filteredGroups = groups.filter { $0 != "Favorites" }
//                selectedFile.groups = filteredGroups
//                selectedFile.favorite = "No"
//
//                if let currentPublication = publicationsCD.first(where: {$0.filename == selectedFile.filename}) {
//
//                    currentPublication.removeFromPublicationGroup(favoritesGroup!)
//
//                    saveCoreData()
//                    loadCoreData()
//
//                } else {
//                    addFileToCoreData(file: selectedFile)
//                }
//            }
//
//        } else if selectedFile.category == "Books" {
//            let favoritesGroup = booksGroupsCD.first(where: {$0.tag == "Favorites"})
//
//            if selectedFile.favorite == "No" {
//                selectedFile.favorite = "Yes"
//                selectedFile.groups.append("Favorites")
//
//                if let currentBook = booksCD.first(where: {$0.filename == selectedFile.filename}) {
//                    currentBook.addToBooksGroup(favoritesGroup!)
//                    saveCoreData()
//                    loadCoreData()
//                } else {
//                    addFileToCoreData(file: selectedFile)
//                }
//            } else {
//
//                let groups = selectedFile.groups
//                let filteredGroups = groups.filter { $0 != "Favorites" }
//                selectedFile.groups = filteredGroups
//                selectedFile.favorite = "No"
//
//                if let currentBook = booksCD.first(where: {$0.filename == selectedFile.filename}) {
//
//                    currentBook.removeFromBooksGroup(favoritesGroup!)
//
//                    saveCoreData()
//                    loadCoreData()
//                } else {
//                    print("Book not found in CD")
//                    addFileToCoreData(file: selectedFile)
//                }
//            }
//        }
//
//        return selectedFile
//    }
