//
//  SystemInfoViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-11-05.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import UIKit

class SystemInfoViewController: UIViewController {

    var exitTimer: Timer!
    
    @IBOutlet weak var label: UILabel!
    
    @objc func exitView() {
        print("Dismiss")
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("View did appear")
        
        exitTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(exitView), userInfo: nil, repeats: false)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        exitTimer.invalidate()
    }

}
