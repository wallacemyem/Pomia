# Pomia

## Apfel server integration

This app can connect to a local Apfel OpenAI-compatible server with support for streaming AI responses.

### Start the server

Run:

```bash
./scripts/start-apfel-server.sh
```

If `apfel` is not installed, install it with Homebrew:

```bash
brew tap Arthur-Ficial/tap
brew install Arthur-Ficial/tap/apfel
```

### App features

- **Real-time streaming responses** - AI responses appear word-by-word as they're generated

### App controls

- `⌘ + Return` — send current message
- `⌘ + K` — focus the message input field
- `⌥ + ⌘ + S` — start the Apfel server from the app
- `⇧ + ⌘ + S` — stop the server from the app
- `Esc` — clear the message input

### Quick replies

The UI includes quick reply suggestion chips for faster prompts.
