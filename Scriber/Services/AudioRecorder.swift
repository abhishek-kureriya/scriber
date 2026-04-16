import AVFoundation

final class AudioRecorder: ObservableObject {
    @Published var isRecording = false

    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?

    func startRecording() throws {
        // Check mic permission
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { _ in }
            throw RecordingError.micPermissionNeeded
        case .denied, .restricted:
            throw RecordingError.micPermissionDenied
        case .authorized:
            break
        @unknown default:
            break
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("wav")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        let recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder.prepareToRecord()

        guard recorder.record() else {
            throw RecordingError.recordFailed
        }

        audioRecorder = recorder
        recordingURL = url
        isRecording = true
    }

    func stopRecording() -> URL? {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        return recordingURL
    }
}

enum RecordingError: LocalizedError {
    case micPermissionNeeded
    case micPermissionDenied
    case recordFailed
    case noMicrophone

    var errorDescription: String? {
        switch self {
        case .micPermissionNeeded:
            return "Microphone permission needed. Please try again."
        case .micPermissionDenied:
            return "Microphone access denied. Enable in System Settings > Privacy > Microphone."
        case .recordFailed:
            return "Failed to start recording."
        case .noMicrophone:
            return "No microphone detected."
        }
    }
}
