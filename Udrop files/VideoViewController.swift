//
//  VideoViewController.swift
//  VEXTit Drop


import UIKit
import AVFoundation
import AVKit


class VideoViewController: AVPlayerViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        

        // Do any additional setup after loading the view.
        
//        let videoURL = URL(string: "https://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")
        
        
        let videoURL = DataStore.sharedInstance.allDropsForViewing![DataStore.sharedInstance.selectedCellInViewDrops!].content
        let player = AVPlayer(url: videoURL)

        self.showsPlaybackControls = true
        self.player = player
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
