import Vapor
import HTTP

fileprivate let UpdateInterval: Double = 600

class CodesManager {
    
    // MARK: - Singleton
    
    private init() {}
    static let instance = CodesManager()
    
    // MARK: - Properties
    
    private var codes: [Code] = []
    private let baseUrl = URL(string: "https://www.papajohns.by/")!
    private let session = URLSession(configuration: .default)
    
    // MARK: - Obtain local codes
    
    func getCodes() -> [Code] {
        return codes
    }
    
    // MARK: - Update codes
    
    func startUpdatingCodes() {
        updateCodes()
    }
    
    private func updateCodes() {
        updateCodesFromPapaJohnsApi { codes in
            self.codes = codes
            DispatchQueue.global().asyncAfter(deadline: .now() + UpdateInterval, execute: {
                self.updateCodes()
            })
        }
    }
    
    private func updateCodesFromPapaJohnsApi(_ completion: @escaping (([Code]) -> ())) {
        getCodesList { (codes) in
            if codes.count > 0 {
                let group = DispatchGroup()
                var codeModels: [Code] = []
                for code in codes {
                    group.enter()
                    self.getCodeInfo(code, completion: { codeModel in
                        if let codeModel = codeModel {
                            codeModels.append(codeModel)
                        }
                        group.leave()
                    })
                }
                group.notify(queue: .global(), execute: {
                    completion(codeModels)
                })
            } else {
                completion([])
            }
        }
    }
    
    // MARK: - Requests
    
    private func getCodesList(_ completion: @escaping ([String]) -> ()) {
        let url = baseUrl.appendingPathComponent("api/stock/codes")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = session.dataTask(with: request) { (data, response, error) in
            if let data = data, let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let jsonArray = dict?["codes"] as? [[String: Any]] {
                let codes = jsonArray.compactMap({ $0["code"] as? String })
                completion(codes)
            } else {
                completion([])
            }
        }
        task.resume()
    }
    
    private func getCodeInfo(_ code: String, completion: @escaping ((Code?) -> ())) {
        let url = self.baseUrl.appendingPathComponent("stock/stock/getbycode/\(code)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
        
        let task = session.dataTask(with: request) { (data, response, error) in
            if let data = data, let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                var code: String? = nil
                var minimumOrder: Double? = nil
                var discountValue: Double? = nil
                
                code = dict?["code"] as? String
                if let stock = dict?["stock"] as? [String: Any] {
                    if let minOrderSum = stock["min_order_sum"] as? String {
                        if let minOrderDouble = Double(minOrderSum) {
                            minimumOrder = minOrderDouble
                        }
                    }
                    
                    if let discount = stock["discount"] as? [String: Any] {
                        if (discount["type"] as? String) == "order" {
                            if let amount = discount["amount"] as? String, let amountDouble = Double(amount) {
                                discountValue = amountDouble
                            } else if let amountDouble = stock["amount"] as? Double {
                                discountValue = amountDouble
                            }
                        }
                    }
                }
                
                if let code = code, let minimumOrder = minimumOrder, let discount = discountValue {
                    let codeModel = Code(code: code, minimumOrder: minimumOrder, discount: discount)
                    completion(codeModel)
                } else {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
        task.resume()
    }
}


