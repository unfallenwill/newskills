# ruff-format

在修改 Python 文件后自动执行 ruff format 和 ruff check --fix。

## 工作原理

通过 `PostToolUse` Hook 监听 `Write` 和 `Edit` 工具调用，当被修改的文件是 `.py` 文件时，自动执行：

1. `ruff format <file>` — 格式化代码
2. `ruff check --fix <file>` — 检查并自动修复 lint 问题
3. `ruff check <file>` — 检查是否还有残留问题，有则反馈给 Claude 自动处理

## 判断链

```
文件后缀 != py            → 静默跳过
ruff 未安装               → 警告，不阻断工作流
ruff format + check --fix  → 静默修复
还有残留 lint 问题         → 反馈给 Claude 自动修复
```

## 跨平台支持

- Windows：通过 `cygpath` 自动转换路径格式，兼容原生 ruff 二进制
- macOS / Linux：原生支持

## 前置要求

- 安装 [ruff](https://docs.astral.sh/ruff/)（`pip install ruff`）
- 项目中建议配置 `pyproject.toml` 或 `ruff.toml`（未配置时使用 ruff 默认值）

## 已知限制

- 每次 Write/Edit 都会触发三次 ruff 调用（format + check --fix + check），重构场景下可能较慢
- ruff format 修改磁盘文件后，Claude 内部缓存与磁盘文件可能短暂不同步，后续操作前 Claude 会重新读取文件
