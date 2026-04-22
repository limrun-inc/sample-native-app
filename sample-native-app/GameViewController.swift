//
//  GameViewController.swift
//  sample-native-app
//

import UIKit
import MetalKit

class GameViewController: UIViewController {

    var mtkView: MTKView!
    var renderer: Renderer!
    var gameState = GameState()

    // Display link for fixed-timestep game loop
    var displayLink: CADisplayLink?
    var lastTimestamp: CFTimeInterval = 0

    // UI controls
    var steerSlider:  UISlider!
    var throttleBtn:  UIButton!
    var brakeBtn:     UIButton!
    var speedLabel:   UILabel!
    var steerLabel:   UILabel!

    // Touch tracking for steering
    var steerTouchActive = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMetal()
        setupUI()
        startGameLoop()
    }

    // MARK: – Metal

    private func setupMetal() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal not available")
        }
        mtkView = MTKView(frame: view.bounds, device: device)
        mtkView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mtkView.colorPixelFormat         = .bgra8Unorm
        mtkView.depthStencilPixelFormat  = .depth32Float
        mtkView.clearColor               = MTLClearColorMake(0.45, 0.72, 0.95, 1)
        mtkView.isPaused                 = true
        mtkView.enableSetNeedsDisplay    = false
        view.addSubview(mtkView)

        renderer = Renderer(mtkView: mtkView, gameState: gameState)!
        mtkView.delegate = renderer
    }

    // MARK: – UI

    private func setupUI() {
        view.backgroundColor = .black

        // --- Steering slider (bottom-centre) ---
        steerSlider = UISlider(frame: .zero)
        steerSlider.minimumValue  = -1
        steerSlider.maximumValue  =  1
        steerSlider.value         =  0
        steerSlider.tintColor     = .white
        steerSlider.translatesAutoresizingMaskIntoConstraints = false
        steerSlider.addTarget(self, action: #selector(steerChanged), for: .valueChanged)
        steerSlider.addTarget(self, action: #selector(steerReleased), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        view.addSubview(steerSlider)

        // --- Throttle button (bottom-right) ---
        throttleBtn = makeButton(title: "GAS", color: UIColor(red:0.15,green:0.75,blue:0.2,alpha:1))
        brakeBtn    = makeButton(title: "BRAKE", color: UIColor(red:0.85,green:0.2,blue:0.2,alpha:1))
        view.addSubview(throttleBtn)
        view.addSubview(brakeBtn)

        throttleBtn.addTarget(self, action: #selector(throttleDown), for: .touchDown)
        throttleBtn.addTarget(self, action: #selector(throttleUp),   for: [.touchUpInside, .touchUpOutside, .touchCancel])
        brakeBtn.addTarget(self,    action: #selector(brakeDown),    for: .touchDown)
        brakeBtn.addTarget(self,    action: #selector(brakeUp),      for: [.touchUpInside, .touchUpOutside, .touchCancel])

        // --- HUD labels (top) ---
        speedLabel = makeLabel("Speed: 0.0")
        steerLabel = makeLabel("Steer: 0.0")
        view.addSubview(speedLabel)
        view.addSubview(steerLabel)

        // Layout
        NSLayoutConstraint.activate([
            // steering slider
            steerSlider.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            steerSlider.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            steerSlider.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),

            // gas button
            throttleBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            throttleBtn.bottomAnchor.constraint(equalTo: steerSlider.topAnchor, constant: -16),
            throttleBtn.widthAnchor.constraint(equalToConstant: 90),
            throttleBtn.heightAnchor.constraint(equalToConstant: 90),

            // brake button
            brakeBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            brakeBtn.bottomAnchor.constraint(equalTo: steerSlider.topAnchor, constant: -16),
            brakeBtn.widthAnchor.constraint(equalToConstant: 90),
            brakeBtn.heightAnchor.constraint(equalToConstant: 90),

            // HUD
            speedLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            speedLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            steerLabel.topAnchor.constraint(equalTo: speedLabel.bottomAnchor, constant: 4),
            steerLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16)
        ])
    }

    private func makeButton(title: String, color: UIColor) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .boldSystemFont(ofSize: 16)
        btn.backgroundColor  = color.withAlphaComponent(0.85)
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }

    private func makeLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.textColor = .white
        l.font = .monospacedSystemFont(ofSize: 14, weight: .semibold)
        l.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        l.layer.cornerRadius = 6
        l.layer.masksToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }

    // MARK: – Controls

    @objc func steerChanged()  { gameState.steerInput  = steerSlider.value }
    @objc func steerReleased() {
        UIView.animate(withDuration: 0.15) { self.steerSlider.value = 0 }
        gameState.steerInput = 0
    }

    @objc func throttleDown()  { gameState.throttleInput = 1 }
    @objc func throttleUp()    { gameState.throttleInput = 0 }
    @objc func brakeDown()     { gameState.brakeInput    = 1 }
    @objc func brakeUp()       { gameState.brakeInput    = 0 }

    // MARK: – Game loop

    private func startGameLoop() {
        lastTimestamp = CACurrentMediaTime()
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc func tick(link: CADisplayLink) {
        let now = link.timestamp
        let dt  = min(Float(now - lastTimestamp), 0.05)
        lastTimestamp = now

        gameState.update(dt: dt)
        mtkView.draw()

        DispatchQueue.main.async {
            self.speedLabel.text = String(format: "  Speed: %5.1f km/h  ", self.gameState.speed * 3.6)
            self.steerLabel.text = String(format: "  Steer: %+.2f  ", self.gameState.car.steerAngle)
        }
    }
}
