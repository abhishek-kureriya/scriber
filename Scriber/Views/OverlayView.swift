import SwiftUI

struct OverlayView: View {
    @ObservedObject var vm: RecordingViewModel
    @ObservedObject var settings: AppSettings
    var onOpenSettings: (() -> Void)?
    var onClose: (() -> Void)?
    @State private var languages: [(identifier: String, name: String)] = TranscriptionService.availableLanguages
    @State private var recordHover = false
    @State private var stopHover = false

    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack(spacing: 8) {
                // App name with gradient
                HStack(spacing: 5) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Text("Scriber")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                Spacer()

                // Status pill
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                    Text(statusLabel)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(statusColor.opacity(0.1))
                .clipShape(Capsule())

                // Settings button
                if let action = onOpenSettings {
                    Button(action: action) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .frame(width: 22, height: 22)
                            .background(Color.primary.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Settings")
                }

                // Close button
                if let close = onClose {
                    Button(action: close) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 22, height: 22)
                            .background(Color.primary.opacity(0.05))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Close")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            // Separator
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .primary.opacity(0.1), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)

            // Content
            Group {
                switch vm.state {
                case .idle:
                    idleView
                case .recording:
                    recordingView
                case .processing:
                    processingView
                case .done, .error:
                    idleView
                        .onAppear { vm.reset() }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Status

    private var statusColor: Color {
        switch vm.state {
        case .idle: return .gray
        case .recording: return .red
        case .processing: return .orange
        case .done: return .green
        case .error: return .yellow
        }
    }

    private var statusLabel: String {
        switch vm.state {
        case .idle: return "Ready"
        case .recording: return "Recording"
        case .processing: return "Processing"
        case .done: return "Done"
        case .error: return "Error"
        }
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 10) {
            // Language + Auto-detect
            HStack(spacing: 6) {
                Image(systemName: "globe")
                    .font(.system(size: 11))
                    .foregroundStyle(.blue.opacity(0.7))
                if settings.autoDetectLanguage {
                    Text("Auto-detect")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(action: {
                        settings.autoDetectLanguage = false
                    }) {
                        Text("Manual")
                            .font(.system(size: 9))
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                } else {
                    Picker("", selection: $settings.selectedLanguage) {
                        ForEach(languages, id: \.identifier) { lang in
                            Text(lang.name).tag(lang.identifier)
                        }
                    }
                    .pickerStyle(.menu)
                    .controlSize(.small)
                    .labelsHidden()
                    Spacer()
                    Button(action: {
                        settings.autoDetectLanguage = true
                    }) {
                        Text("Auto")
                            .font(.system(size: 9))
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Tone selector
            HStack(spacing: 4) {
                ForEach(MessageTone.allCases, id: \.rawValue) { tone in
                    Button(action: { settings.tone = tone }) {
                        HStack(spacing: 3) {
                            Image(systemName: tone.icon)
                                .font(.system(size: 9))
                            Text(tone.label)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(settings.tone == tone
                            ? Color.purple.opacity(0.15)
                            : Color.primary.opacity(0.03))
                        .foregroundStyle(settings.tone == tone ? .purple : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Record button
            Button(action: vm.startRecording) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.3))
                            .frame(width: 20, height: 20)
                        Circle()
                            .fill(.white)
                            .frame(width: 10, height: 10)
                    }
                    Text("Record")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: recordHover ? [.green, .green.opacity(0.8)] : [Color(red: 0.2, green: 0.75, blue: 0.4), Color(red: 0.15, green: 0.65, blue: 0.35)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .green.opacity(0.3), radius: recordHover ? 8 : 4, y: 2)
            }
            .buttonStyle(.plain)
            .onHover { recordHover = $0 }
            .scaleEffect(recordHover ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: recordHover)

            Text("Speak naturally, AI writes the message")
                .font(.system(size: 9, design: .rounded))
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Recording

    private var recordingView: some View {
        VStack(spacing: 12) {
            // Waveform + timer
            HStack(spacing: 10) {
                HStack(spacing: 3) {
                    ForEach(0..<7, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [.red, .orange],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(width: 3, height: barHeight(for: i))
                    }
                }
                .frame(height: 24)

                Text(vm.formattedDuration)
                    .font(.system(size: 24, weight: .ultraLight, design: .monospaced))
                    .foregroundStyle(.primary)

                Spacer()

                // Pulsing dot
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                    .opacity(pulseDotOpacity)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: vm.duration)
            }

            // Stop button
            Button(action: vm.stopAndProcess) {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.white)
                        .frame(width: 12, height: 12)
                    Text("Stop")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: stopHover ? [.red, .red.opacity(0.8)] : [Color(red: 0.85, green: 0.2, blue: 0.2), Color(red: 0.75, green: 0.15, blue: 0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .red.opacity(0.3), radius: stopHover ? 8 : 4, y: 2)
            }
            .buttonStyle(.plain)
            .onHover { stopHover = $0 }
            .scaleEffect(stopHover ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: stopHover)
        }
    }

    private var pulseDotOpacity: Double {
        Int(vm.duration * 2) % 2 == 0 ? 1.0 : 0.3
    }

    private func barHeight(for i: Int) -> CGFloat {
        let phase = sin(vm.duration * 3.5 + Double(i) * 0.8)
        return 6 + 16 * CGFloat((phase + 1) / 2)
    }

    // MARK: - Processing

    private var processingView: some View {
        VStack(spacing: 10) {
            // Animated dots
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 8, height: 8)
                        .opacity(processingDotOpacity(for: i))
                }
            }

            VStack(spacing: 2) {
                Text("Transcribing...")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                if settings.isAPIConfigured && settings.autoSummarize {
                    Text("AI is polishing your message")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    private func processingDotOpacity(for index: Int) -> Double {
        let t = Date().timeIntervalSinceReferenceDate
        let phase = sin(t * 3.0 + Double(index) * 1.2)
        return 0.3 + 0.7 * (phase + 1) / 2
    }
}
