//
//  Global.swift
//  One Speed
//
//  Created by Reza Kashkoul on 31/5/1401 AP.
//

import Foundation

var testData: [Test] = [] {
    didSet {
        saveData(item: testData)
    }
}

func saveData(item: [Test]) {
    do {
        let encoder = JSONEncoder()
        let data = try encoder.encode(item)
        UserDefaults.standard.set(data, forKey: "TestData")
    } catch {
        print("Unable to Encode data (\(error))")
    }
}

func loadData() -> [Test] {
    if let data = UserDefaults.standard.data(forKey: "TestData") {
        do {
            let decoder = JSONDecoder()
            testData = try decoder.decode([Test].self, from: data)
        } catch {
            print("Unable to Decode data (\(error))")
        }
    }
    return testData
}
