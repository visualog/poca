import Foundation
import SwiftUI

struct Stamp: Identifiable, Hashable {
    let id: UUID
    let uiColor: Color // 임시로 색상을 사용하여 모양 확인
    let capturedDate: Date
    let title: String
    
    // 포맷팅된 날짜 반환 (예: 16:27:43 / March 28, 2026)
    var formattedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss / MMMM d, yyyy"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: capturedDate)
    }
}

// 갤러리를 테스트하기 위한 임시 목업 데이터
let mockStamps: [Stamp] = [
    Stamp(id: UUID(), uiColor: .purple.opacity(0.8), capturedDate: Date(), title: "기하학 패턴"),
    Stamp(id: UUID(), uiColor: .orange.opacity(0.8), capturedDate: Date().addingTimeInterval(-86400), title: "고스트 프레임"),
    Stamp(id: UUID(), uiColor: .cyan.opacity(0.8), capturedDate: Date().addingTimeInterval(-186400), title: "추상적 물결"),
    Stamp(id: UUID(), uiColor: .red.opacity(0.8), capturedDate: Date().addingTimeInterval(-286400), title: "붉은 바다"),
    Stamp(id: UUID(), uiColor: .blue.opacity(0.8), capturedDate: Date().addingTimeInterval(-386400), title: "푸른 하늘"),
    Stamp(id: UUID(), uiColor: .mint.opacity(0.8), capturedDate: Date().addingTimeInterval(-486400), title: "민트 잔디")
]
