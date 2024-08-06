//
//  ACAudioRecorderTool.swift
//  DooKit
//
//  Created by Alibaba on 2024/7/30.
//

import UIKit
import AVFoundation

class ACAudioRecorderTool: NSObject {
    
    static let shareInstance = ACAudioRecorderTool()
    
    weak var delegate: ACAudioRecorderToolDelegate?
    
    fileprivate var audioRecorder: AVAudioRecorder?
    
    fileprivate var recordingSettings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatLinearPCM), /* kAudioFormatLinearPCM: 无损压缩，内容非常大 kAudioFormatMPEG4AAC */
        AVSampleRateKey: 11025.0, /* 采样率(通过测试的数据，根据公司的要求可以再去调整)，必须保证和转码设置的相同 */
        AVNumberOfChannelsKey: 2, /* 通道数（必须设置为双声道, 不然转码生成的 MP3 会声音尖锐变声.） */
        AVEncoderAudioQualityKey:AVAudioQuality.min.rawValue /* 音频质量,采样质量(音频质量越高，文件的大小也就越大) */
    ]
    
    fileprivate var timer: Timer?
    
    fileprivate var recordingDuration: Int = 0
    
    fileprivate override init() {
        super.init()
    }
    
    fileprivate func ac_initAudioRecorder() {
        do {
            audioRecorder = try AVAudioRecorder(url: URL(string: ac_composeDir())!, settings: recordingSettings)
            audioRecorder?.isMeteringEnabled = true
        } catch {
            // 处理错误
            print("Failed to initialize the audio recorder: \(error.localizedDescription)")
            audioRecorder = nil
        }
    }
    
    //MARK: - Public
    class func ac_config(_ recordingSettings: [String: Any]? = nil) -> ACAudioRecorderTool {
        guard let settIng = recordingSettings else {
            return shareInstance
        }
        shareInstance.recordingSettings.merge(settIng) { (current, _) in current }
        return shareInstance
    }
    
    /// 开始录音
    func ac_beginRecording() {
        
        // 开始之前先暂停之前的录音对象
        audioRecorder?.stop()
        
        audioRecorder = nil
        
        recordingDuration = 0
        
        ac_invalidateTimer()
        // 创建录音对象
        ac_initAudioRecorder()
        
        audioRecorder?.prepareToRecord()
        
        let recordeStatus = audioRecorder?.record()
        
        if recordeStatus == true {
            
            recordingDuration = 0
            
            ac_createTimer()
            
            delegate?.ac_beginRecord()
        } else {
            delegate?.ac_recordFailure("开启录音失败")
        }
    }
    
    /// 停止录音
    func ac_stopRecord() {
        
        audioRecorder?.stop()
        
        audioRecorder = nil
        
        recordingDuration = 0
        
        ac_invalidateTimer()
        
        delegate?.ac_stopRecord()
    }
    
    /// 暂停录音
    func ac_pauseRecord() {
        
        audioRecorder?.pause()
        
        delegate?.ac_puaseRecord()
        
        ac_invalidateTimer()
    }
    
    /// 恢复录音
    func ac_reRecord() {
        
        let recordeStatus = audioRecorder?.record()
        
        if recordeStatus == true {
            
            ac_createTimer()
            
            delegate?.ac_reRecord()
        } else {
            delegate?.ac_recordFailure("恢复录音失败")
        }
    }
    
    /// 删除录音
    func ac_deletedRecord() {
        ac_stopRecord()
        audioRecorder?.deleteRecording()
    }
    
    /// 更新音频测量值
    func ac_updateMeters() {
        audioRecorder?.updateMeters()
    }
    
    /// 获取制定声道的分贝峰值
    func ac_peakPowerForChannel0() -> Float {
        ac_updateMeters()
        return audioRecorder?.peakPower(forChannel: 0) ?? 0.0
    }
    
    //MARK: - Private
    /// 获取存储地址
    fileprivate func ac_composeDir() -> String {
        
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let composeDir = cacheDir.appendingPathComponent("Audio_Recording")
        if !FileManager.default.fileExists(atPath: composeDir.path) {
            do {
                try FileManager.default.createDirectory(at: composeDir, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create directory: \(error)")
            }
        }
        return composeDir.path
    }
    
    fileprivate func ac_createTimer() {
        ac_invalidateTimer()
        if timer == nil {
            timer = Timer(timeInterval: 1.0, target: self, selector: #selector(ac_timerFired), userInfo: nil, repeats: true)
            RunLoop.main.add(timer!, forMode: .default)
        }
    }
    
    fileprivate func ac_invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc fileprivate func ac_timerFired() {
        recordingDuration += 1
        delegate?.ac_recordIngDuration(recordingDuration)
    }
}
