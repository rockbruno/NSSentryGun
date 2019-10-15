import UIKit
import Combine

protocol TargetDataViewModelDelegate: AnyObject {
    func targetDataDidChange(_ data: String)
}

class TargetDataViewModel: ObservableObject {

    weak var delegate: TargetDataViewModelDelegate?

    let objectWillChange = ObservableObjectPublisher()

    var targetTitle = "..." {
        willSet {
            self.objectWillChange.send()
        }
    }

    var targetDescription = "..." {
        willSet {
            self.objectWillChange.send()
        }
    }

    func process(target: CGRect?, view: UIView) {
        guard let target = target else {
            targetTitle = "Sentry mode"
            targetDescription = "No targets"
            delegate?.targetDataDidChange("L")
            return
        }
        let oldMin: CGFloat = 0
        let offset: CGFloat = 40
        let newMin: CGFloat = 0 + offset
        let newMax: CGFloat = 180 - offset
        let newRange = newMax - newMin
        func convertToDegrees(position: CGFloat, oldMax: CGFloat) -> Int {
            let oldRange = oldMax - oldMin
            let scaledAngle = (((position - oldMin) * newRange) / oldRange) + newMin
            return Int(scaledAngle)
        }
        let bounds = UIScreen.main.bounds
        let oldMaxX = bounds.width
        let oldMaxY = bounds.height
        let xAngle = convertToDegrees(position: target.midX, oldMax: oldMaxX)
        let yAngle = convertToDegrees(position: target.midY, oldMax: oldMaxY)
        targetTitle = "Shooting"
        targetDescription = "X: \(xAngle) | Y: \(yAngle)"
        let data = "X\(xAngle)."
        delegate?.targetDataDidChange(data)
    }
}
