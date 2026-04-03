# TGO Kubernetes 部署审计

> 审计目标：围绕“部署到现有 Kubernetes 集群”整理当前仓库的组件、依赖、配置、容器化现状与落地风险。  
> 审计时间：2026-04-03  
> 审计范围：`E:\go\src\github\tgo`

## 结论摘要

- 当前仓库是“前后端分离 + 多服务/多组件”架构，不是单体应用。
- 仓库当前没有正式 Helm Chart，也没有可直接复用的仓库级 Kubernetes manifests。
- 现有部署事实主要体现在根级 `docker-compose.yml`、`docker-compose.source.yml`、`tgo.sh`、各服务 `Dockerfile`、各服务 `config.py` / `.env.example`。
- 若落地到现有 Kubernetes 集群，建议优先采用“应用上集群，中间件沿用现有外部/托管基础设施”的方案；“应用和中间件全上集群”可做，但复杂度明显更高。

## A. 项目组件清单

### A.1 整体架构判断

- **已确认**：当前仓库是多服务架构，核心调用关系可由根级 [`AGENTS.md`](E:/go/src/github/tgo/AGENTS.md)、[`docker-compose.yml`](E:/go/src/github/tgo/docker-compose.yml) 和各服务目录共同印证。
- **已确认**：前端与后端分离。
  - 后端服务位于 `repos/tgo-api`、`repos/tgo-ai`、`repos/tgo-rag`、`repos/tgo-platform`、`repos/tgo-workflow`、`repos/tgo-plugin-runtime`、`repos/tgo-device-control`
  - 前端位于 `repos/tgo-web`、`repos/tgo-widget-js`
- **已确认**：存在异步组件与后台任务。
  - `tgo-rag-worker`
  - `tgo-rag-beat`
  - `tgo-workflow-worker`
- **已确认**：存在非集群内主业务组件。
  - 设备侧 agent：`repos/tgo-device-agent`
  - CLI / MCP 工具：`repos/tgo-cli`、`repos/tgo-widget-cli`
  - SDK / 客户端：`repos/tgo-widget-miniprogram`、`repos/tgo-widget-flutter`、`repos/tgo-widget-ios`
  - 文档/站点：`docs-site`、`website`

### A.2 组件清单

| 组件 | 目录 / 来源 | 职责 | 是否建议作为 K8s 工作负载 | 证据 |
| --- | --- | --- | --- | --- |
| tgo-api | `repos/tgo-api` | 核心 API 网关、多租户主入口，连接 AI / RAG / Platform / Workflow / Plugin / Device Control | 必须 | [`docker-compose.yml`](E:/go/src/github/tgo/docker-compose.yml), [`repos/tgo-api/app/core/config.py`](E:/go/src/github/tgo/repos/tgo-api/app/core/config.py) |
| tgo-ai | `repos/tgo-ai` | LLM、Agent Runtime、技能执行 | 必须 | [`docker-compose.yml`](E:/go/src/github/tgo/docker-compose.yml), [`repos/tgo-ai/app/config.py`](E:/go/src/github/tgo/repos/tgo-ai/app/config.py) |
| tgo-rag | `repos/tgo-rag` | 知识库、向量检索、文档解析 API | 按功能决定，启用知识库则必须 | [`docker-compose.yml`](E:/go/src/github/tgo/docker-compose.yml), [`repos/tgo-rag/src/rag_service/config.py`](E:/go/src/github/tgo/repos/tgo-rag/src/rag_service/config.py) |
| tgo-rag-worker | compose 服务 | RAG 异步任务 worker | 启用知识库则必须 | [`docker-compose.yml`](E:/go/src/github/tgo/docker-compose.yml) |
| tgo-rag-beat | compose 服务 | RAG 定时任务 / Celery Beat | 启用知识库则必须 | [`docker-compose.yml`](E:/go/src/github/tgo/docker-compose.yml) |
| tgo-platform | `repos/tgo-platform` | 渠道消息同步与外部平台适配 | 按功能决定，启用外部渠道时建议部署 | [`docker-compose.yml`](E:/go/src/github/tgo/docker-compose.yml), [`repos/tgo-platform/app/core/config.py`](E:/go/src/github/tgo/repos/tgo-platform/app/core/config.py) |
| tgo-workflow | `repos/tgo-workflow` | 工作流引擎 API | 按功能决定，启用工作流则建议部署 | [`docker-compose.yml`](E:/go/src/github/tgo/docker-compose.yml), [`repos/tgo-workflow/app/config.py`](E:/go/src/github/tgo/repos/tgo-workflow/app/config.py) |
| tgo-workflow-worker | compose 服务 | 工作流 Celery Worker | 启用工作流则建议部署 | [`docker-compose.yml`](E:/go/src/github/tgo/docker-compose.yml) |
| tgo-plugin-runtime | `repos/tgo-plugin-runtime` | 插件 / MCP 运行时 | 按功能决定，启用插件能力时建议部署 | [`docker-compose.yml`](E:/go/src/github/tgo/docker-compose.yml), [`repos/tgo-plugin-runtime/app/config.py`](E:/go/src/github/tgo/repos/tgo-plugin-runtime/app/config.py) |
| tgo-device-control | `repos/tgo-device-control` | 设备管理、截图、设备控制 API / RPC | 仅在设备控制场景必须 | [`docker-compose.yml`](E:/go/src/github/tgo/docker-compose.yml), [`repos/tgo-device-control/app/config.py`](E:/go/src/github/tgo/repos/tgo-device-control/app/config.py) |
| tgo-web | `repos/tgo-web` | 管理后台前端 | 面向管理端场景时必须 | [`docker-compose.yml`](E:/go/src/github/tgo/docker-compose.yml), [`repos/tgo-web/Dockerfile`](E:/go/src/github/tgo/repos/tgo-web/Dockerfile) |
| tgo-widget-js | `repos/tgo-widget-js` | 访客聊天前端 widget | 面向访客聊天场景时必须 | [`docker-compose.yml`](E:/go/src/github/tgo/docker-compose.yml), [`repos/tgo-widget-js/Dockerfile`](E:/go/src/github/tgo/repos/tgo-widget-js/Dockerfile) |
| postgres | compose 服务 | 主数据库，包含 pgvector 扩展 | 基础设施，必须 | [`docker-compose.yml`](E:/go/src/github/tgo/docker-compose.yml), [`.env.example`](E:/go/src/github/tgo/.env.example) |
| redis | compose 服务 | 缓存、队列、Celery broker/backend | 基础设施，必须 | [`docker-compose.yml`](E:/go/src/github/tgo/docker-compose.yml), [`.env.example`](E:/go/src/github/tgo/.env.example) |
| wukongim | compose 服务 | IM / 实时消息基础设施 | 当前主链路建议保留 | [`docker-compose.yml`](E:/go/src/github/tgo/docker-compose.yml), [`.env.example`](E:/go/src/github/tgo/.env.example) |
| nginx | compose 服务 | 根级反向代理与静态入口 | K8s 中通常不直接照搬 | [`docker-compose.yml`](E:/go/src/github/tgo/docker-compose.yml) |
| certbot | compose 服务 | 证书申请 / 续期 | K8s 中通常由 cert-manager 取代 | [`docker-compose.yml`](E:/go/src/github/tgo/docker-compose.yml) |
| tgo-celery-flower | compose 服务 | Celery 运维面板 | 可选 | [`docker-compose.yml`](E:/go/src/github/tgo/docker-compose.yml) |

### A.3 其他目录职责

| 目录 | 职责 | 是否属于 K8s 主部署链路 | 证据 |
| --- | --- | --- | --- |
| `docs-site` | 文档站点，包含独立部署说明 | 否 | [`docs-site/package.json`](E:/go/src/github/tgo/docs-site/package.json), [`docs-site/README.md`](E:/go/src/github/tgo/docs-site/README.md) |
| `website` | 官网 / 营销站点 | 否 | [`website/Dockerfile`](E:/go/src/github/tgo/website/Dockerfile) |
| `repos/tgo-cli` | 员工 CLI 与 MCP Server | 否 | [`repos/tgo-cli/package.json`](E:/go/src/github/tgo/repos/tgo-cli/package.json), [`repos/tgo-cli/README.md`](E:/go/src/github/tgo/repos/tgo-cli/README.md) |
| `repos/tgo-widget-cli` | 访客 CLI 与 MCP Server | 否 | [`repos/tgo-widget-cli/package.json`](E:/go/src/github/tgo/repos/tgo-widget-cli/package.json) |
| `repos/tgo-device-agent` | 设备侧 Go agent，运行在受控设备上 | 否，通常跑在设备或边缘主机 | [`repos/tgo-device-agent/Dockerfile`](E:/go/src/github/tgo/repos/tgo-device-agent/Dockerfile), [`repos/tgo-device-agent/README.md`](E:/go/src/github/tgo/repos/tgo-device-agent/README.md) |
| `repos/tgo-widget-miniprogram` | 微信小程序客户端 | 否 | [`repos/tgo-widget-miniprogram/README.md`](E:/go/src/github/tgo/repos/tgo-widget-miniprogram/README.md) |
| `repos/tgo-widget-flutter` | Flutter 客户端 SDK | 否 | [`repos/tgo-widget-flutter/README.md`](E:/go/src/github/tgo/repos/tgo-widget-flutter/README.md) |
| `repos/tgo-widget-ios` | iOS 客户端 SDK | 否 | [`repos/tgo-widget-ios/README.md`](E:/go/src/github/tgo/repos/tgo-widget-ios/README.md) |

## B. 中间件依赖清单

### B.1 依赖总表

| 依赖 | 用途 | 是否必选 | 状态 | 仓库证据 | 集群侧需准备内容 |
| --- | --- | --- | --- | --- | --- |
| PostgreSQL + pgvector | 主数据库、向量检索底座 | 必选 | 已确认 | [`docker-compose.yml`](E:/go/src/github/tgo/docker-compose.yml), [`.env.example`](E:/go/src/github/tgo/.env.example), [`repos/tgo-rag/src/rag_service/config.py`](E:/go/src/github/tgo/repos/tgo-rag/src/rag_service/config.py) | 主机、端口、数据库名、用户名、密码、`pgvector` 扩展 |
| Redis | 缓存、Celery broker/backend、可能的会话/限流支撑 | 必选 | 已确认 | [`docker-compose.yml`](E:/go/src/github/tgo/docker-compose.yml), [`.env.example`](E:/go/src/github/tgo/.env.example), [`repos/tgo-workflow/app/config.py`](E:/go/src/github/tgo/repos/tgo-workflow/app/config.py) | 主机、端口、密码、DB index、最大连接策略 |
| WuKongIM | 即时消息、长连接/消息同步 | 当前主链路建议视为必选 | 已确认 | [`docker-compose.yml`](E:/go/src/github/tgo/docker-compose.yml), [`.env.example`](E:/go/src/github/tgo/.env.example), [`tgo.sh`](E:/go/src/github/tgo/tgo.sh) | HTTP/TCP/WS/WSS 地址、域名、对外暴露端口、插件目录 |
| Celery | RAG/Workflow 异步任务模型 | 启用对应功能时必选 | 已确认 | [`docker-compose.yml`](E:/go/src/github/tgo/docker-compose.yml), [`repos/tgo-rag/src/rag_service/celery_app.py`](E:/go/src/github/tgo/repos/tgo-rag/src/rag_service/celery_app.py), [`repos/tgo-workflow/app/celery_app.py`](E:/go/src/github/tgo/repos/tgo-workflow/app/celery_app.py) | 不单独准备中间件，但要准备 Redis 与 worker / beat 工作负载 |
| 对象存储（OSS / MinIO / S3） | 文件上传与静态资源持久化 | 可选，但生产强烈建议 | 已确认 | [`repos/tgo-api/.env.example`](E:/go/src/github/tgo/repos/tgo-api/.env.example), [`repos/tgo-api/app/core/config.py`](E:/go/src/github/tgo/repos/tgo-api/app/core/config.py), [`repos/tgo-device-control/.env.example`](E:/go/src/github/tgo/repos/tgo-device-control/.env.example) | Endpoint、Bucket、Access Key、Secret Key、Region、外链域名 |
| 本地文件卷 | 未启用对象存储时的文件落盘 | 可选回退方案 | 已确认 | [`docker-compose.yml`](E:/go/src/github/tgo/docker-compose.yml), [`repos/tgo-rag/src/rag_service/config.py`](E:/go/src/github/tgo/repos/tgo-rag/src/rag_service/config.py), [`repos/tgo-device-control/app/config.py`](E:/go/src/github/tgo/repos/tgo-device-control/app/config.py) | PVC 或宿主机目录，需为上传目录、截图目录、插件目录提供持久化 |
| Store Service | 平台商品 / Store 相关能力 | 可选，取决于业务功能 | 已确认 | [`.env.example`](E:/go/src/github/tgo/.env.example), [`repos/tgo-api/app/core/config.py`](E:/go/src/github/tgo/repos/tgo-api/app/core/config.py) | `STORE_SERVICE_URL`、`STORE_WEB_URL`、网络连通性 |
| 第三方 LLM / Embedding 提供商 | 模型推理与向量生成 | 必选 | 已确认 | [`repos/tgo-ai/app/models/llm_provider.py`](E:/go/src/github/tgo/repos/tgo-ai/app/models/llm_provider.py), [`repos/tgo-ai/app/services/llm/`](E:/go/src/github/tgo/repos/tgo-ai/app/services/llm), [`repos/tgo-rag/src/rag_service/main.py`](E:/go/src/github/tgo/repos/tgo-rag/src/rag_service/main.py) | API Base URL、API Key、模型名、网络出站策略 |
| SMTP | 邮件渠道发送 | 可选 | 已确认 | [`repos/tgo-platform/app/channels/email_channel.py`](E:/go/src/github/tgo/repos/tgo-platform/app/channels/email_channel.py) | SMTP Host、Port、TLS、用户名、密码 |
| Slack / Telegram / 飞书 / 钉钉 等外部 API | 渠道消息对接 | 可选 | 已确认 | [`repos/tgo-platform/app/channels`](E:/go/src/github/tgo/repos/tgo-platform/app/channels), [`repos/tgo-platform/app/services/platforms/`](E:/go/src/github/tgo/repos/tgo-platform/app/services/platforms) | 各渠道 Token、Webhook、App ID/Secret、回调域名 |
| Kafka | 事件流 / 消息总线 | 待确认 | 待确认 | [`repos/README.md`](E:/go/src/github/tgo/repos/README.md), [`repos/tgo-api/.env.example`](E:/go/src/github/tgo/repos/tgo-api/.env.example) | 仅当后续确认代码实际依赖时才需准备 Broker/Topic |
| 向量数据库（Weaviate / Pinecone 等） | 参考文档中提及的替代方案 | 当前实现非必选 | 待确认 | [`repos/tgo-rag/docs/deployment-guide.md`](E:/go/src/github/tgo/repos/tgo-rag/docs/deployment-guide.md) | 当前代码未证实，先不要作为集群前置项 |

### B.2 关键依赖说明

1. PostgreSQL 是当前事实上的共享主库。  
   证据：根级 compose 使用 `ankane/pgvector:v0.5.1`；`tgo.sh` 在启动阶段等待 Postgres 可用并顺序执行 7 个服务的 Alembic 迁移。

2. Redis 是异步任务的核心依赖。  
   证据：`tgo-rag` 与 `tgo-workflow` 都定义了 Celery app；根级 compose 中 `tgo-rag-worker`、`tgo-rag-beat`、`tgo-workflow-worker` 都依赖 Redis。

3. 当前 RAG 实现以 PostgreSQL/pgvector 为主，而不是独立向量数据库。  
   证据：`repos/tgo-rag/src/rag_service/config.py` 使用 `DATABASE_URL`；根级 compose 未编排 Milvus/Qdrant/Weaviate/Pinecone。

4. WuKongIM 不是“可有可无的演示组件”，而是当前实时消息链路的重要部分。  
   证据：根级 `.env.example`、compose、`tgo.sh` 都显式配置和初始化 WuKongIM；根级 README 也要求准备 IM 服务。

5. Kafka 目前不能算已确认依赖。  
   证据：虽然 `repos/README.md` 与 `repos/tgo-api/.env.example` 还残留 `KAFKA_*` 配置，但本次扫描未在当前主运行链路代码中找到与 Kafka 强绑定的服务初始化逻辑，应标记为“待确认”。

## C. 配置清单

### C.1 配置来源

本次确认过的主要配置来源如下：

- 根级共享配置：[`E:/go/src/github/tgo/.env.example`](E:/go/src/github/tgo/.env.example), [`E:/go/src/github/tgo/.env.dev.example`](E:/go/src/github/tgo/.env.dev.example)
- 根级编排：[`E:/go/src/github/tgo/docker-compose.yml`](E:/go/src/github/tgo/docker-compose.yml), [`E:/go/src/github/tgo/docker-compose.source.yml`](E:/go/src/github/tgo/docker-compose.source.yml), [`E:/go/src/github/tgo/docker-compose.tools.yml`](E:/go/src/github/tgo/docker-compose.tools.yml)
- 启动与迁移逻辑：[`E:/go/src/github/tgo/tgo.sh`](E:/go/src/github/tgo/tgo.sh)
- 各服务配置：
  - [`E:/go/src/github/tgo/repos/tgo-api/app/core/config.py`](E:/go/src/github/tgo/repos/tgo-api/app/core/config.py)
  - [`E:/go/src/github/tgo/repos/tgo-ai/app/config.py`](E:/go/src/github/tgo/repos/tgo-ai/app/config.py)
  - [`E:/go/src/github/tgo/repos/tgo-rag/src/rag_service/config.py`](E:/go/src/github/tgo/repos/tgo-rag/src/rag_service/config.py)
  - [`E:/go/src/github/tgo/repos/tgo-platform/app/core/config.py`](E:/go/src/github/tgo/repos/tgo-platform/app/core/config.py)
  - [`E:/go/src/github/tgo/repos/tgo-workflow/app/config.py`](E:/go/src/github/tgo/repos/tgo-workflow/app/config.py)
  - [`E:/go/src/github/tgo/repos/tgo-plugin-runtime/app/config.py`](E:/go/src/github/tgo/repos/tgo-plugin-runtime/app/config.py)
  - [`E:/go/src/github/tgo/repos/tgo-device-control/app/config.py`](E:/go/src/github/tgo/repos/tgo-device-control/app/config.py)
- 前端运行时注入：
  - [`E:/go/src/github/tgo/repos/tgo-web/docker-entrypoint.sh`](E:/go/src/github/tgo/repos/tgo-web/docker-entrypoint.sh)
  - [`E:/go/src/github/tgo/repos/tgo-widget-js/docker-entrypoint.sh`](E:/go/src/github/tgo/repos/tgo-widget-js/docker-entrypoint.sh)

### C.2 按组件整理的关键配置

#### C.2.1 根级共享配置

| 配置项 | 作用 | 是否必填 | 示例值 / 推断值 | 建议存放 | 组件 |
| --- | --- | --- | --- | --- | --- |
| `POSTGRES_DB` | PostgreSQL 数据库名 | 必填 | `tgo` | Secret 或外部 DB 连接 Secret | 共享基础设施 |
| `POSTGRES_USER` | PostgreSQL 用户名 | 必填 | `tgo` | Secret | 共享基础设施 |
| `POSTGRES_PASSWORD` | PostgreSQL 密码 | 必填 | `tgo` | Secret | 共享基础设施 |
| `POSTGRES_PORT` | PostgreSQL 端口 | 必填 | `5432` | ConfigMap | 共享基础设施 |
| `REDIS_PORT` | Redis 端口 | 必填 | `6379` | ConfigMap | 共享基础设施 |
| `ENVIRONMENT` | 运行环境标识 | 建议必填 | `PRODUCTION` | ConfigMap | 多组件共享 |
| `STORE_SERVICE_URL` | Store 后端服务地址 | 可选 | `https://store.tgo.ai` | ConfigMap | `tgo-api`, `tgo-ai` |
| `STORE_WEB_URL` | Store 前端地址 | 可选 | `https://store.tgo.ai` | ConfigMap | `tgo-api` |
| `WK_EXTERNAL_IP` | WuKongIM 外部 IP | 如自建 IM 则必填 | 空，需按集群出口填写 | ConfigMap | `wukongim` |
| `WK_EXTERNAL_TCPADDR` | WuKongIM TCP 外部地址 | 如自建 IM 则建议填 | 例如 `im.example.com:5100` | ConfigMap | `wukongim` |
| `WK_EXTERNAL_WSADDR` | WuKongIM WS 地址 | 如前端走 WS 则建议填 | 例如 `ws://im.example.com:5200` | ConfigMap | `wukongim` |
| `WK_EXTERNAL_WSSADDR` | WuKongIM WSS 地址 | 如 HTTPS/WSS 则建议填 | 例如 `wss://im.example.com:5210` | ConfigMap | `wukongim` |
| `WEB_DOMAIN` / `WIDGET_DOMAIN` / `API_DOMAIN` | 根级 nginx/certbot 使用的域名 | K8s 中通常不再直接使用 | 空 | Ingress 配置，不建议继续放应用容器环境变量 | 边缘入口 |
| `SSL_MODE` / `SSL_EMAIL` | 根级 certbot 配置 | K8s 中通常不用 | `none` / 空 | Ingress / cert-manager | 边缘入口 |
| `STORAGE_TYPE` | 全局存储方案提示 | 按方案决定 | `local` / `oss` / `minio` | ConfigMap | 多组件共享 |

#### C.2.2 tgo-api

| 配置项 | 作用 | 是否必填 | 示例值 / 推断值 | 建议存放 | 组件 |
| --- | --- | --- | --- | --- | --- |
| `DATABASE_URL` | API 主库连接 | 必填 | `postgresql+asyncpg://user:pass@postgres:5432/tgo` | Secret | `tgo-api` |
| `SECRET_KEY` | JWT / 签名密钥 | 必填 | 长随机串，至少 32 字符 | Secret | `tgo-api` |
| `API_BASE_URL` | API 对外基地址，用于回调与链接生成 | 必填 | `https://api.example.com` | ConfigMap | `tgo-api` |
| `BACKEND_CORS_ORIGINS` | 外部前端跨域白名单 | 建议必填 | `["https://admin.example.com","https://widget.example.com"]` | ConfigMap | `tgo-api` |
| `INTERNAL_SERVICE_HOST` | 内部无鉴权服务绑定地址 | 建议必填 | `0.0.0.0` | ConfigMap | `tgo-api` |
| `INTERNAL_SERVICE_PORT` | 内部无鉴权端口 | 建议必填 | `8001` | ConfigMap | `tgo-api` |
| `PLATFORM_SERVICE_URL` | 平台服务内部地址 | 按功能决定 | `http://tgo-platform:8003` | ConfigMap | `tgo-api` |
| `AI_SERVICE_URL` | AI 服务内部地址 | 必填 | `http://tgo-ai:8081` | ConfigMap | `tgo-api` |
| `RAG_SERVICE_URL` | RAG 服务内部地址 | 启用知识库时必填 | `http://tgo-rag:8082` | ConfigMap | `tgo-api` |
| `WORKFLOW_SERVICE_URL` | Workflow 服务内部地址 | 启用工作流时必填 | `http://tgo-workflow:8000` | ConfigMap | `tgo-api` |
| `PLUGIN_RUNTIME_URL` | 插件运行时内部地址 | 启用插件时必填 | `http://tgo-plugin-runtime:8090` | ConfigMap | `tgo-api` |
| `DEVICE_CONTROL_SERVICE_URL` | 设备控制服务内部地址 | 启用设备控制时必填 | `http://tgo-device-control:8085` | ConfigMap | `tgo-api` |
| `WUKONGIM_SERVICE_URL` | WuKongIM API 地址 | 当前建议必填 | `http://wukongim:5001` | ConfigMap | `tgo-api` |
| `REDIS_URL` | Redis 连接 | 建议必填 | `redis://redis:6379/0` | Secret | `tgo-api` |
| `STORE_SERVICE_URL` / `STORE_WEB_URL` | Store 服务与前端地址 | 可选 | 仓库默认指向 `store.tgo.ai` | ConfigMap | `tgo-api` |
| `STORAGE_TYPE` | 上传存储类型 | 必填 | `local` / `oss` / `minio` | ConfigMap | `tgo-api` |
| `UPLOAD_BASE_DIR` | 本地上传目录 | `local` 时必填 | `/app/uploads` 或挂载路径 | ConfigMap + PVC | `tgo-api` |
| `OSS_ENDPOINT` / `OSS_BUCKET_NAME` / `OSS_BUCKET_URL` / `OSS_ACCESS_KEY_ID` / `OSS_ACCESS_KEY_SECRET` | 阿里云 OSS 配置 | `oss` 时必填 | 见 `.env.example` 注释 | Secret（URL 可放 ConfigMap） | `tgo-api` |
| `MINIO_URL` / `MINIO_UPLOAD_URL` / `MINIO_DOWNLOAD_URL` / `MINIO_ACCESS_KEY_ID` / `MINIO_SECRET_ACCESS_KEY` / `MINIO_BUCKET_NAME` | MinIO 配置 | `minio` 时必填 | 见 `.env.example` 注释 | Secret（公共 URL 可放 ConfigMap） | `tgo-api` |
| `RAG_SERVICE_API_KEY` / `AI_SERVICE_API_KEY` / `PLATFORM_SERVICE_API_KEY` | 预留的服务间鉴权 Key | 当前 compose 未显式使用，按需 | `optional_key` | Secret | `tgo-api` |
| `KAFKA_*` | Kafka 连接与 Topic | 待确认 | `.env.example` 有默认值 | 仅在确认启用后再配置 | `tgo-api` |

#### C.2.3 tgo-ai

| 配置项 | 作用 | 是否必填 | 示例值 / 推断值 | 建议存放 | 组件 |
| --- | --- | --- | --- | --- | --- |
| `database_url` / `DATABASE_URL` | AI 服务数据库连接 | 必填 | `postgresql+asyncpg://...` | Secret | `tgo-ai` |
| `secret_key` / `SECRET_KEY` | JWT / 服务签名 | 必填 | 长随机串 | Secret | `tgo-ai` |
| `api_service_url` / `API_SERVICE_URL` | 回调或主系统 API 地址 | 必填 | `http://tgo-api:8000` | ConfigMap | `tgo-ai` |
| `rag_service_url` / `RAG_SERVICE_URL` | RAG 内部地址 | 启用知识库时必填 | `http://tgo-rag:8082` | ConfigMap | `tgo-ai` |
| `workflow_service_url` / `WORKFLOW_SERVICE_URL` | Workflow 内部地址 | 启用工作流时必填 | `http://tgo-workflow:8000` | ConfigMap | `tgo-ai` |
| `plugin_runtime_url` / `PLUGIN_RUNTIME_URL` | 插件运行时地址 | 启用插件时必填 | `http://tgo-plugin-runtime:8090` | ConfigMap | `tgo-ai` |
| `device_control_mcp_endpoint` | 设备控制 MCP 模板地址 | 启用设备控制时必填 | `http://tgo-device-control:8085/mcp/{device_id}` | ConfigMap | `tgo-ai` |
| `skills_base_dir` | 技能文件目录 | 使用技能导入时建议持久化 | `/data/skills` | ConfigMap + PVC | `tgo-ai` |
| `github_token` | GitHub 拉取技能时使用 | 可选 | GitHub PAT | Secret | `tgo-ai` |
| `store_service_url` / `store_api_key` | Store 服务配置 | 可选 | 业务决定 | Secret / ConfigMap | `tgo-ai` |
| `cors_origins` | AI 服务 CORS 白名单 | 建议必填 | 管理后台/内部域名 | ConfigMap | `tgo-ai` |
| `DEVICE_CONTROL_AGENTOS_URL` | Computer Use Agent 地址 | 启用 AgentOS 时必填 | `http://tgo-device-control:7778` | ConfigMap | `tgo-ai` |

#### C.2.4 tgo-rag

| 配置项 | 作用 | 是否必填 | 示例值 / 推断值 | 建议存放 | 组件 |
| --- | --- | --- | --- | --- | --- |
| `DATABASE_URL` | RAG 数据库连接 | 必填 | `postgresql+asyncpg://...` | Secret | `tgo-rag`, `tgo-rag-worker`, `tgo-rag-beat` |
| `REDIS_URL` | Redis 连接 | 必填 | `redis://redis:6379/2` | Secret | `tgo-rag`, `tgo-rag-worker`, `tgo-rag-beat` |
| `CELERY_BROKER_URL` / `CELERY_RESULT_BACKEND` | Celery 显式配置 | 可选，不填会回退到 `REDIS_URL` | `redis://redis:6379/2` | Secret | `tgo-rag`, `tgo-rag-worker`, `tgo-rag-beat` |
| `UPLOAD_DIR` | 文档上传目录 | 未接对象存储时必填 | `/app/uploads` | ConfigMap + PVC | `tgo-rag`, `tgo-rag-worker` |
| `EMBEDDING_PROVIDER` | Embedding 提供商 | 必填 | `openai` / `qwen3` | ConfigMap | `tgo-rag` |
| `OPENAI_API_KEY` | OpenAI Embedding Key | `openai` 时必填 | 外部密钥 | Secret | `tgo-rag`, `tgo-rag-worker` |
| `OPENAI_COMPATIBLE_BASE_URL` | OpenAI 兼容 Embedding 接口地址 | 可选 | `http://ollama:11434/v1` 类似值 | ConfigMap | `tgo-rag`, `tgo-rag-worker` |
| `QWEN3_API_KEY` / `QWEN3_BASE_URL` / `QWEN3_MODEL` | DashScope Embedding 配置 | `qwen3` 时必填 | `.env.example` 默认值 | Secret / ConfigMap | `tgo-rag`, `tgo-rag-worker` |
| `CHUNK_SIZE` / `CHUNK_OVERLAP` / `BATCH_SIZE` | 文档切分与处理参数 | 可选 | `1000` / `200` / `50` | ConfigMap | `tgo-rag`, `tgo-rag-worker` |
| `CORS_ORIGINS` | 跨域白名单 | 可选 | 管理后台域名 | ConfigMap | `tgo-rag` |

#### C.2.5 tgo-platform

| 配置项 | 作用 | 是否必填 | 示例值 / 推断值 | 建议存放 | 组件 |
| --- | --- | --- | --- | --- | --- |
| `api_base_url` / `API_BASE_URL` | 指向 `tgo-api` 的内部地址 | 必填 | `http://tgo-api:8000` | ConfigMap | `tgo-platform` |
| `database_url` / `DATABASE_URL` | Platform 数据库连接 | 必填 | `postgresql+asyncpg://...` | Secret | `tgo-platform` |
| `redis_url` / `REDIS_URL` | Redis 缓存连接 | 可选但建议 | `redis://redis:6379/0` | Secret | `tgo-platform` |
| `sse_backpressure_limit` | SSE 背压限制 | 可选 | `1000` | ConfigMap | `tgo-platform` |
| `request_timeout_seconds` | 外部请求超时 | 可选 | `120` | ConfigMap | `tgo-platform` |
| `log_level` | 日志级别 | 可选 | `INFO` | ConfigMap | `tgo-platform` |

补充说明：  
`tgo-platform` 对外部渠道的大量凭据并不固定写在环境变量里，而是通过平台配置模型落库。证据见 [`repos/tgo-api/app/models/platform.py`](E:/go/src/github/tgo/repos/tgo-api/app/models/platform.py) 中的 `api_key` 与 `config` 字段，以及 [`repos/tgo-platform/app/channels`](E:/go/src/github/tgo/repos/tgo-platform/app/channels) / [`repos/tgo-platform/app/services/platforms`](E:/go/src/github/tgo/repos/tgo-platform/app/services/platforms)。

#### C.2.6 tgo-workflow

| 配置项 | 作用 | 是否必填 | 示例值 / 推断值 | 建议存放 | 组件 |
| --- | --- | --- | --- | --- | --- |
| `DATABASE_URL` | Workflow 数据库连接 | 必填 | `postgresql+asyncpg://...` | Secret | `tgo-workflow`, `tgo-workflow-worker` |
| `REDIS_URL` | Celery Broker / Backend | 必填 | `redis://redis:6379/2` | Secret | `tgo-workflow`, `tgo-workflow-worker` |
| `AI_SERVICE_URL` | AI 服务内部地址 | 必填 | `http://tgo-ai:8081` | ConfigMap | `tgo-workflow`, `tgo-workflow-worker` |
| `ALLOWED_ORIGINS` | 跨域白名单 | 可选 | `["*"]` 或域名列表 | ConfigMap | `tgo-workflow` |
| `OPENAI_API_KEY` / `ANTHROPIC_API_KEY` | 样例文件中的 LLM Key | 待确认是否当前主逻辑必需 | `your_openai_api_key` | Secret | `tgo-workflow` |

#### C.2.7 tgo-plugin-runtime

| 配置项 | 作用 | 是否必填 | 示例值 / 推断值 | 建议存放 | 组件 |
| --- | --- | --- | --- | --- | --- |
| `DATABASE_URL` | Plugin Runtime 数据库连接 | 必填 | `postgresql+asyncpg://...` | Secret | `tgo-plugin-runtime` |
| `SECRET_KEY` | JWT 校验密钥，需与 `tgo-api` 对齐 | 必填 | 同 API Secret | Secret | `tgo-plugin-runtime` |
| `AI_SERVICE_URL` | AI 服务地址，用于工具同步 | 必填 | `http://tgo-ai:8081` | ConfigMap | `tgo-plugin-runtime` |
| `PLUGIN_SOCKET_PATH` | 插件 Unix Socket 路径 | 使用本地 socket 时必填 | `/var/run/tgo/tgo.sock` | ConfigMap + EmptyDir/PVC | `tgo-plugin-runtime` |
| `PLUGIN_TCP_PORT` | 插件 TCP 调试端口 | 可选 | 空 | ConfigMap | `tgo-plugin-runtime` |
| `PLUGIN_BASE_PATH` | 插件存储目录 | 建议必填 | `/var/lib/tgo/plugins` | ConfigMap + PVC | `tgo-plugin-runtime` |
| `LOG_LEVEL` / `ENVIRONMENT` / `DEBUG` | 基础运行参数 | 可选 | `INFO` / `production` | ConfigMap | `tgo-plugin-runtime` |

#### C.2.8 tgo-device-control

| 配置项 | 作用 | 是否必填 | 示例值 / 推断值 | 建议存放 | 组件 |
| --- | --- | --- | --- | --- | --- |
| `DATABASE_URL` | Device Control 数据库连接 | 必填 | `postgresql+asyncpg://...` | Secret | `tgo-device-control` |
| `REDIS_URL` | Redis 连接 | 必填 | `redis://redis:6379/3` | Secret | `tgo-device-control` |
| `SECRET_KEY` | JWT 校验密钥，需与 `tgo-api` 对齐 | 必填 | 同 API Secret | Secret | `tgo-device-control` |
| `API_SERVICE_URL` | `tgo-api` 地址 | 必填 | `http://tgo-api:8000` | ConfigMap | `tgo-device-control` |
| `AI_SERVICE_URL` | `tgo-ai` 地址 | 按功能决定 | `http://tgo-ai:8081` | ConfigMap | `tgo-device-control` |
| `STORAGE_TYPE` | 截图存储类型 | 建议必填 | `local` / `s3` / `minio` | ConfigMap | `tgo-device-control` |
| `STORAGE_LOCAL_PATH` | 截图本地目录 | `local` 时必填 | `/var/lib/tgo/device-control/screenshots` | ConfigMap + PVC | `tgo-device-control` |
| `STORAGE_S3_BUCKET` / `STORAGE_S3_ENDPOINT` / `STORAGE_S3_ACCESS_KEY` / `STORAGE_S3_SECRET_KEY` | S3 兼容存储配置 | `s3` / `minio` 时必填 | 业务对象存储地址 | Secret（Endpoint 可放 ConfigMap） | `tgo-device-control` |
| `TCP_RPC_HOST` / `TCP_RPC_PORT` | 设备 TCP JSON-RPC 监听地址 | 启用 Peekaboo 类设备时必填 | `0.0.0.0:9876` | ConfigMap | `tgo-device-control` |
| `AGENTOS_ENABLED` / `AGENTOS_HOST` / `AGENTOS_PORT` | AgentOS 开关与监听端口 | 启用 Computer Use Agent 时必填 | `true`, `0.0.0.0`, `7778` | ConfigMap | `tgo-device-control` |
| `PLANNING_MODEL` / `GROUNDING_MODEL` / `OPENAI_API_KEY` / `OPENAI_BASE_URL` | AgentOS 模型推理配置 | 启用 AgentOS 时必填 | `.env.example` 有样例 | Secret / ConfigMap | `tgo-device-control` |

#### C.2.9 前端：tgo-web / tgo-widget-js

| 配置项 | 作用 | 是否必填 | 示例值 / 推断值 | 建议存放 | 组件 |
| --- | --- | --- | --- | --- | --- |
| `VITE_API_BASE_URL` | 前端调用 API 的基地址 | 必填 | `/api` 或 `https://api.example.com` | ConfigMap | `tgo-web`, `tgo-widget-js` |
| `VITE_DEBUG_MODE` | Web 调试开关 | 可选 | `false` | ConfigMap | `tgo-web` |
| `VITE_WIDGET_PREVIEW_URL` | 管理后台内 widget 预览地址 | 可选 | `/widget/` | ConfigMap | `tgo-web` |
| `VITE_WIDGET_SCRIPT_BASE` | Widget SDK 地址 | 可选 | `/widget/tgo-widget-sdk.js` | ConfigMap | `tgo-web` |
| `VITE_WIDGET_DEMO_URL` | Widget Demo 地址 | 可选 | `/widget/demo.html` | ConfigMap | `tgo-web` |
| `VITE_DISABLE_WEBSOCKET_AUTO_CONNECT` | 是否关闭自动 WS 连接 | 可选 | `false` | ConfigMap | `tgo-web` |
| `VITE_STORE_API_URL` | Store API 前端访问地址 | 可选 | `/store-api/api/v1` | ConfigMap | `tgo-web` |

### C.3 已确认的配置坑位

1. **已确认：`tgo-widget-js` 的变量名不一致。**  
   [`repos/tgo-widget-js/.env.example`](E:/go/src/github/tgo/repos/tgo-widget-js/.env.example) 使用 `VITE_API_BASE`，但 [`repos/tgo-widget-js/docker-entrypoint.sh`](E:/go/src/github/tgo/repos/tgo-widget-js/docker-entrypoint.sh) 以及实际运行时注入使用 `VITE_API_BASE_URL`。  
   影响：如果沿用 `.env.example`，容器在 K8s 中可能拿不到正确 API 地址。

2. **已确认：`tgo-workflow` 的端口说明不一致。**  
   根级 [`AGENTS.md`](E:/go/src/github/tgo/AGENTS.md) 表格中写的是 `8004`，但 [`docker-compose.yml`](E:/go/src/github/tgo/docker-compose.yml)、[`repos/tgo-workflow/Dockerfile`](E:/go/src/github/tgo/repos/tgo-workflow/Dockerfile)、[`repos/tgo-workflow/app/main.py`](E:/go/src/github/tgo/repos/tgo-workflow/app/main.py) 实际都以 `8000` 为准。  
   影响：K8s Service/Probe/NetworkPolicy 应以 `8000` 为准。

3. **已确认：部分服务配置名大小写混用。**  
   例如 `tgo-ai` / `tgo-platform` / `tgo-workflow` 使用 Pydantic Settings，既有大写示例，也有小写字段；K8s 中应尽量统一使用仓库现有 compose 所采用的大写变量名，避免运维侧混淆。

## D. Dockerfile 现状

### D.1 可运行组件的容器化状态

| 组件 | 是否已有 Dockerfile | 现状判断 | 启动命令 / 端口 | 生产可用性判断 | 证据 |
| --- | --- | --- | --- | --- | --- |
| `tgo-api` | 有 | 多阶段构建，Python 3.11 slim | `uvicorn app.main:app --port 8000` 与 `uvicorn app.internal:internal_app --port 8001` 同容器启动；暴露 `8000/8001` | 基本可用于生产，但双进程单容器需要在 K8s 里额外注意探针和资源隔离 | [`repos/tgo-api/Dockerfile`](E:/go/src/github/tgo/repos/tgo-api/Dockerfile) |
| `tgo-ai` | 有 | 多阶段构建 | `uvicorn app.main:app --port 8081`；暴露 `8081` | 可直接作为基础生产镜像 | [`repos/tgo-ai/Dockerfile`](E:/go/src/github/tgo/repos/tgo-ai/Dockerfile) |
| `tgo-rag` | 有 | 多阶段构建，分离浏览器缓存层 | `uvicorn src.rag_service.main:app --port 8082 --workers 4`；暴露 `8082` | 可用于生产，但镜像重、运行依赖多、冷启动慢 | [`repos/tgo-rag/Dockerfile`](E:/go/src/github/tgo/repos/tgo-rag/Dockerfile) |
| `tgo-platform` | 有 | 多阶段构建 | `uvicorn app.main:app --port 8003`；暴露 `8003` | 可直接复用 | [`repos/tgo-platform/Dockerfile`](E:/go/src/github/tgo/repos/tgo-platform/Dockerfile) |
| `tgo-workflow` | 有 | 多阶段构建 | `uvicorn app.main:app --port 8000`；暴露 `8000` | 可直接复用 | [`repos/tgo-workflow/Dockerfile`](E:/go/src/github/tgo/repos/tgo-workflow/Dockerfile) |
| `tgo-plugin-runtime` | 有 | 多阶段构建，运行时内置 Node.js / Go / build-essential | `uvicorn app.main:app --port 8090`；暴露 `8090` 与 `8005` | 可运行，但更像“带构建能力的 runtime”，生产安全边界和多副本策略要谨慎 | [`repos/tgo-plugin-runtime/Dockerfile`](E:/go/src/github/tgo/repos/tgo-plugin-runtime/Dockerfile) |
| `tgo-device-control` | 有 | 多阶段构建 | `uvicorn app.main:app --port 8085`；暴露 `8085` | 可直接复用，若启用 TCP/AgentOS 还需补充额外 Service 暴露策略 | [`repos/tgo-device-control/Dockerfile`](E:/go/src/github/tgo/repos/tgo-device-control/Dockerfile) |
| `tgo-device-control` AgentOS | 有单独 Dockerfile | 单独运行 AgentOS 进程，暴露 `7778` | `python -m app.agent_os`；暴露 `7778` | 可选镜像，不在默认 compose 主链路内 | [`repos/tgo-device-control/Dockerfile.agentos`](E:/go/src/github/tgo/repos/tgo-device-control/Dockerfile.agentos) |
| `tgo-web` | 有 | Node build + Nginx runtime | Nginx 80；entrypoint 运行时生成 `env-config.js` | 可直接用于生产，适合 K8s + Ingress | [`repos/tgo-web/Dockerfile`](E:/go/src/github/tgo/repos/tgo-web/Dockerfile) |
| `tgo-widget-js` | 有 | Node build + Nginx runtime | Nginx 80；entrypoint 运行时生成 `env-config.js` | 可直接用于生产，但运行时变量名问题需先校正 | [`repos/tgo-widget-js/Dockerfile`](E:/go/src/github/tgo/repos/tgo-widget-js/Dockerfile) |
| `tgo-device-agent` | 有 | Go 二进制多阶段构建 | `ENTRYPOINT ["tgo-device-agent"]` | 适合边缘/设备，不属于集群主链路 | [`repos/tgo-device-agent/Dockerfile`](E:/go/src/github/tgo/repos/tgo-device-agent/Dockerfile) |
| `website` | 有 | Next.js 多阶段构建 | `node server.js`；暴露 `3000` | 不属于主业务部署链路 | [`website/Dockerfile`](E:/go/src/github/tgo/website/Dockerfile) |

### D.2 需要特别注意的镜像特征

1. `tgo-api` 单容器同时运行 2 个 uvicorn 进程。  
   K8s 中如继续沿用现状，建议：
   - 同一个 Pod 暴露两个端口
   - readiness / liveness 同时覆盖 `8000` 与 `8001`
   - 通过 ClusterIP Service 控制 `8001` 仅集群内可达

2. `tgo-rag` 生产镜像依赖较重。  
   已确认依赖包括：
   - `libreoffice-core`
   - `libmagic1`
   - Playwright/Chromium 运行时依赖
   - NLTK 数据下载  
   影响：镜像构建慢、镜像体积大、调度时对节点磁盘和网络缓存更敏感。

3. `tgo-plugin-runtime` 并非纯 API 容器。  
   运行时包含：
   - Node.js 20
   - Go 1.22.5
   - `build-essential`
   - `python3-venv`  
   这说明插件运行时具备“拉代码、构建、执行”的能力，生产上需要单独考虑：
   - 镜像攻击面
   - 资源配额
   - 插件目录持久化
   - 是否允许多副本共享状态

4. `tgo-web` 与 `tgo-widget-js` 都采用“构建时打包 + 启动时注入运行时环境变量”的模式。  
   这很适合 K8s，因为域名/API 变更不需要重建镜像，只需更新 Deployment 环境变量。

### D.3 缺失项

- **已确认**：仓库当前无 Helm Chart。
- **已确认**：仓库当前无正式仓库级 K8s manifests。
- **已确认**：仓库当前无统一 migration image / migration Job 模板。
- **已确认**：虽然有 [`repos/tgo-rag/docs/deployment-guide.md`](E:/go/src/github/tgo/repos/tgo-rag/docs/deployment-guide.md)，但它是参考性文档，不等价于现成可执行的 K8s 资产。

### D.4 CI/CD 构建链路交叉校验

- **已确认**：GitHub Actions 会自动发现 `repos/*/Dockerfile` 并构建对应镜像。证据见 [`E:/go/src/github/tgo/.github/workflows/build-and-push.yml`](E:/go/src/github/tgo/.github/workflows/build-and-push.yml)。
- **已确认**：当前工作流默认跳过 `tgo-rag` 的自动发现，需要手动指定或通过专门 tag 触发，因为该镜像构建耗时较长。
- **已确认**：构建目标平台包含 `linux/amd64` 与 `linux/arm64`。
- **已确认**：面向 Kubernetes 主链路的核心应用组件目前都已有 Dockerfile，因此第一阶段不需要额外“补核心服务 Dockerfile”；真正缺的是 K8s 资产和迁移编排。

## E. Kubernetes 部署落地清单

### E.1 建议的前置部署顺序

1. 先准备基础设施。  
   PostgreSQL/pgvector、Redis、WuKongIM、对象存储、域名与 TLS、Ingress Controller。

2. 再执行数据库迁移。  
   证据：[`tgo.sh`](E:/go/src/github/tgo/tgo.sh) 的 `run_all_migrations` 会按如下顺序执行：
   - `tgo-rag`
   - `tgo-ai`
   - `tgo-api`
   - `tgo-platform`
   - `tgo-workflow`
   - `tgo-plugin-runtime`
   - `tgo-device-control`

3. 再启动核心后端。  
   `tgo-rag`、`tgo-ai`、`tgo-plugin-runtime`、`tgo-platform`、`tgo-workflow`、`tgo-device-control`、`tgo-api`

4. 再启动异步 worker / beat。  
   `tgo-rag-worker`、`tgo-rag-beat`、`tgo-workflow-worker`

5. 最后启动前端和公网入口。  
   `tgo-web`、`tgo-widget-js`、Ingress

### E.2 组件级 K8s 资源建议

| 组件 | 建议资源类型 | 是否需持久化 | 是否需 Service | 是否需 Ingress | Secret / ConfigMap | 探针建议 | 多副本建议 | 启动顺序依赖 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `tgo-api` | Deployment | 上传走本地盘时需要 PVC，否则可无 | 需要，建议同一 Service 暴露 `8000` 与内部 `8001` | 需要，暴露 `8000` | 两者都需要 | `8000/health` 与 `8001/health` | 可以多副本，但要确认内部无本地状态 | 依赖 DB、Redis、WuKongIM、下游服务 |
| `tgo-ai` | Deployment | `skills_base_dir` 建议 PVC | 需要 | 一般不直接 Ingress，仅集群内 | 两者都需要 | `/health` | 可多副本，但技能同步和后台任务需压测验证 | 依赖 DB、RAG、API |
| `tgo-rag` | Deployment | `UPLOAD_DIR` 建议 PVC | 需要 | 一般不直接 Ingress，仅集群内 | 两者都需要 | `/health` | API 可多副本，前提是上传目录或对象存储一致 | 依赖 DB、Redis、Embedding 提供商 |
| `tgo-rag-worker` | Deployment | 与 `tgo-rag` 共享上传存储 | 不需要 | 不需要 | 两者都需要 | 命令型 worker 可做进程探针 | 可多副本 | 依赖 DB、Redis、`tgo-rag` |
| `tgo-rag-beat` | Deployment | 通常不需要 | 不需要 | 不需要 | 两者都需要 | 进程探针即可 | 建议单副本，避免重复调度 | 依赖 DB、Redis、`tgo-rag` |
| `tgo-platform` | Deployment | 否 | 需要 | 一般不直接 Ingress，仅集群内 | 两者都需要 | `/health` | 可多副本 | 依赖 DB、`tgo-api` |
| `tgo-workflow` | Deployment | 否 | 需要 | 一般不直接 Ingress，仅集群内 | 两者都需要 | `/health` | 可多副本 | 依赖 DB、Redis、`tgo-ai` |
| `tgo-workflow-worker` | Deployment | 否 | 不需要 | 不需要 | 两者都需要 | 进程探针即可 | 可多副本，视队列吞吐量 | 依赖 DB、Redis、`tgo-workflow` |
| `tgo-plugin-runtime` | Deployment | 建议 PVC 或至少 EmptyDir | 需要 | 一般不直接 Ingress，仅集群内 | 两者都需要 | `/health` | 初期建议单副本 | 依赖 DB、`tgo-ai` |
| `tgo-device-control` | Deployment | 截图目录建议 PVC | 需要；若启用 TCP/AgentOS 需额外 Service | 默认不需要公网 Ingress；设备接入时按协议决定 | 两者都需要 | `/health` | 初期建议单副本 | 依赖 DB、Redis、`tgo-ai`、`tgo-api` |
| `tgo-web` | Deployment | 否 | 需要 | 需要 | ConfigMap 即可 | `/` | 可多副本 | 依赖 `tgo-api` 对外可达 |
| `tgo-widget-js` | Deployment | 否 | 需要 | 需要 | ConfigMap 即可 | `/` | 可多副本 | 依赖 `tgo-api` 对外可达 |
| PostgreSQL | 外部服务优先；若自建则 StatefulSet | 需要 PVC | 需要 | 不需要 | Secret + ConfigMap | TCP/SQL 探针 | 单主起步 | 最前置 |
| Redis | 外部服务优先；若自建则 StatefulSet / Operator | 需要 PVC | 需要 | 不需要 | Secret + ConfigMap | `PING` | 先单实例或托管版 | 最前置 |
| WuKongIM | 若自建可用 StatefulSet 或 Deployment + PVC | 建议 PVC | 需要，多端口 | 通常不走标准 HTTP Ingress 单独解决全部协议 | ConfigMap 为主 | 健康探针需按实际端口设计 | 初期建议单副本 | 最前置 |

### E.3 两套落地口径

#### 方案一：应用上集群，中间件沿用现有外部/托管基础设施

这是当前更推荐的落地方式。

优点：

- 落地快
- 风险小
- 便于先验证应用编排是否正确
- PostgreSQL / Redis / 对象存储 / TLS 可直接复用你现有集群外能力

至少需要准备的 K8s 对象：

- `Namespace`
- 每个应用组件的 `Deployment`
- 每个应用组件的 `Service`
- 对公网组件的 `Ingress`
- 按组件拆分的 `ConfigMap`
- 按组件拆分的 `Secret`
- RAG / AI / Device / Plugin 相关 `PersistentVolumeClaim`
- 数据库迁移 `Job`
- 可选 `HPA`
- 可选 `NetworkPolicy`

#### 方案二：应用和中间件都纳入集群部署

可做，但明显更重。

额外复杂点：

- PostgreSQL 需要备份、扩容、升级与 `pgvector` 扩展管理
- Redis 需要高可用策略或 Operator
- WuKongIM 需要多协议端口暴露与插件目录管理
- 证书和域名边缘层要从根级 `nginx + certbot` 映射到 Ingress + cert-manager

### E.4 建议优先准备的 YAML

建议最先准备以下对象清单：

1. `postgres-external`、`redis-external`、`wukongim-external` 的连接 Secret/ConfigMap  
   如果你已有外部基础设施，这一步是最低成本路径。

2. 数据库迁移 Jobs  
   至少为以下镜像准备可重复执行的 Job：
   - `tgo-rag`
   - `tgo-ai`
   - `tgo-api`
   - `tgo-platform`
   - `tgo-workflow`
   - `tgo-plugin-runtime`
   - `tgo-device-control`

3. 核心后端 Deployments / Services  
   最小闭环通常是：
   - `tgo-api`
   - `tgo-ai`
   - `tgo-rag`
   - `tgo-rag-worker`
   - `tgo-rag-beat`
   - `tgo-web` 或 `tgo-widget-js`

4. 条件性组件  
   仅在需要对应功能时再补：
   - `tgo-platform`
   - `tgo-workflow`
   - `tgo-workflow-worker`
   - `tgo-plugin-runtime`
   - `tgo-device-control`
   - `tgo-celery-flower`

### E.5 不建议直接照搬到 K8s 的 compose 组件

| compose 组件 | 原因 | K8s 替代建议 |
| --- | --- | --- |
| `nginx` | 根级反向代理逻辑与 K8s Ingress 职责重叠 | 使用现有 Ingress Controller |
| `certbot` | 证书生命周期应交给集群证书体系 | 使用 cert-manager 或已有证书平台 |
| `tgo-celery-flower` | 运维辅助组件，不是主业务链路必需 | 后续按需补 |
| `adminer` / `redis-insight` / docs 站点 | 工具性质或非主链路 | 不纳入第一批生产工作负载 |

### E.6 可能卡住部署的点

1. **迁移不是随 `docker-compose up` 自动完成的。**  
   `tgo.sh` 明确要求先运行 Alembic 迁移，再启动全部服务。K8s 里必须单独设计 Job 或 init/migration 流程。

2. **`tgo-api` 内部 `8001` 端口是无鉴权内部端口。**  
   必须限制在集群内访问，不应通过公网 Ingress 暴露。

3. **WuKongIM 的暴露方式不只是一个 HTTP 端口。**  
   compose 里同时使用 TCP、WS、WSS、管理 API 和集群端口；在现有 K8s 集群里如何接入负载均衡，需要结合你的网络方案人工确认。

4. **RAG / Plugin / Device Control 都带本地目录语义。**  
   如果不换成对象存储或统一共享卷，多副本时容易出现状态不一致。

## F. 风险与不确定项

### F.1 已确认风险

1. **仓库没有现成 Helm / K8s 部署资产。**  
   这意味着落地时需要你们自己补全 Deployment、Service、Ingress、Job、ConfigMap、Secret 等 YAML。

2. **部署文档与代码存在不一致。**  
   已确认包括：
   - `tgo-widget-js` 的 `VITE_API_BASE` / `VITE_API_BASE_URL` 不一致
   - `tgo-workflow` 的端口文档与实际实现不一致

3. **部分组件的“是否必须部署”取决于业务功能，而不是仓库是否存在。**  
   例如 `tgo-platform`、`tgo-workflow`、`tgo-plugin-runtime`、`tgo-device-control` 都是条件性组件。

4. **RAG 镜像较重，插件运行时镜像权限面较大。**  
   这两类组件在生产集群中更需要资源配额、节点选择、镜像扫描与运行时安全策略。

### F.2 待确认项

| 项目 | 当前判断 | 原因 | 需要你人工确认什么 |
| --- | --- | --- | --- |
| Kafka 是否仍为实际依赖 | 待确认 | 配置和文档有残留，但主运行链路代码未证实 | 你的目标功能是否依赖历史异步消息链路 |
| `repos/tgo-rag/docs/deployment-guide.md` 中的 Weaviate / Pinecone | 待确认 | 文档提到但当前实现未体现 | 你是否计划改用外部向量库，而不是 pgvector |
| WuKongIM 是否必须纳入第一期集群部署 | 倾向需要 | 当前实时消息链路明显依赖 IM | 你的现有集群是否已有等价 IM 能力，或可先直连外部 WuKongIM |
| `tgo-device-control` 是否需要部署 | 取决于设备场景 | 仅设备控制链路使用 | 你是否需要截图、设备接管、Computer Use Agent |
| `tgo-plugin-runtime` 是否需要部署 | 取决于插件/MCP 场景 | 不是所有客服部署都需要插件系统 | 你是否需要插件执行、工具同步、MCP runtime |
| `tgo-platform` / `tgo-workflow` 是否需要部署 | 取决于渠道与流程需求 | 非最小聊天闭环强制项 | 你是否需要外部渠道同步、流程编排 |
| 根级 `nginx` / `certbot` 是否保留 | 不建议直接保留 | K8s 一般已有入口层 | 你的现有集群 Ingress / TLS 体系是什么 |

### F.3 最终交付建议

如果你的目标是“尽快在已有 Kubernetes 集群里跑起来”，建议按下面顺序推进：

1. 先确认第一期只上哪些业务组件。  
   最小建议：`tgo-api`、`tgo-ai`、`tgo-rag`、`tgo-rag-worker`、`tgo-rag-beat`、`tgo-web`/`tgo-widget-js`。

2. 明确基础设施来源。  
   PostgreSQL、Redis、对象存储、WuKongIM 是用现有外部服务，还是也要放进集群。

3. 先补迁移 Job 与应用 YAML，再考虑完整运维增强项。  
   第一批不必急着上 HPA、Flower、AgentOS、根级 nginx/certbot 兼容层。

4. 把本文档作为后续编写 Helm/Kustomize 的输入清单。  
   当前仓库信息已经足够支撑第一版 Kubernetes 资产设计，但仍需你对“哪些条件性组件要上线”做业务确认。
