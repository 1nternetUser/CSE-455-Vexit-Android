//
//  MyDropsCollectionViewCell.swift
//  VEXTit Drop

import UIKit
import AVKit

class MyDropsCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var tapToWatch: UILabel!
    @IBOutlet weak var dropInfo: UILabel!
    @IBOutlet weak var dropImage: UIImageView!
    @IBOutlet weak var bigDropMessage: UILabel!
    @IBOutlet weak var dropMessage: UILabel!
    var dropVideo: AVPlayerLayer = AVPlayerLayer()
}
