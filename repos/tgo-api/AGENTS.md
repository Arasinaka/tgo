# TGO API AGENTS Guide

> 适用范围：`repos/tgo-api`  
> 最近校准：2026-03-05（按当前代码与配置扫描）

## 1. 服务定位

`tgo-api` 是核心业务网关，负责多租户业务实体与对外 API。

- Main API：`app/main.py`，默认 `8000`，需要认证（JWT/API Key）
- Internal API：`app/internal.py`，默认 `8001`，无认证，仅允许内网访问

---

## 2. 关键目录

```text
app/
├── api/v1/endpoints/        # 对外接口
├── api/internal/endpoints/  # 内部接口（no auth）
├── services/                # 业务逻辑与跨服务客户端
├── schemas/                 # Pydantic 请求/响应模型
├── models/                  # SQLAlchemy 模型（api_*）
├── tasks/                   # 后台定时/轮询任务
├── core/                    # config、db、security、logging、exceptions
├── main.py                  # Main API
└── internal.py              # Internal API
```

---

## 3. 强约束规范

### 3.1 类型与分层

- 禁止在核心业务接口使用 `Any`。
- 禁止以裸 `dict` 作为稳定业务对象在 service 层传递。
- Endpoint 仅做参数校验与编排，业务逻辑放 `app/services/*`。
- 请求/响应模型必须定义在 `app/schemas/*`。

### 3.2 常量与错误处理

- 公共常量与枚举放 `app/utils/const.py`，禁止重复硬编码。
- 业务错误统一使用 `app.core.exceptions.TGOAPIException` 体系。
- 禁止 `print`，使用项目日志组件。

### 3.3 微服务边界

- 访问 AI/RAG/Workflow/Plugin/Device 等外部服务时，优先复用 `app/services/*_client.py`。
- 禁止跨服务直连数据库或复制他服务私有逻辑。
- Internal API 必须维持“仅内网可见”假设，不添加公网暴露路径。

### 3.4 数据库迁移

- `models` 变更必须附带 Alembic 脚本（`alembic/versions`）。
- 迁移与业务代码必须同提交，避免 schema/code 不一致。

---

## 4. 高频改动入口

- 聊天链路：`app/services/chat_service.py`
- 访客分配：`app/services/visitor_service.py`、`app/tasks/process_waiting_queue.py`
- 外部 AI 调用：`app/services/ai_client.py`
- 平台同步：`app/services/platform_sync.py`
- 设备控制接入：`app/services/device_control_client.py`

---

## 5. 本地开发命令

```bash
# 依赖
poetry install

# 迁移
poetry run alembic upgrade head

# 启动 main API
poetry run uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

# 启动 internal API（单独终端）
poetry run uvicorn app.internal:internal_app --host 127.0.0.1 --port 8001 --reload

# 质量检查
poetry run pytest
poetry run flake8 app tests
poetry run mypy app
poetry run black app tests
poetry run isort app tests
```

---

## 6. AI 代理改动流程

1. 先定位所属域（endpoint/schema/service/model/task）。
2. 优先复用已有 service/client，不新增平行实现。
3. 接口字段改动时，同步更新 schema、service、调用方。
4. 涉及数据结构改动时，补 Alembic 迁移。
5. 提交前至少完成 `pytest` + `flake8` + `mypy`（或解释未执行原因）。

---

## 7. 变更自检清单

- 是否误把内部接口暴露到公网路由？
- 是否引入跨服务硬编码 URL/字段？
- 是否遗漏 schema 与 response model 的同步更新？
- 是否遗漏迁移脚本？
- 是否影响 `tgo-web` 消息结构但未同步联调？
