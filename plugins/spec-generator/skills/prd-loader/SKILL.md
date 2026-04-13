---
name: prd-loader
description: >
  内部步骤（Task 1），由 spec-generator 编排器调用，不从用户直接触发。
  判断 PRD 输入来源（文件路径、飞书 URL、内联文本）并加载内容到工作目录。
context: fork
allowed-tools:
  - Read
  - Write
  - Skill
  - AskUserQuestion
---

# 步骤 1：加载 PRD 内容

判断输入来源并加载 PRD 原始内容，写入工作目录文件。

## 输入输出

- **输入**: `$ARGUMENTS/.input.md`（由编排器写入的 PRD 来源配置文件）
- **输出**: `$ARGUMENTS/prd-source.md`

## 执行流程和规范

### 读取输入配置

使用 Read 工具读取 `$ARGUMENTS/.input.md`，获取编排器传入的 PRD 来源信息。该文件格式为：

```markdown
---
source-type: file-path | lark-url | inline-text
source-ref: <文件路径 | URL | inline>
feature-name: <功能名称>
---
<如果是内联文本，PRD 内容写在此处>
```

### 识别来源类型

根据 `.input.md` 中的 `source-type` 字段加载 PRD：

1. **本地文件路径**（`file-path`）
   - 使用 Read 工具读取 `source-ref` 指定的文件内容
   - 如果文件不存在，使用 AskUserQuestion 请求用户提供正确路径

2. **飞书文档 URL**（`lark-url`）— 匹配 `https://*.larkoffice.com/docx/*` 或 `https://*.feishu.cn/docx/*`
   - 如果 `lark-doc` skill 未安装，使用 AskUserQuestion 请求用户提供本地文件或内联文本
   - 使用 `lark-doc` skill 获取文档内容
   - 如果获取失败，使用 AskUserQuestion 请求替代来源

3. **内联文本**（`inline-text`）
   - 直接使用 `.input.md` frontmatter 之后的内容
   - 如果内容过短（少于 100 字符），使用 AskUserQuestion 确认用户是否提供了完整 PRD

### 加载验证

加载内容后执行基础验证：

1. **完整性检查** — 内容是否有明显截断（末尾不完整、段落中断）
2. **可读性检查** — 内容是否可解析（Markdown、纯文本、HTML 等格式是否可识别）
3. **最低内容检查** — 内容是否包含至少一个可识别的需求描述

### 写入产出

将加载的 PRD 内容写入 `$ARGUMENTS/prd-source.md`：

1. 在文件顶部添加元数据头（`feature-name` 从 `.input.md` 中获取）：

```markdown
---
source-type: <本地文件 | 飞书文档 | 内联文本>
source-ref: <文件路径或 URL，内联文本标注"内联">
loaded-at: <加载时间>
feature-name: <从 .input.md 获取>
---

<PRD 原始内容>
```

2. 使用 Write 工具写入文件
3. 使用 Read 工具回读文件，验证内容完整写入

### 异常处理

- 如果无法确定来源类型，使用 AskUserQuestion 请求用户澄清
- 如果内容加载失败，报告具体错误并建议替代方案
- 如果内容不完整，标记缺失部分并在后续 PRD 分析步骤中处理
