import Foundation

struct Log {
    static let fileURL = URL(fileURLWithPath: "/tmp/scriber.log")

    static func write(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let line = "[\(timestamp)] \(message)\n"
        print(line, terminator: "")

        if let data = line.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if let handle = try? FileHandle(forWritingTo: fileURL) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            } else {
                try? data.write(to: fileURL)
            }
        }
    }

    static func clear() {
        try? "".write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
