//
//  ApfelClient.swift
//  Pomia
//
//  Created by GitHub Copilot on 04/04/2026.
//

import Foundation

enum ApfelClientError: LocalizedError {
    case invalidURL
    case commandNotInstalled
    case serverUnavailable
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Unable to create a valid URL for the Apfel server."
        case .commandNotInstalled:
            return "The apfel executable is not installed. Install it with Homebrew: brew tap Arthur-Ficial/tap && brew install Arthur-Ficial/tap/apfel."
        case .serverUnavailable:
            return "The Apfel server is unavailable. Start it with the app button or ./scripts/start-apfel-server.sh."
        case .invalidResponse:
            return "Received an unexpected response from the Apfel server."
        case .apiError(let message):
            return message
        }
    }
}

struct ApfelChatMessage: Codable {
    let role: String
    let content: String
}

struct ApfelChatRequest: Codable {
    let model: String
    let messages: [ApfelChatMessage]
    let temperature: Double
    let max_tokens: Int
    let stream: Bool
}

struct ApfelChatResponse: Codable {
    let choices: [ApfelChoice]
}

struct ApfelChoice: Codable {
    let message: ApfelChatMessage
}

struct ApfelStreamChunk: Codable {
    let choices: [ApfelStreamChoice]
}

struct ApfelStreamChoice: Codable {
    let delta: ApfelDelta
}

struct ApfelDelta: Codable {
    let content: String?
}

final class ApfelClient {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL = URL(string: "http://127.0.0.1:11434")!, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    func sendChatStream(messages: [ApfelChatMessage], onChunk: @escaping (String) -> Void) async throws {
        let requestURL = baseURL.appendingPathComponent("/v1/chat/completions")
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload = ApfelChatRequest(
            model: "apple-foundationmodel",
            messages: messages,
            temperature: 0.6,
            max_tokens: 1024,
            stream: true
        )

        request.httpBody = try JSONEncoder().encode(payload)
        request.timeoutInterval = 300

        let (asyncBytes, response) = try await session.bytes(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApfelClientError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            throw ApfelClientError.invalidResponse
        }

        for try await line in asyncBytes.lines {
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst("data: ".count))
                if jsonString == "[DONE]" {
                    break
                }
                if let jsonData = jsonString.data(using: .utf8) {
                    if let chunk = try? JSONDecoder().decode(ApfelStreamChunk.self, from: jsonData) {
                        if let content = chunk.choices.first?.delta.content {
                            onChunk(content)
                        }
                    }
                }
            }
        }
    }


    func checkHealth() async throws -> Bool {
        let requestURL = baseURL.appendingPathComponent("/health")
        var request = URLRequest(url: requestURL)
        request.timeoutInterval = 4

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ApfelClientError.invalidResponse
        }

        return httpResponse.statusCode == 200
    }

    func startServer() throws -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["apfel", "--serve", "--host", "127.0.0.1", "--port", "11434", "--cors", "--no-origin-check"]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            throw ApfelClientError.commandNotInstalled
        }

        return process
    }

}

