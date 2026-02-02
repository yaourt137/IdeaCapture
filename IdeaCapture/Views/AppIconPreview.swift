//
//  AppIconPreview.swift
//  IdeaCapture
//
//  App 图标设计预览
//

import SwiftUI

struct AppIconPreview: View {
    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.49, blue: 0.92),  // #667eea
                    Color(red: 0.46, green: 0.29, blue: 0.64)  // #764ba2
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: -10) {
                // 灯泡图标 - 代表想法
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 280, weight: .medium))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)

                // 相机快门元素 - 代表捕捉
                Circle()
                    .stroke(lineWidth: 16)
                    .frame(width: 140, height: 140)
                    .foregroundStyle(.white.opacity(0.9))
                    .overlay(
                        Circle()
                            .fill(.white)
                            .frame(width: 100, height: 100)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    .offset(y: 20)
            }
        }
        .frame(width: 1024, height: 1024)
    }
}

// MARK: - 备选设计方案

/// 简约版：仅灯泡
struct AppIconPreviewMinimal: View {
    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.49, blue: 0.92),
                    Color(red: 0.46, green: 0.29, blue: 0.64)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 灯泡图标
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 480, weight: .regular))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
        }
        .frame(width: 1024, height: 1024)
    }
}

/// 现代版：圆形灯泡
struct AppIconPreviewModern: View {
    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.49, blue: 0.92),
                    Color(red: 0.46, green: 0.29, blue: 0.64)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 圆形背景
            Circle()
                .fill(.white.opacity(0.15))
                .frame(width: 700, height: 700)
                .blur(radius: 60)

            // 灯泡图标
            Image(systemName: "lightbulb.max.fill")
                .font(.system(size: 420, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.85)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 8)
        }
        .frame(width: 1024, height: 1024)
    }
}

/// 活力版：多彩灯泡
struct AppIconPreviewVibrant: View {
    var body: some View {
        ZStack {
            // 深色背景
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.15, blue: 0.2),
                    Color(red: 0.1, green: 0.1, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 发光效果
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.4),
                            .clear
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 400
                    )
                )
                .frame(width: 800, height: 800)

            // 灯泡图标
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 450, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.95, blue: 0.6),
                            Color(red: 1.0, green: 0.84, blue: 0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.6), radius: 40, x: 0, y: 0)
                .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
        }
        .frame(width: 1024, height: 1024)
    }
}

// MARK: - 图标导出视图

struct AppIconExportView: View {
    @State private var selectedStyle = 0

    let styles = [
        "组合版（灯泡+快门）",
        "简约版（仅灯泡）",
        "现代版（圆形灯泡）",
        "活力版（发光灯泡）"
    ]

    var body: some View {
        VStack(spacing: 30) {
            Text("IdeaCapture 图标设计")
                .font(.title)
                .bold()

            Picker("选择样式", selection: $selectedStyle) {
                ForEach(0..<styles.count, id: \.self) { index in
                    Text(styles[index]).tag(index)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // 图标预览
            Group {
                switch selectedStyle {
                case 0:
                    AppIconPreview()
                case 1:
                    AppIconPreviewMinimal()
                case 2:
                    AppIconPreviewModern()
                case 3:
                    AppIconPreviewVibrant()
                default:
                    AppIconPreview()
                }
            }
            .frame(width: 300, height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 67.5))
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)

            VStack(alignment: .leading, spacing: 12) {
                Text("导出说明：")
                    .font(.headline)

                Text("1. 选择喜欢的样式")
                Text("2. 在 Xcode Simulator 或真机上运行")
                Text("3. 截图并裁剪为 1024x1024")
                Text("4. 或使用下方的完整尺寸预览")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
        .padding()
    }
}

// MARK: - 完整尺寸导出视图

struct AppIconFullSizeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                Text("完整尺寸图标 (1024x1024)")
                    .font(.title2)
                    .bold()
                    .padding(.top)

                // 组合版
                VStack(spacing: 10) {
                    Text("组合版")
                        .font(.headline)
                    AppIconPreview()
                        .clipShape(RoundedRectangle(cornerRadius: 227.5))
                }

                // 简约版
                VStack(spacing: 10) {
                    Text("简约版")
                        .font(.headline)
                    AppIconPreviewMinimal()
                        .clipShape(RoundedRectangle(cornerRadius: 227.5))
                }

                // 现代版
                VStack(spacing: 10) {
                    Text("现代版")
                        .font(.headline)
                    AppIconPreviewModern()
                        .clipShape(RoundedRectangle(cornerRadius: 227.5))
                }

                // 活力版
                VStack(spacing: 10) {
                    Text("活力版")
                        .font(.headline)
                    AppIconPreviewVibrant()
                        .clipShape(RoundedRectangle(cornerRadius: 227.5))
                }

                Text("长按图标保存到相册")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom)
            }
        }
    }
}

// MARK: - Preview

#Preview("图标选择器") {
    AppIconExportView()
}

#Preview("完整尺寸") {
    AppIconFullSizeView()
}

#Preview("组合版") {
    AppIconPreview()
        .clipShape(RoundedRectangle(cornerRadius: 227.5))
}

#Preview("简约版") {
    AppIconPreviewMinimal()
        .clipShape(RoundedRectangle(cornerRadius: 227.5))
}

#Preview("现代版") {
    AppIconPreviewModern()
        .clipShape(RoundedRectangle(cornerRadius: 227.5))
}

#Preview("活力版") {
    AppIconPreviewVibrant()
        .clipShape(RoundedRectangle(cornerRadius: 227.5))
}
