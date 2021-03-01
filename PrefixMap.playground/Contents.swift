import Cocoa

extension Collection {
    @inlinable func prefixMap<T>(_ transform: (Self.Element) throws -> T?) rethrows -> [T] {
        var result = [T]()
        for element in self {
            if let transformedElement = try transform(element) {
                result.append(transformedElement)
            }
            else {
                break
            }
        }
        return result
    }
}

struct Lane {
    let name: String
    let summary: String
}

extension NSRegularExpression {
    func firstMatch(in string: String, options: NSRegularExpression.MatchingOptions = []) -> NSTextCheckingResult? {
        let nsRange = NSRange(string.startIndex..<string.endIndex, in: string)
        return firstMatch(in: string, options: options, range: nsRange)
    }
}

struct FastfileParser {
    private static let laneExpression = try! NSRegularExpression(pattern: "^\\s*lane :([A-z_]+)", options: [])
    private static let descExpression = try! NSRegularExpression(pattern: "^\\s*desc [\"']{1}([^\"]*)[\"']{1}", options: [])
    
    static func lanes(in contents: String) -> [Lane] {
        let lines = contents.components(separatedBy: .newlines)
        let laneMatches = lines.indices.compactMap({ lineIndex -> (Int, String)? in
            let line = lines[lineIndex]
            guard let match = laneExpression.firstMatch(in: line) else { return nil }
            guard match.numberOfRanges >= 2 else { return nil }
            guard let laneRange = Range(match.range(at: 1), in: line) else { return nil }
            let laneName = line[laneRange]
            return (lineIndex, String(laneName))
        })
        return laneMatches.map { (lineIndex, laneName) -> Lane in
            // Look for preceeding lines with `desc` prefix
            let summary = (0..<lineIndex)
                .reversed()
                .prefixMap({ index -> String? in
                    let line = lines[index]
                    guard let match = descExpression.firstMatch(in: line) else { return nil }
                    guard match.numberOfRanges >= 2 else { return nil }
                    guard let range = Range(match.range(at: 1), in: line) else { return nil }
                    return String(line[range])
                })
                .reversed()
                .joined(separator: "\n")
            return Lane(name: laneName, summary: summary)
        }
    }
}

// Section from a Fastfile
let contents = """
           desc "Release a new daily build"
           desc ""
           desc "- Only works on `master branch`"
           desc "- Updates translations"
           desc "- Pushes translations update to master"
           lane :deploy_daily do
        """
let lanes = FastfileParser.lanes(in: contents)
print(lanes)
print(lanes.first?.summary)
