"""Anki 导出服务"""

import html
from dataclasses import dataclass
from datetime import datetime


@dataclass
class AnkiCard:
    """Anki 卡片数据"""

    front: str  # 正面内容
    back: str  # 背面内容
    tags: list[str]  # 标签


class AnkiService:
    """Anki 导出服务类"""

    @staticmethod
    def escape_html(text: str) -> str:
        """转义 HTML 特殊字符"""
        return html.escape(text).replace("\n", "<br>")

    @staticmethod
    def escape_tsv(text: str) -> str:
        """转义 TSV 特殊字符"""
        # 将换行符替换为 HTML 换行
        text = text.replace("\n", "<br>")
        # 转义制表符
        text = text.replace("\t", " ")
        return text

    def generate_card(
        self,
        title: str,
        content: str,
        tags: list[str],
    ) -> AnkiCard:
        """
        生成 Anki 卡片

        Args:
            title: 想法标题
            content: 想法内容
            tags: 标签列表

        Returns:
            AnkiCard 对象
        """
        # 正面：标题 + 标签
        tags_html = " ".join([f'<span class="tag">{tag}</span>' for tag in tags])
        front = f"<h2>{self.escape_html(title)}</h2><div class='tags'>{tags_html}</div>"

        # 背面：完整内容
        back = f"<div class='content'>{self.escape_html(content)}</div>"

        return AnkiCard(front=front, back=back, tags=tags)

    def generate_tsv(self, ideas: list[dict]) -> str:
        """
        生成 Anki 可导入的 TSV 格式

        TSV 格式：正面<TAB>背面<TAB>标签（空格分隔）

        Args:
            ideas: 想法列表，每个想法包含 title, content, tags

        Returns:
            TSV 格式的字符串
        """
        lines = []

        for idea in ideas:
            title = idea.get("title", "Untitled")
            content = idea.get("content", "")
            tags = idea.get("tags", [])

            card = self.generate_card(title, content, tags)

            # TSV 格式：正面 \t 背面 \t 标签
            front_escaped = self.escape_tsv(card.front)
            back_escaped = self.escape_tsv(card.back)
            tags_str = " ".join([tag.replace(" ", "_") for tag in tags])

            lines.append(f"{front_escaped}\t{back_escaped}\t{tags_str}")

        return "\n".join(lines)

    def generate_txt_with_headers(self, ideas: list[dict]) -> str:
        """
        生成带有 Anki 导入标记的文本文件

        Args:
            ideas: 想法列表

        Returns:
            带标记的文本内容
        """
        header = """#separator:tab
#html:true
#tags column:3
"""
        content = self.generate_tsv(ideas)
        return header + content

    def generate_simple_qa(self, ideas: list[dict]) -> str:
        """
        生成简单的问答格式（适合基础卡片）

        格式：
        Q: 标题
        A: 内容
        Tags: 标签

        Args:
            ideas: 想法列表

        Returns:
            问答格式的文本
        """
        lines = []
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M")
        lines.append(f"# IdeaCapture Export - {timestamp}\n")

        for i, idea in enumerate(ideas, 1):
            title = idea.get("title", "Untitled")
            content = idea.get("content", "")
            tags = idea.get("tags", [])

            lines.append(f"## Card {i}")
            lines.append(f"**Q:** {title}")
            lines.append(f"**A:** {content}")
            if tags:
                lines.append(f"**Tags:** {', '.join(tags)}")
            lines.append("")

        return "\n".join(lines)
