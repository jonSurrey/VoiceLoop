# iOS Voice Assistant – Take-Home Assignment

A small iOS app that records your voice, transcribes it using OpenAI’s Whisper, sends it to GPT-4o-mini, and speaks the reply back to you.  
Built for a take-home test.

## What It Does

- 🎙 Records voice using `AVAudioRecorder`
- ✍️ Transcribes with OpenAI Whisper
- 💬 Gets smart replies from GPT-4o-mini
- 🔊 Reads them out loud with text-to-speech
- 🧩 Uses MVVM + dependency injection
- 🧠 Keeps code testable with protocols
- 🎨 Simple SwiftUI chat-style interface

## Requirements

- Xcode 15+
- iOS 17+
- Swift 5.9+
- OpenAI API key

## How to Run

1. Open the project in Xcode  
2. Go to `Info.plist` → look for `OpenAIAPIKey`  
3. Add your key, e.g.:

   ```xml
   <key>OpenAIAPIKey</key>
   <string>sk-proj-your-key-here</string>
   ```

4. Build and Run it
5. Tap and hold the mic button to record, then let go to send

## How It’s Structured

I went with a basic MVVM setup:

```
Views (SwiftUI)
↓
ViewModel (handles state)
↓
Services (audio, transcription, chat, TTS)
↓
APIClient (network layer)
↓
Models
```

Each service does one thing and talks to the network layer through protocols, so it’s easy to test or swap things out later.

## Project Layout

```
Luzia-Home-Test/
├── Models/
├── Services/
├── ViewModels/
├── Views/
├── Configuration/
└── Info.plist
```

## Permissions

Only asks for microphone access (`NSMicrophoneUsageDescription`) when you first try to record.

## If I Had More Time...

- Save chat history
- Add offline mode
- Better UI
- UI tests

## Known Issues

- Simulator sometimes has trouble uploading audio — works fine on device
- Occasional network drop errors (`-1005`) in simulator
- Had problems with the GPT API responses, with exceeding limits error. For that, I added a debug flag which simulates the API response
