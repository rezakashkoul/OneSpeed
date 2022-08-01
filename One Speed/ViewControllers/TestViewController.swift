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
    var counter = 15
    var timer: Timer?
    var speedTestResult: Test!
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
    
    func testButtonActionFunctionality() {
        testDownloadSpeed(timeout: TimeInterval(counter)) { [self] result in
            switch result {
            case .failure(let error):
                print(error)
            case .success(let megabytesPerSecond):
                print(megabytesPerSecond)
                let downloadResult = megabytesPerSecond.rounded(decimalPoint: 2)
                speedTestResult = Test(download: downloadResult.description, upload: "", date: Date().shortDateTime)
                testData.append(speedTestResult)
                saveData()
                DispatchQueue.main.async {[self] in
                    downloadLabel.text = downloadResult.description + "MB/S"
                }
            }
        }
    }
    
    func setupTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(handleTimerAction), userInfo: nil, repeats: true)
    }
    
    @objc private func handleTimerAction() {
        counter = counter - 1
        if counter > 0 {
            print("It takes \(counter) seconds to finish")
            testButton.isEnabled = false
            testButton.setTitle("\(counter) Seconds", for: .normal)
        } else if counter == 0 {
            print("Task Finished")
            timer?.invalidate()
            timer = nil
            counter = 15
            testButton.isEnabled = true
            testButton.setTitle("Test Speed", for: .normal)
        }
    }
    
    func testDownloadSpeed(timeout: TimeInterval, completionHandler: @escaping (Result<Double, Error>) -> Void) {
        let url = URL(string: "https://updates.cdn-apple.com/2022SummerFCS/fullrestores/012-41728/C0769E31-5F11-4F6F-AF48-58175F955F51/iPhone14,5_15.6_19G71_Restore.ipsw")!
        setupTimer()
        startTime = CFAbsoluteTimeGetCurrent()
        bytesReceived = 0
        speedTestCompletionHandler = completionHandler
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForResource = timeout
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        session.dataTask(with: url).resume()
        session.finishTasksAndInvalidate()
    }
}

//MARK: URLSession URLSessionDataDelegate:
extension TestViewController: URLSessionDataDelegate {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        bytesReceived += data.count
    }
}

//MARK: URLSession URLSessionDelegate:
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

//MARK: Save Data:
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
