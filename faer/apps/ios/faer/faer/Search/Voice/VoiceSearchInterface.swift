//
//  VoiceSearchInterface.swift
//  faer
//
//  Created by pluto on 04.11.17.
//  Copyright © 2017 pluto. All rights reserved.
//

import Foundation
import AVFoundation
import googleapis

protocol VoiceSearchInterfaceDelegate {
    func received(intermediateText: String)
    func received(finalText: String)
    func streamingInterrupted(error: Error)
}

class VoiceSearchInterface {
    
    private var audioRecorder: AVAudioRecorder?
    private var audioData: NSMutableData?
    private var isTranscribing: Bool = false
    
    private let SAMPLE_RATE = 16000
    
    public var delegate: VoiceSearchInterfaceDelegate?
    
    init() {
        AudioController.sharedInstance.delegate = self
        SpeechRecognitionService.sharedInstance.sampleRate = self.SAMPLE_RATE
        _ = AudioController.sharedInstance.prepare(specifiedSampleRate: self.SAMPLE_RATE)
        
        self.configurePhraseHints()
    }
    
    private func configurePhraseHints() {
        struct Settings: Codable {
            let phraseHints: [String]
        }
        // Refactor to use Google Cloude storage auth
        URLSession.shared.dataTask(with: GlobalConfig.speechRecognitionPhraseHintsResource) { (data, response, error) in
            guard let _ = data else {
                return
            }
            do {
                let settings = try JSONDecoder().decode(Settings.self, from: data!)
                SpeechRecognitionService.sharedInstance.phraseHints = settings.phraseHints
            } catch {
                #if DEBUG
                    print("error configurePhraseHints()", error)
                #endif
            }
            }.resume()
    }
    
    
    public func startAudio() {
        
        audioData = NSMutableData()
        AudioController.sharedInstance.delegate = self
        let _ = AudioController.sharedInstance.start()
    }
    
    public func stopAudio() {
        
        _ = AudioController.sharedInstance.stop()
        let _ = SpeechRecognitionService.sharedInstance.stopStreaming()
    }
    
}

extension VoiceSearchInterface: AudioControllerDelegate {
    
    func processSampleData(_ data: Data) -> Void {
        audioData?.append(data)
        
        // We recommend sending samples in 100ms chunks
        let chunkSize : Int /* bytes/chunk */ = Int(0.1 /* seconds/chunk */
            * Double(SAMPLE_RATE) /* samples/second */
            * 2 /* bytes/sample */);
        
        guard let _ = audioData, audioData!.length > chunkSize else {
            return
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        SpeechRecognitionService.sharedInstance.streamAudioData(audioData!, completion: { [weak self] (response, error) in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            guard let r = response, let strongSelf = self, let result = r.resultsArray.firstObject as? StreamingRecognitionResult, let alternative = result.alternativesArray.firstObject as? SpeechRecognitionAlternative, error == nil else {
                if let _ = error {
                    self?.delegate?.streamingInterrupted(error: error!)
                }
                return
            }
            
            if !strongSelf.isTranscribing {
                // running for the first time
                strongSelf.isTranscribing = true
            }
            
            strongSelf.delegate?.received(intermediateText: alternative.transcript)
            if result.isFinal {
                guard let result = r.resultsArray.firstObject as? StreamingRecognitionResult, let alternative = result.alternativesArray.firstObject as? SpeechRecognitionAlternative else { return }
                
                strongSelf.isTranscribing = false
                strongSelf.delegate?.received(finalText: alternative.transcript)
                
            }
            
        })
        
        self.audioData = NSMutableData()
    }
    
}
