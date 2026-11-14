# SM8750 Android kexec 交接入口

日期：2026-11-14。开发分支：`kexec`。设备：OnePlus Pad 2 Pro / SM8750，槽位 `_a`。

**完整 Android 经 kexec 启动尚未成功。最后一次实际 kexec 是 R42；最后一次普通临时启动是 R43，原 GPU、桌面和触摸已恢复正常。R43 没有执行 kexec。** 本包整理已有材料，没有再重启或测试设备。

## 接手时先看

1. 本页和[关键证据索引](KEY-EVIDENCE.md)。
2. [完整排查记录](../kexec-handoff-status.md)，尤其第59—66节的 GPI、最近失败和 GPU 恢复结果。
3. [43轮状态索引](round-index.json)：链接到当时的原始状态和日志。并非每一轮都执行过 kexec；普通启动、取证和装载前中止的轮次也保留。
4. [文件清单与原始哈希](manifest.json)、[历史证据选取说明](reviews/history-selection.json)、[近期证据选取说明](reviews/latest-selection.json)。

本包包含 699 份逐字复制的日志、原有报告、配置及取证附件，合计 57.76 MiB；另外提供本页、索引和校验工具。原始坏字、NUL、回卷和残片均保留，没有修补寄存器或从旧轮次补栈。另附[打包内容检查报告](reviews/export-content-audit.json)，未发现凭证/私钥等内容；检查规则和局限见报告。

## 当前能确定的结果

- 最初错误的固定 IMEM 写入及 `head.S` / `cpu-reset.S` 探针已撤销，保留局部 KCFI 和 KABI 修正。历史错误补丁位于 `evidence/initial/previous.patch`，仅用于复盘，不能作为当前补丁应用。
- 历史实测已经进入新内核；部分组合能完成存储挂载、第二阶段 init 和 APEX bootstrap。因此不能把所有失败都称为“没跳进新内核”。
- 已保存 SP 安全堆、CMA/TZ 日志缓冲及 GPU 分配页相关的同步外部访问异常。跳过 SP 堆、保留 TZ/GPU 内存属于诊断隔离，不是完整安全内存回收方案；page_owner 也不是固件实时 ACL 证明。
- UFS 辅助时钟失败曾阻断启动。现有 AH8、FORCE、SWCTRL 和 HALT_SKIP 等实验使部分组合越过该点，但修改了行为，不能当作最终硬件复位修复。
- R38 原 `msm_gpi` 的合法 NULL event 参数会在超时错误路径被解引用，实际 PC 和地址与模块指令相符。已保存 NULL 修复、构建结果及原/新 ELF；首次命令超时原因未知，新模块在后续失败现场是否实际运行仍未证实。
- R42 唯一 kexec 后，用户明确确认无人操作、自动进入 fastboot。之后又正常启动已安装系统收日志；没有可靠的新目标身份或首个故障，不能断言这轮仍是 GPI 崩溃。
- R43 撤销源 GPU 黑名单及 SF 停止流程，保持源 Image 逐字不变。Android完成、695个原模块、GPU及五个其他模块身份、SF/SS及同UUID均通过，用户确认“桌面和触摸都正常”。此前把只有ADB可用称为完整Android启动是不准确的。

## 最近三种内核身份

| 用途 | GNU build ID | Image SHA-256 |
| --- | --- | --- |
| 源：R43完整GPU普通启动，release `6.6.89-Gold_Bug_kexec_kgsl_binary_source_diag` | `72782e2196eb1c46c8c5205ccd93f2acf42de294` | `8401f353d7477c87db2e54ef5734ad2ac25acbe574a928b1c5b6ff82579f4f9e` |
| 目标：R38—R42使用的诊断Image，R39普通启动对照通过 | `68e85e134a894c34b5fef3ac30f4dd450d00a6b5` | `8824087346c58ea7ff57b31fdcee795c509f7cc58699c558b234f1417851130f` |
| 已安装、可正常启动的 `6.6.89-Gold_bug` | `931f89c6463a6af0eea9436b61f059f31e451f6a` | `c36d8c0f7d5f03ce3cc42c98b383166bc29ff838e677b765e56448d67211e980` |

已安装版本是 Gold_bug 自定义内核，不应称为未经修改的 OEM 内核。源7278仍含此前编译进去的诊断/交接改动，恢复GPU不等于更换成干净源内核。最后验证的源UUID是 `8212bfe6-d5ed-4c8b-be3f-dbecf7d93a1e`；此处是历史记录，不是本包发布时重新读取的设备状态。

配置及构建身份见 [source manifest](evidence/kgsl-blocked-quiet-source/manifest.json)、[target manifest](evidence/kgsl-binary-target/manifest.json)、[R43 boot manifest](evidence/source-full-graphics-baseline/manifest.json) 和[已安装版本只读提取记录](evidence/installed-kernel-baseline-audit/readback.json)。相关 `.config`、build-command/result 和 source-delivery-manifest 也在对应 `evidence/` 目录。

## 需要避免的误判

- R41 有用户手动进入 fastboot，时间未知；R42 明确是自动重启。不能混用两轮结论。
- R42 的 pstore 来自额外一次恢复启动之后，产生者没有可靠认证。缺少 nonce、build ID 或某条探针不证明目标未运行，也不证明异常消失。
- R43 的旧 `result-audit.json` 在用户回答之前冻结，里面的 physical confirmation pending 是历史状态。后来的[用户原话](evidence/round43/user-display-touch-confirmation.json)和[新版状态](evidence/round43/device-test.json)已确认桌面触摸正常；旧报告按原样保留。
- R42 review 中“下一步恢复GPU”已经由R43完成，不应误读为仍待进行。
- ABI/CRC和默认诊断关闭的普通启动通过，不能排除已启用的kexec专用路径、四个改装模块或探针本身的回归。当前没有证明唯一根因。
- 用户已经自行验证传统/文件两条kexec装载路径在当前情况无差异，不必重新把这个区别当作主要排查方向。

## 补丁与复现边界

正式改动保存在仓库 [other_patch](../../other_patch/) 中；[主kexec补丁](../../other_patch/kexec_kabi_6.6.89.patch)、[GPI NULL修复](../../other_patch/kexec_gpi_event_timeout_null_fix_6.6.89.patch)、[GPI观测补丁](../../other_patch/kexec_gpi_first_event_trace_diag_6.6.89.patch)、[GPI正常加载清单补丁](../../other_patch/kexec_gpi_initramfs_load_diag_6.6.89.patch)和[恢复完整GPU启动参数补丁](../../other_patch/kexec_source_full_graphics_boot_6.6.89.patch)均保留。

用户要求先改补丁，再应用到独立的 `out/` 副本，不直接修改仓库 `kernel/`。不要复用旧GPU禁用/SF停止runner作为正常源启动流程。当前缺少“完整GPU源 + 未改已安装目标/原模块”的新kexec对照；该目标只完成了只读提取，尚未跳转验证。

这里的3个小型 `.ko` 只供离线ELF核对；它们的存在和哈希不代表已经在目标运行。完整 Image、boot.img、vmlinux、initramfs、约44MB的page_owner压缩档及完整源树未放进本包，仍在原主机 `out/` 中；详见 [未打包制品说明](LOCAL-ARTIFACTS.md)。本包不是可直接执行的刷机/测试脚本合集。

原报告里引用的 `/home/gold/.../out/...` 是采集时主机路径。按 `manifest.json` 的 `source_path → path` 映射查找本包文件；未映射的依赖说明没有随包复制，不能声称完整依赖闭包已交付。

## 离线核对

在本目录执行：

```sh
python3 verify.py
sha256sum -c SHA256SUMS
rg -a -n 'gpi_send_cmd|Kernel panic|KSEA|KUSR' evidence/round38/pstore-after-exec.txt
```

`verify.py`只检查本地文件字节，不访问ADB/fastboot、不重启设备。坏字日志按原始LF计行；文本查看器的显示或decode替换字符不是新的原始证据。
