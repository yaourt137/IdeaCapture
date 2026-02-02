"""Obsidian 导出服务"""

import re
from datetime import datetime


class ObsidianService:
    """Obsidian Markdown 导出服务类"""

    @staticmethod
    def sanitize_filename(title: str, max_length: int = 50) -> str:
        """
        清理文件名，移除不合法字符

        Args:
            title: 原标题
            max_length: 最大长度

        Returns:
            安全的文件名
        """
        # 移除或替换不合法字符
        filename = re.sub(r'[<>:"/\\|?*]', "", title)
        # 移除前后空格
        filename = filename.strip()
        # 替换多个空格为单个
        filename = re.sub(r"\s+", " ", filename)
        # 截断长度
        if len(filename) > max_length:
            filename = filename[:max_length].rstrip()
        # 如果为空，使用默认名称
        if not filename:
            filename = "Untitled"
        return filename

    @staticmethod
    def format_tags_yaml(tags: list[str]) -> str:
        """
        格式化标签为 YAML 格式

        Args:
            tags: 标签列表

        Returns:
            YAML 格式的标签字符串
        """
        if not tags:
            return "[]"

        # 处理包含特殊字符的标签
        formatted_tags = []
        for tag in tags:
            # 如果标签包含空格或特殊字符，用引号包围
            if " " in tag or "," in tag or ":" in tag:
                formatted_tags.append(f'"{tag}"')
            else:
                formatted_tags.append(tag)

        return "[" + ", ".join(formatted_tags) + "]"

    def generate_markdown(
        self,
        title: str,
        content: str,
        tags: list[str],
        created_at: datetime | None = None,
        include_image: bool = False,
        image_filename: str | None = None,
    ) -> str:
        """
        生成 Obsidian Markdown 文件内容

        Args:
            title: 想法标题
            content: 想法内容
            tags: 标签列表
            created_at: 创建时间
            include_image: 是否包含图片引用
            image_filename: 图片文件名

        Returns:
            Markdown 格式的字符串
        """
        if created_at is None:
            created_at = datetime.now()

        # YAML frontmatter
        frontmatter = f"""---
tags: {self.format_tags_yaml(tags)}
created: {created_at.strftime("%Y-%m-%dT%H:%M:%S")}
source: IdeaCapture
type: idea
---"""

        # 主体内容
        body_parts = [
            frontmatter,
            "",
            f"# {title}",
            "",
            content,
        ]

        # 如果有图片
        if include_image and image_filename:
            body_parts.extend(
                [
                    "",
                    "## 原始图片",
                    "",
                    f"![[attachments/{image_filename}]]",
                ]
            )

        return "\n".join(body_parts)

    def generate_filename(
        self,
        title: str,
        created_at: datetime | None = None,
    ) -> str:
        """
        生成 Obsidian 文件名

        格式: YYYY-MM-DD-标题简写.md

        Args:
            title: 想法标题
            created_at: 创建时间

        Returns:
            文件名
        """
        if created_at is None:
            created_at = datetime.now()

        date_prefix = created_at.strftime("%Y-%m-%d")
        safe_title = self.sanitize_filename(title, max_length=30)

        return f"{date_prefix}-{safe_title}.md"

    def generate_daily_note_entry(
        self,
        title: str,
        content: str,
        tags: list[str],
        created_at: datetime | None = None,
    ) -> str:
        """
        生成适合追加到 Daily Note 的条目

        Args:
            title: 想法标题
            content: 想法内容
            tags: 标签列表
            created_at: 创建时间

        Returns:
            Daily Note 条目格式的字符串
        """
        if created_at is None:
            created_at = datetime.now()

        time_str = created_at.strftime("%H:%M")
        tags_str = " ".join([f"#{tag.replace(' ', '-')}" for tag in tags])

        entry = f"""
## {time_str} - {title}

{content}

{tags_str}

---
"""
        return entry.strip()
