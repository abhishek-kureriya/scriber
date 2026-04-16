import Speech

final class TranscriptionService {

    static var availableLanguages: [(identifier: String, name: String)] {
        SFSpeechRecognizer.supportedLocales()
            .map { locale in
                // Normalize to hyphen format (en-US) for consistency
                let id = locale.identifier.replacingOccurrences(of: "_", with: "-")
                let name = Locale.current.localizedString(forIdentifier: locale.identifier) ?? id
                return (identifier: id, name: name)
            }
            .sorted { $0.name < $1.name }
    }

    static func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    func transcribeAutoDetect(fileURL: URL) async throws -> String {
        // Use default recognizer (system language, handles auto-detection)
        guard let recognizer = SFSpeechRecognizer() else {
            throw TranscriptionError.recognizerUnavailable
        }

        guard recognizer.isAvailable else {
            throw TranscriptionError.recognizerUnavailable
        }

        let request = SFSpeechURLRecognitionRequest(url: fileURL)
        request.shouldReportPartialResults = false
        request.taskHint = .dictation
        request.addsPunctuation = true

        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                if let result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }

    func transcribe(fileURL: URL, language: String) async throws -> String {
        let locale = Locale(identifier: language)
        guard let recognizer = SFSpeechRecognizer(locale: locale) else {
            throw TranscriptionError.languageNotSupported
        }

        guard recognizer.isAvailable else {
            throw TranscriptionError.recognizerUnavailable
        }

        // Use on-device recognition if available (better accent handling, more private)
        if recognizer.supportsOnDeviceRecognition {
            recognizer.defaultTaskHint = .dictation
        }

        let request = SFSpeechURLRecognitionRequest(url: fileURL)
        request.shouldReportPartialResults = false
        request.taskHint = .dictation
        request.addsPunctuation = true

        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                if let result, result.isFinal {
                    continuation.resume(returning: result.bestTranscription.formattedString)
                }
            }
        }
    }
}

enum TranscriptionError: LocalizedError {
    case languageNotSupported
    case recognizerUnavailable

    var errorDescription: String? {
        switch self {
        case .languageNotSupported:
            return "The selected language is not supported for speech recognition."
        case .recognizerUnavailable:
            return "Speech recognizer is currently unavailable. Please try again."
        }
    }
}
