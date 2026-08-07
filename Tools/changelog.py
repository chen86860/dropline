#!/usr/bin/env python3
"""从 CHANGELOG.md 抽取某个版本的条目。

    changelog.py 1.1.0            # 输出 Markdown（用作 GitHub Release 正文）
    changelog.py 1.1.0 --html     # 输出 HTML（用作 Sparkle 更新弹窗说明）

找不到该版本时以非零状态退出，好让发布脚本及时中止。
"""
import html
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CHANGELOG = ROOT / "CHANGELOG.md"


def section(version: str) -> str:
    if not CHANGELOG.exists():
        sys.exit(f"找不到 {CHANGELOG}")
    text = CHANGELOG.read_text(encoding="utf-8")
    # 匹配 "## [1.1.0] - 2026-08-07" 或 "## 1.1.0"，取到下一个 "## " 之前
    pattern = rf"^##\s+\[?{re.escape(version)}\]?[^\n]*\n(.*?)(?=^##\s|\Z)"
    m = re.search(pattern, text, re.MULTILINE | re.DOTALL)
    if not m:
        sys.exit(f"CHANGELOG.md 里没有 {version} 的条目，请先补上再发版")
    body = m.group(1).strip()
    if not body:
        sys.exit(f"CHANGELOG.md 里 {version} 的条目是空的")
    return body


def inline(md: str) -> str:
    """行内 Markdown → HTML。"""
    out = html.escape(md)
    out = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', out)
    out = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", out)
    out = re.sub(r"`([^`]+)`", r"<code>\1</code>", out)
    return out


def to_html(md: str) -> str:
    lines, parts, bullets = md.split("\n"), [], []

    def flush():
        if bullets:
            parts.append("<ul>" + "".join(f"<li>{b}</li>" for b in bullets) + "</ul>")
            bullets.clear()

    for raw in lines:
        line = raw.rstrip()
        if not line.strip():
            continue
        if line.startswith("#"):
            flush()
            level = len(line) - len(line.lstrip("#"))
            parts.append(f"<h{max(3, level)}>{inline(line.lstrip('#').strip())}</h{max(3, level)}>")
        elif line.lstrip().startswith(("- ", "* ")):
            bullets.append(inline(line.lstrip()[2:].strip()))
        elif bullets and raw.startswith(("  ", "\t")):
            bullets[-1] += " " + inline(line.strip())   # 列表项的续行
        else:
            flush()
            parts.append(f"<p>{inline(line.strip())}</p>")
    flush()

    return (
        '<!DOCTYPE html>\n<html lang="zh-CN">\n<head><meta charset="utf-8"></head>\n'
        '<body style="font: 13px -apple-system, BlinkMacSystemFont, sans-serif; color: #222;">\n'
        + "\n".join(parts)
        + "\n</body>\n</html>\n"
    )


def latest() -> str:
    """CHANGELOG 里最上面那个版本号。"""
    if not CHANGELOG.exists():
        sys.exit(f"找不到 {CHANGELOG}")
    m = re.search(r"^##\s+\[?(\d+\.\d+\.\d+)\]?", CHANGELOG.read_text(encoding="utf-8"), re.MULTILINE)
    if not m:
        sys.exit("CHANGELOG.md 里没有任何版本条目")
    return m.group(1)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    if sys.argv[1] == "--latest":
        print(latest())
    else:
        body = section(sys.argv[1])
        print(to_html(body) if "--html" in sys.argv else body)
