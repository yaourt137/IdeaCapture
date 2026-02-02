# IdeaCapture 图片云同步功能实现

## 📋 功能概述

实现了将想法配图同步到 Supabase Storage 的功能，替代之前的 Base64 编码存储方案。

## 🎯 实现方案

### 之前的方案 ❌

**存储方式**: Base64 编码存储在数据库中

**问题**:
- 数据库体积快速增长
- 有大小限制（通常 1-2MB）
- 查询性能下降
- 不适合大图片

### 现在的方案 ✅

**存储方式**: Supabase Storage + URL 引用

**优点**:
- ✅ 专业的文件存储服务
- ✅ 支持任意大小的图片
- ✅ CDN 加速
- ✅ 数据库保持轻量
- ✅ 更好的性能

## 🏗️ 架构设计

```
┌─────────────────┐
│   iOS App       │
│                 │
│ 1. 拍摄/选择图片│
└────────┬────────┘
         │
         │ 2. 上传图片
         ▼
┌─────────────────┐
│ Supabase Storage│
│  idea-images/   │
│                 │
│  - {uuid}.jpg   │ ← 图片文件
└────────┬────────┘
         │
         │ 3. 返回公开 URL
         ▼
┌─────────────────┐
│  数据库 ideas   │
│                 │
│  - image_url    │ ← 存储 URL
└────────┬────────┘
         │
         │ 4. Web 端获取
         ▼
┌─────────────────┐
│  Web 查看器     │
│                 │
│ <img src=url>   │ ← 显示图片
└─────────────────┘
```

## 📝 实现细节

### 1. 数据库变更

#### 创建 Storage Bucket
```sql
-- 创建公开的图片存储 bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('idea-images', 'idea-images', true);
```

#### 设置 RLS 策略
```sql
-- 允许所有人上传图片
CREATE POLICY "允许所有人上传图片"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'idea-images');

-- 允许所有人读取图片
CREATE POLICY "允许所有人读取图片"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'idea-images');

-- 允许所有人更新图片（支持覆盖已存在的文件）
CREATE POLICY "允许所有人更新图片"
ON storage.objects FOR UPDATE
TO public
USING (bucket_id = 'idea-images')
WITH CHECK (bucket_id = 'idea-images');

-- 允许所有人删除图片
CREATE POLICY "允许所有人删除图片"
ON storage.objects FOR DELETE
TO public
USING (bucket_id = 'idea-images');
```

#### 添加 image_url 字段
```sql
-- 添加新字段存储图片 URL
ALTER TABLE ideas ADD COLUMN IF NOT EXISTS image_url TEXT;

-- 添加注释说明
COMMENT ON COLUMN ideas.image_url IS 'Supabase Storage 中的图片 URL';
COMMENT ON COLUMN ideas.image_data IS '已废弃：使用 image_url 代替。保留用于向后兼容。';
```

### 2. iOS 端实现

#### 更新 SupabaseIdea 模型

**文件**: `IdeaCapture/Services/SupabaseService.swift:11-31`

```swift
struct SupabaseIdea: Codable, Sendable {
    let id: String
    let title: String
    let content: String
    let tags: [String]
    let createdAt: String
    let updatedAt: String
    let imageData: String?  // 已废弃，保留向后兼容
    let imageUrl: String?   // 新增：Storage 中的图片 URL

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case tags
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case imageData = "image_data"
        case imageUrl = "image_url"
    }
}
```

#### 实现图片上传方法

**文件**: `IdeaCapture/Services/SupabaseService.swift:65-96`

```swift
private func uploadImage(_ imageData: Data, ideaId: String) async throws -> String {
    print("🟦 [Supabase] 开始上传图片...")

    // 生成唯一文件名：{ideaId}.jpg
    let fileName = "\(ideaId).jpg"
    let uploadURL = URL(string: "\(baseURL)/storage/v1/object/idea-images/\(fileName)")!

    var request = URLRequest(url: uploadURL)
    request.httpMethod = "PUT"  // 使用 PUT 支持创建或覆盖
    request.setValue(publishableKey, forHTTPHeaderField: "apikey")
    request.setValue("Bearer \(publishableKey)", forHTTPHeaderField: "Authorization")
    request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
    request.setValue("true", forHTTPHeaderField: "x-upsert")  // 明确允许覆盖
    request.httpBody = imageData

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
        throw SupabaseError.invalidResponse
    }

    guard (200...299).contains(httpResponse.statusCode) else {
        let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
        print("🔴 [Supabase] 图片上传失败: \(errorMessage)")
        throw SupabaseError.uploadFailed(statusCode: httpResponse.statusCode, message: errorMessage)
    }

    // 构建公开图片 URL
    let imageURL = "\(baseURL)/storage/v1/object/public/idea-images/\(fileName)"
    print("🟦 [Supabase] 图片上传成功: \(imageURL)")

    return imageURL
}
```

#### 更新上传想法逻辑

**文件**: `IdeaCapture/Services/SupabaseService.swift:99-121`

```swift
func uploadIdea(_ idea: Idea) async throws -> String {
    guard isConfigured else {
        throw SupabaseError.notConfigured
    }

    print("🟦 [Supabase] 开始上传想法: \(idea.title)")

    // 如果有图片，先上传到 Storage
    var imageURL: String? = nil
    if let imageData = idea.imageData {
        imageURL = try await uploadImage(imageData, ideaId: idea.id.uuidString)
    }

    let supabaseIdea = SupabaseIdea(
        id: idea.id.uuidString,
        title: idea.title,
        content: idea.content,
        tags: idea.tags,
        createdAt: idea.createdAt.ISO8601Format(),
        updatedAt: idea.updatedAt.ISO8601Format(),
        imageData: nil,  // 不再使用 Base64
        imageUrl: imageURL
    )

    // ... 后续上传逻辑
}
```

### 3. Web 端实现

#### 添加图片样式

**文件**: `web/index.html:116-127`

```css
.idea-image {
    width: 100%;
    border-radius: 8px;
    margin-bottom: 16px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    cursor: pointer;
    transition: transform 0.3s;
}

.idea-image:hover {
    transform: scale(1.02);
}
```

#### 渲染图片

**文件**: `web/index.html:317-325`

```javascript
${idea.image_url ? `
    <img
        src="${escapeHtml(idea.image_url)}"
        alt="想法配图"
        class="idea-image"
        onclick="window.open('${escapeHtml(idea.image_url)}', '_blank')"
        onerror="this.style.display='none'"
    />
` : ''}
```

**功能说明**:
- 显示图片（如果存在 `image_url`）
- 点击图片在新标签页打开原图
- 图片加载失败时自动隐藏

## 📊 文件命名规则

图片文件名使用想法的 UUID：
```
{ideaId}.jpg
```

**示例**:
```
Storage Path: idea-images/550e8400-e29b-41d4-a716-446655440000.jpg
Public URL:   https://xxx.supabase.co/storage/v1/object/public/idea-images/550e8400-e29b-41d4-a716-446655440000.jpg
```

## 🔄 数据流程

### 上传流程

1. **iOS App 拍摄/选择图片**
2. **调用 `uploadIdea()`**
   - 检查是否有图片数据
   - 如果有，调用 `uploadImage()` 上传到 Storage
   - Storage 返回公开 URL
3. **创建想法记录**
   - `image_url` = Storage 返回的 URL
   - `image_data` = nil（不再使用）
4. **保存到数据库**

### 读取流程

1. **Web 端获取想法列表**
2. **遍历想法，检查 `image_url`**
3. **如果存在，渲染 `<img>` 标签**
4. **浏览器直接从 Supabase Storage CDN 加载图片**

## ⚠️ 向后兼容

### 保留 image_data 字段

虽然不再使用 Base64 编码，但保留了 `image_data` 字段：

**原因**:
- 兼容旧数据（如果之前有使用 Base64 存储）
- 避免破坏性变更
- 平滑迁移

### Web 端兼容处理

可以添加以下逻辑同时支持新旧方案：

```javascript
// 优先使用 image_url，回退到 image_data
const imageSource = idea.image_url ||
    (idea.image_data ? `data:image/jpeg;base64,${idea.image_data}` : null);

if (imageSource) {
    // 显示图片
}
```

## 🧪 测试验证

### 测试步骤

1. **iOS App 测试**
   ```
   1. 在 iOS App 中创建新想法
   2. 选择一张图片
   3. 填写标题和内容
   4. 点击保存
   5. 检查控制台日志，确认图片上传成功
   ```

2. **Supabase Storage 验证**
   ```
   1. 登录 Supabase Dashboard
   2. 进入 Storage -> idea-images
   3. 检查是否有新的 {uuid}.jpg 文件
   4. 点击文件，验证可以预览
   ```

3. **数据库验证**
   ```sql
   SELECT id, title, image_url
   FROM ideas
   WHERE image_url IS NOT NULL;
   ```

4. **Web 端测试**
   ```
   1. 打开 Web 查看器 (http://localhost:8080)
   2. 刷新页面，加载最新数据
   3. 检查想法卡片是否显示图片
   4. 点击图片，验证可以在新标签页打开
   ```

### 预期结果

- ✅ iOS App 显示"图片上传成功"日志
- ✅ Storage 中有对应的图片文件
- ✅ 数据库 `image_url` 字段包含正确的 URL
- ✅ Web 端正确显示图片
- ✅ 图片可以点击放大查看

## 🔐 安全考虑

### RLS 策略

当前策略允许所有人上传/读取/删除图片：

```sql
WITH CHECK (bucket_id = 'idea-images')
USING (bucket_id = 'idea-images')
```

### 生产环境建议

如果需要更严格的权限控制：

```sql
-- 仅允许上传（删除当前策略后）
CREATE POLICY "仅允许认证用户上传"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'idea-images');

-- 读取保持公开
CREATE POLICY "允许所有人读取"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'idea-images');
```

## 📈 性能优化

### 图片压缩建议

在 iOS 端上传前压缩图片：

```swift
// 在 uploadImage 之前
let compressedData = imageData.jpegData(compressionQuality: 0.7)
```

### CDN 缓存

Supabase Storage 自动提供 CDN 缓存，无需额外配置。

## 🐛 故障排查

### 问题 1: 图片上传失败

**错误**: "图片上传失败: 401 Unauthorized"

**原因**: Publishable Key 没有 Storage 上传权限

**解决**:
1. 检查 RLS 策略是否正确设置
2. 验证 bucket 是否标记为 `public`

### 问题 2: Web 端图片不显示

**错误**: 图片位置显示空白

**原因**:
- `image_url` 为空
- URL 不正确
- 图片文件不存在

**解决**:
1. 检查数据库 `image_url` 字段
2. 访问 URL 验证图片是否存在
3. 检查浏览器控制台网络错误

### 问题 3: 图片上传很慢

**原因**: 图片文件太大

**解决**:
1. iOS 端添加图片压缩
2. 限制图片最大尺寸（如 1920x1920）

## 📚 相关资源

- [Supabase Storage 文档](https://supabase.com/docs/guides/storage)
- [Supabase Storage RLS](https://supabase.com/docs/guides/storage/security/access-control)
- [主项目重构文档](SUPABASE_MIGRATION.md)

## 🎉 实现成果

### 功能完整性

- ✅ iOS App 可以上传图片
- ✅ 图片存储在 Supabase Storage
- ✅ Web 端可以查看图片
- ✅ 向后兼容旧数据

### 技术优势

- 🚀 专业的文件存储方案
- 📦 数据库保持轻量
- ⚡ CDN 加速，加载快速
- 🔒 支持 RLS 权限控制

---

**实现日期**: 2026-01-31
**实现人员**: Claude (AI Assistant)
**功能状态**: ✅ 已完成，待测试验证
