//
//  TestViewController.swift
//  One Speed
//
//  Created by Reza Kashkoul on 25/4/1401 AP.
//

import UIKit
import Foundation

class TestViewController: UIViewController {
    
    @IBOutlet weak var downloadLabel: UILabel!
    @IBOutlet weak var uploadLabel: UILabel!
    @IBOutlet weak var testButton: UIButton!
    
    @IBAction func testButtonAction(_ sender: Any) {
        timer?.invalidate()
        testButtonActionFunctionality()
    }
    
    var startTime: CFAbsoluteTime!
    var bytesReceived: Int = 0
    var speedTestCompletionHandler: ((Result<Double, Error>) -> Void)?
    var counter = 5 //20
    var timer: Timer?
    var speedTestResult = Test(download: "", upload: "", date: Date().shortDateTime.description)
    var testData: [Test] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }
    
    func setupUI() {
        title = "Test Your Network!"
        navigationController?.navigationBar.prefersLargeTitles = true
        tabBarController?.tabBar.items![0].title = "Test"
        tabBarController?.tabBar.items![1].title = "History"
        tabBarController?.tabBar.items![0].image = UIImage(systemName: "network")
        tabBarController?.tabBar.items![1].image = UIImage(systemName: "clock")
        testButton.layer.cornerRadius = 12
        testButton.clipsToBounds = true
    }
    
    func updateDownloadSpeed(speed: Int) {
        downloadLabel.text = (Double(speed) / 1024.0 / 1024.0).rounded(decimalPoint: 2).description + "MB/S"
    }
    
    func updateUploadSpeed(speed: Int64) {
        let uploadSpeed = (Double(speed) / 1024.0 / 1024.0).rounded(decimalPoint: 2).description + "MB/S"
        uploadLabel.text = uploadSpeed
        speedTestResult.upload = uploadSpeed.description
        testData.append(speedTestResult)
        saveData()
    }
    
    func testButtonActionFunctionality() {
        startDownload(timeout: TimeInterval(counter)) { [self] result in
            switch result {
            case .failure(let error):
                print(error)
                speedTestResult.download = "Error"
                startUpload()
                DispatchQueue.main.async {[self] in
                    downloadLabel.text = "Error!"
                }
            case .success(let megabytesPerSecond):
                print(megabytesPerSecond)
                let downloadResult = megabytesPerSecond.rounded(decimalPoint: 2)
                speedTestResult.download = downloadResult.description
                DispatchQueue.main.async {[self] in
                    downloadLabel.text = downloadResult.description + "MB/S"
                }
                startUpload()
            }
        }
    }
    
//    func setupTimer() {
//        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(handleTimerAction), userInfo: nil, repeats: true)
//    }
    
//    @objc private func handleTimerAction() {
//        DispatchQueue.main.async {
//            self.testButton.isEnabled = false
//        }
////        counter = counter - 1
////        if counter > 0 {
////            print("It takes \(counter) seconds to finish")
////            DispatchQueue.main.async {[self] in
////                testButton.isEnabled = false
////                testButton.setTitle("\(counter) Seconds", for: .normal)
////            }
////
////
////        } else if counter == 0 {
////            print("Task Finished")
////            timer?.invalidate()
////            timer = nil
////            counter = 15
////            DispatchQueue.main.async {[self] in
////                testButton.isEnabled = true
////                testButton.setTitle("Test Speed", for: .normal)
////            }
////
////        }
//    }
    
    func startDownload(timeout: TimeInterval, completionHandler: @escaping (Result<Double, Error>) -> Void) {
        print("Starting download")
        let url = URL(string: "https://updates.cdn-apple.com/2022SummerFCS/fullrestores/012-41728/C0769E31-5F11-4F6F-AF48-58175F955F51/iPhone14,5_15.6_19G71_Restore.ipsw")!
//        setupTimer()
        startTime = CFAbsoluteTimeGetCurrent()
        bytesReceived = 0
        speedTestCompletionHandler = completionHandler
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForResource = timeout
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        session.dataTask(with: url).resume()
        session.finishTasksAndInvalidate()
    }
    
    func startUpload() {
        print("Starting upload")
//        setupTimer()
        var allData:[String: Data] = [:]
        if let file = (0...1000).compactMap({_ in UUID().uuidString}).description.data(using: .utf8) {
            for i in 0...1000 {
                allData["file \(i)"] = file
            }
        }
        upload(timeout: TimeInterval(counter), data: allData.compactMap({$0.value}).reduce(Data(), +))
    }
    
    func upload(timeout: TimeInterval, data: Data) {
        var request = URLRequest(url: NSURL(string: "https://www.filestackapi.com/api/store/S3?key=MY_API_KEY")! as URL)
        request.httpMethod = "POST"
        request.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
        request.setValue("image/png", forHTTPHeaderField: "Content")
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForResource = timeout
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: .main)
        let dataTask = session.uploadTask(with: request, from: data) { [self] (data, response, error) in
            if let httpResponse = response as? HTTPURLResponse {
                print("response code: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    print("failed upload")
                    DispatchQueue.main.async {[self] in
                        uploadLabel.text = "Error!"
                        speedTestResult.upload = "Error!"
                    }
                } else {
                    print("success upload")
                }
//                DispatchQueue.main.async {
//                    self.testButton.isEnabled = true
//                }
            }
            if let error = error {
                print("upload error",error.localizedDescription)
                speedTestResult.upload = "Error!"
                DispatchQueue.main.async {[self] in
                    testButton.isEnabled = true
                }
            }
        }
        dataTask.resume()
    }
}

//MARK: Download URLSessionDataDelegate , URLSessionDelegate:
extension TestViewController: URLSessionDataDelegate, URLSessionDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        bytesReceived += data.count
        DispatchQueue.main.async { [self] in
            updateDownloadSpeed(speed: data.count)
        }
        
    }
    
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

//MARK: Upload URLSessionTaskDelegate:
extension TestViewController: URLSessionTaskDelegate {
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        let progress:Float = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        print("progress", progress)
        DispatchQueue.main.async {[self] in
            updateUploadSpeed(speed: bytesSent)
        }
        let data = Double(bytesSent)
//        speedTestCompletionHandler?(.success(data))
    }
}

//MARK: Save and load Data:
extension TestViewController {
    
    func saveData() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(testData)
            UserDefaults.standard.set(data, forKey: "TestData")
        } catch {
            print("Unable to Encode data (\(error))")
        }
    }
    
    func loadData() {
        if let data = UserDefaults.standard.data(forKey: "TestData") {
            do {
                let decoder = JSONDecoder()
                testData = try decoder.decode([Test].self, from: data)
            } catch {
                print("Unable to Decode data (\(error))")
            }
        }
    }
}
