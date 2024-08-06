//
//  ACCropTool.swift
//  DooKit
//
//  Created by Alibaba on 2024/7/30.
//

import UIKit
import AVFoundation

class ACCropTool: NSObject {
    
    class func ac_addAudio(_ fromPath: String, _ toPath: String, _ outPath: String) {
        // 1.获取两个音频源
        let audioAsset1 = AVURLAsset(url: URL(filePath: fromPath))
        let audioAsset2 = AVURLAsset(url: URL(filePath: toPath))
        
        
        // 2.获取两个音频素材中的素材轨道
        let audioAssetTrack1: AVAssetTrack = audioAsset1.tracks(withMediaType: .audio).first!
        let audioAssetTrack2: AVAssetTrack = audioAsset2.tracks(withMediaType: .audio).first!
        
        // 3.向音频合成器，添加一个空的素材器
        let composition = AVMutableComposition()
        let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: 0)
        
        // 4.向素材容器中，插入音轨素材
        do {
            try audioTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: audioAsset2.duration), of: audioAssetTrack2, at: CMTime.zero)
        } catch { }
        
        do {
            try audioTrack?.insertTimeRange(CMTimeRangeMake(start: CMTime.zero, duration: audioAsset1.duration), of: audioAssetTrack1, at: audioAsset2.duration)
        } catch { }
        
        // 5.根据合成器，创建一个导出对象，并设置参数
        let session = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetAppleM4A)
        session?.outputURL = URL(filePath: outPath)
        // 导出类型
        session?.outputFileType = .m4a
        
        // 6.开始到处
        session?.exportAsynchronously(completionHandler: {
            let status = session?.status
            switch status {
            case .unknown:
                print("未知状态")
            case .waiting:
                print("等待导出")
            case .exporting:
                print("导出中")
            case .completed:
                print("导出成功")
            case .failed:
                print("导出失败")
            case .cancelled:
                print("导出取消")
            case .none:
                break
            case .some(_):
                break
            }
        })
    }
    
    class func ac_cropAudio(_ audioPath: String, _ fromTime: TimeInterval, _ toTime: TimeInterval, _ outputPath: String) {
        // 1.获取音频源
        let asset = AVAsset(url: URL(filePath: audioPath))
        // 2.创建一个音频会话，并且设置相应的配置
        let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)
        session?.outputFileType = .m4a
        session?.outputURL = URL(filePath: outputPath)
        
        let startTime = CMTimeMake(value: Int64(fromTime),timescale: 1)
        let endTime = CMTimeMake(value: Int64(toTime), timescale: 1)
        
        session?.timeRange = CMTimeRange(start: startTime, end: endTime)
        
        // 3.导出
        session?.exportAsynchronously(completionHandler: {
            let status = session?.status
            switch status {
            case .unknown:
                print("未知状态")
            case .waiting:
                print("等待导出")
            case .exporting:
                print("导出中")
            case .completed:
                print("导出成功")
            case .failed:
                print("导出失败")
            case .cancelled:
                print("导出取消")
            case .none:
                break
            case .some(_):
                break
            }
        })
    }
}
