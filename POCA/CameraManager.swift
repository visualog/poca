import Foundation
import AVFoundation
import SwiftUI
import Combine

class CameraManager: ObservableObject {
    @Published var session = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    
    // 권한 확인 및 카메라 세션 설정
    func checkPermissionsAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.setupCamera()
                }
            }
        default:
            print("Camera access denied")
        }
    }
    
    private func setupCamera() {
        session.beginConfiguration()
        
        // 고화질 사진을 위한 프리셋 설정
        session.sessionPreset = .photo
        
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoDeviceInput) else {
            session.commitConfiguration()
            return
        }
        
        session.addInput(videoDeviceInput)
        self.videoDeviceInput = videoDeviceInput
        session.commitConfiguration()
        
        // 백그라운드 스레드에서 카메라 구동 시작
        DispatchQueue.global(qos: .background).async {
            self.session.startRunning()
        }
    }
    
    func stopSession() {
        if session.isRunning {
            DispatchQueue.global(qos: .background).async {
                self.session.stopRunning()
            }
        }
    }
    
    // 줌 배율 설정
    func setZoom(factor: CGFloat) {
        guard let device = videoDeviceInput?.device else { return }
        do {
            try device.lockForConfiguration()
            // 최소 1배, 최대 5배(혹은 기기 최대 줌)로 제한
            let maxZoom: CGFloat = min(device.activeFormat.videoMaxZoomFactor, 5.0)
            device.videoZoomFactor = max(1.0, min(factor, maxZoom))
            device.unlockForConfiguration()
        } catch {
            print("Failed to set zoom: \(error)")
        }
    }
}
