//
//  ContentView.swift
//  Pomia
//
//  Created by Wallace Aboiyar on 04/04/2026.
//

import SwiftUI
import Foundation
import AppKit

enum ApfelServerStatus: String {
    case checking = "Checking…"
    case running = "Running"
    case stopped = "Stopped"
    case unavailable = "Unavailable"

    var labelColor: Color {
        switch self {
        case .running: return .green
        case .checking: return .orange
        case .stopped: return .yellow
        case .unavailable: return .red
        }
    }
}

enum NotificationSeverity {
    case success, warning, error

    var background: Color {
        switch self {
        case .success: return Color.green.opacity(0.88)
        case .warning: return Color.orange.opacity(0.90)
        case .error: return Color.red.opacity(0.92)
        }
    }

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }
}

struct NotificationBanner: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let severity: NotificationSeverity
}

extension Notification.Name {
    static let pomiaSendMessage = Notification.Name("pomiasendmessage")
    static let pomiaFocusInput = Notification.Name("pomiafocusinput")
    static let pomiaStartServer = Notification.Name("pomiastartserver")
}

struct Message: Identifiable {
    let id: UUID
    let text: String
    let isUser: Bool

    init(text: String, isUser: Bool, id: UUID = UUID()) {
        self.id = id
        self.text = text
        self.isUser = isUser
    }
}

struct ColorTheme: Identifiable {
    let id: String
    let name: String
    let accent: Color
    let messageBackground: Color
    let messageForeground: Color
    let bubbleBackground: Color
    let toolbarBackground: Color
    let inputBackground: Color
    let pageGradient: LinearGradient

    static let ocean = ColorTheme(
        id: "ocean",
        name: "Ocean",
        accent: Color(red: 0.10, green: 0.58, blue: 0.89),
        messageBackground: Color(red: 0.14, green: 0.19, blue: 0.28).opacity(0.9),
        messageForeground: .white,
        bubbleBackground: Color(red: 0.11, green: 0.16, blue: 0.27).opacity(0.9),
        toolbarBackground: Color.white.opacity(0.09),
        inputBackground: Color.white.opacity(0.10),
        pageGradient: LinearGradient(
            colors: [Color(red: 0.05, green: 0.11, blue: 0.21), Color(red: 0.08, green: 0.21, blue: 0.38)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )

    static let sage = ColorTheme(
        id: "sage",
        name: "Sage",
        accent: Color(red: 0.30, green: 0.58, blue: 0.38),
        messageBackground: Color(red: 0.92, green: 0.95, blue: 0.92),
        messageForeground: Color(red: 0.13, green: 0.18, blue: 0.14),
        bubbleBackground: Color(red: 0.98, green: 0.98, blue: 0.96),
        toolbarBackground: Color.white.opacity(0.75),
        inputBackground: Color.white.opacity(0.92),
        pageGradient: LinearGradient(
            colors: [Color(red: 0.96, green: 0.98, blue: 0.96), Color(red: 0.82, green: 0.89, blue: 0.84)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )

    static let twilight = ColorTheme(
        id: "twilight",
        name: "Twilight",
        accent: Color(red: 0.76, green: 0.43, blue: 0.85),
        messageBackground: Color(red: 0.10, green: 0.08, blue: 0.16).opacity(0.95),
        messageForeground: .white,
        bubbleBackground: Color(red: 0.17, green: 0.12, blue: 0.28).opacity(0.95),
        toolbarBackground: Color.white.opacity(0.08),
        inputBackground: Color.white.opacity(0.08),
        pageGradient: LinearGradient(
            colors: [Color(red: 0.07, green: 0.05, blue: 0.12), Color(red: 0.25, green: 0.15, blue: 0.38)],
            startPoint: .top,
            endPoint: .bottomTrailing
        )
    )

    static let themes = [ocean, twilight]
    static let `default` = ocean
}

struct ContentView: View {
    @AppStorage("selectedThemeID") private var selectedThemeID = ColorTheme.default.id
    @State private var messages: [Message] = []
    @State private var inputText = ""
    @State private var isTyping = false
    @State private var serverStatus: ApfelServerStatus = .checking
    @State private var serverProcess: Process?
    @State private var isStartingServer = false
    @FocusState private var inputFocused: Bool

    private let apfelClient = ApfelClient()
    private let quickReplies = [
        "Summarize this conversation.",
        "What would be the best next step?",
        "Make this answer shorter.",
        "Explain this in plain language.",
    ]

    private var theme: ColorTheme {
        ColorTheme.themes.first(where: { $0.id == selectedThemeID }) ?? .default
    }

    @State private var banner: NotificationBanner?
    @State private var scrollTargetMessageID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            if let banner {
                bannerView(banner)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            VStack(spacing: 12) {
                header
                suggestionsView
                messageList
                inputArea
            }
            .frame(minWidth: 460, minHeight: 580)
            .background(theme.pageGradient.ignoresSafeArea())
        }
        .onAppear {
            Task {
                await refreshServerStatus()
                inputFocused = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .pomiaSendMessage)) { _ in
            sendMessage()
        }
        .onReceive(NotificationCenter.default.publisher(for: .pomiaFocusInput)) { _ in
            inputFocused = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .pomiaStartServer)) { _ in
            Task { await startOrRestartServer() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Pomia")
                        .font(.title2.weight(.bold))
                        .foregroundColor(theme.messageForeground)
                    Text("Apple Intelligence chat with quick suggestions and server control.")
                        .font(.subheadline)
                        .foregroundColor(theme.messageForeground.opacity(0.85))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 10) {
                    statusBadge
                    if serverStatus != .running {
                        Button(action: { Task { await startOrRestartServer() } }) {
                            Text(isStartingServer ? "Starting…" : "Start Apfel Server")
                                .frame(minWidth: 146)
                        }
                        .keyboardShortcut("s", modifiers: [.command, .option])
                        .disabled(isStartingServer)
                    } else {
                        Button(action: { stopServer() }) {
                            Text("Stop Server")
                                .frame(minWidth: 146)
                        }
                        .keyboardShortcut("s", modifiers: [.command, .shift])
                    }
                }
                .buttonStyle(.borderedProminent)
            }

            HStack(spacing: 16) {
                Picker("Theme", selection: $selectedThemeID) {
                    ForEach(ColorTheme.themes) { theme in
                        Text(theme.name).tag(theme.id)
                    }
                }
                .pickerStyle(.segmented)
                .tint(theme.accent)
                .frame(maxWidth: 360)

                Spacer(minLength: 0)
            }
        }
        .padding(18)
        .background(theme.toolbarBackground)
        .cornerRadius(22)
        .padding(.horizontal, 16)
    }

    private var statusBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(serverStatus.labelColor)
                .frame(width: 10, height: 10)
            Text("Apfel: \(serverStatus.rawValue)")
                .font(.footnote.weight(.semibold))
        }
        .foregroundColor(.white)
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.black.opacity(0.25))
        .clipShape(Capsule())
    }

    private var suggestionsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(quickReplies, id: \ .self) { reply in
                    Button(action: {
                        inputText = reply
                        sendMessage()
                    }) {
                        Text(reply)
                            .font(.footnote)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(theme.inputBackground.opacity(0.95))
                            .foregroundColor(theme.messageForeground)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }

    private var messageList: some View {
        ScrollView {
            ScrollViewReader { scrollView in
                VStack(spacing: 14) {
                    ForEach(messages) { message in
                        MessageRow(message: message, theme: theme)
                            .id(message.id)
                            .transition(message.isUser ? .move(edge: .trailing).combined(with: .opacity) : .move(edge: .leading).combined(with: .opacity))
                    }

                    if isTyping {
                        typingIndicator
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(18)
                .onChange(of: messages.count) { _ in
                    if let lastMessage = messages.last {
                        withAnimation(.easeOut(duration: 0.35)) {
                            scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: scrollTargetMessageID) { targetID in
                    if let targetID {
                        withAnimation(.easeOut(duration: 0.2)) {
                            scrollView.scrollTo(targetID, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .background(theme.messageBackground)
        .cornerRadius(24)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private var typingIndicator: some View {
        HStack(spacing: 10) {
            ProgressView()
                .scaleEffect(0.75, anchor: .center)
            Text("Pomia is thinking...")
                .font(.footnote)
                .foregroundColor(theme.messageForeground.opacity(0.8))
            Spacer()
        }
        .padding(12)
        .background(theme.inputBackground)
        .cornerRadius(16)
        .padding(.horizontal, 18)
    }

    private var inputArea: some View {
        HStack(spacing: 12) {
            TextField("Type your message...", text: $inputText)
                .textFieldStyle(.plain)
                .padding(14)
                .background(theme.inputBackground)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.accent.opacity(0.25), lineWidth: 1)
                )
                .foregroundColor(theme.messageForeground)
                .accessibilityLabel("Message input field")
                .focused($inputFocused)
                .onSubmit {
                    sendMessage()
                }

            if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button(action: { inputText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .keyboardShortcut(.escape)
                .help("Clear message")
            }

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .resizable()
                    .frame(width: 34, height: 34)
                    .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? theme.accent.opacity(0.5) : theme.accent)
                    .scaleEffect(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 1.0 : 1.02)
            }
            .buttonStyle(.plain)
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .keyboardShortcut(.return, modifiers: [.command])
            .accessibilityLabel("Send message")
        }
        .padding(16)
        .background(theme.toolbarBackground)
        .cornerRadius(24)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private func sendMessage() {

        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            messages.append(Message(text: trimmedText, isUser: true))
        }
        inputText = ""
        inputFocused = true
        isTyping = true

        Task {
            await fetchAIReply()
        }
    }

    private func fetchAIReply() async {
        let apiMessages = messages.map { message in
            ApfelChatMessage(role: message.isUser ? "user" : "assistant", content: message.text)
        }

        // Add empty AI message that will be updated as we stream
        let placeholderMessage = Message(text: "", isUser: false)
        await MainActor.run {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                messages.append(placeholderMessage)
            }
        }

        do {
            var fullResponse = ""
            try await apfelClient.sendChatStream(messages: apiMessages) { chunk in
                fullResponse += chunk
                Task { @MainActor in
                    if let lastIndex = messages.lastIndex(where: { $0.id == placeholderMessage.id }) {
                        messages[lastIndex] = Message(text: fullResponse, isUser: false, id: placeholderMessage.id)
                    }
                    scrollTargetMessageID = nil
                    scrollTargetMessageID = placeholderMessage.id
                }
            }
        } catch {
            let message = "Unable to reach Apfel. Start the server or run ./scripts/start-apfel-server.sh."
            await MainActor.run {
                withAnimation {
                    if let lastIndex = messages.lastIndex(where: { $0.id == placeholderMessage.id }) {
                        messages[lastIndex] = Message(text: message, isUser: false, id: placeholderMessage.id)
                    }
                }
            }
            serverStatus = .stopped
            showNotification(title: "Server error", message: message, severity: .error)
        }
        isTyping = false
    }

    private func refreshServerStatus() async {
        do {
            let reachable = try await apfelClient.checkHealth()
            if reachable {
                serverStatus = .running
            } else {
                serverStatus = .stopped
                showNotification(title: "Apfel server stopped", message: "Apfel is not responding. Start the server to continue.", severity: .warning)
            }
        } catch {
            serverStatus = .stopped
            showNotification(title: "Server unavailable", message: "Apfel is unreachable. Run the server before sending requests.", severity: .warning)
        }
    }

    private func startOrRestartServer() async {
        guard !isStartingServer else { return }
        isStartingServer = true

        do {
            serverProcess?.terminate()
            serverProcess = try apfelClient.startServer()
            serverStatus = .running
            try await Task.sleep(nanoseconds: 800_000_000)
            await refreshServerStatus()
        } catch {
            serverStatus = .unavailable
        }

        isStartingServer = false
    }

    private func stopServer() {
        serverProcess?.terminate()
        serverProcess = nil
        serverStatus = .stopped
    }

    private func showNotification(title: String, message: String, severity: NotificationSeverity) {
        withAnimation {
            banner = NotificationBanner(title: title, message: message, severity: severity)
        }
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation {
                banner = nil
            }
        }
    }

    private func bannerView(_ banner: NotificationBanner) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: banner.severity.icon)
                .foregroundColor(.white)
                .font(.title3)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(banner.title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(banner.message)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
            Spacer()
        }
        .padding(16)
        .background(banner.severity.background)
        .cornerRadius(20)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

struct MessageRow: View {
    let message: Message
    let theme: ColorTheme
    @State private var isHovered = false

    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                bubble
            } else {
                bubble
                Spacer()
            }
        }
    }

    private var bubble: some View {
        Group {
            Text(message.text)
        }
        .textSelection(.enabled)
        .font(.body)
        .foregroundColor(theme.messageForeground)
        .multilineTextAlignment(.leading)
        .lineSpacing(5)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(message.isUser ? theme.accent.opacity(0.22) : theme.bubbleBackground)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .onHover { isHovered = $0 }
        .contextMenu {
            Button(action: copyMessage) {
                Label("Copy message", systemImage: "doc.on.doc")
            }
        }
        .overlay(alignment: .topTrailing) {
            if isHovered {
                Button(action: copyMessage) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(theme.messageForeground.opacity(0.8))
                        .padding(10)
                }
                .buttonStyle(.plain)
                .help("Copy message")
            }
        }
        .accessibilityLabel(message.isUser ? "Your message: \(message.text)" : "AI message: \(message.text)")
    }

    private func copyMessage() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(message.text, forType: .string)
    }
}

#Preview {
    ContentView()
}
