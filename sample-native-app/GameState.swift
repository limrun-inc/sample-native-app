//
//  GameState.swift
//  sample-native-app
//

import Foundation
import simd

struct CarState {
    var position: SIMD3<Float> = SIMD3<Float>(0, 0, 0)
    var heading: Float = 0          // radians, 0 = +Z direction
    var speed: Float = 0            // units/sec
    var steerAngle: Float = 0       // radians, current wheel angle

    // Tuning constants
    static let maxSpeed: Float        = 12.0
    static let acceleration: Float    = 8.0
    static let braking: Float         = 14.0
    static let friction: Float        = 4.0
    static let maxSteer: Float        = 0.55   // ~31°
    static let steerSpeed: Float      = 2.2    // how fast steering responds
    static let steerReturn: Float     = 3.0    // how fast wheel re-centres
    static let wheelBase: Float       = 1.8    // distance front-to-rear axle

    mutating func update(dt: Float,
                         throttle: Float,    // 0…1
                         brake: Float,       // 0…1
                         steerInput: Float)  // -1 (left)…+1 (right)
    {
        // Steering
        let targetSteer = steerInput * CarState.maxSteer
        if abs(steerInput) > 0.01 {
            steerAngle += (targetSteer - steerAngle) * CarState.steerSpeed * dt
        } else {
            steerAngle -= steerAngle * CarState.steerReturn * dt
        }
        steerAngle = max(-CarState.maxSteer, min(CarState.maxSteer, steerAngle))

        // Longitudinal
        if throttle > 0 {
            speed += throttle * CarState.acceleration * dt
        }
        if brake > 0 {
            speed -= brake * CarState.braking * dt
        }
        // Friction (coast slowdown)
        if abs(speed) > 0 {
            let friction = CarState.friction * dt
            if speed > 0 { speed = max(0, speed - friction) }
            else          { speed = min(0, speed + friction) }
        }
        speed = max(-CarState.maxSpeed * 0.4, min(CarState.maxSpeed, speed))

        // Bicycle model heading change
        if abs(speed) > 0.01 {
            let turnRadius  = CarState.wheelBase / tan(steerAngle + 1e-6)
            let angularVel  = speed / turnRadius
            heading        += angularVel * dt
        }

        // Move
        let dx = sin(heading) * speed * dt
        let dz = cos(heading) * speed * dt
        position.x += dx
        position.z += dz

        // Keep on ground
        position.y = 0
    }
}

class GameState: ObservableObject {
    var car = CarState()

    // Raw input (set by the UI)
    var throttleInput: Float = 0
    var brakeInput: Float    = 0
    var steerInput: Float    = 0   // -1…+1

    var lapTime: Double = 0
    var speed: Float { car.speed }

    func update(dt: Float) {
        lapTime += Double(dt)
        car.update(dt: dt,
                   throttle: throttleInput,
                   brake: brakeInput,
                   steerInput: steerInput)
    }
}
