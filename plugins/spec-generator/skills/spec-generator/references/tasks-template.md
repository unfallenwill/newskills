# Spec 生成任务清单: {feature-name}

> 创建时间: {date}
> PRD 来源: {prd-source}
> 工作目录: {workspace}

---

## 任务列表

### Task 1: 加载 PRD 内容

- **产出物**: `{workspace}/prd-source.md`
- **状态**: pending
- **质量门禁**: 文件存在、内容完整未截断、格式可识别、来源类型已确定

### Task 2: PRD 分析

- **输入**: `{workspace}/prd-source.md`
- **产出物**: `{workspace}/prd-analysis.md`
- **状态**: pending
- **质量门禁**: 文件存在、5 个 zone 全填充、功能有唯一编号和优先级、歧义已标注、PRD 章节全覆盖
- **检查点**: 用户确认分析结果符合 PRD 原意

### Task 3: 代码库上下文映射

- **输入**: `{workspace}/prd-analysis.md`
- **产出物**: `{workspace}/codebase-mapping.md`
- **状态**: pending
- **质量门禁**: 文件存在、技术栈正确、相关模块已定位、扩展点有具体文件路径、约定已提取
- **检查点**: 用户确认映射结果准确

### Task 4: 生成规格文档

- **输入**: `{workspace}/prd-analysis.md` + `{workspace}/codebase-mapping.md`
- **产出物**: `{workspace}/{feature-name}-spec.md`
- **状态**: pending
- **质量门禁**: 文件存在、任务有文件路径和操作类型、数据模型全类型化、API 有完整 schema、验收标准可布尔判定、spec 自包含

### Task 5: 质量审查

- **输入**: `{workspace}/prd-source.md` + `{workspace}/prd-analysis.md` + `{workspace}/{feature-name}-spec.md`
- **产出物**: `{workspace}/review-report.md`
- **状态**: pending
- **质量门禁**: 文件存在、PRD 覆盖率 ≥ 95%、无 critical issue、verdict = PASS 或 PASS_WITH_NOTES
- **检查点**: 展示审查结果，如需返工回到 Task 4

### Task 6: 输出交付

- **输入**: `{workspace}/` 所有文件
- **产出物**: 最终 spec 文件 + 可选飞书文档
- **状态**: pending
- **质量门禁**: 最终输出文件可读、格式符合用户要求、tasks.md 步骤 1-5 全部 completed
- **检查点**: 用户确认输出位置和格式
