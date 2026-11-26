# TrafficMonitor 多任务栏窗口补丁 / Multi-Taskbar Patch

让 [TrafficMonitor](https://github.com/zhongyang219/TrafficMonitor) 的任务栏窗口**同时显示在所有显示器的任务栏上**。
原版只能在“主显示器 / 某一个副显示器”里选一个，这个补丁把“一个任务栏窗口”改成了“每个任务栏一个窗口”。

> 本仓库以**补丁 + 说明**为主，不含上游源码；同时在 [Releases](https://github.com/anranyuyue/TrafficMonitor-MultiTaskbar/releases/latest) 提供一份**开箱即用的 x64 构建**，不想自己编译的直接下载即可。

---

## 直接下载（免编译）

不想折腾编译的，拿这一个压缩包就行：

**[⬇ TrafficMonitor-MultiTaskbar-v1.8.6-x64.zip](https://github.com/anranyuyue/TrafficMonitor-MultiTaskbar/releases/latest/download/TrafficMonitor-MultiTaskbar-v1.8.6-x64.zip)**（Windows 10/11 · x64 · 约 1.2 MB）

1. 解压到任意目录（**不要**在压缩包里直接双击运行）
2. 双击 `TrafficMonitor.exe`
3. 前提：Windows 设置里开启「在所有显示器上显示任务栏」

包内 `config.ini` 已预置 `show_taskbar_wnd_in_all_displays = true`，打开就是所有任务栏都有窗口，不用再手动设置。
想改回单个显示器：右键任务栏窗口 → 选项 → 任务栏设置 → 「显示任务栏窗口的显示器」。

> 压缩包内附 `使用说明.txt`、`LICENSE.txt`（上游许可证原文）、`NOTICE.txt`（非官方修改版与 AI 使用声明）。
> 校验值：`sha256 = 9a0ffd222ce3f59b0d6ca8b0fcfc04de7bdc2e012bda8c81767bcfd128b111a3`

---

## 效果 / Screenshots

主显示器任务栏（Windows 11，1920×1080，100% 缩放）：

![主显示器任务栏](docs/pri_taskbar.png)

副显示器任务栏（1920×1080 物理，125% 缩放，即 1536×864 逻辑分辨率）：

![副显示器任务栏](docs/sec_taskbar.png)

---

## 为什么不用插件？

看过官方 [插件开发指南](https://github.com/zhongyang219/TrafficMonitor/wiki/%E6%8F%92%E4%BB%B6%E5%BC%80%E5%8F%91%E6%8C%87%E5%8D%97) 后确认：插件 API（`ITMPlugin` / `IPluginItem`）只负责**提供显示项目与绘制内容**（`GetItem` / `DataRequired` / `DrawItem` / `OnMouseEvent`），
完全接触不到窗口、任务栏、显示器枚举，因此**插件无法实现多任务栏窗口**。只能改源码。

---

## 改动概览

| 文件 | 改动 |
| --- | --- |
| `TaskbarHelper.h/.cpp` | 新增 `TaskbarWnd` 与 `GetAllTaskbarWnd()`：枚举主任务栏 `Shell_TrayWnd` + 所有 `Shell_SecondaryTrayWnd` |
| `TaskBarDlg.h/.cpp` | 新增 `SetTargetTaskbar(hwnd, is_secondary)`，让每个窗口明确嵌入哪条任务栏；DPI 缓存、任务栏上下位置缓存由 static/共享改为**每窗口独立** |
| `TrafficMonitorDlg.h/.cpp` | `m_tBarDlg` → `m_tBarDlgs` 列表 + `ForEachTaskbarWnd()`；刷新、宽度、透明度、DPI、鼠标提示、右键菜单父窗口等全部改为遍历所有窗口 |
| `CommonData.h` / `TrafficMonitor.cpp` | 新增配置项 `show_taskbar_wnd_in_all_displays`（读写 ini） |
| `TaskBarSettingsDlg.cpp` | “显示任务栏窗口的显示器”下拉框新增 **所有显示器** 项（索引 0=主显示器，1=所有显示器，2+=副显示器 N） |
| `language.h` / `language/*.ini` | 新增 `IDS_ALL_DISPLAYS`，补齐 17 种语言 |

完整 diff 见 [`patch/multi-taskbar-windows.patch`](patch/multi-taskbar-windows.patch)（27 个文件，+242/−92）。

---

## 使用方法

```bash
git clone https://github.com/zhongyang219/TrafficMonitor.git
cd TrafficMonitor
git checkout master      # 补丁基于 1.8.6 前后的 master
git apply /path/to/multi-taskbar-windows.patch
```

编译出 x64 Release 的 `TrafficMonitor.exe` 后运行，然后：

**右键任务栏窗口 → 选项 → 任务栏设置 → “显示任务栏窗口的显示器” → 选择「所有显示器」→ 确定**

也可以直接在 `config.ini` 的 `[task_bar]` 段写：

```ini
show_taskbar_wnd_in_all_displays = true
```

---

## 构建说明（以及踩过的坑）

环境：**VS 2022 Build Tools（v143 工具集 + MFC）+ Windows 11 SDK 10.0.26100**，x64 Release，工程要求 C++20。

1. **源码是 UTF-8 无 BOM + 中文注释**。系统代码页为 936 时，MSVC 会把 UTF-8 注释解析错（甚至吞掉行尾换行），
   表现为 `DrawCommonHelper.h(5): error C2447` 之类莫名字法错误。
   给所有项目加 `/utf-8` 即可，见 [`tools/utf8.props`](tools/utf8.props)：
   `msbuild ... /p:ForceImportBeforeCppTargets=tools\utf8.props`
2. **`OpenHardwareMonitorApi` 是 C++/CLI 工程**，需要 .NET Framework 4.7.2 的引用程序集。
   没装 Developer Pack 时，可以下载 NuGet 包 `Microsoft.NETFramework.ReferenceAssemblies.net472` 解压后
   传 `/p:TargetFrameworkRootPath=<解压目录>\build`。
3. 该工程链接 `MSCOREE.lib`。若 SDK 里没有这个 lib，可用 `dumpbin /exports mscoree.dll` + `lib /def` 自己生成导入库，
   放进 SDK 的 `Lib\<ver>\um\x64` 或工具集的 `lib\x64`。
4. 构建脚本见 [`tools/build.ps1`](tools/build.ps1)（参数化，按需改路径）。

---

## 已知限制 / 注意事项

- **前提**：Windows 设置里要开启「在所有显示器上显示任务栏」。没有任务栏的显示器没有可嵌入的宿主窗口，无法显示（这是系统限制，不是补丁问题）。
- 每个任务栏窗口都是独立 HWND 子窗口，**多显示器不同 DPI 已实测**（本机 100% + 125%）；但**未测试** 3 屏以上、Win10 经典任务栏、竖排任务栏、Wine。
- 只支持单实例运行（上游限制未变）；任务栏进程重启（explorer 崩溃）时会按新任务栏列表重建窗口。
- 补丁基于 1.8.6 前后的 master；上游若重构了任务栏窗口相关代码，需要手动 rebase。
- 这是**非官方补丁**，与上游作者无关，未经上游 review。

---

## 许可证 / License

上游 TrafficMonitor 使用 **“Anti 996” License Version 1.0 (Draft)**，本补丁作为其衍生作品遵循同一许可证。
仓库内 [`LICENSE`](LICENSE) 为上游原文（Copyright (c) 2019 zhongyang219）。

---

## AI 使用声明 / AI Disclosure

本仓库的源码修改、构建脚本与文档由 **AI 编程代理**在人工指令下完成，人工负责提出目标、提供软硬件环境并验收结果。

- **AI 完成的部分**：多窗口改造方案与实现、设置项与多语言文案、构建环境搭建与编译排错、双显示器实机验证、截图与文档。
- **人工完成的部分**：提出需求与方案选择（插件 vs 改源码）、提供机器与显示器环境、最终验收。
- **验证范围**：在本机（Windows 11，双显示器，100%/125% 混合缩放）实测通过；未覆盖全部平台与配置。
- 因此：**合入或二次分发前请自行 review diff 并自行承担风险**；发现问题的 issue 欢迎提，但不保证响应速度。

---

## 参考 / References

- 上游项目：<https://github.com/zhongyang219/TrafficMonitor>
- 插件开发指南（判断“插件做不到”的依据）：<https://github.com/zhongyang219/TrafficMonitor/wiki/%E6%8F%92%E4%BB%B6%E5%BC%80%E5%8F%91%E6%8C%87%E5%8D%97>
- Win32 `Shell_TrayWnd` / `Shell_SecondaryTrayWnd` 任务栏窗口结构（Microsoft Docs）
- 构建环境：Visual Studio 2022 Build Tools（v143）、Windows SDK 10.0.26100、MFC
