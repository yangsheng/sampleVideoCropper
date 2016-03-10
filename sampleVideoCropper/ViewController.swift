//
//  ViewController.swift
//  sampleVideoCropper
//
//  Created by Wataru Maeda on 3/10/16.
//  Copyright © 2016 wataru maeda. All rights reserved.
//

import UIKit
import MediaPlayer

class ViewController: UIViewController, SAVideoRangeSliderDelegate
{
    var tmStart : Double?
    var tmEnd : Double?
    var vidURL : NSURL?
    var isTrimming : Bool?
    var tmpVidPath : String?
    var originalVidPath : String?
    var exportSession : AVAssetExportSession?
    var vidPlayer: MPMoviePlayerController?
    var vidSlider: SAVideoRangeSlider?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.setData()
        self.initView()
    }
    
    // MARK: - Data
    func setData()
    {
        isTrimming = false
        
        // Get Temp Storage Path
        tmpVidPath = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("1.mp4").path
        
        // Get original Video Path
        originalVidPath = NSBundle.mainBundle().pathForResource("1", ofType: "mp4")
        vidURL = NSURL.fileURLWithPath(originalVidPath!)
    }
    
    // MARK: - UI
    func initView()
    {
        // Background
        self.view.backgroundColor = UIColor.blackColor()
        
        // Vid Player
        vidPlayer = MPMoviePlayerController()
        vidPlayer?.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 100)
        vidPlayer?.scalingMode = .Fill
        vidPlayer?.controlStyle = .None
        self.view.addSubview(vidPlayer!.view)
        self.playVid(vidURL!)
        
        // Slider
        vidSlider = SAVideoRangeSlider(frame: CGRectMake(0, self.view.frame.size.height - 75, self.view.frame.size.width, 50), videoUrl: vidURL)
        vidSlider?.topBorder.backgroundColor = UIColor.yellowColor()
        vidSlider?.bottomBorder.backgroundColor = UIColor.yellowColor()
        vidSlider?.delegate = self
        self.view.addSubview(vidSlider!)
    }
    
    // MARK: - Action
    func showTrimmedVideo()
    {
        if isTrimming == true {
            return
        }
        
        isTrimming = true
        self.removeTmpFile()
        vidPlayer?.stop()
        
        vidURL = NSURL.fileURLWithPath(originalVidPath!)
        if let url = vidURL as NSURL?
        {
            let asset = AVURLAsset(URL: url)
            let assetSession = AVAssetExportSession.exportPresetsCompatibleWithAsset(asset)
            if assetSession.contains(AVAssetExportPresetMediumQuality)
            {
                let start = CMTimeMakeWithSeconds(tmStart!, asset.duration.timescale)
                let duration = CMTimeMakeWithSeconds(tmEnd!, asset.duration.timescale)
                let range = CMTimeRangeMake(start, duration)
                
                exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough)
                exportSession?.outputURL = NSURL.fileURLWithPath(tmpVidPath!)
                exportSession?.outputFileType = AVFileTypeQuickTimeMovie
                exportSession?.timeRange = range
                exportSession?.exportAsynchronouslyWithCompletionHandler({ () -> Void in
                    
                    if self.exportSession?.status != AVAssetExportSessionStatus.Cancelled &&
                        self.exportSession?.status != AVAssetExportSessionStatus.Failed
                    {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.playVid(NSURL(fileURLWithPath: self.tmpVidPath!))
                            self.isTrimming = false
                        }
                    }
                    else
                    {
                        self.isTrimming = false
                        NSLog("\(self.exportSession?.status)")
                    }
                })
            }
        }
    }
    
    func playVid(url: NSURL)
    {
        vidPlayer?.contentURL = url
        vidPlayer?.prepareToPlay()
        vidPlayer?.play()
    }
    
    // MARK: - SAVideoRangeSliderDelegate
    func videoRange(videoRange: SAVideoRangeSlider!, didChangeLeftPosition leftPosition: CGFloat, rightPosition: CGFloat)
    {
        tmStart = Double(leftPosition)
        tmEnd = Double(rightPosition)
        self.showTrimmedVideo()
    }
    
    // MARK: - Support
    func removeTmpFile()
    {
        if let path = tmpVidPath as String?
        {
            vidURL = NSURL.fileURLWithPath(path)
            let fm = NSFileManager.defaultManager()
            if  vidURL?.path != nil &&
                fm.fileExistsAtPath(vidURL!.path!)
            {
                do {
                    try fm.removeItemAtURL(vidURL!)
                } catch let error as NSError {
                    NSLog("Error")
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

