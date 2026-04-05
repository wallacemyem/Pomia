# Pomia

Pomia is a macOS chat app that connects to a local Apfel server for Apple Intelligence-powered conversations. It provides streaming AI responses, quick reply prompts, keyboard shortcuts, and built-in server control.

## Features

- Native macOS SwiftUI app
- Local Apfel server integration for OpenAI-compatible AI chat
- Streaming response rendering for a fluid conversational experience
- Quick reply suggestions for prompt templates
- Built-in server start/stop controls and status display
- Theme picker for fast UI customization
- Keyboard shortcuts for productivity

## Requirements

- macOS 14 or later
- Xcode 15 or later
- Homebrew (recommended for installing `apfel`)
- `apfel` command-line tool

## Install and run locally

1. Clone the repo:

```bash
git clone https://github.com/<your-org>/Pomia.git
cd Pomia
```

2. Install Apfel if needed:

```bash
brew tap Arthur-Ficial/tap
brew install Arthur-Ficial/tap/apfel
```

3. Start the Apfel server:

```bash
./scripts/start-apfel-server.sh
```

4. Open `Pomia.xcodeproj` in Xcode and run the `Pomia` scheme.

## Usage

- `⌘ + Return` — send current message
- `⌘ + K` — focus the message input field
- `⌥ + ⌘ + S` — start the Apfel server from the app
- `⇧ + ⌘ + S` — stop the Apfel server from the app
- `Esc` — clear the message input

## Release build and DMG packaging

This repository includes a GitHub Actions workflow at `.github/workflows/release-dmg.yml` that builds the app and packages it as a DMG when a tag is pushed.

### Release workflow

- Push a version tag like `v1.0.0`
- GitHub Actions builds the app on `macos-latest`
- A DMG is created and attached to the GitHub release

### Example

```bash
git tag v1.0.0
git push origin v1.0.0
```

## Contributing

- Open Xcode and work on the `Pomia` scheme
- Add UI improvements, theme options, or AI prompt helpers
- Send a PR with your changes

## Notes

- The app expects the Apfel server to be reachable at `http://127.0.0.1:11434`
- The `scripts/start-apfel-server.sh` helper script starts Apfel with `--cors --no-origin-check`
