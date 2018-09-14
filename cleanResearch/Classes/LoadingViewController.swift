//
//  LoadingViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-09-09.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import UIKit

class LoadingViewController: UIViewController {

    var appDelegate: AppDelegate!
    var startTimer: Timer!
    var icloudAvailable: Bool!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.startAnimating()
        self.navigationController?.isNavigationBarHidden = true
        
        let app = UIApplication.shared
        appDelegate = app.delegate as! AppDelegate
        icloudAvailable = appDelegate.iCloudAvailable!
        
        if !icloudAvailable! {
            alert(title: "iCloud Drive not available", message: "Log into your iCloud account and add iCloud Drive services")
        } else {
            activityIndicator.stopAnimating()
            performSegue(withIdentifier: "loadMainVC", sender: self)
        }
        

    }
    
    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            exit(0)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
//    @objc func checkIfFileIsDownloaded() {
//        var stillDownloading = false
//    }
    

//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        loadMainVC
//    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

}
