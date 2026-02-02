//
//  SyncViewModel.swift
//  IdeaCapture
//
//  手动云同步ViewModel
//

import Foundation
import SwiftData

@MainActor
@Observable
class SyncViewModel {
    // MARK: - Properties

    var isSyncing: Bool = false
    var syncMessage: String?
    var showSyncAlert: Bool = false

    private let supabaseService: SupabaseService
    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.supabaseService = SupabaseService()
    }

    // MARK: - Public Methods

    /// 强制同步所有想法（不管是否已同步）
    func syncAllIdeas(ideas: [Idea], forceSync: Bool = true) async {
        guard await supabaseService.isConfigured else {
            syncMessage = "Supabase未配置\n请在.env文件中填入配置信息"
            showSyncAlert = true
            return
        }

        isSyncing = true
        defer { isSyncing = false }

        // 如果强制同步，同步所有想法；否则只同步未同步的
        let ideasToSync = forceSync ? ideas : ideas.filter { !$0.isSynced }

        guard !ideasToSync.isEmpty else {
            syncMessage = forceSync ? "没有想法需要同步" : "所有想法已同步 ✓"
            showSyncAlert = true
            return
        }

        let syncType = forceSync ? "强制同步" : "同步"
        print("🔄 开始\(syncType) \(ideasToSync.count) 个想法")

        do {
            let successCount = try await supabaseService.uploadIdeas(ideasToSync)

            // 标记为已同步
            for idea in ideasToSync {
                idea.markAsSynced(remoteId: idea.id.uuidString)
            }
            try? modelContext.save()

            syncMessage = "成功同步 \(successCount)/\(ideasToSync.count) 个想法"
            showSyncAlert = true

            print("✅ 同步完成: \(successCount)/\(ideasToSync.count)")

        } catch {
            syncMessage = "同步失败: \(error.localizedDescription)"
            showSyncAlert = true
            print("❌ 同步失败: \(error)")
        }
    }

    /// 手动同步所有未同步的想法（保留向后兼容）
    func syncUnsyncedIdeas(ideas: [Idea]) async {
        await syncAllIdeas(ideas: ideas, forceSync: false)
    }
}
