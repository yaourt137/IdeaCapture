//
//  IdeaCaptureView.swift
//  IdeaCapture
//
//  图片捕获和OCR识别界面
//

import SwiftUI
import SwiftData

struct IdeaCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: IdeaCaptureViewModel

    let image: UIImage

    init(image: UIImage, modelContext: ModelContext) {
        self.image = image
        self._viewModel = State(initialValue: IdeaCaptureViewModel(modelContext: modelContext))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 图片预览
                    imagePreviewSection

                    // OCR结果
                    if !viewModel.recognizedText.isEmpty {
                        ocrResultSection
                    }

                    // 推荐标签
                    if !viewModel.recommendedTags.isEmpty {
                        tagsSection
                    }

                    // 错误信息
                    if let errorMessage = viewModel.errorMessage {
                        errorSection(errorMessage)
                    }

                    // 加载指示器
                    if viewModel.isProcessing {
                        ProgressView("处理中...")
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("新建想法")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveIdea()
                    }
                    .disabled(viewModel.recognizedText.isEmpty || viewModel.isProcessing)
                }
            }
            .task {
                await viewModel.processImage(image)
            }
        }
    }

    // MARK: - Subviews

    private var imagePreviewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("原始图片")
                .font(.headline)

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .cornerRadius(12)
                .shadow(radius: 2)
        }
    }

    private var ocrResultSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("识别内容")
                .font(.headline)

            TextEditor(text: .constant(viewModel.recognizedText))
                .frame(minHeight: 150)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .disabled(true)
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("推荐标签")
                .font(.headline)

            FlowLayout(spacing: 8) {
                ForEach(viewModel.recommendedTags, id: \.self) { tag in
                    TagView(text: tag)
                }
            }
        }
    }

    private func errorSection(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Actions

    private func saveIdea() {
        Task {
            do {
                try await viewModel.saveIdea()
                dismiss()
            } catch {
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Flow Layout (for tags)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowLayoutResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowLayoutResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )

        for (index, subview) in subviews.enumerated() {
            let position = result.positions[index]
            subview.place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    struct FlowLayoutResult {
        var size: CGSize
        var positions: [CGPoint]

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var positions: [CGPoint] = []
            var size: CGSize = .zero
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)

                if currentX + subviewSize.width > maxWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += subviewSize.width + spacing
                lineHeight = max(lineHeight, subviewSize.height)
                size.width = max(size.width, currentX - spacing)
            }

            size.height = currentY + lineHeight
            self.size = size
            self.positions = positions
        }
    }
}

// MARK: - Preview
#Preview {
    IdeaCaptureView(
        image: UIImage(systemName: "photo")!,
        modelContext: ModelContext(
            try! ModelContainer(for: Idea.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        )
    )
}
