//
//  IdeaDetailView.swift
//  IdeaCapture
//
//  想法详情和编辑界面
//

import SwiftUI
import SwiftData

struct IdeaDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var idea: Idea

    @State private var isEditing = false
    @State private var editedTitle: String = ""
    @State private var editedContent: String = ""
    @State private var editedTags: [String] = []
    @State private var showShareSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 图片（如果有）
                if let imageData = idea.imageData,
                   let uiImage = UIImage(data: imageData) {
                    imageSection(uiImage)
                }

                // 标题
                titleSection

                // 内容
                contentSection

                // 标签
                tagsSection

                // 元数据
                metadataSection
            }
            .padding()
        }
        .navigationTitle(isEditing ? "编辑想法" : "想法详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if isEditing {
                    Button("完成") {
                        saveChanges()
                    }
                } else {
                    Button("编辑") {
                        startEditing()
                    }
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                Button(action: {
                    showShareSheet = true
                }) {
                    Label("导出", systemImage: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(idea: idea)
        }
        .onAppear {
            editedTitle = idea.title
            editedContent = idea.content
            editedTags = idea.tags
        }
    }

    // MARK: - Subviews

    private func imageSection(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .cornerRadius(12)
            .shadow(radius: 2)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("标题")
                .font(.caption)
                .foregroundStyle(.secondary)

            if isEditing {
                TextField("输入标题", text: $editedTitle)
                    .textFieldStyle(.roundedBorder)
            } else {
                Text(idea.title)
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("内容")
                .font(.caption)
                .foregroundStyle(.secondary)

            if isEditing {
                TextEditor(text: $editedContent)
                    .frame(minHeight: 200)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                Text(idea.content)
                    .font(.body)
            }
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("标签")
                .font(.caption)
                .foregroundStyle(.secondary)

            if idea.hasTags {
                FlowLayout(spacing: 8) {
                    ForEach(idea.tags, id: \.self) { tag in
                        TagView(text: tag)
                    }
                }
            } else {
                Text("暂无标签")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            HStack {
                Label("创建时间", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(idea.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("最后修改", systemImage: "pencil")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(idea.updatedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("云同步", systemImage: idea.isSynced ? "checkmark.icloud" : "icloud.slash")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text(idea.isSynced ? "已同步" : "未同步")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func startEditing() {
        editedTitle = idea.title
        editedContent = idea.content
        editedTags = idea.tags
        isEditing = true
    }

    private func saveChanges() {
        idea.title = editedTitle
        idea.content = editedContent
        idea.tags = editedTags
        idea.markAsUpdated()

        try? modelContext.save()
        isEditing = false
    }
}

// MARK: - Share Sheet
struct ShareSheet: View {
    @Environment(\.dismiss) private var dismiss
    let idea: Idea

    @State private var showCopiedAlert = false
    @State private var copiedMessage = ""

    var body: some View {
        NavigationStack {
            List {
                Section("导出格式") {
                    Button(action: {
                        exportAsText()
                    }) {
                        Label("纯文本", systemImage: "doc.text")
                    }

                    Button(action: {
                        exportAsMarkdown()
                    }) {
                        Label("Markdown", systemImage: "doc.richtext")
                    }
                }

                Section("分享到") {
                    Button(action: {
                        shareViaActivityView()
                    }) {
                        Label("系统分享", systemImage: "square.and.arrow.up")
                    }
                }

                Section {
                    Text("💡 提示：Supabase云备份功能即将推出")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("导出想法")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .alert("已复制", isPresented: $showCopiedAlert) {
                Button("好的", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(copiedMessage)
            }
        }
    }

    private func exportAsText() {
        let text = """
        \(idea.title)

        \(idea.content)

        标签: \(idea.tagsText)
        创建时间: \(idea.formattedDate)
        """

        UIPasteboard.general.string = text
        copiedMessage = "纯文本已复制到剪贴板"
        showCopiedAlert = true
    }

    private func exportAsMarkdown() {
        let markdown = """
        # \(idea.title)

        \(idea.content)

        **标签**: \(idea.tags.map { "`\($0)`" }.joined(separator: " "))

        ---
        *创建时间: \(idea.formattedDate)*
        """

        UIPasteboard.general.string = markdown
        copiedMessage = "Markdown格式已复制到剪贴板"
        showCopiedAlert = true
    }

    private func shareViaActivityView() {
        let text = """
        \(idea.title)

        \(idea.content)
        """

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            print("🔴 无法获取rootViewController")
            return
        }

        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )

        // iPad支持 - 设置popover的sourceView
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        // 找到最顶层的ViewController
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }

        topController.present(activityVC, animated: true) {
            print("🟢 系统分享界面已显示")
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        IdeaDetailView(idea: Idea(
            title: "示例想法",
            content: "这是一个想法的示例内容",
            tags: ["AI", "SaaS", "教育"]
        ))
    }
    .modelContainer(for: Idea.self, inMemory: true)
}
