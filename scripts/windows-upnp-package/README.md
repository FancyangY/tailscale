# Tailscale UPnP patched Windows package

这个包是从本仓库 GitHub Actions 自动生成的 Windows amd64 修改版 Tailscale。

## 修复内容

针对部分网关，尤其是这次遇到的 Huawei ATP IGD：

- UPnP/PCP/PMP 探测等待时间从 `250ms` 调整到 `1000ms`
- `netcheck`/portmapper 探测 socket 优先绑定到检测出的本机 LAN IP；如果绑定失败，再回退到 `0.0.0.0`
- 后台创建 UPnP 映射时，如果之前没有跑过 `tailscale netcheck`，会先主动做一次 UPnP 发现

## 安装

用管理员 PowerShell 进入解压后的目录，然后执行：

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\install.ps1
```

安装脚本会：

- 备份当前 `C:\Program Files\Tailscale` 里的关键文件到 `C:\ProgramData\TailscalePatchedBackups\<timestamp>`
- 停止 Tailscale 服务
- 替换 `tailscale.exe` 和 `tailscaled.exe`
- 重启 Tailscale 服务
- 执行 `tailscale set --auto-update=false`，避免官方自动更新覆盖修改版
- 执行一次 `tailscale netcheck`

## 验证

```powershell
.\verify.ps1
```

重点看三件事：

- `tailscale netcheck` 输出里有 `PortMapping: UPnP`
- `tailscale debug portmap --type upnp --duration 5s --log-http` 有 `successfully obtained mapping ... type=upnp`
- `tailscale status --json` 的本机 endpoints 里出现公网 IP:端口

`tailscale ping` 仍然可能走 DERP，因为直连还取决于对端设备和对端网络的 NAT 情况。本机 UPnP 生效不等于任意两个节点一定都能直连。

## 恢复

用管理员 PowerShell 执行：

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\restore.ps1
```

恢复脚本会使用 `C:\ProgramData\TailscalePatchedBackups` 下最新的一份备份。

## 注意

这个包不是 Tailscale 官方签名安装包，Windows 可能提示未知发布者。
