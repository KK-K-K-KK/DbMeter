//
//  ViewController.swift
//  DbMeter
//
//  Created by Kevin Kuan on 2023/2/17.
//

import UIKit
import AVFoundation


class ViewController: UIViewController {

    @IBOutlet weak var soundLevelLabel: UILabel!
    @IBOutlet weak var maxLevelLabel: UILabel!

    @IBOutlet weak var playStopButton: UIButton!
    
    
    var recordTimer : Timer? = nil
    var terminateTimer: Timer? = nil
    var maxdb: Float = 0.0
    var recording: Bool = false
    var permissionGranted: Bool = false
    
    var audioFileUrl: URL {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let filePath = "recording.caf"
        return tempDir.appendingPathComponent(filePath)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        maxLevelLabel.isHidden = true
    }

    private func setUpAudioCapture() {
        let recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, options: .defaultToSpeaker)
            try recordingSession.setActive(true)
            
            recordingSession.requestRecordPermission({
                result in
                self.permissionGranted = result
                if !result {
                    let alert = UIAlertController(title: "錯誤", message: "麥克風權限未開啟，請參考 🅘說明 ", preferredStyle: .alert)
                    let alertAction = UIAlertAction(title: "好的", style: .default)
                    alert.addAction(alertAction)
                    self.present(alert, animated: true)
                }
            })
            
        } catch {
            print("ERROR: Failed to set up recording session. Have you enabled the recording permission?")
        }
    }
    
    @IBAction func pressPlayStopButton(_ sender: Any) {
        if recording {
            stopAudio()
        } else {
            setUpAudioCapture()
            captureAudio()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        stopAudio()
    }
    
    private func captureAudio() {
        let settings : [String : Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            let audioRecorder = try AVAudioRecorder(url: audioFileUrl , settings: settings)
            audioRecorder.record()
            audioRecorder.isMeteringEnabled = true
            
            recordTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) {
                timer in
                audioRecorder.updateMeters()
                let linear_db = audioRecorder.averagePower(forChannel: 0)
                let calibrated_db = linear_db + 80.0
                self.maxdb = max(calibrated_db, self.maxdb)
                if self.maxdb < 60.0 {
                    self.soundLevelLabel.textColor  = UIColor.systemGreen
                    self.maxLevelLabel.isHidden = true
                } else if self.maxdb < 79.0 {
                    self.soundLevelLabel.textColor = UIColor.systemYellow
                    self.maxLevelLabel.isHidden = true
                } else {
                    self.soundLevelLabel.textColor = UIColor.systemRed
                    self.maxLevelLabel.isHidden = false
                }
                self.soundLevelLabel.text = "\(String(self.maxdb.rounded())) dB"
            }
            playStopButton.setImage(UIImage(named: "Stop"), for: .normal)
            recording = true
            
            /* Add 20s timeout to recording to limit disk & power usage */
            terminateTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) {
                timer in
                self.stopAudio()
            }
        } catch {
            print("ERROR: Failed to start recording process.")
        }
    }
    
    private func stopAudio() {
        recordTimer?.invalidate()
        recordTimer = nil
        terminateTimer?.invalidate()
        terminateTimer = nil
        
        playStopButton.setImage(UIImage(named: "Play"), for: .normal)
        recording = false
        maxdb = 0.0
    }
}

