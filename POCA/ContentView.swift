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
    @StateObject private var stampStore = StampStore()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 전체 배경색 (레퍼런스 이미지의 따뜻한 느낌 반영)
                Color(red: 0.96, green: 0.95, blue: 0.94).ignoresSafeArea()
                
                if stampStore.stamps.isEmpty {
                    // 스탬프가 없을 때 안내 메시지
                    VStack(spacing: 16) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        Text("아직 수집한 스냅이 없어요")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("아래 + 버튼으로 첫 스냅을 찍어보세요!")
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.7))
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(stampStore.stamps) { stamp in
                                NavigationLink {
                                    StampDetailView(stamp: stamp)
                                        // iOS 18+ : Hero Zoom Transition
                                        .navigationTransition(.zoom(sourceID: stamp.id, in: heroAnimation))
                                } label: {
                                    StampItemView(stamp: stamp)
                                        // 애니메이션 소스 ID 매칭
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
            }
            .navigationTitle("컬렉션")
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
                CameraView(stampStore: stampStore)
            }
        }
    }
}

#Preview {
    ContentView()
}
