## 使用方法

### 方式 1：双击运行（推荐）

直接双击 `D:\Source\quantdinger\start-quantdinger.bat`

### 方式 2：PowerShell 运行

```powershell
cd D:\Source\quantdinger
.\start-quantdinger.ps1
```

### 停止所有服务

```powershell
.\start-quantdinger.ps1 -Stop
```

## 文件位置

- **启动脚本**: `D:\Source\quantdinger\start-quantdinger.ps1`
- **快捷启动**: `D:\Source\quantdinger\start-quantdinger.bat`（双击运行）

## 脚本功能

1. ✅ 检查 Docker 是否运行
2. ✅ 启动 PostgreSQL 和 Redis 容器
3. ✅ 启动 Python 后端
4. ✅ 启动前端容器
5. ✅ 健康检查（验证所有服务正常）
6. ✅ 支持停止所有服务（`-Stop` 参数）