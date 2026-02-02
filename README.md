# IdeaCapture - iOS 想法收集应用

## 📱 功能特性

### ✅ 已实现功能

1. **多种图片输入方式**
   - 📸 相机拍照
   - 🖼️ 从相册选择
   - 📄 文档扫描（VisionKit）

2. **AI 智能识别**
   - 🔍 OCR 手写文字识别（AI Builder API）
   - 🏷️ 智能标签推荐

3. **本地数据管理**
   - 💾 SwiftData 本地存储
   - 🔎 搜索和过滤
   - ✏️ 编辑和标签管理

4. **云端同步（Supabase）**
   - ☁️ 自动云同步（保存时）
   - 🔄 手动同步（下拉刷新）
   - 🌐 网页端查看

5. **导出功能**
   - 📝 纯文本导出
   - 📋 Markdown 导出
   - 📤 系统分享

---

## 🚀 快速开始

### 步骤1：配置环境变量

1. 编辑 `.env` 文件：

```bash
cd IdeaCapture
open .env
```

2. 填入您的配置：

```env
# ==================== AI Builder 配置 ====================
# AI Builder API 基础 URL（通常无需修改）
AI_BUILDER_BASE_URL=https://space.ai-builders.com/backend

# AI Builder API Token（必填）
# 在 https://ai-builders.com 注册并获取
AI_BUILDER_TOKEN=your-ai-builder-token-here

# AI Builder 使用的模型（可选，默认：gemini-2.5-pro）
AI_BUILDER_MODEL=gemini-2.5-pro

# ==================== Supabase 配置 ====================
# Supabase 项目 URL（必填，用于云同步）
SUPABASE_URL=https://your-project.supabase.co

# Supabase Publishable Key（必填，客户端安全密钥）
# 在 Supabase Dashboard -> Settings -> API -> Project API keys -> publishable 找到
# 使用 publishable key 而不是 service role key，更安全且遵守 RLS 策略
SUPABASE_PUBLISHABLE_KEY=sb_publishable_your-key-here
```

**重要提示**：使用 Publishable Key 是安全的做法，它遵守 RLS 策略，适合客户端使用。


### 步骤2：配置 Supabase 数据库
（待补充）
若有AI Coding软件，可用Supabase MCP直接配置好。


### 步骤3：运行应用

1. 用 Xcode 打开 `IdeaCapture.xcodeproj`
2. 选择目标设备或模拟器
3. 运行

---

## 📖 使用指南

### 创建新想法

1. 点击右上角 **+** 按钮
2. 选择图片来源（拍照/相册/扫描）
3. 等待 AI 识别文字和推荐标签
4. 点击"保存"

**自动云同步**：保存后自动上传到 Supabase（如已配置）

### 查看和编辑想法

1. 在列表中点击任意想法
2. 查看详情、标签和创建时间
3. 点击"编辑"可修改标题、内容和标签
4. 同步状态显示在底部（已同步/未同步）

### 导出想法

1. 在详情页点击右上角的 **↑** 按钮
2. 选择导出格式：
   - **纯文本**：复制到剪贴板
   - **Markdown**：复制 Markdown 格式
   - **系统分享**：通过短信、邮件等分享

### 手动云同步

**方式1：下拉刷新**
- 在想法列表页面下拉即可同步所有未同步的想法

**方式2：工具栏按钮**
- 点击右上角的 `☁️` 按钮立即同步

### 网页端查看

1. 启动 Web 服务器：
   ```bash
   cd web
   ./start.sh
   ```
2. 在浏览器访问 `http://localhost:8080`
3. 自动加载所有想法
4. 支持搜索和标签过滤
5. 一键导出到 Notion/Anki/Obsidian

详细配置请查看 `web/README.md`

---

## 🔧 技术架构

```
IdeaCapture/
├── Models/
│   └── Idea.swift                 # 核心数据模型
├── Config/
│   ├── AppConfig.swift             # 应用配置
│   └── EnvReader.swift             # .env 文件读取
├── Services/
│   ├── AIBuilderService.swift      # AI OCR 服务
│   └── SupabaseService.swift       # 云同步服务
├── ViewModels/
│   ├── IdeaCaptureViewModel.swift  # OCR 逻辑
│   └── SyncViewModel.swift         # 同步逻辑
├── Views/
│   ├── IdeaListView.swift          # 想法列表
│   ├── IdeaCaptureView.swift       # OCR 识别
│   ├── IdeaDetailView.swift        # 详情编辑
│   └── ImagePicker.swift           # 图片选择
├── web/
│   └── index.html                  # 网页端查看
├── .env                            # 环境变量配置
└── SUPABASE_SETUP.md              # Supabase 配置指南
```
