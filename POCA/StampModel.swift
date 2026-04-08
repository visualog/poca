import Foundation
import SwiftUI
import Combine

struct Stamp: Identifiable, Hashable, Codable {
    let id: UUID
    let imageName: String    // 앱 Documents 폴더 내 파일명
    let capturedDate: Date
    let title: String
    
    // Codable에서 제외 — 런타임에만 사용
    var uiImage: UIImage? {
        let url = Stamp.stampDirectory.appendingPathComponent(imageName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
    
    // 포맷팅된 날짜 반환
    var formattedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss / MMMM d, yyyy"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: capturedDate)
    }
    
    // MARK: - 저장 경로
    static var stampDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("Stamps")
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
}

// MARK: - 스탬프 저장소 (앱 내부 영속 저장)
class StampStore: ObservableObject {
    @Published var stamps: [Stamp] = []
    
    private let saveKey = "saved_stamps"
    
    init() {
        load()
    }
    
    // 새 스탬프 추가 (이미지를 Documents/Stamps/에 저장)
    func addStamp(image: UIImage, title: String? = nil) {
        let id = UUID()
        let fileName = "\(id.uuidString).jpg"
        let fileURL = Stamp.stampDirectory.appendingPathComponent(fileName)
        
        // JPEG로 압축 저장 (품질 90%)
        if let data = image.jpegData(compressionQuality: 0.9) {
            try? data.write(to: fileURL)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd HH:mm"
        let stampTitle = title ?? "스냅 \(dateFormatter.string(from: Date()))"
        
        let stamp = Stamp(id: id, imageName: fileName, capturedDate: Date(), title: stampTitle)
        stamps.insert(stamp, at: 0) // 최신순 정렬
        save()
    }
    
    // 스탬프 삭제
    func deleteStamp(_ stamp: Stamp) {
        let fileURL = Stamp.stampDirectory.appendingPathComponent(stamp.imageName)
        try? FileManager.default.removeItem(at: fileURL)
        stamps.removeAll { $0.id == stamp.id }
        save()
    }
    
    // MARK: - 영속 저장 (UserDefaults + JSON)
    private func save() {
        if let data = try? JSONEncoder().encode(stamps) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([Stamp].self, from: data) else { return }
        stamps = decoded
    }
}
