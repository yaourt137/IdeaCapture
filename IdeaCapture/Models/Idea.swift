//
//  Idea.swift
//  IdeaCapture
//
//  想法数据模型
//

import Foundation
import SwiftData

@Model
final class Idea {
    // MARK: - Properties

    /// 唯一标识符
    var id: UUID

    /// 想法标题（自动从内容提取或用户自定义）
    var title: String

    /// 想法内容
    var content: String

    /// AI推荐的标签列表
    var tags: [String]

    /// 创建时间
    var createdAt: Date

    /// 最后更新时间
    var updatedAt: Date

    /// 原始图片数据（Base64编码）
    var imageData: Data?

    /// 是否已同步到Supabase
    var isSynced: Bool

    /// Supabase远程ID（用于云同步）
    var remoteId: String?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        title: String = "",
        content: String,
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        imageData: Data? = nil,
        isSynced: Bool = false,
        remoteId: String? = nil
    ) {
        self.id = id
        self.title = title.isEmpty ? Idea.generateTitleFromContent(content) : title
        self.content = content
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.imageData = imageData
        self.isSynced = isSynced
        self.remoteId = remoteId
    }

    // MARK: - Helper Methods

    /// 从内容自动生成标题（取前30个字符）
    private static func generateTitleFromContent(_ content: String) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "未命名想法" }

        let maxLength = 30
        if trimmed.count <= maxLength {
            return trimmed
        }

        let index = trimmed.index(trimmed.startIndex, offsetBy: maxLength)
        return String(trimmed[..<index]) + "..."
    }

    /// 更新时间戳
    func markAsUpdated() {
        updatedAt = Date()
        isSynced = false
    }

    /// 标记为已同步
    func markAsSynced(remoteId: String) {
        self.remoteId = remoteId
        isSynced = true
    }
}

// MARK: - Computed Properties
extension Idea {
    /// 格式化的创建日期（精确到分钟）
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: createdAt)
    }

    /// 格式化的更新日期（精确到分钟）
    var formattedUpdatedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: updatedAt)
    }

    /// 是否有标签
    var hasTags: Bool {
        !tags.isEmpty
    }

    /// 标签显示文本
    var tagsText: String {
        tags.joined(separator: " · ")
    }
}
