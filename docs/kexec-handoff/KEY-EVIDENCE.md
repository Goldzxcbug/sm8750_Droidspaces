# 关键证据索引

先读每轮 `review.json`（如有），再对照原始 pstore 和当轮 state。所有 raw 都按原始字节复制；下表概述并不将不同条件的轮次视为单变量实验。

| 轮次/主题 | 原始或直接证据 | 可以说明什么、仍缺什么 |
| --- | --- | --- |
| 最初KCFI与错误IMEM | [validation](evidence/initial/validation.json)、[历史错误补丁](evidence/initial/previous.patch)、[链接反汇编](evidence/initial/machine_kexec-linked.asm) | 错误地址及早期插桩被撤销；局部KCFI检查修正。历史错误补丁不可重用。 |
| R2/R3目标入口 | [R2 raw](evidence/round2/pstore-after-exec.txt)、[R3 raw](evidence/round3/pstore-after-exec.txt) | 当时特定见证镜像进入目标入口及MMU前阶段；不能泛化为所有镜像或完整Android成功。 |
| R7安全SP | [raw](evidence/round7/pstore-after-exec.txt)、[state](evidence/round7/device-test.json) | 安全carveout清页路径SEA；没有实时EL2/TZ ACL证明。 |
| R11与R13 TZ/CMA | [R11 raw](evidence/round11/pstore-after-exec.txt)、[R13分配追踪](evidence/round13/cma-trace-instance.txt) | 跳过SP后在CMA清页异常；另一源启动追踪到同PA的TZ日志分配，不能当成前一轮实时owner。 |
| R14 UFS阻断 | [raw](evidence/round14/pstore-after-exec.txt)、[实际DT审计](evidence/round14/loaded-fdt-audit.json) | 保留TZ后越过旧CMA故障，UFS/PHY失败导致首次挂载失败。 |
| R24越过时钟等待 | [raw](evidence/round24/pstore-after-exec.txt)、[review](evidence/round24/review.json) | HALT_SKIP后callback/原BCR释放通过，随后SEA缺PC/FAR；跳过等待不是物理时钟正常证明。 |
| R30 GPU页来源 | [raw](evidence/round30/pstore-after-exec.txt)、[review](evidence/round30/review.json)、[原807字节page_owner记录](evidence/secure-pool-readonly-review/r30-pfn-884466/archive-match-1.txt)、[大档案查找依据](evidence/secure-pool-readonly-review/r30-pfn-884466/lookup.json) | clear_page访问PA0x884466000发生SEA；同源分配历史来自GPU安全路径。历史分配不是故障时固件ACL。 |
| R35用户态故障 | [raw](evidence/round35/pstore-after-exec.txt)、[review](evidence/round35/review.json) | init/APEX已运行，用户DABT及boringssl自检失败重启；隔离见证有损坏，不能宣布GPU/TLS根因已定。 |
| R38 GPI故障 | [raw](evidence/round38/pstore-after-exec.txt)、[实际ELF与源码窄审](evidence/kgsl-blocked-r38-fault-review/fault-review.json)、[原GPI ELF](evidence/kgsl-blocked-r38-fault-review/msm_gpi.ko) | timeout路径NULL解引用与PC/0x128相符；起始超时原因未知，raw指令字与ELF一处不一致按原样保留。 |
| R39正常目标对照 | [review](evidence/round39/review.json)、[图形检查](evidence/round39/observed-graphics.json)、[原始notes](evidence/round39/observed-notes.bin) | 68e8默认诊断关闭、原模块时普通启动通过；不验证kexec专用条件。 |
| R40新GPI选择遗漏 | [review](evidence/round40/review.json)、[采用路径独审](evidence/gpi-event-r40-payload-runtime-review/audit.json) | 原normal模块清单未保证采用新版GPI；不能用该轮评估NULL修复效果。 |
| R41人工介入 | [review](evidence/round41/review.json)、[屏幕/主机状态核对](evidence/round41/screen-state-discrepancy-review.json)、[额外恢复后raw](evidence/round41/installed-recovery-capture/pstore-console.stdout.bin) | 用户手动进入fastboot，后续日志跨恢复启动；不能认定完整自然复位链。 |
| R42自动fastboot | [review](evidence/round42/review.json)、[用户确认](evidence/round42/user-reboot-observation.json)、[恢复后的raw](evidence/round42/recovery-after-fastboot/first-post-exec-pstore.stdout.bin)、[原字节独审](evidence/gpi-event-r42-raw-result-review/audit.json) | 单次execute后自动fastboot；缺可靠目标身份、首次异常及新GPI采用证明。 |
| R43恢复GPU | [state](evidence/round43/device-test.json)、[dmesg](evidence/round43/observed-dmesg.stdout.bin)、[用户桌面触摸确认](evidence/round43/user-display-touch-confirmation.json) | 同7278 Image完整Android和GPU通过；此轮没有执行kexec。 |

GPI新模块的[构建输入](evidence/gpi-event-timeout-trace-module/input-provenance.json)、[构建结果](evidence/gpi-event-timeout-trace-module/build-result.json)、[验证报告](evidence/gpi-event-timeout-trace-module/validation.json)及[ELF](evidence/gpi-event-timeout-trace-module/msm_gpi.ko)也已保存。它们证明主机构建产物及兼容性检查，不证明目标在R40—R42采用或正确运行。

更多边界见 [history-selection](reviews/history-selection.json) 和 [latest-selection](reviews/latest-selection.json)；其中建议导出路径不一定等于本包最终路径，以 [manifest](manifest.json) 映射为准。
