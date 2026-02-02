# Supabase 配置指南

## ⚠️ 重要安全提示

本应用使用 **Service Role Key**（服务端密钥）进行验证，此密钥：
- ✅ **绕过所有行级安全策略（RLS）**，拥有完全数据库访问权限
- ✅ **简化配置**，无需设置复杂的 RLS 策略
- ⚠️ **高度敏感**，请勿泄露或提交到公共代码仓库
- ⚠️ **仅适合个人使用**，如需多用户共享，请改用 Anon Key + RLS 方案

---

## 📝 步骤1：填写 .env 文件

打开 `IdeaCapture/.env` 文件，填入您的 Supabase 配置：

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
```

### 如何获取这些信息？

1. 登录 [Supabase Dashboard](https://supabase.com/dashboard)
2. 选择您的项目
3. 点击左侧菜单的 **Settings** -> **API**
4. 复制以下内容：
   - **Project URL** -> `SUPABASE_URL`
   - **service_role key**（点击"Reveal"显示）-> `SUPABASE_SERVICE_ROLE_KEY`

**注意**：Service Role Key 默认是隐藏的，需要点击"Reveal"按钮才能看到。

---

## 🗄️ 步骤2：创建数据库表

在 Supabase Dashboard 中：

1. 点击左侧菜单的 **SQL Editor**
2. 点击 **New Query**
3. 粘贴以下 SQL 并点击 **Run**：

```sql
-- 创建 ideas 表
CREATE TABLE ideas (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    tags TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
    image_data TEXT
);

-- 创建索引以提升查询性能
CREATE INDEX idx_ideas_created_at ON ideas(created_at DESC);
CREATE INDEX idx_ideas_tags ON ideas USING GIN(tags);
```

**注意**：由于使用 Service Role Key 进行验证，该密钥会自动绕过所有行级安全策略（RLS），因此**不需要**配置 RLS 策略。如果您希望更安全的多用户访问控制，请考虑使用 Anon Key + RLS 方案。


---

## ✅ 步骤3：验证配置

运行 iOS 应用后，查看 Xcode 控制台：

- ✅ 如果看到 `🟦 [Supabase] 初始化配置: - baseURL: https://...`，说明配置成功
- ❌ 如果看到 `⚠️ Supabase未配置`，请检查 `.env` 文件

---

## 🌐 步骤4：网页端查看（可选）

在 `web/` 文件夹中有一个简单的网页界面，可以在电脑浏览器中查看您的想法。

使用方法：
1. 在浏览器中打开 `web/index.html`
2. 在页面顶部填入您的 Supabase URL 和 Service Role Key
3. 点击"加载想法"即可查看所有同步的想法

**安全警告**：网页端使用 Service Role Key，此密钥会在浏览器中暴露。请仅在私密、安全的本地环境中使用，切勿在公共场所或不安全的网络环境下打开。

---

## 🔒 安全提示

⚠️ **重要**：
- `.env` 文件包含敏感信息，**不要**提交到 Git
- Anon Key 是公开密钥，可以在客户端使用
- 生产环境请配置更严格的 RLS 策略
- 考虑使用 Supabase Auth 进行用户认证

---

## 📱 功能说明

### 自动云同步
- 保存新想法时自动上传到 Supabase
- 失败时会在控制台显示错误信息
- 成功后想法会标记为"已同步"

### 手动云同步
- 在想法列表页面下拉刷新
- 点击"设置"中的"立即同步"按钮
- 会批量上传所有未同步的想法

### 网页端查看
- 在任何设备的浏览器中查看
- 实时显示最新同步的想法
- 支持搜索和标签过滤
