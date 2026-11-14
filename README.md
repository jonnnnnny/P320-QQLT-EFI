# P320 Tiny + QQLT 黑苹果 EFI

联想 ThinkStation P320 Tiny（10MYS06B1M，主板 310C / Q270，魔改 BIOS）+ QQLT（i7-9750H 转接 ES，6 核 12 线程，核显 UHD 630）用的 OpenCore EFI，目标系统 macOS Sequoia 15。

- OpenCore 1.0.8，全部组件均为官方 GitHub release
- SMBIOS MacBookPro16,1（9750H 的真实机型）
- **config.plist 里的三码是占位符**：装机前必须用 GenSMBIOS 生成 MacBookPro16,1 的 Serial / MLB / SmUUID / ROM 填回，否则不要登录 iCloud
- 完整安装流程见 `P320-QQLT-黑苹果安装全流程.md`
- 只升 Sequoia 15.x，不要升 Tahoe（26）
- 实测硬件（2026-11-14）：QQLT 六核、UHD 630 核显 DP 输出正常、WiFi Intel AC 8265、内存金士顿 16G DDR4 2400、磁盘 WD WDS100T2B0C 1TB

## 下载方法

本仓库的 zip 是按 8MB 切开存放的（GitHub 单文件 API 传不了 46MB 整包），下载后按下述方法合并：

- 最省事：仓库页面点 Code → Download ZIP，把整个仓库下载下来，解压后运行 `join.bat`（Windows）或 `sh join.sh`，得到完整的 `EFI-P320-QQLT-v2.zip`。
- 也可以只下载 `EFI-P320-QQLT-v2.zip.001` … `.00N` 和 `join.bat`，放同一文件夹里运行 `join.bat`。
