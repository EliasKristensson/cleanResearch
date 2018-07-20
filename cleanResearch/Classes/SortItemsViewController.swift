//
//  SortItemsViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-04-09.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import UIKit

class SortItemsViewController: UIViewController {

    var sortValue = 0
    var sortStrings: [String] = [""]

    @IBOutlet weak var sortOptions: UISegmentedControl!
    
    @IBAction func sortOptionsClicked(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name.sortCollectionView, object: self)
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sortOptions.replaceSegments(segments: sortStrings)
        sortOptions.selectedSegmentIndex = sortValue

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
