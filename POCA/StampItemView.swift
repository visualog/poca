import SwiftUI

// 우표 이미지 하나를 렌더링하는 뷰 (라이브러리 그리드용 — 스탬프 프레임 크롭)
struct StampItemView: View {
    let stamp: Stamp
    
    var body: some View {
        ZStack {
            // 베이지색 스탬프 틀 (카메라 뷰의 프레임과 동일한 느낌)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.93, green: 0.91, blue: 0.86))
            
            // 안쪽 창문: 스탬프에서 보였던 영역만 보여줌 (센터 크롭)
            if let uiImage = stamp.uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .padding(6) // 베이지 프레임 테두리 두께
            } else {
                // 이미지 로드 실패 시 플레이스홀더
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.gray.opacity(0.2))
                    .padding(6)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundColor(.gray.opacity(0.5))
                    }
            }
        }
        .aspectRatio(230.0 / 320.0, contentMode: .fit) // 스탬프 창문 비율 (230:320)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
}
