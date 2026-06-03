# rtthread-skills

SKILLs for RT-Thread & Embedded System Development

## 技能列表

| 技能 | 说明 | 适用范围 |
|------|------|----------|
| `rtthread-bsp-builder` | 查找官方 RT-Thread BSP 并按 BSP README 推动构建 | 官方 BSP + GCC/MDK/IAR/RT-Studio |
| `rtconfig-kconfig-sync` | `.config` / `rtconfig.h` / `Kconfig` 同步检查 | RT-Thread 配置系统 |

## 贡献规则

- 一个 PR 只新增或修改一个 skill 主题
- 通用 RT-Thread skill 不应把产品专属模板或编号项目布局作为默认行为
- skill 内容应以官方 RT-Thread BSP 布局和 BSP README 为主要依据
- 提交前请验证：frontmatter 校验、Python 语法检查、helper 脚本 help 输出

## 目录结构

```
skills/
├── rtthread-bsp-builder/    # RT-Thread 官方 BSP 构建助手
└── rtconfig-kconfig-sync/   # rtconfig 与 Kconfig 配置同步
```
