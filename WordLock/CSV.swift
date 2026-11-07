import SwiftUI
import UniformTypeIdentifiers

enum CSV {
    static func detectDelimiter(_ text: String) -> Character {
        let firstLine = text.split(whereSeparator: \.isNewline).first.map(String.init) ?? ""
        if firstLine.contains("\t") { return "\t" }
        let semicolons = firstLine.filter { $0 == ";" }.count
        let commas = firstLine.filter { $0 == "," }.count
        return semicolons > commas ? ";" : ","
    }

    static func parse(_ text: String) -> [[String]] {
        let delimiter = detectDelimiter(text)
        let chars = Array(text)
        var rows = [[String]]()
        var row = [String]()
        var field = ""
        var inQuotes = false
        var i = 0

        func endRow() {
            row.append(field)
            field = ""
            if !(row.count == 1 && row[0].isEmpty) { rows.append(row) }
            row = []
        }

        while i < chars.count {
            let ch = chars[i]
            if inQuotes {
                if ch == "\"" {
                    if i + 1 < chars.count, chars[i + 1] == "\"" { field.append("\""); i += 1 } else { inQuotes = false }
                } else {
                    field.append(ch)
                }
            } else if ch == "\"" {
                inQuotes = true
            } else if ch == delimiter {
                row.append(field)
                field = ""
            } else if ch == "\n" || ch == "\r" || ch == "\r\n" {
                endRow()
            } else {
                field.append(ch)
            }
            i += 1
        }
        if !field.isEmpty || !row.isEmpty { endRow() }
        return rows
    }

    static func export(_ cards: [Card]) -> String {
        func esc(_ s: String) -> String {
            if s.contains(",") || s.contains("\"") || s.contains("\n") {
                return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
            }
            return s
        }
        var lines = ["english,translation,example,ipa"]
        for c in cards {
            lines.append([c.english, c.translation, c.example ?? "", c.ipa ?? ""].map(esc).joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }
}

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText, .plainText] }
    var text: String

    init(text: String) { self.text = text }

    init(configuration: ReadConfiguration) throws {
        text = String(decoding: configuration.file.regularFileContents ?? Data(), as: UTF8.self)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}
