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
        testButtonActionFunctionality()
    }
    
    var startTime: CFAbsoluteTime!
    var bytesReceived: Int = 0
    var speedTestCompletionHandler: ((Result<Double, Error>) -> Void)?
    var counter = 20
    var speedTestResult = Test(download: "", upload: "", date: Date().shortDateTime.description)
    var testData: [Test] = []
    var isTesting = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.slideUpViews(delay: 0.5)
    }
    
    fileprivate func setupUI() {
        title = "Test Your Network!"
        navigationController?.navigationBar.prefersLargeTitles = true
        tabBarController?.tabBar.items![0].title = "Test"
        tabBarController?.tabBar.items![1].title = "History"
        tabBarController?.tabBar.items![0].image = UIImage(systemName: "network")
        tabBarController?.tabBar.items![1].image = UIImage(systemName: "clock")
        testButton.layer.cornerRadius = 12
        testButton.clipsToBounds = true
    }
    
    func updateDownloadSpeed(speed: Int) -> String {
        let result = (Double(speed) / 1024.0 / 1024.0).rounded(decimalPoint: 2).description + "MB/S"
        return result
    }
    
    func updateUploadSpeed(speed: Int64) -> String {
        let uploadSpeed = (Double(speed) / 1024.0 / 1024.0).rounded(decimalPoint: 2).description + "MB/S"
        return uploadSpeed
    }
    
    func testButtonActionFunctionality() {
        if !isTesting {
            startTesting()
        } else {
            AlertManager.shared.showAlert(parent: self, title: "Already is testing!", body: "Please wait until test finishes.",buttonTitles: ["Ok"], showCancelButton: false, completion: {_ in})
        }
    }
    
    func startTesting() {
        isTesting = true
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
    
    func startDownload(timeout: TimeInterval, completionHandler: @escaping (Result<Double, Error>) -> Void) {
        print("Starting download")
        let url = URL(string: "https://updates.cdn-apple.com/2022SummerFCS/fullrestores/012-41728/C0769E31-5F11-4F6F-AF48-58175F955F51/iPhone14,5_15.6_19G71_Restore.ipsw")!
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
                    isTesting = false
                    DispatchQueue.main.async {[self] in
                        uploadLabel.text = "Error!"
                        speedTestResult.upload = "Error!"
                    }
                } else {
                    print("success upload")
                    isTesting = false
                }
            }
            if let error = error {
                print("upload error",error.localizedDescription)
                speedTestResult.upload = "Error!"
                isTesting = false
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
            downloadLabel.text = updateDownloadSpeed(speed: data.count)
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
            uploadLabel.text = updateUploadSpeed(speed: bytesSent)
        }
        
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
