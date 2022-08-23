//
//  HistoryViewController.swift
//  One Speed
//
//  Created by Reza Kashkoul on 4/5/1401 AP.
//

import UIKit

class HistoryViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        testData = loadData()
        DispatchQueue.main.async {[self] in
            tableView.reloadData()
            tableView.updateContentStatus()
            updateCleanButtonStatus()
            view.slideLeftViews(delay: 0.5)
        }
    }
    
    func setupUI() {
        title = "Test History"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clean", style: .done, target: self, action: #selector(cleanButtonAction))
        updateCleanButtonStatus()
    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: "TableViewCell")
        tableView.updateContentStatus()
    }
    
    func updateCleanButtonStatus() {
        navigationItem.rightBarButtonItem?.isEnabled = testData.isEmpty ? false : true
    }

    @objc private func cleanButtonAction() {
        showCleanPromptAlert()
    }
    
    func cleanButtonActionFunctionality() {
        testData = []
        saveData(item: testData)
        DispatchQueue.main.async {[self] in
            tableView.reloadData()
            tableView.updateContentStatus()
            updateCleanButtonStatus()
        }
    }
    
    fileprivate func showCleanPromptAlert() {
        AlertManager.shared.showAlert(parent: self, title: "Warning", body: "Are you sure to clear test results?",buttonTitles: ["Yes"], showCancelButton: true, completion: { [self] buttonIndex in
            if buttonIndex == 0 {
                cleanButtonActionFunctionality()
            }
        })
    }
    
}

//MARK: Setup TableView:
extension HistoryViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return testData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as! TableViewCell
        cell.setupCell(download: testData[indexPath.row].download,
                       upload: testData[indexPath.row].upload)
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return testData.isEmpty ? nil : testData[section].date
    }
    
}
