//
//  IdeaListView.swift
//  IdeaCapture
//
//  想法列表主界面
//

import SwiftUI
import SwiftData

struct IdeaListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Idea.createdAt, order: .reverse) private var ideas: [Idea]

    @State private var showImagePicker = false
    @State private var showCaptureView = false
    @State private var selectedImage: UIImage?
    @State private var searchText = ""
    @State private var syncViewModel: SyncViewModel?

    var filteredIdeas: [Idea] {
        guard !searchText.isEmpty else { return ideas }

        return ideas.filter { idea in
            idea.title.localizedCaseInsensitiveContains(searchText) ||
            idea.content.localizedCaseInsensitiveContains(searchText) ||
            idea.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredIdeas.isEmpty {
                    emptyStateView
                } else {
                    ideaList
                }
            }
            .navigationTitle("我的想法")
            .searchable(text: $searchText, prompt: "搜索想法或标签")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        showImagePicker = true
                    }) {
                        Label("添加", systemImage: "plus.circle.fill")
                    }
                }

                ToolbarItem(placement: .secondaryAction) {
                    Button(action: {
                        Task {
                            if syncViewModel == nil {
                                syncViewModel = SyncViewModel(modelContext: modelContext)
                            }
                            // 强制同步所有想法
                            await syncViewModel?.syncAllIdeas(ideas: ideas, forceSync: true)
                        }
                    }) {
                        Label("同步", systemImage: "icloud.and.arrow.up")
                    }
                }
            }
            .refreshable {
                // 下拉刷新触发强制同步
                if syncViewModel == nil {
                    syncViewModel = SyncViewModel(modelContext: modelContext)
                }
                await syncViewModel?.syncAllIdeas(ideas: ideas, forceSync: true)
            }
            .alert(
                syncViewModel?.syncMessage ?? "",
                isPresented: Binding(
                    get: { syncViewModel?.showSyncAlert ?? false },
                    set: { if !$0 { syncViewModel?.showSyncAlert = false } }
                )
            ) {
                Button("好的", role: .cancel) {}
            }
            .sheet(isPresented: $showImagePicker, onDismiss: {
                // 等待 ImagePicker sheet 完全关闭后再显示 CaptureView
                if selectedImage != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showCaptureView = true
                    }
                }
            }) {
                ImageSourcePickerView { image in
                    selectedImage = image
                }
            }
            .sheet(isPresented: $showCaptureView, onDismiss: {
                // 清理已选择的图片
                selectedImage = nil
            }) {
                if let image = selectedImage {
                    IdeaCaptureView(image: image, modelContext: modelContext)
                }
            }
        }
    }

    // MARK: - Subviews

    private var ideaList: some View {
        List {
            ForEach(filteredIdeas) { idea in
                NavigationLink(destination: IdeaDetailView(idea: idea)) {
                    IdeaRowView(idea: idea)
                }
            }
            .onDelete(perform: deleteIdeas)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lightbulb.max")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text(searchText.isEmpty ? "还没有想法" : "没有找到匹配的想法")
                .font(.title2)
                .foregroundStyle(.secondary)

            if searchText.isEmpty {
                Text("点击右上角 + 开始记录你的想法")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    // MARK: - Actions

    private func deleteIdeas(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredIdeas[index])
        }

        try? modelContext.save()
    }
}

// MARK: - Idea Row View
struct IdeaRowView: View {
    let idea: Idea

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(idea.title)
                .font(.headline)
                .lineLimit(1)

            Text(idea.content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            if idea.hasTags {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(idea.tags, id: \.self) { tag in
                            TagView(text: tag)
                        }
                    }
                }
            }

            Text(idea.formattedDate)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Tag View
struct TagView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(8)
    }
}

// MARK: - Preview
#Preview {
    IdeaListView()
        .modelContainer(for: Idea.self, inMemory: true)
}
