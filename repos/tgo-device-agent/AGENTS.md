# TGO Device Agent AGENTS Guide

> 适用范围：`repos/tgo-device-agent`  
> 最近校准：2026-03-05（按当前代码与配置扫描）

## 1. 服务定位

`tgo-device-agent` 是运行在受管设备上的 Go Agent，通过 TCP JSON-RPC 2.0 连接 `tgo-device-control`，对上层 AI 暴露本地工具能力。

---

## 2. 关键架构

```text
cmd/agent/main.go             # CLI 入口
internal/config/              # 配置加载
internal/protocol/            # JSON-RPC 消息结构
internal/transport/client.go  # 连接、认证、心跳、重连
internal/tools/               # fs_read/fs_write/fs_edit/shell_exec
internal/sandbox/sandbox.go   # 路径与命令安全策略
```

---

## 3. 协议约束

- 协议文档：`../tgo-device-control/docs/json-rpc.md`
- 消息格式：换行分隔 JSON（`\n`-delimited JSON）
- 鉴权方法：`auth`（`bindCode` 首次注册，`deviceToken` 后续重连）
- 常见交互：
  - 服务端下发：`tools/list`、`tools/call`、`ping`
  - 设备侧响应：工具列表、工具调用结果、`pong`

---

## 4. 强约束规范

### 4.1 类型与依赖

- 当前实现仅使用 Go 标准库。
- 协议消息优先使用明确 struct，避免无边界 `interface{}` 扩散（工具参数动态 schema 例外）。

### 4.2 工具扩展

新增工具必须实现 `Tool` 接口并注册到 `Registry`：

```go
type Tool interface {
    Name() string
    Definition() protocol.ToolDefinition
    Execute(ctx context.Context, args map[string]interface{}) *protocol.ToolCallResult
}
```

### 4.3 安全

- 所有文件与命令操作必须经过 `internal/sandbox` 校验。
- 禁止绕过 `work_root`/allowed paths 直接访问系统路径。
- 禁止弱化危险命令拦截、输出截断与超时限制。

### 4.4 连接可靠性

- 保持断线重连与心跳机制的幂等性。
- 涉及 token 持久化的改动必须向后兼容旧 token 文件。

---

## 5. 本地开发命令

```bash
# 构建
make build

# 代码检查
make vet

# 测试
make test

# 运行示例
make run
```

---

## 6. AI 代理改动流程

1. 先确认改动属于 `protocol`、`transport`、`tools` 或 `sandbox` 哪一层。
2. 协议字段变更时，先改 `protocol` 再改调用链，避免隐式解码失败。
3. 工具行为变更时，必须复查 sandbox 规则。
4. 提交前至少执行 `make vet && make test`（或说明未执行原因）。

---

## 7. 变更自检清单

- 是否破坏了现有 JSON-RPC 字段兼容性？
- 是否引入潜在路径逃逸或命令注入风险？
- 是否影响重连/心跳但未覆盖断线场景？
- 是否在工具返回中泄露敏感信息？
