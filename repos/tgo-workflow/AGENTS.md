# TGO Workflow AGENTS Guide

> 适用范围：`repos/tgo-workflow`  
> 最近校准：2026-03-05（按当前代码与配置扫描）

## 1. 服务定位

`tgo-workflow` 提供 AI 工作流编排与执行能力（DAG + 节点执行 + 异步任务）。

- HTTP 入口：`app/main.py`
- API 前缀：`/v1/workflows`
- Worker 入口：`celery_app/celery.py`
- 工作区标准端口：`8004`（容器内常见为 `8000`）

---

## 2. 关键目录

```text
app/
├── api/                      # workflows / executions
├── engine/                   # 图执行器、上下文、节点注册
├── engine/nodes/             # llm/api/condition/classifier/tool/agent 等节点
├── services/                 # workflow_service / validation_service
├── integrations/             # AI client / HTTP client
├── models/                   # ORM 模型
├── schemas/                  # Pydantic 模型
└── main.py
celery_app/
├── celery.py
└── tasks.py
```

---

## 3. 强约束规范

### 3.1 执行语义稳定

- 禁止破坏 DAG 拓扑执行与节点状态流转语义。
- 变量引用、模板渲染、分支判断必须保持向后兼容。

### 3.2 节点扩展规范

- 新增节点类型必须同时更新：
  - 节点 schema
  - 节点执行器实现
  - 节点注册表
  - 运行时校验逻辑

### 3.3 异步与超时

- 节点执行应避免阻塞事件循环。
- 外部调用必须带超时与错误映射，避免卡死整个流程。

### 3.4 数据库迁移

- 模型调整必须附带 Alembic 迁移文件。

---

## 4. 高频改动入口

- 执行引擎：`app/engine/executor.py`
- 图与上下文：`app/engine/graph.py`、`app/engine/context.py`
- 节点实现：`app/engine/nodes/*`
- API 层：`app/api/workflows.py`、`app/api/executions.py`
- Celery 任务：`celery_app/tasks.py`

---

## 5. 本地开发命令

```bash
# 依赖
poetry install

# 迁移
poetry run alembic upgrade head

# 启动 API
poetry run uvicorn app.main:app --host 0.0.0.0 --port 8004 --reload

# 启动 Worker
poetry run celery -A celery_app.celery worker --loglevel=info -Q workflow

# 测试
poetry run pytest
```

---

## 6. AI 代理改动流程

1. 先界定改动是 schema、节点执行器还是调度链路。
2. 涉及节点行为变化时，先补/改校验再改执行逻辑。
3. 涉及异步任务时同步验证 API 与 worker 的协作路径。
4. 提交前至少执行 `pytest`（或说明未执行原因）。

---

## 7. 变更自检清单

- 是否破坏已有工作流 JSON 兼容性？
- 是否遗漏节点注册或校验更新？
- 是否引入阻塞调用导致执行超时？
- 是否遗漏迁移与环境变量更新？
