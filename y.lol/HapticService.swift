//
//  HapticService.swift
//  y.lol
//
//  Created by Andrea Russo on 3/1/25.
//


import UIKit

class HapticService {
    private var breathingTimer: Timer?
    
    // Feedback generators for different interactions
    private let typingGenerator: UISelectionFeedbackGenerator
    private let sendGenerator: UIImpactFeedbackGenerator
    private let receiveGenerator: UINotificationFeedbackGenerator
    
    // Configurable parameters
    struct BreathingConfig {
        var cycleLength: Double = 2.0
        var fadeInSteps: Double = 0.2
        var maxIntensity: Double = 1.0
        var minIntensity: Double = 0.0
    }
    
    private let config: BreathingConfig
    private let generator: UIImpactFeedbackGenerator
    
    init(config: BreathingConfig = BreathingConfig()) {
        self.config = config
        self.generator = UIImpactFeedbackGenerator(style: .soft)
        self.typingGenerator = UISelectionFeedbackGenerator()
        self.sendGenerator = UIImpactFeedbackGenerator(style: .medium)
        self.receiveGenerator = UINotificationFeedbackGenerator()
        
        // Prepare all generators
        self.generator.prepare()
        self.typingGenerator.prepare()
        self.sendGenerator.prepare()
        self.receiveGenerator.prepare()
    }
    
    func startBreathing() {
        stopBreathing() // Ensure any existing timer is invalidated
        
        breathingTimer = Timer.scheduledTimer(withTimeInterval: config.cycleLength, repeats: true) { [weak self] _ in
            self?.performBreathingCycle()
        }
    }
    
    func stopBreathing() {
        breathingTimer?.invalidate()
        breathingTimer = nil
    }
    
    private func performBreathingCycle() {
        // Fade in
        for intensity in stride(from: config.minIntensity, to: config.maxIntensity, by: config.fadeInSteps) {
            DispatchQueue.main.asyncAfter(deadline: .now() + intensity) { [weak self] in
                self?.generator.impactOccurred(intensity: intensity)
            }
        }
        
        // Fade out
        for intensity in stride(from: config.maxIntensity, to: config.minIntensity, by: -config.fadeInSteps) {
            DispatchQueue.main.asyncAfter(deadline: .now() + (config.cycleLength - intensity)) { [weak self] in
                self?.generator.impactOccurred(intensity: intensity)
            }
        }
    }
    
    // Typing feedback
    func playTypingFeedback() {
        typingGenerator.selectionChanged()
        typingGenerator.prepare() // Prepare for next use
    }
    
    // Send message feedback
    func playSendFeedback() {
        sendGenerator.impactOccurred(intensity: 1.0)
        sendGenerator.prepare() // Prepare for next use
    }
    
    // Receive message feedback
    func playReceiveFeedback() {
        receiveGenerator.notificationOccurred(.success)
        receiveGenerator.prepare() // Prepare for next use
    }
}
