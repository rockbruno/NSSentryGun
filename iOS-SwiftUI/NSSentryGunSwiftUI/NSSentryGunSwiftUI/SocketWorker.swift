import Combine
import Foundation
import SwiftUI

final class SocketWorker: NSObject, ObservableObject {
    lazy var session = URLSession(configuration: .default,
                                  delegate: self,
                                  delegateQueue: OperationQueue())

    lazy var webSocketTask: URLSessionWebSocketTask = {
        let url = URL(string: "ws://169.254.141.251:12354")!
        return session.webSocketTask(with: url)
    }()

    var lastSentData = ""

    let objectWillChange = ObservableObjectPublisher()

    var isConnected: Bool? = true {
        willSet {
            DispatchQueue.main.async { [weak self] in
                self?.objectWillChange.send()
            }
        }
    }

    var connectionStatus: String {
        guard let isConnected = isConnected else {
            return "Connecting..."
        }
        if isConnected {
            return "Connected"
        } else {
            return "Disconnected"
        }
    }

    func resume() {
        webSocketTask.resume()
    }

    func suspend() {
        webSocketTask.suspend()
    }
}

extension SocketWorker: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        isConnected = true
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        isConnected = false
    }
}

extension SocketWorker: TargetDataViewModelDelegate {
    func targetDataDidChange(_ data: String) {
        guard data != lastSentData else {
            return
        }
        lastSentData = data
        webSocketTask.send(.string(data)) { error in
            if let error = error {
                print(error)
            }
        }
    }
}
