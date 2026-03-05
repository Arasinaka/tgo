# TGO Device Control AGENTS Guide

> 适用范围：`repos/tgo-device-control`  
> 最近校准：2026-03-05（按当前代码与配置扫描）

## 1. 服务定位

`tgo-device-control` 负责设备接入、TCP JSON-RPC 会话管理与 MCP 透明代理。

- HTTP 入口：`app/main.py`（默认 `8085`）
- TCP RPC：默认 `9876`（设备侧 agent 长连接）
- MCP 透传端点：`POST /mcp/{device_id}`
- REST API：`/v1/devices/*`、`/v1/mcp/*`

---

## 2. 关键目录

```text
app/
├── services/
│   ├── tcp_connection_manager.py   # 连接生命周期与在线设备
│   ├── tcp_rpc_server.py           # TCP JSON-RPC 服务
│   ├── mcp_server.py               # MCP 透明代理
│   ├── bind_code_service.py        # 绑定码（Redis）
│   └── device_service.py           # 设备持久化服务
├── api/v1/                         # devices/mcp REST 接口
├── schemas/                        # device/tcp_rpc/mcp
├── models/
├── config.py
└── main.py
```

---

## 3. 强约束规范

### 3.1 协议兼容性

- TCP JSON-RPC 消息结构必须向后兼容设备侧 `tgo-device-agent`。
- MCP 透传逻辑不可篡改上游工具调用语义。

### 3.2 连接与资源管理

- 设备连接生命周期必须经 `tcp_connection_manager` 统一管理。
- 关闭流程必须确保 TCP server 与连接管理器都能正确收敛。

### 3.3 安全与边界

- 鉴权、绑定码、设备 token 不可在日志中明文泄露。
- 禁止绕过 `device_id` 绑定关系访问非目标设备通道。

### 3.4 迁移与配置

- 模型结构变更必须附带 Alembic 迁移。
- 端口、Redis、DB、存储后端必须走配置，不硬编码。

---

## 4. 高频改动入口

- TCP 接入：`app/services/tcp_rpc_server.py`
- 连接管理：`app/services/tcp_connection_manager.py`
- MCP 代理：`app/services/mcp_server.py`
- 绑定码：`app/services/bind_code_service.py`
- 入口协议：`app/main.py`

---

## 5. 本地开发命令

```bash
# 依赖
poetry install

# 迁移
poetry run alembic upgrade head

# 启动
poetry run uvicorn app.main:app --host 0.0.0.0 --port 8085 --reload

# 质量检查（当前仓库无稳定 tests 目录）
poetry run pytest
poetry run black app
poetry run isort app
```

---

## 6. AI 代理改动流程

1. 先判定改动位于 HTTP API、TCP 协议层还是 MCP 代理层。
2. 协议字段变更时先审查设备端兼容性。
3. 连接状态与超时策略改动需验证断线重连链路。
4. 提交前至少验证：设备认证、tools/list、tools/call、MCP 透传。

---

## 7. 变更自检清单

- 是否破坏设备端协议兼容？
- 是否存在连接泄漏/关闭不完整？
- 是否放宽了 device_id 访问边界？
- 是否遗漏迁移或配置更新？
