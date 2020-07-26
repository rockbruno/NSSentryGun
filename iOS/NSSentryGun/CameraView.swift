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

    private var maskLayer = [CAShapeLayer]()

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }

    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    init(delegate: CameraViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)
        captureSession = AVCaptureSession()
        setupCaptureSession()
    }

    required init?(coder: NSCoder) {
        fatalError()
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
        guard defaultVideoDevice != nil else {
            captureSession?.commitConfiguration()
            captureSession = nil
            return
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
        videoPreviewLayer.connection?.videoOrientation = .landscapeRight
    }

    func startCaptureSession() {
        captureSession?.startRunning()
    }

    func stopCaptureSession() {
        captureSession?.stopRunning()
    }
}

extension CameraView: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let exifOrientation = CGImagePropertyOrientation(rawValue: 0) else
        {
            return
        }
        var requestOptions: [VNImageOption : Any] = [:]
        let key = kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix
        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, key: key, attachmentModeOut: nil) {
            requestOptions = [.cameraIntrinsics: cameraIntrinsicData]
        }
        let imageRequestHandler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: exifOrientation,
            options: requestOptions
        )
        do {
            let request = VNDetectFaceRectanglesRequest(completionHandler: handleFaces)
            try imageRequestHandler.perform([request])
        } catch {
            print(error)
        }
    }

    func handleFaces(request: VNRequest, error: Error?) {
        DispatchQueue.main.async { [unowned self] in
            guard let results = request.results as? [VNFaceObservation] else {
                return
            }
            for mask in self.maskLayer {
                mask.removeFromSuperlayer()
            }
            guard results.isEmpty == false else {
                self.delegate.cameraViewFoundNoTargets()
                return
            }
            let frames: [CGRect] = results.map {
                let transform = CGAffineTransform(scaleX: 1, y: -1)
                                    .translatedBy(x: 0, y: -self.frame.height)
                let translate = CGAffineTransform
                                    .identity
                                    .scaledBy(x: self.frame.width, y: self.frame.height)
                return $0.boundingBox
                            .applying(translate)
                            .applying(transform)
            }
            frames
                .sorted { ($0.width * $0.height) > ($1.width * $1.height) }
                .enumerated()
                .forEach(self.drawFaceBox)
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
}
