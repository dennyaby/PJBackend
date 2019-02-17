import Vapor

final class Code: Codable {
    let code: String
    let minimumOrder: Double
    let discount: Double
    
    init(code: String, minimumOrder: Double, discount: Double) {
        self.code = code
        self.minimumOrder = minimumOrder
        self.discount = discount
    }
}

extension Code: Content {}
