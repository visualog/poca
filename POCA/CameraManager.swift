import Foundation
import AVFoundation
import SwiftUI
import Combine
import Photos

class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var capturedImage: UIImage? = nil
    @Published var isSilentMode: Bool = true  // 무음 모드 (기본 ON)
    @Published var isSaving: Bool = false
    
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    
    // 무음 캡처용: 최신 비디오 프레임 보관
    private var latestVideoFrame: CMSampleBuffer?
    private let frameQueue = DispatchQueue(label: "com.poca.frameQueue")
    
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
        
        // 사진 출력 추가 (일반 모드용)
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
        }
        
        // 비디오 데이터 출력 추가 (무음 모드용)
        videoOutput.setSampleBufferDelegate(self, queue: frameQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            // 비디오 연결의 방향 설정
            if let connection = videoOutput.connection(with: .video) {
                connection.videoRotationAngle = 90 // 세로 모드 기준
            }
        }
        
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
            let maxZoom: CGFloat = min(device.activeFormat.videoMaxZoomFactor, 5.0)
            device.videoZoomFactor = max(1.0, min(factor, maxZoom))
            device.unlockForConfiguration()
        } catch {
            print("Failed to set zoom: \(error)")
        }
    }
    
    // 사진 촬영 (모드에 따라 분기)
    func capturePhoto() {
        if isSilentMode {
            captureSilent()
        } else {
            captureWithSound()
        }
    }
    
    // MARK: - 무음 캡처 (비디오 프레임에서 스틸 이미지 추출)
    private func captureSilent() {
        isSaving = true
        
        frameQueue.async { [weak self] in
            guard let self = self,
                  let sampleBuffer = self.latestVideoFrame,
                  let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                DispatchQueue.main.async { self?.isSaving = false }
                return
            }
            
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
                DispatchQueue.main.async { self.isSaving = false }
                return
            }
            
            let image = UIImage(cgImage: cgImage)
            
            DispatchQueue.main.async {
                self.capturedImage = image
                self.isSaving = false
            }
            
            // 사진 앨범에도 저장
            self.saveToPhotoLibrary(image: image)
        }
    }
    
    // MARK: - 일반 캡처 (셔터음 포함)
    private func captureWithSound() {
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = true
        isSaving = true
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // MARK: - 사진 라이브러리 저장
    private func saveToPhotoLibrary(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.95) else { return }
        
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized else {
                print("사진 라이브러리 접근 권한 없음")
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetCreationRequest.forAsset().addResource(with: .photo, data: imageData, options: nil)
            }) { success, error in
                if success {
                    print("✅ 사진 앨범 저장 완료!")
                } else if let error = error {
                    print("❌ 사진 앨범 저장 실패: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - 비디오 프레임 수신 (무음 캡처용 최신 프레임 보관)
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        latestVideoFrame = sampleBuffer
    }
}

// MARK: - 사진 촬영 델리게이트 (일반 모드)
extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("사진 촬영 오류: \(error.localizedDescription)")
            DispatchQueue.main.async { self.isSaving = false }
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("이미지 데이터 변환 실패")
            DispatchQueue.main.async { self.isSaving = false }
            return
        }
        
        DispatchQueue.main.async {
            self.capturedImage = image
            self.isSaving = false
        }
        
        // 사진 앨범에도 저장
        saveToPhotoLibrary(image: image)
    }
}
