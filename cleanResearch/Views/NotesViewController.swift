//
//  NotesViewController.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-10-04.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import UIKit
import Speech

class NotesViewController: UIViewController, SFSpeechRecognitionTaskDelegate {

    var originalShortName: String!
    var originalFilename: String!
    var update = false
    var localFile: LocalFile!
    var index: Int?
    var filenameChanged = false
    var dataManager: DataManager!
    var annotationSettings: [Int]!
    
    var audioRecording = false
    let audioEngine: AVAudioEngine? = AVAudioEngine()
//    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    var request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    var recogniseTimer: Timer!
    var delayTimer: Timer!
    
    var editAuthor = false
    var editYear = false
    var editNote = false
    var editRank = false
    var editJournal = false
    var edit = false
    
    @IBOutlet weak var filenameString: UITextField!
    @IBOutlet weak var journalString: UITextField!
    @IBOutlet weak var notesString: UITextField!
    @IBOutlet weak var authorString: UITextField!
    @IBOutlet weak var yearString: UITextField!
    @IBOutlet weak var rankValue: UILabel!
    @IBOutlet weak var rankOutlet: UISlider!
    @IBOutlet weak var audioButton: UIButton!
    @IBOutlet weak var label: UILabel!
    
    
    @IBAction func detectAudio(_ sender: Any) {
        print("detectAudio")
        
        if !audioRecording {
            label.text = "Auto-detect notes on"
            audioButton.setImage(UIImage(named: "microphone2-filled.png"), for: .normal)
            audioRecording = true
            annotationSettings[22] = 1
            recordAndRecognizeSpeech()
        } else {
            label.text = "Auto-detect notes off"
            audioButton.setImage(UIImage(named: "microphone2.png"), for: .normal)
            audioRecording = false
            annotationSettings[22] = 0
            stopAudio()
        }
    }
    
    @IBAction func rankSlider(_ sender: Any) {
        if localFile != nil {
            rankValue.text = "\(Int(rankOutlet.value))"
            localFile!.rank = rankOutlet.value
            update = true
        } else {
            dismiss(animated: true)
        }
    }
    
    @IBAction func filenameEditingStarting(_ sender: Any) {
        if localFile != nil {
            originalShortName = filenameString.text!
            originalFilename = filenameString.text! + ".pdf"
        } else {
            dismiss(animated: true)
        }
    }
    
    @IBAction func filenameEditing(_ sender: Any) {
        if localFile != nil {
            filenameChanged = true
            update = true
        } else {
            dismiss(animated: true)
        }
    }

    @IBAction func journalStringEditing(_ sender: Any) {
        if localFile != nil {
            if (journalString.text?.isEmpty)! {
                localFile!.journal = "No journal"
            } else {
                localFile!.journal = journalString.text
            }
            
            update = true
        } else {
            dismiss(animated: true)
        }
    }
    
    @IBAction func authorStringEditing(_ sender: Any) {
        if localFile != nil {
        if (authorString.text?.isEmpty)! {
            localFile!.author = "No author"
        } else {
            localFile!.author = authorString.text
        }
        
        update = true
        } else {
            dismiss(animated: true)
        }
        
    }
    
    @IBAction func yearStringEditing(_ sender: Any) {
        if localFile != nil {
            if (yearString.text?.isEmpty)! {
                localFile!.year = -2000
            } else {
                let year = Int16(isStringAnInt(stringNumber: yearString.text!))
                localFile!.year = year
            }
            
            update = true
        } else {
            dismiss(animated: true)
        }
    }
    
    @IBAction func rankSliderEditingEndedOutside(_ sender: Any) {
        if localFile != nil {
            localFile!.rank = rankOutlet.value
            update = true
        } else {
            dismiss(animated: true)
        }
    }
    
    @IBAction func notesStringEditing(_ sender: Any) {
        if localFile != nil {
            if (notesString.text?.isEmpty)! {
                localFile!.note = "No note"
            } else {
                localFile!.note = notesString.text
            }
            update = true
        } else {
            dismiss(animated: true)
        }
    }
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if localFile != nil {
            var components = localFile!.filename.components(separatedBy: ".")
            if components.count > 1 {
                components.removeLast()
            }
            
            originalFilename = localFile!.filename
            originalShortName = components.first!
            filenameString.text = components.first!
            journalString.text = localFile!.journal!
            yearString.text = "\(localFile!.year!)"
            authorString.text = localFile!.author!
            rankValue.text = "\(Int(localFile!.rank!))"
            rankOutlet.value = localFile!.rank!
            notesString.text = localFile!.note!
            
        }
        
        if annotationSettings[22] == 1 {
            label.text = "Auto-detect notes on"
            audioButton.setImage(UIImage(named: "microphone2-filled.png"), for: .normal)
            audioRecording = true
            recordAndRecognizeSpeech()
        } else {
            label.text = "Auto-detect notes off"
            audioButton.setImage(UIImage(named: "microphone2.png"), for: .normal)
            audioRecording = false
        }
        
    }

    
    
    
    
    @objc func delay() {
        edit = true
    }
    
    @objc func timeOut() {
        print("timeOut")
        editYear = false
        editAuthor = false
        editNote = false
        editRank = false
        editJournal = false
        edit = false
        yearString.backgroundColor = UIColor.white
        authorString.backgroundColor = UIColor.white
        rankValue.backgroundColor = UIColor.clear
        notesString.backgroundColor = UIColor.white
        journalString.backgroundColor = UIColor.white
        recogniseTimer.invalidate()
    }
    
    func recordAndRecognizeSpeech() {
        print("recordAndRecognizeSpeech")
        
        request = SFSpeechAudioBufferRecognitionRequest()
        
        guard let node = audioEngine?.inputNode else {return}
        
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) {buffer, _ in self.request.append(buffer)}
        audioEngine?.prepare()
        do {
            try audioEngine?.start()
        } catch {
            return print(error)
        }
        guard let myRecognizer = SFSpeechRecognizer() else {
            return
        }
        if !myRecognizer.isAvailable {
            return
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: {result, error in
            if let result = result {
                
                let bestString = result.bestTranscription.formattedString
                var lastString: String = ""
                
                print("Start")
                
                for segment in result.bestTranscription.segments {
                    let indexTo = bestString.index(bestString.startIndex, offsetBy: segment.substringRange.location)
                    lastString = bestString.substring(from: indexTo)
                }
                
                if !self.edit {
                    self.checkForKeyword(key: lastString, index: 0)
                } else {
                    self.editTextfield(text: lastString, sentence: bestString)
                }
                
                print("-----")
            } else if let error = error {
                print(error)
            }
            
        })
        
    }
    
    func checkForKeyword(key: String, index: Int) {
        print("checkForKeyword")
        print(key)
        
        switch key {
        case "Author", "author":
            authorString.backgroundColor = UIColor.red
            editAuthor = true
            edit = true
            recogniseTimer = Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(timeOut), userInfo: nil, repeats: false)
        case "Year", "year":
            yearString.backgroundColor = UIColor.red
            editYear = true
            edit = true
            recogniseTimer = Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(timeOut), userInfo: nil, repeats: false)
        case "Rank", "rank":
            rankValue.backgroundColor = UIColor.red
            editRank = true
            edit = true
            recogniseTimer = Timer.scheduledTimer(timeInterval: 4, target: self, selector: #selector(timeOut), userInfo: nil, repeats: false)
        case "Journal", "journal":
            journalString.backgroundColor = UIColor.red
            journalString.text = ""
            editJournal = true
            edit = true
            recogniseTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(timeOut), userInfo: nil, repeats: false)
            stopAudio()
            recordAndRecognizeSpeech()
        case "Notes", "Note", "note", "notes":
            notesString.backgroundColor = UIColor.red
            editNote = true
            edit = true
            recogniseTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(timeOut), userInfo: nil, repeats: false)
            stopAudio()
            recordAndRecognizeSpeech()
        default:
            print("Default 201")
        }
    }
    
    func editTextfield(text: String, sentence: String) {
        print("editTextfield")
        
        if editAuthor {
            authorString.text = text
            authorString.backgroundColor = UIColor.white
            localFile.author = authorString.text
            update = true
        }
        if editYear {
            if isStringAYear(stringNumber: text) {
                yearString.text = text
                yearString.backgroundColor = UIColor.white
                localFile.year = Int16(isStringAnInt(stringNumber: text))
                update = true
            }
        }
        if editJournal {
            print(sentence)
            journalString.text = sentence
            localFile.journal = journalString.text
            update = true
        }
        if editNote {
            notesString.text = sentence
            localFile.note = notesString.text
            update = true
        }
        if editRank {
            if isStringAFloat(stringNumber: text) {
                if let value = Float(text) {
                    rankOutlet.value = value
                    rankValue.text = "\(Int(value))"
                    rankValue.backgroundColor = UIColor.clear
                    localFile.rank = rankOutlet.value
                    update = true
                }
            }
        }
    }
    
    func checkIfFilenameIsOk() {
        
        if filenameChanged {
            
            let newFilename = filenameString.text! + ".pdf"
            
            if newFilename != originalFilename {
                var found = false
                
                print(newFilename)
                
                //Search for duplicates
                if dataManager.localFiles[0].index(where: { $0.filename == newFilename }) != nil {
                    found = true
                }

                if found {
                    if filenameString.text != originalShortName {
                        alert(title: newFilename + " already exists", message: "Keeping old filename")
                        filenameString.text = originalShortName
                        filenameChanged = false
                    }
                } else {
                    print("New filename ok")
                    
                    let newiURL = dataManager.publicationsURL.appendingPathComponent(newFilename, isDirectory: false)
                    let newlURL = dataManager.docsURL.appendingPathComponent("Publications").appendingPathComponent(newFilename, isDirectory: false)
                    localFile!.filename = newFilename
                    localFile!.iCloudURL = newiURL
                    localFile!.localURL = newlURL
                    print(localFile)
                    
                    //updateIcloud(file: localFiles[0][index!], oldFilename: originalFilename, newFilename: filenameString.text!+".pdf")
                    //updateCoreData(file: localFiles[0][index!], oldFilename: originalFilename, newFilename: filenameString.text!+".pdf")
                    
                    let originiPath = dataManager.publicationsURL.appendingPathComponent(originalFilename)
                    print(originiPath)
                    print(newiURL)
                    do {
                        try FileManager.default.moveItem(at: originiPath, to: newiURL)
                        print("File moved on iCloud")
                    } catch {
                        print("Error moving on iCloud")
                        print(error)
                    }
                    
                    if localFile!.downloaded {
                        let originlURL = dataManager.docsURL.appendingPathComponent("Publications").appendingPathComponent(originalFilename)
                        print(originlURL)
                        print(newlURL)
                        do {
                            try FileManager.default.moveItem(at: originlURL, to: newlURL)
                        } catch {
                            print("Error moving locally")
                            print(error)
                        }
                    }
                }
            }
        }

        
    }
    
    func checkFields() {
        if (journalString.text?.isEmpty)! {
            localFile.journal = "No journal"
        } else {
            localFile.journal = journalString.text
        }
        if (authorString.text?.isEmpty)! {
            localFile.author = "No author"
        } else {
            localFile.author = authorString.text
        }
        if (yearString.text?.isEmpty)! {
            localFile.year = -2000
        } else {
            let year = Int16(isStringAnInt(stringNumber: yearString.text!))
            localFile.year = year
        }
        localFile!.rank = rankOutlet.value
        if (notesString.text?.isEmpty)! {
            localFile.note = "No note"
        } else {
            localFile.note = notesString.text
        }
    }
    
    func stopAudio() {
        guard let node = audioEngine?.inputNode else {return}
        self.audioEngine!.stop()
        node.removeTap(onBus: 0)
        
        request.endAudio()
        recognitionTask?.finish()
    }
    
    func alert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func isStringAnInt(stringNumber: String?) -> Int32 {
        let number = stringNumber?.replacingOccurrences(of: "\"", with: "")
        if let tmpValue = Int32(number!) {
            return tmpValue
        }
        print("String number could not be converted")
        return -2000
    }
    
    func isStringAYear(stringNumber: String?) -> Bool {
        let number = stringNumber?.replacingOccurrences(of: "\"", with: "")
        if Int32(number!) != nil {
            return true
        }
        print("String number could not be converted")
        return false
    }
    
    func isStringAFloat(stringNumber: String?) -> Bool {
        let number = stringNumber?.replacingOccurrences(of: "\"", with: "")
        if Float(number!) != nil {
            return true
        } else {
            return false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if localFile != nil {
            checkIfFilenameIsOk()
            if update {
                localFile!.dateModified = Date()
            }
            NotificationCenter.default.post(name: Notification.Name.closingNotes, object: self)
        }
        if audioRecording {
            stopAudio()
        }
    }
    
    func speechRecognitionTaskFinishedReadingAudio(_ task: SFSpeechRecognitionTask) {
        print("speech finished reading")
        label.text = "Auto-detect notes off"
    }
    
    func speechRecognitionTaskWasCancelled(_ task: SFSpeechRecognitionTask) {
        print("speech was cancelled")
        label.text = "Auto-detect notes off"
    }
    
    
}
