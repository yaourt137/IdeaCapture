"""Notion 导出服务"""

from datetime import datetime
from typing import Any

import httpx


class NotionError(Exception):
    """Notion API 错误"""

    def __init__(self, message: str, status_code: int | None = None):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)


class NotionService:
    """Notion API 服务类"""

    BASE_URL = "https://api.notion.com/v1"
    API_VERSION = "2022-06-28"

    def __init__(self, token: str):
        if not token:
            raise NotionError("Notion token is required")
        self.token = token

    def _get_headers(self) -> dict[str, str]:
        """获取请求头"""
        return {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json",
            "Notion-Version": self.API_VERSION,
        }

    async def create_page(
        self,
        database_id: str,
        title: str,
        content: str,
        tags: list[str],
        created_at: datetime | None = None,
    ) -> dict[str, Any]:
        """
        在 Notion 数据库中创建页面

        Args:
            database_id: Notion 数据库 ID
            title: 页面标题
            content: 页面内容
            tags: 标签列表
            created_at: 创建时间

        Returns:
            创建的页面信息，包含 URL
        """
        if created_at is None:
            created_at = datetime.now()

        # 先获取数据库结构，了解有哪些属性
        db_info = await self.get_database(database_id)
        db_properties = db_info.get("properties", {})
        
        # 找到 title 类型的属性名（可能不叫 "Name"）
        title_property_name = "Name"
        for prop_name, prop_info in db_properties.items():
            if prop_info.get("type") == "title":
                title_property_name = prop_name
                break

        # 构建页面属性 - 只添加标题（必需）
        properties: dict[str, Any] = {
            title_property_name: {"title": [{"text": {"content": title}}]},
        }

        # 查找 multi_select 类型的属性用于标签
        if tags:
            for prop_name, prop_info in db_properties.items():
                if prop_info.get("type") == "multi_select":
                    properties[prop_name] = {"multi_select": [{"name": tag} for tag in tags]}
                    break

        # 查找 date 类型的属性用于创建时间
        for prop_name, prop_info in db_properties.items():
            if prop_info.get("type") == "date":
                properties[prop_name] = {"date": {"start": created_at.isoformat()}}
                break

        # 构建页面内容块
        children = self._build_content_blocks(content)

        payload = {
            "parent": {"database_id": database_id},
            "properties": properties,
            "children": children,
        }

        async with httpx.AsyncClient(timeout=30.0, follow_redirects=True) as client:
            response = await client.post(
                f"{self.BASE_URL}/pages",
                headers=self._get_headers(),
                json=payload,
            )

            if response.status_code != 200:
                raise NotionError(
                    f"Failed to create Notion page: {response.text}",
                    status_code=response.status_code,
                )

            result = response.json()
            return {
                "id": result.get("id"),
                "url": result.get("url"),
                "created_time": result.get("created_time"),
            }

    def _build_content_blocks(self, content: str) -> list[dict[str, Any]]:
        """
        将文本内容转换为 Notion 块

        Args:
            content: 文本内容

        Returns:
            Notion 块列表
        """
        blocks = []
        paragraphs = content.split("\n\n")

        for paragraph in paragraphs:
            if not paragraph.strip():
                continue

            # 处理每个段落，Notion 单个文本块有 2000 字符限制
            lines = paragraph.split("\n")
            for line in lines:
                if not line.strip():
                    continue

                # 分割长文本
                chunks = self._split_text(line, max_length=2000)
                for chunk in chunks:
                    blocks.append(
                        {
                            "object": "block",
                            "type": "paragraph",
                            "paragraph": {
                                "rich_text": [{"type": "text", "text": {"content": chunk}}]
                            },
                        }
                    )

        return blocks

    def _split_text(self, text: str, max_length: int = 2000) -> list[str]:
        """
        分割长文本

        Args:
            text: 原文本
            max_length: 最大长度

        Returns:
            分割后的文本列表
        """
        if len(text) <= max_length:
            return [text]

        chunks = []
        while text:
            if len(text) <= max_length:
                chunks.append(text)
                break

            # 尝试在句号、逗号或空格处分割
            split_pos = max_length
            for sep in ["。", "，", ".", ",", " "]:
                pos = text.rfind(sep, 0, max_length)
                if pos > 0:
                    split_pos = pos + 1
                    break

            chunks.append(text[:split_pos])
            text = text[split_pos:]

        return chunks

    async def get_database(self, database_id: str) -> dict[str, Any]:
        """
        获取数据库信息

        Args:
            database_id: 数据库 ID

        Returns:
            数据库信息
        """
        async with httpx.AsyncClient(timeout=30.0, follow_redirects=True) as client:
            response = await client.get(
                f"{self.BASE_URL}/databases/{database_id}",
                headers=self._get_headers(),
            )

            if response.status_code != 200:
                raise NotionError(
                    f"Failed to get Notion database: {response.text}",
                    status_code=response.status_code,
                )

            return response.json()
