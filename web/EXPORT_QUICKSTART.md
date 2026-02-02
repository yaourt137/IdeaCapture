# 导出功能快速开始 ⚡

## 🎯 立即可用（无需配置）

### Anki 导出
1. 点击想法卡片底部的 **🗂️ Anki** 按钮
2. 下载 `.txt` 文件
3. 在 Anki 中：File → Import → 选择文件
4. 设置：Field separator = Tab，Allow HTML = ✅
5. Import

### Obsidian 导出
1. 点击想法卡片底部的 **📝 Obsidian** 按钮
2. 下载 `.md` 文件
3. 移动到 Obsidian vault 目录
4. 完成！

## ⚙️ Notion 导出（需 5 分钟配置）

### 快速配置步骤

**1. 创建 Integration（1 分钟）**
- 访问：https://www.notion.so/my-integrations
- 点击 "+ New integration"
- 命名为 "IdeaCapture"
- 点击 Submit
- **复制 Token**（`secret_xxx`）

**2. 创建数据库（1 分钟）**
- 在 Notion 创建新页面
- 添加 Database（Table 视图）
- 数据库会自动有 Name (Title) 字段

**3. 连接 Integration（30 秒）**
- 在数据库页面点击 "..."
- Add connections → 选择 "IdeaCapture"

**4. 获取数据库 ID（30 秒）**
- 从数据库 URL 复制 ID：
  ```
  https://www.notion.so/{database_id}?v=xxx
                        ^^^^^^^^^^^^^^^^
  ```

**5. 配置环境变量（1 分钟）**

编辑 `IdeaCapture/IdeaCapture/.env`：

```bash
NOTION_TOKEN=secret_你的token
NOTION_DATABASE_ID=你的数据库ID
```

**6. 重启服务器（30 秒）**

```bash
cd IdeaCapture/web
./start.sh
```

### 使用

1. 点击 **📤 Notion** 按钮
2. 等待 2-3 秒
3. 成功后可选择打开 Notion 页面

## ❓ 遇到问题？

查看详细指南：`EXPORT_GUIDE.md`

---

**提示**：Anki 和 Obsidian 导出无需任何配置，立即可用！
