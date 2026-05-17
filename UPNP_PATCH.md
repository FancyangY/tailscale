# UPnP portmapper patch

这个 fork 保留一组很小的 UPnP 兼容性修改，用来解决部分 Windows + 家用网关环境下 `tailscale netcheck` 看不到 UPnP，或后台没有自动创建 UPnP 映射的问题。

## 现象

在 Huawei ATP IGD 网关上，网关会响应 SSDP/UPnP，但响应时间略晚于上游 Tailscale 默认的 `250ms` 探测窗口。Windows 上把 UDP socket 绑定到 `0.0.0.0` 时，也可能收不到这类回复。

## 代码修改

核心修改保存在 [patches/upnp-portmapper.patch](patches/upnp-portmapper.patch)：

- `net/portmapper/portmapper.go`
  - `portMapServiceTimeout` 从 `250ms` 调整到 `1000ms`
  - `Probe` 里的 UDP socket 优先绑定到检测出的本机 LAN IP；如果绑定失败，再回退到 `:0`
- `net/portmapper/upnp.go`
  - 后台创建 UPnP 映射时，如果没有已有 UPnP discovery metadata，会先调用 `Probe`

## 自动同步和构建

[.github/workflows/upnp-patched-release.yml](.github/workflows/upnp-patched-release.yml) 每天检查一次 `tailscale/tailscale` 的 latest release。修改补丁、脚本或 workflow 并推送到 `main` 时也会跑一次。

如果发现上游有新 release，workflow 会：

1. clone 上游 release tag
2. 应用 `patches/upnp-portmapper.patch`
3. 推送 `upnp/<upstream-tag>` 分支和 `upnp-<upstream-tag>` tag 到这个 fork
4. 编译 Windows amd64 的 `tailscale.exe` 和 `tailscaled.exe`
5. 打包 `install.ps1`、`restore.ps1`、`verify.ps1`、README 和补丁文件
6. 创建 GitHub Release，并上传 zip 与 sha256 文件

也可以在 GitHub Actions 页面手动运行 `UPnP patched Windows release`，指定上游 tag，例如 `v1.96.4`。
