//
//  BookmarksGridPDFViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2019-02-11.
//  Copyright © 2019 Elias Kristensson. All rights reserved.
//

import UIKit
import Foundation

class BookmarkCellPDF: UICollectionViewCell {
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var bookmarkLabel: UILabel!
    
}

class BookmarksGridPDFViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    var currentFile: LocalFile!
    var fileHandler: FileHandler!
    var dataManager: DataManager!
    var bookmark: Bookmarks!
    var selectedBookmark: Int?
    
    var list: [(label: String, page: Int, thumbnail: UIImage)] = []
    
    @IBOutlet weak var bookmarkCV: UICollectionView!
    
    @IBAction func clickedOutside(_ sender: Any) {
        dismiss(animated: true)
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("BookmarkListViewController loaded")
        
        self.bookmarkCV.delegate = self
        self.bookmarkCV.dataSource = self
//        self.bookmarkCV.backgroundColor = UIColor.clear
        self.bookmarkCV.layer.borderColor = UIColor.black.cgColor
        self.bookmarkCV.layer.borderWidth = 1
        self.bookmarkCV.layer.cornerRadius = 8
//        self.outsideButton.backgroundColor = UIColor.clear
        
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.itemSize = CGSize(width: 185, height: 290)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        bookmarkCV.collectionViewLayout = layout
        
//        self.view.backgroundColor = UIColor.clear
//        self.view.alpha = 1
        
        if let currentBookmark = dataManager.getBookmark(file: currentFile) {
            bookmark = currentBookmark
            let pages = bookmark.page!.count
            
            for i in 0..<pages {
                let image = fileHandler.getThumbnail(icloudURL: currentFile.iCloudURL, localURL: currentFile.localURL, localExist: false, pageNumber: bookmark.page![i]-1)
                
                if i == 0 {
                    list = [((bookmark.label![0]), (bookmark.page![0]), image)]
                } else {
                    list.append( (label: bookmark.label![i], page:bookmark.page![i], image) )
                }
            }
            list = list.sorted(by: {$0.page < $1.page})
        } else {
            print("No bookmark")
        }
        
    }
    
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if bookmark != nil {
            return (bookmark?.page?.count)!
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = bookmarkCV.dequeueReusableCell(withReuseIdentifier: "bookmarkCellPDF", for: indexPath) as! BookmarkCellPDF
        
        cell.thumbnail.image = list[indexPath.row].thumbnail
        
        if list[indexPath.row].label != "" || list[indexPath.row].label != nil {
            cell.bookmarkLabel.text = list[indexPath.row].label
        } else {
            cell.bookmarkLabel.text = "No label"
        }
        
        
        //        cell.pageNumber.text = "Page: " + "\(list[indexPath.row].page)"
        
        cell.backgroundColor = UIColor.white
        cell.layer.borderColor = UIColor.black.cgColor
        cell.layer.borderWidth = 1
        cell.layer.cornerRadius = 8
        cell.clipsToBounds = true
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedBookmark = list[indexPath.row].page
        dismiss(animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.post(name: Notification.Name.openPDFAtBookmarkPDFView, object: self)
    }
    
}
