# treadonsnow-skills

Claude Code 插件集合，包含 Skills、Slash Commands、Hooks、Agents 等扩展。

## 插件列表

| 插件 | 类型 | 说明 |
|------|------|------|
| [ruff-format](plugins/ruff-format/) | Hook | 修改 Python 文件后自动执行 ruff format 和 ruff check --fix |
| [code-postman](plugins/code-postman/) | Agent + Skill | 从代码库逆向分析 API 并生成 Postman 测试集：正向、反向、边界、安全用例 |

## 安装

通过 Marketplace 安装（推荐）：

```bash
# 添加 Marketplace
/plugin marketplace add unfallenwill/treadonsnow-skills

# 安装插件
/plugin install ruff-format@treadonsnow-skills
/plugin install code-postman@treadonsnow-skills
```

## 插件结构

每个插件遵循标准结构：

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json      # 插件元数据（必需）
├── skills/              # 技能定义
├── commands/            # 斜杠命令（可选）
├── agents/              # 子代理定义（可选）
├── hooks/
│   └── hooks.json       # Hook 配置（可选）
├── scripts/             # 脚本文件（可选）
└── README.md            # 插件文档
```

## 开发新插件

1. 在 `plugins/` 下创建插件目录
2. 添加 `.claude-plugin/plugin.json`
3. 按需添加 skills、commands、hooks、agents 等组件
4. 更新 `.claude-plugin/marketplace.json` 中的插件条目
5. 更新仓库根目录 `README.md` 的插件列表

详见 [CLAUDE.md](CLAUDE.md)。
