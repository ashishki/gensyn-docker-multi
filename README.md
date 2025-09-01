# Gensyn RL-Swarm Multi-Node Docker Toolkit

## ⚡ 安装docker
```bash
 curl -fsSL https://test.docker.com -o test-docker.sh
 sudo sh test-docker.sh
 ```

## ⚡ 快速开始

```bash
# 1) 克隆仓库
git clone https://github.com/ashishki/gensyn-docker-multi.git
cd gensyn-docker-multi

# 2) 生成多节点目录与 Compose（示例：3 节点）
./prepare-nodes.sh 3

# 3) 放置登录密钥（来自官方首次设置流程）
cp your-keys/userApiKey.json data/node1/modal-login/temp-data/
cp your-keys/userData.json   data/node1/modal-login/temp-data/
# 如需更多节点，按需复制到 node2、node3 ...

# 4) 本地构建镜像
docker compose build

# 5) 启动节点（CPU 默认）
docker compose up -d 

# 6) 查看日志
docker compose logs -f
```



### 🚀 容器管理（Container Management）
```bash
# 生命周期
docker compose up -d                 # 启动所有服务
docker compose up -d node1           # 启动指定节点
docker compose restart node2         # 重启指定节点
docker compose stop node3            # 停止指定节点
docker compose down                  # 停止全部（保留数据卷）
docker compose down -v               # 停止全部并清理数据卷

# 弹性伸缩
docker compose up -d --scale node1=0 # 临时停用 node1
```

### 🗺️ 监控与排障（Monitoring & Troubleshooting）
```bash
# 实时日志
docker compose logs -f                    # 全部节点
docker compose logs -f node1             # 指定节点
docker compose logs --since="1h" node2   # 时间范围过滤

# 性能监控
docker stats                              # 资源使用
docker compose top                        # 进程概览

# 健康检查
docker compose ps                         # 容器状态
netstat -tlnp | grep 38331               # 端口占用检查
```

### 🛠️ 维护（Maintenance）
```bash
# 更新
docker compose pull          # 拉取最新镜像
docker compose up -d         # 滚动重启
docker system prune -a       # 清理无用资源

# 备份
mkdir -p backups/$(date +%Y%m%d)
cp -r data/ identities/ backups/$(date +%Y%m%d)/
```

## 🔥 高级配置

### 生成的 docker-compose.yml 结构（示例）

工具会生成类似如下的优化配置：

```yaml
services:
  node1:
    image: gensyn-node:local
    container_name: gensyn-test1
    environment:
      - P2P_PORT=38331
      - CPU_ONLY=1
      - NON_INTERACTIVE=1
      - JOIN_TESTNET=true
      - DISABLE_MODAL_LOGIN=1
      - DISABLE_HF_PUSH=1
      - SWARM=A
      - PARAM_B=0.5
    ports:
      - "38331:38331"
    volumes:
      - "./data/node1/modal-login/temp-data:/opt/rl-swarm/modal-login/temp-data"
      - "./identities/node1/swarm.pem:/opt/rl-swarm/swarm.pem"
    restart: on-failure
    cpuset: "0-19"           # 独占 CPU 核心
    deploy:
      resources:
        limits:
          cpus: "20.0"       # CPU 限额
    dns: [8.8.8.8, 1.1.1.1]
```

## ⚙️ 非交互模式与环境变量

本工具默认以非交互模式运行容器。可用变量如下（Compose 已自动注入合理默认）：

- `NON_INTERACTIVE=1`：启用非交互模式
- `JOIN_TESTNET=true|false`：是否连接 Testnet（默认 true）
- `SWARM=A|B`：加入 Math(A) 或 Math Hard(B)（默认 A）
- `PARAM_B=0.5|1.5|7|32|72`：选择模型规模（默认 0.5）
- `DISABLE_MODAL_LOGIN=1`：禁用登录 UI，直接 P2P（默认 1）
- `DISABLE_HF_PUSH=1`：禁用将模型推送到 HF（默认 1）
- `CPU_ONLY=1`：仅 CPU 训练（默认 1）
- `P2P_PORT`：对外 P2P 端口（按节点自增）

如需 GPU，请移除 `CPU_ONLY` 并确保主机具备 NVIDIA 驱动与运行时，且满足 rl-swarm GPU 依赖要求。

## 📌 指定 rl-swarm 版本

构建时可通过构建参数指定某一官方发布版本，例如 `v0.5.8`：

```bash
# PowerShell
$env:RL_SWARM_REF="v0.5.8"; docker compose build; docker compose up -d

# Linux/macOS
export RL_SWARM_REF=v0.5.8
docker compose build && docker compose up -d
```

如需使用其他 fork 或分支，可设置：

```bash
$env:RL_SWARM_REPO="https://github.com/gensyn-ai/rl-swarm"
$env:RL_SWARM_REF="main"
docker compose build && docker compose up -d
```
