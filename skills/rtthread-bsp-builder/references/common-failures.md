# Common failures

## 1. `scons: command not found`

Meaning:
- SCons is not installed or not in PATH.

What to report:
- The BSP uses SCons for build orchestration.
- Ask the user whether to install/fix SCons.

## 2. `pkgs: command not found`

Meaning:
- RT-Thread Env / package tool is not installed or not exposed in PATH.

What to report:
- Some BSPs require `pkgs --update` before they can compile because HAL/CMSIS/packages are pulled on demand.
- Do not fake success if this step is mandatory.
- Ask before installing anything.

## 3. Missing cross compiler

Typical examples:
- `arm-none-eabi-gcc: not found`
- `riscv64-unknown-elf-gcc: not found`
- `riscv32-esp-elf-gcc: not found`

What to inspect:
- `rtconfig.py` for `PREFIX`
- env vars `RTT_EXEC_PATH`, `RTT_CC_PREFIX`, `RTT_CC`
- README setup steps

What to report:
- Exact compiler prefix expected
- Exact env var/path that would satisfy the BSP
- Ask before installing toolchains

## 4. README says GCC is supported, but only IDE projects are obvious

Meaning:
- GCC may still be supported through `SConstruct` + `rtconfig.py`, even if README examples focus on MDK/IAR.

What to do:
- Check `rtconfig.py` before rejecting.
- If `CROSS_TOOL='gcc'` and GCC tools are defined, a GCC path likely exists.

## 5. Packages not pulled yet

Typical symptom:
- missing HAL/CMSIS/package headers or sources

What to do:
- Search README for `pkgs --update`
- If required, run that before blaming the BSP

## 6. `menuconfig` required before first build

Typical symptom:
- config-dependent headers/files missing
- README explicitly says to refresh config first

What to do:
- Use the official step order
- Prefer `scons --menuconfig` if the BSP documents it that way
- If config choices materially affect the build, interact with the user instead of changing options silently

## 7. Dirty repo blocks update or ref switch

Meaning:
- local modifications exist in the RT-Thread repo clone

What to do:
- Do not hard reset or stash silently
- Ask the user before destructive cleanup

## 8. No official BSP found

Meaning:
- the target is unsupported in official `RT-Thread/rt-thread`

What to report:
- Say there is no official BSP in `bsp/`
- Optionally give nearby candidates
- Stop instead of generating a fake board port

## 9. Ambiguous official matches

Meaning:
- multiple official BSPs look plausible for the user's chip/board query

What to do:
- show the top strong candidates
- ask the user to choose
- do not auto-pick silently when reproducibility matters
