/**
 * Every user-facing string on the page, in both languages.
 *
 * Facts here are drawn from the repository README — nothing is invented.
 * If a claim is not in the README or the source, it does not belong in here.
 */

export type Lang = 'en' | 'zh';

export const LANGS: readonly Lang[] = ['en', 'zh'];

/** Where each language lives. `/` is English so the bare domain is the default. */
export const PATH_FOR: Record<Lang, string> = { en: '/', zh: '/zh' };

export const REPO = 'https://github.com/chen86860/dropline';
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
    badge: string[];
    title: string;
    lede: string;
    primary: string;
    meta: string[];
    /** Labels inside the animated demo that replaces the screenshot up top. */
    demo: { drop: string; clipboard: string; copied: string; toast: string };
  };
  ways: {
    id: string;
    title: string;
    lede: string;
    items: { key: string; desc: string }[];
    /** The single exit in the diagram: what lands on the clipboard. */
    output: { label: string; url: string };
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
    /** The two ends of the direct line drawn under the lede. */
    route: [string, string];
  };
  hosts: {
    id: string;
    title: string;
    lede: string;
    presetsLabel: string;
    /** Each preset links to its own configuration page in the manual. */
    presets: { label: string; slug: string }[];
    /** The second marquee row: what the custom engines speak. */
    engines: string[];
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
    ctaMeta: string[];
    brew: { label: string; command: string };
  };
  foot: {
    tagline: string;
    links: { label: string; href: string }[];
    meta: string[];
  };
}

const en: Content = {
  htmlLang: 'en',
  meta: {
    title: 'Dropline — a native macOS uploader',
    description:
      'A native macOS app for people who host their own files. Drag & drop, right-click in Finder or use the menu bar to send images, videos or any file to your S3 bucket, R2 account or image host — the public URL lands on your clipboard.',
  },
  nav: {
    links: [
      { label: 'How it works', href: '#ways' },
      { label: 'Hosts', href: '#hosts' },
      { label: 'FAQ', href: '#faq' },
      { label: 'Docs', href: '/docs' },
    ],
    navLabel: 'Sections',
    download: 'Download',
    langLabel: 'Language',
    docs: 'Docs',
    overview: 'Overview',
  },
  hero: {
    badge: ['Native macOS app', 'Swift + SwiftUI'],
    title: 'Drop a file. Get the link.',
    lede: 'Drag, right-click or paste a file. It lands in your own S3, R2 or image host, and the link is already on your clipboard.',
    primary: 'Download for macOS',
    meta: ['macOS 13+', 'Apple Silicon', 'Free', 'MIT'],
    demo: {
      drop: 'Drop files here',
      clipboard: 'Clipboard',
      copied: 'Copied',
      toast: 'Link copied to clipboard',
    },
  },
  ways: {
    id: 'ways',
    title: 'Five ways in. One way out.',
    lede: 'Wherever the file starts, the link ends up on your clipboard. Plain URL or Markdown, your choice.',
    items: [
      { key: 'Window', desc: 'Drop onto the app window.' },
      { key: 'Dock', desc: 'Drop onto the Dock icon.' },
      { key: 'Finder', desc: 'Right-click any file.' },
      { key: 'Clipboard', desc: 'Paste a screenshot, no saving first.' },
      { key: 'Menu bar', desc: 'Quick upload and your last five links.' },
    ],
    output: { label: 'Link copied', url: 'cdn.example.com/a1b2.png' },
  },
  own: {
    id: 'own',
    title: 'Your bucket. Your keys. Your domain.',
    lede: 'No middle server. Your keys stay in the macOS keychain.',
    templateKeyLabel: 'Object key template',
    templateKey: 'images/{{date}}/{{uuid}}.{{ext}}',
    templateUrlLabel: 'Final URL template',
    templateUrl: 'https://cdn.example.com/{{key}}',
    route: ['Your Mac', 'Your bucket'],
    varsLabel: 'Available variables',
    vars: [
      '{{filename}}',
      '{{base}}',
      '{{ext}}',
      '{{uuid}}',
      '{{date}}',
      '{{datetime}}',
      '{{timestamp}}',
      '{{rand}}',
      '{{key}}',
      '{{result}}',
    ],
  },
  hosts: {
    id: 'hosts',
    title: 'Nine presets. Any API.',
    lede: 'Paste your keys into a preset, or point Dropline at any upload endpoint.',
    presetsLabel: 'Built-in presets',
    presets: [
      { label: 'Amazon S3', slug: 'hosts/s3' },
      { label: 'Cloudflare R2', slug: 'hosts/r2' },
      { label: 'Aliyun OSS', slug: 'hosts/oss' },
      { label: 'Tencent COS', slug: 'hosts/cos' },
      { label: 'MinIO', slug: 'hosts/minio' },
      { label: 'SM.MS', slug: 'hosts/smms' },
      { label: 'Imgur', slug: 'hosts/imgur' },
      { label: 'Lsky Pro / Chevereto', slug: 'hosts/lsky-chevereto' },
      { label: 'EasyImage', slug: 'hosts/easyimage' },
    ],
    presetsCta: 'Every preset has a configuration page →',
    engines: ['multipart/form-data', 'Binary PUT / POST', 'S3-compatible (SigV4)', 'Bearer token', 'Basic auth', 'Custom headers'],
  },
  docsBand: {
    id: 'docs',
    eyebrow: 'Documentation',
    title: 'Everything, written down.',
    lede: 'Every host, every field, every error.',
    cta: 'Read the docs',
    cards: [
      {
        title: 'Your first upload',
        body: 'A working link in about five minutes.',
        slug: 'getting-started/quickstart',
      },
      {
        title: 'Host configuration',
        body: 'One page per preset.',
        slug: 'hosts/overview',
      },
      {
        title: 'Template variables',
        body: 'Every {{variable}}, with recipes.',
        slug: 'guide/templates',
      },
      {
        title: 'Troubleshooting',
        body: 'Each error, mapped to its fix.',
        slug: 'guide/troubleshooting',
      },
    ],
  },
  faq: {
    id: 'faq',
    title: 'Questions people actually ask.',
    lede: 'Something missing? Open an issue on GitHub.',
    items: [
      {
        q: 'Do my files go through your server?',
        a: 'No. Dropline uploads straight to the host you configure. No account, no telemetry.',
      },
      {
        q: 'Which hosts are supported?',
        a: 'Nine presets, from Amazon S3 and Cloudflare R2 to SM.MS and Imgur. Almost any other upload API works through a custom profile.',
      },
      {
        q: 'Is it free?',
        a: 'Yes. MIT licensed, full source on GitHub, no paid tier.',
      },
      {
        q: 'What do I need to run it?',
        a: 'macOS 13 or later on Apple Silicon. The app is about 1 MB of Swift and SwiftUI.',
      },
      {
        q: 'macOS says the app cannot be opened.',
        a: 'The build is not notarised yet. Right-click the app and choose Open, once.',
      },
      {
        q: 'How do updates work?',
        a: 'Automatically, through Sparkle, signed with EdDSA.',
      },
    ],
  },
  install: {
    id: 'install',
    title: 'Installed in about a minute.',
    lede: 'Three steps, one of them only once.',
    steps: [
      {
        title: 'Download the DMG',
        body: 'Drag Dropline into Applications.',
      },
      {
        title: 'Open it the first time',
        body: 'Right-click the app and choose Open, or run:',
        code: 'xattr -dr com.apple.quarantine /Applications/Dropline.app',
      },
      {
        title: 'Turn on the Finder extension',
        body: 'System Settings → General → Login Items & Extensions → Finder Extensions.',
      },
    ],
    cta: 'Download for macOS',
    ctaMeta: ['Universal DMG', 'macOS 13+', 'Apple Silicon'],
    brew: {
      label: 'Or install with Homebrew',
      command: 'brew install --cask chen86860/tap/dropline',
    },
  },
  foot: {
    tagline: 'A native macOS uploader. About 1 MB of Swift.',
    links: [
      { label: 'GitHub', href: REPO },
      { label: 'Releases', href: `${REPO}/releases` },
      { label: 'Changelog', href: `${REPO}/blob/main/CHANGELOG.md` },
      { label: 'Licence (MIT)', href: `${REPO}/blob/main/LICENSE` },
      { label: 'Privacy', href: '/docs/guide/security#this-website' },
      { label: '中文', href: PATH_FOR.zh },
    ],
    meta: ['MIT licensed', 'macOS 13+', 'Built by chen86860'],
  },
};

const zh: Content = {
  htmlLang: 'zh-Hans',
  meta: {
    title: 'Dropline — 原生 macOS 上传工具',
    description:
      '一个给自己搭图床的人写的原生 macOS 应用。拖拽、在访达里右键，或者从菜单栏，把图片、视频、任意文件发到你自己的 S3、R2 或图床，公开链接自动落到剪贴板。',
  },
  nav: {
    links: [
      { label: '怎么用', href: '#ways' },
      { label: '支持的图床', href: '#hosts' },
      { label: '常见问题', href: '#faq' },
      { label: '文档', href: '/zh/docs' },
    ],
    navLabel: '章节',
    download: '下载',
    langLabel: '语言',
    docs: '文档',
    overview: '产品介绍',
  },
  hero: {
    badge: ['原生 macOS 应用', 'Swift + SwiftUI'],
    title: '拖进去，链接就在剪贴板。',
    lede: '拖进去、右键或粘贴，文件直达你自己的 S3、R2 或图床，链接自动复制好。',
    primary: '下载 macOS 版',
    meta: ['macOS 13+', 'Apple Silicon', '免费', 'MIT'],
    demo: {
      drop: '把文件拖到这里',
      clipboard: '剪贴板',
      copied: '已复制',
      toast: '链接已复制到剪贴板',
    },
  },
  ways: {
    id: 'ways',
    title: '五个入口，一个出口。',
    lede: '不管从哪儿进来，链接都落到剪贴板。裸链接或 Markdown，随你选。',
    items: [
      { key: '窗口', desc: '拖到应用窗口上。' },
      { key: '程序坞', desc: '拖到程序坞图标上。' },
      { key: '访达', desc: '右键任意文件。' },
      { key: '剪贴板', desc: '截图直接粘贴，不用存盘。' },
      { key: '菜单栏', desc: '快速上传，附最近 5 条链接。' },
    ],
    output: { label: '链接已复制', url: 'cdn.example.com/a1b2.png' },
  },
  own: {
    id: 'own',
    title: '你的存储桶，你的密钥，你的域名。',
    lede: '没有中转服务器，密钥只在你的钥匙串里。',
    templateKeyLabel: '对象键模板',
    templateKey: 'images/{{date}}/{{uuid}}.{{ext}}',
    templateUrlLabel: '最终链接模板',
    templateUrl: 'https://cdn.example.com/{{key}}',
    route: ['你的 Mac', '你的存储桶'],
    varsLabel: '可用变量',
    vars: [
      '{{filename}}',
      '{{base}}',
      '{{ext}}',
      '{{uuid}}',
      '{{date}}',
      '{{datetime}}',
      '{{timestamp}}',
      '{{rand}}',
      '{{key}}',
      '{{result}}',
    ],
  },
  hosts: {
    id: 'hosts',
    title: '九个预设，外加任意 API。',
    lede: '选个预设填上密钥，或者直接接入任意上传接口。',
    presetsLabel: '内置预设',
    presets: [
      { label: 'Amazon S3', slug: 'hosts/s3' },
      { label: 'Cloudflare R2', slug: 'hosts/r2' },
      { label: '阿里云 OSS', slug: 'hosts/oss' },
      { label: '腾讯云 COS', slug: 'hosts/cos' },
      { label: 'MinIO', slug: 'hosts/minio' },
      { label: 'SM.MS', slug: 'hosts/smms' },
      { label: 'Imgur', slug: 'hosts/imgur' },
      { label: 'Lsky Pro / Chevereto', slug: 'hosts/lsky-chevereto' },
      { label: 'EasyImage', slug: 'hosts/easyimage' },
    ],
    presetsCta: '每个预设都有一页配置说明 →',
    engines: ['multipart/form-data', '二进制 PUT / POST', 'S3 兼容（SigV4）', 'Bearer token', 'Basic 鉴权', '自定义请求头'],
  },
  docsBand: {
    id: 'docs',
    eyebrow: '文档',
    title: '该写的都写下来了。',
    lede: '每个图床、每个字段、每条报错，都有说明。',
    cta: '阅读文档',
    cards: [
      {
        title: '第一次上传',
        body: '五分钟拿到第一条链接。',
        slug: 'getting-started/quickstart',
      },
      {
        title: '图床配置',
        body: '每个预设一页。',
        slug: 'hosts/overview',
      },
      {
        title: '模板变量',
        body: '所有 {{变量}} 和常用写法。',
        slug: 'guide/templates',
      },
      {
        title: '疑难排查',
        body: '每条报错对应的解法。',
        slug: 'guide/troubleshooting',
      },
    ],
  },
  faq: {
    id: 'faq',
    title: '常见问题。',
    lede: '没找到答案？去 GitHub 提个 issue。',
    items: [
      {
        q: '文件会经过你们的服务器吗？',
        a: '不会。Dropline 直接上传到你配置的图床，不用注册，没有埋点。',
      },
      {
        q: '支持哪些图床？',
        a: '内置九个预设，从 Amazon S3、Cloudflare R2 到 SM.MS、Imgur。其它上传 API 基本都能手动配。',
      },
      {
        q: '收费吗？',
        a: '免费。MIT 协议，源码全在 GitHub，没有付费版。',
      },
      {
        q: '系统要求？',
        a: 'macOS 13 及以上，Apple Silicon。应用本体约 1 MB，纯 Swift 与 SwiftUI。',
      },
      {
        q: '提示应用打不开？',
        a: '安装包暂未公证。第一次右键点应用选「打开」即可。',
      },
      {
        q: '怎么更新？',
        a: '通过 Sparkle 自动更新，EdDSA 签名。',
      },
    ],
  },
  install: {
    id: 'install',
    title: '一分钟左右装好。',
    lede: '三步，其中一步只做一次。',
    steps: [
      {
        title: '下载 DMG',
        body: '把 Dropline 拖进「应用程序」。',
      },
      {
        title: '第一次打开',
        body: '右键点应用选「打开」，或者执行：',
        code: 'xattr -dr com.apple.quarantine /Applications/Dropline.app',
      },
      {
        title: '打开访达扩展',
        body: '系统设置 → 通用 → 登录项与扩展 → 访达扩展。',
      },
    ],
    cta: '下载 macOS 版',
    ctaMeta: ['DMG 安装包', 'macOS 13+', 'Apple Silicon'],
    brew: {
      label: '也可以用 Homebrew 安装',
      command: 'brew install --cask chen86860/tap/dropline',
    },
  },
  foot: {
    tagline: '原生 macOS 上传工具，约 1 MB 的 Swift。',
    links: [
      { label: 'GitHub', href: REPO },
      { label: '版本发布', href: `${REPO}/releases` },
      { label: '更新日志', href: `${REPO}/blob/main/CHANGELOG.zh-CN.md` },
      { label: '开源协议（MIT）', href: `${REPO}/blob/main/LICENSE` },
      { label: '隐私', href: '/zh/docs/guide/security#关于本网站' },
      { label: 'English', href: PATH_FOR.en },
    ],
    meta: ['MIT 协议', 'macOS 13+', '由 chen86860 开发'],
  },
};

export const CONTENT: Record<Lang, Content> = { en, zh };
