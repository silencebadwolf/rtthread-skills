---
name: rtconfig-kconfig-sync
description: 当修改 RT-Thread 项目的 rtconfig.h/.config/Kconfig 或执行 scons --menuconfig/defconfig/genconfig 时自动触发，确保配置同步。
version: 1.2.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: ['embedded', 'mcu', 'rt-thread', 'kconfig', 'scons', 'config-sync']
    related_skills: ['embedded-mcu', 'embedded-environment-config', 'gcc', 'keil']
---

# RT-Thread rtconfig.h 与 .config 同步检查

## 触发条件

当执行以下操作时自动触发：
1. 修改 `rtconfig.h`（手动添加宏）
2. 修改 `.config`（手动添加选项）
3. 执行 `scons --menuconfig` / `--defconfig` / `--genconfig`
4. 编译时出现 `RT_USING_XXX` 未定义错误

## 核心概念

RT-Thread 配置系统基于 Kconfig，核心链路：

1. `Kconfig` 声明配置选项（`config BSP_USING_XXX`）
2. `scons --menuconfig` 交互式选择，写入 `.config`
3. `scons --defconfig` 从 `.config` 生成 `rtconfig.h`
4. `scons --genconfig` 从 `rtconfig.h` 反向同步 `.config`

**关键点**：
- `.config` 是配置源头（由 menuconfig 或手动编辑产生）
- `rtconfig.h` 是 C 头文件（由 defconfig 生成，供编译使用）
- 两者之间的宏映射不是简单的一一对应，涉及前缀转换（`CONFIG_XXX` → `RT_USING_XXX`）

## 检查步骤

### 1. 检查同步状态

```bash
# 对比 .config 和 rtconfig.h 中的宏
diff <(grep -E "^CONFIG_" .config | sort) \
     <(grep -E "^#define RT_USING" rtconfig.h | sed 's/#define //' | sort)
```

### 2. 如果手动改了 rtconfig.h

**必须执行**：
```bash
scons --genconfig  # 反向同步 .config
```

**验证**：
```bash
grep "CONFIG_BSP_USING_XXX" .config  # 应该存在
```

### 3. 如果手动改了 .config

**必须执行**：
```bash
scons --defconfig  # 重新生成 rtconfig.h
```

**验证**：
```bash
grep "RT_USING_XXX" rtconfig.h  # 应该存在
```

### 4. 如果新增 BSP 选项

**检查 Kconfig**：
```bash
# 在 BSP 目录下的 Kconfig 中查找
find . -name "Kconfig" -exec grep -l "BSP_USING_XXX" {} \;
```

**如果缺失，添加**：
```kconfig
config BSP_USING_XXX
    bool "Enable XXX"
    default n
    select RT_USING_YYY  # 如果有依赖
```

## 常见错误

### 错误 1：手动改 rtconfig.h 没同步 .config

**症状**：用 `scons --menuconfig` 改选项无效，`.config` 是 `not set`

**修复**：
```bash
scons --genconfig  # 同步
```

### 错误 2：新选项没在 Kconfig 定义

**症状**：`scons --menuconfig` 看不到新选项

**修复**：在 BSP 或相关模块的 `Kconfig` 里添加 `config BSP_USING_XXX`

### 错误 3：编译报宏未定义

**症状**：`error: 'RT_USING_XXX' undeclared`

**修复**：
1. 检查 `.config` 里是否有 `CONFIG_XXX=y`
2. 如果没有，用 `scons --menuconfig` 启用
3. 或手动加到 `.config`，再 `scons --defconfig`

### 错误 4：package 宏消失

**症状**：`scons --defconfig` 后 `PKG_USING_*` 宏在 rtconfig.h 中消失

**修复**：
1. 确认 package 的 `Kconfig` 中有对应的 `config PKG_USING_XXX`
2. 确认 `.config` 中有 `CONFIG_PKG_USING_XXX=y`
3. 执行 `pkgs --update` 确保 package 已下载
4. 重新 `scons --defconfig`

## 最佳实践

1. **优先用 `scons --menuconfig`**（自动同步，最安全）
2. **如果 TUI 不可用**：
   - 编辑 `.config`（源头）
   - 执行 `scons --defconfig`（重新生成 `rtconfig.h`）
3. **如果必须手动改 `rtconfig.h`**：
   - 改完后执行 `scons --genconfig`（反向同步 `.config`）
4. **新增选项前先查上游/原生开关**：
   - 先在 RT-Thread、BSP、厂商 SDK、已有 `Kconfig` 中搜索是否已有控制项
   - 例如 FinSH/MSH 已有 `RT_USING_MSH`、`RT_USING_FINSH`、`FINSH_USING_MSH`
   - 若已有原生开关能满足需求，直接复用，不要自建重复 wrapper
5. **新增选项**：
   - 先在 `Kconfig` 里定义
   - 再用 `scons --menuconfig` 启用
6. **导出工程文件**：
   - `CMakeLists.txt`、MDK/IAR/VS Code 工程文件是 SCons 导出物
   - 新增/移动源码时先改 `SConscript`，再重新导出
   - 不要直接手改生成的工程文件

## 注意事项

- 不同 RT-Thread 版本的 Kconfig 结构可能不同，操作前先确认版本
- BSP 的 Kconfig 路径因芯片厂商而异，用 `find` 命令定位
- `scons --defconfig` 和 `scons --genconfig` 的行为可能因版本有差异
- 某些旧版 BSP 可能不支持 `scons --genconfig`

## 参考

- RT-Thread 文档：https://www.rt-thread.io/document/site/programming-manual/basic/basic/#内核配置
