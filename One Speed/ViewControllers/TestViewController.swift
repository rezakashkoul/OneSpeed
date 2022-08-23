//
//  TestViewController.swift
//  One Speed
//
//  Created by Reza Kashkoul on 25/4/1401 AP.
//

import UIKit
import GaugeSlider
import Reachability

class TestViewController: UIViewController {
    
    @IBOutlet weak var gaugeSlider: GaugeSliderView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var testButton: UIButton!
    @IBOutlet weak var testQualitySegment: UISegmentedControl!
    
    
    @IBAction func testQualitySegment(_ sender: Any) {
        setTestTime()
        print("testTime is", testTime)
    }
    
    @IBAction func testButtonAction(_ sender: Any) {
        testButtonActionFunctionality()
    }
    
    let reachability = try! Reachability()
    var startTime: CFAbsoluteTime!
    var bytesReceived: Int = 0
    var speedTestCompletionHandler: ((Result<Double, Error>) -> Void)?
    var testTime = 15
    var isTesting = false
    var isDownload = true {
        didSet {
            DispatchQueue.main.async {[self] in
                updateUIByTestKind()
            }
        }
    }
    var valueList: [Double] = []
    var testResult = Test(download: "", upload: "", date: Date().shortDate.description) {
        didSet {
            if !isTesting {
                testData.append(testResult)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        testData = loadData()
        handleInternetConnectionStatus()
        view.slideUpViews(delay: 0.5)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        reachability.stopNotifier()
    }
    
    fileprivate func setupUI() {
        title = "Test!"
        navigationController?.navigationBar.prefersLargeTitles = true
        tabBarController?.tabBar.items![0].title = "Test"
        tabBarController?.tabBar.items![1].title = "History"
        tabBarController?.tabBar.items![0].image = UIImage(named: "network")
        tabBarController?.tabBar.items![1].image = UIImage(named: "history")
        testQualitySegment.selectedSegmentIndex = 0
        testQualitySegment.setTitle("Fast", forSegmentAt: 0)
        testQualitySegment.setTitle("Reliable", forSegmentAt: 1)
        testButton.layer.cornerRadius = 12
        testButton.clipsToBounds = true
        testQualitySegment.layer.cornerRadius = 12
        testQualitySegment.clipsToBounds = true
        guageViewConfiguration(view: gaugeSlider)
        setTestTime()
        updateUIByTestStatus()
    }
    
    func updateUIByTestStatus() {
        if isTesting {
            testButton.isEnabled = false
            testQualitySegment.isEnabled = false
        } else {
            testButton.isEnabled = true
            testQualitySegment.isEnabled = true
            statusLabel.text = "Test Status"
            gaugeSlider.setCurrentValue(0, animated: true)
        }
    }
    
    func updateUIByTestKind() {
        if isDownload {
            gaugeSlider.fillPathColor = .green
        } else {
            gaugeSlider.fillPathColor = .blue
        }
    }
    
    private func guageViewConfiguration(view gauge: GaugeSliderView) {
        gauge.blankPathColor = .lightGray
        gauge.fillPathColor = isDownload ? .green : .blue
        gauge.indicatorColor = .blue
        gauge.unitColor = .black
        gauge.placeholderColor = .black
        gauge.unitIndicatorColor = .lightGray
        gauge.customControlColor = .lightGray
        gauge.delegationMode = .immediate(interval: 3)
        gauge.unit = ""
        gauge.placeholder = "MB/S"
        gauge.customControlButtonTitle = "Connected"
        gauge.slideUpViews(delay: 0.5)
        gauge.minValue = 0
        gauge.maxValue = 100
        gauge.isUserInteractionEnabled = false
    }
    
    fileprivate func setTestTime() {
        testTime = testQualitySegment.selectedSegmentIndex == 0 ? 15 : 45
    }
    
    func testButtonActionFunctionality() {
        if !isTesting {
            startTesting()
        } else {
            DispatchQueue.main.async {[self] in
                showTestingNotAvailableAlert()
            }
        }
        DispatchQueue.main.async {[self] in
            updateUIByTestStatus()
        }
    }
    
    fileprivate func showTestingNotAvailableAlert() {
        AlertManager.shared.showAlert(parent: self, title: "Already is testing!", body: "Please wait until test finishes.",buttonTitles: ["Ok"], showCancelButton: false, completion: {_ in})
    }
    
    fileprivate func showInternetConnectionErrorAlert() {
        DispatchQueue.main.async { [self] in
            AlertManager.shared.showAlert(parent: self,
                                          title: "No Connection",
                                          body: "No internet connection, connect to the internet and try again.",
                                          buttonTitles: ["Ok"],
                                          showCancelButton: false) { _ in
            }
        }
    }
    
    func handleInternetConnectionStatus() {
        reachability.whenReachable = { [self] reachability in
            if reachability.connection == .wifi || reachability.connection == .cellular {
                print("Connected to the internet")
                testButton.isEnabled = true
                DispatchQueue.main.async {[self] in
                    gaugeSlider.customControlButtonTitle = "Connected"
                    testButton.isEnabled = true
                }
            }
        }
        reachability.whenUnreachable = { _ in
            print("Not Connected")
            DispatchQueue.main.async {[self] in
                gaugeSlider.customControlButtonTitle = "Not Connected"
                testButton.isEnabled = false
                showInternetConnectionErrorAlert()
            }
        }
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
    
    func calculateMomentarySpeed(value: Int) -> String {
        let result = (Double(value) / 1024.0 / 1024.0).rounded(decimalPoint: 2).description + "MB/S"
        return result
    }
    
    func calculateAverageSpeed(list value: [Double])->Double {
        let sum = valueList.reduce(0, +)
        print("valueList", valueList)
        print("valueList.count", valueList.count)
        print("result", sum/Double(valueList.count))
        return sum*100/Double(valueList.count)//TODO: fix this
    }
    
    func startTesting() {
        isTesting = true
        startDownload(timeout: TimeInterval(testTime)) { [self] result in
            switch result {
            case .failure(let error):
                print(error)
                testResult.download = "Error"
                startUpload()
            case .success(let megabytesPerSecond):
                print(megabytesPerSecond)
                testResult.download = calculateAverageSpeed(list: valueList).rounded(decimalPoint: 1).description
                startUpload()
            }
        }
    }
    
    func startDownload(timeout: TimeInterval, completionHandler: @escaping (Result<Double, Error>) -> Void) {
        print("Starting download")
        isDownload = true
        valueList = []
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
        isDownload = false
        valueList = []
        print("Starting upload")
        var allData:[String: Data] = [:]
        if let file = (0...1000).compactMap({_ in UUID().uuidString}).description.data(using: .utf8) {
            for i in 0...1000 {
                allData["file \(i)"] = file
            }
        }
        upload(timeout: TimeInterval(testTime), data: allData.compactMap({$0.value}).reduce(Data(), +))
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
                        testResult.upload = "Error!"
                        updateUIByTestStatus()
                    }
                } else {
                    print("success upload")
                    DispatchQueue.main.async {[self] in
                        updateUIByTestStatus()
                    }
                    isTesting = false
                    print(calculateAverageSpeed(list: valueList), "uploadspeed")
                    testResult.upload = calculateAverageSpeed(list: valueList).rounded(decimalPoint: 1).description
                }
            }
            if let error = error {
                print("upload error",error.localizedDescription)
                testResult.upload = "Error!"
                DispatchQueue.main.async {[self] in
                    updateUIByTestStatus()
                    AlertManager.shared.showAlert(parent: self,
                                                  title: "Done!",
                                                  body: "Test done successfully", buttonTitles: ["Not now", "Show result"],
                                                  showCancelButton: false) { [self] buttonIndex in
                        if buttonIndex == 1 {
                            DispatchQueue.main.async {
                                self.tabBarController?.selectedIndex = 1
                            }
                        }
                    }
                }
                isTesting = false
                print(calculateAverageSpeed(list: valueList), "uploadspeed")
                testResult.upload = calculateAverageSpeed(list: valueList).rounded(decimalPoint: 1).description
                DispatchQueue.main.async {[self] in
                    updateUIByTestStatus()
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
            let value = (Double(data.count) / 1024.0 / 1024.0).rounded(decimalPoint: 2)
            statusLabel.text = "Testing Download Speed..." //calculateSpeed(speed: data.count)
            gaugeSlider.setCurrentValue(value*100, animated: true)
            
            valueList.append(value)
            print("valueList", valueList)
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
            statusLabel.text = "Testing Upload Speed..." //calculateSpeed(speed: Int(progress*100))
            let value = progress*100
            gaugeSlider.setCurrentValue(CGFloat(value), animated: true)
            valueList.append(Double(value))
            print("valueList", valueList)
        }
    }
}
