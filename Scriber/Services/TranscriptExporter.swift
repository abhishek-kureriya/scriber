import Foundation
import AppKit

struct TranscriptExporter {

    static var transcriptsFolder: URL {
        let folder = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents/Scriber")
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    static func save(raw: String, corrected: String, tone: String, language: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        let displayDate = displayFormatter.string(from: Date())

        let filename = "scriber_\(timestamp).md"
        let fileURL = transcriptsFolder.appendingPathComponent(filename)

        var content = "# Scriber — \(displayDate)\n\n"
        content += "**Tone:** \(tone)  \n"
        content += "**Language:** \(language)\n\n"
        content += "---\n\n"
        content += "## Message\n\n"
        content += corrected + "\n\n"
        if raw != corrected {
            content += "## Raw Transcription\n\n"
            content += raw + "\n"
        }

        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
        Log.write("Saved transcript: \(filename)")
    }

    static func openFolder() {
        NSWorkspace.shared.open(transcriptsFolder)
    }
}
