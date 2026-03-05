# TGO AI AGENTS Guide

> 适用范围：`repos/tgo-ai`  
> 最近校准：2026-03-05（按当前代码与配置扫描）

## 1. 服务定位

`tgo-ai` 负责 LLM 接入、Agent 编排执行、工具调用与流式输出。

- HTTP 入口：`app/main.py`
- 路由前缀：`/api/v1`（见 `app/api/v1/__init__.py`）
- 工作区标准端口：`8081`（建议用仓库根 `make dev-ai`）

---

## 2. 关键目录

```text
app/
├── api/v1/                     # Teams/Agents/Chat/Tools/Skills API
├── services/                   # 跨服务调用与业务服务
├── runtime/supervisor/         # 多智能体编排与执行
├── runtime/tools/              # 工具执行层
├── streaming/                  # SSE/事件流管理
├── schemas/                    # Pydantic 模型
├── models/                     # SQLAlchemy 模型
├── tasks/                      # 后台任务（如 embedding sync retry）
└── main.py                     # FastAPI 入口
```

---

## 3. 强约束规范

### 3.1 类型与接口

- 禁止在核心服务接口使用 `Any`。
- 禁止用裸 `dict` 作为稳定业务对象跨层传递。
- API 入参/出参必须通过 `schemas` 建模。

### 3.2 流式协议稳定性

- 聊天接口需保持 OpenAI 兼容 chunk 输出与 SSE 行格式稳定。
- 涉及工具调用事件时，必须同时校验流式与非流式路径行为一致。
- 不可随意变更事件顺序与终止语义（避免上游提前关流）。

### 3.3 微服务边界

- 与 RAG/Workflow/Plugin/API/Device 通信通过既有 `services/*` 封装完成。
- 禁止在本服务硬编码其他服务内部实现细节。

### 3.4 数据库与配置

- 模型变更必须附带 Alembic 迁移。
- 外部地址、密钥、开关都从 `app/config.py` + `.env` 注入，不硬编码。

---

## 4. 高频改动入口

- Chat Completion：`app/api/v1/chat.py`、`app/services/chat_service.py`
- 监督编排：`app/runtime/supervisor/*`
- 工具执行：`app/runtime/tools/*`、`app/services/tool_executor.py`
- SSE 与事件：`app/streaming/*`

---

## 5. 本地开发命令

```bash
# 依赖
poetry install

# 迁移
poetry run alembic upgrade head

# 启动（工作区标准端口）
poetry run uvicorn app.main:app --host 0.0.0.0 --port 8081 --reload

# 质量检查
poetry run pytest
poetry run flake8 app tests
poetry run mypy app
poetry run black app tests
poetry run isort app tests
```

---

## 6. AI 代理改动流程

1. 先确认变更是 API 层、runtime 编排层还是工具执行层。
2. 先改 schema/类型，再改 service 与 router。
3. 聊天链路改动需同时验证 `stream=false` 与 `stream=true`。
4. 涉及模型结构改动时同步补 Alembic。
5. 提交前至少跑 `pytest + mypy`（或说明未执行原因）。

---

## 7. 变更自检清单

- 是否误改了 `/api/v1` 协议兼容性？
- 是否破坏了 SSE chunk 或事件序列？
- 是否引入跨服务硬编码 URL/字段？
- 是否遗漏迁移与配置项更新？
