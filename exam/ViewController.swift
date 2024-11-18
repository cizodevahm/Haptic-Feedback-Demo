//
//  ViewController.swift
//  exam
//
//  Created by CIZO on 17/11/24.
//

import UIKit
import CoreHaptics
import AudioToolbox

class ViewController: UIViewController {
    private var dotView: UIView! // Red dot view that user tries to reach
    private var tapView: UIView! // Circle view to track finger movement proximity
    private var engine: CHHapticEngine? // Haptic engine for generating feedback
    var ignoreGesture = true // Flag to prevent multiple gesture recognitions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupDot() // Initialize dot and tap views
        prepareHaptics() // Set up the haptic engine
    }
    
    private func setupDot() {
        let size: CGFloat = 20
        dotView = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size)) // Create a red dot
        dotView.backgroundColor = .red
        dotView.layer.cornerRadius = size / 2 // Make the dot circular
        view.addSubview(dotView)
        placeDotAtRandomPosition() // Position dot randomly within view bounds
        
        // Configure tap view for proximity indication
        tapView = UIView(frame: CGRect(x: -100, y: -100, width: size * 3, height: size * 3))
        tapView.backgroundColor = .clear
        tapView.layer.cornerRadius = tapView.frame.width / 2 // Circular shape
        tapView.layer.borderWidth = 1.5 // Border for visual indication
        tapView.layer.borderColor = UIColor.blue.cgColor
        view.addSubview(tapView)
        
        // Add pan gesture recognizer to detect finger movements
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(panGesture) // Attach pan gesture to main view
    }
    
    private func placeDotAtRandomPosition() {
        // Reposition the dot randomly within the view's bounds
        ignoreGesture = false // Reset gesture flag
        let size = view.bounds.size
        let randomX = CGFloat.random(in: 40...(size.width - 40))
        let randomY = CGFloat.random(in: 70...(size.height - 70))
        dotView.backgroundColor = .red // Reset dot color
        dotView.center = CGPoint(x: randomX, y: randomY) // Update dot position
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        // Handle user's finger movement across the screen
        let location = gesture.location(in: view) // Get finger location
        let distance = hypot(dotView.center.x - location.x, dotView.center.y - location.y) // Calculate distance from dot
        let maxDistance = max(view.bounds.width, view.bounds.height) / 2 // Maximum detectable distance
        let intensity = max(0.16, min(1.0, 1.0 - distance / maxDistance)) // Calculate haptic intensity based on proximity
        
        if gesture.state == .began || gesture.state == .changed {
            tapView.center = location // Move tapView with finger
        } else {
            tapView.center = CGPoint(x: -100, y: -100) // Hide tapView when finger lifted
        }
        
        if !ignoreGesture {
            if distance < 30 {
                // Trigger haptic feedback upon reaching the dot
                ignoreGesture = true // Prevent multiple triggers
                dotView.backgroundColor = .black // Change dot color
                
                // Play system sounds for feedback
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                    AudioServicesPlaySystemSound(1519) // System haptic feedback
                    AudioServicesPlaySystemSound(1322) // Additional sound feedback
                })

                // Move dot to a new position after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: { [weak self] in
                    guard let self = self else { return }
                    self.placeDotAtRandomPosition()
                })
            } else {
                // Provide proximity haptic feedback
                playHapticFeedback(intensity: intensity)
            }
        }
    }
    
    private func prepareHaptics() {
        // Initialize haptic engine if supported by the hardware
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start() // Start the haptic engine
        } catch {
            print("Failed to prepare haptics: \(error.localizedDescription)") // Error handling
        }
    }
    
    private func playHapticFeedback(intensity: Double) {
        // Generate and play haptic feedback based on intensity
        guard let engine = engine, CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        let intensityValue = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(intensity))
        let sharpnessValue = CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(intensity))
        let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensityValue, sharpnessValue], relativeTime: 0, duration: 0.1)
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern) // Create haptic player
            try player.start(atTime: CHHapticTimeImmediate) // Play haptic feedback
        } catch {
            print("Failed to play haptic feedback: \(error.localizedDescription)") // Error handling
        }
    }
}
