# IdeaCapture 导出功能指南

## 📤 功能概述

Web 查看器现已支持将想法导出到以下三个平台：

| 平台 | 图标 | 功能 | 输出格式 |
|------|------|------|----------|
| **Notion** | 📤 | 直接创建页面到 Notion 数据库 | Notion 页面 |
| **Anki** | 🗂️ | 生成 Anki 卡片文件 | TXT 文件（可导入 Anki） |
| **Obsidian** | 📝 | 生成 Markdown 笔记 | MD 文件（含 YAML frontmatter） |

## 🚀 快速开始

### 1. Notion 导出（需配置）

#### 前置准备

**步骤 1：创建 Notion Integration**

1. 访问 https://www.notion.so/my-integrations
2. 点击 "+ New integration"
3. 填写基本信息：
   - Name: IdeaCapture
   - Associated workspace: 选择你的工作空间
   - Type: Internal Integration
4. 点击 "Submit"
5. 复制生成的 **Internal Integration Token**（格式：`secret_xxx`）

**步骤 2：创建 Notion 数据库**

1. 在 Notion 中创建一个新页面
2. 添加一个 Database（Table 或 Board 视图均可）
3. 确保数据库包含以下属性：
   - **Name** (Title) - 自动创建
   - **Tags** (Multi-select) - 可选
   - **Created** (Date) - 可选

**步骤 3：分享数据库给 Integration**

1. 打开数据库页面
2. 点击右上角 "..." → "Add connections"
3. 选择你刚创建的 "IdeaCapture" Integration

**步骤 4：获取数据库 ID**

数据库 ID 在 URL 中：
```
https://www.notion.so/workspace/{database_id}?v={view_id}
                               ^^^^^^^^^^^^^^^^
```
复制这个 32 位字符的 ID（不含连字符）

**步骤 5：配置环境变量**

编辑 `IdeaCapture/IdeaCapture/.env` 文件，添加：

```bash
# Notion 配置
NOTION_TOKEN=secret_your_integration_token_here
NOTION_DATABASE_ID=your_database_id_here
```

**步骤 6：重启服务器**

```bash
cd IdeaCapture/web
./start.sh
```

#### 使用方法

1. 打开 Web 查看器：http://localhost:8080
2. 找到要导出的想法卡片
3. 点击卡片底部的 **"📤 Notion"** 按钮
4. 等待导出完成（按钮显示"导出中..."）
5. 导出成功后会提示，可选择打开 Notion 页面查看

#### 导出内容

- ✅ 标题
- ✅ 完整内容（自动分段）
- ✅ 标签（Multi-select）
- ✅ 创建时间
- ⚠️ 图片 URL（存在 image_url 字段，但 Notion API 暂不支持直接嵌入外部图片）

### 2. Anki 导出（无需配置）

#### 使用方法

1. 点击想法卡片底部的 **"🗂️ Anki"** 按钮
2. 浏览器自动下载 `.txt` 文件
3. 打开 Anki
4. 选择 **File → Import**
5. 选择下载的 `.txt` 文件
6. 设置导入选项：
   - **Field separator**: Tab
   - **Allow HTML in fields**: ✅ 勾选
   - **Deck**: 选择目标牌组
7. 点击 **Import**

#### 卡片格式

- **正面**：标题 + 标签
- **背面**：完整内容
- **Tags**：自动导入

示例：
```
正面：
【想法标题】
#标签1 #标签2

背面：
想法的详细内容...
```

### 3. Obsidian 导出（无需配置）

#### 使用方法

1. 点击想法卡片底部的 **"📝 Obsidian"** 按钮
2. 浏览器自动下载 `.md` 文件
3. 将文件移动到你的 Obsidian vault 目录
4. 在 Obsidian 中打开查看

#### 文件格式

文件名格式：`YYYY-MM-DD-标题.md`

示例：
```markdown
---
tags: [标签1, 标签2]
created: 2026-02-02T10:30:00
source: IdeaCapture
type: idea
---

# 想法标题

想法的详细内容...
```

#### 特性

- ✅ YAML frontmatter（标签、时间、来源）
- ✅ 标准 Markdown 格式
- ✅ 与 Obsidian 生态完全兼容
- ✅ 支持双链、标签系统

## ⚙️ 高级配置

### Notion 数据库自定义

你可以在 Notion 数据库中添加更多属性：

| 属性名 | 类型 | 说明 |
|--------|------|------|
| Status | Select | 想法状态（如：待处理、进行中、已完成） |
| Priority | Select | 优先级 |
| Project | Relation | 关联到项目 |
| Notes | Text | 额外笔记 |

**注意**：IdeaCapture 只会填充 Name、Tags 和 Created 字段，其他字段需要手动填写。

### Anki 卡片类型

默认使用基础卡片类型（Basic）。如需自定义：

1. 在 Anki 中创建新的卡片类型
2. 添加字段：Front、Back、Tags
3. 导入时选择对应的卡片类型

### Obsidian 插件推荐

增强导入体验的插件：

- **Dataview**: 查询和展示想法
- **Tag Wrangler**: 管理标签
- **Calendar**: 按日期浏览想法
- **Excalidraw**: 为想法添加手绘图

## 🔧 故障排查

### Notion 导出失败

**错误**: "Notion 配置未设置"
- 检查 `.env` 文件是否包含 `NOTION_TOKEN` 和 `NOTION_DATABASE_ID`
- 确认文件路径正确：`IdeaCapture/IdeaCapture/.env`
- 重启服务器

**错误**: "Failed to create Notion page: 401"
- Integration Token 可能无效或过期
- 重新生成 Integration Token
- 确认 Token 格式正确（`secret_xxx`）

**错误**: "Failed to create Notion page: 404"
- 数据库 ID 可能错误
- 检查数据库是否存在
- 确认已将数据库分享给 Integration

**错误**: "Failed to create Notion page: 400"
- 数据库缺少必需的属性
- 确保数据库至少有一个 Title 类型的属性

### Anki 导入问题

**问题**: 卡片内容显示为代码
- 确认勾选了 "Allow HTML in fields"
- 重新导入文件

**问题**: 标签未导入
- 检查导入设置中的 "Tags column" 是否设为 3
- 确认文件格式正确（TSV，Tab 分隔）

### Obsidian 无法打开文件

**问题**: 文件乱码
- 检查文件编码是否为 UTF-8
- 使用文本编辑器重新保存为 UTF-8

**问题**: YAML frontmatter 报错
- 检查标签名是否包含特殊字符
- 手动编辑 frontmatter 修正格式

## 📊 批量导出（计划中）

未来版本将支持：
- 选择多个想法批量导出
- 导出全部想法
- 定期自动同步到 Notion

## 🔐 安全说明

### Notion Token 安全

- ✅ Token 存储在本地 `.env` 文件中
- ✅ 不会上传到任何服务器
- ✅ 仅在后端使用，不暴露给前端
- ⚠️ 不要将 `.env` 文件提交到 Git

### 数据隐私

- ✅ 导出过程完全本地化
- ✅ Anki 和 Obsidian 导出不涉及网络传输
- ✅ Notion 导出仅与 Notion API 通信
- ✅ 不会发送数据到第三方服务

## 📚 参考资源

- [Notion API 文档](https://developers.notion.com/)
- [Anki 导入指南](https://docs.ankiweb.net/importing.html)
- [Obsidian 帮助文档](https://help.obsidian.md/)

## 🎯 使用建议

### Notion

适合：
- 需要在线访问和协作
- 想要丰富的数据库功能
- 需要与其他 Notion 页面关联

### Anki

适合：
- 需要记忆和复习想法
- 使用间隔重复学习法
- 移动端学习

### Obsidian

适合：
- 本地存储和隐私
- 需要强大的笔记链接功能
- 使用 Markdown 生态

---

**功能状态**: ✅ 已完成并可用
**最后更新**: 2026-02-02
**版本**: 1.0.0
