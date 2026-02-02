//
//  IdeaCaptureViewModel.swift
//  IdeaCapture
//
//  图片捕获和OCR识别的ViewModel
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
class IdeaCaptureViewModel {
    // MARK: - Properties

    var selectedImage: UIImage?
    var recognizedText: String = ""
    var recommendedTags: [String] = []

    var isProcessing: Bool = false
    var errorMessage: String?

    private let aiService: AIBuilderService
    private let supabaseService: SupabaseService
    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.aiService = AIBuilderService()
        self.supabaseService = SupabaseService()
    }

    // MARK: - Public Methods

    /// 处理选中的图片（OCR识别）
    func processImage(_ image: UIImage) async {
        print("🔵 [IdeaCaptureVM] 开始处理图片，尺寸: \(image.size)")
        selectedImage = image
        recognizedText = ""
        recommendedTags = []
        errorMessage = nil
        isProcessing = true

        defer {
            isProcessing = false
            print("🔵 [IdeaCaptureVM] 处理完成，isProcessing = false")
        }

        do {
            // 压缩图片
            print("🔵 [IdeaCaptureVM] 开始压缩图片...")
            guard let imageData = compressImage(image) else {
                throw ProcessError.imageCompressionFailed
            }
            print("🔵 [IdeaCaptureVM] 图片压缩完成，大小: \(imageData.count) bytes")

            // OCR识别
            print("🔵 [IdeaCaptureVM] 开始OCR识别...")
            recognizedText = try await aiService.recognizeText(from: imageData)
            print("🔵 [IdeaCaptureVM] OCR识别完成: \(recognizedText.prefix(50))...")

            // 如果识别成功且有内容，推荐标签
            if !recognizedText.isEmpty {
                print("🔵 [IdeaCaptureVM] 开始推荐标签...")
                try await recommendTagsForCurrentText()
                print("🔵 [IdeaCaptureVM] 标签推荐完成: \(recommendedTags)")
            }

        } catch {
            print("🔴 [IdeaCaptureVM] 处理失败: \(error)")
            errorMessage = "处理失败: \(error.localizedDescription)"
        }
    }

    /// 推荐标签
    func recommendTagsForCurrentText() async throws {
        guard !recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            recommendedTags = try await aiService.recommendTags(for: recognizedText)
        } catch {
            errorMessage = "标签推荐失败: \(error.localizedDescription)"
            throw error
        }
    }

    /// 保存想法到数据库（并自动云同步）
    func saveIdea(customTitle: String? = nil) async throws {
        guard !recognizedText.isEmpty else {
            throw ProcessError.emptyContent
        }

        // 压缩并保存图片数据
        var imageData: Data?
        if let image = selectedImage {
            imageData = compressImage(image)
        }

        // 创建新想法
        let idea = Idea(
            title: customTitle ?? "",
            content: recognizedText,
            tags: recommendedTags,
            imageData: imageData
        )

        modelContext.insert(idea)

        do {
            try modelContext.save()
            print("💾 想法已保存到本地数据库")

            // 自动云同步（如果已配置Supabase）
            Task {
                await syncToCloud(idea)
            }

            reset()
        } catch {
            throw ProcessError.saveFailed(error)
        }
    }

    /// 同步单个想法到云端
    private func syncToCloud(_ idea: Idea) async {
        guard await supabaseService.isConfigured else {
            print("⚠️ Supabase未配置，跳过云同步")
            return
        }

        do {
            let remoteId = try await supabaseService.uploadIdea(idea)
            print("☁️ 想法已同步到云端: \(remoteId)")

            // 更新同步状态
            idea.markAsSynced(remoteId: remoteId)
            try? modelContext.save()
        } catch {
            print("❌ 云同步失败: \(error.localizedDescription)")
        }
    }

    /// 重置状态
    func reset() {
        selectedImage = nil
        recognizedText = ""
        recommendedTags = []
        errorMessage = nil
        isProcessing = false
    }

    // MARK: - Private Methods

    /// 压缩图片到合适大小
    private func compressImage(_ image: UIImage, maxSizeKB: Int = 500) -> Data? {
        let maxBytes = maxSizeKB * 1024
        var compression: CGFloat = 0.8

        guard var data = image.jpegData(compressionQuality: compression) else {
            return nil
        }

        // 如果图片太大，逐步降低质量
        while data.count > maxBytes && compression > 0.1 {
            compression -= 0.1
            guard let newData = image.jpegData(compressionQuality: compression) else {
                break
            }
            data = newData
        }

        return data
    }
}

// MARK: - Errors
enum ProcessError: LocalizedError {
    case imageCompressionFailed
    case emptyContent
    case saveFailed(Error)

    var errorDescription: String? {
        switch self {
        case .imageCompressionFailed:
            return "图片压缩失败"
        case .emptyContent:
            return "内容不能为空"
        case .saveFailed(let error):
            return "保存失败: \(error.localizedDescription)"
        }
    }
}
