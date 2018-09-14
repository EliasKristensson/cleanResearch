//
//  SortSubtableViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-04-09.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import UIKit

class SortSubtableViewController: UIViewController {

    var sortValue = 0
    var sortStrings: [String] = [""]
    
    @IBOutlet weak var sortOptions: UISegmentedControl!
    
    @IBAction func sortOptionsClicked(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name.sortSubtable, object: self)
        dismiss(animated: true, completion: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sortOptions.replaceSegments(segments: sortStrings)
        sortOptions.selectedSegmentIndex = sortValue
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.post(name: Notification.Name.sortSubtable, object: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
