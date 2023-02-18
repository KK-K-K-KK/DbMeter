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
    
    var recordTimer : Timer? = nil
    
    var audioFileUrl: URL {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let filePath = "recording.caf"
        return tempDir.appendingPathComponent(filePath)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
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
    
    override func viewDidAppear(_ animated: Bool) {
        captureAudio()
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
//                print(linear_db)
//                let db = log10(linear_db) * 20
//                let db = audioRecorder.peakPower(forChannel: 1)
                self.soundLevelLabel.text = "\(String(linear_db.rounded())) dB"
            }
        } catch {
            print("ERROR: Failed to start recording process.")
        }
    }
    
    private func stopAudio() {
        recordTimer?.invalidate()
        recordTimer = nil
    }
}

