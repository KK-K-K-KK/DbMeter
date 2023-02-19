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
    var maxdb: Float = 0.0
    var recording: Bool = false
    
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
        setUpAudioCapture()
    }

    private func setUpAudioCapture() {
        let recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, options: .defaultToSpeaker)
            try recordingSession.setActive(true)
            
            recordingSession.requestRecordPermission({
                result in
                guard result else {
                    return
                    // Should alert user, and show instructions to allow microphone access
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
//            playStopButton.imageView!.image = UIImage(named: "Stop")
//            playStopButton.updateConfiguration()
            recording = true
        } catch {
            print("ERROR: Failed to start recording process.")
        }
    }
    
    private func stopAudio() {
        recordTimer?.invalidate()
        recordTimer = nil
        
        playStopButton.setImage(UIImage(named: "Play"), for: .normal)
        recording = false
        maxdb = 0.0
    }
}

