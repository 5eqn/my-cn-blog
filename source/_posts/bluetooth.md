---
title: Win11 + Arch 双系统蓝牙配对折腾日记
date: 2025-01-07 20:43:17
tags:
- 编程
- Linux
---

## 问题

先在 Arch 上用配对罗技 K380 键盘的第一频道，再在 Win11 上配对第三频道。重新打开 Arch，尝试配对时指示灯闪烁约 0.5 秒后就常灭，怀疑内部出错。

## 解决方案

先在 Win11 上配对键盘，然后使用键盘的同一频道在 Arch 上配对。在 Arch 配对后，键盘的配对密钥会改变，下面的目标就是让 Win11 主机知道新的这个密钥。

[Arch Wiki](https://wiki.archlinux.org/title/Bluetooth#Dual_boot_pairing) 有详细文档，不过 K380 键盘的密钥结构相对简单。在 Arch 上执行

```
sudo cat /var/lib/bluetooth/{HostAddr}/{DeviceAddr}/info
```

其中 `{HostAddr}` 是本机的 MAC 地址，一般只有一个所以不用刻意去找。`{DeviceAddr}` 是设备的 MAC 地址，如果连上了设备你大概率知道它的 MAC 地址，不知道的话在 `bluetoothctl` 里执行 `scan on` 也能根据扫描结果确定设备的 MAC 地址。

执行上述命令后会看到类似于下面的东西：

```
[General]
Name=Keyboard K380
Class=0x000...
SupportedTechnologies=BR/EDR;
Trusted=true
Blocked=false
WakeAllowed=true
Services=0000...;0000...;0000...;

[LinkKey]
Key=51121...
Type=5
PINLength=0

[DeviceID]
Source=...
Vendor=...
Product=...
Version=...
```

记住这个密钥，切换到 Win11 上下载 [PsExec.exe](https://docs.microsoft.com/en-us/sysinternals/downloads/psexec)，使用管理员权限 Powershell 执行：

```
.\PsExec.exe -s -i regedit.exe
```

找到 `HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\BTHPORT\Parameters\Keys\{DeviceAddr}`，在这里把配对密钥替换成上面记住的密钥即可。

## 补充

理论上 Windows 配对完后把 Linux 的密钥替换成 Windows 上的密钥也可以，但我尝试一次失败了，原因未知。

我调好之后才看到 Arch Wiki 上有讲（虽然处理方法和我不太一样），再一次体会到 Arch Wiki 包罗万象！