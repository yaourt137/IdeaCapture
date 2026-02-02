//
//  EnvReader.swift
//  IdeaCapture
//
//  读取.env文件的配置
//

import Foundation

enum EnvReader {
    /// 从.env文件读取环境变量
    static func readEnvFile() -> [String: String] {
        // 尝试从多个位置查找.env文件
        let possiblePaths: [URL?] = [
            // 方案1：Bundle资源（最可靠）
            Bundle.main.url(forResource: ".env", withExtension: nil),
            Bundle.main.url(forResource: "env", withExtension: nil),

            // 方案2：项目根目录（开发环境）
            URL(fileURLWithPath: #file)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent(".env"),

            // 方案3：相对于当前文件
            URL(fileURLWithPath: #file)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent(".env")
        ]

        for path in possiblePaths.compactMap({ $0 }) {
            print("🔍 尝试读取: \(path.path)")
            if let envVars = readEnvFile(at: path) {
                print("✅ 成功从 \(path.lastPathComponent) 读取环境变量")
                return envVars
            }
        }

        print("⚠️ 未找到.env文件，使用默认配置")
        print("💡 提示：请在 Xcode 中将 .env 文件添加到项目中")
        return [:]
    }

    private static func readEnvFile(at url: URL) -> [String: String]? {
        guard let contents = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }

        var envVars: [String: String] = [:]

        contents.enumerateLines { line, _ in
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // 忽略注释和空行
            guard !trimmed.isEmpty,
                  !trimmed.hasPrefix("#") else {
                return
            }

            // 解析 KEY=VALUE 格式
            let parts = trimmed.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { return }

            let key = String(parts[0]).trimmingCharacters(in: .whitespaces)
            let value = String(parts[1]).trimmingCharacters(in: .whitespaces)

            envVars[key] = value
        }

        return envVars.isEmpty ? nil : envVars
    }
}
