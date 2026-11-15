# P320 Tiny + QQLT 黑苹果 EFI（OpenCore 1.0.8 / macOS Sequoia 15）

- 目标机器：联想 ThinkStation P320 Tiny（机型 10MYS06B1M，主板联想 310C，Q270，魔改 BIOS，支持 9 代 U）
- CPU：QQLT（i7-9750H 转接 ES，6 核 12 线程，核显 UHD 630 原生设备 ID 3E9B）
- 目标系统：**macOS Sequoia 15.x**（稳定优先，**不升 Tahoe 26**）
- 机型：MacBookPro16,1（9750H 就是这台真 MacBook Pro 2019 的原装 CPU，天然对应）
- 下载：本仓库就是解压后的 EFI 文件夹原样，Code → Download ZIP，解压即得 `EFI` 文件夹，不用拼包；详细分步流程见同仓库的《P320-QQLT-黑苹果安装全流程.md》
- 校验：`ocvalidate config.plist` → `No issues found.`

---

## 实测硬件（2026-11-14，Windows 10 Pro 22H2 下截图确认）

| 项目 | 实测结果 |
|---|---|
| 机型 / 主板 | 联想 10MYS06B1M，主板联想 310C，Q270 |
| CPU | QQLT，6 核 12 线程已确认；Windows 显示 "Genuine 英特尔 0000 @ 2.40GHz"，0000 是 ES 版品牌字串为空，正常 |
| 内存 | 金士顿 16GB DDR4 2400MHz，单条 |
| 显卡 | Intel UHD Graphics 630，**核显确认可用、有画面输出**，DP 接 H27T22 27 寸显示器 |
| 无线网卡 | Intel Wireless-AC **8265** |
| 硬盘 | WDC WDS100T2B0C 1TB NVMe（Windows 盘）；macOS 装到另一块 M.2 上（P320 有两个 M.2 2280 NVMe 槽，分盘双系统） |
| 音频 / 有线网卡 | **未验证**：按资料推断为 Realtek ALC294（layout-id 12）/ Intel I219-LM（IntelMausi 驱动），装完后核对（方法见排障第 4 条和第 5 条） |

## 包内组件（全部为官方 GitHub release，2026-11-14 复核）

| 组件 | 版本 | 备注 |
|---|---|---|
| OpenCore | 1.0.8 | |
| Lilu / WhateverGreen / VirtualSMC / AppleALC / IntelMausi / NVMeFix / RestrictEvents | 1.7.2 / 1.7.1 / 1.3.8 / 1.9.8 / 1.0.8 / 1.1.3 / 1.1.6 | |
| itlwm | v2.3.0 | 默认启用（WiFi，配合 HeliPort） |
| AirportItlwm | v2.3.0 Sonoma 14.4 构建 | 默认禁用，备用；官方无 Sequoia 版，可能加载失败 |
| IntelBluetoothFirmware + IntelBTPatcher | v2.4.0 | |
| USBToolBox + UTBDefault | 1.2.0 | UTBDefault 是通用占位，装完必须生成自己的 UTBMap 替换 |
| ACPI | SSDT-PLUG / EC-USBX / AWAC / PMC / GPRW-XDCI | GPRW-XDCI 是 _PRW 热补丁（治 XDCI 秒唤醒）；AWAC 是保险项，出问题先禁用它 |

关键配置：AAPL,ig-platform-id = 07009B3E，核显 device-id 不设（走原生 3E9B，不用 spoof），unifiedmem 2G，boot-args `keepsyms=1 alcid=12`，CFG Lock 两项 quirk 默认开，XhciPortLimit 装机期开、装完关。

---

## 使用步骤

### 第 1 步：填三码（装机前必做）

config.plist 里的三码现在是**占位符，不能直接拿去登录 iCloud**：SystemSerialNumber=`OEM`、MLB=`GENERATE-YOUR-OWN`、SystemUUID=`OEM`、ROM=空。

1. 下载 **GenSMBIOS**（github.com/corpnewt/GenSMBIOS），运行后选 Generate SMBIOS，机型输入 **MacBookPro16,1**；
2. 把输出的四个值填回 config.plist 的 `PlatformInfo > Generic`：
   - `SystemSerialNumber` ← Serial
   - `MLB` ← Board Serial
   - `SystemUUID` ← SmUUID
   - `ROM` ← ROM（6 字节十六进制，填 Data 类型）
3. 去 checkcoverage.apple.com 查一下序列号：显示「无法验证购买日期 / 未激活」才是可用的，别用能查到真实保修记录的（那是真机码）。
4. 填 config 推荐用 **OCAuxiliaryTools** 或 ProperTree，别用记事本硬改。OCAT 在 Windows 上进程在但窗口空白时：右键以管理员身份运行，或在兼容性里设「替代高 DPI 缩放行为 → 应用程序」，或建个 bat 先 `set QT_OPENGL=software` 再启动。

### 第 2 步：做安装 U 盘（Windows 上操作）

走在线恢复镜像路线：U 盘里不放完整安装器，装机时从苹果服务器在线拉取系统，**装机时 P320 必须插网线**（有线网卡开箱可用；WiFi 在安装界面里还驱动不了）。

1. 准备 U 盘（推荐 ≥8G，重要数据先备份，下一步会格式化）；
2. 装好 **Python 3**（python.org），下载 **OpenCorePkg 1.0.8** 发布包（github.com/acidanthera/OpenCorePkg/releases），解压后找到 `Utilities/macrecovery/macrecovery.py`；
3. 在 `macrecovery` 目录打开命令行，运行：
   ```
   python macrecovery.py -b Mac-937A206F2EE63C01 -m 00000000000000000 download
   ```
   这是拉 Sequoia 15 恢复镜像的固定参数（board-id 对应一台最高只支持到 Sequoia 的机型，`m` 后是 17 个 0）。下载得到 `com.apple.recovery.boot` 文件夹（BaseSystem.dmg + BaseSystem.chunklist，约 600MB）。
   ⚠️ **别用 gibMacOS**：它的 Recovery-Only 模式只认老式 `RecoveryHDUpdate.pkg` / `RecoveryHDMetaDmg.pkg`，Big Sur 之后的系统根本没有这两个包，Sequoia 永远不会出现在那个列表里；直接下的完整安装器 `InstallAssistant.pkg`（15GB）在 Windows 上也做不成启动盘。
4. U 盘格式化成 **FAT32**（资源管理器右键 → 格式化；超 32G 的盘资源管理器不给 FAT32 选项，用 Rufus：启动类型选「非可启动」，文件系统选 FAT32 / Large FAT32）；
5. 把 `com.apple.recovery.boot` 整个文件夹拷到 U 盘**根目录**；
6. 把本仓库的 **`EFI` 文件夹也拷到 U 盘根目录**（与 `com.apple.recovery.boot` 并列，不要多套一层目录）；
7. 自检（U 盘根目录应该长这样）：
   - `EFI\BOOT\BOOTx64.efi`
   - `EFI\OC\config.plist`（三码已填好的那份）
   - `com.apple.recovery.boot\BaseSystem.dmg`
   - `com.apple.recovery.boot\BaseSystem.chunklist`
8. （建议）把 HeliPort.app（OpenIntelWireless release v1.5.0，另行下载）也拷到 U 盘根目录备用。

> ⚠️ 别用网上任何「一键黑苹果 U 盘 / 精简镜像」——只用苹果官方恢复镜像 + 本包 EFI。

### 第 3 步：BIOS 设置（魔改 BIOS 里逐项对）

| 项目 | 设置 |
|---|---|
| Above 4G Decoding | 开（没有这一项也行，config 里 ResizeAppleGpuBars=0 已兜底） |
| CSM | 关（纯 UEFI 启动） |
| Secure Boot | 关 |
| CFG Lock（MSR 0xE2） | 有开关就关；没有就不管，config 里两个 CFG Lock quirk 已默认打开兜底。**若 BIOS 能关 CFG Lock，记得回 config 把 Kernel > Quirks 里的 AppleCpuPmCfgLock、AppleXcpmCfgLock 两个都改回 false** |
| 核显显存预留（DVMT Pre-Allocated） | 64M 或更高 |
| 主显输出（Primary Display） | 核显（IGD/Onboard） |
| XHCI Hand-off | 开 |
| Fast Boot | 关（首装期关掉，避免跳过 U 盘引导） |
| Boot Mode | UEFI Only |

⚠️ **装机调试期间不要在 BIOS 里点「恢复默认设置（Load Optimized Defaults）」**——魔改 BIOS 的功耗墙（45W）等关键设置一恢复默认就没了，动手前先拍照备份当前 BIOS 各项设置。

### 第 4 步：装系统

1. **分盘双系统**：Windows 已在 WDC WDS100T2B0C 1TB 盘上；macOS 装到另一块 M.2 上（安装器里认准容量/型号再点，别选错目标盘）；
2. U 盘插前置 USB 口，开机 F12（联想启动菜单）选 U 盘 UEFI 项；
3. OpenCore 菜单选「Install macOS Sequoia」，正常装机（期间自动重启几次，每次都从 U 盘进 OpenCore、后几次选硬盘上的「macOS Installer」条目）；
4. 装完进桌面后，先别登 iCloud，做首检（见第 5 步）。

### 第 5 步：装完首检 + 收尾（必做）

1. **首检三项**：画面加速（关于本机显示 UHD 630 1536MB+、拖动窗口不卡）、有线网（插网线自动获取 IP）、声音（喇叭/3.5mm 有声）。三项都过再登 iCloud；
2. **EFI 落盘**：用 MountEFI 挂载 macOS 盘的 EFI 分区，把 U 盘上的 EFI 文件夹整个拷过去，以后脱离 U 盘启动；
3. **USB 定制**：用 USBToolBox 逐个口插拔认口，生成自己的 `UTBMap.kext`，替换 Kexts 里的 `UTBDefault.kext`（config 里同步改名启用、禁用旧的），**然后把 Kernel > Quirks > XhciPortLimit 改回 false**。不定制的后果：端口超 15 个上限、部分口无反应、睡眠乱醒；
4. **关自动睡眠**：系统设置 > 节能里把自动睡眠关掉/设永不（睡眠是这块板的短板，24 小时挂机直接关最省心）。

---

## 排障速查（按这个序，别乱改）

1. **OpenCore 菜单黑屏（连菜单都不显示）** → 本包已补齐 `EFI/OC/Resources`（OcBinaryData，469 个文件），图形菜单正常显示；若个别机器仍黑屏，用 OCAT/ProperTree 打开 config.plist，把 `Misc > Boot > PickerMode` 由 `External` 改 `Builtin`（文字菜单），装机不受影响。
2. **过了菜单黑屏（没画面）** → 先换另一个物理口（DP 换另一个 DP 口）、只插一根 DP 线开机；还黑：boot-args 加 `igfxonln=1`；本包已内置 framebuffer-stolenmem（19MB）+ framebuffer-fbmem（9MB），BIOS 的 DVMT Pre-Allocated 即使是 32M 也能亮——若 BIOS 里能设 DVMT 64M，设 64M 更干净；进系统后用 Hackintool 校准 framebuffer 接口映射（config 里的 conX 目前只有 con2 按同平台经验预填了 HDMI 类型，其余是占位）。兜底：核显加 `device-id` = `923E0000`（0x3E92 伪装）再试——实测已证明不需要，优先走上面几步。
3. **卡代码 / 跑码停住** → 卡 CFG Lock 相关行：确认两个 CFG Lock quirk 是 true，或进 BIOS 关 CFG Lock；卡 `apfs_module_start` / 等待根设备：检查 Above 4G 是否开、XhciPortLimit 是否 true、换个 USB 口（优先后置 USB 2.0 口）；早期就重启回 BIOS：把 `SSDT-AWAC.aml` 的 Enabled 改 false 再试；其次怀疑散热器没压好导致 CPU 保护（按烤机清单重装散热器，别急着怀疑 EFI）。
4. **没声音** → 先核对 codec：Windows 设备管理器 → 声音、视频和游戏控制器 → 看音频设备硬件 ID（VEN_10EC + DEV_0294 即 ALC294）。是 ALC294 的话，boot-args 里 `alcid` 依次试 `11`、`13`、`21`、`15`（改完重启），并同步改 `Pci(0x1f,0x3)` 下的 layout-id 为同值。当前 12 是联想 Tiny 平台验证过的布局，命中率最高。
5. **有线网不通** → 先核对型号：Windows 设备管理器 → 网络适配器 → 看有线网卡硬件 ID（VEN_8086，DEV_15B7 即 I219-LM）。I219 全系列都在 IntelMausi 覆盖内，一般不用改；若仍不通，再按实际型号排查。
6. **WiFi 切换**（itlwm ↔ AirportItlwm）：默认启用 **itlwm**（Sequoia 下更稳；连网靠 HeliPort 选 SSID，系统里显示为一个「以太网」服务）。想试 AirportItlwm（原生 WiFi 菜单体验）：config > Kernel > Add 里把 `itlwm.kext` 的 Enabled 改 false、`AirportItlwm.kext` 改 true，重启。**两者绝不能同时启用。**
7. **睡眠秒醒** → 先看 `pmset -g log | grep -i wake` 的唤醒源：是 XDCI 就是 _PRW 补丁没对上实机 DSDT（SSDT-GPRW-XDCI 已在 EFI 里，以实机 DSDT 里真正带 0x6D 的设备为准核对）；最省心的办法就是关自动睡眠。

## 已知妥协（装之前先知道）

- **睡眠可能不完美**：M910q/P320 这块板有 XDCI 秒唤醒通病，EFI 里已放 _PRW 热补丁，但魔改 BIOS + 实机 DSDT 个体差异，不能保证一击命中；很多同平台玩家最终就是关掉自动睡眠。24 小时节点用途基本无影响。
- **Intel 无线网卡无苹果生态功能**：隔空投送（AirDrop）、接力（Handoff）、随航（Sidecar）、通用剪贴板、Apple Watch 解锁**都用不了**——这是 Intel 网卡驱动的硬限制，与 EFI 无关；想要这些只能换博通免驱卡（如 BCM94360CS2）。
- **蓝牙**：Intel 蓝牙靠 IntelBluetoothFirmware + IntelBTPatcher，基础连接（耳机/鼠标）可用；蓝牙依赖 USB，USB 定制没做好时蓝牙会找不到（内建 USB 口要在定制里标 internal/255）。
- **核显接口映射是占位值**：DP 的 framebuffer 接口映射必须上机用 Hackintool 校准，现值只是按同平台经验预填的起点（但实测已确认至少 DP 主口能出画面）。
- **系统更新**：只升 Sequoia 的小版本（15.x）；**不要升 Tahoe（26）**——本 EFI 按 Sequoia 组，升大版本前先回来更新 OpenCore 与 kext。

## 版本说明

- v2（2026-11-14）：按实测硬件复核重出，核显确认走原生 3E9B（不用 spoof）、网卡确认为 AC 8265、CPU 6 核确认；配置本身相对 v1 无功能变化；音频 ALC294 / 有线 I219-LM 仍为推断，待装机后核对。
- 2026-11-15 修复：补齐 `EFI/OC/Resources`（OcBinaryData，469 个文件）——OpenCore 官方包自带的 Resources 文件夹是空的，图形 Picker（PickerMode=External）因此黑屏；补齐后正常显示。
- 2026-11-15 修复：config 增加 framebuffer-stolenmem（19MB）+ framebuffer-fbmem（9MB）——兼容 BIOS 的 DVMT Pre-Allocated 为 32M 的情况，之前没这组补丁、DVMT 32M 时选完安装器会黑屏（有背光、无图像）。
- 仓库形态：EFI 文件夹原样上传，无压缩包分片，下载 ZIP 解压即用。

## 文件对照（出问题时知道动哪）

- `EFI/OC/config.plist` — 主配置（三码、boot-args、quirk 都在这）
- `EFI/OC/ACPI/` — SSDT-PLUG（电源管理）、SSDT-EC-USBX、SSDT-AWAC（可禁用）、SSDT-PMC、SSDT-GPRW-XDCI（治秒唤醒，源码 .dsl 同目录）
- `EFI/OC/Kexts/` — 驱动全家桶；AirportItlwm 默认禁用躺在里面
- `EFI/OC/Resources/` — Picker 图形素材（OcBinaryData）
- 校验方法：在 OpenCorePkg 的 Utilities/ocvalidate 里跑 `ocvalidate config.plist`，应输出 `No issues found.`
