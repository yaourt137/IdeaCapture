# GitHub 上传指南 📦

本文档说明如何将 IdeaCapture 项目安全地上传到 GitHub。

## ✅ 已完成的安全措施

### 1. `.gitignore` 配置
已配置忽略以下敏感文件：
- ✅ `.env` - 环境变量配置文件
- ✅ `web/venv/` - Python 虚拟环境
- ✅ `web/__pycache__/` - Python 缓存
- ✅ Xcode 用户数据和构建产物
- ✅ macOS 系统文件

### 2. 文档脱敏
已脱敏以下文档中的敏感信息：
- ✅ `README.md` - 移除了真实的 API Token
- ✅ `SUPABASE_MIGRATION.md` - 移除了真实的项目 ID 和 Keys
- ✅ `WEB_REFACTOR.md` - 移除了真实配置
- ✅ `web/QUICKSTART.md` - 移除了真实配置

### 3. `.env.example` 示例文件
已创建脱敏的示例文件：
- ✅ `.env.example` - 包含完整的配置模板（无真实值）

### 4. 代码验证
已验证以下代码无硬编码：
- ✅ 所有 Swift 文件从 `.env` 读取配置
- ✅ 所有 Python 文件使用 `os.getenv()`
- ✅ Web 端从后端 API 获取配置
- ✅ 无硬编码的 API Keys、Tokens 或敏感 URL

## 🚀 上传到 GitHub

### 步骤 1: 初始化 Git 仓库（如果尚未初始化）

```bash
cd "/Users/yao/Desktop/Vibe Coding Projects/拍照到导入/IdeaCapture"

# 初始化 git 仓库
git init

# 添加所有文件（.gitignore 会自动排除敏感文件）
git add .

# 创建首次提交
git commit -m "Initial commit: IdeaCapture v1.0.0

- iOS 端：拍照 OCR + AI 标签 + 云同步
- Web 端：想法管理 + 多平台导出（Notion/Anki/Obsidian）
- 技术栈：Swift + SwiftUI + FastAPI + Supabase
"
```

### 步骤 2: 创建 GitHub 仓库

1. 访问 https://github.com/new
2. 仓库名称：`IdeaCapture`（或其他名称）
3. 描述：`拍照记录想法，一键导出到 Notion/Anki/Obsidian`
4. 选择 **Public**（开源）或 **Private**（私有）
5. **不要**勾选 "Initialize this repository with a README"（我们已有 README）
6. 点击 "Create repository"

### 步骤 3: 推送到 GitHub

```bash
# 添加远程仓库（替换为你的 GitHub 用户名）
git remote add origin https://github.com/你的用户名/IdeaCapture.git

# 推送到 main 分支
git branch -M main
git push -u origin main
```

## ⚠️ 上传前最终检查

在执行 `git push` 之前，请确认：

```bash
# 1. 检查将要提交的文件
git status

# 2. 确认 .env 文件被忽略（应该不在列表中）
git status | grep ".env"

# 3. 查看 .gitignore 是否正常工作
git check-ignore -v IdeaCapture/.env
# 应该输出：.gitignore:3:.env	IdeaCapture/.env

# 4. 确认没有敏感文件被跟踪
git ls-files | grep -E "\.env$|venv/|__pycache__"
# 应该没有输出

# 5. 搜索代码中是否有真实的 API Keys（应该无结果）
grep -r "sk_1dc2f89b\|ntn_\|sb_publishable_1DN6" --include="*.swift" --include="*.py" .
```

## 📝 仓库描述建议

### 短描述
```
拍照记录想法，一键导出到 Notion/Anki/Obsidian。iOS + Web 双端同步，支持 OCR 识别和 AI 标签推荐。
```

### Topics（标签）
建议添加以下标签：
- `swift`
- `swiftui`
- `ios`
- `ocr`
- `notion`
- `anki`
- `obsidian`
- `supabase`
- `fastapi`
- `python`
- `idea-management`
- `note-taking`

## 🔒 保持 .env 文件私密

**重要提示**：
- ✅ `.env` 文件**已经在** `.gitignore` 中
- ✅ 永远**不要**运行 `git add -f .env`（强制添加）
- ✅ 如果不小心提交了 `.env`，立即参考下面的"紧急处理"

### 紧急处理：如果不小心提交了 .env

```bash
# 1. 从 Git 历史中移除文件
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch IdeaCapture/.env" \
  --prune-empty --tag-name-filter cat -- --all

# 2. 强制推送到 GitHub
git push origin --force --all

# 3. 立即更换所有泄露的密钥
# - 重新生成 Supabase Publishable Key
# - 重新生成 AI Builder Token
# - 重新生成 Notion Token
```

## 🎉 后续维护

### 添加新功能后提交

```bash
git add .
git commit -m "feat: 添加批量导出功能"
git push
```

### 创建新版本 Tag

```bash
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

### 更新 README

```bash
git add README.md
git commit -m "docs: 更新安装说明"
git push
```

## 📖 参考资源

- [GitHub 官方指南](https://docs.github.com/cn)
- [.gitignore 最佳实践](https://github.com/github/gitignore)
- [保护敏感数据](https://docs.github.com/cn/code-security/getting-started/securing-your-repository)

---

**准备好了吗？开始上传吧！** 🚀
