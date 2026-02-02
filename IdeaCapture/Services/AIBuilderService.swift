//
//  AIBuilderService.swift
//  IdeaCapture
//
//  AI Builder API服务 - OCR识别和标签推荐
//

import Foundation
import UIKit

// MARK: - AI Builder Service
actor AIBuilderService {
    // MARK: - Properties

    private let baseURL: String
    private let token: String
    private let model: String

    // MARK: - Initialization

    init() {
        self.baseURL = AppConfig.aiBuilderBaseURL
        self.token = AppConfig.aiBuilderToken
        self.model = AppConfig.aiBuilderModel

        print("🟢 [AIBuilder] 初始化配置:")
        print("🟢 [AIBuilder]   - baseURL: \(baseURL)")
        print("🟢 [AIBuilder]   - model: \(model)")
        print("🟢 [AIBuilder]   - token: \(token.prefix(20))...")
    }

    // MARK: - Public Methods

    /// 识别图片中的手写文字
    func recognizeText(from imageData: Data) async throws -> String {
        print("🟢 [AIBuilder] 开始OCR识别，图片大小: \(imageData.count) bytes")
        let base64Image = imageData.base64EncodedString()
        print("🟢 [AIBuilder] Base64编码完成，长度: \(base64Image.count)")

        let payload = ChatCompletionRequest(
            model: model,
            messages: [
                Message(
                    role: "user",
                    content: [
                        .text("请识别这张图片中的所有手写文字，保持原有格式和换行。只返回识别出的文字内容，不要添加任何解释、前缀或后缀。"),
                        .image("data:image/jpeg;base64,\(base64Image)")
                    ]
                )
            ]
        )

        print("🟢 [AIBuilder] 发送API请求...")
        let response = try await makeRequest(payload: payload)
        print("🟢 [AIBuilder] API响应成功")

        guard let content = response.choices.first?.message.content else {
            print("🔴 [AIBuilder] 响应内容为空")
            throw AIBuilderError.emptyResponse
        }

        let result = content.trimmingCharacters(in: .whitespacesAndNewlines)
        print("🟢 [AIBuilder] OCR识别结果: \(result.prefix(100))...")
        return result
    }

    /// 根据内容推荐标签
    func recommendTags(for content: String) async throws -> [String] {
        let prompt = """
        分析以下想法，返回3-5个相关标签。
        标签应涵盖：主题分类、应用领域、关键特征等维度。
        只返回JSON格式，不要有其他内容：{"tags": ["标签1", "标签2", ...]}

        想法内容：
        \(content)
        """

        let payload = ChatCompletionRequest(
            model: model,
            messages: [
                Message(
                    role: "user",
                    content: [.text(prompt)]
                )
            ]
        )

        let response = try await makeRequest(payload: payload)

        guard let content = response.choices.first?.message.content else {
            throw AIBuilderError.emptyResponse
        }

        return try parseTags(from: content)
    }

    // MARK: - Private Methods

    private func makeRequest(payload: ChatCompletionRequest) async throws -> ChatCompletionResponse {
        guard let url = URL(string: "\(baseURL)/v1/chat/completions") else {
            throw AIBuilderError.invalidURL
        }

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIBuilderError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIBuilderError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        return try decoder.decode(ChatCompletionResponse.self, from: data)
    }

    private func parseTags(from response: String) throws -> [String] {
        let decoder = JSONDecoder()

        // 尝试直接解析JSON
        if let data = response.data(using: .utf8),
           let json = try? decoder.decode(TagsResponse.self, from: data) {
            return json.tags
        }

        // 尝试从文本中提取JSON
        if let range = response.range(of: #"\{[^}]*"tags"[^}]*\}"#, options: .regularExpression),
           let data = String(response[range]).data(using: .utf8),
           let json = try? decoder.decode(TagsResponse.self, from: data) {
            return json.tags
        }

        // 尝试提取方括号中的内容
        if let range = response.range(of: #"\[([^\]]+)\]"#, options: .regularExpression) {
            let arrayStr = String(response[range])
                .replacingOccurrences(of: "[", with: "")
                .replacingOccurrences(of: "]", with: "")

            let tags = arrayStr
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\"'")) }
                .filter { !$0.isEmpty }

            return tags
        }

        // 如果都失败，返回空数组
        return []
    }
}

// MARK: - Request/Response Models
private struct ChatCompletionRequest: Encodable, Sendable {
    let model: String
    let messages: [Message]
}

private struct Message: Encodable, Sendable {
    let role: String
    let content: [ContentPart]
}

private enum ContentPart: Encodable, Sendable {
    case text(String)
    case image(String)

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .text(let text):
            try container.encode("text", forKey: .type)
            try container.encode(text, forKey: .text)
        case .image(let url):
            try container.encode("image_url", forKey: .type)
            try container.encode(ImageURL(url: url), forKey: .imageURL)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case text
        case imageURL = "image_url"
    }

    private struct ImageURL: Encodable, Sendable {
        let url: String
    }
}

private struct ChatCompletionResponse: Decodable, Sendable {
    let choices: [Choice]

    struct Choice: Decodable, Sendable {
        let message: ResponseMessage
    }

    struct ResponseMessage: Decodable, Sendable {
        let content: String?
    }
}

private struct TagsResponse: Decodable, Sendable {
    let tags: [String]
}

// MARK: - Errors
enum AIBuilderError: LocalizedError {
    case invalidURL
    case invalidResponse
    case emptyResponse
    case apiError(statusCode: Int, message: String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的API地址"
        case .invalidResponse:
            return "无效的服务器响应"
        case .emptyResponse:
            return "服务器返回空内容"
        case .apiError(let statusCode, let message):
            return "API错误 [\(statusCode)]: \(message)"
        case .decodingError:
            return "数据解析失败"
        }
    }
}
