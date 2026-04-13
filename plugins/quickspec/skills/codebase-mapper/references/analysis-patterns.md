# 代码库分析模式

常见项目类型的详细分析模式。

## Web 应用（前端）

**技术栈特征：** 含 React/Vue/Angular 的 `package.json`，`src/` 目录

**需要检查的关键目录：**
- `src/components/` — UI 组件
- `src/pages/` 或 `src/views/` — 页面级组件
- `src/api/` 或 `src/services/` — API 客户端代码
- `src/stores/` 或 `src/state/` — 状态管理
- `src/utils/` 或 `src/helpers/` — 共享工具函数
- `src/types/` 或 `src/interfaces/` — 类型定义
- `src/styles/` — 样式
- `src/hooks/` — 自定义 React hooks（React 项目）

**模式识别方法：**
1. 查看一个代表性的组件文件，了解 import/export 模式。
2. 查看 `src/api/` 了解 API 调用的组织方式（axios 实例、fetch 封装等）。
3. 查看状态管理了解全局状态的访问和修改方式。
4. 查看路由配置了解新页面如何注册。
5. 查看测试文件了解测试框架和断言模式。

## API 服务（后端）

**技术栈特征：** `pyproject.toml`、`go.mod`、`pom.xml`、含 Express/Fastify 的 `package.json`

**需要检查的关键目录：**
- `src/controllers/` 或 `src/handlers/` — 请求处理器
- `src/services/` 或 `src/usecases/` — 业务逻辑
- `src/models/` 或 `src/entities/` — 数据模型
- `src/repositories/` 或 `src/dao/` — 数据访问层
- `src/middleware/` — 中间件
- `src/routes/` — 路由定义
- `src/config/` — 配置
- `migrations/` — 数据库迁移

**模式识别方法：**
1. 查看一个代表性的 controller 了解请求/响应处理模式。
2. 查看 service 层了解依赖注入或直接实例化的方式。
3. 查看模型定义了解 ORM 用法和校验规则。
4. 查看迁移文件了解命名约定和结构。
5. 查看错误处理了解异常类型或错误响应格式。

## Monorepo

**技术栈特征：** `lerna.json`、`pnpm-workspace.yaml`、`turbo.json`、`nx.json`

**分析方式：**
1. 识别工作区根目录下的所有 packages/apps。
2. 确定哪个包与 PRD 功能相关。
3. 对该包应用相应的单项目分析模式。
4. 检查可能需要更新的共享包。
5. 理解包之间的依赖图。

## 微服务

**技术栈特征：** 子目录中有多个服务，docker-compose.yml，k8s 配置

**分析方式：**
1. 识别 PRD 功能涉及的服务。
2. 检查服务间通信模式（REST、gRPC、消息队列）。
3. 检查共享的 proto/API 定义。
4. 检查服务发现和配置管理。

## CLI 工具

**技术栈特征：** `cli.js`、`main.py`、`cmd/` 目录，依赖中有 `click`、`commander`、`argparse`

**分析方式：**
1. 找到命令注册/定义的入口。
2. 检查 flag 和参数的解析方式。
3. 检查输出格式化模式（stdout、JSON、table）。
4. 检查错误处理和退出码约定。
5. 检查配置文件处理方式。

## 常见模式示例

### React 组件模式
```
src/components/ComponentName/
├── index.tsx        # 组件实现
├── styles.ts        # Styled components 或 CSS module
├── types.ts         # TypeScript 接口
└── test.tsx         # 测试
```

### Express 路由模式
```
src/
├── routes/
│   └── feature.ts   # 路由定义
├── controllers/
│   └── feature.ts   # 请求处理器
├── services/
│   └── feature.ts   # 业务逻辑
└── models/
    └── feature.ts   # 数据模型
```

### Django App 模式
```
app_name/
├── models.py        # ORM 模型
├── views.py         # 请求处理器
├── serializers.py   # API 序列化器
├── urls.py          # URL 路由
├── tests.py         # 测试
└── migrations/      # 数据库迁移
```
