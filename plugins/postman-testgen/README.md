# postman-testgen

为 API 自动生成 Postman v2.1.0 格式的测试用例集合，支持三层验证：HTTP 响应断言、VictoriaTraces 调用链验证、VictoriaLogs 业务日志验证。

## 三层验证模型

每个 API 测试用例包含三层断言，按顺序执行：

### 1. HTTP 层 — 功能正确性
- 断言 HTTP 状态码
- 断言响应体结构和字段值
- 提取变量传递给下游请求

### 2. Trace 层 — 调用链结构
- 查询 VictoriaTraces (Jaeger API)
- 断言 span 层级完整性（API → Service → Repository）
- 断言关键 attribute 存在性
- 断言无异常 span（status = OK）

### 3. Log 层 — 业务行为语义
- 查询 VictoriaLogs (LogsQL)
- 断言事件名存在性（如 `order.created`）
- 断言 extra 字段完整性（如 `order_id`、`status`）
- 断言 severity 正确性（正常流程 INFO，not_found WARNING）

## 组件

| 组件 | 名称 | 用途 |
|------|------|------|
| Agent | `postman-testgen` | 分析 API、生成集合、编排依赖、执行验证 |
| Skill | `postman-schema` | Postman v2.1.0 Collection 格式规范 |
| Skill | `http-assertion` | HTTP 响应断言模板 |
| Skill | `trace-assertion` | VictoriaTraces 调用链断言模板 |
| Skill | `log-assertion` | VictoriaLogs 业务日志断言模板 |

## 使用方式

### 生成测试用例

```
# 从 OpenAPI 规范生成
帮我根据 openapi.yaml 生成 Postman 测试集合

# 从代码分析生成
分析这个项目的 API 路由，生成测试用例

# 从描述生成
为用户注册和登录 API 生成测试，需要验证调用链和日志
```

### 运行测试

```
# 运行已生成的集合
运行刚生成的测试集合

# 修复后重跑
测试有失败的，帮我分析修复
```

## 输出结构

生成的文件位于项目 `postman/` 目录：

```
postman/
├── collections/
│   └── <name>.postman_collection.json   # 生成的测试集合
├── environments/
│   └── dev.json                          # 环境配置（baseUrl, vtUrl, vlUrl）
└── results/
    └── <name>-results.json               # Newman 执行结果
```

### 环境变量

| 变量 | 说明 | 示例 |
|------|------|------|
| `baseUrl` | 目标 API 地址 | `http://localhost:8080` |
| `vtUrl` | VictoriaTraces 地址 | `http://localhost:10428` |
| `vlUrl` | VictoriaLogs 地址 | `http://localhost:9428` |

## 依赖

- [Newman](https://github.com/postmanlabs/newman) — 通过 `npx -y newman` 自动使用
- [VictoriaTraces](https://docs.victoriametrics.com/victoriatraces/) — 调用链数据源
- [VictoriaLogs](https://docs.victoriametrics.com/victorialogs/) — 日志数据源
