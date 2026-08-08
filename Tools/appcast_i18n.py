#!/usr/bin/env python3
"""给 appcast 里的每个条目补上中文更新说明。

    appcast_i18n.py <appcast.xml> <releases 目录>

generate_appcast 只会为每个安装包内嵌一份说明（我们喂给它的是英文）。Sparkle 支持在同一个
条目里放多份带 xml:lang 的 <description>，它用 NSBundle.preferredLocalizationsFromArray:
挑一条 —— 也就是跟着 AppleLanguages 走（见 SUAppcast.m）。所以这里：

  1. 给 generate_appcast 内嵌的那份标上 xml:lang="en"；
  2. 如果 releases 目录里有 Dropline-<版本>.zh-Hans.html，再插一份 xml:lang="zh-Hans"。

注意 Sparkle 的实现要求「同名元素出现多个时每个都要显式写 xml:lang」，缺一个只会退回 en
并在日志里报错，所以两份都必须标。
"""
import pathlib
import re
import sys

ZH = "zh-Hans"


def localize(item: str, releases: pathlib.Path) -> str:
    version = re.search(r"<sparkle:version>([^<]+)</sparkle:version>", item)
    if not version:
        return item

    # 先给已有的英文说明标上语言；没有说明的条目（老版本没写 CHANGELOG）直接跳过
    item, tagged = re.subn(r"<description>", '<description xml:lang="en">', item, count=1)
    if not tagged:
        return item

    zh_file = releases / f"Dropline-{version.group(1)}.{ZH}.html"
    if not zh_file.exists():
        print(f"  {version.group(1)}: 没有中文说明，只留英文", file=sys.stderr)
        return item

    zh = zh_file.read_text(encoding="utf-8").strip()

    def append(match: re.Match) -> str:
        indent = " " * 12
        return f'{match.group(0)}\n{indent}<description xml:lang="{ZH}"><![CDATA[{zh}]]></description>'

    item = re.sub(r'<description xml:lang="en">.*?</description>', append, item,
                  count=1, flags=re.DOTALL)
    print(f"  {version.group(1)}: en + {ZH}", file=sys.stderr)
    return item


def main() -> None:
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    appcast, releases = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
    xml = appcast.read_text(encoding="utf-8")
    xml = re.sub(r"<item>.*?</item>",
                 lambda m: localize(m.group(0), releases), xml, flags=re.DOTALL)
    appcast.write_text(xml, encoding="utf-8")


if __name__ == "__main__":
    main()
