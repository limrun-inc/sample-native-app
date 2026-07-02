import Combine
import Foundation

final class GameInput: ObservableObject {
    @Published var steering: Double = 0
    @Published var throttle: Double = 0.35
}
