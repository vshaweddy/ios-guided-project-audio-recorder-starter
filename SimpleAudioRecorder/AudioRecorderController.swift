//
//  ViewController.swift
//  AudioRecorder
//
//  Created by Paul Solt on 10/1/19.
//  Copyright © 2019 Lambda, Inc. All rights reserved.
//

import UIKit
import AVFoundation

class AudioRecorderController: UIViewController {
    
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var audioVisualizer: AudioVisualizer!
    
    var audioPlayer: AVAudioPlayer? {
        didSet {
            guard let audioPlayer = audioPlayer else { return }
            
            audioPlayer.delegate = self
            audioPlayer.isMeteringEnabled = true
            self.updateViews()
        }
    }
    
    weak var timer: Timer?
    
    var audioRecorder: AVAudioRecorder?
    var recordingURL: URL?
	
	private lazy var timeFormatter: DateComponentsFormatter = {
		let formatting = DateComponentsFormatter()
		formatting.unitsStyle = .positional // 00:00  mm:ss
		// NOTE: DateComponentFormatter is good for minutes/hours/seconds
		// DateComponentsFormatter not good for milliseconds, use DateFormatter instead)
		formatting.zeroFormattingBehavior = .pad
		formatting.allowedUnits = [.minute, .second]
		return formatting
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()

        timeLabel.font = UIFont.monospacedDigitSystemFont(ofSize: timeLabel.font.pointSize,
                                                          weight: .regular)
        timeRemainingLabel.font = UIFont.monospacedDigitSystemFont(ofSize: timeRemainingLabel.font.pointSize,
                                                                   weight: .regular)
        self.loadAudio()
        self.updateViews()
	}
    
    func loadAudio() {
        let songURL = Bundle.main.url(forResource: "piano", withExtension: "mp3")!
        
        audioPlayer = try? AVAudioPlayer(contentsOf: songURL)
    }
    
    func updateViews() {
        playButton.isSelected = isPlaying
        recordButton.isSelected = isRecording
        
        // enabled and disabled the other button
        playButton.isEnabled = !isRecording
        recordButton.isEnabled = !isPlaying
        
        let elapsedTime = audioPlayer?.currentTime ?? 0
        let duration = audioPlayer?.duration ?? 0
        let timeRemaining = duration - elapsedTime
        
        self.timeLabel.text = timeFormatter.string(from: elapsedTime)
        
        timeSlider.minimumValue = 0
        timeSlider.maximumValue = Float(audioPlayer?.duration ?? 0)
        timeSlider.value = Float(elapsedTime)
        
        self.timeRemainingLabel.text = "–" + timeFormatter.string(from: timeRemaining)!
    }
    
    // MARK: - Timer
    
    func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func startTimer() {

        self.timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true
            , block: { [weak self] (_) in
                guard let self = self else { return }
                
                self.updateViews()
//                self.audioVisualizer.addValue(decibleValue: self.audioPlayer!.averagePower(forChannel: 0))
        })
    }
    
    // MARK: - Playback
    
    var isPlaying: Bool {
        audioPlayer?.isPlaying ?? false
    }
    
    func play() {
        audioPlayer?.play()
        self.updateViews()
        startTimer()
    }
    
    func pause() {
        audioPlayer?.pause()
        self.updateViews()
        cancelTimer()
    }
    
    // MARK: - Recording
    
    var isRecording: Bool {
        audioRecorder?.isRecording ?? false
    }
    
    func startRecording() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let name = ISO8601DateFormatter.string(from: Date(), timeZone: .current, formatOptions: .withInternetDateTime)
        
        // always have isDirectory so it will be faster
        let file = documents.appendingPathComponent(name, isDirectory: false).appendingPathExtension("caf")
        
        recordingURL = file
        // for checking in the Finder
//        print("Recording URL: \(recordingURL!)")
        
        // standard frequency is 44100
        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        
        self.audioRecorder = try? AVAudioRecorder(url: file, format: format)
        self.audioRecorder?.delegate = self
        self.audioRecorder?.record()
        self.updateViews()
    }
    
    func stopRecording() {
        self.audioRecorder?.stop()
        self.audioRecorder = nil
        self.updateViews()
    }
    
    // MARK: - Actions

    @IBAction func togglePlayback(_ sender: Any) {
        if isPlaying {
            pause()
        } else {
            play()
        }
	}
    
    @IBAction func toggleRecording(_ sender: Any) {
        if isRecording{
            stopRecording()
        } else {
            startRecording()
        }

    }
}

extension AudioRecorderController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        updateViews()
        cancelTimer()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print("Audio Player Error: \(error)")
        }
    }
}

extension AudioRecorderController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if let recordingURL = recordingURL {
            audioPlayer = try? AVAudioPlayer(contentsOf: recordingURL)
            
            // once it's saved, reset it
            self.recordingURL = nil
            self.updateViews()
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("Audio Recorder Error: \(error)")
        }
    }
}

