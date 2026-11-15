# P320 Tiny + QQLT 黑苹果 EFI 使用说明（v2）

- 目标机器：联想 ThinkStation P320 Tiny（机型 10MYS06B1M，主板联想 310C，Q270，魔改 BIOS 支持 9 代 U、ME 已关）
- CPU：QQLT（i7-9750H 转接 ES，6 核 12 线程，核显 UHD 630 原生设备 ID 3E9B）
- 目标系统：**macOS Sequoia 15**（稳定优先，不装 Tahoe）
- OpenCore **1.0.8**，全部组件均为官方 GitHub release（2026-11-14 重新拉取复核：与 v1 2026-11-11 的版本完全一致，无更新，见下「组件版本」），无第三方打包文件
- config.plist 已通过 ocvalidate 校验：`Completed validating config.plist in 1 ms. No issues found.`
- v1（`EFI-P320-QQLT/`）原样保留，本包是 v2 独立新版，不覆盖 v1。

---

## 实测硬件确认（2026-11-14）

用户在 Windows 10 Pro 22H2 下截图实测，以下为准；与 PSREF 推断冲突时以实测为准。

| 项目 | 实测结果 | 状态 |
|---|---|---|
| 机型 / 主板 | 联想 10MYS06B1M（P320 Tiny），主板联想 310C，Intel Q270 芯片组 | ✅ 确认，与 v1 假设一致 |
| CPU | QQLT，Windows 显示 "Genuine 英特尔 0000 @ 2.40GHz 六核"——**6 核已确认**；品牌字串 0000 是 ES 版正常现象，不是故障 | ✅ 确认 |
| 内存 | 金士顿 16GB DDR4 2400MHz，单条 | ✅ 确认 |
| 显卡 | Intel(R) UHD Graphics 630（128MB / 联想），**核显确认可用、有画面输出**，走 DP 接 H27T22 27 寸显示器 | ✅ 确认（v1 的悬案已解决） |
| 无线网卡 | Intel(R) 双频 Wireless-AC **8265** | ✅ 确认 |
| 硬盘 | WDC WDS100T2B0C-00PXH0 1TB NVMe（Windows 盘）；macOS 将装到另一块 M.2 上（P320 有两个 M.2 2280 NVMe 槽，分盘双系统） | ✅ 确认 |
| 系统 | Win10 Pro 22H2 64 位 | ✅ 确认 |

### v1 → v2 改动清单

**因实测而改（配置本身无功能变化，v1 的配置已是对的）：**
- 核显：v1 时"不显版"风险悬而未决，0x3E92 spoof 是备选；v2 实测 DP 输出正常，**确认走原生 3E9B、不用 spoof**——config 里 device-id 仍不设，0x3E92（`923E0000`）只保留作黑屏后的备用方案，不启用。config 的核显注释已更新为实测结论。
- 无线网卡：v1 按"8265 级别"推断；v2 确认就是 AC 8265，itlwm v2.3.0 / AirportItlwm 均原生支持 8265，配置不变，注释已更新。
- CPU：6 核 12 线程实测确认；"0000"字串已确认为 ES 正常现象。SMBIOS 仍为 MacBookPro16,1（9750H 的真实机型），配置不变。
- 三码占位注释修正：v1 的说明文字与实际占位值不符（说 ROM 存的是 "GENERATE-YOUR-" 字串，实际 ROM 是空 Data），v2 已改成与实际一致的描述。占位值本身不变。

**原样保留（实测确认无误）：**
- AAPL,ig-platform-id=07009B3E、unifiedmem 2G、alcid=12、CFG Lock 两项 quirk 开、SSDT-GPRW-XDCI（_PRW 热补丁）、UTBDefault + XhciPortLimit 暂开、boot-args `keepsyms=1 alcid=12`、SMBIOS MacBookPro16,1 占位写法。
- 全部组件版本：2026-11-14 重新从官方 release 拉取并逐文件哈希比对，与 v1 的二进制**完全一致**，无任何更新（见下表）。
- ACPI：SSDT-PLUG / EC-USBX / AWAC / PMC / GPRW-XDCI 全部沿用 v1（其中 EC-USBX、PMC、AWAC 与 OpenCore 1.0.8 官方样例哈希一致；SSDT-PLUG 是 M910Q 仓库的路径无关版，与官方样例不同，保留 v1 的已验证版）。

**仍未验证、不要当成已确认（装机后核对）：**
- 音频 codec：仍按 PSREF 假设为 **Realtek ALC294、layout-id 12**，备选 11→13→21→15。核对方法：装完进 macOS 前，先在 Windows 设备管理器 → 声音、视频和游戏控制器 → 看音频设备的硬件 ID（VEN_10EC 开头即 Realtek，DEV_0294 即 ALC294）；或进 macOS 后看"关于本机 → 系统报告 → 音频"；没声音就按下面排障第 4 条依次试 alcid。
- 有线网卡：仍按 PSREF 假设为 **Intel I219-LM + IntelMausi**。核对方法：Windows 设备管理器 → 网络适配器 → 看有线网卡型号与硬件 ID（VEN_8086，DEV_15B7 即 I219-LM）；若实际是 I219-V 或别的型号，IntelMausi 同样覆盖 I219 全系列，一般不用改；若进 macOS 后有线网不通，再按型号排查。

### 组件版本（2026-11-14 复核，全部为官方最新版，与 v1 相同）

| 组件 | 版本 | 来源 |
|---|---|---|
| OpenCore | 1.0.8（2026-09-27） | acidanthera/OpenCorePkg |
| Lilu | 1.7.2（2026-03-20） | acidanthera/Lilu |
| WhateverGreen | 1.7.1 | acidanthera/WhateverGreen |
| VirtualSMC（+SMCProcessor、SMCSuperIO） | 1.3.8 | acidanthera/VirtualSMC |
| AppleALC | 1.9.8 | acidanthera/AppleALC |
| IntelMausi | 1.0.8 | acidanthera/IntelMausi |
| NVMeFix | 1.1.3 | acidanthera/NVMeFix |
| RestrictEvents | 1.1.6 | acidanthera/RestrictEvents |
| itlwm | v2.3.0（默认启用） | OpenIntelWireless/itlwm |
| AirportItlwm | v2.3.0 Sonoma 14.4 构建（默认禁用，备用） | OpenIntelWireless/itlwm |
| IntelBluetoothFirmware + IntelBTPatcher | v2.4.0 | OpenIntelWireless/IntelBluetoothFirmware |
| USBToolBox + UTBDefault | 1.2.0 | USBToolBox/kext |

---

## ⚠️ 第一步（装机前必做）：填三码

现在 config 里的三码是**占位符，不能直接装机登录 iCloud**：

- `PlatformInfo > Generic > SystemSerialNumber` = `OEM`（占位）
- `PlatformInfo > Generic > MLB` = `GENERATE-YOUR-OWN`（占位）
- `PlatformInfo > Generic > SystemUUID` = `OEM`（占位）
- `PlatformInfo > Generic > ROM` = 空（占位，0 字节）

生成方法：

1. 在任意电脑上下载 **GenSMBIOS**（github.com/corpnewt/GenSMBIOS；Windows 上运行 `GenSMBIOS.bat`、首次会自动准备 Python 环境），运行后选「Install/Update MacSerial」再选「Generate SMBIOS」；
2. 机型输入 **MacBookPro16,1**（QQLT 的 9750H 就是这台真 MacBook Pro 2019 的原装 CPU，机型天然对应）；
3. 把输出的四个值填回 config.plist 的 `PlatformInfo > Generic`：
   - `SystemSerialNumber` ← Serial
   - `MLB` ← MLB / Board Serial
   - `SystemUUID` ← SmUUID
   - `ROM` ← ROM（6 字节，GenSMBIOS 输出的十六进制串直接填 Data 类型）
4. 生成后可去 checkcoverage.apple.com 验证序列号：显示「无法验证购买日期 / 未激活」才是可用的，别用能查到真实保修记录的（那是真机码）。

## 制作安装 U 盘（在 Windows 上操作）

前提提醒：没有现成 Mac 时，Windows 上拿不到官方安装器本体——微软商店/GitHub 上那些「一键黑苹果 U 盘」镜像都是第三方重打包，来源不干净、还容易被植入改版 EFI，**不要用**。下面两条路都是只用官方源：安装器走苹果官方恢复服务器（通过 OpenCore 自带的 macrecovery.py 下载官方原版），EFI 用本包。

### 主路线（无人值守型，最常用）：OpenCore 官方在线恢复镜像

走这条路 U 盘里不放完整安装器，是从苹果服务器在线拉取安装，**装机时 P320 必须插网线**（有线网卡开箱可用；WiFi 在安装界面里还驱动不了）。

1. 准备 **≥2G** 的 U 盘（推荐 ≥8G，FAT32 装得下即可），重要数据先备份，下一步会格式化；
2. 在 Windows 上装好 **Python 3**（python.org），再下载 **OpenCorePkg 1.0.8** 发布包（github.com/acidanthera/OpenCorePkg/releases），解压后找到 `Utilities/macrecovery/macrecovery.py`；
3. 在 `macrecovery` 目录打开命令行，运行 `python macrecovery.py -b Mac-937A206F2EE63C01 -m 00000000000000000 download`（这是拉 Sequoia 15 恢复镜像的固定参数：board-id 对应一台最高只支持到 Sequoia 的机型，`m` 后是 17 个 0）；下载得到 `com.apple.recovery.boot` 文件夹（里面是 BaseSystem.dmg + BaseSystem.chunklist，约 600MB）。⚠️ **别用 gibMacOS**：它的 Recovery-Only 模式只认老式 `RecoveryHDUpdate.pkg`/`RecoveryHDMetaDmg.pkg`，Big Sur 之后的系统根本没有这两个包，Sequoia 永远不会出现在那个列表里；直接下的完整安装器 `InstallAssistant.pkg`（15GB）在 Windows 上也做不成启动盘；
4. 把 U 盘格式化成 **FAT32**（资源管理器右键 → 格式化，文件系统选 FAT32）；U 盘超 32G 时资源管理器不给 FAT32 选项，用 **Rufus**（rufus.ie）格：启动类型选「非可启动」，文件系统选 FAT32（Large FAT32）；
5. 把 gibMacOS 下好的 **`com.apple.recovery.boot` 整个文件夹**拷到 U 盘**根目录**；
6. 把本目录的 **`EFI` 文件夹也拷到 U 盘根目录**（与 `com.apple.recovery.boot` 并列，不要多套一层目录）；
7. 成品结构自检（U 盘根目录应该长这样）：
   - `EFI\BOOT\BOOTx64.efi`
   - `EFI\OC\config.plist`（三码已按上一步填好的那份）
   - `com.apple.recovery.boot\BaseSystem.dmg`
8. （建议）把 **HeliPort.app**（OpenIntelWireless release v1.5.0，需要时另行下载）和这份 README 的副本也拷到 U 盘根目录备用。

> ⚠️ 选错恢复镜像的信号：开口菜单进去显示的是别的系统版本、或提示要连 WiFi 且插网线没反应，多半是 gibMacOS 下错了目录/版本，回第 3 步重下 Sequoia 的 Recovery。

### 备选路线（想要离线完整安装器）：必须有一台能用的 Mac / 已装好的黑苹果

完整安装器只能在 macOS 里用 `createinstallmedia` 写盘，Windows 没有官方等价工具。有 Mac 时：App Store 下载 macOS Sequoia → 磁盘工具把 ≥16G U 盘抹成 Mac OS 扩展（日志式）+ GUID 分区图 → 终端跑
`sudo /Applications/Install\ macOS\ Sequoia.app/Contents/Resources/createinstallmedia --volume /Volumes/你的U盘名`
→ 再用 MountEFI（github.com/corpnewt/MountEFI）挂载 U 盘 EFI 分区，把本目录的 `EFI` 文件夹整个拷到分区根目录。第一次装机别折腾这条，用主路线。

## BIOS 设置清单（魔改 BIOS 里逐项对）

| 项目 | 设置 | 说明 |
|---|---|---|
| Above 4G Decoding | **开（Enabled）** | 没有这一项也行，config 里 ResizeAppleGpuBars=0 已兜底 |
| CSM | **关（Disabled）** | 纯 UEFI 启动 |
| Secure Boot | **关（Disabled）** | |
| CFG Lock（MSR 0xE2） | **有开关就关** | 魔改 BIOS 里可能没有这一项：没有就不管，config 里两个 CFG Lock quirk 已默认打开兜底；**若 BIOS 能关 CFG Lock，记得回 config 把 Kernel > Quirks 里的 AppleCpuPmCfgLock、AppleXcpmCfgLock 两个都改回 false** |
| 核显显存预留（DVMT Pre-Allocated） | **64M 或更高** | 能设就设 64M+；设不了也不怕，config 已带 framebuffer-stolenmem 兜底思路（unifiedmem 2G 已设） |
| 主显输出（Primary Display） | 核显（IGD/Onboard） | 机器没独显是默认，只有装了 P600 的才需要改 |
| XHCI Hand-off | 开 | |
| Fast Boot | 关 | 首装期关掉，避免跳过 U 盘引导 |
| Boot Mode | UEFI Only | 与 CSM 关对应 |

⚠️ 魔改 BIOS 特别注意：**装机调试期间不要在 BIOS 里点「恢复默认设置（Load Optimized Defaults）」**——卖家说过功耗墙（45W）等关键设置一恢复默认就没了，先拍照备份当前 BIOS 各项设置再动。

## 装机流程简述

1. **分盘双系统**：Windows 已在 WDC WDS100T2B0C 1TB 盘上；macOS 装到另一块 M.2 上（P320 有两个 M.2 2280 NVMe 槽，Windows 盘不动，别选错目标盘——安装器里认准容量/型号再点）；
2. U 盘插前置 USB 口，开机 F12（联想启动菜单）选 U 盘 UEFI 项；
3. OpenCore 菜单选「Install macOS Sequoia」，正常装机（期间自动重启几次，每次都从 U 盘进 OpenCore、后几次选硬盘上的「macOS Installer」条目）；
4. 装完进桌面后，先别登 iCloud：确认三项——画面加速（关于本机显示 UHD 630 1536MB+、拖动窗口不卡）、有线网（插网线自动获取 IP）、声音（喇叭/3.5mm 有声）；
5. 把 EFI 从 U 盘拷到 macOS 盘的 EFI 分区（MountEFI 挂载后整夹替换），以后脱离 U 盘启动；开机默认进 OpenCore 菜单，再选 Windows 或 macOS；
6. 再登 iCloud / 做下面的 USB 定制收尾。

## 首启排障顺序（按这个序，别乱改）

1. **黑屏（过了 OpenCore 菜单就没画面）** → 先查核显/接口：
   - v2 实测已确认这颗 QQLT 的核显 DP 输出正常，黑屏大概率是接口映射问题，不是核显本身不亮；
   - 先换另一个物理口（DP ↔ HDMI）再开一次；
   - 只插一根 DP 线开机（双屏先拔掉一个）；
   - 还黑：boot-args 加 `igfxonln=1`（强制点亮所有输出）；
   - 进系统后用 Hackintool 读实际接口，把 config 里 `PciRoot(0x0)/Pci(0x2,0x0)` 下的 framebuffer-conX 占位值改成实测映射（现在只有 con2 按 M910q 老 EFI 的经验预填了 HDMI 类型，其余是占位，上机必校准）；
   - 兜底：给核显加 `device-id` = `923E0000`（0x3E92 伪装，M910q 老 EFI 的做法）再试——这是最后手段，实测已证明不需要，优先走上面几步。
2. **卡代码 / 跑码停住** → 先查 quirk 与 BIOS：
   - 卡在 CFG Lock 相关行（如 `...[EB|LD:OFS] Err` 或早期重启）：确认两个 CFG Lock quirk 是 true，或进 BIOS 找 CFG Lock 关掉；
   - 卡 `apfs_module_start` / 等待根设备：检查 Above 4G 是否开、XhciPortLimit 是否 true、换个 USB 口（优先后置 USB 2.0 口插安装盘）；
   - 早期就重启回 BIOS：怀疑 SSDT-AWAC（保险项）与魔改 BIOS 冲突——进 config 的 ACPI > Add 把 `SSDT-AWAC.aml` 那行 Enabled 改 false 再试；其次怀疑散热器没压好导致 CPU 保护（先按烤机清单重装散热器，别急着怀疑 EFI）。
3. **进系统后的收尾（必做）**：
   - **USB 定制**：用 USBToolBox 工具（Windows 版或 macOS 里）逐个口插拔认口，生成自己的 `UTBMap.kext`，替换掉 Kexts 里的 `UTBDefault.kext`（config 里同步改名启用、禁用旧的），**然后把 Kernel > Quirks > XhciPortLimit 改回 false**。不定制的后果：端口超 15 个上限、部分口无反应、睡眠乱醒；
   - **关自动睡眠**：系统设置 > 节能 里把自动睡眠关掉/设永不。睡眠是这块板公认的短板（见下「已知妥协」），24 小时挂机用途直接关睡眠最省心；
   - 睡眠还想试的话先看 `pmset -g log | grep -i wake` 的唤醒源：是 XDCI 就是 _PRW 补丁没对上板子的实际 DSDT（补丁 SSDT-GPRW-XDCI 已在 EFI 里，但要以实机 DSDT 里真正带 0x6D 的设备为准核对）。
4. **没声音**：先核对音频 codec 是否真是 ALC294（见上「仍未验证」一节的核对方法）；是 ALC294 的话，boot-args 里 `alcid` 依次试 `11`、`13`、`21`、`15`（改完重启），并同步改 `Pci(0x1f,0x3)` 下的 layout-id 为同值。当前 12 是专为联想 Tiny 平台（M710Q）作者写的布局、且 M910q 实机验证过，命中率最高。
5. **WiFi 切换方法**（itlwm ↔ AirportItlwm）：默认启用 **itlwm**（Sequoia 下更稳；连网靠 HeliPort 小工具选 SSID，它在系统里显示为一个「以太网」服务；网卡已确认为 AC 8265，itlwm 原生支持）。想试 AirportItlwm（原生 WiFi 菜单体验）：config > Kernel > Add 里把 `itlwm.kext` 的 Enabled 改 false、`AirportItlwm.kext` 改 true，重启。**两者绝不能同时启用。** 注意：AirportItlwm 官方没有 Sequoia 版，本 EFI 里放的是 v2.3.0 的 Sonoma 14.4 构建，在 Sequoia 上可能加载失败——失败就切回 itlwm，别折腾。

## 已知妥协（装之前先知道）

- **睡眠可能不完美**：M910q/P320 这块板有 XDCI 秒唤醒通病，EFI 里已放了 _PRW 热补丁（GPE 0D/6D 归零法），但魔改 BIOS + 实机 DSDT 个体差异，不能保证一击命中；很多同平台玩家最终就是关掉自动睡眠。24 小时节点用途基本无影响。
- **Intel 无线网卡无苹果生态功能**：隔空投送（AirDrop）、接力（Handoff）、随航（Sidecar）、通用剪贴板、Apple Watch 解锁**都用不了**——这是 Intel 网卡驱动（itlwm/AirportItlwm）的硬限制，与 EFI 无关；想要这些只能换博通免驱卡（如 BCM94360CS2，M910q 老 EFI 作者就是这么干的）。
- **蓝牙**：Intel 蓝牙靠 IntelBluetoothFirmware + IntelBTPatcher 工作，基础连接（耳机/鼠标）可用，个别设备配对稳定性看运气；蓝牙依赖 USB，USB 定制没做好时蓝牙会找不到（内建 USB 口要在定制里标 internal/255）。
- **核显接口映射是占位值**：DP/HDMI 的 framebuffer 接口映射必须上机用 Hackintool 校准，现值只是按同平台经验预填的起点，不保证一次点亮全部口（但 v2 实测已确认至少 DP 主口能出画面）。
- **雷电/USB4、FaceTime/iMessage**：前者这台机器没有；后者要等三码填好并激活状态正常后才可用，别拿占位码去登。
- **系统更新**：只升 Sequoia 的小版本（15.x）；**不要升 Tahoe（26）**——本 EFI 按 Sequoia 组，升大版本前先回来更新 OpenCore 与 kext。

## 文件对照（出问题时知道动哪）

- `EFI/OC/config.plist` — 主配置（三码、boot-args、quirk 都在这）
- `EFI/OC/ACPI/` — SSDT-PLUG（电源管理）、SSDT-EC-USBX、SSDT-AWAC（可禁用）、SSDT-PMC、SSDT-GPRW-XDCI（治秒唤醒，源码 .dsl 同目录）
- `EFI/OC/Kexts/` — 驱动全家桶；AirportItlwm 默认禁用躺在里面
- 校验方法：在 OpenCorePkg 的 Utilities/ocvalidate 里跑 `ocvalidate config.plist`，应输出 `No issues found.`
