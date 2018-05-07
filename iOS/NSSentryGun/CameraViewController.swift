import UIKit
import SwiftSocket

class CameraViewController: UIViewController {

    let client = TCPClient(address: "192.168.1.25", port: 12340)
    var lastSentData = ""

    init() {
        super.init(nibName: nil, bundle: nil)
        connect()
    }

    private func connect() {
        DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
            switch self.client.connect(timeout: 10) {
            case .success:
                DispatchQueue.main.async {
                    self.smartView.setConnected()
                }
            case let .failure(error):
                print(error)
                DispatchQueue.main.async {
                    self.smartView.setDisconnected()
                }
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override func loadView() {
        view = CameraView(delegate: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        smartView.startCaptureSession()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setOrientation()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        smartView.stopCaptureSession()
    }
}

extension CameraViewController {
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        setOrientation()
    }

    func setOrientation() {
        guard let videoPreviewLayerConnection = smartView.videoPreviewLayer.connection else {
            return
        }
        let deviceOrientation = UIDevice.current.orientation
        guard let newVideoOrientation = deviceOrientation.videoOrientation, deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
            return
        }
        videoPreviewLayerConnection.videoOrientation = newVideoOrientation
    }
}

extension CameraViewController: CameraViewDelegate {
    func cameraViewFoundNoTargets() {
        send(data: "L")
    }

    func cameraViewDidTarget(frame: CGRect) {
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
        let oldMaxX = smartView.bounds.width
        let oldMaxY = smartView.bounds.height
        let xAngle = convertToDegrees(position: frame.midX, oldMax: oldMaxX)
        let yAngle = convertToDegrees(position: frame.midY, oldMax: oldMaxY)
        smartView.set(targetX: xAngle, targetY: abs(yAngle - 180))
        send(data: "X" + String(abs(xAngle - 180)) + ".")
    }

    func send(data: String) {
        guard lastSentData != data else {
            return
        }
        let result = client.send(data: data.data(using: .utf8)!)
        switch result {
        case .success:
            lastSentData = data
        case let .failure(error):
            switch error {
            case SocketError.unknownError:
                smartView.setDisconnected()
            default:
                break
            }
        }
    }
}

extension CameraViewController: SmartViewController {
    typealias SmartView = CameraView
}
