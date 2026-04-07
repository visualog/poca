//
//  ContentView.swift
//  POCA
//
//  Created by visualog on 4/6/26.
//

import SwiftUI

struct ContentView: View {
    // 3열 그리드 레이아웃 설정
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    @Namespace private var heroAnimation
    @State private var isPresentingCamera = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 전체 배경색 (레퍼런스 이미지의 따뜻한 느낌 반영)
                Color(red: 0.96, green: 0.95, blue: 0.94).ignoresSafeArea()
                
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(mockStamps) { stamp in
                            NavigationLink {
                                StampDetailView(stamp: stamp)
                                    // iOS 18+ : Hero Zoom Transition
                                    .navigationTransition(.zoom(sourceID: stamp.id, in: heroAnimation))
                            } label: {
                                StampItemView(stamp: stamp)
                                    // 애니메이션 소스 ID 매칭
                                    // (iOS 18+ 타겟으로 수정 필요)
                                    .matchedTransitionSource(id: stamp.id, in: heroAnimation)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    // 스크롤 시 버튼에 가려지지 않도록 하단 여백 추가
                    .padding(.bottom, 100) 
                }
            }
            .navigationTitle("컬렉션") // 장면 4의 카드를 의미하는 타이틀(한국어)
            .navigationBarTitleDisplayMode(.inline)
            
            // 하단 플로팅 액션 버튼 (카메라 열기)
            .overlay(alignment: .bottom) {
                Button(action: {
                    isPresentingCamera = true
                }) {
                    Image(systemName: "plus")
                        .font(.title2.weight(.medium))
                        .foregroundColor(.black)
                        .padding(20)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
                        )
                }
                .padding(.bottom, 32)
            }
            .fullScreenCover(isPresented: $isPresentingCamera) {
                CameraView()
            }
        }
    }
}

#Preview {
    ContentView()
}
