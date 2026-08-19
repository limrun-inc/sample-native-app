@preconcurrency import AVFoundation
import Combine
import SwiftUI

struct CameraRecorderView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recorder = CameraRecorder()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            CameraPreview(session: recorder.session)
                .ignoresSafeArea()

            LinearGradient(
                colors: [.black.opacity(0.55), .clear, .black.opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Spacer()

                if let message = recorder.message {
                    statusCard(message)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                }

                controls
            }
        }
        .task {
            await recorder.prepare()
        }
        .onDisappear {
            recorder.shutdown()
        }
        .statusBarHidden()
    }

    private var header: some View {
        HStack {
            Button {
                if recorder.isRecording {
                    recorder.stopRecording()
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.4), in: Circle())
                    .foregroundStyle(.white)
            }
            .accessibilityLabel("Close camera")

            Spacer()

            if recorder.isRecording {
                HStack(spacing: 8) {
                    Circle()
                        .fill(.red)
                        .frame(width: 9, height: 9)
                    Text(recorder.formattedDuration)
                        .font(.system(.subheadline, design: .monospaced, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.black.opacity(0.45), in: Capsule())
            }

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private var controls: some View {
        VStack(spacing: 24) {
            WaveformView(levels: recorder.audioLevels, isActive: recorder.isRecording)
                .frame(height: 64)
                .padding(.horizontal, 28)
                .accessibilityLabel(recorder.isRecording ? "Live microphone level" : "Microphone waveform")

            Button {
                recorder.toggleRecording()
            } label: {
                ZStack {
                    Circle()
                        .stroke(.white, lineWidth: 5)
                        .frame(width: 78, height: 78)

                    RoundedRectangle(cornerRadius: recorder.isRecording ? 8 : 30)
                        .fill(.red)
                        .frame(
                            width: recorder.isRecording ? 32 : 62,
                            height: recorder.isRecording ? 32 : 62
                        )
                }
                .animation(.easeInOut(duration: 0.2), value: recorder.isRecording)
            }
            .disabled(!recorder.isReady)
            .opacity(recorder.isReady ? 1 : 0.45)
            .accessibilityIdentifier("recordButton")
            .accessibilityLabel(recorder.isRecording ? "Stop recording" : "Start recording")

            Text(recorder.isRecording ? "Tap to stop" : "Tap to record")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.75))
        }
        .padding(.top, 24)
        .padding(.bottom, 34)
        .background(.ultraThinMaterial.opacity(0.65))
    }

    private func statusCard(_ message: String) -> some View {
        Label(message, systemImage: recorder.messageIsError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 14))
            .multilineTextAlignment(.center)
    }
}

private struct WaveformView: View {
    let levels: [CGFloat]
    let isActive: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(Array(levels.enumerated()), id: \.offset) { index, level in
                Capsule()
                    .fill(
                        isActive
                            ? Color(hue: 0.96 - (Double(index) / Double(levels.count) * 0.08), saturation: 0.72, brightness: 1)
                            : .white.opacity(0.32)
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: max(4, level * 58))
                    .animation(.linear(duration: 0.08), value: level)
            }
        }
    }
}

private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.session = session
    }
}

private final class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}

@MainActor
private final class CameraRecorder: NSObject, ObservableObject {
    let session = AVCaptureSession()

    @Published var isReady = false
    @Published var isRecording = false
    @Published var audioLevels = Array(repeating: CGFloat(0.08), count: 36)
    @Published var duration = 0
    @Published var message: String?
    @Published var messageIsError = false

    private let movieOutput = AVCaptureMovieFileOutput()
    private let audioOutput = AVCaptureAudioDataOutput()
    private let audioQueue = DispatchQueue(label: "com.limrun.sample-native.audio-meter")
    private let sessionQueue = DispatchQueue(label: "com.limrun.sample-native.capture-session")
    private var durationTask: Task<Void, Never>?
    private var lastMeterUpdate = Date.distantPast
    private var isConfigured = false

    var formattedDuration: String {
        String(format: "%02d:%02d", duration / 60, duration % 60)
    }

    func prepare() async {
        guard !isConfigured else {
            startSession()
            return
        }

        setMessage("Requesting camera and microphone access…")
        async let cameraAccess = requestAccess(for: .video)
        async let microphoneAccess = requestAccess(for: .audio)
        let permissions = await (cameraAccess, microphoneAccess)

        guard permissions.0, permissions.1 else {
            setMessage(
                "Camera and microphone access are required. Enable them in Settings.",
                isError: true
            )
            return
        }

        do {
            try configureSession()
            isConfigured = true
            isReady = true
            setMessage(nil)
            startSession()
        } catch {
            setMessage(error.localizedDescription, isError: true)
        }
    }

    func toggleRecording() {
        isRecording ? stopRecording() : startRecording()
    }

    func stopRecording() {
        guard movieOutput.isRecording else { return }
        movieOutput.stopRecording()
        durationTask?.cancel()
        durationTask = nil
    }

    func shutdown() {
        if movieOutput.isRecording {
            movieOutput.stopRecording()
        }
        durationTask?.cancel()
        durationTask = nil

        let session = session
        sessionQueue.async {
            if session.isRunning {
                session.stopRunning()
            }
        }
    }

    private func requestAccess(for mediaType: AVMediaType) async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: mediaType)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }

    private func configureSession() throws {
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .high

        guard let camera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) ?? AVCaptureDevice.default(for: .video) else {
            throw RecorderError.cameraUnavailable
        }

        guard let microphone = AVCaptureDevice.default(for: .audio) else {
            throw RecorderError.microphoneUnavailable
        }

        let cameraInput = try AVCaptureDeviceInput(device: camera)
        let microphoneInput = try AVCaptureDeviceInput(device: microphone)

        guard session.canAddInput(cameraInput), session.canAddInput(microphoneInput) else {
            throw RecorderError.cannotConfigureInputs
        }
        session.addInput(cameraInput)
        session.addInput(microphoneInput)

        guard session.canAddOutput(movieOutput), session.canAddOutput(audioOutput) else {
            throw RecorderError.cannotConfigureOutputs
        }
        session.addOutput(movieOutput)
        session.addOutput(audioOutput)

        audioOutput.setSampleBufferDelegate(self, queue: audioQueue)

        if let connection = movieOutput.connection(with: .video) {
            connection.preferredVideoStabilizationMode = .auto
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
        }
    }

    private func startSession() {
        let session = session
        sessionQueue.async {
            if !session.isRunning {
                session.startRunning()
            }
        }
    }

    private func startRecording() {
        guard isReady, !movieOutput.isRecording else { return }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("video-\(UUID().uuidString)")
            .appendingPathExtension("mov")

        duration = 0
        setMessage(nil)
        isRecording = true
        movieOutput.startRecording(to: outputURL, recordingDelegate: self)

        durationTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                self?.duration += 1
            }
        }
    }

    private func saveToDocuments(_ url: URL) {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destination = documents.appendingPathComponent(url.lastPathComponent)
        do {
            // A prior recording with the same name would block the move; the
            // UUID name makes a clash unlikely, but overwrite to be safe.
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.moveItem(at: url, to: destination)
            // Path relative to the app's data container, ready to hand to
            // `lim ios pull-file Documents/<name> --bundle-id <id> --container-type data`.
            let relative = "Documents/\(destination.lastPathComponent)"
            print("Recording saved to \(relative) (\(destination.path))")
            setMessage("Saved to \(relative)")
        } catch {
            setMessage(error.localizedDescription, isError: true)
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func setMessage(_ text: String?, isError: Bool = false) {
        message = text
        messageIsError = isError
    }
}

extension CameraRecorder: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        Task { @MainActor [weak self] in
            self?.isRecording = false
            self?.durationTask?.cancel()
            self?.durationTask = nil

            if let error {
                self?.setMessage(error.localizedDescription, isError: true)
                try? FileManager.default.removeItem(at: outputFileURL)
            } else {
                self?.saveToDocuments(outputFileURL)
            }
        }
    }
}

extension CameraRecorder: AVCaptureAudioDataOutputSampleBufferDelegate {
    nonisolated func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard
            let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer),
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer),
            let audioFormat = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)?.pointee
        else { return }

        var length = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        let status = CMBlockBufferGetDataPointer(
            dataBuffer,
            atOffset: 0,
            lengthAtOffsetOut: nil,
            totalLengthOut: &length,
            dataPointerOut: &dataPointer
        )
        guard status == kCMBlockBufferNoErr, let dataPointer else { return }

        let rawPointer = UnsafeRawPointer(dataPointer)
        let rms: Double
        if audioFormat.mFormatFlags & kAudioFormatFlagIsFloat != 0,
           audioFormat.mBitsPerChannel == 32 {
            let sampleCount = length / MemoryLayout<Float>.size
            guard sampleCount > 0 else { return }
            let samples = rawPointer.bindMemory(to: Float.self, capacity: sampleCount)
            var sum = 0.0
            for index in 0..<sampleCount {
                let sample = Double(samples[index])
                sum += sample * sample
            }
            rms = sqrt(sum / Double(sampleCount))
        } else if audioFormat.mBitsPerChannel == 16 {
            let sampleCount = length / MemoryLayout<Int16>.size
            guard sampleCount > 0 else { return }
            let samples = rawPointer.bindMemory(to: Int16.self, capacity: sampleCount)
            var sum = 0.0
            for index in 0..<sampleCount {
                let sample = Double(samples[index]) / Double(Int16.max)
                sum += sample * sample
            }
            rms = sqrt(sum / Double(sampleCount))
        } else {
            return
        }

        let decibels = 20 * log10(max(rms, 0.000_001))
        let normalizedLevel = CGFloat(max(0.05, min(1, (decibels + 50) / 50)))

        Task { @MainActor [weak self] in
            guard let self, self.isRecording else { return }
            guard Date().timeIntervalSince(self.lastMeterUpdate) > 0.06 else { return }
            self.lastMeterUpdate = Date()
            self.audioLevels.removeFirst()
            self.audioLevels.append(normalizedLevel)
        }
    }
}

private enum RecorderError: LocalizedError {
    case cameraUnavailable
    case microphoneUnavailable
    case cannotConfigureInputs
    case cannotConfigureOutputs

    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            "No camera is available on this device."
        case .microphoneUnavailable:
            "No microphone is available on this device."
        case .cannotConfigureInputs:
            "The camera and microphone could not be configured."
        case .cannotConfigureOutputs:
            "Video recording could not be configured."
        }
    }
}
