import SwiftUI

// 우표 이미지 하나를 렌더링하는 뷰
struct StampItemView: View {
    let stamp: Stamp
    
    var body: some View {
        Rectangle()
            .fill(stamp.uiColor)
            .aspectRatio(0.8, contentMode: .fit)
            .overlay {
                // 임시로 우표 느낌을 내기 위한 안쪽 선
                Rectangle()
                    .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [2]))
                    .padding(4)
            }
            // 테두리를 톱니바퀴처럼 우표 느낌으로 자르는 것은 향후 Custom Shape로 고도화합니다.
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}
