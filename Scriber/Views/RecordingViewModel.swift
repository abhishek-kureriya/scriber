import SwiftUI
import AppKit

class RecordingViewModel: ObservableObject {
    enum State {
        case idle
        case recording
        case processing
        case done(String)
        case error(String)
    }

    @Published var state: State = .idle
    @Published var duration: TimeInterval = 0

    let settings: AppSettings
    var onDone: ((String) -> Void)?

    private let recorder = AudioRecorder()
    private let transcriptionService = TranscriptionService()
    private let grammarService = GrammarService()
    private var timer: Timer?

    init(settings: AppSettings) {
        self.settings = settings
    }

    var formattedDuration: String {
        let m = Int(duration) / 60
        let s = Int(duration) % 60
        return String(format: "%02d:%02d", m, s)
    }

    func startRecording() {
        do {
            try recorder.startRecording()
            state = .recording
            duration = 0
            if settings.soundFeedback { NSSound(named: "Tink")?.play() }
            Log.write("Recording started")
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                DispatchQueue.main.async { self?.duration += 0.1 }
            }
        } catch {
            Log.write("Record error: \(error)")
            state = .error(error.localizedDescription)
        }
    }

    func stopAndProcess() {
        timer?.invalidate()
        timer = nil
        if settings.soundFeedback { NSSound(named: "Pop")?.play() }

        guard let fileURL = recorder.stopRecording() else {
            state = .error("No recording file.")
            return
        }

        state = .processing
        Log.write("Processing...")

        let useAutoDetect = settings.autoDetectLanguage
        let lang = settings.selectedLanguage
        let tone = settings.tone
        let config = GrammarService.APIConfig(
            baseURL: settings.apiBaseURL,
            apiKey: settings.apiKey,
            model: settings.apiModel
        )

        Task {
            do {
                let raw: String
                if useAutoDetect {
                    Log.write("Transcribing (auto-detect)...")
                    raw = try await transcriptionService.transcribeAutoDetect(fileURL: fileURL)
                } else {
                    Log.write("Transcribing (lang: \(lang))...")
                    raw = try await transcriptionService.transcribe(fileURL: fileURL, language: lang)
                }
                Log.write("Transcribed: \(raw.prefix(80))")

                guard !raw.isEmpty else {
                    await MainActor.run { state = .error("No speech detected.") }
                    return
                }

                let finalText: String
                if settings.isAPIConfigured && settings.autoSummarize {
                    Log.write("Rewriting (tone: \(tone.label))...")
                    finalText = try await grammarService.correct(
                        text: raw,
                        config: config,
                        tone: tone,
                        identity: settings.aiIdentity,
                        customInstructions: settings.customInstructions
                    )
                    Log.write("Result: \(finalText.prefix(80))")
                } else {
                    finalText = raw
                }

                await MainActor.run {
                    // Save to file if enabled
                    if settings.exportToFile {
                        TranscriptExporter.save(
                            raw: raw,
                            corrected: finalText,
                            tone: tone.label,
                            language: useAutoDetect ? "Auto-detect" : lang
                        )
                    }

                    state = .done(finalText)
                    onDone?(finalText)
                }

                // Clean up audio file
                try? FileManager.default.removeItem(at: fileURL)
            } catch {
                Log.write("Error: \(error)")
                await MainActor.run { state = .error(error.localizedDescription) }
            }
        }
    }

    func reset() {
        state = .idle
        duration = 0
    }
}
