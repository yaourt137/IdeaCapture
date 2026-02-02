//
//  SupabaseServiceTests.swift
//  IdeaCaptureTests
//
//  Supabase服务单元测试
//

import Testing
import Foundation
@testable import IdeaCapture

/// Supabase服务测试套件
@Suite("SupabaseService 测试")
struct SupabaseServiceTests {

    // MARK: - 配置测试

    @Test("检查Supabase配置状态")
    func testSupabaseConfiguration() async {
        let service = SupabaseService()
        let isConfigured = await service.isConfigured

        // 验证配置是否正确读取
        #expect(isConfigured == true, "Supabase应该已配置（从.env文件读取）")
    }

    // MARK: - 数据模型转换测试

    @Test("Idea模型转换为SupabaseIdea")
    func testIdeaToSupabaseIdeaConversion() {
        let testIdea = Idea(
            id: UUID(),
            title: "测试想法",
            content: "这是测试内容",
            tags: ["测试", "单元测试"],
            createdAt: Date(),
            updatedAt: Date(),
            imageData: nil,
            isSynced: false,
            remoteId: nil
        )

        // 验证基本属性
        #expect(testIdea.title == "测试想法")
        #expect(testIdea.content == "这是测试内容")
        #expect(testIdea.tags.count == 2)
        #expect(testIdea.isSynced == false)
    }

    @Test("自动生成标题功能")
    func testAutoTitleGeneration() {
        // 测试空标题时自动生成
        let shortContent = "短内容"
        let ideaShort = Idea(title: "", content: shortContent)
        #expect(ideaShort.title == shortContent)

        // 测试长内容截断
        let longContent = String(repeating: "很长的内容", count: 20)
        let ideaLong = Idea(title: "", content: longContent)
        #expect(ideaLong.title.count <= 33) // 30个字符 + "..."
        #expect(ideaLong.title.hasSuffix("..."))

        // 测试空内容
        let ideaEmpty = Idea(title: "", content: "")
        #expect(ideaEmpty.title == "未命名想法")
    }

    // MARK: - Idea模型业务逻辑测试

    @Test("标记想法为已更新")
    func testMarkAsUpdated() {
        let idea = Idea(
            title: "测试",
            content: "内容",
            isSynced: true
        )

        let originalUpdatedAt = idea.updatedAt

        // 等待一小段时间确保时间戳不同
        Thread.sleep(forTimeInterval: 0.01)

        idea.markAsUpdated()

        // 验证更新时间改变且同步状态重置
        #expect(idea.updatedAt > originalUpdatedAt)
        #expect(idea.isSynced == false)
    }

    @Test("标记想法为已同步")
    func testMarkAsSynced() {
        let idea = Idea(
            title: "测试",
            content: "内容",
            isSynced: false,
            remoteId: nil
        )

        let testRemoteId = "remote-123"
        idea.markAsSynced(remoteId: testRemoteId)

        // 验证同步状态和远程ID
        #expect(idea.isSynced == true)
        #expect(idea.remoteId == testRemoteId)
    }

    @Test("格式化日期显示")
    func testFormattedDate() {
        let calendar = Calendar.current
        let components = DateComponents(
            year: 2026,
            month: 1,
            day: 31,
            hour: 14,
            minute: 30
        )
        let testDate = calendar.date(from: components)!

        let idea = Idea(
            title: "测试",
            content: "内容",
            createdAt: testDate
        )

        // 验证日期格式
        #expect(idea.formattedDate == "2026年1月31日 14:30")
    }

    @Test("标签相关属性")
    func testTagProperties() {
        let ideaWithTags = Idea(
            title: "有标签",
            content: "内容",
            tags: ["标签1", "标签2", "标签3"]
        )

        #expect(ideaWithTags.hasTags == true)
        #expect(ideaWithTags.tagsText == "标签1 · 标签2 · 标签3")

        let ideaNoTags = Idea(
            title: "无标签",
            content: "内容",
            tags: []
        )

        #expect(ideaNoTags.hasTags == false)
        #expect(ideaNoTags.tagsText == "")
    }

    // MARK: - 错误处理测试

    @Test("SupabaseError错误描述")
    func testSupabaseErrorDescriptions() {
        let notConfiguredError = SupabaseError.notConfigured
        #expect(notConfiguredError.localizedDescription.contains("SUPABASE_PUBLISHABLE_KEY"))

        let invalidResponseError = SupabaseError.invalidResponse
        #expect(invalidResponseError.localizedDescription.contains("无效"))

        let uploadError = SupabaseError.uploadFailed(statusCode: 401, message: "未授权")
        #expect(uploadError.localizedDescription.contains("401"))
        #expect(uploadError.localizedDescription.contains("未授权"))

        let fetchError = SupabaseError.fetchFailed(statusCode: 404, message: "未找到")
        #expect(fetchError.localizedDescription.contains("404"))

        let deleteError = SupabaseError.deleteFailed(statusCode: 500, message: "服务器错误")
        #expect(deleteError.localizedDescription.contains("500"))
    }

    // MARK: - 边界条件测试

    @Test("处理包含Base64图片数据的想法")
    func testIdeaWithImageData() {
        let testImageData = "测试图片数据".data(using: .utf8)!

        let idea = Idea(
            title: "带图片",
            content: "内容",
            imageData: testImageData
        )

        #expect(idea.imageData != nil)
        #expect(idea.imageData == testImageData)
    }

    @Test("处理特殊字符标题和内容")
    func testSpecialCharactersHandling() {
        let specialContent = "特殊字符: !@#$%^&*()_+{}|:\"<>?[]\\;',./\n换行\t制表符"

        let idea = Idea(
            title: "特殊字符标题 😀🎉",
            content: specialContent,
            tags: ["标签😀", "emoji🎉"]
        )

        #expect(idea.title.contains("😀"))
        #expect(idea.content.contains("\n"))
        #expect(idea.tags[0].contains("😀"))
    }

    @Test("处理空标签数组")
    func testEmptyTagsArray() {
        let idea = Idea(
            title: "无标签",
            content: "内容",
            tags: []
        )

        #expect(idea.tags.isEmpty)
        #expect(idea.hasTags == false)
        #expect(idea.tagsText == "")
    }

    @Test("ISO8601日期格式转换")
    func testISO8601DateFormat() {
        let testDate = Date()
        let idea = Idea(
            title: "测试",
            content: "内容",
            createdAt: testDate,
            updatedAt: testDate
        )

        let iso8601String = idea.createdAt.ISO8601Format()

        // 验证ISO8601格式
        #expect(iso8601String.contains("T"))
        #expect(iso8601String.contains("Z") || iso8601String.contains("+") || iso8601String.contains("-"))
    }

    // MARK: - 集成测试注意事项

    /*
     注意：以下测试需要实际的Supabase连接，应该在集成测试中运行

     - testUploadIdea: 测试上传单个想法
     - testBatchUploadIdeas: 测试批量上传
     - testFetchAllIdeas: 测试获取所有想法
     - testDeleteIdea: 测试删除想法
     - testUploadWithoutConfiguration: 测试未配置时的错误处理

     这些测试需要：
     1. 有效的Supabase配置
     2. 网络连接
     3. 可能需要清理测试数据

     建议使用Supabase的测试环境或mock URLSession进行测试
     */
}
