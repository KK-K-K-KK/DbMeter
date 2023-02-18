//
//  ViewController.swift
//  DbMeter
//
//  Created by Kevin Kuan on 2023/2/17.
//

import UIKit
import AVFoundation


class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setUpAudioCapture()
    }

    private func setUpAudioCapture() {
        let recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord)
            try recordingSession.setActive(true)
            
            recordingSession.requestRecordPermission({
                result in
                guard result else {
                    return
                    // Should alert user, and show instructions to allow microphone access
                }
            })
            
            captureAudio()
        } catch {
            print("ERROR: Failed to set up recording session. Have you enabled the recording permission?")
        }
    }
    
    private func captureAudio() {
        let audioFileUrl = Bundle.main.resourceURL!.appendingPathComponent("recording.m4a")
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            let audioRecorder = try AVAudioRecorder(url: audioFileUrl , settings: settings)
            audioRecorder.record()
            audioRecorder.isMeteringEnabled = true
            
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {
                timer in
                audioRecorder.updateMeters()
                let db = audioRecorder.averagePower(forChannel: 0)
                print(db)
            }
        } catch {
            print("ERROR: Failed to start recording process.")
        }
    }
}

