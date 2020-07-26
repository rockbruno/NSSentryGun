import Foundation
import SwiftUI

class CameraHostingController: UIHostingController<ContentView> {

    typealias Content = ContentView

    lazy var session = URLSession(configuration: .default,
                                  delegate: self,
                                  delegateQueue: OperationQueue())

    lazy var webSocketTask: URLSessionWebSocketTask = {
        let url = URL(string: "ws://192.168.15.16:12352")!
        return session.webSocketTask(with: url)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        webSocketTask.resume()
    }
}

extension CameraHostingController: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {

    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {

    }
}
