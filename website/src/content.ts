/**
 * Every user-facing string on the page, in both languages.
 *
 * Facts here are drawn from the repository README — nothing is invented.
 * If a claim is not in the README or the source, it does not belong in here.
 */

export type Lang = "en" | "zh";

export const LANGS: readonly Lang[] = ["en", "zh"];

/** Where each language lives. `/` is English so the bare domain is the default. */
export const PATH_FOR: Record<Lang, string> = { en: "/", zh: "/zh" };

export const REPO = "https://github.com/chen86860/dropline";
/**
 * Direct download. The release asset carries no version number, so
 * `/releases/latest/download/…` always resolves to the newest stable build —
 * the button downloads the DMG instead of dropping people on the Releases page.
 */
export const DOWNLOAD_DMG = `${REPO}/releases/latest/download/Dropline.dmg`;

export interface Content {
  htmlLang: string;
  meta: { title: string; description: string };
  nav: {
    links: { label: string; href: string }[];
    navLabel: string;
    download: string;
    langLabel: string;
    /** Label for the docs, used in the nav and on the landing page's docs band. */
    docs: string;
    /** Label pointing back at the landing page from inside the docs. */
    overview: string;
  };
  hero: {
    badge: string;
    title: string;
    lede: string;
    primary: string;
    secondary: string;
    requirements: string;
    meta: string[];
    readout: {
      file: string;
      size: string;
      verb: string;
      key: string;
      status: string;
      caption: string;
      url: string;
    };
  };
  ways: {
    id: string;
    title: string;
    lede: string;
    items: { key: string; desc: string }[];
    note: string;
  };
  own: {
    id: string;
    title: string;
    lede: string;
    templateKeyLabel: string;
    templateKey: string;
    templateUrlLabel: string;
    templateUrl: string;
    varsLabel: string;
    vars: string[];
    points: { title: string; body: string }[];
  };
  hosts: {
    id: string;
    title: string;
    lede: string;
    presetsLabel: string;
    /** Each preset links to its own configuration page in the manual. */
    presets: { label: string; slug: string }[];
    enginesCaption: string;
    engineHead: [string, string];
    engines: [string, string][];
    authLabel: string;
    auth: string;
    custom: string;
    /** Label on the link from a preset chip through to its docs page. */
    presetsCta: string;
  };
  /** The band that hands readers over to the manual. */
  docsBand: {
    id: string;
    eyebrow: string;
    title: string;
    lede: string;
    cta: string;
    cards: { title: string; body: string; slug: string }[];
  };
  faq: {
    id: string;
    title: string;
    lede: string;
    items: { q: string; a: string }[];
  };
  install: {
    id: string;
    title: string;
    lede: string;
    steps: { title: string; body: string; code?: string }[];
    cta: string;
    ctaMeta: string;
    brew: { label: string; command: string; note: string };
    note: string;
    source: string;
  };
  foot: {
    tagline: string;
    links: { label: string; href: string }[];
    meta: string;
  };
}

const en: Content = {
  htmlLang: "en",
  meta: {
    title: "Dropline — a native macOS uploader",
    description:
      "A native macOS app for people who host their own files. Drag & drop, right-click in Finder or use the menu bar to send images, videos or any file to your S3 bucket, R2 account or image host — the public URL lands on your clipboard.",
  },
  nav: {
    links: [
      { label: "How it works", href: "#ways" },
      { label: "Hosts", href: "#hosts" },
      { label: "FAQ", href: "#faq" },
      { label: "Docs", href: "/docs" },
    ],
    navLabel: "Sections",
    download: "Download",
    langLabel: "Language",
    docs: "Docs",
    overview: "Overview",
  },
  hero: {
    badge: "Native macOS app · Swift + SwiftUI",
    title: "Drop a file. Get the link.",
    lede:
      "Dropline lives in your menu bar and sends an image, a video or anything else to your own S3 bucket, your R2 account or your image host — by drag & drop, by right-click in Finder, or from the Dock. The public URL is on your clipboard before you switch windows.",
    primary: "Download for macOS",
    secondary: "View the source",
    requirements: "macOS 13 Ventura or later, on Apple Silicon. Free and open source.",
    meta: ["macOS 13+", "Apple Silicon", "≈1 MB binary", "MIT licence"],
    readout: {
      file: "screenshot-2026-08-08.png",
      size: "2.4 MB",
      verb: "PUT",
      key: "assets/2026/08/a1f3c9.png",
      status: "200 OK",
      caption: "Clipboard",
      url: "https://cdn.example.com/2026/08/a1f3c9.png",
    },
  },
  ways: {
    id: "ways",
    title: "Five ways in. One way out.",
    lede:
      "Every one of them is somewhere macOS already put your hands: the window, the Dock, the Finder context menu, the clipboard, the menu bar. However the file gets in, it leaves the same way — the URL on your clipboard, plus a notification. Turn on Markdown and you get ![name](url) instead.",
    items: [
      { key: "Window", desc: "Drop the file onto the Dropline window." },
      { key: "Dock", desc: "Drop it onto the Dock icon without opening anything." },
      {
        key: "Finder",
        desc: "Right-click a file — Dropline sits at the top level of the context menu, and takes a keyboard shortcut under Services.",
      },
      {
        key: "Clipboard",
        desc: "Paste. ⇧⌘4 screenshots upload straight from the clipboard, no saving first.",
      },
      { key: "Menu bar", desc: "Quick upload, plus the last five links, one click away." },
    ],
    note:
      "The menu bar icon becomes a progress ring while an upload runs. Large videos stream from a temporary file instead of being held in memory.",
  },
  own: {
    id: "own",
    title: "Your bucket. Your keys. Your domain.",
    lede:
      "Nothing passes through a server anyone else runs. Dropline talks to the endpoint you configure, and your secrets stay in the macOS keychain — never in the config file.",
    templateKeyLabel: "Object key template",
    templateKey: "images/{{date}}/{{uuid}}.{{ext}}",
    templateUrlLabel: "Final URL template",
    templateUrl: "https://cdn.example.com/{{result}}",
    varsLabel: "Available variables",
    vars: [
      "{{filename}}",
      "{{base}}",
      "{{ext}}",
      "{{uuid}}",
      "{{date}}",
      "{{datetime}}",
      "{{timestamp}}",
      "{{rand}}",
      "{{key}}",
      "{{result}}",
    ],
    points: [
      {
        title: "Parse any response",
        body:
          "Point a JSON path at whatever your API returns — data.url, files.0.url — or leave it empty when the body is the URL itself.",
      },
      {
        title: "Test before you trust it",
        body:
          "Test Upload sends an 8×8 image and shows you the URL that came back, or the error that didn't.",
      },
      {
        title: "Switch profiles freely",
        body:
          "Keep several hosts configured side by side, upload to them concurrently, and watch progress and history per file.",
      },
    ],
  },
  hosts: {
    id: "hosts",
    title: "Nine presets. Three engines for everything else.",
    lede:
      "Pick a preset and fill in your credentials, or describe the endpoint by hand. Between the three engines, almost any upload API is reachable.",
    presetsLabel: "Built-in presets",
    presets: [
      { label: "Amazon S3", slug: "hosts/s3" },
      { label: "Cloudflare R2", slug: "hosts/r2" },
      { label: "Aliyun OSS", slug: "hosts/oss" },
      { label: "Tencent COS", slug: "hosts/cos" },
      { label: "MinIO", slug: "hosts/minio" },
      { label: "SM.MS", slug: "hosts/smms" },
      { label: "Imgur", slug: "hosts/imgur" },
      { label: "Lsky Pro / Chevereto", slug: "hosts/lsky-chevereto" },
      { label: "EasyImage", slug: "hosts/easyimage" },
    ],
    presetsCta: "Every preset has a configuration page →",
    enginesCaption: "Upload engines",
    engineHead: ["Engine", "Use it for"],
    engines: [
      ["multipart/form-data", "Most image-host APIs"],
      ["Binary PUT / POST", "Self-hosted services and WebDAV-style endpoints"],
      ["S3-compatible (AWS SigV4)", "S3 · R2 · OSS · COS · MinIO"],
    ],
    authLabel: "Authentication",
    auth: "None · Bearer token · Basic · Custom header · URL query parameter",
    custom:
      "For anything else: give Dropline the upload URL, the JSON path to the link, and an object-key template. That is the whole configuration.",
  },
  docsBand: {
    id: "docs",
    eyebrow: "Documentation",
    title: "Everything, written down.",
    lede:
      "A manual for the app and a configuration page for every host it speaks to — the exact fields, the exact values, and what each error means when it does not work first time.",
    cta: "Read the docs",
    cards: [
      {
        title: "Your first upload",
        body: "Configure a host and get a working link back, in about five minutes.",
        slug: "getting-started/quickstart",
      },
      {
        title: "Host configuration",
        body: "S3, R2, OSS, COS, MinIO, SM.MS, Imgur, Lsky Pro, EasyImage — a page each.",
        slug: "hosts/overview",
      },
      {
        title: "Template variables",
        body: "Every {{variable}}, where it works, and recipes for the object key.",
        slug: "guide/templates",
      },
      {
        title: "Troubleshooting",
        body: "Every error the app can show, mapped to the field that causes it.",
        slug: "guide/troubleshooting",
      },
    ],
  },
  faq: {
    id: "faq",
    title: "Questions people actually ask.",
    lede:
      "If yours isn't here, open an issue on GitHub — the README goes deeper on configuration and on building from source.",
    items: [
      {
        q: "Does Dropline upload my files through your server?",
        a: "No. Dropline talks directly to the endpoint you configure — your S3 bucket, your R2 account, your image host. There is no Dropline server in the path, no account to create, and no telemetry. Your access keys are stored in the macOS keychain rather than in the config file.",
      },
      {
        q: "Which image hosts and storage services are supported?",
        a: "Nine presets ship built in: Amazon S3, Cloudflare R2, Aliyun OSS, Tencent COS, MinIO, SM.MS, Imgur, Lsky Pro / Chevereto and EasyImage. Anything else can be configured by hand through one of three engines — multipart/form-data, binary PUT/POST, or S3-compatible AWS SigV4 — with none, Bearer, Basic, custom-header or URL-query authentication.",
      },
      {
        q: "How do I configure a host that has no preset?",
        a: "Go to Settings → Hosts and add a profile. You need the upload URL, a JSON path to pull the link out of the response (for example data.url or files.0.url — leave it empty if the body is the URL itself), and an object-key template such as images/{{date}}/{{uuid}}.{{ext}}. Test Upload sends an 8×8 image and shows you the URL that came back, or the error.",
      },
      {
        q: "Is Dropline free? Is it open source?",
        a: "Yes to both. Dropline is MIT licensed and the full source is on GitHub. There is no paid tier, no subscription and no trial.",
      },
      {
        q: "What are the system requirements?",
        a: "macOS 13 Ventura or later. The published release is built for Apple Silicon; the executable is roughly one megabyte, written in Swift and SwiftUI with no Electron runtime. You can also build it yourself from source with ./build.sh --install.",
      },
      {
        q: "macOS says the app cannot be opened. What now?",
        a: "The build is ad-hoc signed rather than notarised, so Gatekeeper blocks the first launch. Right-click the app and choose Open, or clear the quarantine flag from Terminal with xattr -dr com.apple.quarantine /Applications/Dropline.app.",
      },
      {
        q: "The Finder right-click menu item is missing.",
        a: "Enable it under System Settings → General → Login Items & Extensions → Finder Extensions. The same command also appears under Keyboard → Keyboard Shortcuts → Services → Files and Folders, where you can assign it a shortcut.",
      },
      {
        q: "Can I upload large videos and non-image files?",
        a: "Yes. Dropline takes any file type, and large files stream from a temporary file instead of being held in memory. Uploads run concurrently, with live progress and a history list.",
      },
      {
        q: "Can it copy the link as Markdown?",
        a: "Yes — turn it on in Settings and the clipboard gets ![name](url) instead of the bare URL. Either way a system notification confirms the upload, and the menu bar keeps the last five links.",
      },
      {
        q: "How do updates work?",
        a: "Through Sparkle, signed with EdDSA. Release notes ship in both English and Chinese and follow the language you pick in Settings.",
      },
    ],
  },
  install: {
    id: "install",
    title: "Installed in about a minute.",
    lede: "Two steps, plus one because the build is ad-hoc signed rather than notarised.",
    steps: [
      {
        title: "Download the DMG",
        body: "Grab the latest release and drag Dropline into your Applications folder.",
      },
      {
        title: "Open it the first time",
        body:
          "Right-click the app and choose Open, or clear the quarantine flag from Terminal:",
        code: "xattr -dr com.apple.quarantine /Applications/Dropline.app",
      },
      {
        title: "Turn on the Finder extension",
        body:
          "If the context-menu item does not appear, enable Dropline under System Settings → General → Login Items & Extensions → Finder Extensions.",
      },
    ],
    cta: "Download for macOS",
    ctaMeta: "Universal DMG · macOS 13+ · Apple Silicon",
    brew: {
      label: "Or install with Homebrew",
      command: "brew install --cask chen86860/tap/dropline",
      note:
        "The cask tracks the latest release, so it needs no version number. Homebrew quarantines what it installs, so step 02 still applies on first launch.",
    },
    note:
      "Updates arrive through Sparkle and are signed with EdDSA. Release notes ship in English and Chinese, and follow the language you pick in Settings.",
    source: "Prefer to build it yourself? Clone the repository and run ./build.sh --install.",
  },
  foot: {
    tagline:
      "A native macOS uploader. Pure Swift and SwiftUI, in about a megabyte.",
    links: [
      { label: "GitHub", href: REPO },
      { label: "Releases", href: `${REPO}/releases` },
      { label: "Changelog", href: `${REPO}/blob/main/CHANGELOG.md` },
      { label: "Licence (MIT)", href: `${REPO}/blob/main/LICENSE` },
      { label: "中文", href: PATH_FOR.zh },
    ],
    meta: "MIT licensed · macOS 13+ · Built by chen86860",
  },
};

const zh: Content = {
  htmlLang: "zh-Hans",
  meta: {
    title: "Dropline — 原生 macOS 上传工具",
    description:
      "一个给自己搭图床的人写的原生 macOS 应用。拖拽、在访达里右键，或者从菜单栏，把图片、视频、任意文件发到你自己的 S3、R2 或图床，公开链接自动落到剪贴板。",
  },
  nav: {
    links: [
      { label: "怎么用", href: "#ways" },
      { label: "支持的图床", href: "#hosts" },
      { label: "常见问题", href: "#faq" },
      { label: "文档", href: "/zh/docs" },
    ],
    navLabel: "章节",
    download: "下载",
    langLabel: "语言",
    docs: "文档",
    overview: "产品介绍",
  },
  hero: {
    badge: "原生 macOS 应用 · Swift + SwiftUI",
    title: "拖进去，链接就在剪贴板。",
    lede:
      "Dropline 待在你的菜单栏里，把图片、视频或任意文件发到你自己的 S3、R2 或图床 —— 拖一下、在访达里右键，或者丢到程序坞图标上。等你切回窗口，公开链接已经复制好了。",
    primary: "下载 macOS 版",
    secondary: "查看源码",
    requirements: "需要 macOS 13 Ventura 及以上、Apple Silicon。完全免费且开源。",
    meta: ["macOS 13+", "Apple Silicon", "约 1 MB", "MIT 协议"],
    readout: {
      file: "screenshot-2026-08-08.png",
      size: "2.4 MB",
      verb: "PUT",
      key: "assets/2026/08/a1f3c9.png",
      status: "200 OK",
      caption: "剪贴板",
      url: "https://cdn.example.com/2026/08/a1f3c9.png",
    },
  },
  ways: {
    id: "ways",
    title: "五个入口，一个出口。",
    lede:
      "五个入口都在 macOS 早就放好你双手的地方：窗口、程序坞、访达右键菜单、剪贴板、菜单栏。不管文件从哪儿进来，出去的方式都一样 —— 链接落到剪贴板，再给你一条系统通知。打开 Markdown 开关，复制的就是 ![name](url)。",
    items: [
      { key: "窗口", desc: "把文件拖到 Dropline 窗口上。" },
      { key: "程序坞", desc: "直接拖到程序坞图标上，不用先打开应用。" },
      {
        key: "访达",
        desc: "右键点文件，Dropline 就在右键菜单的第一层；「服务」里还能给它配个快捷键。",
      },
      {
        key: "剪贴板",
        desc: "直接粘贴。⇧⌘4 截的图不用先存盘，从剪贴板就能传。",
      },
      { key: "菜单栏", desc: "快速上传，外加最近 5 条链接，一次点击就能拿到。" },
    ],
    note:
      "上传时菜单栏图标会变成进度环。大视频从临时文件流式上传，不会整个读进内存。",
  },
  own: {
    id: "own",
    title: "你的存储桶，你的密钥，你的域名。",
    lede:
      "不经过任何第三方服务器，Dropline 只和你配置的那个接口说话。密钥存在 macOS 钥匙串里，不会写进配置文件。",
    templateKeyLabel: "对象键模板",
    templateKey: "images/{{date}}/{{uuid}}.{{ext}}",
    templateUrlLabel: "最终链接模板",
    templateUrl: "https://cdn.example.com/{{result}}",
    varsLabel: "可用变量",
    vars: [
      "{{filename}}",
      "{{base}}",
      "{{ext}}",
      "{{uuid}}",
      "{{date}}",
      "{{datetime}}",
      "{{timestamp}}",
      "{{rand}}",
      "{{key}}",
      "{{result}}",
    ],
    points: [
      {
        title: "任意响应都能解析",
        body:
          "用 JSON path 指向接口返回里的那个字段，比如 data.url、files.0.url；如果响应体本身就是链接，留空即可。",
      },
      {
        title: "先测一次再信它",
        body:
          "「测试上传」会发一张 8×8 的图，然后把返回的链接摆给你看 —— 或者把出错的原因摆给你看。",
      },
      {
        title: "多套配置随时切",
        body:
          "几个图床可以并排配好，支持并发上传，每个文件的进度和历史记录都看得到。",
      },
    ],
  },
  hosts: {
    id: "hosts",
    title: "九个预设，剩下的交给三种引擎。",
    lede:
      "选一个预设填上密钥，或者自己把接口描述一遍。这三种引擎基本覆盖了所有上传 API。",
    presetsLabel: "内置预设",
    presets: [
      { label: "Amazon S3", slug: "hosts/s3" },
      { label: "Cloudflare R2", slug: "hosts/r2" },
      { label: "阿里云 OSS", slug: "hosts/oss" },
      { label: "腾讯云 COS", slug: "hosts/cos" },
      { label: "MinIO", slug: "hosts/minio" },
      { label: "SM.MS", slug: "hosts/smms" },
      { label: "Imgur", slug: "hosts/imgur" },
      { label: "Lsky Pro / Chevereto", slug: "hosts/lsky-chevereto" },
      { label: "EasyImage", slug: "hosts/easyimage" },
    ],
    presetsCta: "每个预设都有一页配置说明 →",
    enginesCaption: "上传引擎",
    engineHead: ["引擎", "适用于"],
    engines: [
      ["multipart/form-data", "大多数图床 API"],
      ["二进制 PUT / POST", "自建服务、WebDAV 风格的接口"],
      ["S3 兼容（AWS SigV4）", "S3 · R2 · OSS · COS · MinIO"],
    ],
    authLabel: "鉴权方式",
    auth: "无 · Bearer token · Basic · 自定义请求头 · URL 查询参数",
    custom:
      "其它情况：给 Dropline 一个上传地址、一条指向链接的 JSON path，再加一个对象键模板 —— 配置就这些。",
  },
  docsBand: {
    id: "docs",
    eyebrow: "文档",
    title: "该写的都写下来了。",
    lede:
      "一份应用手册，外加它能对接的每一个图床的配置页 —— 字段填什么、值写成什么样，以及第一次没配通时每条报错分别意味着什么。",
    cta: "阅读文档",
    cards: [
      {
        title: "第一次上传",
        body: "配好一个图床、拿到能用的链接，大约五分钟。",
        slug: "getting-started/quickstart",
      },
      {
        title: "图床配置",
        body: "S3、R2、OSS、COS、MinIO、SM.MS、Imgur、兰空图床、EasyImage —— 一个一页。",
        slug: "hosts/overview",
      },
      {
        title: "模板变量",
        body: "每一个 {{变量}}、能用在哪儿，以及对象键的几种常用写法。",
        slug: "guide/templates",
      },
      {
        title: "疑难排查",
        body: "应用会报的每一条错，对应到该改的那个字段。",
        slug: "guide/troubleshooting",
      },
    ],
  },
  faq: {
    id: "faq",
    title: "常见问题。",
    lede:
      "这里没有的，欢迎去 GitHub 提 issue。README 里有更完整的配置说明和自行编译的步骤。",
    items: [
      {
        q: "文件会经过你们的服务器吗？",
        a: "不会。Dropline 只和你自己配置的那个接口通信 —— 你的 S3 存储桶、你的 R2、你的图床。链路里没有任何 Dropline 的服务器，不需要注册账号，也没有任何埋点。密钥存在 macOS 钥匙串里，不会写进配置文件。",
      },
      {
        q: "支持哪些图床和对象存储？",
        a: "内置九个预设：Amazon S3、Cloudflare R2、阿里云 OSS、腾讯云 COS、MinIO、SM.MS、Imgur、Lsky Pro / Chevereto、EasyImage。其它服务可以手动配置，走三种引擎之一 —— multipart/form-data、二进制 PUT/POST、S3 兼容（AWS SigV4）—— 鉴权支持无鉴权、Bearer token、Basic、自定义请求头和 URL 查询参数。",
      },
      {
        q: "没有预设的图床怎么配？",
        a: "在「设置 → 图床」里新建一个配置：填上传地址、一条从响应里取链接的 JSON path（比如 data.url、files.0.url，如果响应体本身就是链接就留空），再加一个对象键模板，例如 images/{{date}}/{{uuid}}.{{ext}}。点「测试上传」会发一张 8×8 的图，然后把返回的链接或者错误直接摆给你看。",
      },
      {
        q: "Dropline 收费吗？开源吗？",
        a: "免费，且开源。采用 MIT 协议，完整源码在 GitHub 上。没有付费版、没有订阅、也没有试用期。",
      },
      {
        q: "对系统有什么要求？",
        a: "需要 macOS 13 Ventura 或更高版本。发布的安装包面向 Apple Silicon；可执行文件大约一兆，用 Swift 和 SwiftUI 写成，不带 Electron 运行时。你也可以克隆仓库后用 ./build.sh --install 自行编译。",
      },
      {
        q: "提示应用打不开怎么办？",
        a: "构建用的是 ad-hoc 签名，没有走公证，所以第一次启动会被 Gatekeeper 拦下。右键点应用选「打开」即可，或者在终端里执行 xattr -dr com.apple.quarantine /Applications/Dropline.app 清掉隔离标记。",
      },
      {
        q: "访达右键菜单里没有 Dropline？",
        a: "去「系统设置 → 通用 → 登录项与扩展 → 访达扩展」里把它打开。同名命令也会出现在「键盘 → 键盘快捷键 → 服务 → 文件和文件夹」下，可以给它配一个快捷键。",
      },
      {
        q: "能传大视频和非图片文件吗？",
        a: "可以。任意文件类型都支持，大文件从临时文件流式上传，不会整个读进内存。上传是并发的，有实时进度和历史记录。",
      },
      {
        q: "能直接复制成 Markdown 吗？",
        a: "可以，在设置里打开开关，剪贴板里就是 ![name](url) 而不是裸链接。无论哪种格式，上传完成都会有一条系统通知，菜单栏里也留着最近 5 条链接。",
      },
      {
        q: "更新是怎么下发的？",
        a: "通过 Sparkle 下发，用 EdDSA 签名。更新说明有中英两份，跟着你在设置里选的语言走。",
      },
    ],
  },
  install: {
    id: "install",
    title: "一分钟左右装好。",
    lede: "两步就够，第三步是因为构建用的是 ad-hoc 签名，没有走公证。",
    steps: [
      {
        title: "下载 DMG",
        body: "拿到最新版本，把 Dropline 拖进「应用程序」文件夹。",
      },
      {
        title: "第一次打开",
        body: "右键点应用选「打开」，或者在终端里清掉隔离标记：",
        code: "xattr -dr com.apple.quarantine /Applications/Dropline.app",
      },
      {
        title: "打开访达扩展",
        body:
          "如果右键菜单里没有出现，去「系统设置 → 通用 → 登录项与扩展 → 访达扩展」里把 Dropline 勾上。",
      },
    ],
    cta: "下载 macOS 版",
    ctaMeta: "DMG 安装包 · macOS 13+ · Apple Silicon",
    brew: {
      label: "也可以用 Homebrew 安装",
      command: "brew install --cask chen86860/tap/dropline",
      note:
        "cask 跟随最新版本，所以不带版本号。Homebrew 会给装好的应用加隔离标记，第一次打开仍需执行第 02 步。",
    },
    note:
      "更新通过 Sparkle 下发，用 EdDSA 签名。更新说明有中英两份，跟着你在设置里选的语言走。",
    source: "想自己编译？克隆仓库后执行 ./build.sh --install 就行。",
  },
  foot: {
    tagline: "一个原生 macOS 上传工具。纯 Swift 与 SwiftUI，大约一兆。",
    links: [
      { label: "GitHub", href: REPO },
      { label: "版本发布", href: `${REPO}/releases` },
      { label: "更新日志", href: `${REPO}/blob/main/CHANGELOG.zh-CN.md` },
      { label: "开源协议（MIT）", href: `${REPO}/blob/main/LICENSE` },
      { label: "English", href: PATH_FOR.en },
    ],
    meta: "MIT 协议 · macOS 13+ · 由 chen86860 开发",
  },
};

export const CONTENT: Record<Lang, Content> = { en, zh };
