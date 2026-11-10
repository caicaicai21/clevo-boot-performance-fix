# CLEVO Boot Performance Fix（实验性）

在 Windows 启动阶段，通过用户已安装的原厂 Control Center 接口，单次请求 **娱乐模式**，尝试缩短等待 FnKey 初始化期间的 CPU 0.55 GHz 低频状态。

> **只在作者本人的一台七彩虹 COLORFIRE MEOW R16 24H / AMD Ryzen 9 7845HX 上初步测试。没有验证其他机器，包括同型号的其他个体。它不是 CLEVO / 七彩虹官方工具，也不是通用的 CPU 限频修复工具。请勿在未知硬件上直接套用。**

## 背景与验证范围

测试机器插电启动时，在原厂 FnKey / Control Center 托盘程序初始化完成前，CPU 会长时间停留在约 0.55 GHz。直接提前激活商店应用未得到可靠改善。

本工具绕开应用启动链路，等待已安装的 `AcpiBridge` 驱动进入运行状态，然后调用原厂 DLL 的模式设置接口。**不需要等待 Explorer、AddFn 或 FnKey，也不会停止它们。**

一次实测时序（2026-11-10，北京时间）：

| 事件 | 时间 |
|---|---|
| Windows 启动 | 20:28:46 |
| 本工具开始运行 | 20:29:03.651 |
| 娱乐模式请求返回 0 | 20:29:05.642 |
| FnKey 进程创建 | 20:29:26 |
| FnKey 自己下发娱乐模式 | 20:29:28 |

本工具约在开机后 19 秒完成请求，比 FnKey 自身模式下发早约 22 秒。作者观察到低频等待改善。**没有同步采集 CPU 频率曲线，尚无长期稳定性或其他机器测试；返回 0 不等于硬件一定切换成功。**

## 测试环境

- 设备：COLORFIRE MEOW R16 24H（仅上述一台）
- CPU：AMD Ryzen 9 7845HX
- BIOS：1.07.04COLO1
- EC：1.07.05
- Windows 11 专业工作站版，Build 26300
- 原厂 Control Center Package：v6.069
- ACPI Bridge 驱动：6.0.46.2；DCHU 服务：6.0.46.0
- 当时商店 FnKey：7.101.0.0
- x64 .NET Framework 环境

这些是测试条件，**不是对其他版本兼容性的保证**。本项目未证明商店更新是问题的根因。

## 做什么 / 不做什么

执行流程：

1. 记录启动时间与系统运行时间。
2. 通过 Windows 服务控制接口检查 `AcpiBridge`，最多等待约 30 秒。
3. 加载固定位置的原厂 DLL。
4. 单次请求娱乐模式，记录返回值并退出；不自动重复写入。

不执行：

- 关闭或释放 PROCHOT / 热保护；
- 自定义 CPU 功耗、频率、电压或风扇曲线写入；
- 切换显卡；
- 修改 BIOS、EC 固件、WindowsApps 权限或原厂程序；
- 禁用商店更新或原厂服务。

**模式切换本身可能影响固件控制的性能、功耗和风扇行为。“不写自定义参数”不等于硬件状态完全不变。**

## 重要限制与风险

- 使用的是根据原厂程序还原的内部接口，不是厂商公开承诺兼容的 API。
- 只请求硬件侧娱乐模式，**不修改原厂保存的模式配置**。FnKey 后续可能重新应用保存的安静/省电等模式，托盘状态也未必立即同步。
- **每次完整系统启动都会请求娱乐模式，包括电池供电。** 不适用于希望保留电池启动省电模式的用户。
- 系统启动触发不代表 BIOS 阶段执行，也不保证立刻执行；它不是睡眠恢复触发器。验证时优先使用 Windows 的“重启”。
- 需要原厂驱动已安装。不要卸载 ACPI 驱动或原厂服务。
- 如果出现异常温度、风扇行为、崩溃或模式不一致，停止测试并禁用任务，通过原厂软件恢复模式，必要时重启。
- 不附带任何原厂 DLL、驱动或厂商安装包；请自行从设备厂商获取。不要为了运行本工具去修改安全权限、关闭安全软件或系统保护。
- 安装脚本仅在安装时校验原厂 DLL；后续原厂组件更新前建议先禁用任务，重新审查兼容性。
- 可执行文件没有代码签名。请审阅源码并校验哈希；若安全软件拦截，不要盲目添加排除项。

## 文件

- [ClevoEntertainmentBootV2.cs](./ClevoEntertainmentBootV2.cs)：源码。
- [ClevoEntertainmentBootV2.exe](./ClevoEntertainmentBootV2.exe)：本次测试使用的 x64 可执行文件。
- [Install-Task.ps1](./Install-Task.ps1)：首次安装，复制到受保护目录并注册开机任务。
- [Disable-Task.ps1](./Disable-Task.ps1)：停用任务，不删除文件。

## 安装（仅限明确接受风险的测试环境）

**本机此前已安装实验 V2 的用户无需重复安装。** 脚本遇到已有任务或目录会停止，不覆盖旧配置。

1. 下载项目文件并放在同一目录，阅读源码和风险说明。
2. 先从原厂托盘软件选择娱乐模式，避免保存配置与启动请求不一致。
3. 打开 **64 位 Windows PowerShell，以管理员身份运行**。不要选择 `(x86)`。
4. 将下面路径替换成你实际下载的位置，执行：

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:\下载\clevo-boot-performance-fix\Install-Task.ps1"
   ```

   `Bypass` 只作用于该次安装进程，不永久修改执行策略。

5. 脚本检查机型、CPU、EXE 哈希、原厂 DLL 哈希与签名。**其他硬件会被拒绝；不要为未知机型简单移除检查。** 输入 `YES` 确认安装。
6. 看到安装成功后，保持与原故障相同的供电条件，重启一次验证。安装过程只执行 `--self-test`，不会下发模式请求。

安装位置：`C:\Program Files\ClevoEntertainmentBootTest`。仅管理员和 SYSTEM 可以修改其中代码，普通用户只有读取/执行权限。**不要将 SYSTEM 任务改为执行下载目录、桌面或其他普通用户可写目录中的 EXE。**

### 任务参数（手动核对用）

| 设置 | 值 |
|---|---|
| 名称 | `CLEVO_Entertainment_Boot_Test` |
| 触发器 | 系统启动时，无显式延迟 |
| 身份 | SYSTEM，最高权限 |
| 程序 | `C:\Program Files\ClevoEntertainmentBootTest\ClevoEntertainmentBootV2.exe` |
| 起始位置 | `C:\Program Files\ClevoEntertainmentBootTest` |
| 参数 | 空 |
| 电池条件 | 电池供电也允许运行、不因切到电池而停止 |
| 多实例 | 忽略新实例 |
| 最长执行时间 | 1 分钟 |
| 自动重试 | 无 |

建议使用安装脚本，避免遗漏文件权限和版本检查。首次安装脚本不会自动修改其他任务；若自行添加过同类实验任务，请先禁用，避免重复请求。保留原厂服务。

## 日志和判断效果

```powershell
Get-Content 'C:\Program Files\ClevoEntertainmentBootTest\boot-v2.log' -Tail 30
```

日志包含 `START`、`DRIVER_CHECK_BEGIN`、`DRIVER_READY`、`DLL_LOAD_BEGIN/END`、`MODE_REQUEST_BEGIN/END`，并附每阶段相对耗时。

退出代码：

- `0`：调用返回 0，**不是已测量性能恢复的证明**。
- `1`：环境、驱动、加载或其他错误。
- `2`：模式调用返回非零。

应比较请求时间、实际 CPU 恢复时间与 FnKey 初始化时间。若提前请求仍无改善，停用工具，不要继续试未知硬件参数。日志会追加，项目没有自动轮转功能。

## 停用 / 移除 / 回退

管理员 PowerShell：

```powershell
Disable-ScheduledTask -TaskName 'CLEVO_Entertainment_Boot_Test'
```

或执行 `Disable-Task.ps1`。**停用仅阻止以后的执行，不会撤销已经下发的模式。** 通过原厂 Control Center 重新选择所需模式。

确认不再需要后，移除任务：

```powershell
Unregister-ScheduledTask -TaskName 'CLEVO_Entertainment_Boot_Test' -Confirm:$false
```

然后在资源管理器中确认目录为 `C:\Program Files\ClevoEntertainmentBootTest`，再手动删除该工具目录。不要删除原厂 `ControlCenter` 目录、驱动或服务。

## 从源码构建

在项目目录的 64 位 Windows PowerShell 执行（不访问硬件）：

```powershell
& "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /nologo /platform:x64 /target:exe /optimize+ /out:ClevoEntertainmentBootV2.exe ClevoEntertainmentBootV2.cs
.\ClevoEntertainmentBootV2.exe --self-test
Get-FileHash .\ClevoEntertainmentBootV2.exe -Algorithm SHA256
```

`--self-test` 不加载厂商 DLL、不访问硬件、不写日志。**无参数直接运行会执行模式请求，不要把无参数运行当成安全自检。** 自行重编译的 EXE 哈希可能与发布版本不同，安装脚本会拒绝；应自行审阅构建产物后再更新安装脚本的期望哈希，不要跳过验证。

测试 EXE SHA-256：

```text
90365099794AAD0FB70CD8E463682A1C21929293B4008A7B0CDD34943A4BE621
```

已核对原厂 DLL SHA-256（不随项目分发）：

```text
0D6AA0586C628BEA1B6BFE4D5B2941D68D603474338EB0BB79730F2410BF1721
```

## 免责声明

这是个人设备故障排查中产生的实验性绕过方案，不保证适用于任何其他设备，也不保证长期稳定或彻底修复根因。请自行评估风险，不要用于绕过真实的过热、供电或其他硬件保护。源码的公开可见不自动代表授予特定开源许可证；许可证由仓库作者另行选择。
