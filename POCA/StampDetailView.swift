import SwiftUI

struct StampDetailView: View {
    let stamp: Stamp
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea() // 전체 사진 감상을 위한 어두운 배경
            
            VStack(spacing: 0) {
                Spacer()
                
                // 전체 사진 (크롭 없이 원본 비율 그대로 표시)
                if let uiImage = stamp.uiImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
                        .padding(.horizontal, 16)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(3/4, contentMode: .fit)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 16)
                }
                
                Spacer()
                
                // 메타데이터 표시
                VStack(spacing: 8) {
                    Text(stamp.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\(stamp.formattedDateString)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 50)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Circle().fill(Color.white.opacity(0.15)))
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    // 추가 메뉴 (공유, 삭제 등)
                }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Circle().fill(Color.white.opacity(0.15)))
                }
            }
        }
        .toolbarBackground(.hidden, for: .navigationBar)
    }
}
