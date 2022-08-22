////
////  GaugeView.swift
////  One Speed
////
////  Created by Reza Kashkoul on 22/5/1401 AP.
////
//
//import UIKit
//
//class GaugeView: UIView {
//
//    var outerBezelColor = UIColor(red: 0, green: 0.5, blue: 1, alpha: 1)
//    var outerBezelWidth: CGFloat = 10
//
//    var innerBezelColor = UIColor.white
//    var innerBezelWidth: CGFloat = 5
//
//    var insideColor = UIColor.white
//    
//    var segmentWidth: CGFloat = 20
//    var segmentColors = [UIColor(red: 0.7, green: 0, blue: 0, alpha: 1), UIColor(red: 0, green: 0.5, blue: 0, alpha: 1), UIColor(red: 0, green: 0.5, blue: 0, alpha: 1), UIColor(red: 0, green: 0.5, blue: 0, alpha: 1), UIColor(red: 0.7, green: 0, blue: 0, alpha: 1)]
//    
//    func drawBackground(in rect: CGRect, context ctx: CGContext) {
//        // draw the outer bezel as the largest circle
//        outerBezelColor.set()
//        ctx.fillEllipse(in: rect)
//
//        // move in a little on each edge, then draw the inner bezel
//        let innerBezelRect = rect.insetBy(dx: outerBezelWidth, dy: outerBezelWidth)
//        innerBezelColor.set()
//        ctx.fillEllipse(in: innerBezelRect)
//
//        // finally, move in some more and draw the inside of our gauge
//        let insideRect = innerBezelRect.insetBy(dx: innerBezelWidth, dy: innerBezelWidth)
//        insideColor.set()
//        ctx.fillEllipse(in: insideRect)
//    }
//    
//    override func draw(_ rect: CGRect) {
//        guard let ctx = UIGraphicsGetCurrentContext() else { return }
//        drawBackground(in: rect, context: ctx)
//    }
//    
//}
