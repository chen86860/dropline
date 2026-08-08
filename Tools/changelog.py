#!/usr/bin/env python3
"""从 CHANGELOG 抽取某个版本的条目。

    changelog.py 1.1.0                  # 输出 Markdown（用作 GitHub Release 正文）
    changelog.py 1.1.0 --html           # 输出完整 HTML 文档
    changelog.py 1.1.0 --fragment       # 输出 HTML 片段（无 DOCTYPE/body，供 Sparkle 内嵌进 appcast）
    changelog.py 1.1.0 --lang zh ...    # 改读中文版 CHANGELOG.zh-CN.md（默认 en）
    changelog.py --latest               # 打印最新版本号

英文的 CHANGELOG.md 是主文件，中文对照在 CHANGELOG.zh-CN.md。
找不到该版本时以非零状态退出，好让发布脚本及时中止。
"""
import html
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FILES = {"en": ROOT / "CHANGELOG.md", "zh": ROOT / "CHANGELOG.zh-CN.md"}


def changelog(lang: str = "en") -> Path:
    path = FILES.get(lang)
    if path is None:
        sys.exit(f"未知语言 {lang}，可选：{', '.join(FILES)}")
    return path


def section(version: str, lang: str = "en") -> str:
    path = changelog(lang)
    if not path.exists():
        sys.exit(f"找不到 {path}")
    text = path.read_text(encoding="utf-8")
    # 匹配 "## [1.1.0] - 2026-08-07" 或 "## 1.1.0"，取到下一个 "## " 之前
    pattern = rf"^##\s+\[?{re.escape(version)}\]?[^\n]*\n(.*?)(?=^##\s|\Z)"
    m = re.search(pattern, text, re.MULTILINE | re.DOTALL)
    if not m:
        sys.exit(f"{path.name} 里没有 {version} 的条目，请先补上再发版")
    body = m.group(1).strip()
    if not body:
        sys.exit(f"{path.name} 里 {version} 的条目是空的")
    return body


def inline(md: str) -> str:
    """行内 Markdown → HTML。"""
    out = html.escape(md)
    out = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', out)
    out = re.sub(r"\*\*([^*]+)\*\*", r"<b>\1</b>", out)
    out = re.sub(r"`([^`]+)`", r"<code>\1</code>", out)
    return out


def to_fragment(md: str) -> str:
    """Markdown → HTML 片段。

    不带 DOCTYPE / body：generate_appcast 见到这样的片段会把它直接内嵌进
    appcast 的 <description> CDATA 里，于是更新说明不再需要单独托管一个 HTML 文件。
    """
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

    return "\n".join(parts) + "\n"


def to_html(md: str) -> str:
    """Markdown → 完整 HTML 文档。"""
    return (
        '<!DOCTYPE html>\n<html lang="zh-CN">\n<head><meta charset="utf-8"></head>\n'
        '<body style="font: 13px -apple-system, BlinkMacSystemFont, sans-serif; color: #222;">\n'
        + to_fragment(md).rstrip("\n")
        + "\n</body>\n</html>\n"
    )


def latest() -> str:
    """CHANGELOG 里最上面那个版本号（以英文主文件为准）。"""
    path = changelog("en")
    if not path.exists():
        sys.exit(f"找不到 {path}")
    m = re.search(r"^##\s+\[?(\d+\.\d+\.\d+)\]?", path.read_text(encoding="utf-8"), re.MULTILINE)
    if not m:
        sys.exit(f"{path.name} 里没有任何版本条目")
    return m.group(1)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    if sys.argv[1] == "--latest":
        print(latest())
    else:
        lang = "en"
        if "--lang" in sys.argv:
            i = sys.argv.index("--lang")
            if i + 1 >= len(sys.argv):
                sys.exit("--lang 后面要跟语言代码，如 --lang zh")
            lang = sys.argv[i + 1]
        body = section(sys.argv[1], lang)
        if "--fragment" in sys.argv:
            print(to_fragment(body), end="")
        elif "--html" in sys.argv:
            print(to_html(body), end="")
        else:
            print(body)
