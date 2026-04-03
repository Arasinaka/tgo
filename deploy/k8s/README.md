# TGO Kubernetes 骨架

这是一套基于 [`docs/deployment-audit.md`](E:/go/src/github/tgo/docs/deployment-audit.md) 生成的 Kubernetes 落地骨架，目标是给“现有集群 + 外部依赖”方案提供一个可继续细化的起点。

## 目录说明

- `base/namespace.yaml`
  - 默认命名空间 `tgo`
- `base/externals/*.example.yaml`
  - 外部依赖 Secret / ConfigMap 模板
- `base/migrations/*.yaml`
  - 7 个服务的 Alembic migration Job 模板
- `base/apps/*`
  - 核心服务的 Deployment / Service / Ingress 模板
  - 同时包含少量按组件拆分的 `*.example.yaml` 配置模板

## 当前覆盖范围

已覆盖核心工作负载：

- `tgo-api`
- `tgo-ai`
- `tgo-rag`
- `tgo-rag-worker`
- `tgo-rag-beat`
- `tgo-web`
- `tgo-widget-js`

已覆盖迁移 Job：

- `tgo-rag`
- `tgo-ai`
- `tgo-api`
- `tgo-platform`
- `tgo-workflow`
- `tgo-plugin-runtime`
- `tgo-device-control`

## 使用方式

1. 先复制并修改 `base/externals/*.example.yaml`
2. 再复制并修改各组件目录下的 `configmap.example.yaml` / `secret.example.yaml`
3. 先执行 migration Jobs
4. 再部署 `base/apps/` 中的核心工作负载

说明：

- 所有 `*.example.yaml` 默认只是模板，不在 `kustomization.yaml` 的 `resources` 里。
- 建议复制为不带 `.example` 后缀的正式文件，再按你的集群实际情况接入 Kustomize / Helm / GitOps 流程。

## 重要说明

- 这些 YAML 是“面向当前仓库”的模板骨架，不是最终生产清单。
- 所有 `REPLACE_ME` / `example.com` / 示例密钥都需要替换。
- `tgo-api` 的 `8001` 是内部无鉴权端口，只应在集群内使用。
- 当前骨架优先假设 PostgreSQL、Redis、WuKongIM、对象存储由外部或独立集群能力提供。
