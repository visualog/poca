import SwiftUI
import AVFoundation

// AVFoundation 프리뷰를 SwiftUI에서 사용하기 위한 UIViewRepresentable
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {}
}

class VideoPreviewView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
}

// 스캐너 오버레이가 포함된 메인 카메라 뷰 (Scene 3 구현)
struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @Environment(\.dismiss) private var dismiss
    
    // 줌 기능을 위한 상태 변수
    @State private var currentZoomFactor: CGFloat = 1.0
    @State private var lastZoomFactor: CGFloat = 1.0
    @State private var dragStartZoomFactor: CGFloat = 1.0
    @State private var isZoomIndicatorVisible: Bool = false
    @State private var lastHapticZoomInt: Int = 10 // 햅틱 피드백을 위한 줌 눈금 단위 (1.0 = 10)
    
    var body: some View {
        ZStack {
            // 1. 실제 카메라 배경
            CameraPreview(session: cameraManager.session)
                .ignoresSafeArea()
            
            // 2. 스탬프 바깥 부분 (배경) 투명도 컬러 오버레이
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .mask(
                    ZStack {
                        Color.white
                            .ignoresSafeArea()
                        
                        // 스탬프 프레임 영역만큼 구멍 뚫기
                        RoundedRectangle(cornerRadius: 35, style: .continuous)
                            .frame(width: 300, height: 400)
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()
                )
            
            // 3. UI 및 베이지색 프레임 오버레이
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Circle().fill(Color.black.opacity(0.3)))
                    }
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                // [베이지색 스캐너 프레임]
                // 3D 플라스틱 재질감을 주기 위한 뷰 조합
                ZStack {
                    // 프레임 외부 (베이지색 틀) - 레퍼런스의 도톰한 플라스틱 느낌
                    RoundedRectangle(cornerRadius: 35, style: .continuous)
                        .fill(Color(red: 0.93, green: 0.91, blue: 0.86))
                        .frame(width: 300, height: 400)
                        .shadow(color: .black.opacity(0.6), radius: 30, x: 0, y: 15)
                    
                    // 카메라 프리뷰가 보이는 '안쪽 창문' (Hole)
                    // BlendMode(.destinationOut)를 사용하면 뷰를 구멍 뚫듯이 표현할 수 있습니다.
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(Color.black)
                        .frame(width: 230, height: 320)
                        .blendMode(.destinationOut)
                    
                    // 안쪽 창문의 그림자/테두리 디테일 (깊이감 부여)
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(Color(white: 0.6).opacity(0.5), lineWidth: 4)
                        .frame(width: 230, height: 320)
                    
                    // У표 모양의 가이드라인 (내부 점선)
                    Rectangle()
                        .stroke(Color.white.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                        .frame(width: 200, height: 280)
                }
                // 구멍을 뚫기 위해 compositingGroup 적용
                .compositingGroup()
                // 줌 다이얼 엣지 컨트롤 (우측 하단 코너에 밀착)
                .overlay(alignment: .bottomTrailing) {
                    ZoomDialEdgeView(zoomFactor: currentZoomFactor)
                        // 다이얼 중심을 베이지 프레임의 우측 하단 코너로 이동
                        .offset(x: 100, y: 85)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                // 위로 올리면 줌 인(-height), 아래로 내리면 줌 아웃(+height)
                                // 80pt 당 1.0 배율 변화 (민감도 조절)
                                let zoomDelta = -value.translation.height / 80.0
                                updateZoom(to: dragStartZoomFactor + zoomDelta)
                            }
                            .onEnded { _ in
                                lastZoomFactor = currentZoomFactor
                                dragStartZoomFactor = currentZoomFactor
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        isZoomIndicatorVisible = false
                                    }
                                }
                            }
                    )
                }
                
                Spacer()
                
                // 셔터 버튼
                Button(action: {
                    // TODO: 파일 시스템에 캡처본 저장 로직 구현
                    let generator = UIImpactFeedbackGenerator(style: .heavy)
                    generator.impactOccurred()
                    print("스냅샷 수집 완료!")
                    dismiss()
                }) {
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 76, height: 76)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.8), lineWidth: 3)
                                .frame(width: 66, height: 66)
                        )
                        .shadow(color: .black.opacity(0.2), radius: 5, y: 3)
                }
                .padding(.bottom, 40)
            }
            
            // 줌 배율 표시 (화면 중앙 상단 등)
            if isZoomIndicatorVisible {
                VStack {
                    Text(String(format: "%.1fx", currentZoomFactor))
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.yellow) // 노란색 배경
                        .clipShape(Capsule())
                        .padding(.top, 80)
                        .transition(.opacity.combined(with: .scale))
                    Spacer()
                }
            }
        }
        // 화면에 핀치-줌(Pinch-to-Zoom) 제스처 추가
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    updateZoom(to: lastZoomFactor * value)
                }
                .onEnded { _ in
                    lastZoomFactor = currentZoomFactor
                    dragStartZoomFactor = currentZoomFactor
                    
                    // 조금 뒤에 줌 배율 표시 숨기기
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            isZoomIndicatorVisible = false
                        }
                    }
                }
        )
        .onAppear {
            cameraManager.checkPermissionsAndSetup()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
    }
    
    // 줌 배율 업데이트 및 햅틱 피드백 처리 타이밍 연동
    private func updateZoom(to factor: CGFloat) {
        let newZoom = min(max(factor, 1.0), 5.0)
        
        if currentZoomFactor != newZoom {
            currentZoomFactor = newZoom
            cameraManager.setZoom(factor: newZoom)
            
            let newZoomInt = Int(newZoom * 10)
            if newZoomInt != lastHapticZoomInt {
                lastHapticZoomInt = newZoomInt
                if newZoomInt % 5 == 0 {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                } else {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
            
            withAnimation {
                isZoomIndicatorVisible = true
            }
        }
    }
}

#Preview {
    CameraView()
}

// 스캐너 프레임 코너 엣지에 밀착되는 렌즈 회전형(Radial) 다이얼 뷰
struct ZoomDialEdgeView: View {
    var zoomFactor: CGFloat
    
    // 1.0 ~ 5.0 → 41개 눈금 (0.1 단위)
    private let tickCount = 41
    // 각 눈금 사이 각도 (3도) → 전체 호 120도
    private let anglePerTick: Double = 3.0
    // 다이얼 반지름 (외곽 원)
    private let outerRadius: CGFloat = 120
    // 링 두께
    private let ringWidth: CGFloat = 32
    // 인디케이터가 가리키는 고정 각도 (12시 = 0도 기준, 시계 방향)
    // 프레임 우측 하단 코너에서 visible한 9~12시 방향 아크 중앙
    private let pointerAngle: Double = -45
    
    private var innerRadius: CGFloat { outerRadius - ringWidth }
    
    var body: some View {
        let dialSize = outerRadius * 2 + 20
        
        ZStack {
            // ── 1) 링 트랙 배경 (부채꼴 아크) ──
            Circle()
                .strokeBorder(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            .white.opacity(0.06),
                            .white.opacity(0.12),
                            .white.opacity(0.06)
                        ]),
                        center: .center
                    ),
                    lineWidth: ringWidth
                )
                .frame(width: outerRadius * 2 - ringWidth, height: outerRadius * 2 - ringWidth)
            
            // ── 2) 회전하는 눈금 + 라벨 그룹 ──
            ZStack {
                // 촘촘한 눈금(Ticks)
                ForEach(0..<tickCount, id: \.self) { i in
                    let isMajor = i % 10 == 0   // 1x, 2x, 3x ...
                    let isMid   = i % 5 == 0 && !isMajor // 1.5x, 2.5x ...
                    let angle   = Double(i) * anglePerTick
                    
                    let tickLen: CGFloat  = isMajor ? 14 : (isMid ? 10 : 5)
                    let tickW: CGFloat    = isMajor ? 2.0 : 1.2
                    let tickOpac: Double  = isMajor ? 1.0 : (isMid ? 0.65 : 0.35)
                    
                    Rectangle()
                        .fill(Color.white.opacity(tickOpac))
                        .frame(width: tickW, height: tickLen)
                        // 외곽 테두리에서 안쪽으로 내려오도록 배치
                        .offset(y: -(outerRadius - tickLen / 2 - 2))
                        .rotationEffect(.degrees(angle))
                }
                
                // 주요 배율 텍스트 라벨 (1x ~ 5x)
                ForEach(0..<5, id: \.self) { i in
                    let angle = Double(i * 10) * anglePerTick
                    
                    Text("\(i + 1)x")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .offset(y: -(innerRadius - 14))
                        .rotationEffect(.degrees(angle))
                }
            }
            // 줌 배율에 비례한 회전 (스핀)
            .rotationEffect(
                .degrees(-(Double(zoomFactor) - 1.0) * 10.0 * anglePerTick),
                anchor: .center
            )
            // 포인터 위치에 1x 눈금이 오도록 기본 회전
            .rotationEffect(.degrees(pointerAngle), anchor: .center)
            
            // ── 3) 고정된 인디케이터 포인터 (노란색) ──
            VStack(spacing: 0) {
                // 삼각형 화살표
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.yellow)
                    .offset(y: 2)
                // 포인터 라인
                Rectangle()
                    .fill(Color.yellow)
                    .frame(width: 2.5, height: ringWidth + 6)
                Spacer()
            }
            .frame(height: outerRadius * 2 + 12)
            .rotationEffect(.degrees(pointerAngle), anchor: .center)
        }
        .frame(width: dialSize, height: dialSize)
        // 프레임 코너에서 9시~12시 방향(상단-좌측) 호만 보이도록 클리핑
        .mask(
            Arc(startAngle: .degrees(180), endAngle: .degrees(290), clockwise: false)
                .fill()
                .frame(width: dialSize, height: dialSize)
        )
    }
}

// 부채꼴(Arc) Shape — 클리핑용
struct Arc: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var clockwise: Bool
    
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        path.move(to: center)
        path.addArc(center: center, radius: radius,
                    startAngle: startAngle, endAngle: endAngle,
                    clockwise: clockwise)
        path.closeSubpath()
        return path
    }
}
