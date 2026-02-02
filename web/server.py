#!/usr/bin/env python3
"""
IdeaCapture Web 查看器 - 简单后端服务
提供 Supabase 配置、静态文件服务和导出功能
"""

import os
from pathlib import Path
from datetime import datetime
from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse, JSONResponse, PlainTextResponse, Response
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from dotenv import load_dotenv

from services.notion import NotionService, NotionError
from services.anki import AnkiService
from services.obsidian import ObsidianService

# 加载环境变量（从上级目录的 IdeaCapture/.env）
env_path = Path(__file__).parent.parent / "IdeaCapture" / ".env"
load_dotenv(env_path, override=True)  # 强制覆盖已存在的环境变量

app = FastAPI(
    title="IdeaCapture Web Viewer",
    description="网页查看器 - 查看 Supabase 中的想法",
    version="1.0.0",
)

# CORS 配置
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def serve_html():
    """提供主页面（注入配置）"""
    html_path = Path(__file__).parent / "index.html"
    with open(html_path, "r", encoding="utf-8") as f:
        html_content = f.read()
    return HTMLResponse(content=html_content)


@app.get("/api/config")
async def get_config():
    """
    获取 Supabase 配置

    返回客户端安全的 publishable key，而不是 service role key
    """
    supabase_url = os.getenv("SUPABASE_URL", "")
    supabase_key = os.getenv("SUPABASE_PUBLISHABLE_KEY", "")

    if not supabase_url or not supabase_key:
        return JSONResponse(
            status_code=500,
            content={
                "error": "Supabase 配置未设置",
                "message": "请在 IdeaCapture/IdeaCapture/.env 文件中配置 SUPABASE_URL 和 SUPABASE_PUBLISHABLE_KEY"
            }
        )

    return {
        "supabase_url": supabase_url,
        "supabase_key": supabase_key,
        "configured": True
    }


@app.get("/health")
async def health_check():
    """健康检查"""
    return {
        "status": "healthy",
        "service": "IdeaCapture Web Viewer"
    }


# ============ 导出功能 ============

class ExportRequest(BaseModel):
    """导出请求"""
    title: str = Field(..., description="想法标题")
    content: str = Field(..., description="想法内容")
    tags: list[str] = Field(default=[], description="标签列表")
    created_at: str | None = Field(None, description="创建时间")
    image_url: str | None = Field(None, description="图片URL")


class NotionExportResponse(BaseModel):
    """Notion 导出响应"""
    success: bool
    page_id: str | None = None
    page_url: str | None = None
    message: str | None = None


@app.post("/api/export/notion", response_model=NotionExportResponse)
async def export_to_notion(request: ExportRequest) -> NotionExportResponse:
    """导出到 Notion"""
    notion_token = os.getenv("NOTION_TOKEN", "")
    notion_database_id = os.getenv("NOTION_DATABASE_ID", "")

    if not notion_token or not notion_database_id:
        raise HTTPException(
            status_code=500,
            detail="Notion 配置未设置，请在 .env 文件中配置 NOTION_TOKEN 和 NOTION_DATABASE_ID"
        )

    try:
        service = NotionService(token=notion_token)

        # 解析创建时间
        created_at = None
        if request.created_at:
            try:
                created_at = datetime.fromisoformat(request.created_at.replace('Z', '+00:00'))
            except:
                created_at = None

        result = await service.create_page(
            database_id=notion_database_id,
            title=request.title,
            content=request.content,
            tags=request.tags,
            created_at=created_at,
        )

        return NotionExportResponse(
            success=True,
            page_id=result.get("id"),
            page_url=result.get("url"),
            message="Successfully exported to Notion",
        )

    except NotionError as e:
        raise HTTPException(
            status_code=e.status_code or 500,
            detail=f"Notion export failed: {e.message}",
        ) from e
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Internal error: {str(e)}",
        ) from e


@app.post("/api/export/anki")
async def export_to_anki(request: ExportRequest) -> Response:
    """导出到 Anki"""
    try:
        service = AnkiService()
        ideas_data = [{
            "title": request.title,
            "content": request.content,
            "tags": request.tags,
        }]
        content = service.generate_txt_with_headers(ideas_data)

        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        filename = f"idea-{timestamp}.txt"

        return Response(
            content=content.encode('utf-8'),
            media_type="text/plain; charset=utf-8",
            headers={"Content-Disposition": f'attachment; filename="{filename}"'}
        )

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Anki export failed: {str(e)}",
        ) from e


@app.post("/api/export/obsidian")
async def export_to_obsidian(request: ExportRequest) -> Response:
    """导出到 Obsidian"""
    try:
        service = ObsidianService()

        # 解析创建时间
        created_at = None
        if request.created_at:
            try:
                created_at = datetime.fromisoformat(request.created_at.replace('Z', '+00:00'))
            except:
                created_at = datetime.now()
        else:
            created_at = datetime.now()

        filename = service.generate_filename(request.title, created_at)
        content = service.generate_markdown(
            title=request.title,
            content=request.content,
            tags=request.tags,
            created_at=created_at,
        )

        return Response(
            content=content.encode('utf-8'),
            media_type="text/markdown; charset=utf-8",
            headers={"Content-Disposition": f'attachment; filename="{filename}"'}
        )

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Obsidian export failed: {str(e)}",
        ) from e


if __name__ == "__main__":
    import uvicorn

    print("🚀 启动 IdeaCapture Web 查看器...")
    print(f"📁 环境变量文件: {env_path}")
    print(f"🌐 访问地址: http://localhost:8080")
    print(f"📊 API文档: http://localhost:8080/docs")

    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8080,
        log_level="info"
    )
