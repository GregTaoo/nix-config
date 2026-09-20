# 一次 AMD + NVIDIA 混合显卡 Wayland 显示故障的分层排查

本文记录 ASUS TUF Gaming A14 FA401WV 在 NixOS、Wayland、Hyprland、
KDE Plasma 与 NVIDIA/AMD 混合显卡环境中的显示故障。

最初症状是：外接显示器只显示桌面的右下区域，桌面左上角落在物理屏幕中心，
但鼠标指针位置正常。完整 Plasma 会话启动一次后，再进入 Hyprland 又会恢复。

排查最终发现，这不是一个 bug，而是以下几层问题叠加：

1. 笔记本显示接口的物理布线决定了混合模式必然跨 GPU。
2. 冷启动时，跨 GPU framebuffer 的 primary plane 扫描输出异常。
3. 完整 Plasma/KScreen 会重置 DRM 状态，掩盖了第二层问题。
4. 切换硬件 MUX 后，DRM card 和 connector 名称发生变化。
5. SDDM 的 KWin Wayland greeter 在 dGPU-only 下创建 framebuffer 失败。
6. 一条包含冒号的 DRM by-path 被错误解析成三个设备。

此外，Deskflow 的 Wayland InputCapture 失败是另一条独立链路：普通 Hyprland
会话没有激活 systemd graphical session，导致 portal 无法启动。

## 1. 复现环境

所有结论都基于以下固定版本。升级任意一层后，结果可能发生变化。

### 硬件

| 项目 | 型号或版本 |
|---|---|
| 笔记本 | ASUS TUF Gaming A14 FA401WV |
| BIOS | FA401WV.319，2025-03-25 |
| CPU/iGPU | AMD Strix，Radeon 880M/890M，PCI `0000:65:00.0` |
| dGPU | NVIDIA GeForce RTX 4060 Laptop，PCI `0000:64:00.0` |
| 外接屏 | ViewSonic VX2780-2K-PRO，2560x1440 |
| 外接方式 | 笔记本实体 HDMI |

PCI ID：

```text
NVIDIA: 10de:28e0
AMD:    1002:150e
```

### 软件

| 组件 | 固定版本 |
|---|---|
| NixOS | 26.11 Zokor，build `26.11.20260911.eaad089` |
| nixpkgs | `eaad089433ca2bb662274377d33df3d0e51ef28b` |
| home-manager | `cfcda3f99334c8459fa4cd46cce87502e0b48f0a` |
| Linux | 6.18.51 |
| NVIDIA 驱动 | 595.99.02，专有内核模块 |
| Mesa | 26.2.2 |
| libdrm | 2.4.134 |
| Hyprland | 0.56.2，commit `efb50993780079460b0cbed1363e2166a2de1d9f` |
| Aquamarine | 0.15.0 |
| KDE Plasma/KWin | 6.7.5 |
| SDDM | 0.21.0 |
| UWSM | 0.26.7 |
| xdg-desktop-portal | 1.22.1 |
| xdg-desktop-portal-hyprland | 1.4.1 |
| Deskflow | 1.26.0 |

版本采集命令：

```sh
uname -a
cat /etc/os-release
nvidia-smi --query-gpu=name,driver_version --format=csv,noheader
readlink -f /run/current-system/sw/bin/Hyprland
readlink -f /run/current-system/sw/bin/kwin_wayland
readlink -f /run/current-system/sw/bin/sddm
readlink -f /etc/profiles/per-user/gregtao/bin/deskflow
rg -n '"(nixpkgs|home-manager|rev|narHash|lastModified)"' flake.lock
```

## 2. 图形栈模型

应用不直接把像素写进显示器。实际路径是：

```text
Wayland 应用 buffer
  -> compositor 合成
  -> final framebuffer
  -> DRM/KMS primary plane
  -> GPU display engine
  -> HDMI / DP / eDP
```

KMS 提交的关键状态包括：

```text
FB_ID
SRC_X / SRC_Y / SRC_W / SRC_H
CRTC_X / CRTC_Y / CRTC_W / CRTC_H
format / modifier / stride / offset
```

鼠标一般走独立的 hardware cursor plane：

```text
桌面 -> primary plane
鼠标 -> cursor plane
```

因此“桌面错位但鼠标正常”是重要证据：显示器坐标和鼠标输入不一定有问题，
错误更可能位于 primary framebuffer 的 import、plane 或 scanout。

## 3. 原始问题的最小复现

> 以下步骤会切换 GPU MUX。只应在 SSH 已验证可用、并知道回退命令时执行。

### 3.1 切换到混合模式

```sh
sudo sh -c 'printf 1 > /sys/devices/platform/asus-nb-wmi/gpu_mux_mode'
sudo reboot
```

确认：

```sh
cat /sys/devices/platform/asus-nb-wmi/gpu_mux_mode
```

预期为 `1`。

### 3.2 确认混合模式拓扑

```sh
for f in /sys/class/drm/*/status; do
  printf '%s: ' "${f%/status}"
  cat "$f"
done
```

本机曾观察到：

```text
AMD eDP-1:       connected
NVIDIA HDMI-A-1: connected
NVIDIA eDP-2:    disconnected
```

### 3.3 冷启动直接进入 Hyprland

保持 HDMI 外屏连接，重启后不进入 Plasma，直接进入普通 Hyprland 会话。

故障表现：

- 外屏桌面向右下偏移；
- 桌面左上角对应物理屏幕中心附近；
- 鼠标指针位置正常；
- Hyprland 报告的输出坐标仍为 `0,0`。

查看 compositor 状态：

```sh
hyprctl -j monitors all
```

### 3.4 对照实验：截图

```sh
XDG_RUNTIME_DIR=/run/user/1000 \
WAYLAND_DISPLAY=wayland-1 \
grim /tmp/hypr-compositor.png

identify /tmp/hypr-compositor.png
```

实验截图为完整 `2560x1440`，且内容完整，而实体输出仍错位。

这说明：

```text
应用布局正确
compositor 合成正确
截图读取正确
compositor 之后的 scanout 错误
```

### 3.5 对照实验：先进入 Plasma

1. 冷启动进入完整 Plasma Wayland。
2. 注销 Plasma。
3. 不重启，进入 Hyprland。

本机结果：Hyprland 外屏恢复正常，直到下一次冷启动。

这说明完整 Plasma 启动过程中有动作重新初始化了输出状态。

## 4. 第一层：物理布线约束

### 观察

```sh
lspci -nnk | rg -A4 -B1 'VGA compatible|Display controller'
```

混合模式下：

```text
AMD Radeon 890M
  -> eDP-1 内屏

NVIDIA RTX 4060
  -> HDMI-A-1 外屏
```

### 推理

实体 HDMI 固定连接 NVIDIA display engine。软件不能把该 connector 移到 AMD。

当 compositor 选择 AMD 作为 render GPU，而外屏连接 NVIDIA 时，必须经过：

```text
AMD 渲染
  -> DMA-BUF export
  -> NVIDIA import 或 blit
  -> NVIDIA HDMI scanout
```

### 结论

物理布线不是 bug，但它创造了跨 GPU framebuffer 问题的必要条件。

要让 AMD 直接驱动外屏，应在混合模式下使用机身左侧 USB4 Type-C 的
DisplayPort，而不是实体 HDMI。该映射仍应通过插拔 DRM connector 最终确认。

## 5. 第二层：跨 GPU primary framebuffer 异常

### 假设

AMD 导出的 framebuffer 在 NVIDIA import/scanout 时，format、modifier、stride、
offset 或 source rectangle 中至少有一项被错误解释。

### 支持证据

1. compositor 截图正常；
2. 实体 scanout 错位；
3. hardware cursor plane 正常；
4. 修改 Hyprland 全局坐标没有改变物理偏移；
5. 修改缩放和刷新率没有改变物理偏移。

### 坐标反证

```sh
hyprctl eval "hl.monitor({ output = 'HDMI-A-1', position = '-1024x-576' })"
```

唯一输出会被 Hyprland 重新归一化为 `0,0`，实体偏移不变。

### 缩放/刷新率反证

以下组合均复现同样问题：

```text
2560x1440 @ 143.981 Hz, scale 1.25
2560x1440 @ 143.981 Hz, scale 1.0
2560x1440 @ 59.95 Hz,  scale 1.0
```

### 结论边界

可以确定故障在 compositor 合成之后、物理 scanout 之前。

尚不能仅凭这些证据确定是 Aquamarine、NVIDIA 用户态驱动、nvidia_drm，还是
两者对 DMA-BUF modifier 的组合兼容问题。定位到具体源码需要记录 KMS atomic
state 和 DMA-BUF format/modifier，并与 KWin 正常路径对比。

## 6. 第三层：完整 Plasma/KScreen 重置 DRM 状态

### 观察

完整 Plasma Wayland 正常；SDDM 精简 KWin greeter 和冷启动 Hyprland 异常。

### 差异

完整 Plasma 不只有 KWin：

```text
KWin compositor
Plasma Workspace
KScreen
完整 output configuration
用户保存的显示器配置
```

KScreen 会重新选择 mode、scale、position、priority，并提交完整 atomic modeset。

### 推理

Plasma 启动后，DRM connector、CRTC 和 primary plane 被重新绑定。该状态在
Plasma 退出后没有立刻丢失，随后启动的 Hyprland 继承了正常硬件状态。

### 结论

“先进入 KDE 就正常”不是 KDE 改变了硬件布线，而是完整 Plasma/KScreen
重置了显示控制器状态。

## 7. 第四层：MUX 切换导致设备身份变化

### 切换 dGPU-only

```sh
sudo sh -c 'printf 0 > /sys/devices/platform/asus-nb-wmi/gpu_mux_mode'
sudo reboot
```

### 观察

```text
NVIDIA: card0 -> card2
内屏:   eDP-1 -> eDP-2

card2-HDMI-A-1: connected
card2-eDP-2:    connected
card1-eDP-1:    disconnected
```

### 原因

- `cardN` 由 DRM 驱动注册顺序决定，不是稳定硬件 ID；
- MUX 把内屏链路从 AMD display engine 切到 NVIDIA display engine；
- 同一物理面板因此会在不同 GPU 下显示成不同 connector 名称。

### 修复

按稳定 PCI 地址 `0000:64:00.0` 创建不含冒号的 udev 别名：

```nix
services.udev.extraRules = ''
  SUBSYSTEM=="drm", KERNEL=="card[0-9]*", KERNELS=="0000:64:00.0", SYMLINK+="dri/nvidia-card"
'';
```

```sh
readlink -f /dev/dri/nvidia-card
```

当前结果：

```text
/dev/dri/nvidia-card -> /dev/dri/card2
```

## 8. 第五层：SDDM KWin Wayland 的 framebuffer 失败

### 复现

在 dGPU-only 模式启用：

```nix
services.displayManager.sddm.wayland.enable = true;
services.displayManager.sddm.wayland.compositor = "kwin";
```

重建并重启 display-manager：

```sh
sudo nixos-rebuild switch --flake .#GregTaoLaptop
sudo systemctl restart display-manager
```

### 观察

内核确认两块 NVIDIA 输出 connected，但日志包含：

```text
GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT
<image> and <target> are incompatible
Applying output configuration failed
There are no outputs - creating placeholder screen
```

```sh
journalctl -b -u display-manager --no-pager
journalctl -b --no-pager | rg -i 'framebuffer|kwin|sddm|nvidia|drm'
```

### 推理

connector 和 KMS 都存在，失败发生在 KWin greeter 的 OpenGL/EGL framebuffer
attachment 阶段。这与“没有屏幕”不同。

### 修复

```nix
services.displayManager.sddm.enable = true;
services.displayManager.sddm.enableHidpi = false;
services.displayManager.sddm.wayland.enable = false;
```

Plasma NixOS 模块可能默认开启 Wayland greeter，因此仅删除配置块不够，必须
显式赋值 `false`。SDDM 使用 X11 不影响登录后的 Wayland 会话。

## 9. 第六层：冒号分隔符导致 DRM 路径失效

### 错误配置

```text
KWIN_DRM_DEVICES=/dev/dri/by-path/pci-0000:64:00.0-card
```

`KWIN_DRM_DEVICES` 和 `AQ_DRM_DEVICES` 使用冒号分隔多个设备。该路径被解析为：

```text
/dev/dri/by-path/pci-0000
64
00.0-card
```

### 证据

```text
Failed to open drm device /dev/dri/by-path/pci-0000
Failed to open drm device 64
Failed to open drm device 00.0-card
No suitable DRM devices have been found
```

随后 compositor 崩溃，屏幕只停留在 `Reached target Graphical Interface`。
`graphical.target` 到达不代表 display-manager 的 greeter 成功渲染。

### 修复

```nix
environment.sessionVariables = {
  AQ_DRM_DEVICES = "/dev/dri/nvidia-card";
  KWIN_DRM_DEVICES = "/dev/dri/nvidia-card";
};
```

该配置只属于这台 laptop，不能放进共享 Hyprland 模块。

## 10. 失败实验与原因

### `mode = "disable"`

Hyprland 0.56.2 Lua monitor API 中，`mode` 只接受显示模式。正确字段是：

```lua
disabled = true
```

### `hyprctl keyword monitor ...`

Lua config provider 不支持 legacy `keyword` 修改。运行时修改需要：

```sh
hyprctl eval "hl.monitor({ ... })"
```

### `AQ_NO_MODIFIERS=1`

该设置禁用范围过大，实验结果是外屏无画面，已经撤回。

若以后研究混合 GPU，更有针对性的候选是：

```text
AQ_FORCE_LINEAR_BLIT=1
```

它让多 GPU copy 使用通用 linear buffer，避免目标 GPU 错误解释 tiled modifier。
代价是额外复制、带宽和功耗。当前 dGPU-only 不需要该选项。

### 只删除 SDDM Wayland 配置

Plasma 模块仍可能通过默认值启用它，必须显式设置：

```nix
services.displayManager.sddm.wayland.enable = false;
```

## 11. 当前显示方案

当前采用 dGPU-only：

```text
NVIDIA
├── HDMI-A-1 外屏
└── eDP-2 内屏
```

Hyprland 配置：

```lua
hl.monitor({
    output   = "HDMI-A-1",
    mode     = "highrr",
    position = "0x0",
    scale    = "1.25",
})

hl.monitor({
    output   = "eDP-2",
    mode     = "preferred",
    position = "2048x0",
    scale    = "auto",
})
```

外屏 `2560 / 1.25 = 2048` 个逻辑像素宽，因此内屏从 `2048x0` 开始。

## 12. Deskflow：独立的第七层问题

Deskflow server 使用 TCP `24800`：

```nix
networking.firewall.allowedTCPPorts = [ 24800 ];
```

Wayland 输入捕获还依赖：

```text
Deskflow
  -> org.freedesktop.portal.Desktop
  -> xdg-desktop-portal-hyprland
  -> InputCapture
```

已安装的 `xdg-desktop-portal-hyprland 1.4.1` 声明支持 InputCapture。

```nix
xdg.portal = {
  enable = true;
  extraPortals = with pkgs; [
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
  ];
  config.hyprland.default = [ "hyprland" "gtk" ];
};
```

Deskflow 的决定性错误是：

```text
Could not activate remote peer 'org.freedesktop.portal.Desktop'
failed to initialize input capture session
```

普通 Hyprland session 中：

```sh
systemctl --user is-active graphical-session.target
systemctl --user is-active xdg-desktop-portal.service
systemctl --user is-active xdg-desktop-portal-hyprland.service
```

三者均为 `inactive`，日志报告 `Current graphical user session is inactive`。

NixOS 推荐的 UWSM 集成：

```nix
programs.hyprland.withUWSM = true;
services.displayManager.defaultSession = "hyprland-uwsm";
```

必须在 SDDM 中实际选择 `Hyprland (UWSM)`。SDDM 可能记住旧选择，
`defaultSession` 不一定覆盖历史选择。

`failed to prevent/enable system idle sleep` 只是休眠抑制警告；导致 Deskflow core
退出的是 InputCapture portal 初始化失败。

## 13. 物理接口与 PCI 拓扑

ASUS 官方手册 `0409_E25280_FA401W_U_V2_A.pdf` 给出的接口布局：

```text
右侧：microSD、USB-C 3.2 Gen 2（DP）、USB-A 3.2 Gen 2
左侧：DC、HDMI 2.1、USB4-C（DP/PD）、USB-A 3.2 Gen 2、3.5mm
```

当前 USB sysfs：

```text
3-1     GenesysLogic USB 2.1 Hub
3-1.1   Compx MpandaMouse
3-1.2   ATK Z87 keyboard
4-1     GenesysLogic USB 3.1 Hub
4-1.4   ASIX AX88179A USB Ethernet
```

host controller 是 `0000:67:00.0`，同一 PCI 分支还有
`0000:67:00.5 AMD USB4 Router 0`。因此当前 Hub 很可能连接左侧 USB4-C，
但仍需物理插拔确认。

若要让内外屏都由 AMD 直接驱动：

1. 切回 `gpu_mux_mode=1`；
2. 移除强制 NVIDIA 的 DRM device 环境变量；
3. 使用左侧 USB4-C 转 DP/HDMI；
4. 验证 connected connector 属于 `amdgpu`。

```sh
for f in /sys/class/drm/card*-DP-*/status; do
  printf '%s: ' "${f%/status}"
  cat "$f"
done

rg '^(DRIVER|PCI_SLOT_NAME|PCI_ID)=' /sys/class/drm/cardN/device/uevent
```

预期包含：

```text
DRIVER=amdgpu
PCI_SLOT_NAME=0000:65:00.0
```

USB 数据控制器归属不能直接证明 USB-C 视频信号归属。USB 数据、DP Alt Mode
和 USB-PD 是同一 Type-C 物理接口中的不同链路。

## 14. 安全恢复与验证

```sh
sudo nixos-rebuild switch --flake .#GregTaoLaptop
sudo systemctl restart display-manager
```

重启 display-manager 会终止图形会话，但不会终止已有 SSH。

检查当前状态：

```sh
cat /sys/devices/platform/asus-nb-wmi/gpu_mux_mode
readlink -f /dev/dri/nvidia-card
hyprctl -j monitors all
systemctl --user is-active graphical-session.target
systemctl --user is-active xdg-desktop-portal.service
systemctl --user is-active xdg-desktop-portal-hyprland.service
ss -ltn | rg ':24800\b'
```

紧急切回混合模式：

```sh
sudo sh -c 'printf 1 > /sys/devices/platform/asus-nb-wmi/gpu_mux_mode'
sudo reboot
```

回退整个 NixOS generation：

```sh
sudo nixos-rebuild switch --rollback
sudo reboot
```

## 15. 已验证事实与未验证假设

### 已验证

- HDMI connector 属于 NVIDIA。
- 混合模式内屏属于 AMD；dGPU-only 内屏属于 NVIDIA。
- compositor 截图正常而实体 primary plane 错位。
- 鼠标 hardware cursor plane 正常。
- 60/144Hz 与 100/125% 不改变原始偏移。
- 完整 Plasma 后再进入 Hyprland 会恢复。
- dGPU-only 后两块输出都连接 NVIDIA。
- SDDM KWin Wayland 出现 framebuffer incomplete attachment。
- PCI by-path 中冒号被 DRM device list 当作分隔符。
- `/dev/dri/nvidia-card` 能稳定指向当前 NVIDIA card。

### 仍属推断或待验证

- 原始偏移由哪一层错误解释 modifier/stride/offset，尚未定位到源码。
- 完整 Plasma 中具体哪次 KScreen atomic commit 修正状态，尚未 trace。
- 左侧 USB4 DisplayPort 高度可能属于 AMD，但仍需混合模式逐口实测。
- `AQ_FORCE_LINEAR_BLIT=1` 是否修复本机混合模式，尚未测试。
- UWSM 登录后 Deskflow portal 是否全部 active，尚待实际验证。

## 16. 后续源码级定位

向 Aquamarine/NVIDIA 提交高质量 bug 需要在混合模式采集：

1. render GPU 与 scanout GPU；
2. DMA-BUF format、modifier、plane count、stride、offset；
3. DRM atomic commit 中 primary plane 的 `SRC_*` 与 `CRTC_*`；
4. 完整 Plasma 正常前后的 KMS state 差异；
5. `AQ_FORCE_LINEAR_BLIT=1` 的 A/B 结果；
6. KWin 与 Aquamarine 对 format/modifier intersection 的选择差异。

在没有这些 trace 前，最准确的表述是“跨 GPU framebuffer scanout 兼容问题”，
不能把责任武断归结为某一个具体项目。
