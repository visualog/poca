import SwiftUI

struct StampDetailView: View {
    let stamp: Stamp
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.95, blue: 0.94).ignoresSafeArea() // 따뜻한 베이지 종이 배경
            
            VStack {
                Spacer()
                
                // 확대된 우표 뷰
                StampItemView(stamp: stamp)
                    .frame(width: 250) // 크게 보여주기
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                
                Spacer()
                
                // 메타데이터 표시 (장면 2 레퍼런스 참고)
                VStack(spacing: 8) {
                    Text(stamp.title)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("\(stamp.formattedDateString)")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 60)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                        .padding(8)
                        .background(Circle().fill(Color.white))
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    // 추가 메뉴
                }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.black)
                        .padding(8)
                        .background(Circle().fill(Color.white))
                }
            }
        }
    }
}
