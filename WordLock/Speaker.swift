import AVFoundation

/// Озвучка слов системным синтезатором речи (бесплатно и офлайн).
final class Speaker {
    static let shared = Speaker()
    private let synthesizer = AVSpeechSynthesizer()
    private var sessionReady = false

    func speak(_ text: String, accent: String) {
        if !sessionReady {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try? AVAudioSession.sharedInstance().setActive(true)
            sessionReady = true
        }
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: accent)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        synthesizer.speak(utterance)
    }
}
