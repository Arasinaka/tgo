# TGO Plugin Runtime AGENTS Guide

> 适用范围：`repos/tgo-plugin-runtime`  
> 最近校准：2026-03-05（按当前代码与配置扫描）

## 1. 服务定位

`tgo-plugin-runtime` 负责插件安装、进程托管、插件通信与工具同步。

- HTTP 入口：`app/main.py`
- API 路由：`app/api/routes.py`
- 默认端口：`8090`
- 通信：Unix Socket（默认）或 TCP 端口（可选）

---

## 2. 关键目录

```text
app/
├── api/routes.py               # 插件列表/渲染/事件/安装/生命周期
├── services/
│   ├── plugin_manager.py       # 在线插件注册与请求分发
│   ├── process_manager.py      # 插件进程管理
│   ├── socket_server.py        # 插件通信通道
│   ├── installer.py            # 安装/升级
│   └── tool_sync.py            # 与 tgo-ai 的工具同步
├── models/                     # 已安装插件模型
├── schemas/                    # API schema
├── core/database.py
├── config.py
└── main.py
```

---

## 3. 强约束规范

### 3.1 插件生命周期

- 启动/停止/重启流程必须通过 `process_manager` 统一处理。
- 禁止直接绕过 manager 操作子进程。

### 3.2 通信与超时

- 插件请求走统一 socket/request 流程，保持超时与错误语义一致。
- 不得在 API 层直接拼接低层 socket 协议。

### 3.3 多租户边界

- 插件查询和操作需保留 `project_id` 过滤逻辑。
- 禁止把项目私有插件暴露给全局请求。

### 3.4 迁移与配置

- `models` 调整必须附带 Alembic 迁移。
- Socket 路径、TCP 端口、AI 服务地址等通过配置注入。

---

## 4. 高频改动入口

- 插件 API：`app/api/routes.py`
- 进程托管：`app/services/process_manager.py`
- 请求分发：`app/services/plugin_manager.py`
- 安装/升级：`app/services/installer.py`
- 工具同步：`app/services/tool_sync.py`

---

## 5. 本地开发命令

```bash
# 依赖
poetry install

# 迁移
poetry run alembic upgrade head

# 启动
poetry run uvicorn app.main:app --host 0.0.0.0 --port 8090 --reload

# 质量检查（若无测试用例，至少保证服务可启动）
poetry run pytest
poetry run black app
poetry run isort app
```

---

## 6. AI 代理改动流程

1. 先确定改动在 API、进程管理、安装器还是通信层。
2. 涉及插件状态机改动时，先保证状态迁移可回滚。
3. 涉及 `project_id` 的改动，优先做权限边界检查。
4. 提交前至少验证安装/启动/请求/停止基本链路。

---

## 7. 变更自检清单

- 是否引入插件进程僵尸或泄漏？
- 是否破坏项目级插件隔离？
- 是否绕过统一 socket/timeout 逻辑？
- 是否遗漏迁移与配置更新？
