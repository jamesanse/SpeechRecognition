//
//  JATranslationPlayerView.swift
//  Recognize
//
//  Created by James An on 2018/5/28.
//  Copyright © 2018 Sash Zats. All rights reserved.
//

import UIKit
import AVFoundation
import Speech
import MobileCoreServices

public class JATranslationPlayerController: UIViewController {

    private enum JATranslationPlayerControllerState {
        case Playing
        case Paused
        case Stopped
    }
    @IBOutlet var videoControls : [UIView]!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var albumPickButton: UIButton!
    private var timer : Timer?
    public var locale = Locale(identifier: "en-US")
    private let playerLayer = AVPlayerLayer()
    private var player = AVQueuePlayer()
    private lazy var speechRecognizer = SFSpeechRecognizer(locale: locale)!
    private var videoPicker : UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.delegate = self
        picker.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        return picker
    }
    fileprivate var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var tap: MYAudioTapProcessor!
    private var state : JATranslationPlayerControllerState = JATranslationPlayerControllerState.Stopped {
        didSet {
            playButton.removeTarget(self, action: nil, for: UIControlEvents.touchUpInside)
            if(state == .Paused || state == .Stopped) {
                playButton.setTitle("Play", for: UIControlState.normal)
                playButton.addTarget(self, action: #selector(playVideo), for: UIControlEvents.touchUpInside)
            } else {
                playButton.setTitle("Pause", for: UIControlState.normal)
                playButton.addTarget(self, action: #selector(pauseVideo), for: UIControlEvents.touchUpInside)
                startFadeTimer()
            }
        }
    }
    
    public var url : URL = Bundle.main.url(forResource: "video", withExtension: "mp4")! {
        didSet {
            let asset = AVURLAsset(url:url)
            let item = AVPlayerItem(asset: asset)
            player.removeAllItems()
            player.insert(item, after: nil)
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        // There is open radar rdar://26870006 if you forget to request authorization, any use of speech recognition API silently fails
        url = Bundle.main.url(forResource: "video", withExtension: "mp4")!
        SFSpeechRecognizer.requestAuthorization { status in
            if(status == .authorized) {
                DispatchQueue.main.async {
                    self.setUpVideoPlayer()
                }
            } else {
                self.showPermissionWarning()
            }
        }
        
    }
    
    override public func viewDidLayoutSubviews() {
        playerLayer.frame = view.bounds
    }
    
    func showPermissionWarning() {
        let alert = UIAlertController(title: "No permission to use speech recognizer", message: "", preferredStyle: UIAlertControllerStyle.alert)
        present(alert, animated: true, completion: nil)
    }
    
    func setUpVideoPlayer() {
        view.layer.insertSublayer(playerLayer, at: 0)
        playerLayer.frame = view.bounds
        playerLayer.player = player
    }
}

extension JATranslationPlayerController : MYAudioTabProcessorDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // getting audio buffer back from the tap and feeding into speech recognizer
    public func audioTabProcessor(_ audioTabProcessor: MYAudioTapProcessor!, didReceive buffer: AVAudioPCMBuffer!) {
        recognitionRequest?.append(buffer)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedVideoURL = info[UIImagePickerControllerMediaURL] as? URL {
            url =  pickedVideoURL
            playVideo()
        }
        dismiss(animated: true, completion: nil)
    }
}

//ui control
extension JATranslationPlayerController {
    
    public func startFadeTimer() {
        if let existingTimer = timer {
            existingTimer.invalidate()
        }
        timer = Timer(timeInterval: 3, target: self, selector: #selector(hideControls), userInfo: nil, repeats: false)
        RunLoop.current.add(timer!, forMode: RunLoopMode.commonModes)
    }
    
    @objc private func hideControls() {
        for control in videoControls {
            UIView.animate(withDuration: 0.2) {
                control.alpha = 0
            }
        }
    }
    
    @IBAction public func playVideo() {
        player.play()
        state = .Playing
    }
    
    @IBAction public func pauseVideo() {
        player.pause()
        state = .Paused
    }
    
    @IBAction public func openMediaPicker() {
        pauseVideo()
        present(videoPicker, animated: true, completion: nil)
    }
    
    @IBAction public func playerViewTapped() {
        for control in videoControls where control.alpha == 0{
            UIView.animate(withDuration: 0.2) {
                control.alpha = 1
            }
        }
        startFadeTimer()
    }
}

