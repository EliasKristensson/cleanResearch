//
//  InvoiceViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-08-31.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import UIKit
import PDFKit

class InvoiceCell: UICollectionViewCell {
    @IBOutlet weak var invoiceImage: UIImageView!
    @IBOutlet weak var invoiceFilename: UILabel!
}

struct Invoice {
    var url: URL!
    var filename: String!
    var thumbnail: UIImage!
}

class InvoiceViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var selectedInvoice: String = ""
    var invoiceURL: URL!
    var invoiceFiles: [Invoice] = []

    @IBOutlet weak var invoiceCV: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        invoiceCV.delegate = self
        invoiceCV.dataSource = self
        
        readInvoiceFolder()
    }

    func readInvoiceFolder() {
        invoiceFiles = []
        let fileManager = FileManager.default
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: invoiceURL, includingPropertiesForKeys: nil)
            for file in fileURLs {
                print(file)
                var thumbnail = UIImage()
                var filename = String()
                var available = true
                if file.lastPathComponent.range(of:".icloud") != nil {
                    thumbnail = #imageLiteral(resourceName: "FileOffline")
                    available = false
                    filename = file.deletingPathExtension().lastPathComponent
                    filename.remove(at: filename.startIndex)
                } else {
                    thumbnail = getThumbnail(url: file, pageNumber: 0)
                    filename = file.lastPathComponent
                }
                let newInvoice = Invoice(url: file, filename: filename, thumbnail: thumbnail)
                invoiceFiles.append(newInvoice)
            }
            
        } catch {
            print("Error while reading invoice folder")
        }
        
        invoiceFiles = invoiceFiles.sorted(by: {$0.filename! < $1.filename!})
        invoiceCV.reloadData()
        
    }
    
    func getThumbnail(url: URL, pageNumber: Int) -> UIImage {
        var pageThumbnail = #imageLiteral(resourceName: "fileIcon.png")
        if let document = PDFDocument(url: url) {
            let page: PDFPage!
            page = document.page(at: pageNumber)!
            pageThumbnail = page.thumbnail(of: CGSize(width: 210, height: 297), for: .artBox)
        }
        return pageThumbnail
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.post(name: Notification.Name.closingInvoiceVC, object: self)
    }
    

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return invoiceFiles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "invoiceCell", for: indexPath) as! InvoiceCell
        
        cell.invoiceImage.image = invoiceFiles[indexPath.row].thumbnail
        cell.invoiceFilename.text = invoiceFiles[indexPath.row].filename
        cell.invoiceFilename.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedInvoice = invoiceFiles[indexPath.row].filename
        dismiss(animated: true, completion: nil)
    }

}
