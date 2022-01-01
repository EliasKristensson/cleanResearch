//
//  ScoreViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2020-07-04.
//  Copyright © 2020 Elias Kristensson. All rights reserved.
//

import Foundation
import UIKit

class ExamsTVCell: UITableViewCell {
    @IBOutlet weak var examName: UILabel!
}

class SetupTVCell: UITableViewCell {
    @IBOutlet weak var examStepper: UIStepper!
    @IBOutlet weak var problemNumber: UILabel!
    @IBOutlet weak var subProblemsNumber: UILabel!
    
    @IBAction func subNumberStepperTapped(_ sender: Any) {
        subProblemsNumber.text = "\(examStepper.value)"
        NotificationCenter.default.post(name: Notification.Name.updateExam, object: self)
    }
    
}

class ScoreViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var initialLoad = true
    var exam: Grading?
    var exams: [Exams?] = []
    var selectedExam: Exams? = nil
    var files: [LocalFile]!
    var hideExport: Bool!
    
    var dataManager: DataManager!
    
    @IBOutlet weak var storedExamsTV: UITableView!
    @IBOutlet weak var examSetupTV: UITableView!
    @IBOutlet weak var selectedExamLabel: UILabel!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var passLimitLabel: UILabel!
    @IBOutlet weak var passLimitSlider: UISlider!
    @IBOutlet weak var exportButton: UIButton!
    @IBOutlet weak var lockExamButton: UISwitch!
    @IBOutlet weak var disableExamView: UIView!
    @IBOutlet weak var lockLabel: UILabel!
    
    
    
    
    @IBAction func tappedOutside(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func exportTapped(_ sender: Any) {
        if let tmp = selectedExam {
            let complete = dataManager.writeExamResults(exam: tmp, files: files)
            
            var message = "Exam " + tmp.course! + " export completed"
            if !complete {
                message = "Exam " + tmp.course! + " not export"
            }
            let exportComplete = UIAlertController(title: "Export complete", message: message, preferredStyle: .alert)
            exportComplete.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                exportComplete.dismiss(animated: true, completion: nil)
            }))
            self.present(exportComplete, animated: true, completion: nil)
            
        }
    }
    
    @IBAction func passLimitSliderChangedValue(_ sender: Any) {
        passLimitLabel.text = "\(round(2*passLimitSlider.value)/2)"
        selectedExam?.passLimit = Double(round(2*passLimitSlider.value)/2)
    }
    
    @IBAction func lockExamTapped(_ sender: Any) {
        selectedExam?.locked = lockExamButton.isOn
        if let currentExam = exams.first(where: {$0!.id == selectedExam!.id}) {
            currentExam!.locked = lockExamButton.isOn
            dataManager.saveCoreData()
            dataManager.loadCoreData()
        }
        if selectedExam!.locked {
            lockLabel.text = "Exam is locked"
            disableExamView.isHidden = false
        } else {
            lockLabel.text = "Exam can be edited"
            disableExamView.isHidden = true
        }

    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        storedExamsTV.delegate = self
        storedExamsTV.dataSource = self
        examSetupTV.dataSource = self
        examSetupTV.delegate = self
                
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleScoreUpdate), name: Notification.Name.sortSubtable, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleExamCreated), name: Notification.Name.createdExam, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleScoreUpdate), name: Notification.Name.updateExam, object: nil)

        contentView.layer.cornerRadius = 8
        contentView.layer.borderColor = UIColor.darkGray.cgColor
        contentView.layer.borderWidth = 1
        contentView.backgroundColor = UIColor(white: 0.25, alpha: 0.5)
        
        exams = dataManager.examsCD
        selectedExamLabel.text = selectedExam?.course ?? "No exam selected"
        
        if selectedExam != nil {
            if selectedExam!.locked {
                lockExamButton.isOn = true
                disableExamView.isHidden = false
                lockLabel.text = "Exam is locked"
            } else {
                lockExamButton.isOn = true
                disableExamView.isHidden = true
                lockLabel.text = "Exam can be modified"
            }
        } else {
            lockExamButton.isOn = false
            disableExamView.isHidden = true
            lockLabel.text = "Exam can be modified"
        }
        
        passLimitSlider.maximumValue = Float(selectedExam?.maxScore ?? 50)
        passLimitSlider.minimumValue = 0
        passLimitSlider.value = Float(selectedExam?.passLimit ?? 25)
        passLimitLabel.text = "\(round(2*passLimitSlider.value)/2)"
        
        exportButton.isHidden = hideExport
    }
    
    
    
    
    @objc func handleScoreUpdate(notification: Notification) {
        initialLoad = false
        examSetupTV.reloadData()
    }
    
    @objc func handleExamCreated(notification: Notification) {
        self.exams = self.dataManager.examsCD
        self.storedExamsTV.reloadData()
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if tableView == self.storedExamsTV {
            return exams.count + 1
        } else {
            if let tmp = selectedExam {
                return Int(tmp.problems)
            } else {
                return 0
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.storedExamsTV {
            let cell = tableView.dequeueReusableCell(withIdentifier: "examCell", for: indexPath) as! ExamsTVCell
            
            if indexPath.row < exams.count {
                cell.examName.text = exams[indexPath.row]?.course
                if exams[indexPath.row]?.course == selectedExam?.course {
                    cell.isSelected = true
                }
            } else {
                cell.examName.text = "+ Add new exam"
            }
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "setupCell", for: indexPath) as! SetupTVCell
            
            cell.problemNumber.text = "\(indexPath.row + 1)"
            
            var subProblems: Int = 1
            
            if selectedExam?.subProblems?[indexPath.row] != nil {
                subProblems = selectedExam!.subProblems![indexPath.row]
            }
            
            if initialLoad {
                cell.examStepper.value = Double(subProblems)
                cell.subProblemsNumber.text = "\(subProblems)"
            } else {
                cell.subProblemsNumber.text = "\(Int(cell.examStepper.value))"
                selectedExam?.subProblems![indexPath.row] = Int(cell.examStepper.value)
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == self.storedExamsTV {

            if indexPath.row == exams.count {
                dataManager.createExam(viewController: self)
            } else {
                selectedExam = exams[indexPath.row]!
                selectedExamLabel.text = selectedExam?.course
                lockExamButton.isOn = selectedExam?.locked ?? false
                
                if selectedExam!.locked {
                    lockLabel.text = "Exam is locked"
                    disableExamView.isHidden = false
                } else {
                    lockLabel.text = "Exam can be edited"
                    disableExamView.isHidden = true
                }
                passLimitSlider.maximumValue = Float(selectedExam?.maxScore ?? 50)
                passLimitSlider.minimumValue = 0
                passLimitSlider.value = Float(selectedExam?.passLimit ?? 25)
                passLimitLabel.text = "\(round(2*passLimitSlider.value)/2)"
                disableExamView.isHidden = !selectedExam!.locked
                
                self.examSetupTV.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if tableView == self.storedExamsTV {
            if indexPath.row < self.exams.count {
                return !exams[indexPath.row]!.locked
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if tableView == self.storedExamsTV {
            if !exams[indexPath.row]!.locked {
                if (editingStyle == .delete) {
                    print(exams[indexPath.row]!)
                    dataManager.context.delete(exams[indexPath.row]!)
                    dataManager.loadCoreData()
                    self.storedExamsTV.reloadData()
                    self.examSetupTV.reloadData()
                }
            }
        }
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let editAction = UIContextualAction(style: .normal, title: "Edit") { (action, view, nil) in
            let selectedExam = self.exams[indexPath.row]
            self.dataManager.editExam(exam: selectedExam!, viewController: self)
        }
        
        editAction.backgroundColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
        
        let configuration = UISwipeActionsConfiguration(actions: [editAction])
        return configuration
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.post(name: Notification.Name.settingsScore, object: self)
    }
    
}
