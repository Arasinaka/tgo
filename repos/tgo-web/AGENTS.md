# TGO Web AGENTS Guide

> 适用范围：`repos/tgo-web`  
> 最近校准：2026-03-05（按当前代码与配置扫描）

## 1. 服务定位

`tgo-web` 是管理后台前端，承载 Agent、知识库、会话、平台与工作流配置界面。

- 技术栈：React 19 + TypeScript 5.9 + Vite 7 + Zustand + React Router 7 + Tailwind 4
- 本地开发端口：`5173`（由仓库根 `make dev-web` 启动）

---

## 2. 关键目录

```text
src/
├── components/              # 业务组件（chat/ai/workflow/knowledge/...）
├── pages/                   # 页面组件
├── services/                # API 访问层（统一走 apiClient）
├── stores/                  # Zustand 状态管理
├── types/                   # 全局 TS 类型
├── router/                  # 路由定义
├── i18n/                    # 多语言
├── constants/               # 常量
└── utils/                   # 工具函数
```

---

## 3. 强约束规范

### 3.1 类型安全

- 禁止 `any`（包括 props、store state、API response）。
- 新增接口字段必须同步更新 `src/types/*` 与消费方。
- 不允许通过类型断言规避真实建模（除非有明确注释说明边界原因）。

### 3.2 API 与状态分层

- 禁止在组件内直接 `fetch/axios`，统一走 `src/services/*`。
- HTTP 基座统一走 `src/services/api.ts` 的 `apiClient`。
- 跨组件共享状态放 `src/stores/*`，避免重复本地状态实现。

### 3.3 生产安全

- 禁止直接导入 mock 数据（ESLint 已限制 `**/data/mock*`）。
- 日志仅允许 `console.warn` / `console.error`（普通 `console.log` 需避免）。
- 环境变量走运行时或构建时配置，不硬编码后端地址。

### 3.4 国际化与文案

- 用户可见文案优先走 `i18n` 词条，不直接硬编码中文/英文。

---

## 4. 高频改动入口

- 聊天消息渲染：`src/components/chat/*`
- WebSocket 与 IM：`src/components/WebSocketManager.tsx`、`src/services/wukongimWebSocket.ts`
- 聊天消息 API：`src/services/chatMessagesApi.ts`
- 类型中心：`src/types/index.ts`
- 聊天状态：`src/stores/chatStore.ts`、`src/stores/messageStore.ts`
- 工作流配置：`src/components/workflow/*`、`src/services/workflowApi.ts`

---

## 5. 本地开发命令

```bash
# 依赖
yarn install

# 开发
yarn dev

# 最小质量检查
yarn type-check
yarn lint
yarn build

# 完整检查
yarn build:check
```

---

## 6. AI 代理改动流程

1. 先确定变更落点：`types -> services -> stores -> components`。
2. 若后端字段变化，先改类型再改渲染，避免隐式 `undefined`。
3. 新 API 必须封装到 `services`，组件只消费 typed 方法。
4. 聊天链路改动需检查流式消息、历史消息、WebSocket 三条路径一致性。
5. 提交前至少执行 `yarn type-check && yarn lint && yarn build`。

---

## 7. 变更自检清单

- 是否引入了 `any` 或不安全断言？
- 是否在组件里绕过 `services` 直接发请求？
- 是否改了消息结构但漏改 `types/store/renderer` 之一？
- 是否新增了未国际化的界面文案？
- 是否通过了 `type-check` 与 `lint`？
