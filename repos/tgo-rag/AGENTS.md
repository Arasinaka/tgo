# TGO RAG AGENTS Guide

> 适用范围：`repos/tgo-rag`  
> 最近校准：2026-03-05（按当前代码与配置扫描）

## 1. 服务定位

`tgo-rag` 负责文档解析、向量化、检索、网站抓取与 QA 处理。

- HTTP 入口：`src/rag_service/main.py`
- API 前缀：核心业务路由在 `/v1/*`
- 系统端点：`/health`、`/ready`、`/metrics`
- 工作区标准端口：`18082`（开发编排），容器默认 `8082`

---

## 2. 关键目录

```text
src/rag_service/
├── routers/                  # collections/files/websites/qa/monitoring
├── services/                 # 检索、向量库、embedding、爬虫
├── tasks/                    # Celery 任务（文档处理/抓取/QA）
├── models/                   # ORM 模型
├── schemas/                  # Pydantic 模型
├── auth/                     # 认证依赖
├── database.py               # DB 初始化与健康检查
└── main.py                   # FastAPI 入口
```

---

## 3. 强约束规范

### 3.1 数据一致性

- 文件、文档块、集合三者状态必须保持一致。
- 删除/重建流程需考虑向量索引与文档元数据同步清理。

### 3.2 任务与性能

- 重 CPU/IO 处理放 Celery 任务，避免阻塞 HTTP 请求线程。
- 批处理参数、分块参数、embedding 参数变更必须评估回归成本。

### 3.3 类型与边界

- 禁止用裸 `dict` 在 service 核心接口传复杂业务对象。
- 跨服务调用保持既有接口契约（尤其与 `tgo-ai` 的检索与配置同步接口）。

### 3.4 迁移与配置

- ORM 变更必须附带 Alembic 迁移。
- 模型、provider、限流、上传大小等策略统一走 `config.py` / `.env`。

---

## 4. 高频改动入口

- 检索逻辑：`src/rag_service/services/search.py`
- 向量存储：`src/rag_service/services/vector_store.py`
- Embedding：`src/rag_service/services/embedding.py`
- 文档处理：`src/rag_service/tasks/document_processing*.py`
- 站点抓取：`src/rag_service/tasks/website_crawling.py`

---

## 5. 本地开发命令

```bash
# 依赖
poetry install --with dev

# 迁移
poetry run alembic upgrade head

# 启动 API
poetry run uvicorn src.rag_service.main:app --host 0.0.0.0 --port 8082 --reload

# 启动 Celery Worker
poetry run celery -A src.rag_service.tasks.celery_app worker \
  --loglevel=info \
  -Q document_processing,embedding,website_crawling,qa_processing,celery

# 质量检查
poetry run pytest
poetry run flake8 src tests
poetry run mypy src
```

---

## 6. AI 代理改动流程

1. 先判定改动是 HTTP 路由、检索服务还是后台任务。
2. 先改 schema 与模型，再改 service 与 router。
3. 任务链路改动时，同步验证状态流转与重试策略。
4. 影响 embedding/检索结果的改动需做回归样例验证。
5. 提交前至少执行 `pytest`（或解释未执行原因）。

---

## 7. 变更自检清单

- 是否破坏 `/v1` 接口兼容性？
- 是否引入重复入库或脏索引问题？
- 是否把重处理逻辑误放到了同步请求路径？
- 是否遗漏迁移或配置项？
