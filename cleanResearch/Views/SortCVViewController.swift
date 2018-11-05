//
//  SortCVViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-09-13.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import UIKit

class SortCVViewController: UIViewController {

    var sortValue = 0
    var sortStrings: [String] = [""]
    
    @IBOutlet weak var sortOptions: UISegmentedControl!
    
    @IBAction func sortOptionsTapped(_ sender: Any) {
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
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.post(name: Notification.Name.sortCollectionView, object: self)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
