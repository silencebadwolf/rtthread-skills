---
name: rtthread-bsp-builder
description: 克隆或更新官方 RT-Thread 仓库，可按需让用户选择分支、标签或提交，查找指定芯片或板卡的官方 BSP，检查 BSP 的 README 与 rtconfig，并按官方工作流推动其完成构建（GCC/MDK/IAR/RT-Studio）。当处理 RT-Thread MCU 或嵌入式项目，且需要回答"官方是否支持这个芯片或板卡"、选择版本、设置官方 BSP、运行 menuconfig/pkgs/scons 时使用。如果没有可信的官方 BSP，就明确停止，不要自行虚构或移植。
version: 1.1.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: ['rt-thread', 'bsp', 'mcu', 'gcc', 'keil', 'iar', 'scons', 'embedded']
    related_skills: ['embedded-mcu', 'embedded-environment-config', 'gcc', 'keil']
---

# RT-Thread 官方 BSP 构建助手

这个 skill 只适用于 **官方 `RT-Thread/rt-thread` 仓库中已经存在的官方 BSP**。

不要新建 BSP、不要从零移植芯片、不要克隆第三方 fork，也不要把“看起来差不多”的 BSP 当成可替代方案。如果不存在可信的官方 BSP，就明确说明并停止。

## 范围

本技能覆盖：

- 官方 `RT-Thread/rt-thread`
- 已存在于 `bsp/` 下的官方 BSP
- 根据 BSP README 支持的构建目标：GCC、MDK、IAR、RT-Studio
- 关键选择点上与用户交互确认

当前不在范围内的包括：

- 新 BSP 创建或新芯片移植
- 厂商 fork 支持
- 静默替换 BSP
- 自动烧录
- 自动安装系统级软件包
- 自动修改全局环境

## 构建目标选择

**不要假设 GCC 是唯一或优先目标。** 根据 BSP README 和用户需求决定：

| 目标 | scons 命令 | 典型产物 |
|------|-----------|----------|
| GCC | `scons` | `rtthread.bin`, `rtthread.elf` |
| MDK | `scons --target=mdk5` | `project.uvprojx` |
| IAR | `scons --target=iar` | `project.eww` |
| RT-Studio | `scons --target=eclipse` | `.cproject` |

如果 BSP README 明确推荐 MDK 或 IAR，不要强行走 GCC。

## 必须交互的节点

不要跳过会影响可复现性的关键决策。

必要时向用户确认：

1. **仓库版本**
   - 如果用户没有指定版本，要询问是使用：
     - 默认分支最新版本
     - 某个分支
     - 某个标签
     - 某个具体提交
   - 需要时可用 `scripts/list_refs.sh` 展示候选分支或标签。
   - 用 `scripts/ensure_repo.sh --dest <path> --ref <ref>` 检出指定版本。

2. **BSP 选择存在歧义时**
   - 如果存在多个较强候选 BSP，需要展示出来并让用户选择。

3. **构建目标**
   - 如果 BSP 支持多个构建目标，让用户选择。

4. **可能影响宿主环境的操作**
   - 安装 `scons`、`pkgs`、交叉编译工具链或系统软件包前，必须得到用户确认。

## 工作流程

1. **先明确目标**
   - 如果请求比较模糊，先问清楚具体芯片或板卡。
   - 如果没有指定 RT-Thread 版本，先问清楚要用哪个版本。

2. **确保官方仓库存在**
   - 使用 `scripts/ensure_repo.sh --dest <path>`。
   - 如需固定版本，增加 `--ref <branch|tag|commit>`。
   - 如果仓库已存在且有未提交改动，不要强行覆盖。

3. **查找 BSP**
   - 使用 `scripts/find_bsp.py --repo <repo> --query <chip|board>`。
   - 只有在结果是以下情况时才继续：
     - `exact`
     - 或单个 `strong` 官方匹配
   - 如果结果是 `ambiguous`，让用户选择。
   - 如果结果是 `none`，明确告诉用户没有官方 BSP，并停止。

4. **构建前先检查**
   - 使用 `scripts/inspect_bsp.py --repo <repo> --bsp <bsp>`。
   - 然后自行阅读 BSP README。
   - 特别关注：
     - 需要的工具链和前缀
     - 是否强制要求 `pkgs --update`
     - 是否必须走 `menuconfig`
     - 该 BSP 支持哪些构建目标（GCC/MDK/IAR/RT-Studio）

5. **先跑预检查**
   - 使用 `scripts/build_bsp.sh --repo <repo> --bsp <bsp> --preflight`。
   - 这一步会检查 BSP 路径、README 提示、`scons`、可选 `pkgs` 以及编译器前缀。
   - 如果宿主环境缺前置条件，就停止并明确告知缺什么。

7. **按官方顺序构建**
   - 先阅读 README，再按 README 执行。
   - 常见顺序是：
     1. `pkgs --update`，如果 README 或 BSP 要求
     2. 仅在有要求或用户明确希望改配置时，再执行 `scons --menuconfig` 或 `menuconfig`
     3. 根据目标执行构建：
        - GCC: `scons -j$(nproc)`
        - MDK: `scons --target=mdk5`
        - IAR: `scons --target=iar`
   - **Windows 用户**：RT-Thread Env 环境下 `pkgs` 可能是 `pkgs.exe`，不要只依赖 `command -v pkgs`。

8. **只有真实编译成功后才能宣称成功**
   - “预检查通过” 不等于 “编译通过”。
   - 汇报时要包含：
     - 仓库路径与检出版本
     - BSP 路径
     - 使用了哪个 README
     - 使用了哪个构建目标
     - 实际执行了哪些命令
     - 产物路径，例如 `rtthread.bin`、`.elf`、`.hex`、`project.uvprojx`
     - 仍然缺少的工具链或软件包条件

## 安全规则

- 如果 **没有官方 BSP**，必须明确说明并停止。
- 不要静默替换为别的 BSP。
- 除非用户明确要求，不要安装系统软件包、烧录硬件或修改全局 shell 启动文件。
- 更新或检出 RT-Thread 仓库时，不要覆盖脏工作区。
- 优先使用默认配置，不要随意引入不必要的 `menuconfig` 变更。

## 脚本说明

- `scripts/list_refs.sh`
  - 列出官方 RT-Thread 分支和标签，便于用户选版本。
- `scripts/ensure_repo.sh`
  - 克隆官方 RT-Thread 仓库，或安全地报告/更新已存在仓库。
  - 支持 `--ref <branch|tag|commit>`。
- `scripts/find_bsp.py`
  - 按芯片或板卡关键词搜索官方 BSP，并区分 exact / strong / ambiguous / none。
- `scripts/inspect_bsp.py`
  - 解析 BSP 并汇总 README、工具链和构建提示。
- `scripts/build_bsp.sh`
  - 执行预检查和默认 GCC 构建流程。

## 参考资料

- `references/common-build-flow.md`
  - 对澄清目标、选择版本、定位 BSP、预检查、构建和汇报的决策规则说明。
- `references/common-failures.md`
  - 常见 RT-Thread BSP 构建失败场景，以及下一步该检查什么。

## 推荐默认做法

- 优先使用官方仓库，而不是镜像或 fork。
- 优先以 BSP README 为准，而不是泛泛的 RT-Thread 通用建议。
- 根据 BSP README 推荐的构建目标来选择，不要默认假设 GCC。
- 如果 README 要求 `pkgs --update`，不要静默跳过。
- 如果因为缺少工具链而无法继续，要明确告诉用户缺的编译器前缀或环境变量。
- `pkgs` 检测应支持 Env 下的显式路径（如 `pkgs.exe`），不能只依赖 `command -v pkgs`。

