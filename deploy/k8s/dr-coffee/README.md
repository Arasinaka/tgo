# dr-coffee Production Manifests

这套清单是 `dr-coffee` 环境的正式 Kubernetes YAML，当前已调整为部署到 `dr-coffee-test` 命名空间，基于 `deploy/k8s/base` 骨架固化了真实域名、镜像仓库、外部依赖连接和密钥。

## 目录

- `namespace/`
- `secrets/`
- `externals/`
- `migrations/`
- `apps/`

## 发布顺序

1. `namespace`
2. `secrets` + `externals`
3. `migrations`
4. `apps`

## 固定值

- Namespace: `dr-coffee-test`
- Image registry: `dr-acr-registry.cn-hangzhou.cr.aliyuncs.com/dr-coffee`
- Image pull secret: `aliyun-registry-secret`
- API: `tgo-api.dr-coffee.cn`
- Admin: `tgo-admin.dr-coffee.cn`
- Widget: `tgo-widget.dr-coffee.cn`
- IM: 复用现有 `wkim-wukongim-local.wukongim.svc.cluster.local`

## 说明

- Ingress 只声明 `host` 和路由，不声明 cert-manager 注解或 TLS secret。
- PostgreSQL 与 Redis 使用阿里云外部实例。
- Redis 统一使用单实例 `DB0`。
- RAG 使用 `qwen3` Embedding。
- WuKongIM 不再由这套清单部署，直接复用 `wukongim` 命名空间下的现有 Service：`wkim-wukongim-local`。
