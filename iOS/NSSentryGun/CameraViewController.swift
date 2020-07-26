import Combine
import UIKit
import SwiftUI

struct CameraViewWrapper: UIViewControllerRepresentable {

    typealias UIViewControllerType = CameraViewController
    typealias Context = UIViewControllerRepresentableContext

    let viewController: CameraViewController

    func makeUIViewController(context: Context<CameraViewWrapper>) -> CameraViewController {
        return viewController
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context<CameraViewWrapper>) {}
}

final class CameraViewController: UIViewController, ObservableObject {

    @ObservedObject var targetViewModel: TargetDataViewModel

    init(targetViewModel: TargetDataViewModel) {
        self.targetViewModel = targetViewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func loadView() {
        let view = CameraView(delegate: self)
        self.view = view
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (view as? CameraView)?.startCaptureSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (view as? CameraView)?.stopCaptureSession()
    }
}

extension CameraViewController: CameraViewDelegate {
    func cameraViewDidTarget(frame: CGRect) {
        targetViewModel.process(target: frame, view: view)
    }

    func cameraViewFoundNoTargets() {
        targetViewModel.process(target: nil, view: view)
    }
}
