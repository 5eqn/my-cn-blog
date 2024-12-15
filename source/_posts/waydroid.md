---
title: Waydroid 折腾日记
date: 2024-10-22 15:58:29
tags:
- 编程
- Linux
- Wayland
---

## 前置

用 linux-zen 内核替代原先的 linux 内核：

```sh
paru -S linux-zen
paru -Rs linux
```

记得重新生成 GRUB 启动项：

```sh
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

## 安装和配置

安装 Waydroid 本体：

```sh
paru -S waydroid
```

初始化 Waydroid 的安卓系统，为了支持主流应用，需要启用 GApps：

```sh
sudo waydroid init -s GAPPS
```

下载 Waydroid 脚本：

```sh
git clone https://github.com/casualsnek/waydroid_script
cd waydroid_script
python3 -m venv venv
venv/bin/pip install -r requirements.txt
```

由于我的电脑是 Intel 芯片，使用脚本启用 `libhoudini`：

```sh
sudo venv/bin/python3 main.py install libhoudini
```

如果你需要使用 Root 权限的应用，应取得 Root 权限：

```sh
sudo venv/bin/python3 main.py install magisk
```

为了兼容 HiDPI 屏幕，以及提供 IMEI 信息规避风控，需要配置：

```sh
sudo vim /var/lib/waydroid/waydroid_base.prop
```

```properties
persist.waydroid.width=787.5
persist.waydroid.height=887.5
ro.secure=0 
ro.boot.hwc=GLOBAL 
ro.ril.oem.imei=861503068361145 
ro.ril.oem.imei1=861503068361145 
ro.ril.oem.imei2=861503068361148 
ro.ril.miui.imei0=861503068361148 
ro.product.manufacturer=Xiaomi 
ro.build.product=chopin
```

具体的长宽属性请自行计算。IMEI 号等风控相关配置来源于[这篇博客](https://zyhahaha.github.io/redroid.html)。

## 启动

启动守护进程：

```sh
sudo systemctl enable --now waydroid-container
```

启动 Waydroid：

```sh
waydroid session start
```

启动 UI 显示：

```sh
waydroid show-full-ui
```

## 激活 Google Play

为了激活 Google Play，需要获取设备的 `android_id`，然后上传到[注册页面](https://www.google.com/android/uncertified/?pli=1)：

```sh
sudo venv/bin/python3 main.py certified
```

等待大约 10 分钟（我尝试了两次，每次都在 10 分钟内，但部分人在博客中说需要 30 分钟以上甚至数天），然后重启 Waydroid，即可正常使用 Google Play。

## 微信

微信可以通过 Google Play 安装，但安装后请不要清除应用数据，也不要通过官网安装包安装，否则在登录界面尝试修改手机号区域时会卡住。

如果你安装了 Magisk，请安装 [Storage Isolation](https://play.google.com/store/apps/details?id=moe.shizuku.redirectstorage) 并对微信启动！这可以避免微信通过文件系统检查到自己跑在被 root 的环境中，一旦检测到会被封号，可以解封但麻烦。

如果第一次打开微信闪退，就再打开一次。滑条验证加载超过 5 秒钟就刷新。

如果小程序内点击无效，一种大力出奇迹的方法是使用连点器（例如 [Clickmate](https://play.google.com/store/apps/details?id=com.inscode.autoclicker&hl=en&gl=US)），小程序可以读取到连点器的点击事件。

## 清除安装痕迹

如果因为安装错误导致无法正常启动，可以清除安装痕迹后重试：

```
paru -Rs waydroid
sudo rm -rf /var/lib/waydroid ~/waydroid ~/.share/waydroid ~/.local/share/applications/*aydroid* ~/.local/share/waydroid 
```