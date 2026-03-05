# TGO Platform AGENTS Guide

> 适用范围：`repos/tgo-platform`  
> 最近校准：2026-03-05（按当前代码与配置扫描）

## 1. 服务定位

`tgo-platform` 负责多渠道消息接入与归一化后转发（微信/企微/飞书/钉钉/Telegram/Slack/邮件/WuKongIM）。

- HTTP 入口：`app/main.py`
- 关键能力：回调接入、消息归一化、SSE 推送、渠道 listener 生命周期管理
- 工作区标准端口：`8003`（服务内 Makefile 默认 `8001`，以工作区编排为准）

---

## 2. 关键目录

```text
app/
├── api/v1/                      # health/messages/platforms/callbacks/internal
├── domain/services/listeners/   # 各渠道 listener
├── domain/services/normalizer.py
├── infra/                       # tgo-api HTTP client / visitor client / SSE
├── db/                          # SQLAlchemy 会话与模型
├── core/config.py               # 必填配置(api_base_url/database_url 等)
└── main.py
```

---

## 3. 强约束规范

### 3.1 Listener 生命周期

- 新增渠道 listener 必须接入启动/停止流程，确保退出时可取消任务并清理资源。
- 禁止在 listener 中执行长时间阻塞调用，统一使用异步 I/O。

### 3.2 消息归一化与幂等

- 外部平台消息必须先归一化再转发，避免渠道专属字段泄漏到上游。
- 回调重试场景需要考虑幂等处理，避免重复创建消息。

### 3.3 边界与配置

- 向 `tgo-api` 转发统一复用 infra client，不在业务层拼接分散调用。
- 平台密钥、回调地址、API 基地址必须走配置，不硬编码。

### 3.4 数据库变更

- 模型结构变更必须附带 Alembic 迁移。

---

## 4. 高频改动入口

- 消息接入：`app/api/v1/messages.py`
- 平台配置接口：`app/api/v1/platforms.py`
- 外部回调：`app/api/v1/callbacks.py`
- 渠道 listener：`app/domain/services/listeners/*`

---

## 5. 本地开发命令

```bash
# 依赖
poetry install

# 迁移
PYTHONPATH=. poetry run alembic upgrade head

# 启动
poetry run uvicorn app.main:app --host 0.0.0.0 --port 8003 --reload

# 质量检查
poetry run ruff check .
poetry run ruff format .
```

说明：当前仓库未提供稳定 `tests/` 套件，改动后至少做接口级联调与关键回调路径自测。

---

## 6. AI 代理改动流程

1. 先识别改动是否在 API 层、listener 层或归一化层。
2. 保持渠道输入模型与归一化输出模型边界清晰。
3. 若改动 listener，必须同步验证启动/关闭行为。
4. 变更对 `tgo-api` 的调用字段时，同步检查上游兼容性。

---

## 7. 变更自检清单

- 是否引入 listener 任务泄漏或无法关闭问题？
- 是否破坏回调幂等性？
- 是否硬编码了渠道 URL 或凭证？
- 是否遗漏迁移与环境变量文档更新？
