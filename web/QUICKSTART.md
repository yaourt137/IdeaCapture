# IdeaCapture Web 查看器 - 快速开始

## ✅ 已完成设置

- ✅ 虚拟环境已创建 (`venv/`)
- ✅ 依赖已安装 (FastAPI, Uvicorn, python-dotenv)
- ✅ 配置已就绪

## 🚀 启动服务器

### 方法一：使用启动脚本（推荐）

```bash
cd IdeaCapture/web
./start.sh
```

### 方法二：手动启动

```bash
cd IdeaCapture/web

# 激活虚拟环境
source venv/bin/activate

# 启动服务器
python server.py
```

## 🌐 访问页面

启动后打开浏览器访问：

- **主页**: http://localhost:8080
- **API 文档**: http://localhost:8080/docs
- **健康检查**: http://localhost:8080/health

## 📋 预期行为

1. 页面自动加载 Supabase 配置
2. 显示绿色配置成功提示
3. 自动加载所有想法
4. 支持实时搜索

## 🔧 如何停止服务器

在终端按 `Ctrl + C`

## ⚠️ 常见问题

### Q: 配置加载失败
**A**: 检查 `IdeaCapture/IdeaCapture/.env` 文件是否包含：
```bash
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_your-key-here
```

### Q: 端口被占用
**A**: 修改 `server.py` 中的端口号：
```python
uvicorn.run(
    app,
    host="0.0.0.0",
    port=8081,  # 改为其他端口
    log_level="info"
)
```

### Q: 想法加载失败
**A**:
1. 检查 Publishable Key 是否正确
2. 验证 Supabase 项目是否正常运行
3. 检查 RLS 策略是否允许读取

## 📚 更多信息

查看完整文档：
- [README.md](README.md) - 详细使用说明
- [WEB_REFACTOR.md](../WEB_REFACTOR.md) - 重构说明

---

**提示**: 首次使用建议阅读 README.md 了解更多功能
