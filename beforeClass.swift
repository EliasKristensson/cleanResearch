//
//  beforeClass.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-10-26.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import Foundation

/*
func getCategoryNumberAndURL(name: String) -> (number: Int, url: URL) {
    var number = 1
    var url: URL!
    
    if name == "Publications" {
        number = 0
        url = publicationsURL
    } else if name == "Economy" {
        number = 1
        url = economyURL
    } else if name == "Manuscripts" {
        number = 2
        url = manuscriptsURL
    } else if name == "Presentations" {
        number = 3
        url = presentationsURL
    } else if name == "Proposals" {
        number = 4
        url = proposalsURL
    } else if name == "Supervision" {
        number = 5
        url = supervisionsURL
    } else if name == "Teaching" {
        number = 6
        url = teachingURL
    } else if name == "Patents" {
        number = 7
        url = patentsURL
    } else if name == "Courses" {
        number = 8
        url = coursesURL
    } else if name == "Meetings" {
        number = 9
        url = meetingsURL
    } else if name == "Conferences" {
        number = 10
        url = conferencesURL
    } else if name == "Reviews" {
        number = 11
        url = reviewsURL
    } else if name == "Miscellaneous" {
        number = 12
        url = miscellaneousURL
    }
    return (number, url)
}

 func searchFolders(categoryURL: URL, categoryNumber: Int) {
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
 print("Error")
 }
 
 if filesAfter != filesBefore {
 reloadLocalFiles(category: categoryNumber)
 } else {
 print(categories[categoryNumber] + " unchanged")
 }
 }
 
 
 func handleFilename(icloudURL: URL) -> String {
 var filename = String()
 if icloudURL.lastPathComponent.range(of:".icloud") != nil {
 filename = icloudURL.deletingPathExtension().lastPathComponent
 filename.remove(at: filename.startIndex)
 } else {
 filename = icloudURL.lastPathComponent
 }
 return filename
 }
 
 func readIcloudDriveFolders() {
 localFiles = [[]]
 
 for type in categories{
 switch type {
 case "Publications":
 do {
 let fileURLs = try fileManagerDefault.contentsOfDirectory(at: publicationsURL!, includingPropertiesForKeys: nil)
 for file in fileURLs {
 var available = true
 let icloudFileURL = file
 let filename = handleFilename(icloudURL: icloudFileURL)
 let path = type + filename
 let localFileURL = docsURL.appendingPathComponent("Publications").appendingPathComponent(filename)
 
 let localCopy = fileManagerDefault.fileExists(atPath: localFileURL.path)
 
 let thumbnail = handleThumbnail(icloudURL: icloudFileURL, localURL: localFileURL, localExist: localCopy)
 
 if icloudFileURL.lastPathComponent.range(of:".icloud") != nil {
 available = false
 }
 
 let newFile = LocalFile(label: file.lastPathComponent, thumbnail: thumbnail, favorite: "No", filename: filename, journal: "No journal", year: -2000, category: "Publications", rank: 50, note: "No notes", dateCreated: Date(), dateModified: Date(), author: "No author", groups: ["All publications"], parentFolder: nil, grandpaFolder: nil, available: available, filetype: nil, iCloudURL: icloudFileURL, localURL: localFileURL, path: path, downloading: false, downloaded: localCopy, uploaded: nil, size: getSize(url: icloudFileURL))
 localFiles[0].append(newFile)
 
 }
 } catch {
 print("Error while enumerating files \(publicationsURL.path): \(error.localizedDescription)")
 }
 default:
 let (number, url) = getCategoryNumberAndURL(name: type)
 readFilesInFolders(url: url, type: type, number: number)
 }
 }
 }
 
 
 func readFilesInFolders(url: URL, type: String, number: Int) {
 do {
 let folderURLs = try fileManagerDefault.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
 localFiles.append([])
 for folder in folderURLs {
 if folder.isDirectory()! {
 let subfoldersURLs = try fileManagerDefault.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
 for subfolder in subfoldersURLs {
 if subfolder.isDirectory()! {
 let files = try fileManagerDefault.contentsOfDirectory(at: subfolder, includingPropertiesForKeys: nil)
 for file in files {
 var available = true
 let icloudFileURL = file
 let filename = handleFilename(icloudURL: icloudFileURL)
 
 let path = type + folder.lastPathComponent + subfolder.lastPathComponent + filename
 let localFileURL = docsURL.appendingPathComponent(type).appendingPathComponent(folder.lastPathComponent).appendingPathComponent(subfolder.lastPathComponent).appendingPathComponent(filename)
 
 let localCopy = fileManagerDefault.fileExists(atPath: localFileURL.path)
 
 let thumbnail = handleThumbnail(icloudURL: icloudFileURL, localURL: localFileURL, localExist: localCopy)
 
 if icloudFileURL.lastPathComponent.range(of:".icloud") != nil {
 available = false
 }
 
 let newFile = LocalFile(label: filename, thumbnail: thumbnail, favorite: "No", filename: filename, journal: nil, year: nil, category: type, rank: nil, note: "No notes", dateCreated: Date(timeIntervalSince1970: 0), dateModified: Date(timeIntervalSince1970: 0), author: nil, groups: [nil], parentFolder: subfolder.lastPathComponent, grandpaFolder: folder.lastPathComponent, available: available, filetype: nil, iCloudURL: icloudFileURL, localURL: localFileURL, path: path, downloading: false, downloaded: localCopy, uploaded: nil, size: getSize(url: icloudFileURL))
 localFiles[number].append(newFile)
 
 }
 } else {
 var available = true
 let icloudFileURL = subfolder
 let filename = handleFilename(icloudURL: icloudFileURL)
 let path = type + folder.lastPathComponent + filename
 let localFileURL = docsURL.appendingPathComponent(type).appendingPathComponent(folder.lastPathComponent).appendingPathComponent(filename)
 let localCopy = fileManagerDefault.fileExists(atPath: localFileURL.path)
 
 let thumbnail = handleThumbnail(icloudURL: icloudFileURL, localURL: localFileURL, localExist: localCopy)
 
 if icloudFileURL.lastPathComponent.range(of:".icloud") != nil {
 available = false
 }
 
 let newFile = LocalFile(label: filename, thumbnail: thumbnail, favorite: "No", filename: filename, journal: nil, year: nil, category: type, rank: nil, note: "No notes", dateCreated: Date(timeIntervalSince1970: 0), dateModified: Date(timeIntervalSince1970: 0), author: nil, groups: [nil], parentFolder: "Uncategorized", grandpaFolder: folder.lastPathComponent, available: available, filetype: nil, iCloudURL: icloudFileURL, localURL: localFileURL, path: path, downloading: false, downloaded: localCopy, uploaded: nil, size: getSize(url: icloudFileURL))
 localFiles[number].append(newFile)
 
 }
 }
 } else {
 var available = true
 let icloudFileURL = folder
 let filename = handleFilename(icloudURL: icloudFileURL)
 let path = type + folder.lastPathComponent + filename
 let localFileURL = docsURL.appendingPathComponent(type).appendingPathComponent(folder.lastPathComponent).appendingPathComponent(filename)
 let localCopy = fileManagerDefault.fileExists(atPath: localFileURL.path)
 
 let thumbnail = handleThumbnail(icloudURL: icloudFileURL, localURL: localFileURL, localExist: localCopy)
 
 if icloudFileURL.lastPathComponent.range(of:".icloud") != nil {
 available = false
 }
 
 let newFile = LocalFile(label: filename, thumbnail: thumbnail, favorite: "No", filename: filename, journal: nil, year: nil, category: type, rank: nil, note: "No notes", dateCreated: Date(timeIntervalSince1970: 0), dateModified: Date(timeIntervalSince1970: 0), author: nil, groups: [nil], parentFolder: "Uncategorized", grandpaFolder: "Uncategorized", available: available, filetype: nil, iCloudURL: icloudFileURL, localURL: localFileURL, path: path, downloading: false, downloaded: localCopy, uploaded: nil, size: getSize(url: icloudFileURL))
 localFiles[number].append(newFile)
 
 }
 
 }
 } catch {
 print("Error while reading " + type + " folders")
 }
 
 }
 
 
 func reloadLocalFiles(category: Int) {
 
 localFiles[category] = []
 switch categories[category] {
 case "Publications":
 do {
 let fileURLs = try fileManagerDefault.contentsOfDirectory(at: publicationsURL!, includingPropertiesForKeys: nil)
 for file in fileURLs {
 var available = true
 let icloudFileURL = file
 let filename = handleFilename(icloudURL: icloudFileURL)
 let path = "Publications" + filename
 let localFileURL = docsURL.appendingPathComponent("Publications").appendingPathComponent(filename)
 
 let localCopy = fileManagerDefault.fileExists(atPath: localFileURL.path)
 
 let thumbnail = handleThumbnail(icloudURL: icloudFileURL, localURL: localFileURL, localExist: localCopy)
 
 if icloudFileURL.lastPathComponent.range(of:".icloud") != nil {
 available = false
 }
 
 let newFile = LocalFile(label: file.lastPathComponent, thumbnail: thumbnail, favorite: "No", filename: filename, journal: "No journal", year: -2000, category: "Publications", rank: 50, note: "No notes", dateCreated: Date(timeIntervalSince1970: 0), dateModified: Date(timeIntervalSince1970: 0), author: "No author", groups: ["All publications"], parentFolder: nil, grandpaFolder: nil, available: available, filetype: nil, iCloudURL: icloudFileURL, localURL: localFileURL, path: path, downloading: false, downloaded: localCopy, uploaded: nil, size: getSize(url: icloudFileURL))
 localFiles[0].append(newFile)
 
 }
 compareLocalFilesWithDatabase()
 
 } catch {
 print("Error while enumerating files \(publicationsURL.path): \(error.localizedDescription)")
 
 }
 
 default:
 
 let (number, url) = getCategoryNumberAndURL(name: categories[category])
 readFilesInFolders(url: url, type: categories[category], number: number)
 
 }
 
 populateListTable()
 populateFilesCV()
 sortFiles()
 categoriesCV.reloadData()
 listTableView.reloadData()
 filesCollectionView.reloadData()
 
 }
 
 
 func getSize(url: URL) -> String {
 var fileSize: UInt64 = 0
 var sizeString: String = "134 kb"
 
 do {
 let attr = try fileManagerDefault.attributesOfItem(atPath: url.path)
 fileSize = attr[FileAttributeKey.size] as! UInt64
 
 } catch {
 print("Error: \(error)")
 }
 
 if fileSize < 1000 {
 sizeString = "\(fileSize)" + " b"
 } else if fileSize >= 1000 && fileSize < 1000000 {
 sizeString = "\(fileSize/1000)" + " kb"
 } else if fileSize >= 1000000 && fileSize < 1000000000 {
 let tmp = (Double(fileSize)/100000).rounded()/10
 sizeString = "\(tmp)" + " Mb"
 } else if fileSize >= 1000000000 {
 let tmp = (Double(fileSize)/100000000).rounded()/10
 sizeString = "\(tmp)" + " Gb"
 }
 
 return sizeString
 }
 
 
 
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
 
 let requestBookmarks: NSFetchRequest<Bookmarks> = Bookmarks.fetchRequest()
 requestBookmarks.sortDescriptors = [NSSortDescriptor(key: "filename", ascending: true)]
 do {
 bookmarksCD = try context.fetch(requestBookmarks)
 } catch {
 print("Error loading bookmarks")
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
 
 func updateCoreData(file: LocalFile, oldFilename: String?, newFilename: String?) {
 
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
 
 currentPublication.dateModified = Date()
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
 }
 
 
 
 func updateLocalFilesWithIcloud(index: Int, category: Int, icloudFile: Any) {
 switch category {
 case 0:
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
 
 //Update Core data with just updated localFiles
 updateCoreData(file: localFiles[category][index], oldFilename: nil, newFilename: nil)
 
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
 
 default:
 print("Default 130")
 }
 }

 
 
 
 func addFileToCoreData(file: LocalFile) {
 switch categories[selectedCategoryNumber] {
 case "Publications":
 let newPublication = Publication(context: context)
 
 newPublication.filename = file.filename
 newPublication.thumbnail = getThumbnail(url: publicationsURL.appendingPathComponent(file.filename), pageNumber: 0)
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
 print("Added new author: " + newAuthor.name!)
 newPublication.author = newAuthor
 
 saveCoreData()
 loadCoreData()
 } else {
 newPublication.author = authorsCD.first(where: {$0.name == file.author})
 }
 
 if journalsCD.first(where: {$0.name == file.journal}) == nil {
 let newJournal = Journal(context: context)
 newJournal.name = file.journal
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

 
 
 func assignPublicationToAuthor(filename: String, authorName: String) {
 
 // LOCAL FILES
 for i in 0..<localFiles[0].count {
 if localFiles[0][i].filename == filename {
 localFiles[0][i].author = authorName
 updateIcloud(file: localFiles[0][i], oldFilename: nil, newFilename: nil)
 updateCoreData(file: localFiles[0][i], oldFilename: nil, newFilename: nil)
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
 
 updateIcloud(file: localFiles[0][i], oldFilename: nil, newFilename: nil)
 updateCoreData(file: localFiles[0][i], oldFilename: nil, newFilename: nil)
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
 updateIcloud(file: localFiles[0][i], oldFilename: nil, newFilename: nil)
 dataManager.updateCoreData(file: localFiles[0][i], oldFilename: nil, newFilename: nil)
 }
 }
 }
 
 
 
 func updateDatabasesWithNewFileInformation(currentFile: LocalFile) {
 if categories[selectedCategoryNumber] == "Publications" {
 print("Updating databases")
 // UPDATING LOCALFILES
 navigationController?.title = "Uploading " + (currentFile.filename)
 
 // UPDATING CORE DATA
 updateCoreData(file: currentFile, oldFilename: nil, newFilename: nil)
 
 // UPDATING ICLOUD
 updateIcloud(file: currentFile, oldFilename: nil, newFilename: nil)
 
 populateListTable()
 populateFilesCV()
 sortFiles()
 listTableView.reloadData()
 filesCollectionView.reloadData()
 
 navigationController?.title = ""
 
 }
 }
 
 
 func handleThumbnail(icloudURL: URL, localURL: URL, localExist: Bool) -> UIImage {
 var thumbnail = UIImage()
 //
 //        thumbnail = thumbnailHandler.get(url: icloudURL, pageNumber: 0)
 //
 //        if localExist {
 //            thumbnail = thumbnailHandler.get(url: localURL, pageNumber: 0)
 //        }
 return thumbnail
 }
 
 
 func getThumbnail(url: URL, pageNumber: Int) -> UIImage {
 var pageThumbnail = #imageLiteral(resourceName: "FileOffline")
 if url.lastPathComponent.range(of:".jpg") != nil {
 pageThumbnail = #imageLiteral(resourceName: "JpgIcon")
 if url.lastPathComponent.range(of:".icloud") == nil {
 if let data = try? Data(contentsOf: url) {
 pageThumbnail = UIImage(data: data)!
 }
 }
 
 } else if url.lastPathComponent.range(of:".pdf") != nil || url.lastPathComponent.range(of:".PDF") != nil {
 if let document = PDFDocument(url: url) {
 let page: PDFPage!
 page = document.page(at: pageNumber)!
 pageThumbnail = page.thumbnail(of: CGSize(width: 210, height: 297), for: .artBox)
 }
 } else if url.lastPathComponent.range(of:".tiff") != nil {
 pageThumbnail = #imageLiteral(resourceName: "TIFF")
 if url.lastPathComponent.range(of:".icloud") == nil {
 if let data = try? Data(contentsOf: url) {
 pageThumbnail = UIImage(data: data)!
 }
 }
 } else if url.lastPathComponent.range(of:".png") != nil {
 pageThumbnail = #imageLiteral(resourceName: "PNG")
 if url.lastPathComponent.range(of:".icloud") == nil {
 if let data = try? Data(contentsOf: url) {
 pageThumbnail = UIImage(data: data)!
 }
 }
 } else if url.lastPathComponent.range(of:".m") != nil {
 pageThumbnail = #imageLiteral(resourceName: "M")
 } else if url.lastPathComponent.range(of:".ai") != nil {
 pageThumbnail = #imageLiteral(resourceName: "AI")
 } else if url.lastPathComponent.range(of:".eps") != nil {
 pageThumbnail = #imageLiteral(resourceName: "EPS")
 } else if url.lastPathComponent.range(of:".pptx") != nil || url.lastPathComponent.range(of:".ppt") != nil {
 pageThumbnail = #imageLiteral(resourceName: "PowerpointIcon")
 } else if url.lastPathComponent.range(of:".docx") != nil || url.lastPathComponent.range(of:".doc") != nil {
 pageThumbnail = #imageLiteral(resourceName: "WordIcon")
 } else if url.lastPathComponent.range(of:".xlsx") != nil || url.lastPathComponent.range(of:".xlsm") != nil {
 pageThumbnail = #imageLiteral(resourceName: "ExcelIcon")
 } else if url.lastPathComponent.range(of:".key") != nil {
 pageThumbnail = #imageLiteral(resourceName: "KeynoteIcon")
 } else if url.lastPathComponent.range(of:".txt") != nil {
 pageThumbnail = #imageLiteral(resourceName: "TXT")
 }
 return pageThumbnail
 }
 
 
 func saveToIcloud(url: URL?, type: String, object: Any?) {
 if let zoneID = recordZone?.zoneID {
 
 switch categories[selectedCategoryNumber] {
 case "Publications":
 print("Publications")
 //                // Saving default values
 //                let myRecord = CKRecord(recordType: "Publications", zoneID: zoneID)
 //                let thumbnail = CKAsset(fileURL: url!)
 //                let tag = ["All publications"]
 //                myRecord.setObject(url?.lastPathComponent as CKRecordValue?, forKey: "Filename")
 //                myRecord.setObject("No author" as CKRecordValue?, forKey: "Author")
 //                myRecord.setObject(thumbnail as CKRecordValue?, forKey: "Thumbnail")
 //                myRecord.setObject(tag as CKRecordValue?, forKey: "Group")
 //                myRecord.setObject(50 as CKRecordValue?, forKey: "Rank")
 //                myRecord.setObject(-2000 as CKRecordValue?, forKey: "Year")
 //                myRecord.setObject("No notes" as CKRecordValue?, forKey: "Note")
 //                myRecord.setObject("No title" as CKRecordValue?, forKey: "Title")
 //                myRecord.setObject("No" as CKRecordValue?, forKey: "Favorite")
 //
 //                let modifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: [myRecord], recordIDsToDelete: nil)
 //                let configuration = CKOperationConfiguration()
 //                configuration.timeoutIntervalForRequest = 10
 //                configuration.timeoutIntervalForResource = 10
 //
 //                modifyRecordsOperation.configuration = configuration
 //                modifyRecordsOperation.modifyRecordsCompletionBlock =
 //                    { records, recordIDs, error in
 //                        if let err = error {
 //                            print(err)
 //                        } else {
 //                            DispatchQueue.main.async {
 //                                print("Record saved successfully to icloud database")
 //                            }
 //                            self.currentRecord = myRecord
 //                        }
 //                }
 //                privateDatabase?.add(modifyRecordsOperation)
 
 case "Economy":
 
 var myRecord: CKRecord!
 
 if type == "Expense" {
 myRecord = CKRecord(recordType: "Expenses", zoneID: zoneID)
 let expense = object as! Expense
 myRecord.setObject(expense.amount as CKRecordValue?, forKey: "Amount")
 myRecord.setObject(expense.dateAdded as CKRecordValue?, forKey: "createdAt")
 myRecord.setObject(expense.overhead as CKRecordValue?, forKey: "Overhead")
 myRecord.setObject(expense.comment as CKRecordValue?, forKey: "Comment")
 myRecord.setObject(expense.reference as CKRecordValue?, forKey: "Reference")
 if let tmp = expense.project {
 myRecord.setObject(tmp.name as CKRecordValue?, forKey: "BelongsToProject")
 }
 if expense.active {
 myRecord.setObject("Yes" as CKRecordValue?, forKey: "Active")
 } else {
 myRecord.setObject("No" as CKRecordValue?, forKey: "Active")
 }
 
 } else if type == "Project" {
 myRecord = CKRecord(recordType: "Projects", zoneID: zoneID)
 let project = object as! Project
 myRecord.setObject(project.amountReceived as CKRecordValue?, forKey: "AmountReceived")
 myRecord.setObject(project.amountRemaining as CKRecordValue?, forKey: "AmountRemaining")
 myRecord.setObject(project.name as CKRecordValue?, forKey: "Name")
 myRecord.setObject(project.dateCreated as CKRecordValue?, forKey: "createdAt")
 
 }
 
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
 print("Economy record saved successfully to icloud database")
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
 
 
 
 func updateIcloud(file: LocalFile, oldFilename: String?, newFilename: String?) {
 
 var filename = file.filename
 if oldFilename != nil {
 filename = oldFilename!
 }
 
 let predicate = NSPredicate(format: "Filename = %@", filename)
 let query = CKQuery(recordType: "Publications", predicate: predicate)
 
 var found = false
 privateDatabase?.perform(query, inZoneWith: recordZone?.zoneID) { (records, error) in
 guard let records = records else {return}
 DispatchQueue.main.async {
 // FOUND AT LEAST ONE RECORD
 if records.count > 0 {
 for record in records {
 print(record.object(forKey: "Filename") as! String)
 if record.object(forKey: "Filename") as! String == filename {
 
 found = true
 
 if oldFilename != nil {
 record.setObject(newFilename! as CKRecordValue?, forKey: "Filename")
 print("Updating icloud filename for " + oldFilename!)
 }
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
 }
 print(file.filename + " successfully updated to icloud database")
 self.navigationController?.title = ""
 }
 }))
 
 }
 }
 }
 
 if !found {
 // ADD FILE TO ICLOUD
 if let zoneID = self.recordZone?.zoneID {
 let myRecord = CKRecord(recordType: self.categories[self.selectedCategoryNumber], zoneID: zoneID)
 switch self.categories[self.selectedCategoryNumber] {
 case "Publications":
 
 if oldFilename != nil {
 myRecord.setObject(newFilename! as CKRecordValue?, forKey: "Filename")
 } else {
 myRecord.setObject(filename as CKRecordValue?, forKey: "Filename")
 }
 
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
 self.navigationController?.title = ""
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
 
 
 
 
 
 
 
 
 */


