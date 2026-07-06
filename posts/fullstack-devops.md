---
AIGC:
    Label: "1"
    ContentProducer: 001191110102MACQD9K64018705
    ProduceID: 7641889108075528511-data_volume/files/所有对话/主对话/教程文件/前后端架构解析/全栈架构与DevOps.md
    ReservedCode1: ""
    ContentPropagator: 001191110102MACQD9K64028705
    PropagateID: 0#1781573275986
    ReservedCode2: ""
---
# 全栈架构与 DevOps

## 目录

1. [全栈架构模式](#1-全栈架构模式)
2. [部署与 DevOps](#2-部署与-devops)
3. [架构设计模式](#3-架构设计模式)

---

## 1. 全栈架构模式

### 1.1 SSR vs CSR vs SSG 适用场景

#### 1.1.1 三种渲染模式对比

| 模式 | 全称 | 首屏渲染 | 交互性 | SEO | 适用场景 |
|------|------|---------|--------|-----|---------|
| **CSR** | Client-Side Rendering | 慢（需等 JS 下载执行） | 高 | 差 | 后台系统、SPA |
| **SSR** | Server-Side Rendering | 快 | 高 | 好 | 动态内容、用户个性化 |
| **SSG** | Static Site Generation | 最快 | 中 | 最好 | 静态站点、博客、文档 |

#### 1.1.2 CSR 实现（React SPA）

```javascript
// React + Vite 实现 CSR
// src/App.jsx
import React, { useState, useEffect } from 'react';

function App() {
    const [data, setData] = useState(null);
    const [loading, setLoading] = useState(true);

    // 客户端数据获取
    useEffect(() => {
        fetch('/api/data')
            .then(res => res.json())
            .then(data => {
                setData(data);
                setLoading(false);
            });
    }, []);

    if (loading) return <div>Loading...</div>;

    return (
        <div>
            <h1>CSR Application</h1>
            {data && <p>{data.message}</p>}
        </div>
    );
}

export default App;
```

```javascript
// vite.config.js
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
    plugins: [react()],
    build: {
        outDir: 'dist',
        // CSR 模式：所有资源从相对路径加载
    }
});
```

#### 1.1.3 SSR 实现（Next.js）

```javascript
// pages/index.js - Next.js SSR
// 每次请求都会在服务端执行
export async function getServerSideProps() {
    // 服务端直接查询数据库
    const res = await fetch('http://internal-api/data');
    const data = await res.json();

    return {
        props: { data },  // 传递给组件的 props
    };
}

export default function Home({ data }) {
    return (
        <div>
            <h1>SSR Page</h1>
            <p>{data.message}</p>
        </div>
    );
}
```

#### 1.1.4 SSG 实现（Next.js）

```javascript
// pages/about.js - Next.js SSG
// 构建时生成，部署后无需服务端
export async function getStaticProps() {
    // 构建时执行一次
    const data = await fetch('http://api/data').then(r => r.json());

    return {
        props: { data },
        // ISR: 构建后每 3600 秒重新生成
        revalidate: 3600,
    };
}

export default function About({ data }) {
    return (
        <div>
            <h1>About (Static)</h1>
            <p>{data.content}</p>
        </div>
    );
}
```

### 1.2 BFF（Backend For Frontend）模式

#### 1.2.1 BFF 架构设计

```
┌─────────────────────────────────────────────────────────────┐
│                      BFF 架构模式                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐                 │
│  │   iOS   │    │ Android │    │   Web   │                 │
│  └────┬────┘    └────┬────┘    └────┬────┘                 │
│       │              │              │                        │
│       └──────────────┼──────────────┘                        │
│                      │                                       │
│              ┌───────┴───────┐                              │
│              │      BFF       │                              │
│              │  (API Gateway) │                              │
│              │               │                              │
│              │ ┌───────────┐ │                              │
│              │ │ iOS BFF   │ │  ← 不同客户端                │
│              │ │ Android   │ │    定制化接口                 │
│              │ │ Web BFF   │ │                              │
│              │ └───────────┘ │                              │
│              └───────┬───────┘                              │
│                      │                                       │
│       ┌──────────────┼──────────────┐                        │
│       │              │              │                        │
│       ▼              ▼              ▼                        │
│  ┌─────────┐    ┌─────────┐    ┌─────────┐                  │
│  │ User    │    │ Product │    │ Order   │                  │
│  │ Service │    │ Service │    │ Service │                  │
│  └─────────┘    └─────────┘    └─────────┘                  │
│                                                             │
│  优势：                                                      │
│  1. 减少客户端请求次数（聚合多个微服务）                      │
│  2. 定制化返回字段（iOS 不需要 web 特有字段）                 │
│  3. 统一认证、日志、监控                                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### 1.2.2 BFF 实现示例

```typescript
// bff/src/routes/web.ts
// Web 端 BFF - 返回完整数据（SEO 需要）
import { Router } from 'express';
import { userService } from '../services/user';
import { productService } from '../services/product';

const router = Router();

router.get('/home', async (req, res) => {
    // Web 端需要完整的 SEO 数据
    const [user, products, banners] = await Promise.all([
        userService.getRecommendUsers(),
        productService.getHotProducts(),
        productService.getBanners()
    ]);

    res.json({
        user,
        products,
        banners,  // Web 特有
        meta: { title: 'Home', description: '...' }  // Web 特有 SEO
    });
});

export default router;
```

```typescript
// bff/src/routes/mobile.ts
// 移动端 BFF - 返回精简数据
import { Router } from 'express';
import { userService } from '../services/user';
import { productService } from '../services/product';

const router = Router();

router.get('/home', async (req, res) => {
    // 移动端不需要 SEO，专注于性能
    const [user, products] = await Promise.all([
        userService.getRecommendUsers({ limit: 5 }),
        productService.getHotProducts({ limit: 10 })
        // 移动端不需要 banners，减少数据传输
    ]);

    res.json({
        user,
        products,
        version: '2.0'  // 移动端特有
    });
});

export default router;
```

### 1.3 微前端架构设计与实现

#### 1.3.1 微前端解决的问题

```
┌─────────────────────────────────────────────────────────────┐
│                    微前端架构价值                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  传统巨石应用问题：                                          │
│  ├── 技术栈单一，无法引入新技术                               │
│  ├── 部署耦合，改一处需全量回归                               │
│  ├── 开发团队协作困难                                        │
│  └── 扩展性差，难以拆分                                      │
│                                                             │
│  微前端解决方案：                                            │
│  ├── 技术无关（React/Vue/Angular 混用）                      │
│  ├── 独立部署（各子应用独立上线）                             │
│  ├── 团队自治（按业务/功能划分）                              │
│  └── 增量升级（逐步迁移新技术）                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### 1.3.2 微前端实现方案对比

| 方案 | 原理 | 优点 | 缺点 |
|------|------|------|------|
| **iframe** | 浏览器原生隔离 | 实现简单，完全隔离 | 通信困难，性能差 |
| **Web Components** | 原生组件标准 | 原生支持，通用性强 | 生态不成熟 |
| **Module Federation** | Webpack 运行时共享 | 性能好，生态成熟 | 配置复杂 |
| **qiankun** | 基于 Single-SPA 封装 | 封装完善，文档好 | 依赖 Single-SPA |

#### 1.3.3 Module Federation 实现示例

```javascript
// 主应用 webpack.config.js
const ModuleFederationPlugin = require('webpack/lib/container/ModuleFederationPlugin');
const HtmlWebpackPlugin = require('html-webpack-plugin');

module.exports = {
    mode: 'development',
    devServer: { port: 3000 },
    plugins: [
        new ModuleFederationPlugin({
            name: 'host',
            remotes: {
                // 声明远程应用
                dashboard: 'dashboard@http://localhost:3001/remoteEntry.js',
                admin: 'admin@http://localhost:3002/remoteEntry.js'
            },
            shared: ['react', 'react-dom', 'react-router-dom']
        }),
        new HtmlWebpackPlugin({
            template: './index.html'
        })
    ]
};
```

```javascript
// 子应用（Dashboard）webpack.config.js
const ModuleFederationPlugin = require('webpack/lib/container/ModuleFederationPlugin');
const HtmlWebpackPlugin = require('html-webpack-plugin');

module.exports = {
    mode: 'development',
    devServer: { port: 3001 },
    plugins: [
        new ModuleFederationPlugin({
            name: 'dashboard',
            filename: 'remoteEntry.js',  // 暴露给主应用的入口
            exposes: {
                // 暴露组件
                './Dashboard': './src/Dashboard',
                './DashboardStats': './src/components/Stats'
            },
            shared: ['react', 'react-dom']
        }),
        new HtmlWebpackPlugin({
            template: './index.html'
        })
    ]
};
```

```jsx
// 主应用中使用子应用组件
import React, { Suspense } from 'react';

// 使用 React.lazy 懒加载远程组件
const Dashboard = React.lazy(() => import('dashboard/Dashboard'));
const DashboardStats = React.lazy(() => import('dashboard/DashboardStats'));

function App() {
    return (
        <div className="app">
            <header>Main Application Header</header>
            
            <main>
                <Suspense fallback={<div>Loading Dashboard...</div>}>
                    <Dashboard title="Sales Overview" />
                </Suspense>
                
                <Suspense fallback={<div>Loading Stats...</div>}>
                    <DashboardStats />
                </Suspense>
            </main>
        </div>
    );
}
```

---

## 2. 部署与 DevOps

### 2.1 Docker 容器化核心概念

#### 2.1.1 Docker vs 传统部署

```
传统部署问题：
┌─────────────────────────────────────────────────────────────┐
│  服务器 A: Python 3.8 + Django + PostgreSQL 12              │
│  服务器 B: Python 3.9 + Flask + MySQL 8                      │
│  服务器 C: Node 14 + Express + MongoDB 5                    │
│                                                             │
│  问题：                                                    │
│  • 环境冲突（需要同时运行 Python 3.8 和 3.9）                  │
│  • 依赖版本不一致导致各种问题                                 │
│  • 新机器部署困难（手动配置环境）                             │
│  • 资源利用率低                                              │
└─────────────────────────────────────────────────────────────┘

Docker 容器化：
┌─────────────────────────────────────────────────────────────┐
│                    宿主机 (Host OS)                         │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                     │
│  │Container│  │Container│  │Container│                     │
│  │ App A   │  │ App B   │  │ App C   │                     │
│  │Python3.8│  │Python3.9│  │Node 14  │                     │
│  │Django   │  │Flask    │  │Express  │                     │
│  ├─────────┤  ├─────────┤  ├─────────┤                     │
│  │Container│  │Container│  │Container│                     │
│  │Postgres │  │MySQL    │  │MongoDB  │                     │
│  └─────────┘  └─────────┘  └─────────┘                     │
│                    ↑                                        │
│              Docker Engine                                  │
└─────────────────────────────────────────────────────────────┘

优势：
• 环境一致（开发/测试/生产完全相同）
• 资源隔离（应用间互不干扰）
• 快速部署（镜像拉取即用）
• 弹性伸缩（容器可快速扩缩）                                    │
└─────────────────────────────────────────────────────────────┘
```

#### 2.1.2 Dockerfile 编写

```dockerfile
# Dockerfile 示例 - Node.js 应用
# 阶段一：构建
FROM node:18-alpine AS builder

WORKDIR /app

# 复制依赖文件并安装
COPY package*.json ./
RUN npm ci --only=production

# 复制源代码并构建
COPY . .
RUN npm run build

# 阶段二：运行
FROM node:18-alpine AS runner

WORKDIR /app

# 创建非 root 用户（安全）
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# 从构建阶段复制产物
COPY --from=builder --chown=nextjs:nodejs /app/dist ./dist
COPY --from=builder --chown=nextjs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nextjs:nodejs /app/package.json ./

# 切换用户
USER nextjs

# 暴露端口
EXPOSE 3000

# 启动命令
CMD ["node", "dist/server.js"]
```

#### 2.1.3 Docker Compose 编排

```yaml
# docker-compose.yml
version: '3.8'

services:
  # 应用服务
  web:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://postgres:password@db:5432/myapp
    depends_on:
      - db
      - redis
    restart: unless-stopped
    networks:
      - app-network

  # 数据库服务
  db:
    image: postgres:15-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    environment:
      - POSTGRES_DB=myapp
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    restart: unless-stopped
    networks:
      - app-network

  # Redis 缓存
  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes
    restart: unless-stopped
    networks:
      - app-network

  # Nginx 反向代理
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - web
    restart: unless-stopped
    networks:
      - app-network

volumes:
  postgres_data:
  redis_data:

networks:
  app-network:
    driver: bridge
```

### 2.2 Kubernetes 架构设计

#### 2.2.1 Kubernetes 核心概念

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes 架构                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                    Master Node                       │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐ │   │
│  │  │ kube-   │  │ kube-   │  │ kube-   │  │   etcd  │ │   │
│  │  │apiserver│  │scheduler│  │controller│ │         │ │   │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────┘ │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                                 │
│                           ▼                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   Worker Node 1                       │   │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐              │   │
│  │  │  Pod     │  │  Pod     │  │  Pod     │              │   │
│  │  │┌───────┐│  │┌───────┐│  │┌───────┐│              │   │
│  │  ││Container│ │Container│ │Container│ │              │   │
│  │  │└───────┘│  │└───────┘│  │└───────┘│              │   │
│  │  └─────────┘  └─────────┘  └─────────┘              │   │
│  │                                                    │   │
│  │  ┌─────────────────────────────────────────────┐  │   │
│  │  │              kubelet + kube-proxy            │  │   │
│  │  └─────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────┘   │
│                           │                                 │
│                           ▼                                 │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                   Worker Node 2                      │   │
│  │  ┌─────────┐  ┌─────────┐                           │   │
│  │  │  Pod     │  │  Pod     │                           │   │
│  │  │┌───────┐│  │┌───────┐│                           │   │
│  │  ││Container│ │Container│ │                           │   │
│  │  │└───────┘│  │└───────┘│                           │   │
│  │  └─────────┘  └─────────┘                           │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘

核心概念：
• Pod: 最小调度单元，包含一个或多个容器
• Service: 负载均衡和服务发现
• Deployment: 声明式更新，副本管理
• Ingress: HTTP/HTTPS 路由
• ConfigMap/Secret: 配置管理
• PersistentVolume: 持久化存储
```

#### 2.2.2 Kubernetes 资源定义

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  labels:
    app: web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
        - name: web-app
          image: myregistry/web-app:v1.0.0
          ports:
            - containerPort: 3000
          env:
            - name: NODE_ENV
              value: "production"
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key: url
          resources:
            requests:
              memory: "256Mi"
              cpu: "250m"
            limits:
              memory: "512Mi"
              cpu: "500m"
          livenessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 10
            periodSeconds: 5
          readinessProbe:
            httpGet:
              path: /ready
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 3
```

```yaml
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-service
spec:
  selector:
    app: web-app
  ports:
    - protocol: TCP
      port: 80        # Service 端口
      targetPort: 3000  # 容器端口
  type: ClusterIP
```

```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - example.com
      secretName: web-app-tls
  rules:
    - host: example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: web-app-service
                port:
                  number: 80
```

### 2.3 CI/CD 流程设计

#### 2.3.1 完整 CI/CD 流程

```
┌─────────────────────────────────────────────────────────────┐
│                    CI/CD 完整流程                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  代码提交 ──▶ Git Hooks ──▶ GitLab CI / GitHub Actions      │
│      │                                  │                   │
│      │                            ┌─────▼─────┐            │
│      │                            │  Pipeline │            │
│      │                            └─────┬─────┘            │
│      │                                  │                   │
│      │                   ┌──────────────┼──────────────┐    │
│      │                   ▼              ▼              ▼    │
│      │              ┌─────────┐   ┌─────────┐   ┌─────────┐ │
│      │              │  Lint   │   │  Test   │   │  Build  │ │
│      │              │ 代码风格 │   │ 单元测试 │   │  编译   │ │
│      │              └────┬────┘   └────┬────┘   └────┬────┘ │
│      │                   │              │              │    │
│      │                   └──────────────┼──────────────┘    │
│      │                                  │                   │
│      │                            ┌─────▼─────┐            │
│      │                            │  质量门禁  │            │
│      │                            └─────┬─────┘            │
│      │                                  │                   │
│      │                            ┌─────▼─────┐            │
│      │                            │ Security  │            │
│      │                            │   Scan    │            │
│      │                            └─────┬─────┘            │
│      │                                  │                   │
│      │                   ┌──────────────┴──────────────┐    │
│      │                   ▼                             ▼    │
│      │              ┌─────────┐                  ┌─────────┐│
│      │              │  Push   │                  │  Push   ││
│      │              │  Image  │                  │  Image  ││
│      │              │ to Dev  │                  │ to Prod ││
│      │              └────┬────┘                  └────┬────┘│
│      │                   │                            │    │
│      │                   ▼                            ▼    │
│      │              ┌─────────┐                  ┌─────────┐│
│      │              │ Deploy  │                  │ Deploy  ││
│      │              │   to    │                  │  to     ││
│      │              │   Dev   │                  │  Prod   ││
│      │              └────┬────┘                  └────┬────┘│
│      │                   │                            │    │
│      │                   ▼                            ▼    │
│      │              ┌─────────┐                  ┌─────────┐│
│      │              │ Auto    │                  │ Canary  ││
│      │              │  Test   │                  │ Deploy  ││
│      │              └─────────┘                  └─────────┘│
│      │                   │                            │    │
│      └───────────────────┴────────────────────────────┘    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

#### 2.3.2 GitHub Actions 示例

```yaml
# .github/workflows/ci.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  # 阶段一：代码检查
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run ESLint
        run: npm run lint
      
      - name: Check types
        run: npm run type-check

  # 阶段二：测试
  test:
    runs-on: ubuntu-latest
    needs: lint
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run unit tests
        run: npm run test:unit
      
      - name: Run integration tests
        run: npm run test:integration
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/lcov.info

  # 阶段三：构建并推送到镜像仓库
  build-and-push:
    runs-on: ubuntu-latest
    needs: test
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Login to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=sha,prefix={{branch}}-
            type=raw,value=latest
      
      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  # 阶段四：部署到 Kubernetes
  deploy:
    runs-on: ubuntu-latest
    needs: build-and-push
    if: github.ref == 'refs/heads/main'
    environment: production
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup kubectl
        uses: azure/setup-kubectl@v3
      
      - name: Configure kubectl
        run: |
          echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > kubeconfig
          echo "KUBECONFIG=$(pwd)/kubeconfig" >> $GITHUB_ENV
      
      - name: Deploy to production
        run: |
          kubectl set image deployment/web-app \
            web-app=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          kubectl rollout status deployment/web-app --timeout=300s
```

### 2.4 云原生架构设计原则

#### 2.4.1 云原生十二要素

| 要素 | 说明 | 实践 |
|------|------|------|
| **基准代码** | 一份基准代码，多分部署 | Git 管理，CI/CD 流水线 |
| **依赖** | 显式声明依赖 | package.json, requirements.txt |
| **配置** | 环境变量存储配置 | ConfigMap, Secret |
| **后端服务** | 把后端服务当作附加资源 | 数据库、缓存作为服务引用 |
| **构建/发布/运行** | 严格分离构建和运行阶段 | Docker 镜像分层 |
| **进程** | 应用作为一个或多个无状态进程 | 容器无状态设计 |
| **端口绑定** | 通过端口绑定导出服务 | Service 暴露 |
| **并发** | 通过进程模型扩展 | Kubernetes HPA |
| **易处理** | 快速启动和优雅停止 | 优雅关闭信号处理 |
| **开发/生产对等** | 开发/ staging /生产环境一致 | 容器镜像统一 |
| **日志** | 把日志当作事件流 | stdout 输出，ELK 收集 |
| **管理进程** | 后台管理任务作为一次性进程 | Kubernetes Job |

#### 2.4.2 微服务设计原则

```
┌─────────────────────────────────────────────────────────────┐
│                    微服务设计原则                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. 单一职责原则                                             │
│     每个服务只负责一个业务功能                               │
│     ┌─────────┐  ┌─────────┐  ┌─────────┐                 │
│     │ User    │  │ Product │  │  Order  │                 │
│     │ Service │  │ Service │  │ Service │                 │
│     └─────────┘  └─────────┘  └─────────┘                 │
│                                                             │
│  2. 独立数据库原则                                           │
│     每个服务拥有自己的数据库                                 │
│     ┌─────────┐  ┌─────────┐  ┌─────────┐                 │
│     │ Users DB│  │Products │  │ Orders  │                 │
│     │ Postgres│  │  MySQL  │  │ MongoDB │                 │
│     └─────────┘  └─────────┘  └─────────┘                 │
│                                                             │
│  3. API 优先原则                                             │
│     通过 API 进行服务间通信                                  │
│     ┌───────┐     ┌───────┐     ┌───────┐                 │
│     │ A     │────▶│ B     │────▶│ C     │                 │
│     └───────┘     └───────┘     └───────┘                 │
│                                                             │
│  4. 异步通信原则                                             │
│     优先使用消息队列解耦                                     │
│     ┌───────┐     ┌─────────┐     ┌───────┐               │
│     │ A     │────▶│  Kafka  │────▶│ B     │               │
│     └───────┘     └─────────┘     └───────┘               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. 架构设计模式

### 3.1 设计模式在前端的应用

#### 3.1.1 常见设计模式

| 模式 | 前端应用场景 | 示例 |
|------|------------|------|
| **单例模式** | 全局状态、弹窗管理器 | Redux Store、Modal |
| **工厂模式** | 创建不同类型组件 | React.createElement |
| **观察者模式** | 响应式数据绑定 | Vue 响应式原理、EventEmitter |
| **策略模式** | 表单验证规则切换 | 不同验证策略 |
| **装饰器模式** | HOC、装饰器 | @withStyles、@observer |
| **组合模式** | 组件树结构 | React Props.children |

#### 3.1.2 观察者模式实现

```javascript
// 简单的观察者模式实现
class EventEmitter {
    constructor() {
        this.events = {};
    }
    
    on(event, callback) {
        if (!this.events[event]) {
            this.events[event] = [];
        }
        this.events[event].push(callback);
        // 返回取消订阅函数
        return () => this.off(event, callback);
    }
    
    off(event, callback) {
        if (!this.events[event]) return;
        this.events[event] = this.events[event].filter(cb => cb !== callback);
    }
    
    emit(event, ...args) {
        if (!this.events[event]) return;
        this.events[event].forEach(callback => callback(...args));
    }
    
    once(event, callback) {
        const wrapper = (...args) => {
            callback(...args);
            this.off(event, wrapper);
        };
        this.on(event, wrapper);
    }
}

// 使用示例
const emitter = new EventEmitter();

// 订阅
const unsubscribe = emitter.on('user:login', (user) => {
    console.log('User logged in:', user.name);
});

// 发布
emitter.emit('user:login', { name: 'John' });

// 取消订阅
unsubscribe();
```

#### 3.1.3 装饰器模式（HOC）

```javascript
// 高阶组件 (Higher-Order Component)
function withLoading(WrappedComponent) {
    return function WithLoadingComponent({ isLoading, ...props }) {
        if (isLoading) {
            return <div className="loading-spinner">Loading...</div>;
        }
        return <WrappedComponent {...props} />;
    };
}

// 多个装饰器组合
function withAuth(WrappedComponent) {
    return function AuthComponent({ isAuthenticated, ...props }) {
        if (!isAuthenticated) {
            return <div>Please login first</div>;
        }
        return <WrappedComponent {...props} />;
    };
}

// 使用装饰器
const EnhancedUserList = withAuth(withLoading(UserList));

// 渲染
<EnhancedUserList isLoading={true} isAuthenticated={true} />
```

### 3.2 设计模式在后端的应用

#### 3.2.1 依赖注入模式

```typescript
// TypeScript 依赖注入示例
import { Injectable, Inject } from '@nestjs/common';

// 定义 Token
const DATABASE_TOKEN = 'DATABASE';

// 接口定义
interface Database {
    query(sql: string): Promise<any>;
}

// 实现
@Injectable()
class PostgreSQL implements Database {
    async query(sql: string) {
        // PostgreSQL 实现
    }
}

// 使用 @Inject 指定 Token
@Injectable()
class UserService {
    constructor(
        @Inject(DATABASE_TOKEN) private db: Database
    ) {}
    
    async findUsers() {
        return this.db.query('SELECT * FROM users');
    }
}

// 模块注册
@Module({
    providers: [
        { provide: DATABASE_TOKEN, useClass: PostgreSQL },
        UserService
    ]
})
export class AppModule {}
```

#### 3.2.2 仓储模式（Repository Pattern）

```typescript
// 仓储接口
interface UserRepository {
    findById(id: number): Promise<User | null>;
    findAll(): Promise<User[]>;
    save(user: User): Promise<User>;
    delete(id: number): Promise<void>;
}

// 仓储实现
@Injectable()
class TypeORMUserRepository implements UserRepository {
    constructor(
        @InjectRepository(User)
        private ormRepo: Repository<User>
    ) {}
    
    async findById(id: number): Promise<User | null> {
        return this.ormRepo.findOne({ where: { id } });
    }
    
    async findAll(): Promise<User[]> {
        return this.ormRepo.find();
    }
    
    async save(user: User): Promise<User> {
        return this.ormRepo.save(user);
    }
    
    async delete(id: number): Promise<void> {
        await this.ormRepo.delete(id);
    }
}

// 服务层使用仓储
@Injectable()
class UserService {
    constructor(
        private userRepo: UserRepository
    ) {}
    
    async getUserWithOrders(userId: number) {
        const user = await this.userRepo.findById(userId);
        if (!user) {
            throw new NotFoundException('User not found');
        }
        const orders = await this.orderRepo.findByUser(userId);
        return { user, orders };
    }
}
```

### 3.3 分布式系统核心概念

#### 3.3.1 负载均衡算法

| 算法 | 原理 | 优点 | 缺点 |
|------|------|------|------|
| **轮询 (Round Robin)** | 依次分配请求 | 简单、均匀 | 不考虑服务器负载 |
| **加权轮询** | 按权重分配 | 可控制比例 | 权重固定 |
| **最少连接** | 分配给连接数最少的 | 动态平衡 | 实现复杂 |
| **IP 哈希** | 同一 IP 固定到某服务器 | Session 保持 | 可能不均匀 |

```
负载均衡示意：
                    ┌─────────────┐
                    │ Load        │
                    │ Balancer    │
                    └──────┬──────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
         ▼                 ▼                 ▼
    ┌─────────┐       ┌─────────┐       ┌─────────┐
    │ Server A│       │ Server B│       │ Server C│
    │ 10 req  │       │ 15 req  │       │ 8 req   │
    │ (权重2) │       │ (权重3) │       │ (权重1) │
    └─────────┘       └─────────┘       └─────────┘
```

#### 3.3.2 熔断器模式（Circuit Breaker）

```python
# Python 熔断器实现
import time
from enum import Enum
from functools import wraps

class CircuitState(Enum):
    CLOSED = "closed"      # 正常状态
    OPEN = "open"          # 熔断状态
    HALF_OPEN = "half_open"  # 半开状态

class CircuitBreaker:
    def __init__(self, failure_threshold=5, timeout=60):
        self.failure_threshold = failure_threshold
        self.timeout = timeout
        self.failure_count = 0
        self.last_failure_time = None
        self.state = CircuitState.CLOSED
    
    def call(self, func, *args, **kwargs):
        if self.state == CircuitState.OPEN:
            if time.time() - self.last_failure_time >= self.timeout:
                self.state = CircuitState.HALF_OPEN
            else:
                raise Exception("Circuit breaker is OPEN")
        
        try:
            result = func(*args, **kwargs)
            self._on_success()
            return result
        except Exception as e:
            self._on_failure()
            raise e
    
    def _on_success(self):
        self.failure_count = 0
        self.state = CircuitState.CLOSED
    
    def _on_failure(self):
        self.failure_count += 1
        self.last_failure_time = time.time()
        if self.failure_count >= self.failure_threshold:
            self.state = CircuitState.OPEN

# 使用示例
breaker = CircuitBreaker(failure_threshold=3, timeout=30)

@wraps(some_function)
def resilient_function(*args, **kwargs):
    return breaker.call(some_function, *args, **kwargs)
```

#### 3.3.3 限流策略

```python
import time
from collections import defaultdict
from threading import Lock

class RateLimiter:
    def __init__(self, max_requests, window_seconds):
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self.requests = defaultdict(list)
        self.lock = Lock()
    
    def is_allowed(self, key):
        with self.lock:
            now = time.time()
            # 清理过期请求记录
            self.requests[key] = [
                req_time for req_time in self.requests[key]
                if now - req_time < self.window_seconds
            ]
            
            if len(self.requests[key]) < self.max_requests:
                self.requests[key].append(now)
                return True
            return False

# 使用示例
limiter = RateLimiter(max_requests=100, window_seconds=60)

def rate_limit(key):
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            if not limiter.is_allowed(key):
                return {"error": "Rate limit exceeded"}, 429
            return func(*args, **kwargs)
        return wrapper
    return decorator

@app.route("/api/data")
@rate_limit("api_data")
def get_data():
    return {"data": "..."}
```

---

## 总结

### 全栈架构知识图谱

```
全栈架构与DevOps
├── 全栈架构模式
│   ├── SSR/CSR/SSG（渲染策略）
│   ├── BFF（Backend For Frontend）
│   └── 微前端（Module Federation）
│
├── 部署与DevOps
│   ├── Docker（容器化）
│   ├── Kubernetes（编排）
│   ├── CI/CD（自动化流水线）
│   └── 云原生（12要素）
│
└── 架构设计模式
    ├── 前端设计模式（观察者、装饰器）
    ├── 后端设计模式（DI、Repository）
    └── 分布式系统（负载均衡、熔断、限流）
```

---

*文档版本：2024.12*

---

> 本内容由 Coze AI 生成，请遵循相关法律法规及《人工智能生成合成内容标识办法》使用与传播。
