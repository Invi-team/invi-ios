import Foundation

extension Bundle {
    public func readLocalFile(forName name: String) throws -> Data {
        if let bundlePath = path(forResource: name, ofType: "json"),
           let jsonData = try String(contentsOfFile: bundlePath).data(using: .utf8) {
            return jsonData
        } else {
            throw NSError()
        }
    }
}
