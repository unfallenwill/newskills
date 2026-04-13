---
name: spec-deliverer
description: >
  内部步骤（Task 6），由 spec-generator 编排器调用，不从用户直接触发。
  将审查通过的规格文档以用户指定的格式和位置交付。
context: fork
allowed-tools:
  - Read
  - Write
  - Bash
  - Skill
  - AskUserQuestion
---

# 步骤 6：输出交付

将最终规格文档写入用户指定的输出格式和位置。

## 输入输出

- **输入**: `$ARGUMENTS/` 目录下的所有文件（prd-source.md、prd-analysis.md、codebase-mapping.md、{feature-name}-spec.md、review-report.md、tasks.md）
- **输出**: 最终 spec 文件（用户指定位置）+ 可选飞书文档

## 执行流程和规范

### 读取输入

1. 使用 Read 工具读取 `$ARGUMENTS/prd-source.md`，从元数据头中提取 `feature-name`
2. 使用 Read 工具读取 `$ARGUMENTS/tasks.md`，确认步骤 1-5 状态均为 completed
3. 使用 Read 工具读取 `$ARGUMENTS/review-report.md`，确认审查结论为 PASS 或 PASS_WITH_NOTES
4. 使用 Read 工具读取 `$ARGUMENTS/{feature-name}-spec.md`，获取最终的规格文档内容

### 确认输出格式

根据用户偏好确定输出方式：

1. **Markdown 文件**（默认）— 写入项目根目录的 `specs/<功能名>-spec.md`
2. **飞书文档** — 使用 `lark-doc` skill 创建或更新飞书文档
3. **两者都要** — 同时输出到本地文件和飞书

如果用户未指定，默认为 Markdown 文件，在交付确认检查点中向用户确认默认选择。

### 输出前检查

在写入之前执行最终检查：

1. **tasks.md 状态** — 确认步骤 1-5 状态均为 completed
2. **spec 文件存在** — 确认 `$ARGUMENTS/{feature-name}-spec.md` 存在且可读
3. **审查已通过** — 确认 review-report.md 中的审查结论为 PASS 或 PASS_WITH_NOTES

### Markdown 文件输出

1. 确认输出路径（默认 `specs/<功能名>-spec.md`）
2. 如果 specs/ 目录不存在，使用 Bash 创建它
3. 将 `$ARGUMENTS/{feature-name}-spec.md` 的内容复制到最终输出路径
4. 使用 Read 工具读取输出文件，验证写入成功

### 飞书文档输出

1. 使用 `lark-doc` skill 将 spec 内容写入飞书文档
2. 如果 `lark-doc` skill 不可用，向用户报告并建议改用 Markdown 文件输出
3. 返回文档 URL 给用户

### 交付确认

向用户展示：
- 输出文件路径或飞书文档 URL
- 工作目录路径（`$ARGUMENTS`，包含所有中间产出物）
- spec 文档的简要摘要（功能数量、任务数量、关键约束）
- 提示用户可以将此 spec 交给 coding agent 执行
