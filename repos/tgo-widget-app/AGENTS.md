# TGO Widget App AGENTS Guide

> 适用范围：`repos/tgo-widget-app`  
> 最近校准：2026-03-05（按当前代码与配置扫描）

## 1. 服务定位

`tgo-widget-app` 是访客侧嵌入式聊天组件，运行在 iframe 场景，负责消息展示、输入、IM 通道与宿主页交互。

- 技术栈：React 18 + TypeScript + Vite 5 + Emotion + Zustand
- 开发端口：`5174`（工作区 `make dev-widget`）

---

## 2. 关键目录

```text
src/
├── components/               # Header/MessageList/MessageInput/widgets/*
├── services/                 # platform/visitor/wukongim/messageHistory/upload
├── store/                    # chatStore/platformStore
├── types/                    # chat/api 类型定义
├── contexts/                 # ThemeContext
├── i18n/                     # 多语言词条
├── utils/                    # URL、通知、Markdown、Widget 解析
└── App.tsx / main.tsx
```

---

## 3. 强约束规范

### 3.1 iframe 与宿主通信

- `postMessage` 事件类型与 payload 结构需保持兼容。
- 不得随意变更宿主侧依赖的消息名（如可见性、未读数、配置同步）。

### 3.2 状态与 API 分层

- 组件不得直接发请求，统一走 `services/*` + `store/*`。
- 消息模型变更要同步 `types`、store 和渲染组件。

### 3.3 安全与内容渲染

- Markdown/HTML 渲染必须保持 XSS 防护（`dompurify` 等既有链路）。
- 外链、Action URI 与文件链接处理需保留白名单与校验逻辑。

### 3.4 国际化与主题

- 用户可见文案优先写入 `i18n/locales/*`。
- 主题色、位置、展开状态与宿主页同步逻辑不可破坏。

---

## 4. 高频改动入口

- 主流程：`src/App.tsx`
- 启动与 iframe 渲染：`src/main.tsx`
- 聊天状态：`src/store/chatStore.ts`
- 平台状态：`src/store/platformStore.ts`
- IM 接入：`src/services/wukongim.ts`
- Widget 解析渲染：`src/utils/uiWidgetParser.ts`、`src/components/widgets/*`

---

## 5. 本地开发命令

```bash
# 依赖
yarn install

# 开发
yarn dev

# 构建与预览
yarn build
yarn preview
```

说明：当前项目未内置 lint/type-check 脚本，改动后至少完成 `yarn build` 并做页面交互回归。

---

## 6. AI 代理改动流程

1. 先确认改动在消息渲染、状态层还是宿主交互层。
2. 先改类型与 store，再改 UI 组件。
3. 涉及消息协议改动时，验证历史消息与实时消息两条路径。
4. 涉及 iframe 通信改动时，联调宿主页事件。

---

## 7. 变更自检清单

- 是否破坏宿主 `postMessage` 协议兼容？
- 是否引入未清洗的富文本渲染路径？
- 是否改了消息结构但漏改 store/renderer？
- 是否完成构建并验证主交互链路？
