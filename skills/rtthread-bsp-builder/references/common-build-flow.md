# Common build flow

## Goal

Take a user request like “帮我把 RT-Thread 的某个芯片/开发板工程拉起来并编译过” and turn it into a safe, repeatable workflow that only uses **official BSPs** and keeps the user involved in key choices.

## Decision tree

### 1. Clarify the target

Input may be any of these:

- exact BSP name: `stm32f103-blue-pill`
- chip family: `stm32f103`
- board name: `blue pill`
- vendor board: `ESP32_C3`, `artpi`, `n32g452xx-mini-system`

If the request is vague, ask before guessing.

### 2. Clarify the repository version

For reproducibility, prefer asking the user which official repo version to use:

- latest default branch
- specific branch
- specific tag
- specific commit

Use `scripts/list_refs.sh` when the user wants choices.
Use `scripts/ensure_repo.sh --dest <path> --ref <ref>` to pin the checkout.

### 3. Confirm official support

A target counts as supported only when it exists under `bsp/` in the official RT-Thread repo.

Good:
- exact directory exists
- README exists for the BSP or BSP family
- `SConstruct`/`rtconfig.py` exists in the BSP

Bad:
- only a blog/tutorial exists
- only a fork exists
- only a similar chip exists
- only Studio-generated artifacts exist with no official BSP path

If unsupported, stop with a clear message such as:

> 没在官方 `RT-Thread/rt-thread` 的 `bsp/` 里找到这个芯片/开发板的官方 BSP，所以这个 skill 按约定不会替你硬造工程。

### 4. Resolve BSP selection strictly

Use `find_bsp.py` results this way:

- `exact` → can proceed
- `strong` with exactly one candidate → can proceed
- `ambiguous` → ask the user to choose
- `none` → report unsupported and stop

Do not auto-pick from weak fuzzy matches.

### 5. Inspect the BSP

Check these files first:

- `README.md` / `README_zh.md` / `readme.md`
- `rtconfig.py`
- `SConstruct`
- `.config` if present

Extract:
- compiler family (`gcc`, `keil`, `iar`, etc.)
- compiler prefix from `rtconfig.py`
- whether `RTT_EXEC_PATH` / `RTT_CC_PREFIX` / `RTT_CC` are used
- whether `pkgs --update` is required
- whether `menuconfig` is required before first build

### 6. Choose the build stance

#### Proceed

Proceed only if there is a credible GCC path:
- README says GCC is supported, or
- `rtconfig.py` clearly supports `CROSS_TOOL='gcc'`

#### Stop and report

Stop if:
- the BSP is clearly MDK/IAR-only,
- GCC support looks absent or broken by design,
- required compiler prefix is unknown and cannot be inferred,
- mandatory prerequisites are missing.

### 7. Preflight

Before the real build, verify:

- repo exists
- BSP exists
- `scons` exists
- compiler binary exists or the exact expected prefix is known
- package manager command requirements are understood

Do not call it “success” yet.

### 8. Build

Typical order:

1. enter BSP directory
2. `pkgs --update` if the BSP/README requires packages
3. optional `scons --menuconfig` when needed
4. `scons -j$(nproc)`

Keep environment changes local to the process when possible, for example:

```sh
RTT_EXEC_PATH=/opt/arm-none-eabi/bin scons -j$(nproc)
```

instead of editing shell startup files.

### 9. Report

A good completion report contains:

- repo path
- checked-out branch/tag/commit
- BSP path
- official README used
- whether official support exists
- GCC toolchain prefix expected
- commands run
- whether build succeeded
- artifact files found
- exact blockers if it failed
