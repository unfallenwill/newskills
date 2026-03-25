# ruff-auto-format

在修改 Python 文件后自动执行 ruff format 和 ruff check --fix。

## 工作原理

通过 `PostToolUse` Hook 监听 `Write` 和 `Edit` 工具调用，当被修改的文件是 `.py` 文件时，自动执行：

1. `poetry run ruff format <file>` — 格式化代码
2. `poetry run ruff check --fix <file>` — 检查并自动修复 lint 问题

## 安装

```bash
/plugin marketplace add ./.
/plugin install ruff-auto-format@newstar
```

## 前置要求

- 项目使用 [Poetry](https://python-poetry.org/) 管理
- 项目依赖中包含 [ruff](https://docs.astral.sh/ruff/)

## 配置

默认直接使用 `poetry run ruff`，如需自定义 ruff 路径，编辑 `hooks/hooks.json` 中的 command 字段。
