//
//  AppConfig.swift
//  IdeaCapture
//
//  应用配置管理
//

import Foundation

enum AppConfig {
    // MARK: - Environment Variables

    /// 从.env文件读取的环境变量（懒加载）
    nonisolated(unsafe) private static let envVars: [String: String] = EnvReader.readEnvFile()

    // MARK: - AI Builder API

    /// AI Builder API基础URL
    static var aiBuilderBaseURL: String {
        envVars["AI_BUILDER_BASE_URL"] ?? "https://space.ai-builders.com/backend"
    }

    /// AI Builder API Token
    static var aiBuilderToken: String {
        envVars["AI_BUILDER_TOKEN"] ?? ""
    }

    /// AI Builder模型
    static var aiBuilderModel: String {
        envVars["AI_BUILDER_MODEL"] ?? "gemini-2.5-pro"
    }

    // MARK: - Supabase

    /// Supabase项目URL
    static var supabaseURL: String {
        envVars["SUPABASE_URL"] ?? ""
    }

    /// Supabase Publishable Key（客户端安全密钥，遵守RLS策略）
    static var supabasePublishableKey: String {
        envVars["SUPABASE_PUBLISHABLE_KEY"] ?? ""
    }

    // MARK: - Export Services

    /// Notion Integration Token
    static var notionToken: String? {
        envVars["NOTION_TOKEN"]
    }

    // MARK: - Validation

    /// 检查配置是否完整
    static func validateConfig() throws {
        guard !aiBuilderToken.isEmpty else {
            throw ConfigError.missingAIBuilderToken
        }
    }
}

// MARK: - Errors
enum ConfigError: LocalizedError {
    case missingAIBuilderToken

    var errorDescription: String? {
        switch self {
        case .missingAIBuilderToken:
            return "AI Builder Token未配置"
        }
    }
}
