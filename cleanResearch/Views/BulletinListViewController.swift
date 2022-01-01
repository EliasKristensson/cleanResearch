//
//  BulletinListViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2019-05-03.
//  Copyright © 2019 Elias Kristensson. All rights reserved.
//

import UIKit


internal class BulletinListCell: UITableViewCell {

    @IBOutlet weak var bulletinName: UILabel!
    
}

class BulletinListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var selectedBulletin: String? = nil
    var bulletinCD: [BulletinBoard]!
    var listBulletins: [BulletinBoard] = []

    @IBOutlet weak var bulletinListTV: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        listBulletins = bulletinCD.sorted(by: {$0.dateModified! > $1.dateModified!})
        bulletinListTV.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return listBulletins.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bulletinCell", for: indexPath) as! BulletinListCell
        
        cell.backgroundColor = UIColor.white
        cell.layer.borderColor = UIColor.black.cgColor
        cell.layer.borderWidth = 1
        cell.layer.cornerRadius = 8
        cell.clipsToBounds = true
        
        cell.bulletinName.text = listBulletins[indexPath.section].bulletinName
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedBulletin = listBulletins[indexPath.section].bulletinName
        self.dismiss(animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 5
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.post(name: Notification.Name.bulletinList, object: self)
    }
    
}
