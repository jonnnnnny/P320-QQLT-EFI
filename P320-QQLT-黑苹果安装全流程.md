# P320 Tiny + QQLT 黑苹果安装全流程

> 目标：联想 ThinkStation P320 Tiny（10MYS06B1M，主板 310C / Q270，魔改 BIOS）+ QQLT（9750H 转接 ES，6 核 12 线程，UHD 630）装 **macOS Sequoia 15**，与现有 Win10 Pro 22H2 分盘双系统。
> EFI 用已交付的 **EFI-P320-QQLT-v2**（OpenCore 1.0.8，ocvalidate 已通过）。本文档是 v2 README 的安装执行版：README 讲"为什么"，这篇讲"先做什么、再做什么"。
> 全程预计 2–3 小时（不含下载时间）。**先通读一遍再动手。**

## 0. 总览：9 个阶段

| 阶段 | 做什么 | 在哪台机器上 |
|---|---|---|
| 1. 准备 | 备齐硬件、软件、EFI | Windows（P320 本机） |
| 2. 填三码 | GenSMBIOS 生成 MacBookPro16,1 四项 | 任意 Windows 电脑 |
| 3. 做安装 U 盘 | macrecovery.py 下官方 Recovery + EFI 上盘 | Windows |
| 4. BIOS 设置 | 逐项对表，拍照备份先 | P320 开机进 BIOS |
| 5. 装系统 | 抹第二块 M.2 → 装 Sequoia | P320 从 U 盘启动 |
| 6. 首检 | 加速 / 有线网 / 声音，三项过关再登 iCloud | macOS 桌面 |
| 7. EFI 落盘 | EFI 从 U 盘拷到 macOS 盘，脱离 U 盘启动 | macOS |
| 8. 收尾 | USB 定制、关自动睡眠、WiFi | macOS |
| 9. 排障 | 出问题按速查表处理 | — |

**三条红线（别碰）：**
- ❌ 不要用网上任何"一键黑苹果 U 盘 / 精简镜像"——只用苹果官方 Recovery（macrecovery.py 拉）+ 本包 EFI。
- ❌ 不要在 BIOS 里点「恢复默认设置（Load Optimized Defaults）」——会清空魔改的 45W 功耗墙等设置。
- ❌ 安装时不要选错目标盘——Windows 在 WDC WDS100T2B0C 1TB 盘上，macOS 只能装另一块 M.2；选错盘 Windows 就没了。

---

## 1. 准备：工具与软件清单

### 1.1 硬件（装机前摆好）

| 东西 | 要求 | 状态 |
|---|---|---|
| U 盘 | ≥8G，里面数据先备份（要格式化） | 自备 |
| 第二块 M.2 | 2280 NVMe（P320 有两个 M.2 2280 槽），容量建议 ≥256G | 已有（多余那块） |
| 网线 | 安装全程必须插网线（安装界面里 WiFi 驱动不了） | 自备 |
| 显示器线 | DP 线接 H27T22（实测 DP 口能出画面） | 已有 |
| 键盘鼠标 | 有线键盘（进 BIOS / OC 菜单最稳），插后置 USB 口 | 自备 |
| 硅脂、散热 | 已涂好、散热器已按对角渐进装好（烤机 45W / 75°C / 2.9GHz 已验证） | ✅ 已完成 |

### 1.2 软件（全部官方源，下载到 Windows 桌面建个 `hackintosh` 文件夹统一放）

| 软件 | 用途 | 下载地址 | 备注 |
|---|---|---|---|
| **macrecovery.py**（OpenCorePkg 自带） | 从苹果官方恢复服务器下载 Sequoia Recovery 镜像 | github.com/acidanthera/OpenCorePkg/releases（1.0.8 发布包内 `Utilities/macrecovery/`） | 需 Python 3，命令行运行 |
| **GenSMBIOS** | 生成 MacBookPro16,1 的三码 | github.com/corpnewt/GenSMBIOS | Windows 运行 `GenSMBIOS.bat`，首次自动装 Python 环境 |
| **Rufus** | U 盘 >32G 时格 FAT32 用 | rufus.ie | U 盘 ≤32G 时资源管理器直接格 FAT32 就行，不用它 |
| **OCAuxiliaryTools（OCAT）** | 图形界面改 config.plist（填三码、改 alcid、开关 kext 都用它） | github.com/ic005k/OCAuxiliaryTools | Windows 版；别用记事本改 plist，容易改坏格式 |
| **HeliPort v1.5.0** | itlwm 的连网工具（选 WiFi SSID 用） | OpenIntelWireless 的 release 页 | 装完系统后用，先拷到 U 盘备用 |
| **Hackintool** | 核显接口校准、看硬件信息 | github.com/headkaze/Hackintool | 装完后用 |
| **USBToolBox 1.2.0** | USB 端口定制（生成自己的 UTBMap） | USBToolBox 的 release 页 | 装完后用，Windows 版也行 |
| **MountEFI** | macOS 里挂载 EFI 分区 | github.com/corpnewt/MountEFI | 装完后用（macOS 里跑） |
| **EFI-P320-QQLT-v2.zip** | 本机 EFI（已校验通过） | 已交付 | 解压后备用 |

> 核对：EFI 解压后应有 `EFI/BOOT/BOOTx64.efi`、`EFI/OC/config.plist`、`EFI/OC/Kexts/`、`EFI/OC/ACPI/`，另有 `README.md`。

---

## 2. 阶段二：填三码（装机前必做，约 10 分钟）

现在 config 里的三码是**占位符，不能直接装机登录 iCloud**：

| config 里的字段 | 现在的值（占位） | 要填成 |
|---|---|---|
| `PlatformInfo > Generic > SystemSerialNumber` | `OEM` | GenSMBIOS 输出的 Serial |
| `PlatformInfo > Generic > MLB` | `GENERATE-YOUR-OWN` | GenSMBIOS 输出的 MLB / Board Serial |
| `PlatformInfo > Generic > SystemUUID` | `OEM` | GenSMBIOS 输出的 SmUUID |
| `PlatformInfo > Generic > ROM` | 空（0 字节） | GenSMBIOS 输出的 ROM（6 字节十六进制，直接填 Data 类型） |

**步骤：**

1. 解压 GenSMBIOS，运行 `GenSMBIOS.bat`；
2. 先选「Install/Update MacSerial」（装序列号生成器），完成后再选「Generate SMBIOS」；
3. 机型输入 **MacBookPro16,1**（QQLT 的 9750H 就是这台真 MacBook Pro 2019 的原装 CPU，机型天然对应）；
4. 把输出的四个值用 OCAuxiliaryTools 打开 `EFI/OC/config.plist`，在 `PlatformInfo > Generic` 里逐项填回，保存；
5. （建议）去 checkcoverage.apple.com 查一下生成的序列号：显示「无法验证购买日期 / 未激活」才是可用的；如果能查到真实保修记录，说明撞了真机码，重新生成一组。

> ⚠️ 三码只填这一份 config，填完的 config 就是后面要拷到 U 盘的那份，别填错文件（v1 和 v2 各有一份 config，只动 v2 的）。

---

## 3. 阶段三：做安装 U 盘（Windows 上，约 20 分钟 + 下载时间）

1. U 盘插 Windows 电脑，**先备份 U 盘里的数据**；
2. 在 `macrecovery` 目录打开命令行，运行 `python macrecovery.py -b Mac-937A206F2EE63C01 -m 00000000000000000 download`（拉 Sequoia 15 恢复镜像的固定参数：board-id 对应一台最高只支持到 Sequoia 的机型，`m` 后是 17 个 0）。下载得到的是官方 Recovery 镜像，目录形如 `com.apple.recovery.boot`（里面是 `BaseSystem.dmg` + `BaseSystem.chunklist`，约 600MB）。⚠️ **别用 gibMacOS**：它的 Recovery-Only 模式只认老式 `RecoveryHDUpdate.pkg`/`RecoveryHDMetaDmg.pkg`，Big Sur 之后的系统根本没有这两个包，Sequoia 永远不会出现在那个列表里；直接下的完整安装器 `InstallAssistant.pkg`（15GB）在 Windows 上也做不成启动盘；
3. U 盘格式化成 **FAT32**：资源管理器右键 → 格式化 → 文件系统选 FAT32。U 盘超 32G 时资源管理器不给 FAT32 选项，用 Rufus 格：启动类型选「非可启动」，文件系统选 FAT32（Large FAT32）；
4. 把 gibMacOS 下好的 **`com.apple.recovery.boot` 整个文件夹**拷到 U 盘**根目录**；
5. 把第 2 步填好三码的 **`EFI` 文件夹也拷到 U 盘根目录**（与 `com.apple.recovery.boot` 并列，不要多套一层目录）；
6. （建议）把 `HeliPort.app` 和这份文档也拷到 U 盘根目录备用；
7. **成品结构自检**（U 盘根目录应该长这样，缺一项就别开机）：
   - `EFI\BOOT\BOOTx64.efi`
   - `EFI\OC\config.plist`（三码已填好的那份）
   - `com.apple.recovery.boot\BaseSystem.dmg`
   - `com.apple.recovery.boot\BaseSystem.chunklist`

> ⚠️ 选错恢复镜像的信号：进 OpenCore 菜单显示的是别的系统版本、或提示要连 WiFi 且插网线没反应，多半是 gibMacOS 下错了目录/版本，回第 2 步重下 Sequoia 的 Recovery。

---

## 4. 阶段四：BIOS 设置（开机按 F1 进，逐项对）

**先进 BIOS 先拍照**：把当前每一页设置都拍下来备份（魔改 BIOS 的功耗墙等设置丢了不好找回）。

| 项目 | 设置 | 说明 |
|---|---|---|
| Above 4G Decoding | **开（Enabled）** | 没有这一项也行，config 里 ResizeAppleGpuBars=0 已兜底 |
| CSM | **关（Disabled）** | 纯 UEFI 启动 |
| Secure Boot | **关（Disabled）** | |
| CFG Lock（MSR 0xE2） | **有开关就关** | 魔改 BIOS 里可能没有这一项：没有就不管，config 里两个 CFG Lock quirk 已默认打开兜底；**若 BIOS 能关 CFG Lock，记得回 config 把 Kernel > Quirks 里的 AppleCpuPmCfgLock、AppleXcpmCfgLock 两个都改回 false** |
| 核显显存预留（DVMT Pre-Allocated） | **64M 或更高** | 能设就设 64M+；设不了也不怕，config 已带 unifiedmem 2G 兜底 |
| 主显输出（Primary Display） | 核显（IGD / Onboard） | 机器没独显是默认，只有装了 P600 的才需要改 |
| XHCI Hand-off | 开 | |
| Fast Boot | 关 | 首装期关掉，避免跳过 U 盘引导 |
| Boot Mode | UEFI Only | 与 CSM 关对应 |

改完保存退出（一般是 F10）。**再次提醒：不要点「恢复默认设置」。**

---

## 5. 阶段五：装系统（约 40–60 分钟，重启 3–4 次是正常的）

1. **先装第二块 M.2**：关机断电，打开底盖，把多余的 M.2 装进空着的那个 2280 槽，固定螺丝拧好，合盖；
2. **插好线**：网线插上、DP 线接显示器、有线键盘插后置 USB 口、安装 U 盘插前置 USB 口；
3. 开机，立刻反复按 **F12**（联想启动菜单），选 U 盘的 **UEFI 项**（不是不带 UEFI 的那项）；
4. 进 OpenCore 菜单，选 **Install macOS Sequoia**；
5. 进安装界面后，先别点"安装"：顶部菜单 → **磁盘工具** → 左上角「显示」→「显示所有设备」→ 在左侧选中**第二块 M.2 的物理盘**（认准容量/型号，**绝不能选 WDC WDS100T2B0C 1TB 那块 Windows 盘**）→ 点「抹掉」：名称随便填（如 `macOS`），格式选 **APFS**，方案选 **GUID 分区图** → 抹掉 → 完成 → 退出磁盘工具；
6. 回安装界面点"继续"，同意许可，目标盘选刚抹好的那块 M.2，开始安装；
7. 安装中会自动重启几次：**每次重启后都按 F12 选 U 盘进 OpenCore**，菜单里后几次会出现硬盘上的 **macOS Installer** 条目，选它继续（别再选 U 盘那个 Install 项）；
8. 最后一次重启后进设置向导：选地区、键盘，**先不要登录 Apple ID**（首检完再登），建一个本地管理员账户；
9. 进桌面。

> ⚠️ 安装全程保持网线插着（在线恢复安装要联网），不要拔 U 盘，不要中途断电。

---

## 6. 阶段六：装完首检（三项都过关，再登 iCloud）

| 检查项 | 怎么确认 | 不过关怎么办 |
|---|---|---|
| 画面加速 | 关于本机 → 显示 UHD 630、显存 1536MB+；拖动窗口不卡顿、不撕裂 | 见第 9 节"黑屏"排障 |
| 有线网 | 插网线，系统设置 → 网络 → 以太网显示"已连接"、能自动获取 IP | 见第 9 节"没网"；先确认 BIOS 里网卡没关 |
| 声音 | 播个视频/音乐，喇叭或 3.5mm 耳机有声 | boot-args 里 `alcid` 依次试 11、13、21、15（改完重启），并同步改 `Pci(0x1f,0x3)` 下的 layout-id 为同值；当前 12 是联想 Tiny 平台命中率最高的布局 |

三项都过，再登录 iCloud / App Store。

**同时核对两项 v2 的未验证推断**（Windows 设备管理器里看硬件 ID 也行）：
- 音频 codec 是不是 Realtek ALC294（硬件 ID `VEN_10EC / DEV_0294`）；
- 有线网卡是不是 Intel I219-LM（硬件 ID `VEN_8086 / DEV_15B7`；若是 I219-V 或同系列，IntelMausi 同样覆盖，一般不用改）。

---

## 7. 阶段七：EFI 落盘（脱离 U 盘启动）

1. macOS 里运行 **MountEFI**，挂载 macOS 盘（第二块 M.2）的 EFI 分区；
2. 把 U 盘里的 `EFI` 文件夹**整个拷到 macOS 盘 EFI 分区的根目录**（分区里原来没有 EFI 文件夹，直接拷过去；如果已有，先删旧的再拷）；
3. 拔掉 U 盘，重启，开机按 F12：能看到硬盘的 OpenCore 启动项就说明落盘成功；
4. 进 BIOS → 启动顺序，把 macOS 盘（OpenCore）设为第一启动项，Windows 盘在后；以后开机默认进 OpenCore 菜单，在菜单里选 macOS 或 Windows。

> 此后改任何 EFI 配置（alcid、USB 定制、开关 kext）都改 macOS 盘 EFI 分区里的那份，U 盘那份只作备份。

---

## 8. 阶段八：收尾（必做两项 + WiFi）

### 8.1 USB 定制（必做）

1. 用 **USBToolBox**（Windows 版或 macOS 里）逐个口插拔 U 盘认口，生成自己的 `UTBMap.kext`；
2. 把生成的 `UTBMap.kext` 放进 `EFI/OC/Kexts/`，在 config 的 Kernel > Add 里启用它、禁用 `UTBDefault.kext`（改名同步）；
3. **然后把 Kernel > Quirks > XhciPortLimit 改回 false**。
> 不定制的后果：端口超 15 个上限、部分口无反应、睡眠乱醒。蓝牙也依赖 USB 定制（内建 USB 口要在定制里标 internal/255）。

### 8.2 关自动睡眠（必做）

系统设置 → 节能 → 把自动睡眠关掉/设永不。睡眠是这块板公认的短板（XDCI 秒唤醒通病，EFI 里已放 _PRW 热补丁，但魔改 BIOS + 个体 DSDT 差异不能保证一击命中；很多同平台玩家最终就是关自动睡眠）。24 小时节点用途直接关睡眠最省心。

### 8.3 WiFi

默认启用 **itlwm**（Sequoia 下更稳）：连网靠 **HeliPort** 小工具选 SSID，它在系统里显示为一个"以太网"服务；网卡已确认为 AC 8265，itlwm 原生支持。

想试 **AirportItlwm**（原生 WiFi 菜单体验）：config > Kernel > Add 里把 `itlwm.kext` 的 Enabled 改 false、`AirportItlwm.kext` 改 true，重启。**两者绝不能同时启用。** 注意：AirportItlwm 官方没有 Sequoia 版，本 EFI 里放的是 v2.3.0 的 Sonoma 14.4 构建，在 Sequoia 上可能加载失败——失败就切回 itlwm，别折腾。

---

## 9. 阶段九：排障速查（按这个序，别乱改）

### 9.1 黑屏（过了 OpenCore 菜单就没画面）

v2 实测已确认这颗 QQLT 的核显 DP 输出正常，黑屏大概率是接口映射问题，不是核显本身不亮：
1. 先换另一个物理口（DP ↔ HDMI）再开一次；
2. 只插一根 DP 线开机（双屏先拔掉一个）；
3. 还黑：boot-args 加 `igfxonln=1`（强制点亮所有输出）；
4. 进系统后用 Hackintool 读实际接口，把 config 里 `PciRoot(0x0)/Pci(0x2,0x0)` 下的 framebuffer-conX 占位值改成实测映射（现在只有 con2 按 M910q 老 EFI 的经验预填了 HDMI 类型，其余是占位，上机必校准）；
5. 兜底：给核显加 `device-id` = `923E0000`（0x3E92 伪装）再试——最后手段，实测已证明不需要，优先走上面几步。

### 9.2 卡代码 / 跑码停住

- 卡在 CFG Lock 相关行（如 `...[EB|LD:OFS] Err` 或早期重启）：确认两个 CFG Lock quirk 是 true，或进 BIOS 找 CFG Lock 关掉；
- 卡 `apfs_module_start` / 等待根设备：检查 Above 4G 是否开、XhciPortLimit 是否 true、换个 USB 口（优先后置 USB 2.0 口插安装盘）；
- 早期就重启回 BIOS：怀疑 SSDT-AWAC 与魔改 BIOS 冲突——进 config 的 ACPI > Add 把 `SSDT-AWAC.aml` 那行 Enabled 改 false 再试；其次怀疑散热器没压好导致 CPU 保护（先按烤机清单重装散热器，别急着怀疑 EFI）。

### 9.3 没网 / 没声音 / 睡眠秒醒

- 没网：先确认网线插好、BIOS 里网卡没关；有线不通先看硬件 ID 核对网卡型号（见第 6 节）；WiFi 问题见 8.3。
- 没声音：见第 6 节 alcid 试值表。
- 睡眠秒醒：先关自动睡眠（8.2）；还想试的话 `pmset -g log | grep -i wake` 看唤醒源，是 XDCI 就是 _PRW 补丁没对上板子的实际 DSDT（补丁 SSDT-GPRW-XDCI 已在 EFI 里，但要以实机 DSDT 里真正带 0x6D 的设备为准核对）。

---

## 10. 配置速查表（出问题时知道动哪）

| 配置项 | 值 | 位置 |
|---|---|---|
| 机型 SMBIOS | MacBookPro16,1 | config > PlatformInfo > Generic |
| 三码 | GenSMBIOS 生成后填回（见第 2 节） | 同上 |
| 核显 platform-id | `07009B3E` | `PciRoot(0x0)/Pci(0x2,0x0)` > AAPL,ig-platform-id |
| 核显 device-id | 不设（原生 3E9B） | 同上；黑屏兜底才加 `923E0000` |
| 核显显存 | unifiedmem `00000080`（2G） | 同上 |
| 声卡 layout-id / alcid | 12（备选 11→13→21→15） | `Pci(0x1f,0x3)` layout-id + boot-args alcid |
| 启动参数 | `keepsyms=1 alcid=12` | config > NVRAM > boot-args |
| CFG Lock quirk | AppleCpuPmCfgLock、AppleXcpmCfgLock 均为 true（BIOS 能关 CFG Lock 时改回 false） | config > Kernel > Quirks |
| XhciPortLimit | 装机期 true；USB 定制完成后改 false | config > Kernel > Quirks |
| WiFi 默认 | itlwm 启用 / AirportItlwm 禁用（两者绝不同时启用） | config > Kernel > Add |
| 睡眠补丁 | SSDT-GPRW-XDCI（_PRW 热补丁，源码 .dsl 同目录） | EFI/OC/ACPI/ |
| 可禁用项 | SSDT-AWAC（与魔改 BIOS 冲突时禁用） | config > ACPI > Add |
| 系统版本 | 只升 Sequoia 15.x，**不要升 Tahoe（26）** | — |

### 组件版本（v2，2026-11-14 复核，全部官方最新版）

OpenCore 1.0.8、Lilu 1.7.2、WhateverGreen 1.7.1、VirtualSMC 1.3.8、AppleALC 1.9.8、IntelMausi 1.0.8、NVMeFix 1.1.3、RestrictEvents 1.1.6、itlwm v2.3.0、AirportItlwm v2.3.0（Sonoma 14.4 构建，默认禁用）、IntelBluetoothFirmware + IntelBTPatcher v2.4.0、USBToolBox 1.2.0。

### 已知妥协（装之前先知道）

- 睡眠可能不完美（见 8.2），24 小时节点关自动睡眠即可。
- Intel 无线网卡无苹果生态功能：AirDrop、Handoff、Sidecar、通用剪贴板、Apple Watch 解锁都用不了——这是 itlwm/AirportItlwm 的硬限制，与 EFI 无关；想要这些只能换博通免驱卡（如 BCM94360CS2）。
- 蓝牙基础连接（耳机/鼠标）可用，个别设备配对稳定性看运气；蓝牙依赖 USB 定制。
- 核显接口映射是占位值，上机后用 Hackintool 校准（见 9.1）。
- FaceTime/iMessage 要等三码填好并激活状态正常后才可用，别拿占位码去登。

---

## 11. 动手前检查清单（逐项打勾）

- [ ] 第二块 M.2 已装进空槽、螺丝拧好
- [ ] 三码已用 GenSMBIOS 生成并填进 v2 的 config（不是占位值）
- [ ] 安装 U 盘结构自检通过（EFI + com.apple.recovery.boot 都在根目录）
- [ ] BIOS 已拍照备份，设置已按第 4 节逐项对过，没点"恢复默认设置"
- [ ] 网线已插、DP 线接 H27T22、有线键盘在后置 USB 口
- [ ] Windows 数据有备份（以防选错盘）
- [ ] 知道 Windows 盘是 WDC WDS100T2B0C 1TB，安装时绝不选它
