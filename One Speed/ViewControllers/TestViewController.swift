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
    var testTime = 5
    var speedTestResult = Test(download: "", upload: "", date: Date().shortDateTime.description)
    var testData: [Test] = []
    var isTesting = false
    var isDownload = true
    let gaugeSlider = GaugeSliderView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
        handleInternetConnectionStatus()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.slideUpViews(delay: 0.5)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        reachability.stopNotifier()
    }
    
    fileprivate func setupUI() {
        title = "Test Your Network!"
        navigationController?.navigationBar.prefersLargeTitles = true
        tabBarController?.tabBar.items![0].title = "Test"
        tabBarController?.tabBar.items![1].title = "History"
        tabBarController?.tabBar.items![0].image = UIImage(named: "network")
        tabBarController?.tabBar.items![1].image = UIImage(named: "history")
        testQualitySegment.selectedSegmentIndex = 0
        testQualitySegment.setTitle("Fast", forSegmentAt: 0)
        testQualitySegment.setTitle("Relible", forSegmentAt: 1)
        testButton.layer.cornerRadius = 12
        testButton.clipsToBounds = true
        statusLabel.text = "Test Status"
        setupGuageView()
        setTestTime()
        print("testTime is", testTime)
    }
    
    fileprivate func setupGuageView() {
        let width = UIScreen.main.bounds.width
        
        guageViewConfiguration(view: gaugeSlider)
        gaugeSlider.frame = CGRect(x: width * 0.05, y: 150, width: width * 0.9, height: width * 0.9)
        view.addSubview(gaugeSlider)
        view.backgroundColor = .white
    }
    
    private func guageViewConfiguration(view gauge: GaugeSliderView) {
        gauge.blankPathColor = UIColor(red: 218/255, green: 218/255, blue: 218/255, alpha: 1)
        gauge.fillPathColor = isDownload ? UIColor(red: 47/255, green: 190/255, blue: 169/255, alpha: 1) : UIColor.blue
        gauge.indicatorColor = .blue
        gauge.unitColor = UIColor(red: 74/255, green: 74/255, blue: 74/255, alpha: 1)
        gauge.placeholderColor = UIColor(red: 139/255, green: 154/255, blue: 158/255, alpha: 1)
        gauge.unitIndicatorColor = UIColor(red: 74/255, green: 74/255, blue: 74/255, alpha: 0.2)
        gauge.customControlColor = UIColor(red: 47/255, green: 190/255, blue: 169/255, alpha: 1) // button color
        gauge.delegationMode = .immediate(interval: 3)
        gauge.isCustomControlActive = false
        gauge.unit = ""
        gauge.placeholder = "MB/S"
        gauge.customControlButtonVisible = false
        gauge.slideUpViews(delay: 2)
        gauge.isUserInteractionEnabled = false
    }
    
    fileprivate func setTestTime() {
        testTime = testQualitySegment.selectedSegmentIndex == 0 ? 15 : 45
    }
    
    func testButtonActionFunctionality() {
        if !isTesting {
            startTesting()
        } else {
            showTestingNotAvailableAlert()
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
            }
        }
        reachability.whenUnreachable = { _ in
            print("Not Connected")
            DispatchQueue.main.async {[self] in
                showInternetConnectionErrorAlert()
                testButton.isEnabled = false
            }
        }
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
    
    func calculateSpeed(speed: Int) -> String {
        let result = (Double(speed) / 1024.0 / 1024.0).rounded(decimalPoint: 2).description + "MB/S"
        return result
    }
    
    func startTesting() {
        isTesting = true
        startDownload(timeout: TimeInterval(testTime)) { [self] result in
            switch result {
            case .failure(let error):
                print(error)
                speedTestResult.download = "Error"
                startUpload()
            case .success(let megabytesPerSecond):
                print(megabytesPerSecond)
                let downloadResult = megabytesPerSecond.rounded(decimalPoint: 2)
                speedTestResult.download = downloadResult.description
                startUpload()
            }
        }
    }
    
    func startDownload(timeout: TimeInterval, completionHandler: @escaping (Result<Double, Error>) -> Void) {
        print("Starting download")
        isDownload = true
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
                        speedTestResult.upload = "Error!"
                        statusLabel.text = "Test Status"
                    }
                } else {
                    print("success upload")
                    DispatchQueue.main.async {[self] in
                        statusLabel.text = "Test Status"
                    }
                    isTesting = false
                }
            }
            if let error = error {
                print("upload error",error.localizedDescription)
                speedTestResult.upload = "Error!"
                DispatchQueue.main.async {[self] in
                    gaugeSlider.setCurrentValue(0, animated: true)
                    statusLabel.text = "Test Status"
                    AlertManager.shared.showAlert(parent: self,
                                                  title: "Done!",
                                                  body: "Test done successfully", buttonTitles: ["Not now", "Show result"],
                                                  showCancelButton: false) { buttonIndex in
                        if buttonIndex == 1 {
                            DispatchQueue.main.async {
                                self.tabBarController?.selectedIndex = 1
                            }
                        }
                    }
                }
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
            let value = (Double(data.count) / 1024.0 / 1024.0).rounded(decimalPoint: 2)
            statusLabel.text = "Testing Download Speed..." //calculateSpeed(speed: data.count)
            gaugeSlider.setCurrentValue(value*100, animated: true)
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
            gaugeSlider.setCurrentValue(CGFloat(progress*100), animated: true)
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
