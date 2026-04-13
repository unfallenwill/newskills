---
name: spec-generator
description: >
  当用户要求 "生成规格文档", "把 PRD 转成规格文档", "convert PRD to spec",
  "从 PRD 生成实现方案", "生成 spec", "写一个实现规格", "create implementation spec",
  "准备 PRD 给 agent 执行", 或执行 /spec-generator 命令时使用。
  将产品需求文档（PRD）转化为精确的、编码 Agent 可直接执行的实现规格文档。
argument-hint: "<PRD 来源：文件路径 | 飞书文档 URL | 文本内容>"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - Skill
  - AskUserQuestion
---

# Spec 生成工作流

将产品需求文档（PRD）转化为精确的、编码 Agent 可直接执行的实现规格文档。

## 执行原则

1. **严格按步骤顺序执行** — 不跳步、不并行
2. **每步必须通过质量门禁** — 未通过则修复后重新检查，不推进到下一步
3. **检查点必须暂停** — 等待用户明确确认后才继续
4. **产出物可追溯** — 每步产出物都有明确的目标、使用场景和验收标准
5. **每步产出物写入文件** — 产出物必须写入工作目录下的指定文件，后续步骤从文件读取输入

## 执行流程

### 初始化

1. 解析用户输入，确定 PRD 来源（文件路径 / 飞书 URL / 内联文本）
2. 从 PRD 来源中提取 `{feature-name}`（从文件名、PRD 标题或用户指定获取）
3. 使用 Bash 工具生成 6 位随机字符：`openssl rand -hex 3`
4. 创建工作目录：`mkdir -p specs/{feature-name}-spec-{随机字符}/`
5. 定义 `{workspace}` 变量为工作目录的绝对路径
6. 将 PRD 来源信息写入 `{workspace}/.input.md`：
   ```markdown
   ---
   source-type: file-path | lark-url | inline-text
   source-ref: <文件路径 | URL | inline>
   feature-name: <功能名称>
   ---
   <如果是内联文本，PRD 内容写在此处；否则留空>
   ```
7. 从 `references/tasks-template.md` 读取任务清单模板
8. 将任务清单写入 `{workspace}/tasks.md`，填充所有模板变量
9. 使用 TaskCreate 创建 6 个 task，与任务清单一一对应

### 逐步执行

每个步骤在独立的上下文窗口中执行（通过 `context: fork` 实现）。编排器在主上下文中负责质量门禁检查和用户确认。

对每个步骤，严格执行以下循环：

```
对于 step N (N = 1..6):
  1. TaskUpdate → in_progress
  2. 使用 Skill 工具调用该步骤的 skill，传入 {workspace} 绝对路径作为参数
     - 子代理在独立上下文窗口中执行该步骤的执行流程和规范
     - 子代理从文件读取输入、执行处理、写入产出文件
  3. 子代理完成后，读取该步骤 skill 目录下的 `references/quality-gate.md`（如 `plugins/spec-generator/skills/prd-loader/references/quality-gate.md`）
  4. 产出物自检：逐项检查验收标准（含文件存在性检查）
  5. 如果验收标准未全部通过：
     - 使用 Edit 工具修复产出文件中的问题
     - 重新自检
     - 最多重试 2 次，仍未通过则向用户报告
  6. 更新 {workspace}/tasks.md 中该步骤状态为 completed
  7. TaskUpdate → completed
  8. 如果该步骤有检查点：
     - 展示产出物摘要（读取产出文件的关键内容）
     - 使用 AskUserQuestion 等待用户确认
     - 如果用户有修改意见，使用 Edit 工具根据意见修改产出文件后重新自检
```

### 步骤与内部 skill 的对应关系

| 步骤 | 内部 skill | 输入文件 | 输出文件 | 检查点 |
|------|-----------|----------|----------|--------|
| Task 1: 加载 PRD | `prd-loader` | `.input.md`（编排器写入） | `prd-source.md` | — |
| Task 2: PRD 分析 | `prd-analyzer` | `prd-source.md` | `prd-analysis.md` | 用户确认分析结果 |
| Task 3: 代码库映射 | `codebase-mapper` | `prd-analysis.md` | `codebase-mapping.md` | 用户确认映射结果 |
| Task 4: 生成规格 | `spec-creator` | `prd-analysis.md` + `codebase-mapping.md` | `{feature-name}-spec.md` | — |
| Task 5: 质量审查 | `spec-reviewer` | `prd-source.md` + `prd-analysis.md` + `{feature-name}-spec.md` | `review-report.md` | 展示审查结果，需返工则回到 Task 4 |
| Task 6: 输出交付 | `spec-deliverer` | 工作目录所有文件 | 最终输出 | 用户确认输出位置 |

所有输入输出文件路径相对于 `{workspace}`。

### Task 5 返工循环

如果 spec-reviewer 的审查结论为 `NEEDS_REVISION`：

1. 读取 `{workspace}/review-report.md` 中的关键问题
2. 更新 `{workspace}/tasks.md` 中 Task 4 状态为 in_progress
3. 使用 Skill 工具重新调用 `spec-creator`，传入 `{workspace}` 路径
   - 子代理会读取已有文件并根据需要调整（如有返工记录，读取后针对性修复）
4. 更新 `{workspace}/tasks.md` 中 Task 4 状态为 completed
5. 使用 Skill 工具重新调用 `spec-reviewer` 审查
6. 最多循环 2 次（共 3 次审查），仍未通过则向用户报告并请求指导

## 内部 skill 调用方式

本工作流的内部 skill（`prd-loader`、`prd-analyzer`、`codebase-mapper`、`spec-creator`、`spec-reviewer`、`spec-deliverer`）不为用户独立调用而设计。编排器通过以下方式使用它们：

1. 使用 **Skill 工具** 调用 `{skill-name}`，传入 `{workspace}` 绝对路径作为参数
2. 各步骤 skill 均设置了 `context: fork`，在独立的上下文窗口中执行
3. 子代理通过 `$ARGUMENTS` 获取工作目录路径，从文件读取输入、写入产出文件
4. 编排器在主上下文中负责：
   - 读取各步骤 skill 目录下的 `references/quality-gate.md` 执行质量门禁检查
   - 使用 AskUserQuestion 处理检查点用户确认
   - 使用 Edit 工具修复质量门禁未通过的问题
   - 协调返工循环

## 依赖

- **`prd-loader`** — PRD 内容加载执行流程和规范
- **`prd-analyzer`** — PRD 5-zone 分析执行流程和规范
- **`codebase-mapper`** — 代码库上下文映射执行流程和规范
- **`spec-creator`** — 规格文档生成执行流程和规范
- **`spec-reviewer`** — 规格文档质量审查执行流程和规范
- **`spec-deliverer`** — 输出交付执行流程和规范
- **`lark-doc`** skill（可选）— 飞书文档集成，用于 PRD 输入和 spec 输出
