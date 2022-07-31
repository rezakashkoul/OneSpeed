//
//  HistoryViewController.swift
//  One Speed
//
//  Created by Reza Kashkoul on 4/5/1401 AP.
//

import UIKit

class HistoryViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var testData: [Test] = [] {
        didSet {
            DispatchQueue.main.async {[self] in
                tableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadData()
    }

    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
}

//MARK: Setup TableView:
extension HistoryViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return testData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "Download: " + testData[indexPath.row].download + "/ " + "Upload :" + testData[indexPath.row].upload
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return testData[section].date?.description
    }
    
    
}

//MARK: Load Data:
extension HistoryViewController {
        
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

