//
//  DeselectableSegmentedControl.swift
//  VEXTit Drop

import UIKit

class DeselectableSegmentedControl: UISegmentedControl {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    var previousSelectedSegmentIndex: Int?
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        previousSelectedSegmentIndex = self.selectedSegmentIndex
        
        super.touchesEnded(touches, with: event)
        
        if previousSelectedSegmentIndex == self.selectedSegmentIndex {
            let touch = touches.first!
            let touchLocation = touch.location(in: self)
            if bounds.contains(touchLocation) {
                self.sendActions(for: .valueChanged)
            }
        }
    }
}
