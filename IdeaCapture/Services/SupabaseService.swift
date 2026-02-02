//
//  SupabaseService.swift
//  IdeaCapture
//
//  Supabase 云同步服务
//

import Foundation

// MARK: - Supabase Models
struct SupabaseIdea: Codable, Sendable {
    let id: String
    let title: String
    let content: String
    let tags: [String]
    let createdAt: String
    let updatedAt: String
    let imageData: String?  // 已废弃，保留向后兼容
    let imageUrl: String?   // 新增：Storage 中的图片 URL

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case tags
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case imageData = "image_data"
        case imageUrl = "image_url"
    }
}

// MARK: - Supabase Service
actor SupabaseService {
    // MARK: - Properties

    private let baseURL: String
    private let publishableKey: String

    // MARK: - Initialization

    init() {
        self.baseURL = AppConfig.supabaseURL
        self.publishableKey = AppConfig.supabasePublishableKey

        print("🟦 [Supabase] 初始化配置:")
        print("🟦 [Supabase]   - baseURL: \(baseURL.isEmpty ? "未配置" : baseURL)")
        print("🟦 [Supabase]   - publishableKey: \(publishableKey.isEmpty ? "未配置" : "\(publishableKey.prefix(20))...")")
    }

    // MARK: - Public Methods

    /// 检查Supabase是否已配置
    var isConfigured: Bool {
        !baseURL.isEmpty && !publishableKey.isEmpty
    }

    // MARK: - Image Upload

    /// 上传图片到 Supabase Storage（支持覆盖已存在的文件）
    /// - Parameters:
    ///   - imageData: 图片数据
    ///   - ideaId: 想法ID（用于生成唯一文件名）
    /// - Returns: 图片的公开 URL
    private func uploadImage(_ imageData: Data, ideaId: String) async throws -> String {
        print("🟦 [Supabase] 开始上传图片...")

        // 生成唯一文件名：{ideaId}.jpg
        let fileName = "\(ideaId).jpg"
        let uploadURL = URL(string: "\(baseURL)/storage/v1/object/idea-images/\(fileName)")!

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "PUT"  // 使用 PUT 支持创建或覆盖
        request.setValue(publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(publishableKey)", forHTTPHeaderField: "Authorization")
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "x-upsert")  // 明确允许覆盖
        request.httpBody = imageData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("🔴 [Supabase] 图片上传失败: \(errorMessage)")
            throw SupabaseError.uploadFailed(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        // 构建公开图片 URL
        let imageURL = "\(baseURL)/storage/v1/object/public/idea-images/\(fileName)"
        print("🟦 [Supabase] 图片上传成功: \(imageURL)")

        return imageURL
    }

    /// 上传想法到Supabase（支持 UPSERT：如果记录已存在则更新）
    func uploadIdea(_ idea: Idea) async throws -> String {
        guard isConfigured else {
            throw SupabaseError.notConfigured
        }

        print("🟦 [Supabase] 开始上传想法: \(idea.title)")

        // 如果有图片，先上传到 Storage
        var imageURL: String? = nil
        if let imageData = idea.imageData {
            imageURL = try await uploadImage(imageData, ideaId: idea.id.uuidString)
        }

        let supabaseIdea = SupabaseIdea(
            id: idea.id.uuidString,
            title: idea.title,
            content: idea.content,
            tags: idea.tags,
            createdAt: idea.createdAt.ISO8601Format(),
            updatedAt: idea.updatedAt.ISO8601Format(),
            imageData: nil,  // 不再使用 Base64
            imageUrl: imageURL
        )

        let url = URL(string: "\(baseURL)/rest/v1/ideas")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(publishableKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // resolution=merge-duplicates: 如果主键冲突则更新记录（UPSERT）
        request.setValue("resolution=merge-duplicates,return=minimal", forHTTPHeaderField: "Prefer")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(supabaseIdea)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("🔴 [Supabase] 上传失败: \(errorMessage)")
            throw SupabaseError.uploadFailed(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        print("🟦 [Supabase] 上传成功: \(idea.id.uuidString)")
        return idea.id.uuidString
    }

    /// 批量上传想法
    func uploadIdeas(_ ideas: [Idea]) async throws -> Int {
        guard isConfigured else {
            throw SupabaseError.notConfigured
        }

        print("🟦 [Supabase] 开始批量上传 \(ideas.count) 个想法")

        var successCount = 0
        for idea in ideas {
            do {
                _ = try await uploadIdea(idea)
                successCount += 1
            } catch {
                print("🔴 [Supabase] 上传失败: \(idea.title) - \(error)")
            }
        }

        print("🟦 [Supabase] 批量上传完成: \(successCount)/\(ideas.count)")
        return successCount
    }

    /// 从Supabase获取所有想法
    func fetchAllIdeas() async throws -> [SupabaseIdea] {
        guard isConfigured else {
            throw SupabaseError.notConfigured
        }

        print("🟦 [Supabase] 开始获取所有想法")

        let url = URL(string: "\(baseURL)/rest/v1/ideas?select=*")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(publishableKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SupabaseError.fetchFailed(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        let decoder = JSONDecoder()
        let ideas = try decoder.decode([SupabaseIdea].self, from: data)

        print("🟦 [Supabase] 获取成功: \(ideas.count) 个想法")
        return ideas
    }

    /// 删除Supabase中的想法
    func deleteIdea(_ ideaId: String) async throws {
        guard isConfigured else {
            throw SupabaseError.notConfigured
        }

        print("🟦 [Supabase] 开始删除想法: \(ideaId)")

        let url = URL(string: "\(baseURL)/rest/v1/ideas?id=eq.\(ideaId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(publishableKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SupabaseError.deleteFailed(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        print("🟦 [Supabase] 删除成功: \(ideaId)")
    }
}

// MARK: - Errors
enum SupabaseError: LocalizedError {
    case notConfigured
    case invalidResponse
    case uploadFailed(statusCode: Int, message: String)
    case fetchFailed(statusCode: Int, message: String)
    case deleteFailed(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase未配置，请在.env文件中填入SUPABASE_URL和SUPABASE_PUBLISHABLE_KEY"
        case .invalidResponse:
            return "无效的服务器响应"
        case .uploadFailed(let statusCode, let message):
            return "上传失败 [\(statusCode)]: \(message)"
        case .fetchFailed(let statusCode, let message):
            return "获取失败 [\(statusCode)]: \(message)"
        case .deleteFailed(let statusCode, let message):
            return "删除失败 [\(statusCode)]: \(message)"
        }
    }
}
