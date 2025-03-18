import Foundation

struct WaterRecord: Codable, Identifiable {
    let id: UUID
    let date: Date
    var amount: Double
    
    init(id: UUID = UUID(), date: Date = Date(), amount: Double) {
        self.id = id
        self.date = date
        self.amount = amount
    }
} 