//
//  PlayerCharacter.swift
//  sample-native-app
//

import SceneKit
import UIKit

final class PlayerCharacter {
    enum Phase {
        case idle, running, jumping, rolling, dead
    }

    let node = SCNNode()

    private let hips = SCNNode()
    private let torso = SCNNode()
    private let neckJoint = SCNNode()
    private let upperArmL = SCNNode()
    private let upperArmR = SCNNode()
    private let lowerArmL = SCNNode()
    private let lowerArmR = SCNNode()
    private let upperLegL = SCNNode()
    private let upperLegR = SCNNode()
    private let lowerLegL = SCNNode()
    private let lowerLegR = SCNNode()

    private var originalDiffuse: [SCNMaterial: Any] = [:]
    private var rollStart: TimeInterval?
    private let rollDuration: TimeInterval = 0.6

    private let hipsBaseY: Float = 0.95

    private func material(_ color: UIColor) -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .physicallyBased
        m.roughness.contents = NSNumber(value: 0.7)
        m.metalness.contents = NSNumber(value: 0.0)
        m.diffuse.contents = color
        originalDiffuse[m] = color
        return m
    }

    init() {
        let hoodie = material(UIColor(red: 0.2, green: 0.35, blue: 0.85, alpha: 1))
        let jeans = material(UIColor(red: 0.15, green: 0.18, blue: 0.3, alpha: 1))
        let skin = material(UIColor(red: 0.85, green: 0.65, blue: 0.5, alpha: 1))
        let capRed = material(UIColor(red: 0.8, green: 0.15, blue: 0.15, alpha: 1))
        let hair = material(UIColor(white: 0.15, alpha: 1))
        let sneaker = material(UIColor(white: 0.95, alpha: 1))

        hips.position = SCNVector3(0, hipsBaseY, 0)
        node.addChildNode(hips)

        // Pelvis block for continuity between torso and legs
        let pelvis = SCNNode(geometry: SCNBox(width: 0.42, height: 0.18, length: 0.26, chamferRadius: 0.04))
        pelvis.geometry?.materials = [jeans]
        pelvis.position = SCNVector3(0, -0.04, 0)
        hips.addChildNode(pelvis)

        // Torso joint at chest base; geometry child offset +halfHeight
        torso.position = SCNVector3(0, 0.08, 0)
        hips.addChildNode(torso)
        let chest = SCNNode(geometry: SCNBox(width: 0.5, height: 0.6, length: 0.28, chamferRadius: 0.06))
        chest.geometry?.materials = [hoodie]
        chest.position = SCNVector3(0, 0.3, 0)
        torso.addChildNode(chest)

        // Neck + head pivoting at the neck
        neckJoint.position = SCNVector3(0, 0.62, 0)
        torso.addChildNode(neckJoint)
        let neck = SCNNode(geometry: SCNCylinder(radius: 0.06, height: 0.12))
        neck.geometry?.materials = [skin]
        neck.position = SCNVector3(0, 0.05, 0)
        neckJoint.addChildNode(neck)
        let head = SCNNode(geometry: SCNSphere(radius: 0.17))
        head.geometry?.materials = [skin]
        head.position = SCNVector3(0, 0.24, 0)
        neckJoint.addChildNode(head)
        let cap = SCNNode(geometry: SCNBox(width: 0.24, height: 0.1, length: 0.26, chamferRadius: 0.04))
        cap.geometry?.materials = [capRed]
        cap.position = SCNVector3(0, 0.36, 0.01)
        neckJoint.addChildNode(cap)
        let brim = SCNNode(geometry: SCNBox(width: 0.22, height: 0.03, length: 0.12, chamferRadius: 0.01))
        brim.geometry?.materials = [hair]
        brim.position = SCNVector3(0, 0.32, -0.18)
        neckJoint.addChildNode(brim)

        // Arms: shoulder joints at torso top corners
        for (joint, lower, side) in [(upperArmL, lowerArmL, Float(-1)), (upperArmR, lowerArmR, Float(1))] {
            joint.position = SCNVector3(0.31 * side, 0.52, 0)
            torso.addChildNode(joint)
            let upper = SCNNode(geometry: SCNCapsule(capRadius: 0.07, height: 0.32))
            upper.geometry?.materials = [hoodie]
            upper.position = SCNVector3(0, -0.16, 0)
            joint.addChildNode(upper)
            lower.position = SCNVector3(0, -0.32, 0)
            joint.addChildNode(lower)
            let fore = SCNNode(geometry: SCNCapsule(capRadius: 0.06, height: 0.3))
            fore.geometry?.materials = [skin]
            fore.position = SCNVector3(0, -0.15, 0)
            lower.addChildNode(fore)
            let hand = SCNNode(geometry: SCNSphere(radius: 0.07))
            hand.geometry?.materials = [skin]
            hand.position = SCNVector3(0, -0.32, 0)
            lower.addChildNode(hand)
        }

        // Legs: hip joints at the bottom of the hips
        for (joint, lower, side) in [(upperLegL, lowerLegL, Float(-1)), (upperLegR, lowerLegR, Float(1))] {
            joint.position = SCNVector3(0.13 * side, -0.05, 0)
            hips.addChildNode(joint)
            let thigh = SCNNode(geometry: SCNCapsule(capRadius: 0.09, height: 0.42))
            thigh.geometry?.materials = [jeans]
            thigh.position = SCNVector3(0, -0.21, 0)
            joint.addChildNode(thigh)
            lower.position = SCNVector3(0, -0.42, 0)
            joint.addChildNode(lower)
            let shin = SCNNode(geometry: SCNCapsule(capRadius: 0.08, height: 0.4))
            shin.geometry?.materials = [jeans]
            shin.position = SCNVector3(0, -0.2, 0)
            lower.addChildNode(shin)
            let foot = SCNNode(geometry: SCNBox(width: 0.16, height: 0.1, length: 0.28, chamferRadius: 0.02))
            foot.geometry?.materials = [sneaker]
            foot.position = SCNVector3(0, -0.4, -0.07)
            lower.addChildNode(foot)
        }
    }

    func startRoll() {
        rollStart = nil
    }

    func setTint(_ color: UIColor?) {
        for (m, original) in originalDiffuse {
            m.diffuse.contents = color ?? original
        }
    }

    func reset() {
        rollStart = nil
        updatePose(time: 0, speed: 0, phase: .idle)
    }

    func update(time: TimeInterval, speed: Float, phase: Phase) {
        updatePose(time: time, speed: speed, phase: phase)
    }

    // Limb rotation convention (character faces -Z):
    //   +x rotation swings the limb tip forward (-Z); -x swings it backward.
    private func updatePose(time: TimeInterval, speed: Float, phase: Phase) {
        guard phase != .dead else { return }

        if phase == .rolling {
            if rollStart == nil { rollStart = time }
            let p = Float(min((time - rollStart!) / rollDuration, 1))
            hips.position.y = 0.55
            hips.eulerAngles = SCNVector3(-2 * .pi * p, 0, 0)
            torso.eulerAngles = SCNVector3(-1.22, 0, 0)
            upperLegL.eulerAngles = SCNVector3(1.05, 0, 0)
            upperLegR.eulerAngles = SCNVector3(1.05, 0, 0)
            lowerLegL.eulerAngles = SCNVector3(-1.57, 0, 0)
            lowerLegR.eulerAngles = SCNVector3(-1.57, 0, 0)
            upperArmL.eulerAngles = SCNVector3(1.0, 0, 0)
            upperArmR.eulerAngles = SCNVector3(1.0, 0, 0)
            lowerArmL.eulerAngles = SCNVector3(0.4, 0, 0)
            lowerArmR.eulerAngles = SCNVector3(0.4, 0, 0)
            neckJoint.eulerAngles = SCNVector3(0.3, 0, 0)
            return
        }
        rollStart = nil
        hips.eulerAngles = SCNVector3(0, 0, 0)

        switch phase {
        case .running:
            let cadence = Float(2 * Double.pi) * max(speed, 1) / 3
            let s = Float(sin(Double(cadence * Float(time))))
            let c = Float(sin(Double(2 * cadence * Float(time))))

            hips.position.y = hipsBaseY + 0.05 * c
            torso.eulerAngles = SCNVector3(-0.14, 0.09 * s, 0)
            neckJoint.eulerAngles = SCNVector3(0.05, 0, 0)

            let legSwing: Float = 0.7 // ~40°
            upperLegL.eulerAngles = SCNVector3(legSwing * s, 0, 0)
            upperLegR.eulerAngles = SCNVector3(-legSwing * s, 0, 0)
            // Knees flex (foot backward) on the back swing
            lowerLegL.eulerAngles = SCNVector3(-0.9 * max(0, -s), 0, 0)
            lowerLegR.eulerAngles = SCNVector3(-0.9 * max(0, s), 0, 0)

            let armSwing: Float = 0.61 // ~35°
            upperArmL.eulerAngles = SCNVector3(-armSwing * s, 0, 0)
            upperArmR.eulerAngles = SCNVector3(armSwing * s, 0, 0)
            lowerArmL.eulerAngles = SCNVector3(1.2, 0, 0)
            lowerArmR.eulerAngles = SCNVector3(1.2, 0, 0)

        case .jumping:
            hips.position.y = hipsBaseY
            torso.eulerAngles = SCNVector3(-0.1, 0, 0)
            neckJoint.eulerAngles = SCNVector3(-0.1, 0, 0)
            // Legs tucked: thighs forward 60°, knees bent ~90°
            upperLegL.eulerAngles = SCNVector3(1.05, 0, 0)
            upperLegR.eulerAngles = SCNVector3(1.05, 0, 0)
            lowerLegL.eulerAngles = SCNVector3(-1.57, 0, 0)
            lowerLegR.eulerAngles = SCNVector3(-1.57, 0, 0)
            // Arms raised
            upperArmL.eulerAngles = SCNVector3(0, 0, 2.6)
            upperArmR.eulerAngles = SCNVector3(0, 0, -2.6)
            lowerArmL.eulerAngles = SCNVector3(0.4, 0, 0)
            lowerArmR.eulerAngles = SCNVector3(0.4, 0, 0)

        default: // idle
            hips.position.y = hipsBaseY + 0.015 * Float(sin(2.2 * time))
            torso.eulerAngles = SCNVector3(-0.02 + 0.02 * Float(sin(2.2 * time)), 0, 0)
            neckJoint.eulerAngles = SCNVector3(0.05 * Float(sin(0.9 * time)), 0, 0)
            upperLegL.eulerAngles = SCNVector3(0, 0, 0.03)
            upperLegR.eulerAngles = SCNVector3(0, 0, -0.03)
            lowerLegL.eulerAngles = SCNVector3(0, 0, 0)
            lowerLegR.eulerAngles = SCNVector3(0, 0, 0)
            upperArmL.eulerAngles = SCNVector3(0, 0, 0.1)
            upperArmR.eulerAngles = SCNVector3(0, 0, -0.1)
            lowerArmL.eulerAngles = SCNVector3(0.15, 0, 0)
            lowerArmR.eulerAngles = SCNVector3(0.15, 0, 0)
        }
    }
}
