//
//  Structs.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-09-05.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import UIKit
import Foundation
import CoreData

struct thumbnails {
    var image: UIImage
    var filename: String
    var iCloudURL: URL
    var localURL: URL
}

struct DocCV {
    var listTitle: String
    var sectionHeader: [String]
    var files: [[LocalFile]]
}

struct LocalFile {
    var label: String
    var thumbnail: UIImage
    var favorite: String
    var filename: String
    var journal: String?
    var year: Int16?
    var category: String
    var rank: Float?
    var note: String?
    var dateCreated: Date?
    var dateModified: Date?
    var author: String?
    var groups: [String?]
    var parentFolder: String?
    var grandpaFolder: String?
    var available: Bool
    var filetype: String?
    var iCloudURL: URL
    var localURL: URL
    var path: String
    var downloading: Bool
    var downloaded: Bool
    var uploaded: Date?
    var size: String
    var saving: Bool
    var views: Int64
}

struct PublicationFile {
    var filename: String
    var title: String?
    var year: Int16?
    var thumbnails: [UIImage]?
    var category: String
    var rank: Float?
    var note: String?
    var dateCreated: Date?
    var dateModified: Date?
    var favorite: String?
    var author: String?
    var journal: String?
    var groups: [String?]
}

struct FastFolderContent {
    var files: [[LocalFile]]
    var folder: String
    var subfolders: [String]
    var mainURL: URL
    var folderLevel: Int
}

struct ProjectFile {
    var name: String
    var amountReceived: Int32
    var amountRemaining: Int32
    var expenses: [ExpenseFile]
}

struct ExpenseFile {
    var amount: Int32
    var reference: String?
    var overhead: Int16?
    var comment: String?
    var pdfURL: URL?
    var localFile: LocalFile?
    var belongsToProject: String
    var idNumber: Int64
}

struct DownloadingFile {
    var filename: String
    var url: URL
    var downloaded: Bool
    var path: String
    var category: Int
}

struct FolderStructure {
    var categories = [String]()
    var mainFolders = [[String]]()
    var subFolders = [[[String]]]()
    var mainURL = [[URL]]()
    var subURL = [[[URL]]]()
}

struct SelectedFolder {
    var category: String!
    var categoryNumber: Int!
    var mainFolderNumber: Int?
    var mainFolderName: String!
    var subFolderNumber: Int?
    var subFolderName: String?
    var filename: String?
    var folderLevel: Int!
    var tableNumber: Int!
}

struct ListTable {
    var main = [String]()
    var sub = [String]()
}

struct SelectedFile {
    var category: String?
    var filename: String?
    var indexPathCV: [IndexPath?]
}

struct BookmarkFile {
    var filename: String
    var path: String
    var category: String
    var lastPageVisited: Int32?
    var page: [Int]?
    var label: [String]?
}

struct SearchResult {
    var files: [LocalFile]
    var title: String
}

enum categories {
    case recently
    case search
    case publications
    case books
    case economy
    case manuscripts
    case presentations
    case proposals
    case supervision
    case teaching
    case patents
    case courses
    case meetings
    case conferences
    case reviews
    case workDocuments
    case travel
    case notes
    case miscellaneous
    case readingList
    case memos
    case settings
    case bulletinBoard
}

struct SelectedScore {
    var main: Int
    var sub: Int
    var value: Double
}

struct Grading {
    var exam: Exams?
    var score: Student?
}
