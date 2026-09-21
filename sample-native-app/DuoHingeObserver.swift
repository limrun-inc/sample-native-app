import SwiftUI
import UIKit

/// Bridges the iOS 27.1 hinge interaction at runtime while staging builds with
/// Xcode 27.0. On devices without a hinge, the callback receives `nil`.
struct DuoHingeObserver: UIViewRepresentable {
    let onChange: (Double?) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false

        guard let interactionClass = NSClassFromString("UIHingeInteraction") else {
            return view
        }

        typealias UpdateHandler = @convention(block) (AnyObject, AnyObject) -> Void
        let handler: UpdateHandler = { _, update in
            let updateObject = update as? NSObject
            let hinge = updateObject?.value(forKey: "hinge") as? NSObject
            let radians = (hinge?.value(forKey: "angle") as? NSNumber)?.doubleValue
            let degrees = radians.map { $0 * 180 / .pi }

            Task { @MainActor in
                onChange(degrees)
            }
        }

        guard
            let allocated = class_createInstance(interactionClass, 0) as? NSObject,
            let initialized = allocated
                .perform(NSSelectorFromString("initWithUpdateHandler:"), with: handler as AnyObject)?
                .takeUnretainedValue(),
            let interaction = initialized as? any UIInteraction
        else {
            return view
        }

        view.addInteraction(interaction)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
