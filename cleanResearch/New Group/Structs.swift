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
}
