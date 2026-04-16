# Scriber

**Speak naturally. Let AI write the message.**

Scriber is a native macOS menu bar app that turns your voice into polished, ready-to-send messages. Speak rough notes or fragments — the AI understands your intent and types a clean, natural message directly into whatever app you're working in.

---

## Why Scriber?

### The Problem
- Typing messages takes time, especially during meetings or multitasking
- Non-native English speakers spend extra time crafting grammatically correct messages
- Quick Slack/email messages often come out rough, unclear, or unprofessional

### How Scriber Helps

| Pain Point | How Scriber Helps |
|------------|-------------------|
| Slow typing for quick updates | Speak for 5 seconds instead of typing for 30 |
| Grammar/spelling issues | AI auto-corrects before it's sent |
| Switching between apps | Speak from wherever your cursor is — Notes, Slack, email, Jira |
| Meeting multitasking | Cmd+Shift+R, speak your update, it types itself |
| Non-native English speakers | Speak rough fragments, get polished English output |
| Tone mismatches | Casual for Slack, Formal for client emails — one toggle |

### Real Examples

| You Say | What Gets Typed (Professional) |
|---------|-------------------------------|
| "meeting moved to 3 tell the team" | Hey team, just a heads up — the meeting has been moved to 3 PM. |
| "deployed the fix looks good now" | Deployed the fix, and it's looking good now. |
| "taking friday off kids school event" | I'll be taking Friday off for my kid's school event. |
| "code review done looks good ship it" | Code review is done, looks good — let's ship it. |

### Why Not Just macOS Dictation?

- macOS Dictation gives raw speech — no grammar fix, no tone, no intent understanding
- Scriber understands fragments and writes complete natural messages
- Tone selector means one tool for casual Slack and formal emails
- Auto-pastes directly into the app you're working in

---

## Features

### Voice to Text with AI
- Record your voice and Scriber transcribes it on-device using Apple Speech Recognition
- AI rewrites the transcription into a clean, natural message
- Text is auto-pasted into the app where your cursor was (Slack, Notes, email, etc.)

### Global Hotkey — Cmd+Shift+R
- Press **Cmd+Shift+R** from any app to start recording
- Press **Cmd+Shift+R** again to stop and type
- No need to click the menu bar — works from anywhere
- Menu bar icon turns red while recording

### Tone Selector
Switch between three tones with one click:

| Tone | Style | Best For |
|------|-------|----------|
| **Casual** | Friendly, uses contractions, conversational | Slack messages, team chat |
| **Professional** | Clean, natural, balanced | General communication |
| **Formal** | No contractions, structured, respectful | Client emails, official docs |

### Auto-detect Language
- Enabled by default — just speak and Scriber figures out the language
- Supports 50+ languages via Apple Speech Recognition
- Switch to manual language selection anytime

### Multi-language Support
- 50+ languages supported for transcription
- Manual language picker available when auto-detect is off
- AI grammar correction works with any language input

### Settings & Permissions
- **Permissions dashboard** — see status of Microphone, Speech Recognition, Accessibility
- **API Gateway** — configure your OpenAI-compatible API with connection test
- **Slack webhook** — post messages directly to Slack channels

---

## Quick Start

### 1. Install & Launch
Scriber appears as a mic icon in your menu bar.

### 2. Grant Permissions
On first launch, grant:
- **Microphone** — to record your voice
- **Speech Recognition** — for on-device transcription
- **Accessibility** — to type text into other apps

### 3. Configure AI (Optional)
Right-click mic icon → Settings:
- Enter your OpenAI-compatible API base URL and key
- Choose your model
- Enable "Auto-correct grammar with AI"

Without AI configured, Scriber still works — it pastes the raw transcription.

### 4. Start Using

**Option A — Menu Bar:**
1. Place your cursor in any app (Slack, Notes, email)
2. Click the mic icon in the menu bar
3. Pick your tone (Casual / Professional / Formal)
4. Click **Record**, speak, click **Stop & Type**
5. Text appears where your cursor was

**Option B — Keyboard Shortcut:**
1. Place your cursor in any app
2. Press **Cmd+Shift+R** to start recording
3. Speak naturally
4. Press **Cmd+Shift+R** again to stop
5. Text appears where your cursor was

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| **Cmd+Shift+R** | Start / Stop recording (global — works from any app) |
| **Left-click** mic icon | Open recording popover |
| **Right-click** mic icon | Settings, Quit menu |

---

## Menu Bar Controls

| Action | What Happens |
|--------|-------------|
| Left-click mic icon | Opens the recording popover |
| Right-click mic icon | Shows menu: Settings, Hotkey reminder, Quit |
| Gear icon in popover | Opens Settings window |
| X icon in popover | Closes the popover |

---

## Architecture (For Developers)

- **Native macOS** — built with Swift & SwiftUI, no Electron
- **On-device transcription** — Apple Speech framework, private, no audio sent to cloud
- **AI rewriting** — OpenAI-compatible API (configurable gateway & model)
- **Auto-paste** — CGEvent-based keyboard simulation
- **Lightweight** — menu bar app, no dock icon, minimal resources

---

*Built with Swift, SwiftUI, Apple Speech Framework, and OpenAI-compatible API.*
