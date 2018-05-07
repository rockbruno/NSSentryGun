import UIKit
import AVFoundation
import Vision

protocol CameraViewDelegate: class {
    func cameraViewDidTarget(frame: CGRect)
    func cameraViewFoundNoTargets()
}

final class CameraView: UIView {

    unowned let delegate: CameraViewDelegate

    private var captureSession: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        } set {
            videoPreviewLayer.session = newValue
        }
    }

    private var requests = [VNRequest]()
    private var maskLayer = [CAShapeLayer]()
    var devicePosition: AVCaptureDevice.Position = .back

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    private let connectionLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .callout)
        label.textColor = .white
        label.text = "Connecting..."
        label.textAlignment = .left
        return label
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.largeTitle)
        label.textColor = .white
        label.numberOfLines = 3
        label.textAlignment = .center
        return label
    }()

    private let degreesLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title3)
        label.textColor = .white
        return label
    }()

    init(delegate: CameraViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)
        captureSession = AVCaptureSession()
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    private func setup() {
        backgroundColor = .black
        setupCaptureSession()
        setupVision()
        setupLabels()
        constrainLabels()
    }

    private func setupCaptureSession() {
        captureSession?.beginConfiguration()
        captureSession?.sessionPreset = .high
        var defaultVideoDevice: AVCaptureDevice?
        if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: AVMediaType.video, position: .back) {
            defaultVideoDevice = dualCameraDevice
        } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) {
            defaultVideoDevice = backCameraDevice
        } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front) {
            defaultVideoDevice = frontCameraDevice
        }
        let input = try! AVCaptureDeviceInput(device: defaultVideoDevice!)
        captureSession?.addInput(input as AVCaptureInput)
        let captureMetadataOutput = AVCaptureVideoDataOutput()
        captureMetadataOutput.alwaysDiscardsLateVideoFrames = true
        captureMetadataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): Int(kCVPixelFormatType_32BGRA)]
        captureMetadataOutput.alwaysDiscardsLateVideoFrames = true
        let outputQueue = DispatchQueue(label: "outputQueue")
        captureMetadataOutput.setSampleBufferDelegate(self, queue: outputQueue)
        captureSession?.addOutput(captureMetadataOutput)
        captureSession?.commitConfiguration()
    }

    private func setupVision() {
        requests = [VNDetectFaceRectanglesRequest(completionHandler: self.handleFaces)]
    }

    func handleFaces(request: VNRequest, error: Error?) {
        DispatchQueue.main.async { [unowned self] in
            guard let results = request.results as? [VNFaceObservation] else {
                return
            }
            for mask in self.maskLayer {
                mask.removeFromSuperlayer()
            }
            if results.isEmpty {
                self.setUnknownPrediction()
                self.delegate.cameraViewFoundNoTargets()
            } else {
                let frames: [CGRect] = results.map {
                    let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -self.frame.height)
                    let translate = CGAffineTransform.identity.scaledBy(x: self.frame.width, y: self.frame.height)
                    return $0.boundingBox.applying(translate).applying(transform)
                }
                frames.sorted { ($0.width * $0.height) > ($1.width * $1.height) }.enumerated().forEach(self.drawFaceBox)
            }
        }
    }

    func drawFaceBox(index: Int, frame: CGRect) {
        if index == 0 {
            delegate.cameraViewDidTarget(frame: frame)
            createLayer(in: frame, color: UIColor.red.cgColor)
        } else {
            createLayer(in: frame, color: UIColor.yellow.cgColor)
        }
    }

    private func createLayer(in rect: CGRect, color: CGColor) {
        let mask = CAShapeLayer()
        mask.frame = rect
        mask.opacity = 1
        mask.borderColor = color
        mask.borderWidth = 2
        maskLayer.append(mask)
        layer.insertSublayer(mask, at: 1)
    }

    private func setupLabels() {
        addSubview(connectionLabel)
        addSubview(nameLabel)
        addSubview(degreesLabel)
        setUnknownPrediction()
    }

    private func constrainLabels() {
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        degreesLabel.translatesAutoresizingMaskIntoConstraints = false
        connectionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nameLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -48),
            nameLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            degreesLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            degreesLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            connectionLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            connectionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
        ])
    }

    func startCaptureSession() {
        captureSession?.startRunning()
    }

    func stopCaptureSession() {
        captureSession?.stopRunning()
    }

    func set(targetX: Int, targetY: Int) {
        nameLabel.text = "Targeting"
        degreesLabel.text = "X: \(targetX)° Y: \(targetY)°"
    }

    func setUnknownPrediction() {
        nameLabel.text = "No targets"
        degreesLabel.text = "Sentry mode"
    }

    func setConnected() {
        connectionLabel.text = "Connected"
        connectionLabel.textColor = .green
    }

    func setDisconnected() {
        connectionLabel.text = "Disconnected"
        connectionLabel.textColor = .red
    }
}

extension CameraView: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer), let exifOrientation = CGImagePropertyOrientation(rawValue: exifOrientationFromDeviceOrientation()) else {
            return
        }
        var requestOptions: [VNImageOption : Any] = [:]
        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics: cameraIntrinsicData]
        }
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: requestOptions)
        do {
            try imageRequestHandler.perform(requests)
        } catch {
            print(error)
        }
    }
}
