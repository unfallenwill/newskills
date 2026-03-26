# feature-explorer

深入解析代码仓库中某个功能的实现原理，追踪调用链、梳理数据流、输出结构化报告。

## 什么时候该用

- 需要理解某个功能/模块/机制是如何实现的
- 想要追踪代码调用链和数据流
- 接手新项目，需要快速了解核心功能的设计

## 什么时候不该用

- 调试或修复 bug
- 修改或重构代码
- 需要执行实际的代码变更

## 使用方式

```
/feature-explorer 登录流程
/feature-explorer payment module
```

## 输出内容

1. **Overview**：功能概述（2-3 句话）
2. **Call Chain**：带 `file:line` 的调用关系链（最多 7 层）
3. **Data Flow**：数据来源、转换、去向
4. **Key Design Decisions**：关键设计决策和模式
5. **Files**：所有关键文件路径列表
