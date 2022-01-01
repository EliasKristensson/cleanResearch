//
//  Navigator.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2020-05-09.
//  Copyright © 2020 Elias Kristensson. All rights reserved.
//

import Foundation



class Navigator {
    
    var categories = [String]()
    var selectedCategory = String()
    var folders = [[[String]]]() // [Category] - [Main folders] - [Sub folders]
    var selected: SelectedFolder!
    var selectedMainFolder = String()
    var list: ListTable!
//    var listTable = [String]()
//    var subListTable = [String]()
    var fastFolder: IndexPath?
    var folderStructure = FolderStructure()
    var path = String()
    var pathURL: URL?
    var note: String?
    var longpress: LocalFile?

    init (categoryList: [String]) {
        categories = categoryList
        list = ListTable(main: [], sub: [])
        selected = SelectedFolder(category: nil, categoryNumber: 0, mainFolderNumber: 0, mainFolderName: "", subFolderNumber: 0, subFolderName: nil, filename: nil, folderLevel: 0, tableNumber: 0)
        folderStructure.categories = categoryList
        folderStructure.mainFolders = []
        folderStructure.subFolders = [[[]]]
        folderStructure.mainURL = []
        folderStructure.subURL = [[[]]]
        for _ in 0..<categoryList.count {
            folderStructure.mainFolders.append([])
            folderStructure.mainURL.append([])
        }
    }
    
    func printStructure() {
        print("printStructure()")
        
        for i in 0..<folderStructure.categories.count {
            print("-------" + folderStructure.categories[i] + "--------------")
            for j in 0..<folderStructure.mainFolders[i].count {
                print("---" + folderStructure.mainFolders[i][j] + "---")
                for k in 0..<folderStructure.subFolders[i][j].count {
                    print(">" + folderStructure.subFolders[i][j][k])
                }
            }
        }
    }
    
}
