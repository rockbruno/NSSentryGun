import Combine
import SwiftUI
import UIKit

struct ContentView: View {

    @ObservedObject var socketWorker: SocketWorker
    @ObservedObject var targetViewModel: TargetDataViewModel

    let cameraViewController: CameraViewController

    init() {
        self.socketWorker = SocketWorker()
        let targetViewModel = TargetDataViewModel()
        self.targetViewModel = targetViewModel
        self.cameraViewController = CameraViewController(
            targetViewModel: targetViewModel
        )
        targetViewModel.delegate = socketWorker
    }

    var body: some View {
        ZStack {
            CameraViewWrapper(
                viewController: cameraViewController
            )
            DataView(
                descriptionText: targetViewModel.targetTitle,
                degreesText: targetViewModel.targetDescription,
                connectionText: socketWorker.connectionStatus,
                isConnected: socketWorker.isConnected
            ).expand()
        }.onAppear {
            self.socketWorker.resume()
        }.onDisappear {
            self.socketWorker.suspend()
        }.expand()
    }
}

extension View {
    func expand() -> some View {
        return frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity,
            alignment: .topLeading
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
