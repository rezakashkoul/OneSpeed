//
//  TestViewController.swift
//  One Speed
//
//  Created by Reza Kashkoul on 25/4/1401 AP.
//

import UIKit

class TestViewController: UIViewController {
    
    @IBOutlet weak var downloadLabel: UILabel!
    @IBOutlet weak var uploadLabel: UILabel!
    @IBOutlet weak var testButton: UIButton!
    
    @IBAction func testButtonAction(_ sender: Any) {
        testButtonFunctionality()
    }
    
    var startTime: CFAbsoluteTime!
    var bytesReceived: Int = 0
    var speedTestCompletionHandler: ((Result<Double, Error>) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        tabBarController?.tabBar.items![0].title = "Test"
        tabBarController?.tabBar.items![0].image = UIImage(systemName: "person")
        tabBarController?.tabBar.items![1].title = "History"
        testButton.layer.cornerRadius = 12
        testButton.clipsToBounds = true
    }
    
    func testDownloadSpeed(timeout: TimeInterval, completionHandler: @escaping (Result<Double, Error>) -> Void) {
        let url = URL(string: "https://hajifirouz10.cdn.asset.aparat.com/aparat-video/e7b4cd9407047dc54307d54c68eabead46478494-1080p.mp4?wmsAuthSign=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbiI6IjAzYTkyYjNmZWI1MTkwMzlmODY2M2JiZjgwMDM2ZGU0IiwiZXhwIjoxNjU4ODU0OTExLCJpc3MiOiJTYWJhIElkZWEgR1NJRyJ9.2ju6eZSOBw8XvWeVxnDsz26RE4x_Bx5uWQjGqDbiBGU")!
        startTime = CFAbsoluteTimeGetCurrent()
        bytesReceived = 0
        speedTestCompletionHandler = completionHandler
        print(timeout)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForResource = timeout
//        testButton.isEnabled = false
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        session.dataTask(with: url).resume()
        session.finishTasksAndInvalidate()
    }
    
    fileprivate func testButtonFunctionality() {
        testButton.isEnabled = true
        testDownloadSpeed(timeout: 15) { [self] result in
            switch result {
            case .failure(let error):
                print(error)
                AlertManager.shared.showAlert(parent: self, title: "Sorry :( ", body: "There's just an error for checking internet speed. Please try again", buttonTitles: ["OK"], showCancelButton: false) { _ in
                    print("OK")
                }
            case .success(let megabytesPerSecond):
                print("Speed in MB/S", megabytesPerSecond)
                DispatchQueue.main.async {[self] in
                    downloadLabel.text = "\(megabytesPerSecond)" + "MB/S"
                }
            }
        }
    }
    
}
//MARK: - Setup Session Functions:
extension TestViewController: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        bytesReceived += data.count
    }
}

extension TestViewController: URLSessionDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let stopTime = CFAbsoluteTimeGetCurrent()
        let elapsed = stopTime - startTime
        guard elapsed != 0 && (error == nil || (error as? URLError)?.code == .timedOut) else {
            speedTestCompletionHandler?(.failure(error ?? URLError(.unknown)))
            return
        }
        let speed = elapsed != 0 ? Double(bytesReceived) / elapsed / 1024.0 / 1024.0 : -1
        speedTestCompletionHandler?(.success(speed))
    }
}
