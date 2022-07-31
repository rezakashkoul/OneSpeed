//
//  Extensions.swift
//  One Speed
//
//  Created by Reza Kashkoul on 9/5/1401 AP.
//

import Foundation

extension Double {
    
    func rounded(decimalPoint: Int) -> Double {
        let num = pow(10, Double(decimalPoint))
       return (self * num).rounded() / num
    }
}
