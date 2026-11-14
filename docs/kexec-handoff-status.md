# kexec 启动安卓内核：问题交接文档

日期：2026-11-14（R42单次跳转后自动回fastboot；R43恢复GPU，完整源Android及桌面触摸已通过，尚未执行新kexec）
设备：OnePlus Pad 2 Pro（OPD2413 / OP615EL1，SM8750，A/B 槽位 `_a`，16GB）

---

## 一、目标

在 Android 里用 kexec 装载并跳转到另一个内核，并使目标 Android 完成启动。目前以同一 6.6.89 基底和匹配的厂商模块做交接诊断，源、目标的诊断配置并不完全相同；通过临时 boot 正常启动只验证源镜像可运行，不能作为 kexec 成功。

---

## 二、当前状态一句话

最新R43已撤销源启动的`module_blacklist=msm_kgsl`和SurfaceFlinger停止流程，保持源7278 Image逐字不变。普通临时启动实测Android完成、695个原模块、原GPU及另外五个模块身份、BTF和同UUID均通过，用户确认“桌面和触摸都正常”。此前GPU禁用源只有ADB/内核运行证据，不能称为完整Android正常启动。R42用户明确确认无人操作而自动进入fastboot，不能沿用R41人工介入的分类；目标运行身份、新GPI采用和复位原因仍未取证。诊断Image及模块改动尚未排除回归，完整kexec修复未完成。详见第六十五、六十六节。

第三十八轮已完成源GPU从未加载的单次kexec对照：源7278的693模块、八处缺席、BTF和身份通过，临时停止surfaceflinger后同UUID稳定60.439秒，装载与233关键页等检查均通过；目标仍失败。保存的首个完整异常现场为内核态DABT，`gpi_send_cmd+0x180 [msm_gpi]`访问`0x128`。实际模块证实合法event调用传NULL，而超时分支无条件读取channel字段，存在明确的二次空指针缺陷。已保存独立vendor修正补丁并完成完整模块重编与主机验证；R40和R41均未取得新模块运行采用的可靠证明，初始命令超时的原因仍未知，详见第五十九至六十四节。

第三十九轮已用同一实际目标68e8 Image作普通临时启动，完整Android、695个原厂模块、BTF及GPI/SPI/GPU等六个GNU note通过，该轮UUID `55cf2d03-4429-4d36-8115-8d3dbe078e57`。该对照使用默认关闭的kexec诊断参数和原厂模块，不能单独区分热交接状态与kexec专用参数/三个改装模块，详见第六十节。R40随后完成一次跳转并恢复安装版`6.6.89-Gold_bug`/BID931f，当时UUID为`16b13af7-b3d4-48e7-a4e5-d9e09d87d4af`。R41单次跳转后捕获过原厂内核ADB，之后用户确认手动进入fastboot，不能把fastboot终态或等待未完成归为自然失败链。经一次普通fastboot reboot收日志后，当时安装版931f、UUID `5719bd82-5a19-4cb0-a3d3-2d036f861682`，Android/root/图形服务、watchdog0/kptr2及helper缺席通过；kexec_loaded接口不存在。当前debugfs挂载已原样记录，未作额外卸载。完整kexec启动尚未验证成功。

第三十五轮的前次kexec跳转已实际运行同一目标68e8：源缓存、实际装载DT与主机9段GPU blob逐字一致，运输后缀正确裁掉，7,927个交接控制分配页及233个目标关键页核对通过；审计后再次完成同源SG采样才唯一execute。目标完成第一阶段、SELinux初始化及APEX bootstrap，首次保存用户异常是1.848秒linkerconfig的DABT（ESR92000005、FAR28），随后modprobe同类失败，2.426秒明确以boringssl-self-check-failed有序重启。KGPUM3仅NOMAP全位图完整，reserved位图/摘要和取指字受损、nonce未留存，不能宣称完整隔离或TLS根因已经证实。详见第五十五节。

第三十轮已取得完整SEA及原始调用栈：新内核在0.712秒解包initramfs、分配shmem页时，于`clear_page+0x18`的`DC ZVA x0`访问PA `0x884466000`发生外部访问异常，随后明确panic。同一轮源page_owner归档唯一匹配该PFN，来自surfaceflinger的`kgsl_system_alloc_pages → kgsl_allocate_secure → kgsl_allocate_global → send_start_msg`。实际KGSL模块还确认安全分配会从VMID3赋给10，而六个相关platform driver的shutdown均为空；globals释放属于remove路径，普通kexec不会调用。R30这一处SEA收敛到GPU安全内存的交接缺口；尚未取得交接瞬间SG/固件ACL，也未验证修复，不能把历史分配记录当作实时归属证明，亦不能外推为全部后续异常的唯一原因。

第三十一轮目标4646的五段GPU SG装载冲突检查及跳转前重复采样均通过，但实际隔离标记没有留存，不能认定隔离有效。该轮完整记录确认init完成第一阶段、执行selinux_setup后，在libcrypto用户态发生level-1 translation fault（ESR92000005、fault addr2），SIGSEGV11导致PID1 panic，详见第五十节。第三十二轮同一4646 Image已在正常临时启动中完整运行Android，695个原厂模块及BTF通过，当轮UUID `52ac911d-1444-400b-bbe6-308c14dfe965`。该对照只有普通启动/默认关闭路径，不能排除热启动专用诊断设置或直接指定某个交接根因。

第二十九轮同b04目标已运行第二阶段init及apexd-bootstrap，约1.828秒同样在clear_page清页发生SEA，但当轮FAR/符号之外多项字段受损，候选PA `0xaf32a000`仍有映射前提。R30实际memstart不能追认为R29实测；也不能直接宣布两轮全部异常、SIGILL和持久日志坏字都由GPU导致。

第二十八轮同镜像仅保存源交接尾、没有目标console；第二十九轮的正证表明同镜像可以进入目标。不能据前一轮缺日志认定目标完全未运行或归因晚期观察器，也不能把两轮的不同表现直接归到同一已知机制。

截至第二十七轮，`kexec -s -l`（`kexec_file_load`）装载成功，诊断配置下目标已完成UFS枚举、F2FS/EROFS/EXT4挂载并进入第二阶段init。第二十六轮明确由已启动的apexd-bootstrap PID354收到signal4（SIGILL）触发重启；第二十七轮保持Image不变、只启用既有信号打印参数，已保存APEX挂载及`OnBootstrap done`，随后仅留下linkerconfig exec-hook载荷和晚期PM/调度日志，约30.88秒后日志终止，最终恢复安装版。没有取得原始SIGILL PC，也没有后续停滞任务状态；不能宣布SIGILL已修复、指定linkerconfig故障或确定看门狗复位。完整目标Android仍未启动，安全内存隔离和时钟检查绕过也尚未收敛为正式修复。

第二十五轮先取得六个SCSI磁盘、分区及dm设备和`bootstrap-apexd-failed`正常重启证据。第二十六轮仅删除逐设备关机EMERG打印后，保住了上述前因；保存环仍满，不能根据缺少SEA记录排除更早事件。

此前直接阻塞是辅助叶时钟使能超时−16，导致UFS失败和首次挂载失败；第二十轮已确认GDSC上电完成、父根状态on且CFG硬件控制位已清，叶时钟仍off。第二十二、二十三轮正常启动对照表明：PHY两个本地寄存器也读0，但AUX在首次PHY采样前已有零计数enable窗口、后续aux返回0且Android成功，支持原流程依赖已有时钟引用的假设。

第二十四轮只对单AUX叶启用HALT_SKIP，原复位顺序不变：完整正记录确认leaf callback返回0、PHY power-on返回0、原BCR deassert成功，HBA HW_VERSION重新读到60010000。随后1.828530秒出现同步外部访问异常，ESR96000010，保存日志在下一行终止，没有此次异常的PC/FAR/栈。因此确已越过旧软件−16阻断，但不能证明物理AUX正常，也不能把后面的异常认定为独立原因或PCS故障。第二十五轮已补SEA入口记录并实际跳转，结果推进到上述用户态重启，但满环未保留早期上下文；跳过等待的ret0仍不是最终修复。

此前第七轮已抓到直接 panic：目标约 1.175 秒创建 `qcom,secure-sp-tz` 时，首次清零物理 `0x9b280000` 的 256 KiB carveout 发生同步外部访问异常。安全内存归属跨 kexec 遗留是早期重点假设，尚无实时 EL2/TZ owner 查询，不能视为已证实的完整根因。

第八、九轮均在源端 SP-TZ 回收调用前留下最后记录。第十轮在冻结 source8dde 上加入可选只读探针后，已取得正记录：`assign-enter valid=1 → lower-enter valid=1 frame_match=1 → smc-before fid=0x42000c16`。因此最后可观察位置已从“调用前”推进到实际厂商 SCM 模块中的 `BL __arm_smccc_smc` 前；之后没有保存 after/call-return/reclaimed/目标身份，设备复位。仍不能把缺少返回日志绝对等同于 SMC 未返回或已知固件拒绝原因。

第十一轮隔离已实际执行：源保留 SP-TZ 归属、不调用逆向 SCM，目标实际装载 DT 中只禁用两块 SP heap 子节点，两个 reserved-memory 节点全部属性保持不变。目标已越过 qcom_dma_heaps 初始化，随后在约 1.211 秒由 minidump 申请默认 CMA 内存时，于 clear_page 的 DC ZVA 再次触发外部中止，故障 PA 为 `0xecca0000`。因此只跳过 SP 堆还不能启动完整 Android，不能作为最终修复。

随后用同一源 Image 加 CMA 启动追踪：第十三轮在完整专用 trace instance 中记录到 `tz_log_probe` 成功分配 `0xecca0000/0x20000`，另有三个同驱动缓冲区；目前追踪无 overrun/dropped。它把后续重点收敛到 TrustZone 日志 DMA 缓冲的跨 kexec 交接，但这是新源启动中的分配记录，不能倒推为第十一轮实时 owner 的直接证明。正在核查实际厂商模块的固件注册、保护和清理路径。

第十四轮对照已执行一次：新源动态捕获四块 TZ 日志缓冲，并在实际目标 DT 中逐块保留为 no-map。目标原 F93 已越过旧 CMA 崩溃点，`minidump.ko` 在1.054秒明确加载成功，继续运行至11.225秒。新的启动阻塞为 UFS PHY 辅助时钟启用失败：`gcc_ufs_phy_phy_aux_clk` 报off超时，PHY返回−16，UFS probe最终返回−5；PID1找不到启动分区，first stage mount失败后退出，触发 `Attempted to kill init! exitcode=0x00007f00`。下一重点是 UFS/时钟的热交接，不能将它误报成仍卡在 CMA。

第十五轮也已实际执行一次，目标7cfb仍因UFS初始化失败而未能启动完整Android。新日志确认：父时钟SRC早期已成功启用，UFS请求时已有引用，随后子支路真实callback返回−16；首次BCR前AH8_CFG=`0x183c`，四个时钟请求控制位`0x3c`确实保留。当前重点是AH8请求与UFS复位的交接，尚未证明清位可以修复，也不把SRC既有引用称为已知critical vote。

第十六轮清AH8实验已执行一次：完整HBA采样显示entry=`0x183c`、pre-BCR=`0x1800`，但PHY仍返回−16。本轮父SRC从count0实际执行启用callback并返回0，子支路仍off，因此仅清AH8、或仅以父引用计数跳过callback解释失败，都不足以覆盖本轮证据。时钟dump仍为CMD_RCGR=`80000000`、CFG_RCGR=`00100001`、CBCR=`88000001`，下一步核查SRC硬件自动门控和复位/PHY供电依赖。

第十七轮又完成一次对照：实际KUFSAUX1标记确认只给aux SRC启用既有FORCE机制，五组完整dump的CMD_RCGR均由前轮80000000变为00000002（ROOT_OFF清、ROOT_EN在），但叶CBCR仍88000001、status stuck off、callback仍−16。AH8清位也有完整一致记录。故剩余故障已缩到下游叶门控、复位或PHY电源域条件，不能继续只归因父RCG没开；尚未直接测得哪一个下游条件不满足。

第十八轮已取得首次真实PHY电源域采样：GDSC由OFF/DOWN变为ON/UP，qref原调用返回0，但父根on、子支路off和PHY−16继续复现。此轮排除了“首次GDSC一直未完成上电”这一解释，仍未区分PHY局部控制/复位、下游门控或硬件控制模式。详见第三十六节。

第十九轮已验证根的软件控制对照：四组完整CFG从前轮00100001变为00000001，CMD仍00000002、叶CBCR仍88000001，故去除根HW控制模式与保留FORCE的组合仍不足以恢复aux。首次GDSC仍由OFF/DOWN到ON/UP。损坏的KUFSAUX2/首组CFG没有用于修补或证明，详见第三十七节。

第二十一轮尝试正常启动对照：临时内核842能正常启动，但所附ramdisk没有使新PHY模块和参数生效，不能用作寄存器对照。实际FDT的initrd起止与原启动完全相同。后续改用独立、默认关闭的内建观察点，继续保持原厂模块和原复位/时钟流程。详见第三十九节。

第二十二轮内建观察已实际生效：精确匹配原厂PHY身份和四处指令，在首个被观察的power-on中取得七条完整记录；两处0/0采样随后伴随aux返回0、UFS枚举及Android完成。没有采集BCR返回/寄存器或原调用栈，不宣称完整复位序列已经实测等同。详见第四十节。

第二十三轮保持R22 Image及原厂模块，只通过临时boot参数启用既有时钟事件。专用instance完整保存3082条、8CPU无丢失；正常leaf的实际enable窗口早于GCC注册完成和首次PHY采样。它与CCF保留bootloader已有时钟的机制吻合，但未证明唯一holder或BCR就是唯一硬件条件，详见第四十一节。

第三十轮已自动恢复安装版 `6.6.89-Gold_bug` / BID `931f89c6463a6af0eea9436b61f059f31e451f6a`，恢复UUID `49d71bde-6915-40a6-bd6a-96959e57f480`，Android/root、watchdog disable0及复核通过；temporary boot/helper/load/execute均1，安全池collector insmod/rmmod各1。第三十一轮已完成一次GPU安全页隔离配置的实际跳转：helper/load/execute各1，目标4646已运行到init，在libcrypto用户态访问地址2触发SIGSEGV并panic；实际KGPUM早期标记被满环裁掉，隔离执行仍未取证。设备随后自动恢复安装版931f、UUID `62826719-1cea-40ef-932c-8d88896b4212`，Android/root、watchdog0及前后同UUID复核通过；第三十二轮已再次普通临时启动同4646，Android正常。此后R33/R34均正常临时启动源842，但在元数据/表达容量守卫处停止，helper/load/execute全部0；R34源UUID为`d33443dc-8ee9-4956-929c-4c686a0c8a85`；此后R35新协议源4424已正常启动并完成一次kexec测试，源UUID为`985424e2-23f9-49f9-8137-5ce33ca95ef4`，曾恢复安装版UUID `e601cc28-9c73-4f43-99d7-24fadaba842b`。R36唯一临时源启动未通过，曾恢复安装版UUID `d91d837f-dc0c-46dd-ad1f-e06681d1edd3`；R37取得新源及KGSL拒绝、SF关键服务恢复链证据。R38随后完成一次源GPU缺席的kexec，保存GPI内核异常并恢复stock8936；R39已将同一68e8 Image普通临时启动到完整Android，该轮UUID `55cf2d03-4429-4d36-8115-8d3dbe078e57`；R40唯一跳转后恢复stock931f，当前UUID `16b13af7-b3d4-48e7-a4e5-d9e09d87d4af`，Android/root/图形服务正常、watchdog0。安装版没有kexec_loaded接口，未写成已读0。两SP堆、四TZ及既往GPU保留仍是诊断隔离，完整功能修复未完成。

所有新增内核/模块代码先保存补丁，再应用到独立 `out/` 副本，仓库 `kernel/` 未修改；旧 GIC/native 诊断差异也已补齐权威补丁并逐文件重放验证。第十三、二十三轮仅修改临时boot头中的受支持追踪参数，Image不变；第二十七轮只改目标启动参数，第二十八轮新增只读用户异常/任务观察补丁，第二十九轮未新增内核改动。未刷分区、未改变看门狗。用户已授权后续可逆诊断默认继续。详见第二十四至四十八节。

---

## 三、环境

### 设备

| 项 | 值 |
|---|---|
| 内核 | `6.6.89-Gold_Bug_kexec_kgsl_binary_source_diag`（当前R43普通临时启动，GNU 7278，完整GPU）/ `6.6.89-Gold_bug`（已安装可正常启动版本，GNU 931f） |
| Android | android15/16，GKI |
| Hypervisor | **Gunyah**（DT 有 `qcom,gunyah-hypervisor-1.0`；加载 `hvc_gunyah`、`qrtr_gunyah`、`gunyah_loader`、`gh_*`） |
| 启动参数 | 含 `kvm-arm.mode=protected`、`console=ttynull`、`qcom_geni_serial.con_enabled=0`、`loglevel=6` |
| boot_a 分区 | 100663296 字节 |
| MemTotal | 15802560 kB |

### 内核配置（关键项）

```
CONFIG_KEXEC_CORE=y
CONFIG_KEXEC=y
CONFIG_KEXEC_FILE=y
# CONFIG_KEXEC_SIG is not set
# CONFIG_KEXEC_SIG_FORCE is not set
# CONFIG_KEXEC_IMAGE_VERIFY_SIG is not set
CONFIG_MODVERSIONS=y
# CONFIG_MODULE_FORCE_LOAD is not set
# CONFIG_DEVMEM is not set          ← 用户态读不了物理内存
# CONFIG_PROC_KCORE is not set      ← 同上
CONFIG_CRYPTO=y
CONFIG_CRYPTO_SHA256=y
kexec_load_disabled = 0
```

### 工具

- `kexec-tools 2.0.32`，静态 aarch64，SHA-256 `d81e1b182deb8356bee6637a57feeddd75c253b1161a31bbb8550024a68bcc83`
- **选项语义（易错）**：`-s/--kexec-file-syscall` = `kexec_file_load`；`-c/--kexec-syscall` = 老 `kexec_load`

---

## 四、测试用的命令

```sh
su
cd /data/local/tmp/kx
cp /sdcard/kexec/kexec . && chmod 755 kexec

cp /sdcard/kexec/current-slot-a/Image ./Image          # 37,480,960 字节
cat /sys/firmware/fdt > ./live.dtb

./kexec -s -l ./Image \
  --initrd=/sdcard/kexec/ramdisk-with-bootconfig.img \
  --append="$(cat /proc/cmdline)"

cat /sys/kernel/kexec_loaded      # → 1
./kexec -e
```

### 准备物

- `Image`：从 `boot_a` 分区 header 偏移 4096 处按 `kernel_size` 提取，build-id 与运行内核一致（已核对）
- `ramdisk-with-bootconfig.img`：`vendor_ramdisk`（LZ4→cpio，63,072,256 B）+ `init_boot` ramdisk（5,765,480 B）字节拼接 → 68,837,736 B cpio → gzip，再用内核树里的 `tools/bootconfig` 把 `/proc/bootconfig` 追加到尾部（格式 `[initrd][data][size u32][csum u32]["#BOOTCONFIG\n"]`，符合 `init/main.c:get_boot_config_from_initrd()`）
- `/sdcard` 是 FUSE + `noexec`，**kexec 二进制必须从 `/data/local/tmp` 运行**

---

## 五、已确认的事实（有证据）

### 5.1 装载系统调用成功

- `kexec -s -l` 返回 0，`kexec_loaded` 由 0 → 1
- 这证明 `machine_kexec_prepare()` 返回 0，即 **`cpus_are_stuck_in_kernel()` 为假**
  （`arch/arm64/kernel/machine_kexec.c` 中该检查在装载期，返回 `-EBUSY`）

### 5.2 关机流程全部正常走完

用 `pr_emerg` 探针（级别 0，`console=ttynull` 下仍进 ramoops）实测，以下**全部打印**：

```
KT: enter                          ← 进入 kernel_kexec 跳转段
KT: after restart_prepare          ← reboot notifier 链正常返回
KT: after migrate_to_reboot_cpu
KT: syscore irq_gc_shutdown        ← syscore_shutdown 只有一个回调
KT: after syscore_shutdown
KT: after cpu_hotplug_enable
KT: after machine_shutdown         ← 220ms 完成
KT: before kmsg_dump
KT: before machine_kexec
KT: machine_kexec stuck=0 online=1 pkm=0
```

`device_shutdown()` 逐设备探针额外打印了 100+ 个设备名（`KT: dev ...`），说明设备关机遍历也走完了。

**结论：这些关机调用均已返回，没有卡在相应调用内。** 这不证明全部硬件 DMA、远程处理器或虚拟看门狗都已停止；没有 shutdown 回调的设备也会正常通过遍历。

### 5.3 `BUG_ON` 安全通过

```
KT: machine_kexec stuck=0 online=1 pkm=0
```

对应 `arch/arm64/kernel/machine_kexec.c`：

```c
BUG_ON(!in_kexec_crash && (stuck_cpus || (num_online_cpus() > 1)));
```

`stuck=0`、`online=1`，不会触发。

### 5.4 protected KVM **没有**生效（重要，推翻过此前的错误结论）

`pkm=0`。原因链：

- `is_protected_kvm_enabled()` → `cpus_have_final_cap(ARM64_KVM_PROTECTED_MODE)`
- 该能力 `matches = is_kvm_protected_mode()` → `kvm_get_mode() == KVM_MODE_PROTECTED`
- `early_kvm_mode_cfg()` 里有前置检查：
  ```c
  if (!is_hyp_mode_available()) {
      pr_warn_once("KVM is not available. Ignoring kvm-arm.mode\n");
      return 0;          // 参数被丢弃
  }
  ```
- `is_hyp_mode_available()` 要求 `__boot_cpu_mode[0]==EL2 && [1]==EL2`

设备跑在 Gunyah 之下，内核在 EL1，EL2 归 hypervisor，因此 **`kvm-arm.mode=protected` 被静默忽略**。
旁证：`/dev/kvm` 不存在、dmesg 里没有任何 kvm 相关消息。

**所以：不能再把失败归因于 protected KVM 的 CPU 安全检查。** `pkm=0` 不排除 Gunyah 的 Stage-2 权限、虚拟看门狗或其他固件状态交接问题。

### 5.5 `last_boot_reason` 的栈**不是**崩溃栈

`/proc/last_boot_reason` 会显示：

```
hard_reset;Boot reboot
KERNEL_SHD:
18382:kexec
notifier_call_chain+0x90/0x174
blocking_notifier_call_chain+0x48/0x78
kernel_restart_prepare+0x20/0x48
kernel_kexec+0xa8/0x160
__arm64_sys_reboot+0x214/0x2c0
```

这是厂商模块 `oplus_bsp_dfr_last_boot_reason.ko` 注册的 **reboot notifier 主动记录的"谁请求了重启 + 当时调用栈"**（模块里有 `KERNEL_SHD:` 字符串和 `register_reboot_notifier`），记录的是 `kernel_kexec` 的**正常**路径，**不是崩溃栈**。不要误读。

### 5.6 复位是硬件级

- `/sys/pmic_info/pon_reason`：`PON Trigger: HARD_RESET (4)`（4 条 PMIC 全一致）
- `/proc/shutdown_detect`：`SHUTDOWN_ACTION | 1:SYS_RESTART`、`SHUTDOWN_STAGE_HARDWARE | 580499 | ...`
- 存在 devlink `platform:hypervisor:qcom,gh-watchdog—platform:soc:pmic-pon-log`，即 Gunyah 虚拟看门狗与 PMIC 复位源绑定

### 5.7 现场存在 5 个看门狗

`gh_virt_wdt`、`qcom_wdt_core`、`qcom_enhance_watchdog`、`oplus_bsp_dfr_pmic_watchdog`、`oplus_bsp_dfr_init_watchdog`
（此前审计：`gh_virt_wdt` 的 `disable=0`、`wakeup_enable=1`，且其驱动没有 shutdown 回调）

---

## 六、失败点精确定位（当前边界）

第一轮日志最后为 `KT: machine_kexec reloc=... ttbr0=... ttbr1=... el2=0`，它在 `local_daif_mask()` 之前打印。第二轮随后保存了目标入口跳板写入的 `KEXEC_FILE_PROBE stage=target-entry`，首次在本文的 `kexec_file_load` 路径确认交接后的执行。原 `primary_entry` 内部进度仍未观测。

注意排除一个误判：`pr_info("Bye!\n")` 是**级别 6**，而 `loglevel=6` 意味着只有级别 <6 才进 console，
所以 **`Bye!` 缺失不能作为"没走到那里"的证据**。

`arch/arm64/kernel/machine_kexec.c` 中，打印之后的执行顺序是：

```c
	pr_info("Bye!\n");                  // 级别 6，可能被过滤

	local_daif_mask();                  // 关中断/调试异常

	if (kimage->head & IND_DONE) {      // 无需搬运，镜像已在最终地址
		typeof(cpu_soft_restart) *restart;
		cpu_install_idmap();
		restart = (void *)__pa_symbol(cpu_soft_restart);
		restart(is_hyp_nvhe(), kimage->start, kimage->arch.dtb_mem, 0, 0);
	} else {                            // 搬运各段；是否有 purgatory 取决于装载器
		...
		kernel_reloc(kimage);
	}

	BUG(); /* Should never get here. */
```

只有直接分支才调用 `cpu_soft_restart()`（`arch/arm64/kernel/cpu-reset.S`）：

```asm
	mov_q	x12, INIT_SCTLR_EL1_MMU_OFF
	msr	sctlr_el1, x12      ← 关闭 MMU / cache
	isb
	cbz	x0, 1f              ← el2_switch?
	mov	x0, #HVC_SOFT_RESTART
	hvc	#0
1:	mov	x8, x1
	...
	br	x8                  ← 跳到目标内核入口
```

**`IND_DONE` 不表示单段镜像。** 普通、非 crash 的 `kexec_file_load` 会由 `kimage_load_normal_segment()` 建立搬运链，`kimage->head` 指向间接列表。因此本文的 `kexec -s -l` 路径应检查：

`local_daif_mask()` → `cpu_install_ttbr0()` → 复制到控制页的 `arm64_relocate_new_kernel()` → 切换线性映射、搬运并刷新目标段 → 关闭 MMU → `br x28` → 目标内核早期启动。

这条 arm64 文件装载路径直接进入 Image，不经过用户态 kexec-tools 的 purgatory。旧的 `cpu-reset.S` 探针并未覆盖这条搬运路径。没有 `BUG()` 或目标启动日志，均不能证明相应代码没有运行：第一轮只有交接前日志；第二轮已取得目标入口跳板的正面证据，仍不能用缺失的 printk 推断原 `primary_entry` 内部或后续 console 注册前的执行进度。

---

## 七、此前的尝试与已排除项

| 曾经的假设 | 结论 | 依据 |
|---|---|---|
| KCFI 导致 `machine_kexec` 崩溃 | **已修复** | 最初 pstore 有 `machine_kexec+0x114` 的 `ldur w16,[x8,#-4]` Oops；给 `machine_kexec` 加 `__nocfi` 后不再出现 |
| protected KVM 使 `BUG_ON` 必触发 | **排除该检查** | `pkm=0`；Gunyah 的其他影响未排除 |
| CPU stuck | **排除** | `stuck=0 online=1` |
| 厂商 reboot notifier 崩溃 | **排除** | `after restart_prepare` 正常打印 |
| `syscore_shutdown` 挂起 | **排除** | 只一个回调 `irq_gc_shutdown`，正常返回 |
| `machine_shutdown` 挂起 | **排除** | 220ms 完成 |
| 目标内核/DTB/ramdisk 不匹配 | **未完全排除** | Image 的身份核对不能替代 DTB、ramdisk、保留内存和固件状态交接核验 |

### 曾经尝试但已撤销的方案：IMEM 裸标记

曾尝试向假定的 `0x68140000 + 0xe000` 写 4 字节阶段号，以越过 printk 失效区。**这个基址和大小的读取是错误的。** 2026-11-13 重新解析实机 `/sys/firmware/fdt`，节点是 `/soc/qcom,msm-imem@14680000`，`reg` 的两个大端 cell 为 `0x14680000` 和 `0x1000`。旧探针写入的 `0x6814e000` 根本不在该窗口内，`0xe000` 偏移也超出实际窗口。

**已撤销，且撤销理由是成立的**：

1. **DT 里存在该窗口不代表有权写每个字节**——这不能证明所有权，也不能证明安全/非安全侧允许写。
2. **`primary_entry` 每次正常开机都会执行**，且此时异常向量尚未安装；在此处写裸内存一旦异常，会死在最早期的静默区。
3. 在最终跳转路径里做 `ioremap/iounmap` 本身也有风险。
4. 且 **读不回来**：`CONFIG_DEVMEM=n`、`CONFIG_PROC_KCORE=n`，用户态无法读取该物理地址，写入等于白写。

---

## 八、其它值得注意的现象

### 8.1 pstore 日志严重损坏

某次会话的 `console-ramoops-0`：2606 行里**只有 6 行**是结构完整的，其余全部字节错乱。
这与项目更早实验的记录一致（"Raw logs show byte corruption"）。

含义：**跨启动日志本身不可靠**。需要区分 RAM 保留、地址或布局变化、缓存一致性、硬件继续访问等原因；单凭乱码不能证明是目标内核覆写，也不能用缺失日志定位最后执行的指令。

### 8.2 `console=ttynull` + `qcom_geni_serial.con_enabled=0`

没有串口输出。此前多次 ramoops/pstore 严重损坏；本轮移除错误 IMEM 探针、启用用户进程冻结后，交接前的关键 pstore 日志完整可读。两项条件同时变化，不能单独归因于其中一项。第二轮已取得目标入口标记，但 console 注册前还没有更细的阶段证据。

### 8.3 厂商关机干预模块

`oplus_bsp_dfr_shutdown_detect.ko` 带 `shutdown_delay enable, shutdown timeout: %d`，超时会做 `sysrq show block and cpu thread`。
这类模块假设"关机应在 N 秒内完成"，与 kexec 长时间停留在关机流程的场景天然冲突。

---

## 九、给接手者的建议方向

### 优先级 1：恢复可观测性

在继续定位之前，**必须先有可信的日志通道**。可选：

- 核验 ramoops 的实际地址、映射属性和目标 DTB 保留方式；动态地址、缓存别名或覆盖都需要证据，不能仅凭乱码确定原因。
- 或改用其它持久化通道（本项目另有一次实验用过 IPMI/pmsg 之外的方案）
- 确认 `console=` 参数能否改为可用串口

### 优先级 2：把 `machine_kexec` 之后切成可观测的几段

在**不碰 `head.S` / `cpu-reset.S` / 不写裸内存**的前提下，可行的做法：

- 在 `machine_kexec_post_load()` 记录实际分支、入口、DTB 和各段地址；装载后立即保存 dmesg，不依赖跨启动 pstore。
- 在 `machine_kexec()` 的 `local_daif_mask()` 之前再次记录分支、控制页和 TTBR 地址。
- 保持切换页表后的路径原样，不在该阶段分配映射或引入一般 C 日志调用。上述日志仍不能证明搬运汇编或目标入口已经执行。

### 优先级 3：确认 `IND_DONE` 分支

`kimage->head & IND_DONE` 决定走「直接 `cpu_soft_restart`」还是「`relocate`」。本轮实测已确认后者；`kexec_file_load` 在搬运后直接进入 Image，不经过用户态 purgatory。

### 优先级 4：看门狗

已确认 `gh_virt_wdt` 的运行时 `disable=0`、`wakeup_enable=1`，参考驱动没有 shutdown 回调。其他看门狗模块存在，不等于每个实例都启用或触发。需要测量复位时间并核对硬件原因，才能把超时确认为根因；也应区分“最先卡住的原因”和“最终触发复位的机制”。

公开 `gh_virt_wdt.c` 提供虚拟看门狗控制操作，`qcom_wdt_core.c` 提供设备 `disable` 属性；尚未改变实机状态或验证该操作在本机上的结果。不能用 suspend helper 代替关闭：wakeup 启用时它可能保留计时器运行。

---

## 十、代码位置

仓库：`Goldzxcbug/sm8750_Droidspaces`，分支 `main`，HEAD `77128cb6f`

- `other_patch/kexec_kabi_6.6.89.patch` —— kexec 相关全部改动，涉及 6 个文件：
  - `include/linux/kexec.h`、`drivers/base/cpu.c`：`__GENKSYMS__` 隔离，保证 KABI/CRC 不偏移
  - `arch/arm64/kernel/machine_kexec.c`：`void __nocfi machine_kexec()`（KCFI 修复）+ `pr_emerg` 探针
  - `kernel/kexec_core.c`：`pr_emerg` 阶段探针 + 可选的 `kexec_freeze_userspace`（默认关闭）
  - `drivers/base/syscore.c`、`drivers/base/core.c`：逐回调/逐设备追踪
- `.github/workflows/fastbuild_6.6.89.yml` 第 531、536-539 行：`CONFIG_KEXEC=y`、`CONFIG_KEXEC_FILE=y`、显式关闭三个 `KEXEC_SIG*`

### KABI 状态（已验证）

- `module_layout` CRC = `0x4e276f37`，与设备基线一致
- 564 个既有导出符号 CRC **零变化**，结构体布局（task_struct / module / device / inode / file / super_block / mm_struct / vm_area_struct / css_set / cgroup）逐字节一致
- 设备实机：696 个模块加载，`disagrees about version` / `Unknown symbol` 均为 0
- 设备模块 `oplus_bsp_midas.ko` 的 59 个版本依赖全部匹配

### 构建方式

云端 GitHub Actions（`.github/workflows/fastbuild_6.6.89.yml`，`workflow_dispatch`），产物为 AnyKernel3 zip（就地替换 boot 分区内核，保留 ramdisk 与 AVB 结构）。
可用参数示例（`ksu_type=none` 时不内置 KernelSU，KernelSU 走 `init_boot` 里的 `kernelsu.ko` 模块）：

```sh
gh workflow run fastbuild_6.6.89.yml -R Goldzxcbug/sm8750_Droidspaces --ref main \
  -f ksu_type=none -f susfs_enable=false -f kpm_enable=false -f lz4_enable=true \
  -f lz4kd_enable=false -f bbr_enable=false -f droidspaces_enable=standard \
  -f better_net=false -f adios_enable=true -f rekernel_enable=false \
  -f baseband_guard=true -f ccache_update=false -f ccache_debug=false \
  -f kernel_suffix=<后缀>
```

注意：构建树由 `kernel/`（GKI common 6.6.89）+ `droidspaces_patch/fix_cgroup_limits_kabi_6.6.89.patch`（`-F 0`）+ `droidspaces_patch/fix_sysvipc_kabi_6_7_8.patch`（`-F 3`，历史上 hunk 2 需 fuzz 2）+ 本 kexec 补丁 组成。改补丁后必须完整复现这个顺序验证，且**判断 `patch` 自身退出码**（曾因 `patch ... | tail` 取到 `tail` 的状态而误判通过）。

---

## 十一、一句话总结

**正常启动回归已修复；第二轮实测确认 `kexec_file_load` 已经经搬运路径进入目标入口跳板，问题在后续早期启动。** 具体失败指令尚未锁定，原 `primary_entry`、MMU 重新启用和后续初始化仍需阶段证据，Gunyah、看门狗、DMA 和内存交接未完全排除。

## 十二、2026-11-13 复核与正常启动修复

- 删除错误 IMEM 标记及 `head.S`、`cpu-reset.S` 的相关改动；保留 KABI 头文件隔离、`__nocfi` 和既有关闭流程日志。
- 在装载期加入分支及各段地址日志，在切页表前打印入口、DTB、搬运控制页和 TTBR 地址。探针不再依赖固定硬件地址。
- 设备起初运行 `6.6.89-Gold_bug`，没有 `/sys/kernel/kexec_loaded`；本轮临时切换诊断内核后完成了装载及一次执行，复位后已恢复该已安装内核。
- 现存测试 ramdisk 解压后为 68,837,736 字节，含 523 个 vendor 条目与 23 个 generic 条目、一个 `/init`；bootconfig 尾部长度与校验和通过。此检查不证明全部 Android 启动内容正确。
- 实机 ramoops 节点只有 `size=0x240000`、`alloc-ranges` 和 `no-map`，没有固定 `reg`。kexec 文件装载器复制初始 FDT；动态保留区地址在目标内核是否保持一致尚需核验。不能直接把动态区域或 `mem-type=2` 判定为乱码根因。
- 同设备另一套旧 `kexec_load` 实验的第 10 次记录曾保存目标入口至 `__cpu_setup()` 返回的六个标记。这只适用于该实验组合，不能直接外推到本文的 `kexec_file_load`，但足以说明不能把所有失败统称为“未进入目标内核”。
- 诊断内核已用 Android clang r510928、LLD 18 和 pahole 1.25 全量构建成功；与上一版 `_kt` Image 的配置差异仅为版本后缀 `-Gold_Bug_kexec_diag`，最终 Image 的嵌入配置与构建 `.config` 逐字节相同。已通过临时启动和 Android 运行验证，同 Image 的单次 kexec 跳转仍失败；没有刷写分区。
- 本地临时启动镜像为 `out/kexec-boot-fix/kexec-diag-boot.img`，37,007,360 字节，SHA-256 为 `be7aa32a416c8c4fdbcca7a1fc77630271d6daff3bcf2bddfcf912fea70d997e`。v4 镜像头除 kernel 大小外与当前 boot_a 相同，不含 ramdisk 或签名，依赖现有 vendor_boot/init_boot/DTBO；已通过 `fastboot boot` 临时启动，Android 启动完成、root 可用，运行 build-id 与本地链接镜像一致。
- 对测试 ramdisk 的 514 个模块，22,650 处内核本体导出依赖 CRC 全部匹配；`module_layout=0x4e276f37`。1,348 个不由 vmlinux 提供的符号未在本轮验证提供者，不能把这些检查称为完整模块兼容性认证。10 个关键结构的 BTF 布局与原设备基线一致。
- 最终链接函数保留两条物理间接调用，没有 KCFI 类型字前置读取。新增 `python3 tests/kexec_patch_test.py`：完整补丁顺序通过，三份启动/搬运汇编及关异常后的交接代码均保持原样；用 HEAD 旧补丁运行该测试会在 `head.S` 改动处失败。
- 先前离线按 memblock 快照估算旧测试文件的目标布局：Image 从 `0x82800000` 开始，initrd 从 `0x84bf0000` 开始，DTB 约在 `0xbeb200000`，没有与快照中 memblock 保留区相交。它不是实际装载结果，也没有排除 GIC/DMA 或 Stage-2 问题；本轮已取得真实布局，见第十三节。


## 十三、2026-11-13 授权单次实测结果

### 13.1 已完成的动作

用户明确允许“临时启动并单次测试”。本轮使用 `fastboot boot`，没有 flash 分区，没有改变看门狗设置，也没有重复执行跳转。

- 源内核及目标 Image 相同：`6.6.89-Gold_Bug_kexec_diag`，build-id `6081c037cab4c9e169ee897e5d9ad65a98de5109`，Image SHA-256 `21b56cfcd53b474326a8c431fc35e9571be86ffd75d011df1658d021477a0c8a`。
- 临时源内核进入 Android，`sys.boot_completed=1`、root 可用；启动日志未发现 `disagrees about version` 或 `Unknown symbol`。
- ramdisk 的压缩 cpio 主体不变，bootconfig 尾部按这次临时启动的 `/proc/bootconfig` 重新生成；SHA-256 为 `e3ca3e2a6c9ba5fcd816d19f8a36bb8d622c203a1f702aaeef1eaa88f016337c`。
- `kexec_freeze_userspace=Y`；`kexec -s -l` 返回 0，`kexec_loaded=1`。16:34:49 发出唯一一次 `kexec -e`。
- 复位后回到已安装的 `6.6.89-Gold_bug`，build-id `931f89c6463a6af0eea9436b61f059f31e451f6a`，Android 启动完成、root 可用。命令的 ADB 退出码 0 不代表目标内核启动成功。

### 13.2 实际装载与只读检查

| 段 | 起始地址 | 分配长度 |
|---|---|---|
| Image | `0x82800000` | `0x23f0000` |
| initrd | `0x84bf0000` | `0x1157000` |
| DTB | `0xbeb200000` | `0x187000` |

`post_load` 明确输出 `file=1 path=relocate`。在装载后，用有限长度、只读的 BPF 读取检查了运行时对象与页表；工具没有写寄存器、改变内核内存或执行跳转。

- 1 个 ITS、8 个启用 LPI 的 redistributor，共 16 处去重后的表内存范围，与三个目标段均不相交。此快照不证明所有 DMA 已停止，也不保证新内核稍后的分配不会覆盖旧硬件表。
- 28 个重定位链表页覆盖全部 14,030 个目标页，目标没有重复；搬运代码 288 字节与链接原件一致。
- 检查的 97 处线性映射正确、可写；入口恒等映射允许执行，检查到的控制页、页表及链表没有落在目标段内。目标 Image 首页面与本地文件一致。这些是装载时快照，不代替搬运后的内容校验，也没有验证全部 Stage-2 权限。

### 13.3 本次保留下来的最后阶段

本次 `console-ramoops-0` 为 262,132 字节，可打印字节约 99.98%；末尾关键日志完整：

```text
[651.780108] kexec_core: KT: after restart_prepare
[651.780182] kexec_core: KT: after migrate_to_reboot_cpu
[651.780187] KT: syscore irq_gc_shutdown
[651.780194] kexec_core: KT: after syscore_shutdown
[651.841372] kexec_core: KT: after machine_shutdown
[651.841378] kexec_core: KT: before machine_kexec
[651.841380] KT: machine_kexec stuck=0 online=1 pkm=0
[651.841382] KT: machine_kexec path=relocate head=0xae0e14002 start=0x82800000 dtb=0x0000000beb200000
[651.841386] KT: machine_kexec reloc=0x0000000ae0e12000 ttbr0=0x000000099fe6a000 ttbr1=0x0000000a38531000 el2=0
```

PMIC 与 bootloader 记录 `PS_HOLD / HARD_RESET`；`/proc/last_boot_reason` 保存了 `kexec → kernel_kexec → kernel_restart_prepare` 的关机通知栈。它证明发生过本次重启准备，不给出最终复位的根因。

恢复后的 hyp 日志从 `Hypervisor cold boot` 开始，S2 fault counter 为 0。这属于新一轮冷启动，**不能用来排除上一次 Stage-2 异常**。现有证据也没有确认看门狗触发。

### 13.4 第一轮结束时的结论和下一步

以下为第一轮结束时的状态；第二轮新证据和准备过程修正见第十四节。

- **已修复并实机验证**：旧补丁在正常 `primary_entry` 写错误 IMEM 地址造成的启动回归。修复后的同配置诊断内核可以正常临时启动 Android。
- **仍未定位**：kexec 的具体失败指令。装载快照和关闭流程通过，但还没有搬运入口、搬运完成、关闭 MMU 后、目标入口的可靠阶段证据。
- 下一轮应先判断是否到达目标入口。本地已准备一个仅用于目标 Image 副本的无栈入口跳板模板；它保留 x0–x3、x18–x30 与 SP，要求 EL1、MMU/cache 关闭，并校验现有 ramoops ring 头部。688 个离线模拟用例通过，包括环形回绕、无效头部和拒绝写入条件；系统寄存器读取在分支测试中模拟，不代表实机验证。
- 模板内地址均为 0。当时的运行时准备程序拟要求源内核 build-id、真实 `ramoops_context`、sysfs、无 ECC、Device-nGnRE 映射及无线性别名全部匹配；当时尚未在设备上运行。第二轮实际发现 Normal-WB 映射，程序在该检查处拒绝继续，随后按实测缓存属性修正了探针，见第十四节。
- 本轮一次跳转授权已经用完；再次临时启动或跳转需用户另行允许。

本轮本地证据位于忽略目录 `out/kexec-boot-fix/`：`device-test.json`、`live-gic-before-exec.json`、`loaded-metadata-audit.json`、`pstore-after-exec.txt`、`recovery-reset-reason.txt` 和 `entry-probe-validation.json`。设备原始日志保留在本地，没有加入补丁。


## 十四、第二轮：文件装载路径已到达目标入口

### 14.1 授权、输入和映射核验

用户另行明确允许第二轮临时启动及单次入口探针测试。本轮再次 `fastboot boot` 同一诊断启动镜像，运行 build-id 仍为 `6081c037cab4c9e169ee897e5d9ad65a98de5109`，Android 启动完成、root 可用；未刷分区，也未改变看门狗设置。

运行时从匹配的 ELF/BTF、真实 `ramoops_context` 和 console zone 取得：

- console 物理地址 `0x880000000`，分配总长 `0x40000`，可写数据容量 262,132 字节，无 ECC；与 ramoops sysfs 参数一致。
- 每页 PTE 指向预期物理页，**AttrIndx=0（MT_NORMAL，Normal-WB）**；对应线性映射不存在。`mem-type=2` 实际走 `persistent_ram_vmap()` 的普通内存映射，`no-map` 并不意味着 `pfn_valid()` 一定为假或必定走 `ioremap()`。
- 原先要求 Device 映射的准备检查拒绝继续。没有绕过此差异直接执行：入口模板先加入按 `CTR_EL0` 行大小覆盖整个 console 的 `dc civac` 与 `dsb sy`，再核对全部 console 页，并重新生成目标。
- 修正后的入口模板 278 字节，688 个离线用例通过；填好真实参数的完整 Image 另通过 4 个模拟用例，核对实际头部跳转、返回原入口、启动寄存器和 16/32/64/128 字节 cache line 的维护范围。模拟器没有真实硬件缓存模型，实机仍以保存下来的标记为证。

这项发现解释了为什么探针必须处理缓存一致性，**尚不能把先前乱码或 Android 启动失败归因于缓存**。

### 14.2 目标与装载检查

只在目标副本修改 Image 头的入口分支和声明大小，并追加跳板；原始文件从偏移 24 到结尾的内核代码/数据字节保持不变。临时启动用的源 boot.img 未改。

- 目标 `out/kexec-boot-fix/round2/target.Image`：37,687,296 字节，SHA-256 `31d5a51d71428769e8fa277eec8d07059ae69ab92bdb79be46d53e90dba473cd`。
- ramdisk 的 cpio 压缩主体不变，仅刷新本次 bootconfig 尾部；SHA-256 `b9d50144482f916a157e548a3c79e20e1b3683bc982d6a8e01b0c8e8dd9eae02`。
- 实际目标段：Image `0x82800000 + 0x23f1000`，initrd `0x84bf1000 + 0x1157000`，DTB `0xbeb200000 + 0x187000`，`file=1 path=relocate`。
- 16 处 GIC/ITS 表内存均未与目标相交。28 个链表页覆盖 14,031 个目标页，搬运代码与原件一致，检查的 97 处线性映射通过；实际装载的头页面和探针页面逐字节匹配本地目标，包括 ring 地址、容量和消息。

### 14.3 单次执行的正面证据

本轮只执行一次 `kexec -e`。新 pstore 可打印字节约 99.97%，关键末尾如下：

```text
[526.222728] kexec_core: KT: after machine_shutdown
[526.222739] kexec_core: KT: before machine_kexec
[526.222742] KT: machine_kexec stuck=0 online=1 pkm=0
[526.222746] KT: machine_kexec path=relocate head=0x9095b6002 start=0x82800000 dtb=0x0000000beb200000
[526.222754] KT: machine_kexec reloc=0x00000009095b0000 ttbr0=0x000000099b11f000 ttbr1=0x000000098c766000 el2=0

KEXEC_FILE_PROBE stage=target-entry
```

跳转前保存的 pstore 中没有该标记；跳转后仅出现一次，正好位于日志末尾。此消息只由目标追加跳板在通过 EL1、MMU/D-cache 关闭、ring 头部等检查后写入。因此：

1. 本次控制流已经走出旧内核交接，执行了目标头部入口分支和追加跳板。
2. 原搬运汇编的循环、关闭 MMU 和转入 Image 这条控制流已完成，不能继续把它描述为“kexec 根本没跳过去”。这不代替所有目标页的搬运后完整性检查，也不排除随后发生的 DMA 覆写。
3. 跳板写完标记后还有恢复到原 `primary_entry` 的分支。返回计算和寄存器保留已在模拟器核对，但**原 `primary_entry` 第一条指令及内部阶段尚无实机标记**，不能越过这一证据边界。
4. 没有目标 printk 或 panic 记录仍不证明没有执行 `start_kernel()`：设备的 pstore console 建立较晚，且没有串口日志。

设备随后仍硬复位并进入已安装的 `6.6.89-Gold_bug`，build-id `931f89c6463a6af0eea9436b61f059f31e451f6a`；Android 启动完成、root 可用。PMIC 再次记录 `PS_HOLD / HARD_RESET`，尚未确认最初异常或看门狗触发原因。

### 14.4 下一轮已在主机准备的阶段模板

已对**这颗精确 Image** 的反汇编逐条匹配，构建七个只覆盖 MMU 启用前 B/BL 位置的跳板：

`target-entry` → `mmu-state-recorded` → `boot-args-preserved` → `idmap-created` → `exception-level-ready` → `cpu-setup-returned` → `before-enable-mmu`。

模板不依赖旧栈；保留 SP、NZCV 和除 x16/x17 之外的全部 GPR。x16/x17 是在这些已审阅调用/分支处不承载活跃输入的临时寄存器。每个跳板只写自身追加区中的 scratch 和核实过的 console；不改页表或异常向量，不写设备寄存器。它不会直接观测 MMU 启用后的进度。

1,512 个离线模拟用例通过，包含原 B/BL 语义及 LR、不可用的 SP、寄存器/标志恢复、无效 ring、拒绝条件和多种 cache line 大小；系统寄存器读取和硬件缓存仍不是完整系统仿真。模板参数仍为 0，须下一次临时启动后重新核验真实 ring 才能生成目标。

本轮第二次单次授权已用完，尚未进行第三次临时启动、装载或跳转。本轮证据位于 `out/kexec-boot-fix/round2/`，下一轮离线模板位于 `out/kexec-boot-fix/early-stages/`。生产补丁没有加入这些目标 Image 实验跳板。


## 十五、目标入口后的异常捕获准备（尚未实机执行）

本次目标轮重新读取工作区及设备状态：设备仍运行复位恢复后的 `6.6.89-Gold_bug`，Android 启动完成，启动 ID 与第二轮恢复记录一致。没有进行第三次临时启动或 kexec。

### 15.1 实际建表代码的离线核验

从已实机临时启动的精确 Image 解析其入口调用，直接在模拟器执行实际 `create_idmap()` 机器码，并读取生成的页表；没有用另写的建表算法替代被测代码。结果：

- 对本轮真实使用的 Image 物理基址 `0x82800000`，追加区 `0x84bf0000` 起的 16 KiB 均为恒等、可写、允许 EL1 执行的映射，覆盖下一版 7,960 字节的追加诊断内容。
- 原因是 `create_idmap()` 初始映射整个 Image 及 FDT 临时窗口，且内核页表所在的 2 MiB 块被重映射为可写；不能把它误认为只映射 `.idmap.text`。
- 实际 DTB 物理地址 `0xbeb200000` 被正确映射到临时虚拟地址 `0x84c00000`。

这证明该输入下的 EL1 初始页表结构允许追加诊断代码运行，不证明实机已经重新启用 MMU，也没有验证 SoC 的 Stage-2 权限或硬件缓存行为。若下一次装载布局不同，执行前必须重新核验适用性。

### 15.2 单独构建的增强目标模板

在七阶段模板之外，另建 `out/kexec-boot-fix/early-fault/` 版本。生产补丁和临时启动用的源 boot.img 不变，未替换旧版本实验记录。

新模板只在首个入口标记成功写入之后，安装 2 KiB 对齐的临时 EL1 向量；不改初始页表。若随后发生 EL1 异常，捕获向量号、`ESR_EL1`、`ELR_EL1`、`FAR_EL1`、`SCTLR_EL1`、`TCR_EL1`、两个 TTBR、MAIR、SPSR、SP、Image 物理基址和原 x23 值。异常路径在恒等地址上关闭 MMU/cache，按核实的 Normal-WB console 属性进行缓存维护，将寄存器追加到现有 ring，然后请求标准 PSCI SYSTEM_RESET。运行时准备程序必须重新读取 FDT，确认 PSCI 方法为 `smc`；现存 FDT 的节点为 `/soc/psci`，兼容 `arm,psci-1.0`。

原 `__primary_switched` 会在初始化启动任务后安装内核自己的 VBAR，此后临时异常捕获不再生效。EL2 处理但未传递给 EL1 的异常、无法持久化的日志，以及新的 VBAR 安装后的失败，都可能没有这条捕获记录；不能以记录缺失排除异常。

### 15.3 已完成和未完成的验证

- 七阶段与 VBAR 安装条件的 1,512 个离线用例通过；16 个向量入口的 672 个故障注入用例通过，检查寄存器输出、ring 回绕、非法头部、写入边界、无栈访问，以及只在故障路径请求 PSCI 复位。
- 实际 `create_idmap()` 机器码执行及页表读取通过。特权寄存器、MMU/cache 的硬件效果仍不是完整系统仿真。
- 进一步分别执行原始 Image 和增强目标的完整入口机器码链，到达 `__enable_mmu` 入口为止：七条阶段消息按序出现，boot arguments 正确，传入 MMU 启用函数的活跃寄存器、SP、PSTATE、已生成页表和 CPU 设置寄存器写入均与未加探针的基线一致（刻意新增的 VBAR 除外）。该检查使用通用 CPU ID 值并模拟 ERET，未执行实际 MMU 启用，不代表 Oryon/Gunyah 实机通过。
- 另有日志解码器将物理或基于 x23 的虚拟 ELR 换算到匹配 ELF 的函数及偏移，解析 ESR 类别和 fault status；合成数据测试与实机数据严格区分。第二轮真实 pstore 中没有故障捕获行，解码器没有虚构异常。
- 模板 SHA-256 为 `8577cade8644dda048b2cb5653893782e9267c3a356745ce9ac5b31939783e82`；ring 参数仍为 0，须在下一次已授权临时启动后重新核验运行时对象和映射，才能生成可测试目标。
- **尚未完成**：这个版本的第三轮实机执行；目标内核具体失败原因及功能修复仍未证实，不能把诊断准备当作任务完成。

第三轮增强方案已单独请求授权。此前两轮单次授权均已执行，本次没有自行增加实机跳转次数。

## 十六、第三轮实测：已到 MMU 启用前调用点，具体失败点仍未知

用户回复“授权你测试”后，执行了一次临时启动和一次增强目标 kexec。用户随后明确允许使用子代理并行研究；设备操作仍由主代理统一执行。

### 16.1 装载前后核验

临时源内核仍为上述 `6081c037…`，Android 启动完成、root 可用。重新读取运行时 ramoops 对象和 Stage-1 页表，console 仍为物理 `0x880000000`、总长 `0x40000`、容量 `262132`、无 ECC；页面 AttrIndx 为 0，未发现线性别名。Normal-WB 的解释基于匹配内核的 MAIR 配置，未直接读取运行中的 MAIR 或验证 Stage-2。FDT 的 PSCI 方法再次确认为 `smc`。

目标 Image 为 37,691,392 字节，SHA-256 `03e280133667aac94daf4f6fe283137c5f8f0b88990fa40e08db55204a235b86`。仅将已验证模板的 ring/capacity 填成当次读取值。ramdisk 保持原 CPIO 内容，仅刷新本次 bootconfig 尾部。

实际 file-load 仍走 `relocate`：

| 段 | 起始物理地址 | 长度 |
| --- | --- | --- |
| Image | `0x82800000` | `0x23f2000` |
| initrd | `0x84bf2000` | `0x1157000` |
| DTB | `0xbeb200000` | `0x187000` |

16 个核实的 GIC/ITS 表区间与目标段没有重叠。搬运链有 28 个列表页、14,032 个目标页；目标页完整且不重复。97 个线性映射采样、复制的搬运代码、四个修改页（入口/原调用页/两个追加页）与主机目标均核对通过。此检查仍不能保证跳转后的 DMA 或新内核后续分配不会覆盖旧固件表。

### 16.2 新的实机证据

跳转前保存的 pstore 没有以下标记；跳转后的末尾按顺序各出现一次：

```text
KEXEC_EARLY_V2 stage=target-entry
KEXEC_EARLY_V2 stage=mmu-state-recorded
KEXEC_EARLY_V2 stage=boot-args-preserved
KEXEC_EARLY_V2 stage=idmap-created
KEXEC_EARLY_V2 stage=exception-level-ready
KEXEC_EARLY_V2 stage=cpu-setup-returned
KEXEC_EARLY_V2 stage=before-enable-mmu
```

因此，原 `primary_entry` 已执行，且启动参数保存、恒等页表创建、异常级初始化、`__cpu_setup` 返回均有实机证据；`__primary_switch` 已到达调用 `__enable_mmu` 的跳板。最后一条消息在跳板转入原函数之前写出，尚不能证明函数首条指令、页粒度检查或 SCTLR 写入已执行。现在应排查 **该调用之后及 MMU 启用后的路径**，不能继续把定位停留在“目标入口未执行”。

没有 `KEXEC_EARLY_FAULT` 行。它不能证明没有异常：可能由 EL2 接管、向量处理或持久化失败，也可能失败已经发生在普通 VBAR 替换之后。七条标记也不能证明 MMU 启用成功返回、跳到虚拟 `__primary_switched` 或进入 `start_kernel()`。

设备随后复位回已安装的 `6.6.89-Gold_bug`，build-id `931f89c6…`；Android 启动完成且 root 可用。PMIC 仍为 `PS_HOLD / HARD_RESET`，没有足够证据认定最初触发源。没有刷分区、没有改变看门狗状态、没有自动重试跳转。原始记录在 `out/kexec-boot-fix/round3/`。

### 16.3 后续定位范围

下一版诊断需要分别观测 `__enable_mmu` 返回、KASLR/高位页表建立、虚拟 `__primary_switched` 和调用 `start_kernel`。MMU 开启后不能直接沿用原先的物理 console 写法，须先验证诊断专用映射及缓存维护；当前仍在主机设计阶段。

另外并行核对 SM8750 的 ITS/LPI 固件表跨 kexec 保留问题。该项有平台相关上游讨论，但目前只是待验证风险，不能把它写成这三轮失败的已确认根因。

## 十七、MMU 后诊断已完成离线准备，尚未进行第四轮实测

子代理分别复核启动路径、探针和 GIC 表交接，主代理统一审阅、集成验证。新版本保留第三轮七阶段与临时 EL1 故障向量，另加入：

- 原 `__enable_mmu` 的 ISB 位置写入寄存器快照，然后重放 ISB 并返回未修改的 MSR SCTLR 序列。记录 desired SCTLR、当前 SCTLR/TCR/TTBR0/TTBR1/MAIR 和 MMFR0/1/3，用于区分页粒度检查与实际转换。
- 十一个 MMU 后边界：MMU 序列返回、早期 KASLR 前后、清建高位页表、重定位及虚拟跳转、启动任务就绪、清 BSS/FDT/feature override，以及调用 `start_kernel` 之前。
- 在 MMU 关闭阶段，只向已验证为空的 idmap root[34] 加入两页自有页表，精确映射现有 console 的 64 页；不覆盖原 Image/FDT 映射。页属性由本次精确头文件编译得到 `PROT_NORMAL=0x0068000000000703`，同时检查传统 AP 与 S1PIE 的 EL1 RW 权限。离线审阅已修正原型漏 DBM 位而在 S1PIE 下变只读的问题；该错误版本没有上设备。
- 每次 MMU-on 日志在写前、写后清理 console 缓存。最后一个跳板在进入 `start_kernel` 前，经高虚拟可写别名核对并清除自有 root descriptor，执行 cache/TLB 维护；此后不访问 console。追加区在链接 `_end` 外，故不可让这两页表继续存活至内存分配阶段。若清理前置条件异常则停在专用拒绝路径，不能把这种停顿误认为原目标代码失败。

定版模板为 24,576 字节，SHA-256 `9a76077f6e64a5194f11c75d49ee2dbf3d8da66009d369313239157137543045`。1,512 个原阶段回归、576 个新阶段/撤销用例、364 个寄存器快照用例共 2,452 例通过；实际建表机器码覆盖六个追加页和多个 KASLR 值。

主代理另以物理/高虚拟地址共享内存执行真实启动汇编和 RELA/RELR，对照原 Image 到实际 `start_kernel` 入口，三个 KASLR/S1PIE 场景下活跃 GPR、SP、flags、系统寄存器写入和清理后的 idmap 与基线一致。**KASLR/FDT/feature override/finalise_el2 的 C 辅助返回，以及 CPU IDs、ERET 和 MMU/cache 效果仍经模拟；这不是完整启动或硬件通过证明。**

离线审阅 Image 为 37,707,776 字节，SHA-256 `bc7b46f6e1e5f8fd2a11c642ec334b0f1324158087a70e9062ce89920d5e8ecb`。其中 console 参数来自第三轮归档，**不能直接装载**；新的准备脚本必须在已授权临时启动后重核源 build-id、当次对象/映射、PSCI 和布局，才生成可测试目标。源 boot.img 和生产补丁保持不变。

第四轮装载审计还将从实际搬运源页捕获完整目标 DTB，核对 initrd 和 GIC 表保留区。现有上游讨论已撤回“到 ITS 初始化时才认领旧表”的方案，本树也确在 `init_IRQ` 前运行 `memblock_free_all()`。若后续确认卡在 GIC，合理方向是源装载器选段前排除真实表范围，并将保留写入交给目标的新 DT；这仍是修复设计，未作为本次根因，也没有加入生产补丁。

准备代码与离线记录在 `out/kexec-boot-fix/post-mmu-design/`、`post-mmu-runner/` 和 `pre-mmu-snapshot/`；GIC 核验在 `gic-handoff-design/`。目前已请求第四轮临时启动及一次跳转授权，尚无第四轮设备动作。

### 17.1 装载审计的进一步复核

第四轮授权待回复期间，仅继续主机准备及读取当前设备状态；设备启动 ID 与第三轮恢复记录一致，仍为原 Android 且启动完成。没有第四次临时启动、装载或跳转。

独立复核补齐了对实际交接字段的绑定：不仅核对三个段的地址/长度，还必须读取并比对 `kimage.start`、`arch.dtb_mem` 及每段实际 `bufsz`，确保所核验的 Image 和捕获的 DTB 正是跳转汇编将用于入口与 x0 的内容。打包 DTB 的 totalsize 必须等于 DTB 段 bufsz；其 initrd-end 应等于 initrd-start 加精确 bufsz，不能拿按页取整的 memsz 代替。

新 DTB 检查还要求实际 bootargs 与本轮源 cmdline 一致、唯一 PSCI 节点为 `smc`，并核验 `/reserved-memory` 的 cells 与根节点相同、空 `ranges` 存在。否则目标内核可能忽略整组保留节点，覆盖报告不能算有效。原始 DTB 含随机种子，只留在本地忽略目录；报告仅输出必要结构和摘要。完成较长的 DTB 捕获后，再读取一次 GIC 表范围；若与初始快照不同，不进入跳转。两次相同仍不代替 DMA quiesce 或未来稳定性证明。

新增的 DTB 检查器和进度解码器各通过 8 个主机测试；输入明确区分第三轮真实日志、归档源 DTB 和模拟场景。解码器不会把寄存器快照当作 SCTLR 已写入，也不会把 `before-start-kernel` 当作清理和内核主体已经执行。以上新增审计尚未连接到新的实机装载，不能作为第四轮通过证据。目标模板、生产补丁和源 boot.img 未改变。


## 十八、第四轮实测：主 CPU 已通过 MMU；发现并隔离诊断钩子缺陷

第四轮在用户明确授权后完成一次临时启动和一次 kexec，没有刷分区、改变看门狗状态或重试跳转。原始证据与当次目标保存在 `out/kexec-boot-fix/round4/`。以下实测结果取代第十七节的“尚未执行”状态，旧准备记录保留供追溯。

### 18.1 本轮有效证据

临时源内核 build-id 仍为 `6081c037cab4c9e169ee897e5d9ad65a98de5109`，Android 完成启动，root 可用。重新核实 console 物理地址 `0x880000000`、总长 `0x40000`、容量 `262132`、无 ECC 和 Normal-WB 映射，并核实 PSCI `smc`。实际装载目标 SHA-256 为 `bc7b46f6e1e5f8fd2a11c642ec334b0f1324158087a70e9062ce89920d5e8ecb`，37,707,776 字节。

实际 Image 在 `0x82800000`、initrd 在 `0x84bf6000`、DTB 在 `0xbeb200000`。搬运链的 28 个列表页、14,036 个目标页及 9 个修改页验证通过，实际 `kimage.start`、`arch.dtb_mem` 和 bufsz 均与审计对象一致。捕获的完整目标 DTB SHA-256 为 `ae0e754c397a50c5b07384339b647e886db59d9d51086f8c118e7baa9b2d70f2`。两次 GIC 表范围快照相同，16 个范围与装载段没有重叠；这些检查仍不等于 DMA 停止或后续分配安全。

跳转前 pstore 没有本轮消息。跳转后的七条早期标记及以下十一条均按序各出现一次：

```text
KEXEC_POST_V1 stage=mmu-enabled
KEXEC_POST_V1 stage=before-kaslr-early-init
KEXEC_POST_V1 stage=kaslr-initialized
KEXEC_POST_V1 stage=kernel-tables-cleared
KEXEC_POST_V1 stage=kernel-mapping-installed
KEXEC_POST_V1 stage=before-primary-switched
KEXEC_POST_V1 stage=primary-switched-task-ready
KEXEC_POST_V1 stage=bss-cleared
KEXEC_POST_V1 stage=early-fdt-mapped
KEXEC_POST_V1 stage=feature-overrides-initialized
KEXEC_POST_V1 stage=before-start-kernel
```

因此，不能再把故障停留在 MMU 启用前。主 CPU 已完成上述汇编及早期辅助路径；最后一条在最后跳板的清理和原 `start_kernel` 跳转之前，不能单独证明其清理成功或 `start_kernel` 主体执行。

首条 MMU 配置快照的 `TTBR0=0x848f0000`、`TTBR1=0x84514000`，随后另有五条 `TTBR0=0x84512000`、`TTBR1=0x84515000`。后者分别对应常驻 `idmap_pg_dir` 与 `swapper_pg_dir`，符合 secondary/resume 调用上下文，但没有 LR/MPIDR，不能区分二者或认定五核上线。快照发生在 SCTLR 写入前；独立机器码核对得到的固定 SCTLR 设置值是 `0x30500800`，不是早期离线计算误写的 `0x30d00800`。TCR 的能力相关保留位差异目前不能作为根因。

### 18.2 已证实的第四轮诊断缺陷及证据边界

第四轮将共享 `__enable_mmu` 的 RET（Image 偏移 `0x1d11400`）改成跳往约 `0x84bf1f20` 的追加区。主 CPU 初始 `init_idmap_pg_dir` 映射整个 Image，因此可执行；后续 `idmap_pg_dir` 只为 `__idmap_text_start..end`（本轮物理 `0x84511000..0x845118a0`）建立常驻恒等映射，不包含该追加区。secondary/resume 在启用 MMU 后会先取指跳板，再判断内部 guard，因而 guard 无法防止未映射取指。主 CPU 的临时异常 VBAR 不会自动安装到其他 CPU，缺少故障行也不能排除此类失败。

共享 ISB 快照钩子也没有在进入普通内存分配前撤销，其代码与全局 scratch 位于链接 `_end` 外，存在生命周期和并发风险。当前逐 CPU 串行上线配置没有证明实际发生 scratch 竞争。**上述诊断缺陷足以污染第四轮后续结果，但不能解释前三轮未加共享 RET 钩子时的原始失败。** 本轮末尾没有 `KEXEC_EARLY_FAULT` 行，设备随后恢复 `6.6.89-Gold_bug`（build-id `931f89c6…`），Android 启动完成、root 可用。PMIC 的 `PS_HOLD / HARD_RESET` 仍不揭示最初触发源。

已单独构造 `post-mmu-smp-safe/` 修正模板：保留原 RET，快照在任何共享写入前按主 CPU 初始 TTBR0 过滤，最后独立恢复共享 ISB 并做 D/I cache 同步，随后撤销临时 console 映射。528 个阶段/清理、1,512 个旧阶段、364 个主 CPU 快照、232 个 secondary 用例通过，含追加区释放或覆写后的返回检查。该模板 SHA-256 为 `a515bd850c4d9d8770a6ca146a1008887b290da2e6d4755d4a033ea7cb6103c5`；尚未上设备，不代表原始故障已修好。

### 18.3 后续范围与未证实的 GIC 风险

实际目标 DTB 的静态保留节点与 reserve-map 没有覆盖上述 16 个源 GIC/ITS 表范围；另有 15 个动态节点，其未来分配地址不能由捕获文件单独确定。本树在 `init_IRQ()` 前执行 `mm_core_init()` / `memblock_free_all()`。这使旧表被新内核提前重用成为需要验证的平台风险，但当前没有捕获到表损坏或 GIC 初始化失败，不能写成已确认根因。

下一版在独立 `late-boot/source` / `late-boot/build` 中构建，将 C 阶段代码与状态链接在内核保留范围内，不改共享 MMU 汇编。默认不开启，只有本轮明确参数启用；在 `setup_arch()` 返回后校验目标实际 reserved-memory 与新鲜源对象，再映射并记录 `mm_core_init`、`init_IRQ`/ITS、首次开本地 IRQ、`smp_prepare_cpus`、`smp_init` 及逐 CPU 上线边界。在普通 ramoops 写入器注册前关闭记录与映射。**实物配置 `CONFIG_PSTORE_RAM=y`，不能依赖此前摘要误记的模块配置；必须按真实 initcall 顺序审阅。** 构建和主机审阅仍在进行，尚无第五轮临时启动、装载或跳转。


## 十九、内置 C 阶段诊断已构建并完成主机核验，尚未进行第五轮实测

新增诊断与生产补丁隔离，仅在 `out/kexec-boot-fix/late-boot/source/` 的八个文件内。普通构建默认关闭；本次诊断配置只新增 `CONFIG_KEXEC_TARGET_TRACE=y` 并将 LOCALVERSION 改为 `-Gold_Bug_kexec_late_diag`，其余配置与已四次正常启动的源诊断内核一致。

- 目标 Image：37,001,728 字节，SHA-256 `30aeb86ee56111477958b3b75afedf3c791315e91cf2542cf2fabc0b9ed32d0a`，内核保留大小 `0x23f0000`，build-id `f04d5f44f8eeaf7586a6da926defa4d252a9c6d8`。
- 临时 boot：`out/kexec-boot-fix/late-boot/kexec-late-diag-boot.img`，37,007,360 字节，SHA-256 `9e7954459ef6273a906611df81a7ce43bd43e533e1ae488b0767d5e4cb3ce81d`。Android v4 header 除 kernel_size 外与旧诊断 boot 一致，无 ramdisk/signature；不替换现有分区。
- 完整构建及最终增量构建成功。16,306 个内建导出 CRC、10 个既有关键结构布局完全一致，内嵌配置与构建配置一致；原 head.S、cpu-reset.S、relocate_kernel.S、proc.S 未改。CRC/布局核验不等于这颗新内核已实机正常启动。
- 实际编译的 `kexec_target_trace.o` SHA-256 `1abfcfbde2f9abf686074a429e6b453aaa1f7e3b1c43f82beea3828aa08b6f82`，通过 66 个主机机器码场景：严格参数拒绝、ring/FNV/回绕/边界、IRQ 与 C ABI 保存、PID1 交接和任务迁移、在真实外层 busy 状态重入、关闭后移除 ring 映射仍无访问。OF/memblock 所有权、early mapping API 与特权寄存器/cache 效果被模拟，未验证真实 Oryon/Gunyah 或动态 PAC/SCS 行为。
- 最终 ELF 独立静态审阅绑定 Image/ELF/object：19 个实际函数、14 个 SROA 状态符号、BTMAP 页表与状态均在 `_end` 内；正常 emit 只有四个内部辅助调用，无 printk/分配/格式化/意外插桩或间接调用。编译器生成的少量 IRQ/OF wrapper 位于普通 `.text`，也在保留范围内，并非全部函数均在 `.init.text`。从真实 ADRP/ADD 恢复了被链接器分散的字符串引用；32 个关键文件页纳入下一轮实际搬运源页核验。

诊断通过 `kexec_late_trace=base,full_region_size,console_size,capacity,run_id` 五个带 `0x` 的十六进制字段启用。参数须由当轮源内核真实 ramoops 对象、BTF、页面属性和随机 run ID 生成，不能复用归档地址。目标还必须有 booted-from-kexec、匹配的实际 reserved_mem/consumer phandle、全区 RAM/NOMAP、Normal-WB、console/pmsg 布局及零 ECC/record/ftrace 条件，否则拒写。**最早持久记录点是 setup_arch 返回后；如果目标动态 ramoops 分配改变，可能没有标记，不能据此认定原内核卡死。**

记录覆盖 mm_core、init_IRQ、boot 专用 GIC dist/CPU interface、ITS 初始化和原返回值、首次开 IRQ、PID1 交接、smp_prepare、smp_init 及逐 CPU 的 cpu_up 前后/原返回值。AP 共用函数体和 MMU 汇编没有钩子。SMP 返回后关闭并 unmap，在内建 ramoops_init 入口再确认关闭；若有忙态或非 owner，拒绝关闭并阻止后端并存注册。进入正常 ramoops 后，旧 ring 可能被保存/重置，后续需要结合普通目标 printk 判断，不能只按有无直接标记下结论。

新运行准备与审计在 `late-boot-runner/`：匹配新 ELF/BTF/build-id、源启动 UUID、精确目标 cmdline 含 run ID、实际段/入口/DTB/bufsz、完整目标 DTB、console 属性和两次 GIC 范围快照。FDT 检查器 8 个用例和解码器 6 个格式用例通过；解码器只报告校验通过的正面边界，不自动认定根因。离线 manifest 在 `late-boot/manifest.json`，验证及脚本哈希在 `late-boot-runner/validation.json`。

当前仅完成第五轮准备，没有第五轮临时启动、装载或跳转。第四轮的一次授权已经执行完；第五轮若获授权，先临时启动本镜像核实正常 Android/模块，再对同一未修改 Image 加入当轮诊断参数，仅执行一次 kexec。不刷分区、不改看门狗、不自动重试。设备当前仍为原已安装 Android（启动 UUID `6e767b42-0df1-45e7-a73f-ad155b2c0d52`），启动完成、root 可用。原始 kexec 的根因和功能修复仍未完成。


### 19.1 测试授权更新

用户已明确回复“允许,以后默认确认,因为都是可逆的”。第五轮临时启动及 kexec 已获授权；后续为本诊断所需的可逆测试默认继续，不再逐轮确认。该授权不用于刷分区、修改看门狗或其他不可逆操作。设备动作仍由主代理统一执行并逐次记录。


## 二十、第五轮实测：确认 ITS 的 EBUSY，目标已完成 8 核 SMP

第五轮完成一次临时 `fastboot boot` 和一次 kexec；没有刷分区、改变看门狗或重试跳转。临时源内核 build-id `f04d5f44f8eeaf7586a6da926defa4d252a9c6d8`，Android 正常启动、root 可用，695 个模块已加载，包含 `oplus_bsp_midas` 和 `qcom_dynamic_ramoops`，没有版本或 Unknown symbol 错误。原始记录在 `out/kexec-boot-fix/round5/`。

### 20.1 装载与目标执行证据

目标是与源相同的原始 Image，SHA-256 `30aeb86ee56111477958b3b75afedf3c791315e91cf2542cf2fabc0b9ed32d0a`，没有外加 MMU 跳板。重新核实 console 地址 `0x880000000`、console 大小 `0x40000`、容量 `262132`、全区大小 `0x240000`、Normal-WB、无 ECC。本轮 run ID 为 `e2ee8e7f043e9cb8`。

实际 Image 段 `0x82800000..0x84bf0000`，initrd `0x84bf0000..0x85d47000`，DTB `0xbeb200000..0xbeb387000`。分别核实精确 bufsz `37001728`、`18179200`、`1600574`，以及真实 `kimage.start` 和 `arch.dtb_mem`。28 个搬运列表页、14,030 个目标页、97 个映射采样和 32 个关键 Image 文件页核验通过。捕获的完整目标 DTB SHA-256 为 `c0f90c2ee99d662b6da72032b7dc066fb5a69d906b447250e10e7e80189461c8`；两次 GIC 快照的 16 个范围相同，与装载段无重叠。这仍不能证明目标后续分配不会重用旧表，或硬件 DMA 已停止。

复位后的 pstore 找到本轮 37 条连续、FNV 校验有效的记录，无缺号、无拒绝项：

- `setup_arch`、`mm_core_init`、GIC distributor/CPU interface 和 `its_init` 均完成，`its_init` 返回 0。
- **`its_cpu_init` 返回 -16（EBUSY）**，随后 `init_IRQ` 返回并开启本地 IRQ。
- PID1 完成 `smp_prepare_cpus`；CPU 0 至 7 的 `cpu_up` 均返回 0。
- `smp_init` 返回，`num_online_cpus=8`；诊断按设计写入 SMP_DONE 并关闭映射。

本树的 `its_cpu_init()` 通过 `its_cpu_init_lpis()` 返回该错误，表示写入关闭后重新读取 `GICR_CTLR.EnableLPIs` 仍为 1。它不是 MMU 前或从核无法上线的证据。`cpu_up=0` 也不证明每个 CPU 的 MSI/LPI 已正常初始化，因为部分错误被上层忽略。

### 20.2 当前结论和下一步验证

已确认 ITS 的 LPI 关闭失败。尚未确认最终复位的直接触发点：自定义记录在 SMP 完成即停止，现有 vendor ramoops 要到用户空间装载模块才创建后端，当前没有足够晚期目标 printk。不能把最后一条记录当成随后立即崩溃，也不能把 ITS 异常直接写成完整根因。

后续在独立 `gic-fix/source` / `gic-fix/build` 中实现：源装载器在任何目标段分配之前排除真实 GIC/ITS 表页，将这些范围写入目标的保留节点，并在最终跳转前重核当前表是否仍被覆盖；不完整快照或新表范围出现时拒绝跳转并正常重启。仅保留当前硬件仍引用的表，不累积历代无效范围。该修复还在构建准备，尚未实测。

同时增加默认关闭、明确参数启用的诊断：只改目标 DT 的原 ramoops 区域，固定为当轮源实际分配地址，交给内建标准 ramoops 提前接管；停用原 qcom consumer，避免两个后端同时写。目标继续使用冻结的原始 `f04d5f44…` Image，其旧 C 诊断会因 consumer 不可用而安全拒写，下一轮改看正常 printk。该差别必须保留在记录中，不能把缺少旧标记当作启动失败。Normal-WB 的普通 console 尾部可能在硬复位时丢失，缺日志仍不能单独定性。

设备已恢复 `6.6.89-Gold_bug`（build-id `931f89c6463a6af0eea9436b61f059f31e451f6a`），启动 UUID `4b013c62-07ff-480b-8536-6210061e6b6f`，Android 启动完成且 root 可用。原始 kexec 故障与功能修复仍未完成。

### 20.3 归档字段纠正

早期归档字段 `ramdisk_cpio_body_sha256=a5f001b2020f167b4c9bdd51973ec70011d0fd33ea2618f9237f298162fa5bc5` 实际计算的是 **gzip 压缩后的有效载荷**，不是解压后的 CPIO。压缩载荷为 18,177,300 字节；解压后的完整 CPIO 为 68,837,736 字节，其 SHA-256 是 `0569fae5dfcbfb26caebb22c954c23267a0a243a8aa780d269ac81c2889c1a11`。各轮载荷字节保持一致；此次仅纠正名称含义，保留旧归档以便追溯。第五轮使用分开的正确字段，刷新 bootconfig footer 后的整个 initrd 为 18,179,200 字节。


## 二十一、第六轮实测：GIC 表继承生效，已到 Android init 装载模块

### 21.1 新源内核与装载审计

独立 `gic-fix/source` 构建一次通过，build-id `7fbb6d4cdd9bbf06915a84f0d71665a4afbdb33f`，release `6.6.89-Gold_Bug_kexec_gic_diag`。16,306 个导出 CRC、10 个关键结构布局与安全基线相同，内嵌配置一致，启动/复位/搬运汇编及 DAIF mask 之后的物理交接代码未变。相对第五轮只新增 GIC 表交接开关、native ramoops 诊断开关与 LOCALVERSION。临时 boot SHA-256 `c79931e42c41b27c74a9f200e3083c11c5980a175d353775589b1c77067bf4b5`。

GIC loader 的实际 C/libfdt 主机验证通过 320 场景、7,014 条断言；native ramoops helper 通过 72 场景。内核 MMIO、内存分配和 live OF API 在主机验证中明确模拟，不能代替设备结果。新审计器另以真实构建 BTF 核验私有 captured reader，旧轮次和旧审计器保持冻结。

本轮源临时启动成功，Android 完成启动、root 可用，695 个模块加载，没有模块版本/符号错误。源启动 UUID `2c09ac11-3067-448f-8d8e-846d1ed9df0b`。目标仍为原始 `f04d5f44…` Image，SHA-256 `30aeb86e…`，initrd 原压缩载荷保持一致；仅目标 cmdline 增加本轮 native ramoops、nonce 及 `initcall_debug ignore_loglevel`。

源 loader 成功捕获 8 个归并后的保留范围；独立只读审计确认其覆盖全部 16 个原硬件范围，实际 `kimage.arch.gic_tables->captured` 与最终 DT 的 `/reserved-memory/kexec-gic-tables/reg` 逐项相等，全部实际装载段均无交集。最终 DTB 为 1,601,005 字节，SHA-256 `f6070f1b0fbded36c8e9edc2489486c1702826ad443c3f1a31ffd8ab5109b558`。核实 native ramoops 保留地址、布局和禁用 vendor consumer，并验证实际入口、x0、bufsz、搬运链及 32 个关键 Image 页后，只执行一次跳转。

### 21.2 已取得的目标执行证据

复位后保存的 native console 含完整 `GICv3: Using preallocated redistributor tables`、CPU1 使用 reserved LPI pending table 的行，以及部分其他 CPU 的一致地址。本树先置 `RD_TABLES_PREALLOCATED` 再打印该消息；随后 `redist_disable_lpis()` 直接返回，**绕过第五轮已确认返回 EBUSY 的关闭分支**。CPU1 的完整消息还证明它完成相应 LPI 初始化路径。这不是本轮直接记录 boot CPU 的 `its_cpu_init=0`，不能混用两轮观测。

日志出现目标 `f04d5f44…` build-id、目标独有的 `kexec-gic-tables` 保留节点和 Android init 并行装载模块；完整初始化返回至少到 `1.157106s` 的 `oplus_bsp_fpga_monitor=0`。这些关键 GIC 消息不在本轮跳转前日志中。定位已推进至 Android 第一阶段模块装载，不能再写成卡在 MMU、`start_kernel` 或 SMP 上线。

`/proc/task_info` 重复注册 WARN 的同模块/同 PC/同堆栈在第五轮正常源启动中也存在，之后模块返回 0；`VM_AUTH_IMAGE -1` 也见于正常源启动且被后续代码忽略。它们均不能据本轮片段直接定性为复位原因。当前未取得完整可靠的 panic、SError 或致命回溯。

### 21.3 日志限制与后续

本轮 console 同时含目标早期回放、1.1 秒附近模块记录、源 378/379 秒关机残片及明显字节损坏；本轮 nonce/cmdline 未保留下来。目标身份依赖 build-id、目标独有 DT 节点及前后日志差异，不能逐字认证每条残行，也不能据最后残行推断复位时刻。Normal-WB ramoops 的普通写入没有每条 console 到 PoC 的显式写回，且 debug 日志对 256 KiB ring 造成大量覆盖；目前不能仅由这些混杂字节断定具体损坏机制。

已从同一 initrd 提取并审阅实际 `qcom_dynamic_ramoops.ko`：module_init 只注册 platform driver，创建 ramoops 位于 probe，不会绕过被禁用的 consumer 节点直接创建第二后端。下一轮保留已验证的 GIC 交接，在独立 `native-log/` 目标树增加默认关闭、明确参数启用的 console 写回诊断，并移除 `initcall_debug ignore_loglevel`；不凭最后残留模块名做禁用，不改看门狗。

设备随后恢复安装版 `6.6.89-Gold_bug`，build-id `931f89c6…`，启动 UUID `0f6ecaaa-f99d-4099-b84b-30ba70566321`，Android 启动完成、root 可用。第六轮原始记录在 `out/kexec-boot-fix/round6/`；没有刷分区、改变看门狗或重试跳转。整体目标仍未完成。


## 二十二、第七轮实测：捕获安全 carveout 清零的致命外部访问异常

### 22.1 本轮镜像与日志证据

源仍为已正常启动的 GIC 交接内核 `7fbb6d4cdd9bbf06915a84f0d71665a4afbdb33f`，本轮源启动 UUID `188e1634-2e0c-4502-a2a7-8d2a8d056081`，Android 启动完成、695 个模块正常加载。目标另在 `native-log/` 构建，只增加默认关闭的 Normal-WB console 写回诊断，保留既有启动/搬运/MMU 汇编和 `__memset`；build-id `f93a5b41fb60172452d1ba9cc767d9014162da82`，Image SHA-256 `7e4f108e6ab0e2b34afe776fb22257c738061ae0adf3626a92ca3d528b7cfaba`。配置、16,306 个导出 CRC、10 个关键布局和实际 ELF 已核验；20 个关键目标文件页在真实搬运源页中逐页核对。写回诊断只对明确启用、Normal-WB、无 ECC 的 console 全区（含 header）清到 PoC 并执行 DSB，未改 pmsg/dmesg 写入；其开销可能改变时序，仅作故障采集。

本轮移除 `initcall_debug ignore_loglevel`，保留 native ramoops 和 GIC 保留范围。实际 DTB SHA-256 `adc2b069cdd8b161e87a95d5967b4a3865bc7dca43b55f0db11f0aa25b4779d3`，源捕获集合与目标保留范围相等，均不与装载段相交。只临时启动一次、跳转一次，未刷分区或改看门狗。原始记录在 `out/kexec-boot-fix/round7/`。

`pstore-after-exec.txt` 的实际 LF 行 133–180 记录：

- `1.175388s`：`Internal error: synchronous external abort: 0000000096000010 [#1]`，CPU6、PID185、`Comm: init`，目标独有 build-id `f93a5b41…`。
- `pc: __memset+0x16c/0x188`，`lr: __carveout_heap_init+0x60/0xd8 [qcom_dma_heaps]`；堆栈包含 `qcom_secure_carveout_heap_create`、`qcom_dma_heap_probe` 和 `finit_module`。
- 实际寄存器 `x21=0x9b280000`、`x20=0x40000`；故障字 `0xd50b7428` 为 `DC ZVA x8`，与目标 ELF 完全匹配。这是该对齐清零路径的第一次实际写入。
- `1.179683s`：`Kernel panic - not syncing: synchronous external abort: Fatal exception`。后续其他 CPU 的 `clear_page` 等回溯是 panic 停核快照，不是额外独立故障。

ESR 是当前 EL 数据访问的同步外部异常，不能仅凭它判断是哪一层 TZ、互连或 EL2 权限拒绝。实际模块映射意图为 Normal-NC，不能据 DC ZVA 故障擅自改成 `memset_io` 或跳过清零。目标命令行 printk 截断，未保留本轮 nonce；console 仍有少量字节损坏，但关键 PC/LR、寄存器、panic、目标 build-id 和厂商模块 build-id 互相吻合。不能宣称每个日志字节均可靠。

### 22.2 实际厂商模块与安全内存生命周期

从本轮完整 CPIO 提取实际 `qcom_dma_heaps.ko`，build-id `d06a59aeae01fb44d0ba7088ec1b6f142127d51c`，SHA-256 `ab7c562caae199b8a14d06c28bd3479e0c5c78e5e91a8cd77dcb459e51eebe80`；结合 `secure_buffer.ko`、`qcom-scm.ko` 和匹配的 OnePlus 官方源码逐指令核对，审计在 `round7-dma-review/audit.json`。

故障范围是 `/reserved-memory/spu_secure_shared_memory_region@9b280000`，`no-map`，对应 `qcom,secure-sp-tz`。厂商实现先映射并清零，再执行 HLOS→安全 VMID 赋权，最后发布 dma heap。因此目标此次尚未执行自己的赋权。token `0x01000000` 在实际模块解码为 VMID `0x22 / CP_SPSS_SP_SHARED`、RW，目标列表不包含 HLOS。源正常启动的 `Created qcom,secure-sp-tz` 证明创建路径及赋权 API 返回成功，但不是实时所有权查询；第二十四节补充了实际 SCM 接口可能直接 no-op 的条件。

相邻 `qcom,secure-sp-modem` 位于 `0x9b2c0000..0x9b300000`，token `0x10800000` 对应 VMID `0x0f / MSS_MSA` 和 `0x1a / CP_SPSS_SP`，也不含 HLOS。实际 driver 没有 `.shutdown`、`.remove` 或 module-exit 整块回收；buffer free 只归还 gen_pool，不撤销整块安全赋权。**这构成跨 kexec 遗留安全归属的完整代码路径，但仍须回收后的设备对照实验确认因果。**

### 22.3 修复验证范围与当前设备

先用只读 GPL helper 核验两块 heap 的实际 metadata、pool/bitmap 及 SPSS 的 remoteproc state/power；不访问安全 backing RAM，不调用 SMC，不停止 remoteproc。已核实安装内核与 helper 构建的相关公有 BTF 布局一致，加载的三个厂商模块 build-id 与本轮 initrd 相同。仅 pool 空闲不能证明固件/DMA 静止，`OFFLINE/power=0` 也只是一时框架状态。

后续回收须在 SCM 服务仍有效时执行，验证真实 heap/DT/VMID、阻止新分配、确认相关消费方已静止，然后通过已有 SCM API 归还 HLOS。不能在 `device_shutdown()` 已关闭 SCM 后补调，不能忽略错误继续跳转。SPSS、MSS 的状态和启动竞态仍在核对；Linux MSS DT `status="no"` 不等于证明硬件已停，不能盲目回收第二块。目标保留原清零与赋权流程。

设备已恢复安装版 `6.6.89-Gold_bug`，build-id `931f89c6463a6af0eea9436b61f059f31e451f6a`，启动 UUID `3a811e8f-05f7-4b0b-ab3e-49388fe10a3b`，Android 启动完成、root 可用。直接 panic 已定位，安全归属的对照验证与完整修复尚未完成。

### 22.4 只读实机快照与下一轮准备

在上述安装版 Android 加载一次 `secure_heap_readonly.ko`（SHA-256 `b95121a71349e53a66c02d6786ea438d22b4fbd8a1fd31bffca058a2460f2188`），读取后卸载成功，前后启动 UUID 相同、Android 正常：

- 两块 heap 均为预期 token/base，`size=avail=0x40000`，单 chunk，64 位 bitmap 为 0，`allocated_pages=0`。
- 实际 SPSS phandle `0x49`，父 OF 节点吻合，锁内 `RPROC_OFFLINE / power=0`。
- 没有 backing RAM 访问、SCM 调用、remoteproc 停启或通知器；这是瞬时软件快照，仍不是 owner/DMA 静止证明。

原始记录在 `secure-heap-readonly/stock-device-test.json` 和 `stock-observation.txt`。预检首次发现本设备 `adb exec-out` 不传递远端失败退出码，在任何 insmod 前停止；改用无 PTY 的 `adb shell -T`，确认真实退出码后才执行上述一次加载。预检记录单独保留，没有重复 insmod。

第八轮准备已临时启动既有 `7fbb6d4c…` 源内核，Android/root/695 个模块正常，源启动 UUID `6de6f115-34c3-45b2-84b1-fb9e2e4b494c`。尚未装载目标或执行 kexec。单 heap 回收 helper 的生命周期审阅仍在进行；现成 `rproc_del()` 有检查到删除的锁窗口，且 crash worker 可能改变 DELETED 状态，不能直接当完整重启禁止机制。新 runner 将 nonce 放到命令行开头，避免 printk 的 1024 字节截断；目标仍是冻结的 `f93a5b41…`，不修改清零代码。


## 二十三、改用补丁交付；SP-TZ 回收验证已准备，USB 传输中断

### 23.1 修改入口约束与可重放补丁

用户明确要求“不要改源码，改补丁”。此前内核修改只发生于 `out/kexec-boot-fix/` 的临时副本，没有修改上游源码仓库。后续所有内核与模块代码调整都先改补丁，再应用到临时目录编译，不直接编辑源码。

已保存两份默认不启用的诊断补丁：

- `other_patch/kexec_spss_offline_gate_diag_6.6.89.patch`：给 common remoteproc 增加 kexec 专用、不可解封的离线启动封锁；不修改 `struct rproc` 或既有接口。
- `other_patch/kexec_secure_sp_tz_reclaim_diag_6.6.89.patch`：独立 GPL 实验模块，只处理第一块 SP-TZ heap；不会自动装载。SCM 调用在 source freezer 完成、SCM shutdown 之前执行，先封锁 SPSS，再写锁确认全池空闲并令 pool 为 NULL，最后按实际 VMID34→HLOS3/RWX7 回收；失败直接正常复位。完全不处理 SP-modem，不接触 backing RAM。

补丁以 `--fuzz=0` 在独立目录重放，三个 gate 文件及三个 helper 输入文件均与本轮构建输入逐字一致，记录在 `out/kexec-boot-fix/patch-replay/validation.json`。新增代码仍属诊断实验，尚未合入正式主补丁，也未被工作流自动启用。已有正常开机修复仍在 `kexec_kabi_6.6.89.patch`。

### 23.2 最终构建和主机核验

新源 build-id `946e78ead3508f77b1e888f36f5b0485dc72942c`，release `6.6.89-Gold_Bug_kexec_heap_gate_diag`，临时 boot SHA-256 `ab6558526b85b5bc9c35abac6f9c4a91dcb714f8bb371e1cbd306f86688f3375`。相对 GIC 源仅新增离线 gate 开关与 LOCALVERSION；16,306 个既有导出 CRC、14 种关键布局全部相同，唯一新增导出 `rproc_kexec_seal_offline` CRC `0xcbf43629`。内嵌配置一致，启动/MMU/搬运汇编和 DAIF 之后交接不变。

最初构建被 ABI 检查拒绝：实现头 `kexec.h` 使 genksyms 将原本不完整的 `nsproxy/pid_namespace` 展开，改变 22 个 rproc CRC。已只对该实现 include 增加 genksyms guard，普通编译仍使用规范声明；独立比较确认 563 个既有类型定义与旧树相同，没有强制 CRC。修正后的最终 ELF 独立审阅确认 gate、锁、引用及 release/acquire 发布均存在。真实 C 函数的主机测试通过开启 455、关闭 9 条断言，包含在途 boot/add 与 seal 的线程竞态；内核/固件回调仍为模拟。

最终回收模块 SHA-256 `f574276bfe758164f39bbaabb09264f20fdeebe075408162b159801c6a80e2eb`，38 个 CRC 全部匹配（含 `module_layout`），SCM 的规范声明独立生成 CRC `0xcdaced8a`，与实际 vendor 导出/调用方三方一致；正确保留 GPL-only 属性。34 个真实 callback 提取的主机用例通过，包含 seal 在无锁状态调用、pool 隔离先于 SCM、64 位源 VMID mask 及所有失败不继续跳转。`armed`/phandle 参数只读、默认不启用；这些证据不代替硬件对照实验。

实际 `spss_utils.ko` 已与 live GNU note 匹配（build-id `23892a3ff1b07fd71f1f264a21f5ff5fd7d90d37`），没有绕过 common 的 SPSS 启动/SCM 接口。SPSS 按 OF 路径 `/soc/remoteproc-spss@1880000`、phandle `0x49` 识别；remoteproc 序号随启动改变，本次 `remoteproc0` 是 ADSP，不能复用安装版的序号。

### 23.3 当前硬件状态：新镜像尚未执行

切换新 gate 源时，fastboot 的 product/slot/unlocked 查询正常，但发送 boot 镜像失败：`SendBuffer() (Permission denied)`。后续 getvar/reboot 同样传输失败。没有发出有效的 boot 跳转，没有装载回收模块，第八轮 kexec 执行次数仍为 **0**；不能将本次错误算作新内核启动失败。

对指定 serial 执行一次 USB reset 后，主机 xHCI 报 USB 描述符 `-71`、无法重新枚举；ADB/fastboot 都暂时看不到设备。没有刷分区或修改看门狗，已请求用户重新插拔 USB 线/更换直连口。现场记录在 `round8/host-usb-transport-kernel-log.txt`、`gate-fastboot-boot.txt`、`device-test.json`。连接恢复后，先核验新源正常 Android/实际厂商 Build ID，再进行一次已授权的单 heap 对照验证。

### 23.4 原始源码上的完整补丁顺序验证

在独立临时目录从仓库 `kernel/` 原始源码逐文件复制，按正式顺序应用 cgroup、sysvipc、主 kexec 修复补丁，再应用 SPSS gate 诊断补丁，全部成功。gate 三个文件与最终 `946e78ea…` 构建输入逐字一致，启动/复位/搬运汇编不变；原始 `kernel/` 文件哈希前后完全相同。记录在 `out/kexec-boot-fix/patch-replay/pristine-sequence-validation.json`。此项证明补丁顺序和交付输入正确，不能代替待进行的设备回收对照实验。复查时 ADB/fastboot 仍无设备，USB 物理连接仍是下一步实测的必要条件。

### 23.5 USB 重新枚举后的协议状态

主机重新识别到同一 serial `f84de51c`（USB device 78），但系统 fastboot 的 `getvar product` 在 10 秒内无响应，SDK 自带 fastboot 的同一只读查询也持续等待。没有重发启动镜像，未新增临时启动或 kexec 次数。已请求在平板上重启并重新进入 fastboot；仅枚举到 USB serial 不能当作协议已恢复。查询进程与日志记录在 `round8/usb-recovery-protocol-status.json`、`fastboot-usb-recovery-identity.json`。


## 二十四、第八轮已执行：封锁和隔离成功，SCM 结果日志尚缺

### 24.1 USB 恢复与单次对照实测

用户重新进入 fastboot 后，协议恢复，新 gate boot 临时启动成功。源 build-id `946e78ead3508f77b1e888f36f5b0485dc72942c`，启动 UUID `c15d817d-ec82-4c37-b935-682f3b03a8e8`，Android 完成启动，695 个模块正常且实际 vendor notes 匹配。此前失败的 USB 发送没有执行新内核；本轮总计三个临时 boot 请求，只有一次 kexec 执行，具体计数见 `round8/device-test.json`。

首次加载 helper 被 EBUSY 拒绝且没有保留模块。实际发现 SPSS recovery 为 `enabled`；按精确 OF 路径识别 SPSS，确认 OFFLINE 后，仅将已有 sysfs recovery 写成 `disabled`。该操作只改变框架 recovery flag，不启动/关闭固件、不改变看门狗；复位恢复默认状态。第二次 insmod 成功，helper 仅完成 metadata 校验，直到 kexec notifier 才封锁和回收。

目标仍为原始 `f93a5b41…` Image，SHA-256 `7e4f108e6ab0e2b34afe776fb22257c738061ae0adf3626a92ca3d528b7cfaba`；本轮 nonce `7c542957a37e4cde`。initrd 压缩载荷及 CPIO 未变，只刷新 bootconfig footer。装载审计通过：28 个搬运链页、14,030 个目标页、97 个 PTE 样本、20 个关键 Image 页，真实 captured 集合等于 DT 保留集合，覆盖 16 个硬件表范围，且与全部装载段无交集。DTB SHA-256 `d56742cb40f9e2a5eb59701d26010992fe02feb19178e5da09bb8194a63e0ca7`。

### 24.2 日志能证明和不能证明的边界

`round8/pstore-after-exec.txt` 为 262,132 字节，SHA-256 `1523a7f1110966c90146f305c4c852a417bec960b6c5ee5518427aef1869f690`。实际 LF 第 12–14 行出现源 698.964 秒的 `KT enter`、`SHRC phase=sealed`、`SHRC phase=isolated`，身份与 heap 地址/size/VMID 符合；随后变成旧源日志残片。没有 `phase=reclaimed`、`fatal`、目标 build-id 或本轮 nonce。

这些记录只证明 seal 和 pool=NULL 隔离完成，并到达 SCM 调用之前的日志点；不能证明 SCM 已进入/返回、回收成功、目标进入，亦不能据缺尾日志断言 SCM 卡死。源的 Normal-WB console 当时没有显式逐次清到 PoC，日志头和数据可能只保存了部分。独立证据审阅在 `secure-heap-reclaim-review/round8-evidence.json`。

复位后恢复安装版 `6.6.89-Gold_bug`，build-id `931f89c6463a6af0eea9436b61f059f31e451f6a`，启动 UUID `b39035bf-4592-419c-8299-9edff9a8d0ca`，Android/root 正常。没有刷分区、改变看门狗或重试跳转。

### 24.3 实际 SCM/Gunyah 接口的补充核验

实际 `qcom-scm.ko` 的 public assign 先调用 `gh_rm_needs_scm_assign`；谓词为 false 时直接返回 0，不修改输入 owner mask，也不执行 SCM。真实 SCM 成功路径才将 owner mask 写为目标 VMID 位图。本 helper 坚持同时验证 ret=0 且 owner mask=BIT(3)，不把 no-op 当回收成功。源 BIT34 没有被截断；实际序列化是 VMID34，目标 HLOS3/RWX7。低层错误最终一般被 public API 归为 EINVAL，无法仅凭该 errno 得到固件详细拒绝原因。审计在 `round8-scm-review/audit.json`，主机用例模拟 RM/分配/SCM，不能代替硬件结果。

对本请求，no-op 的精确条件是：feature_use_scm_assign=false、getter 成功且当前 VMID 不等于 3。已将只读 getter 模块保存为 `other_patch/kexec_gh_vmid_readonly_diag_6.6.89.patch`，通过应用补丁生成临时源码并构建。实际 GPL 导出、CRC `0x31f38dd6` 与 getter 原型独立核对，模块仅调用一次 getter 并打印结果，不调用 assign、不触碰 heap。

在上述安装版 Android 实测一次加载、一次卸载成功：getter ret=0、当前 VMID=3，前后启动 UUID 不变，Android 正常。记录在 `gh-vmid-readonly/stock-device-test.json`。这说明正常当前环境应走真实 SCM 分支，不是实时 owner 查询；新源正常启动后还会核验其 VMID。

### 24.4 下一次最小差别：只补源 console 持久性

新增默认关闭、须 `ramoops.console_flush_diag=1` 明确启用的 `other_patch/kexec_console_flush_diag_6.6.89.patch`，应用到独立 `secure-heap-flush/source`。其 `fs/pstore/ram.c` 与已使用的 F93 目标逐字相同，只对已完成的 Normal-WB、ECC0 console 写入清理整个 validated zone 和 header 到 PoC，随后 DSB SY。不更改 pmsg/dmesg、目标 Image、SCM 回收顺序或 callback C。

新源 Image 已编译成功，正在完成 ABI/ELF/boot header 和运行时守卫核验。即使启用写回，printk 尚未进入 console 或执行中断仍可能留下缺失记录，不能把“没有最后一行”直接当某个调用未返回的证明。此项仍属诊断补丁，尚未合入主 kexec 补丁或工作流。


## 二十五、第九轮实测：带源 console 写回仍停在 SCM 回收调用前可观察边界

### 25.1 冻结构建与实际运行守卫

源 build-id `8dde72278b557d4fd2488c1cab40759e890397bc`，release `6.6.89-Gold_Bug_kexec_heap_flush_diag`；boot SHA-256 `175f99b5cefd5b74313d26586e96cdb4bf89b65afe98fc8233cdf49d0634d657`。与 `946e78ea…` 相比仅新增 console flush 配置及 LOCALVERSION；16,307 个已有导出 CRC（含 seal）和 14 个结构布局一致，remoteproc 全部执行段及归一重定位相同。`ram.c` 与 F93 逐字相同。boot v4 保留全部原头字段，仅在 cmdline 字段追加 `ramoops.console_flush_diag=1`。独立最终 ELF 审阅在 `secure-heap-flush/probe-final-elf-audit.json`。

回收 helper 用原权威补丁重新应用，C 仍为 `b99466b05dfc4b360533688b8d442239dcb65c122bffc97f60b8eb126ac45dda`，重新绑定新源后 ko SHA-256 `617c917c0416ecaecbd9e20069e8c3282505c86a265e2df90c5c10445944ea3a`。全部执行段与上一轮逐字相同，38 项 CRC 匹配；变化仅为绑定、版本及构建 metadata，见 `secure-heap-flush-reclaim-review/audit.json`。

临时启动一次成功，源 UUID `c98d4c50-1f2d-47a9-a473-1ac89b4cbaec`，Android/root/695 个模块及 vendor notes 正常。只读 getter 再次查得 VMID3并卸载。运行时 BTF、machine_kexec 前缀及新 ELF 匹配。实际 bool=1，ramoops context memtype2、console type2/ECC0，console PA `0x880000000`、256 KiB；全部 64 页的 PFN 元数据、PTE PA/index0 及无线性别名检查通过，双读相关 metadata/PTE 稳定。PFN 快照不能持有跨用户态 BPF 调用的同一 RCU 临界区；MAIR0 的 WB 含义基于匹配源码初始化，没有读取 live MAIR。

目标仍为原始 F93 Image，initrd 压缩载荷/CPIO/完整 footer 刷新后的哈希与第八轮相同。nonce `d4b35dbfac8f843c`，只保留一个 flush 参数。28 个搬运链页、14,030 个目标页、97 个映射样本、20 个关键目标页及 GIC captured==DT 检查通过；DTB SHA-256 `d70bc83d39f1c13073eae7debb8e6068f1f5b8c4b2e1cf8885b4bac32c2064df`。之后只执行一次 kexec，无重试。

### 25.2 本轮证据及其边界

`round9/pstore-after-exec.txt` 为 262,132 字节、2,273 个 LF，SHA-256 `1c78613324740edbb8c9c73cbffd2087d69125053f30bafa864dbfd5519c2224`。最后三行均完整 ASCII/换行：源 `527.317324` 的 KT enter，`527.317425` 的 sealed，`527.317495` 的 isolated；随后直接 EOF。没有 reclaimed、fatal、目标 F93 build-id 或 nonce。较第八轮，尾部不再回卷到旧 37 秒残片；整份日志前段仍有损坏，不能称全日志无损。

三个 marker 只给出最后可观察执行位置。isolated 在 printk 返回、对应 cache clean 结束和实际 BL assign 之前；即使启用 flush，新的 printk 仍可能先入 ring 尚未交给 backend，不能从 missing return 断言 SCM 已进入、未返回或已错误返回。独立审阅在 `secure-heap-flush-reclaim-review/round9-evidence.json`。

ADB 在执行请求后 8.210543 秒以 255 返回，42.247260 秒内完成新 stock 的证据采集；这些不是精确复位时刻，也不能据 stock uptime 倒推出失败停留时长。安装版 build-id `931f89c6…`，UUID `c4e14928-a066-4570-8e13-6ffd72a674dd`，Android/root 正常。未刷分区或改变看门狗。

### 25.3 接口与现有固件日志复核

对实际 vendor 初始路径及 helper 逆向参数再次核对：静态 SP-TZ heap 直接经 `hyp_assign_from_flags → qcom_scm_assign_mem`，HLOS3→VMID34/RW6，整区 `0x9b280000/0x40000`；逆向使用 BIT34→HLOS3/RWX7/count1 未发现范围、ABI 或必需 SG API 错配。RWX7 也符合匹配官方 SG unassign 回收约定；这不证明实时 owner、固件静止或安全固件允许逆转。记录在 `round9-assignment-review/audit.json`。

源 normal kexec 在 SHRC 之前只冻结用户线程并禁用 usermodehelper，不冻结 kernel workers；blocking reboot chain 完成后才置 SYSTEM_RESTART、执行 device_shutdown。实际 qcom-scm 没有 reboot notifier，只有后续 restart handler；GH/RM 消息模块也未见在此链关闭服务的 callback。SCM 的设备 shutdown 仍晚于当前 helper。这些复核未发现“调用前 SCM 已因本轮关机关闭”的静态路径。

只读读取 `/proc/tzdbg`：TZ reset/boot/log/vmid 等为加密日志，无法据其判断此次拒绝；hyp_log 只含当前 stock 新启动 1–11 秒的记录，rm_log 为空，不能当上一次失败瞬间证据。已归档在 `round9/firmware-logs/`。临时只读 debugfs mount 已卸载并删除目录，未改任何日志开关。

### 25.4 下一轮仅加 helper 调用边界 telemetry

复用冻结 source8dde/targetf93，不改变 SCM 参数、seal、pool 隔离、返回后所有权 guard 或目标清零流程。补充默认关闭、只读参数显式启用的 helper 诊断补丁：只记录 public assign、lower C transport 入口及实际 BL SMC 的前/后位置；probe 只读参数，不改 regs、不显式 console 操作或睡眠。正常 callback 立即记录 SCM ret/owners，并作有界 best-effort console trylock/unlock；所有新行为须显式启用。该方案仍不能将缺失 marker 当“未执行”的证明，须用实际正记录推进定位。


## 二十六、第十轮实测：已到实际 SMC 包装调用前，准备隔离 SP heap 初始化

### 26.1 可选 telemetry 补丁与实机启用

source 复用冻结 `8dde72278b557d4fd2488c1cab40759e890397bc` 和原 boot，target 仍复用 F93 Image。新 helper 由原权威回收补丁加 `other_patch/kexec_secure_sp_tz_trace_diag_6.6.89.patch` 生成，最终权威补丁 SHA-256 `3b07f06ec50e0c3bb1ee0ebe82f88d0657e117804c4897d9dc2f9c34ed4bfb6d`，C `d518d82193374b5e10f926ffd68789d2948e53227e86d46239aae4dc9cf0b2b8`，ko `7293eb1df221dcace697c16bf77e59132751b2339668dc2a1dab199075bbd20c`。首编只因 u64 printf 类型不匹配被 Werror 拒绝，修复先入权威补丁再应用 delta；未禁用 Werror 或直接改 C。最终 45 个 CRC 全匹配，三个参数 0400，trace 默认关闭，SCM/seal 仍各一次。完整补丁重放与构建输入逐字一致。两份最终独立 ELF 审阅在 `secure-heap-trace-probe-review/audit.json`、`secure-heap-trace-early-review/final-audit.json`。

四个 kprobe 位于 actual qcom-scm BID `45818a2d…` 的 public assign `.text+0x29fc`、lower C transport `.text+0x6e90`、该函数 `+0x200` 的 BL 前及 `+0x204` 的下一条指令。init 验证 entry16B、实际 address delta、原 opcode 及 BL 直达/既有 PLT 目标；handler 只读寄存器/desc/结果，始终 return0，不显式 console 操作、睡眠、赋权或 reset。single-task、validated publicSP→lowerSP−0x130、lower SP/FP/result pointer 约束防混入嵌套调用。normal callback 立即记 ret/owners，最多十次 trylock 促进 console 写出；不是严格总时限或持久化完成屏障，printk 仍会扰动时序。

源本轮 UUID `1ae13e2f-827d-4b6a-9fc0-0a802c814b8e`，Android/root/695 个原模块、VMID3、source flush 64 页守卫均正常。启用 console 只有 `ttynull0`、`ramoops-1`。helper 实机 insmod 一次成功并完成四处指令核验；debugfs global enabled=1，四个 symbol+offset 均在 active 列表。列表模块名不带方括号且地址按 `%pK` 隐藏为 0，主机旧解析因格式而暂停；修正主机 parser 后只重新只读核验，并未再次 insmod。真实地址/指令绑定以 helper init 的核验及 `%px` 注册记录为准，没有修改 kptr 策略。

目标 nonce `5910bfd030bfa731`，原 Image、initrd payload/CPIO 不变，实际搬运页/DT/GIC 检查通过后只执行一次 kexec。原始记录在 `round10/`，temporary boot、helper insmod、target load、execute 均各一次；没有自动重试。

### 26.2 保存的调用链正记录

`round10/pstore-after-exec.txt` 为 262,132 字节，2,197 个 LF，SHA-256 `7cc8ae4f604e7b7bc0659d162782eb8065ce0a8f88ce74acaf20d814426ac4c0`。最后 LF2191–2197 均完整 ASCII、同 T28134、时间顺序完整：

- `1483.619135` KT enter；`.619212` sealed；`.619265` isolated。
- `.619321` call-begin：固定 base/size/BIT34→HLOS3/RWX7。
- `.619376` assign-enter，valid=1、base=9b280000、size40000、nr1。
- `.619457` lower-enter，valid=1、convention3、mode0、frame_match1。
- `.619514` smc-before，FID `0x42000c16`、arginfo `0x1117`，mem `0x9deac2040`、memsz `0x10`、src `0x9deac2000`、ext `0xb6c09000`。

没有 smc-after、call-return、reclaimed、fatal、F93 或本轮 nonce。正记录证明进入实际厂商 public/lower 函数，并到达实际模块 BL 前 pre-handler。marker 后仍有 handler 返回、原 BL、core ASM SMC 及 printk 持久化窗口，不能绝对断言 BL 已执行或 SMC 没返回。全文前段仍有少量损坏，不能拼造未保存的 panic。独立证据审阅在 `secure-heap-trace-probe-review/round10-evidence.json`。

ADB 返回255用时 8.165253 秒，42.218533 秒内完成 stock 采集，均不是精确复位时间。恢复 stock BID `931f89c6…`、UUID `725dec6e-9382-42e9-ab1f-ddac190cb1ef`，Android/root 正常。未刷分区或改变看门狗。

### 26.3 下一隔离诊断的范围

不继续盲换 SCM/VMID/permission 参数。新源将仅在 native ramoops 诊断和显式 skip 参数同时启用时，禁用目标 FDT 中 `qcom,secure-sp-tz`、`qcom,secure-sp-modem` 两个 heap 子节点。精确 actual `qcom_dma_heaps.ko` 已核实计数和创建均通过 `of_get_next_available_child`，所以这会跳过其 create/zero/assign；父节点、其他 heap、两个 reserved-memory 节点及 reg/no-map/phandle/status 等全部保留。显式 memory-region 引用只见对应 heap，不排除固件或硬编码 PA 消费方。

源 helper 从原 b994 另加 `other_patch/kexec_secure_sp_preserve_diag_6.6.89.patch`，默认 false/0400，显式 `preserve_for_skip_diag=1` 才在原 seal/empty/identity/锁/poolNULL 后走 no_scm 分支，再核 identity 并共用原释放路径；false 的原 SCM 与所有失败门保留。权威补丁 SHA-256 `f4f06468d0e05198a0fd2cf47c49f3e793f807f6e83a39f9d60619aaf23785e8`，应用后 C `b649c98a196a98b685d928e19048ff8cbd1460a542a2f40eb0ebe01aa919e805`。真实 patched callback 的全桩主机定向验证通过 166 条断言；硬件/锁/SCM 为明确模拟，不替代实测。

必须在真正 loaded DT 中确认两个 heap disabled、reserved-memory 原样、其他 heap 未变后才能 execute。preserve helper 本身不验证目标树、不证明 owner，也不能配未经适配的目标当作修复。此隔离用于确认后续 Android 路径，完整修复仍须正确交接安全堆并恢复功能。新工作目录 `secure-heap-skip/{source,build}`、`secure-heap-preserve/`，旧轮次与原 kernel 源码保持冻结。


## 二十七、第十一轮隔离结果：越过 SP 堆，暴露默认 CMA 页面外部中止

源 `218a41818e13202f577a7ef27eca92a55fb84f83` 正常启动 Android，695 个原模块、root、源 console flush 检查均通过。source boot SHA `dc52b023f4fa71eb1c8ed30d558b24dc688e241595082a2f8f0aa31cd5998c39`；只有 LOCALVERSION 和 native DT helper 相对 8dde 改变，16,307 个 CRC 和 14 个布局不变。preserve helper ko `e5b99e096424ee14e9a48cf9a47d787e9b98d3f20a2ae66f5fe6d628e42d4d01`，38 个导入 CRC 匹配，三个参数 0400，实际 true 分支没有 SCM，false 保留旧返回码/owners/身份门。原 F93 Image、initrd 压缩载荷及 CPIO 不变。

实际装载 DT 审计确认两 heap 仅 status 变为 disabled、父及全部其他 heap 不变、两个 secure reserved-memory 完整属性相等。28 个搬运链页、14,030 个目标页、20 个关键 Image 页、GIC capture==DT 和无重叠检查通过；DT SHA `030b0642846455f63a2ebcf937b73f9768502e01c30e96061706f66f8a689a2c`。nonce `c1b3e952cbf046ea`。temporary boot、helper insmod、load、execute 各一次，无自动重试。此轮不作 VMID getter 查询，不虚构本轮 VMID 观测。

目标 F93 已进入 init 模块加载，qcom_dma_heaps 已在已加载列表（无 `+`）。随后 CPU6/init PID186 于 `1.211136` 报 ESR `0x96000010`，pc `clear_page+0x18/0x50`、lr `post_alloc_hook+0x164/0x244`；实际五条 opcode 与 F93 ELF/Image 一致，故障指令为 `DC ZVA x0`。x0/x8 `ffffff806cca0000`、目标实报 PHYS_OFFSET `80000000` 和 VA_BITS39 得到 PA `ecca0000`；struct-page 与清零循环寄存器进一步交叉吻合。

调用链为 `clear_page → split_map_pages → isolate_freepages_range → alloc_contig_range → __cma_alloc → cma_alloc → md_register_memory_dump → md_minidump_memory_init → msm_minidump_log_init → probe`。实际 minidump BID `51c03293594cc8a94c5d4998cf33a952e349bd83`，ko SHA `c3dfd9c9539d74fbd30a0b23936910959561ff31bc41bba172606acb314940fd`。ELF 双 return site 表明本次申请的是 DMA_INFO 的 256 KiB，使用 dma_contiguous_default_area，尚未从 cma_alloc 返回，未登记该缓冲或执行 minidump 自己的 memset；当前 DT 选择 SMEM，不是 minidump-rm。模块不导入 assign，remove 仅返回、shutdown 为空；不能据模块名把拒绝来源归为 minidump 赋权。

F93 的 INIT_ON_ALLOC_DEFAULT_ON=y，分离 buddy 页时会清零整块，故 fault 页不一定等于最终 256 KiB 申请边界。源 default CMA 实报 `ec800000..eebfffff/36MiB`，包含 fault；目标仍为相同 size-only CMA DT，未从已存目标日志直接取得其完整边界。不可仅禁 minidump 或硬编码跳过 fault PA，否则其他分配者仍可能触及旧受保护页。

pstore 为 31,250 字节、364 LF，SHA `9dc9115f81e88fe7383a668827379cb9bc3f1c2bda77a0a0c56ff4ab7a2f4b1a`，含少量损坏，未修补损坏寄存器行。复位后安装版 Android/root 正常，UUID `255ea9fe-e0b5-4f5f-a6ef-4f8f46e4639c`。独立证据见 `secure-heap-skip-review/round11-evidence.json`；actual minidump 审计见 `round11-minidump-review/minidump-offline-audit.json`。完整 Android 尚未启动成功。


## 二十八、第十二、十三轮：只读源元数据和 CMA 分配者追踪

第十二轮再次临时启动同一 218a 源，UUID `de477f49-259c-4895-9fce-a8fded3166c7`。只读临时 debugfs mount 采集 CMA 普通元数据和 dma-buf 列表，随后卸载删除；未写 alloc/free。default CMA basePFN ec800/count9216/order0，bitmap popcount 与 used 均4438，旧 fault 同值 PFN 的 bit=1。它只说明此轮 Linux CMA 占用，不含 VMID，也不能复原第十一轮旧 boot。

对这 9216 页的 struct-page 普通描述符作有界 BPF 读取（146 次），BTF/ELF/build-id/bootUUID/memstart 校验通过，未读取 backing RAM。private+0x28 全无 `0xeeeeeeee`，旧 fault 同值页也是0。actual secure_buffer 仅在部分 hyp_assign_table 成功且目标不含 HLOS 时设置该 software tag；direct SCM 等路径可不设，故无 tag 不能证明页面可写。实物未启用全局赋权 debug xarray，page-owner 明确 disabled。记录在 `round12/`，边界说明在 `round11-cma-review/metadata-evidence.json`。

第十三轮只修改同一 boot 的头部 cmdline，Image 和全部代码不变；boot SHA `6435c94c57906a9aef1eeb2d60edb4c13cabfb1328dfc801ba8c39ca21609bef`。参数启用 builtin CMA start/finish/release，以及独立 `kexec_cma` trace instance、stacktrace、每CPU每array2MiB。global clock 为 global，instance 保持 local，未在启动后改时钟（改时钟会清 buffer）。双 array 共约32MiB加 metadata。source 正常 Android/root/695 模块，UUID `2d6c16b8-04a2-4896-8510-eac3b157c377`。

`round13/cma-trace-instance.txt` 158,906 字节，SHA `7680421e3cebfe5810a723610de7d6f0b4579bfd03eba5f72b3b1ca7b499864d`，646 entries/646 written，各CPU overrun/commit-overrun/dropped 均0。专用 instance 启动后始终开启三事件并保留 stacktrace；global 被 Android 关 tracing，专用仍完整。使用非消耗的 trace 文件归档，未读 trace_pipe、未改变事件或时钟配置。

正记录显示 tz_log_probe 经 dma_alloc_attrs 在 default CMA 成功分配四块：ecca0000/128KiB、eccc0000/132KiB、ecc8c000/12KiB、ed100000/512KiB。其中第一块与第十一轮 fault PA 同值；这是同代码新源启动中的分配者线索，不能倒推为旧 boot 实时 owner 的直接证明。下一步核实际 tz_log_dlkm（BID `44d5bc6026c74b531ae05068a806c847a6b2592f`、SHA `de91d8824d3d87c32c563868022f5dfdcbef1dcc7c86b02a52177dfd4bf3a6ac`）的普通描述符、固件注册及清理路径，正确保留/交接这些动态缓冲；不盲逆赋权。

第十三轮随后已取得 live 普通描述符：模块 notes 精确匹配、tz_log_probe 头16字节与冻结 ELF 一致，四个 PA/size 与 trace 逐项一致，encrypted/enlarged 均为 true。源 sysfs sections 按 kallsyms 策略返回0；保持该策略不变，改用已授权 BPF 读取精确 BTF 的 modules/sect_attrs 普通元数据定位，再双读检查描述符稳定，未读任何 DMA payload。见 `round13/tz-log-live-descriptors.json`。其 host 快照不持跨调用的共同 RCU/模块引用，不能将稳定双读夸为原子固件状态。

实际 raw QSEE 缓冲通过 SCM svc1/cmd6/owner TOS 注册；actual SCM 和匹配官方接口没有对应 unregister。encrypted 模式 remove 直接 dma_free raw buffer，另两个 bridge 的删除返回值也未作为安全回收条件，shutdown 为空。因此不尝试 unbind/rmmod 来撤销，也不猜测 VMID 逆赋权。下一诊断补丁以当次 live 元数据动态保留缓冲区，装载前核身份/引用/设备绑定，跳转前复核并防止目标分配覆盖；仍须由下一次实测验证是否推进，完整日志接管/重复 kexec 的功能修复另需处理厂商生命周期。


## 二十九、第十四轮准备：动态捕获并保留四块 TZ 日志缓冲

权威补丁为 `other_patch/kexec_tzlog_preserve_diag_6.6.89.patch`，SHA-256 `0c251e2e3f60478a1fa5dd0110cced205ac6c9dff60c8e30f3c9842f5ecfddfd`。只有配置开启且目标同时显式指定 `kexec_diag.early_ramoops=1`、`kexec_diag.preserve_tzlog=1` 时启用；从当次实际 `tz_log_dlkm` 普通 metadata 取得 raw QSEE、encrypted QSEE、encrypted TZ、display 四块 PA/size，固定模块 build-id、设备/driver/OF 绑定、CMA 范围与分配状态，并持有引用。不读取 DMA payload，不调用 SCM、unregister 或固件停止接口。

捕获存入每个 kimage 私有 metadata，在目标 `/reserved-memory/kexec-tzlog-preserved` 新增 version1、四个有序 `reg` tuple 和 `no-map`；最后单 CPU、IRQ 屏蔽、禁止调度窗口再核身份和 metadata。F93 的实际多 tuple 循环会为四块分别执行 NOMAP，first 标志只影响 reserved_mem 对象登记。不过逐项失败仅打印错误，故主机仍须验证四块都在真实 RAM 中、与其他静态保留、GIC、header reserve、目标段及完整搬运链分离；节点存在本身不等于目标已成功预留。

新源 release `6.6.89-Gold_Bug_kexec_tzlog_preserve_diag`，build-id `84260068f6d24ee8926dbe14ac0c131d8b23587a`；boot SHA-256 `4b06a1e5068f0769d11f0d19a8560f7b76476a60d0446538530872f5f88887b1`。完整构建通过，16,307 个原 CRC 和14个关键布局一致；原 remoteproc/GIC 执行代码、共享启动/搬运汇编及最终物理调用后缀不变。25项真实 libfdt 定向验证通过，不能代替硬件权限验证。证据在 `tz-log-preserve-review/`。

准备阶段临时启动一次，新源 UUID `98887e59-b9df-4d55-afd5-2a4852beaab9`，Android/root/695 个原模块及实际 vendor notes 匹配。目标准备 nonce `07d066c804098959`，Image 仍为 F93、原 initrd 压缩载荷/CPIO 不变；目标末尾 `loglevel=7` 用于尽可能保存 CMA 实际边界。新 preserve helper 仅绑定新源，C 与前轮相同，38个导入 CRC 通过。helper 和目标均各加载一次，此时尚未执行跳转；随后实际结果见第三十节及 `round14/device-test.json`。此轮是定位对照，四块 NOMAP 和禁用两 SP 堆均不能作为完整功能修复。

本轮读到 per-kimage 捕获快照与当时实际模块 globals 逐项一致，四块仍为 `ecca0000/20000`、`eccc0000/21000`、`ecc8c000/3000`、`ed100000/80000`，source CMA 为 `ec800000/2400000`。第一次只读装载审计停在 host 原有的保留页链表4096项限制，未执行 kexec；该旧错误没有区分 cycle 和 cap，不能仅据报错断言其中之一。源码证明复制整个线性映射时合法控制页可超过4096，因此修正 host 上限、分别报告循环/数量限制，缓存普通 memmap 块并只复核实际使用的 lru/order 字段，保留全部 PA 重叠检查。六个定向用例通过，新 validation SHA `0f41609b93855ef0723973f8b20b52f4f2e723cfe71c2fb6ff32efb294999aa6`；修正后只重跑只读审计，没有重装载或更改任何内核代码，随后通过并执行一次跳转。


## 三十、第十四轮实测：越过 CMA 崩溃，定位到 UFS 辅助时钟和首次挂载

修订后的只读检查通过：7927个合法 control_pages，无 dest_pages/unusable_pages，2011个普通 memmap 块及所用 lru/order 字段复查稳定；全部源/目标/链表/控制页及 kimage 私有 metadata 页与四块 TZ、GIC和ramoops保留区分离。28个搬运链页、14030个目标页、20个关键 Image 页及实际 x0/入口/段大小检查通过。实际目标 DT SHA `c34d5c1b11237a1078d760749a3aee7bc2a46ad30736d3ad3452659f5ca8c7b0`，四个有序 reg/no-map 与内核捕获和当前模块 globals 一致，真实 RAM 覆盖和其他静态/header/GIC保留无交叉。source/target/helper/Image均未因 host 检查修正而改变。

随后严格执行一次 kexec。目标 F93 约1.054268秒明确记录 `init: Loaded kernel module /lib/modules/minidump.ko`，已经越过第十一轮该模块 cma_alloc/clear_page 崩溃路径。本次没有保存可读的目标 CMA 完整基址/长度或四tuple逐项 NOMAP执行成功记录；早期日志已被256KiB环覆盖，不能将 source CMA 地址当作 target CMA 地址。保留方案使本轮启动推进，但不单独证明实时固件 owner 或完整日志交接协议。

目标约1.212秒首次出现新异常：`gcc_ufs_phy_phy_aux_clk_src` 的 CMD_RCGR=`0x80000000`、CFG_RCGR=`0x00100001`；`gcc_ufs_phy_phy_aux_clk` 的 CBCR=`0x88000001`，branch等待off超时。`ref_aux_clk enable failed -16`导致 PHY power_on失败、UFS控制器多次enable失败，约1.479秒 `ufs_qcom` probe最终返回−5。约11.225秒 PID1等待分区超时、无法建立首次挂载所需设备，主动退出，panic原因字段为 `Attempted to kill init! exitcode=0x00007f00`。最后的watchdog bite是panic复位路径，不能反过来当作最早启动故障；没有改变看门狗。

SPMI transaction0x3和QSMMUV500若干probe告警在本轮正常源和复位后的安装版也存在，暂不列为热启动独有根因；UFS auxclk失败在这些正常日志中没有出现。当前正对实际clk_qcom（从本轮CPIO提取核实BID `91d44fc19669bcbe13c2525725cf337b4f693cd3`，损坏日志中有不同变体）、phy_qcom_ufs（`da0d45e45f727c03861320cf4132255b22a0cf5c`）和ufs_qcom（`a0f190cdb34943457dc4f4642b720838e77acda3`）核对父时钟、门控与source shutdown/target enable顺序，不跳过检查强行继续。

实际ELF进一步确认：首个失败返回点对应 `ufshcd_init` 的 device_reset 调用；vendor major>=6 路径已经成功调用原 `reset_control_assert`，随后 PHY power_on 返回−16，原 deassert 尚未执行。后四次相同失败对应 HCE PRE 初次及三次重试。source842/F93 的 common UFScore源码和执行段相同，UFS/PHY/GCC实际装载DT属性也完全一致。当前窄假设包括复位范围、AH8时钟请求及GDSC/父时钟状态；最后失败后的整片HBA寄存器为0发生在BCR仍assert之后，不能据此复原最初进入reset时的状态。下一步若需新增日志，将仅通过独立vendor诊断补丁记录原调用边界，保持复位/clock/PHY调用顺序与次数不变。

原始pstore为262132字节、2888个LF，SHA `63767893c8db2249b2b41e16604ade568eb16f165513616b5047962baeb303f3`，含大量损坏字节，不补造缺失字符或nonce。目标身份由多处完整F93 build-id/调用栈交叉确认。恢复安装版UUID `81ba8eaa-ccd0-4444-9e93-4ef9fac14d0a`、Android/root正常；没有重试跳转或写入分区。记录在 `out/kexec-boot-fix/round14/`。


## 三十一、第十五轮准备：保持原复位流程，记录 UFS 和时钟回调

本轮复用冻结source842及原helper，仅更换目标诊断Image和带一个诊断厂商模块的initrd。临时源UUID `78e5e9a9-e184-4c9e-a4c5-53993eae5384`，Android/root/695原模块正常。准备阶段先装载而不跳转，完整搬运链和实际DT审计通过后执行一次；最终计数和实测结果见第三十二节及 `round15/device-test.json`。

CCF权威补丁 `other_patch/kexec_ufs_clk_trace_diag_6.6.89.patch`，SHA `cc424f3a58df8ff58e54d8073615ad02209586b573d0f2e103c0fb57694b31f0`。仅改clk.c，在精确一次 `kexec_diag.ufs_clocks=1` 且目标chosen含kexec标记时，记录 `gcc_ufs_phy_phy_aux_clk_src` 和 `gcc_ufs_phy_phy_aux_clk` 的软件计数、父级和实际callback边界；不新增时钟操作。42项实际C主机定向检查通过。独立目标BID `7cfb27fb800a8d51ef5f2a90ba582cb03185fdd5`，Image SHA `2ab9fbca04d66a4c178b568ee3a497d80b3f54182de2441697048dffbdd93b04`。最终ELF控制流、16306个CRC及18个布局检查通过；重新计算76个关键页，console参数表地址确已变化，未冒用旧F93偏移或console审计。

UFS权威补丁 `other_patch/kexec_ufs_handoff_trace_diag_6.6.89.patch`，SHA `874ecef29b3d6fad7917f8b0927f8bb7502362b559a39d6b0d332ce5cf698fe2`。保留原GPIO/BCR/PHY顺序和错误路径，仅在device_reset入口、BCR assert前后、原phy_power_on返回后、成功BCR deassert后五处记录AHIT/HCE/CFG1/HW_VERSION/AH8_CFG。默认false/0400参数还要求kexec chosen标记与major>=6；寄存器为顺序读，不是原子硬件快照，BCR窗口读取及printk仍有故障和时序扰动风险。

厂商完整5obj基线由官方4553152f原样输入加fe7332c9原样ufsfeature.h组合，逐文件出处已保存，明确不是单commit快照。原始重建模块的全部执行段、运行时数据及271个CRC与实机模块一致；没有删UFSTW/HID功能、手改位定义或伪造CRC/vermagic。其上生成的诊断模块BID `8caf54bbd029e9dea8dae52c58eae54bcee579df`、SHA `2d961e2bdc98eb1c9f52a5625ce57d0921cf66e40e501b2bee4e7fe23c6f5f35`，原271个CRC保留，仅新增of_chosen导入；布局和其他四个feature对象检查通过。

目标initrd仅替换 `lib/modules/ufs_qcom.ko` 并新增 `modules.options` 的显式诊断参数。两段newc串联保留，其余547个原member的header/data/padding逐字一致，段间512对齐重新计算。新gzip载荷SHA `c43884f3d2bf8b43ce4f028fdabea41c4051d88c9492b7c3ff9c278d590a450a`，CPIO SHA `e1aa5b36ffc1646757f30d5f345bc4b19ba8b7e5f1a27b6e1f222f51a8a6d585`；装载前已刷新为本次source bootconfig。最终runner validation SHA `1a7b4cfc66ebcde6a48048d0d584e245ac047a8bbecbdac3fb0505364b0de812`，独立闭环绑定通过；新模块244个GKI CRC已对新目标核验，其余28个vendor导入仍对actual模块核验。nonce `f6f9a03da51a22c0`，实际load一次成功，随后完整GIC/TZ/搬运链互斥检查通过并只执行一次。


## 三十二、第十五轮实测：父时钟早启成功，首次BCR前AH8请求配置仍在

装载后只读审计全部通过：7927个control pages、1196个普通memmap块、2398次保留页链后端读取；28个搬运链页、14144个目标页、76个关键Image页和5个kimage bookkeeping页与GIC/TZ/ramoops保留区无交叉。实际目标DT为1601295字节，SHA `c85ca5b8230e76c2b42106068a20dc741b5304517515e29a84d79297524d11ef`。四个TZ实际捕获仍为rawQSEE `ecca0000/20000`、encQSEE `eccc0000/21000`、encTZ `ecc8c000/3000`，display本次为 `ecd00000/80000`，与第十四轮不同，动态捕获及实际DT逐项匹配。source CMA仍为ec800000/36MiB，未据此假定target CMA边界。

temporary boot、helper insmod、load、execute均严格各1，无自动重试。目标日志LF604完整记录1.258366秒 `Loaded kernel module /lib/modules/minidump.ko`；LF1066完整记录实际init用 `kexec_handoff_diag=1` 加载ufs模块，后续有多条完整新BID `8caf54bbd029e9dea8dae52c58eae54bcee579df` 与目标7cfb的栈记录。因此本轮确实运行到新诊断模块，不能只按host文件推测参数生效。

时钟正记录将两个阶段分开：LF1085在1.401400秒显示SRC enable=0/prepare1，随后callback-begin；LF1088完整enable.return显示SRC count1/ret0，发生在GCC注册完成日志之前。中间callback-return的clock名字受损，未补字。结合冻结实际函数控制流，SRC早期已经成功走过启用路径，不能说父callback始终未执行。SRC实际clk_init_data.flags为4（CLK_SET_RATE_PARENT），并非CLK_IS_CRITICAL；这一个早期引用的具体调用来源仍在追查。

UFS真正请求aux子支路时，SRC已持有count1。完整LF1271显示SRC skip-count，其他完整返回显示count2；子支路callback实际返回−16，失败回退后SRC由2降为1。多处完整记录相互印证这一模式。LF1492的raw count0与紧邻skip/return矛盾，该行本身受损，不能将其解释成父计数重新清零的正证据，也不能拼修为1。

五点HBA记录中，LF1193的整个payload完整：1.440332秒、pre-bcr-assert、major6、ret0、is_phy_pwr_on0，AHIT=00000000、HCE=00000000、CFG1=d85c052c、HW_VERSION=60010000、AH8_CFG=0000183c。因此首次BCR前四个请求控制位0x3c确实开启。实际匹配厂商代码只在linkstartup POST开启这四位，另有独立0x1800未用Unipro门控位；本轮尚未到linkstartup。此证据支持热交接残留假设，但尚未测得请求线电平或证明它造成aux超时。

device-reset-enter行的AHIT/HCE受损；post-BCR行连stage拼写也受损，保留原字节，不规范化。该行HCE/CFG1/HW_VERSION/AH8字段读到0，且postPHY记录ret−16，但BCR窗口HW_VERSION本身也为0，不能把它当作“AH8已经正确清除”的硬件证明。正向PHY失败及已审代码解释为何本次未走成功deassert路径，不用缺少marker反证动作不存在。

目标随后仍为auxclk/PHY−16，UFS probe−5，PID1等必需分区10009ms后退出，11.456秒panic原因字段为 `Attempted to kill init! exitcode=0x00007f00`，随后走watchdog复位。source/恢复系统中也有proc/task_info重复、部分SPMI及stub扩展告警，目前没有将这些共同告警改称本轮首要故障。

原始pstore为262132字节、2824个LF，SHA `4b3253d17920e20f2286c086955d309c3f2f6c98a79dd1c720de7b263d5e5c89`，仍有大量损坏字节，不修字符。恢复安装版BID931f、UUID `c324ca10-b089-486e-8a6a-2b8cc5b527e4`，Android/root正常，看门狗disable实读0。证据分别在 `ufs-handoff-runner-review/round15-evidence.json`、`ufs-handoff-trace-review/round15-evidence.json` 与CCF审阅目录，原始测试数据在 `round15/`。

随后已把这一实验保存为单独、默认关闭的诊断补丁，在同一kexec/major6和初始未上电条件下，于原GPIO/BCR之前按UFS_HW_CLK_CTRL_EN只清0x3c，保留0x1800及其他位，记录写前/目标/读回并保持原BCR/PHY顺序和所有错误检查。正常linkstartup POST恢复请求的既有代码保留。第十六轮应用、构建及实测结果见下一节；它没有解决当前故障。


## 三十三、第十六轮：AH8请求配置已清，父时钟回调执行后仍失败

本轮复用source842的原boot/helper和target7cfb的原Image，只替换目标UFS模块。权威补丁为 `other_patch/kexec_ufs_ah8_reset_diag_6.6.89.patch`，SHA `c73f1f43ae4feafd34c948f9b8ef03025e38df5ab9609783f2c9ea5c64c6da47`，依赖原五点trace补丁；新模块SHA `9a9d01348cdd893843a5c799bf056f19e9ec26ec050c43aba207f0c3b07500a9`、BID `dac4ecf95ba43474bc1de478988329668fd4d75c`。两参数均默认false/0400，只有显式 `kexec_handoff_diag=1 kexec_ah8_reset_diag=1`、实际kexec chosen标记、major恰为6、有效reset controls、PHY尚未上电且mask非零时，才对HBA+fc写入一次old&~0x3c，随后readback/屏障/日志。原GPIO/BCR/PHY顺序、失败返回和link POST恢复逻辑不变。

补丁先保存再fuzz0应用到新out副本，未直接编辑C；构建成功，全部272条CRC与R15相同，244个GKI导入对实际target7cfb核验，28个vendor导入对actual模块核验，11种布局不变。实际ELF验证唯一写、读回、DSB与原流程的顺序，独立审阅通过。目标initrd其余547个原member raw records不变，只换该模块并增加双options，gzip SHA `dc6544fa629c01085fd0e5622235fb00e7a2b51f28d8520d1d9836e7aec7bb7f`，装载前刷新本次source bootconfig，最终完整initrd SHA `3ffad960d8b90f029fc7cb806d7b596cec0f8c4de44c6d674d58d708010dbffb`。源UUID `5e3f9ca7-8559-4079-a091-14112373ca00`，Android/root/695个原模块正常；nonce `ebbef56b71ae9afd`。

temporary boot/helper/load/execute均各1，无额外设备重试。装载后7927个control pages、126个普通memmap块、258次保留页链后端读取、5个bookkeeping页、28个搬运链页、14144个目标页和76个关键Image页检查通过；保护区分离、实际GIC capture和双heap/四TZ的DT检查均通过。实际目标DT 1601295字节，SHA `28c66b2b1e5ad84cd7ffdef31a7ef3cbfcdf2c7723853c51b12be4e61b2cac5b`。四TZ依序仍为ecca0000/20000、eccc0000/21000、ecc8c000/3000、ecd00000/80000；本轮重新读取，未假定沿用旧地址。

原始pstore为262132字节、2822个LF，SHA `f7613cf9ceb67a772cc2320bbc61e02a60828f84eed8251ed6802f4f9a2af1d8`。LF1024完整init记录确实用双参数加载模块，actual栈包含新BID。LF1161完整device-reset-enter为AH8_CFG=183c；LF1163完整pre-BCR为1800，其他四个值与上一轮相同；LF1164完整post-BCR五值均0；LF1239完整post-PHY为ret−16、is_phy_pwr_on0、五值均0。post-BCR时HW_VERSION也为0，仍不能将reset窗口零值视作独立硬件恢复证明。

唯一UFSKH2行LF1162的原字节为old=0000183c、desired=00301800、readback=00001800、masK=0000003c、full_match=1。desired与readback/full_match矛盾，mask键大小写也受损，不能修字或称整行算术一致。相邻完整HBA采样与该行readback共同支持pre-BCR请求配置3c已经清除，但不证明内部latch或CLKREQ线电平已经恢复。

与R15的另一重要差异是本轮父SRC首次请求时enable0/prepare1：LF1167–1169完整记录父callback begin→return ret0→count1，随后叶callback返回−16（LF1230等）；失败回滚还实际执行父disable，而非一直保留旧count1。故“父引用非零导致不执行enable ops”不能作为本轮失败的充分解释，也不据本轮倒推R15的早期引用属于哪个hold caller。

首组完整时钟dump LF1175/1176/1178仍为CMD_RCGR80000000、CFG_RCGR00100001、CBCR88000001，与R15相同。叶仍报off超时；UFS probe最终−5，PID1无法创建设备，11.365626秒panic为 `Attempted to kill init! exitcode=0x00007f00`。minidump于1.181854秒完整记录加载成功，旧CMA故障没有重现。结论仅为“先清AH8请求配置3c单独不足以解决当前UFS故障”，不能称该候选为修复。

设备自动恢复安装版BID931f、UUID `e45b96d2-2a7f-4669-b657-41c113b1a515`，已另行只读复核Android/root和watchdog disable0，见 `round16/recovery-readonly.json`。本轮原始数据在 `round16/`，UFS窄审在 `ufs-ah8-reset-review/round16-evidence.json`，CCF独立审阅在 `ufs-ah8-reset-independent-review/round16-evidence.json`，全轮绑定在 `ufs-ah8-reset-runner-review/round16-evidence.json`。下一步只读核对父SRC启用返回值、硬件自动门控、PHY/GDSC及BCR依赖，尚未应用下一项硬件干预。


## 三十四、第十七轮准备：通过既有RCG机制保留单一aux根的启用状态

实际GCC aux SRC使用 `clk_rcg2_ops`、safe_config和HW_CLK_CTRL_MODE；普通enable会在配置后撤销临时ROOT_EN，再依赖下游请求。实际provider的force helper超时可能只WARN后返回0，enable也没有传播其全部失败，因此R16的callback ret0不证明时钟实际on。原机制已有FORCE_ENABLE_RCG选项，启用它会在正常CCF enable期间保留force，原disable仍park到CXO并清force；configure失败或probe失败的原有限制必须保留记录，不能据此宣称所有失败都自动清理。只读研究在 `ufs-aux-force-review/evidence.json`。

PHY侧核实：GDSC、qref、refgen/vddaPHY、specific ON、vddaPLL、iface与ref链在aux之前；没有“GDSC必须等aux之后才开”的证据。qref原错误未传播、GDSC is_enabled返回软件缓存、specific OFF的void callback也可能仅记录关电失败，均不构成硬件供电已恢复的证明。保留原major6 BCR/PHY顺序，后续若需要另做只读采样，见 `ufs-ah8-reset-review/phy-power-retention-review.json`。

原样GCC基线已由官方455的18个未改输入构建，19条版本记录、4个函数全部执行段和file-backed运行时数据及规范化reloc与actual模块一致；BSS须按SHT_NOBITS的类型、大小、对齐与符号布局解释为零初始化区，不能把ELF文件片段当作BSS内存字节。基线报告为 `gcc-sun-vendor-baseline/validation.json`。新权威候选 `other_patch/kexec_ufs_aux_force_diag_6.6.89.patch` SHA `4863884ac5e9beaecfa74f731c2e02039127fa5f588a9476498bd9162897596d`，只在default-false/0400模块参数、chosen kexec标记和exact qcom,sun-gcc同时通过时，于原really_probe前给该一个SRC的flags OR既有FORCE_ENABLE_RCG，保留HW mode及其他所有定义，不新增手工MMIO操作。

候选经独立补丁窄审后，在新out副本严格fuzz0应用、单次编译成功，gcc-sun.ko SHA `3c14c06d7cc70e83d83c7e1b8d5dc31e6e73a444df688f08dad7d63d1942b6dc`、BID `31f9f5ffc5fa115726b0d42dbf87d94ae5188c2f`。本轮复用source842、target7cfb与R16 UFS9a9/原双参数，只新增GCC模块和 `options gcc_sun kexec_ufs_aux_force_diag=1`。新initrd其余546个原newc records逐字一致，gzip SHA `2c314f86082fb52d585b9f1cba5d9046e6cee3f9f98edc944def36108903a963`。以上为准备阶段，随后已完成最终ELF核验、绑定及单次实测，见下一节；仍不能称为已验证修复。


## 三十五、第十七轮实测：父根报告on，但aux叶门控仍off

最终新GCC模块的原19条CRC保留，新增4个正规GKI导入，共23条全部核验；10条匹配实际target7cfb，13条匹配实际clk-qcom导出。默认关闭/0400、四个拒绝守卫、唯一flags byte OR在really_probe前、原probe路径及其他时钟数据、10种布局均通过窄审；未重复构建或绕过Werror。最终runner validation SHA `3c7ab90db8873efdf72ada33b42edd18eebc96a0027700ccc17b85d27f7e79d0`，root闭环绑定SHA `5d481770c9ec6cde8af490a828ec50c02dcf4de4b14f5fab94e4d05db339eb36`。

source842临时启动后UUID为 `7d09f53b-304e-41f2-bba3-f128bf8c3668`，Android/root和695个原模块正常。nonce `0cc41bd073f1722e`，当前bootconfig刷新后的完整initrd18772372字节、SHA `57ea151c9e49238eb63ef703a2db2167421de283d07b8819b57e320a22008665`。实际DT1601295字节、SHA `8609e5197821d9d78f32c8438c5400f6df5b7b2cd1bdc520eafe3013d0bef6bb`；四TZ前三项同前，本轮display重新捕获为ed100000/80000，与R16不同。7927个control pages、126个普通memmap块、258次链后端读取、5个bookkeeping页、28个搬运链页、14175个目标页、76个关键Image页及完整GIC/TZ/双heap DT检查均通过。四项设备请求各1，没有重试。

原始pstore262132字节、2804个LF，SHA `4a1bc99eb11adab2a804b6430bac381a922bd06690da675cad855cd825dad5f5`。LF982完整init加载GCC的force参数；LF1031完整新marker显示old_rcg_flags2/new3/force_mask1/hw_ctl_kept1。GCC完整新BID未在日志中完整出现，不虚称观测到了；运行代码由实际载入initrd字节、原符号版本核验和新marker分别绑定。UFS双参数的args字串精确，但LF1009前缀损坏，未规范化。

LF1142/1144/1145/1217四条KH1完整；LF1143的KH2首次得到完整算术一致正记录：old183c、desired1800、readback1800、mask3c、full_match1，随后完整pre-BCR为AH8_CFG1800。post-BCR的HW_VERSION和其余四值仍0，post-PHY仍ret−16/is_phy_pwr_on0。原BCR/PHY/error流程没有绕过。

LF1155、1229、1305、1378、1450五组完整clock dump均为CMD_RCGR00000002、CFG_RCGR00100001、CBCR88000001。因此父RCG的ROOT_OFF bit31已清且ROOT_EN bit1保持，叶的软件enable bit0虽置位，CLK_OFF bit31仍为1，并各有status stuck off记录。此为硬件寄存器状态采样，未测实际电气频率。它正向排除“本轮仅是父根仍off”的解释，却未区分叶门控、复位、GDSC或PHY条件中的哪一项。

四条完整叶callback返回−16，另一次callback-return行损坏，原样保留；父计数2→1的回滚不撤销早期hold引用。首PHY/host/device-reset仍−16，后续HCE尝试也失败，LF2461–2463完整给出UFS probe−5。minidump在1.124079秒完整加载成功。分区等待有完整boot_a/super等列表，约11.29秒PID1终端记录的panic前缀有损，仅如实保留exitcode7f00片段；其后panic notifier链另有96000005 Oops，不能混为1.28秒UFS先发原因。

自动恢复安装版BID931f、UUID `b18bba87-6878-48a5-bb80-1ac8ed9294e2`，已只读复核Android/root/watchdog disable0，见 `round17/recovery-readonly.json`。原始数据与root聚合报告在 `round17/`，三个窄审分别在 `ufs-aux-force-review/round17-evidence.json`、`ufs-aux-force-independent-review/round17-evidence.json`、`ufs-aux-force-runner-review/round17-evidence.json`。下一项应取得下游门控/复位及PHY电源域的实际状态，连同qref原始返回值和GDSC缓存状态交叉核对；不把regulator软件enabled当作硬件已上电证明，也不盲改BCR/PHY顺序。


## 三十六、第十八轮实测：GDSC上电完成、qref返回0，但aux仍off

本轮只读观测补丁 `other_patch/kexec_ufs_phy_power_trace_diag_6.6.89.patch` SHA `41fac91334e9d356d89e9d21a93f85d3b20363cc6342fd583deffcabe83a72fc`，先保存再fuzz0应用到新的out副本。generic PHY原样基线与实物执行代码、42条版本记录和20项导出匹配；新模块为SHA `d629806cbe7fe65863534a45a6215c6b7b8d93eabb8bf78cadbe24b4f75a6507`、BID `1e1816bf13e6731ccc1481afee9fb9e61575ff58`。原42CRC、20导出和6种布局保持，新47条版本记录为46个目标GKI和1个实际GPL GDSC API。default-false/0400参数、chosen kexec、exact Sun PHY与major6共同守卫，原qref错误仍忽略，所有原错误返回和清理顺序保留。权威验证与独审分别在 `ufs-phy-power-trace/validation.json`、`ufs-phy-power-trace-independent-review/audit.json`。主验证中重复旧函数reloc审计未完成的host断言如实保留，原函数语义由已完成的独立窄审证明，未重编或绕过检查。

实际 `gdsc_debug_print_regs(struct regulator *)` 从已有consumer和regmap读取GDSCR/CFG/CFG2，不新建映射、不写电源/复位寄存器；调用在正常PHY上下文，分别位于原GDSC投票前、aux前和原aux返回后/清理前，每次原流程重试各采样一次。为满足该真实新导入，initrd只额外修改modules.dep中PHY的一行，增加GDSC及其原proxy/debug依赖；静态modules.load逐字不变，但有效依赖装载时机提前，不能宣称与R17完全相同。三模块加该一行共四个原record发生变更，其他544个原newc records逐字不变，新增唯一三行options。独立CPIO审阅与最终主机绑定分别在 `ufs-phy-power-root-review/repack-audit.json`、`final-binding-audit.json`（后者SHA `8fe6857cbe00adc6fbebd924cf858e9417dcd99210b16ab9669223f758a17aea`）。

source842临时启动正常，UUID `360c681a-a89d-4195-809a-f200ef1c24c1`，695个原模块/Android/root通过，watchdog disable0。nonce `975b4ca7d46f50a5`，当次bootconfig刷新后initrd18903560字节、SHA `acf83401b351ef71a76620abf0c5a0f4df38e45dce3dfb15ce703fe26db24620`。实际目标DT1601295字节、SHA `a7c50ddca50303f425f2056e940a0cdbb39c6904b5c607c1d42b77ed7535e7ca`；四TZ重新捕获为ecca0000/20000、eccc0000/21000、ecc8c000/3000、ed100000/80000。7927个control页、126个普通memmap块、258次保留链后端读取、5个bookkeeping页、28个搬运链页、14207个目标页、76个关键Image页、97个PTE采样和827次有界读取通过；实际GIC捕获等于DT、双heap隔离及四TZ no-map检查均通过。temporary boot/helper/load/execute均各1。

原始pstore262132字节、2736个LF，SHA `2f042153bca6b1bd143c6aa7c4db3b454e8b2d7ae58e6a1fe08d4f42413793cf`。LF966完整首次投票前为GDSCR02222801/CFG04088000/CFG2 0002022f；LF978/1054完整首次aux前/后为fa222800/04070000/0002022f。按实际驱动定义，PWR_ON31由0到1、SW_COLLAPSE0由1到0、UP_COMPLETE16由0到1、DOWN_COMPLETE15由1到0，RETAIN_FF11始终1。13条完整GDSC行、LF1383合并行的完整数字后缀分别记录；LF1460数值损坏，不解码或修补。它说明首次实际完成电源域上电，不证明模拟电压、时钟波形或隐藏的clamp/reset已正常。

首次GDSC helper的enabled缓存0→1/ret0，后四次GDSC、QREF、REFGEN为1→1缓存跳过；PHY与PLL失败清理后再由0→1。供电mask首轮0→1f→7。qref四条整行完整combined_ret0，第五条只有payload完整且前缀损坏；五条aux-after和power-on-return整行均为−16。LF970/1376/1377有损字段不补造。新PHY完整BID在五处实际power_on栈可见。

本轮父SRC每次都从count0实际执行callback并返回0，失败回滚也实际disable回0；与R17早期引用保留不同，但同样复现五组CMD00000002/CFG00100001/CBCR88000001，父根状态on、叶状态off。四个完整leaf callback返回−16，另一次callback行损坏；五个完整leaf-final均−16。LF958/959完整确认AH8 183c→1800和pre-BCR1800；post-BCR/post-PHY的部分行受损，不把它们重构为完整五值。KUFSAUX1的clock名字损坏但flags2→3/force1/hwctl1字段完整；GCC完整新BID未在raw中找到，不虚称观测到。

终端LF2506完整first-stage设备创建失败，LF2507完整PID1 panic为exitcode7f00，LF2735随后请求watchdog bite；不把该后续看门狗请求当作UFS的先发原因，也未修改看门狗。设备自动恢复安装版BID931f、UUID `dbb19b70-6b99-414f-8ca2-e36ed86e4630`，Android/root/watchdog0已另行只读复核，见 `round18/recovery-readonly.json`。

本轮结论是GDSC真实上电完成和qref返回0仍不足以恢复aux。后续区分PHY POWER_DOWN_CONTROL本地状态、独立的局部/host/BCR复位及叶门控，另核实根CFG硬件控制位的因果对照；不盲改复位先后、不把电源缓存当硬件状态。三份窄证据在 `ufs-phy-power-trace-review/round18-evidence.json`、`ufs-phy-power-review/round18-gdsc-evidence.json`、`ufs-phy-power-trace-independent-review/round18-evidence.json`；root聚合 `round18/review.json` SHA `06855202a5bc4d33472aaa83e2235f9dc055a7035e7dcd8cd816383de354ba29`。仓库kernel仍未修改，完整功能修复仍未完成。


## 三十七、第十九轮实测：根退出HW控制模式仍不足以恢复aux

从实际clk-qcom与官方455核实：`__clk_rcg2_configure`会先清CFG bit20，再仅按独立hw_clk_ctrl布尔或HW_CLK_CTRL_MODE flag恢复；actual AUX的hw_clk_ctrl初值0，FORCE和safe_config支持与软件控制组合。既有enable/disable/configure及其失败限制不变，不能把callback0当作根on或叶on。只读候选研究在 `ufs-phy-power-review/aux-software-control-candidate.json` SHA `10e45894011b365190f2072a4260fe2e4f035a0d9fe3b1c5a720acda07ff6782`。

新权威增量补丁 `other_patch/kexec_ufs_aux_swctrl_diag_6.6.89.patch` SHA `d71784675a1d25cd36f5fdf0e4407f7ef877c35dceb081c61f7acdd2ca8a5844`，依赖原force补丁，先保存后在新的out副本fuzz0重放两补丁。独立default-false/0400参数只在原force全部守卫、OR与KUFSAUX1日志之后生效，只清单一AUX SRC的HW_CLK_CTRL_MODE flag，并新增KUFSAUX2标记；不新增MMIO、时钟、复位或超时调用。GCC模块SHA `b852ed1d480bfe43bc9974c2c9b1bc5324a7d22ebf186ee9723289c57d54ba4b`、BID `71f3438ae65571fd62e21fbf2e545516ea55fbbd`，原23条CRC逐字保留、没有新导入、10种布局及其他时钟数据保持；原流程/指针语义独立窄审通过。

本轮复用R18 UFS9a9、PHYd629、GDSC新依赖行、source842与target7cfb，只换GCC并在gcc_sun的force选项后追加 `kexec_ufs_aux_swctrl_diag=1`。实际CPIO独审仍为544个其他原record逐字不变，三模块和唯一依赖行精确，options唯一。17个host脚本AST及新增参数/实物绑定通过，没有重跑未变化的13个纯DT/BTF用例，旧报告单独引用。最终runner SHA `1607c37a7e07bd3af4920f2d9cbb684f630cb8ba2e463c572b236edf2644353a`；root最终绑定SHA `19e9674ce4ca22f0b8ebc529ef7e71ef91ff5b03de05b3d9bf6fe2b8ebe20d5b`。

source842临时启动正常，UUID `c60882e9-d8cf-496d-9f92-5b13e4fa8e9a`、695个原模块，Android/root及watchdog disable0通过。nonce `b33ca89166fc34ef`，当次bootconfig刷新后initrd18903992字节、SHA `fc3a926f5fd864426ae3c9265045e94388b01fcd977a1f6c1825bba66eb25374`。实际DT1601295字节、SHA `60edf88bd300c32b5e7536e12258d049976f229c1512129a6013776bdddcdc1d`；四TZ重新捕获的PA/size与R18相同，没有直接沿用。7927个control页、126个memmap块、258次链读取、5个bookkeeping页、28个搬运链页、14207个目标页、76个关键Image页、97个PTE采样和827次有界读取通过；实际GIC/双heap/四TZ检查通过。temporary boot/helper/load/execute均各1，无设备重试。

原始pstore262132字节、2717个LF，SHA `85355340d89b087d51fced0b0fddaac3d5f571064faebbc12eb67bd85e086729`。KUFSAUX2在LF860可见，但flags_before字节为13，flags_after/force_kept/hw_ctrl键也损坏，不能修成完整flags3→1记录。首组LF991把0x写成0X，LF992为CFG_RCGV:0h00000001，整组单列损坏。后四组LF1093/1197/1298/1399的完整具名CFG均00000001，同组CMD00000002/CBCR88000001完整：CFG20确已清、ROOT_EN1/ROOT_OFF0，叶enable1/HWCG0/CLK_OFF1。该硬件读回正向确立软件模式对照，不依赖有损flags日志。

首次GDSC的三条完整LF968/980/1056仍从02222801/04088000变为fa222800/04070000并保持，电源域由OFF/DOWN到ON/UP。qref前三条整行完整combined_ret0，后两条分别有ignored键或prefix损坏，不能称五条整行通过；aux-after三条整行−16，另两条字段名受损但返回尾部完整。完整SRC callback0四条、leaf callback−16三条、leaf-final−16四条，其余坏行保留，不以缺少完整skip行证明未执行。LF959–962四条AH8记录完整，clear/pre-BCR1800。PHY完整BID四处可见，GCC完整新BID在raw中未见，仅如实保留loaded marker、实际payload和CFG读回的独立绑定。

终端LF2491完整首阶段设备创建失败；LF2492的panic内容与exitcode7f00完整但时间戳损坏，不称整行完整；LF2716随后watchdog bite请求完整。自动恢复安装版BID931f、UUID `0c81463d-b87a-4fd7-858c-29c0a35985f8`，Android/root/watchdog0已独立只读复核，见 `round19/recovery-readonly.json`。未刷分区、未改看门狗、仓库kernel仍未修改。

本轮说明保留FORCE并退出根HW控制模式仍不足以恢复辅助叶时钟，完整Android仍未启动。三份窄证据为 `ufs-aux-swctrl-review/round19-evidence.json`、`round19-phy-evidence.json`、`ufs-aux-swctrl-independent-review/round19-evidence.json`，root聚合 `round19/review.json` SHA `45dda464ff3a835b16554a92ecec77151e7c2833d253506ae232caaa62a8710c`。随后按 `ufs-aux-swctrl-review/round20-local-read-plan.json` 完成第二十轮：在generic PHY原power_control(true)返回后及原aux前，读取已有映射的+404 POWER_DOWN_CONTROL和+408本地SW_RESET；区分它们与host CFG1 bit1的PHY reset及GCC BCR，不改变复位/供电顺序。实测见下一节。


## 三十八、第二十轮实测：PHY电源控制写1后读0，仍需正常启动对照

权威增量补丁 `other_patch/kexec_ufs_phy_local_read_diag_6.6.89.patch` SHA `90f59d038dcc0a2a0d5e50cb32f2d1f594743c72b14ad8138dbfa3242b9d7375`，依赖R18电源追踪补丁。新增独立default-false/0400参数，还要求原kexec/Sun/major6守卫和有效原PHY映射；只在原power_control(true)返回后和原aux调用前，顺序读取+404、+408并记录进入/结果，不新增硬件写入、复位、时钟、延迟或重试。先补丁、后新out副本fuzz0应用，单次正常构建成功；模块SHA `1061487cf69090ec2fdd2ca91950d61030a230360b891b14d886ed5d23c5d96b`、BID `e29ae60436e8e2bd860d89a6ec6693fcaf3f08f3`，47条CRC与R18逐字相同，20导出、6种布局及原错误/清理路径保持。主验证SHA `2c5c6749c5440b5870a51c6241c23e0c889fe25801b77d47fa6d4545903024d4`，独立ELF窄审SHA `742750810b85fb506703a17f4d86199baf07ded8bc073b625c841ac65a86ead8`。

source842、target7cfb、UFS9a9和GCCb852均未变，只换generic PHY并增加显式local-read参数。CPIO其余544个原record逐字相同；最终runner SHA `d5d7f8579ddb37e3db7af0708e43022d1f80baeb34d88b024a70352fd150f68d`，root绑定SHA `101725ceadf860c638326f120e6518976346ccbeac16c930e69f2ceaf34d273e`。临时源UUID `0edb7818-b0dc-4aea-a7f0-83fb684793c9`，Android/root/695模块正常；nonce `1d32bf8cdb0f8491`。刷新当次bootconfig后的initrd18906408字节、SHA `9c30751eece750f6be45eb92e081b8deebb4f38d3c04e1e6a97c88ce013957ca`。实际目标DT SHA `db943911e385dae4cc6385b5d42b5e4ff56c398e648bffe328247e480224e319`；完整搬运页、GIC、双heap及四TZ保留检查通过。另对实际loaded DT复核PHY原命名资源PA1d80000/size2000及soc恒等映射，两次32位读取均在已有范围内，报告SHA `9345df192506a26bc44c1f1320d15b96255eb59551c20cd5bb2a7999f5d7a54d`。这只确认范围和正常上下文，不保证MMIO永不异常。

temporary boot/helper/load/execute各1。原始pstore262132字节、2723个LF，SHA `2ec5a2362b57f3fa0fc79f1c09bde30c82938b7a51d46ab4c5d36a18602bdd60`。五条完整post-power-control结果LF969/1072/1177/1278/1377全部为POWER_DOWN_CONTROL=00000000、SW_RESET=00000000；aux前完整LF979/1186同为0/0。另外三条aux结果含坏键、坏值或坏前缀，未补造或升格为完整结果。实际Sun原回调在.text+654写404=1、+658执行DSB，因此立即读回0偏离软件写入意图；但原代码没有保证BCR保持期间该寄存器可锁存，不能据此宣布复位顺序错误。

首次完整GDSC words在LF963为OFF/DOWN，LF977/1053为ON/UP；原首次phase/consumer/cache有损字段另列。四条完整CMD为2、五条CFG为1、四条CBCR为88000001，其他坏行未修复。完整新PHY BID执行记录有四条，原始console未见完整nonce；实际loaded DT的bootargs已独立逐字核验nonce与expected append一致。aux仍返回−16，目标仍未完成Android启动，终端可见分区挂载失败和init退出panic；本轮panic退出码和watchdog文本受损，未套用前轮的完整7f00/请求文本。

原major>=6代码明确按BCR assert→完整PHY power_on→仅成功后deassert执行；power_on错误跳出会保留BCR断言。因此当前证据不支持提前解除BCR或清本地SW_RESET。Sun原power_on不写+408，后续calibrate才执行1→校准表→0；aux失败时还未进入calibrate，不能期待此时必须为0或把0称为目标主动释放复位的证明。CBCR bit27在已核厂商定义中未知，实际halt判定只检查31和30:28，不能臆称bit27是reset。

设备已自动回安装版BID931f、UUID `f954f6df-97e0-43e9-a484-e73c6bfc1ea2`，重新只读核实Android/root/watchdog disable0。PHY窄证据为 `round20/phy-local-read-evidence.json`（SHA `f6270573a787bd9bdd9a0d84b535508c5d6b4c8ef9cd6118f4ec2f47f7fa519e`），独立raw审阅为 `ufs-phy-local-read-independent-review/round20-evidence.json`（SHA `2f410714056edd4bd1605498fb0b72548d7d74c78918afc21b74a5d6a3f48337`），root聚合 `round20/review.json`（SHA `b634dd8504f8bcda027557d53790db8a933e92a600c43744c7f0b34c2c1d36c1`）。第二十一轮随后尝试显式守卫的正常启动只读对照，保留原stock UFS/GCC和BCR时序，但新模块未被实际采用；没有取得有效的正常启动寄存器对照，详见下一节。


## 三十九、第二十一轮：临时内核正常启动，附带PHY观察ramdisk未生效

为区分BCR正常保持期间的零值与热交接独有状态，先保存增量补丁 `other_patch/kexec_ufs_phy_cold_reference_diag_6.6.89.patch`（SHA `62f672f779afef155ece354f84a1383ad7fae5ad28b26b1d848fad4a556ace50`），再在新out副本依序fuzz0应用三层PHY补丁。原kexec谓词先行且保持独立；新增默认false/0400的cold-reference参数只有在原powertrace/localread均启用、chosen存在而无kexec标记、exact Sun且major6时，才启用同一只读观察，并输出UFSPWR3。未新增硬件操作或改变原时序。模块SHA `3f198ed8a1601d11179df7077257113a9fc0cb86c4c53d86a65d8cb588f4a27c`、BID `b339da8a76fe1530b7e104e082e7f1218d78373a`；47CRC、20导出和6布局保持。主验证SHA `66b4db60be2956b7f3384c23476a3fc1ea93b3826a2a6b9cbaf60dc837d2b692`，独立守卫窄审SHA `35cf645d817fb76fe12b90e79c4b8d348ec00d243717b362313c396cf0a045a2`。

正常启动包保留source842原Image，只改v4头ramdisk_size并追加gzip；boot SHA `3fc55345f67bab4de66ad71bdcbb42b574a14a864d19965c2ba328b560f1c3d7`，55144448字节。载荷只换generic PHY、修改原modules.dep单行，并新增唯一一行PHY三参数，原stock UFS/GCC保持，其他546个原CPIO record逐字不变。实际boot/header/CPIO由封装者和root分别检查。闭源启动器如何选择fastboot临时ramdisk与已安装init_boot无法在本地主机源码中证明，运行前已明确把新PHY BID、三参数Y、UFSPWR3和正常Android作为对照成立条件，未仅凭封装通过认定会生效。

单次fastboot boot返回成功，Android正常完成，运行内核确为842，UUID `d8eaa728-6b0e-4b94-a82e-caf447e2f3ab`。但实际generic PHY仍为原厂BID `da0d45e45f727c03861320cf4132255b22a0cf5c`，三新参数全ABSENT，live dmesg无UFSPWR3。UFS/GCC分别仍为stock `a0f190cdb34943457dc4f4642b720838e77acda3` / `fd0294bddc6fc79a28a1a6826e5328eee01567cb`。R20正常源与本轮实际FDT的linux,initrd-start/end完全一致，均为3065507840..3087003868。结论是临时Image被采用，而附带ramdisk没有实现预期模块替换；具体启动器选择机制未确认，不能虚称观察到正常PHY零值或宣称冷对照通过。

本轮temporary boot1、helper/load/execute均0；随后正常adb reboot1次回安装版BID931f、UUID `5ea13afb-0e5f-4019-b064-ad2a3bd10765`，Android/root/watchdog disable0再次核实。正式state SHA `dfbbcc07aa1f894bffd231746a2ba91dff5e7f1908562ec3dbb7d7531ffa100a`，恢复记录SHA `cd84ba5e67533a792b9f4458c6866b37127c18987854486660be449c72e61516`。封装运行审阅在 `ufs-phy-cold-reference-boot/runner-review/round21-runtime-report.json`（SHA `9d7ad66e9d5d1ba8f618f7b7f8012aacc1a89de5b6219fb7e2fc22d019759466`），root聚合 `round21/review.json`（SHA `fa3cb6f95c40bff1062c6bacad9d8cf3e759b7e55add2b384e8b92805b1fa175`）。未刷任何分区，未改变看门狗，仓库kernel仍未修改。

不重复同一ramdisk方案，也没有证据支持仅降v3头就能改变本机启动器取舍。现有842支持早期kprobe_event及等待模块符号，但通用nofault memory fetch会把访问错误置零且丢失错误码，不能把其零值当作与readl_relaxed同等级的正常MMIO回读。随后改用单独默认关闭的内建观察器，在原power-control后、aux前后只读采样，保留原模块、BCR/PHY顺序及硬件操作；有效实测见第四十节。


## 四十、第二十二轮实测：正常启动同样读0，aux却成功

权威补丁 `other_patch/kexec_ufs_phy_cold_builtin_diag_6.6.89.patch` SHA `a2b60282c247d3962add71e2b6b2ab8a4b5813f85eb72553d84133e4546f51e3`，先保存后在source842的新out副本fuzz0应用。只增加独立内建观察器及Makefile条目；默认关闭，须显式 `kexec_diag.ufs_cold_probe=1` 且chosen不含kexec标记。观察器只接受原厂generic PHY精确BID `da0d45e45f727c03861320cf4132255b22a0cf5c`、原函数四处精确指令、Sun/major6和原命名PHY资源。只在原power-control后和aux前使用已有映射顺序readl_relaxed读取+404/+408，aux后记录原返回值；不新增硬件写入、时钟/电源/复位操作、延迟或重试，也不修改原寄存器上下文。

同一任务、栈帧、PHY/mmio/aux对象和首代调用关联均须成立；若首代观察失败，不能用后续重试或PM调用冒充。模块退出时同步撤销观察点。最终补丁先后经过窄源码和实际ELF审阅，目标对象SHA `6cfd9ea0039c2875bdce713084316c915e9cce9a09e4f7c9e926c345e7a83d07`。新内核BID `f29c7de230e4cb44d0192b4fc0d9eaa0a427ceef`，Image SHA `3fda00c548f810ff273699f72c24480d4f9a1af0cba0fef955d26f5305e46445`；最终临时boot SHA `40bf9f9505699894a2220c08815fc746eae85dabebebd9a4d42d3ecfca42c32d`，v4头、ramdisk0。source842的16307条导出CRC、14种布局及五个关键原对象的执行段/重定位均保持；主manifest SHA `f94f11464a17af5c2706320b7ee881a0ba92f0331235f72aaf3f5e6376677a9c`。

单次fastboot boot成功，运行UUID `d4a82171-28f6-4fb3-812d-6bfb3ea3388e`，实际内核确为f29c；PHY/UFS/GCC仍为原厂da0d/a0f190cdb34943457dc4f4642b720838e77acda3/fd0294bddc6fc79a28a1a6826e5328eee01567cb，显式参数唯一。实际FDT SHA `14c0a04bdc2714969f1722883ffe50e9cd7f9cdd9bfa865d41b3ce538f3672c4`，chosen无kexec标记，PHY资源、compatible/status及父cell数与R20正常源和实际loaded target逐字一致，仍为PA1d80000/size2000。

本轮主证据是完整live dmesg，而非旧pstore：1773882字节、18513个LF，SHA `f6f3fd7e9fad59f3e12a1010d098f6990a59797fcc0703909594dd9d6ed594b7`。七条KUFSCOLD1均完整：LF304 notifier-ready0；LF1321匹配原厂PHY并安装四点；LF2278/2279为首代post-power-control进入/结果；LF2280/2281为同代aux-before进入/结果；LF2282为关联的原aux返回0。两条结果的POWER_DOWN_CONTROL和SW_RESET均为00000000，未出现关联取消。随后LF2288建立MCQ九队列，LF2290/2296枚举存储，LF17779及后续记录Android启动完成。

| 同一语义采样点/结果 | R20 kexec目标 | R22正常bootloader启动 |
|---|---|---|
| 原power-control后PDC/SW_RESET | 完整采样0/0 | 首代完整采样0/0 |
| 原aux前PDC/SW_RESET | 完整采样0/0 | 同代完整采样0/0 |
| aux与后续存储 | leaf实际callback −16，UFS失败 | aux原返回0，UFS及Android成功 |

因此“写1后读0”不能单独解释kexec失败，也不支持盲目改变复位先后。静态原调用链支持初次device_reset的major6 BCR assert→power_on路径：此前setup_clocks因host尚未初始化而跳过，vendor init/phy_init本身不执行power_on。但本轮未采BCR返回/状态或调用栈，不能把这项源码推断写成硬件实测；本轮也未做电气断电，不能称为断电冷启动。正常原厂路径与R20多层诊断路径不是单变量对照，仍不能据此锁定唯一固件、复位或时钟根因。

下一最小问题是正常aux返回0时，CCF究竟从count0调用leaf enable，还是因已有引用而跳过；配合同点的叶CBCR及qref提供者状态，才能判断热交接缺少什么条件。SRC ROOT_EN/ROOT_OFF、qref原调用返回0和enable缓存都不测量真实振荡频率。继续保持原复位顺序。

本轮temporary boot1、helper/load/execute0，正常adb reboot1次回安装版BID931f、UUID `fad50338-5d3c-4aa7-9214-c2fb58ee47cb`。Android/root正常、watchdog disable0并在恢复采样前后核对同一UUID；state SHA `ce90b8c61f905909dce7ab00a428841d15bd23fdc9b4527c645f1aa279089ae6`，恢复SHA `5874c89d7f83dd1fe3c82e7c00a5025c6fa4991aac8bc2221982e3adcbc709c3`。独立raw证据SHA `a31dd9c17e19ac831084aeb23d3fa0524d13a9b92029c9357ae7f4b591625dbe`，资源/身份运行绑定SHA `28f1fa501aa02e7599080941cda713617646a0e5a347cae7790e535ab72910d6`，root聚合 `round22/review.json` SHA `938ef517f906e5694d2b2313786ee0559246727375f15e4975a07185a2aa5914`。未刷分区、未改看门狗、仓库kernel未修改；本轮正常启动成功不等于kexec已修复，完整目标仍未实现。


## 四十一、第二十三轮实测：正常aux在首次PHY上电前已有enable窗口

本轮不改C、不重新编译，保留R22冻结的f29c Image、内建观察器及原厂PHY/UFS/GCC模块，只在临时boot头cmdline增加既有四种clk enable/disable事件。使用独立 `ufscold` instance，同时留global缓冲作额外记录，2MiB/CPU。最终boot SHA `01335cad2f1d2d6a936013621a879c9ed7830409279745b5e266fab9f479ad94`；Image和cmdline以外所有字节与R22相同。最终host绑定SHA `e551c26626414e2a3c5709cd05ea95757ca6d94187537e58685e5139bc095bbd`，独立包/脚本窄审SHA `895179f2262ea6326cdb4f61253205efb3e9c97bedc344c56464ef2a1c07a638`。此前仅instance候选未实测，归档后只运行最终版一次。

临时UUID `653bf0ad-4b4f-46e8-9b6f-4a612da02732`，f29c及da0d/a0f/fd02身份正确，首代七条KUFSCOLD1完整，两处PDC/SW_RESET仍0/0，aux原返回0，Android完成。live dmesg SHA `91f2fdce86b4d709bd169629c34c5428dd2305d776083dbaac9c659320188aec`。

专用trace SHA `f2f10dfecd1bf09a46c4065b7a665e99fcb0b1dcacbe69bf0e6bf8b5741fa0f2`，实际clock为local、3082/3082条；8CPU的overrun/commit overrun/dropped/read events均0，四个事件均启用。LF13/14在CPU1、init PID234记录qref enable/complete。LF91–94在CPU6、kworker/u17:2 PID135记录AUX SRC的0.800277/0.800285秒enable/complete，以及leaf的0.800286/0.800289秒enable/complete。GCC Registered日志在0.800791秒，首次PHY post-power-control在0.832982秒，aux-before/原返回0在0.833000..003秒。即已正向捕获首次PHY采样之前的leaf零计数使能窗口，不只是“后来没有报错”。

global SHA `9bcc55c43f214559e2ceebe35d91d992dcca534a19cbe20c33c68df007958c05`，实际mono、460/460条，同样保存六条目标事件，但在采集前已被停止、仅覆盖至2.116049秒，不能冒充全程trace。`trace_clock=mono`只设置global，instance仍local；printk/local在当前配置下使用sched_clock族，但不宣称跨CPU严格同步，更不能把global mono与dmesg数值直接相减当作精确延时。两个缓冲仅停止tracing以取得静态采集，不写clock/reset/power状态。

原CCF只有enable_count为0才发出enable/complete窗口；count已有引用时递增后返回0。注册时的 `clk_core_hold_state` 可保留boot_enabled时钟，而GCC的sync_state晚至3.640144秒。这与R23早期窗口及后续aux返回0高度吻合，支持正常路径沿用既有引用；但未采调用栈、boot_enabled/need_sync或现场count，不能认定唯一holder。`enable_complete`无返回值，且在错误判断前输出，不能自身证明callback成功或硬件on；完整trace内未见后续同名disable，也不单独当作skip的直接证明。静态shutdown核查另表明，源UFS确有关闭PHY/AUX/qref的条件路径，但返回值、host/PHY/CCF引用状态都会影响是否真正执行，不能仅凭shutdown完成断言硬件一定关闭或一定保留。

随后选择仅对目标单aux叶显式取消halt等待的最小诊断，保持原复位顺序，不继续逐层跳过PCS/link检查；实测见第四十二节。它也改变disable等待和成功计数语义，ret0不能作为成功条件，也不是最终修复。qref原callback采用HALT_DELAY，返回0不测频；实际 `clk_measure` 读接口会写debug mux/计数器，不能误称纯只读测频，见 `ufs-qref-clock-review/next-plan.json`。

本轮temporary boot1、helper/load/execute0，随后adb reboot1回安装版BID931f、UUID `3a0677ca-2320-4c61-ad45-917a945a90d8`；Android/root/watchdog0及恢复采样前后同UUID核实通过。最终state SHA `660ff7d9c2922c435f00ce309e239917e8c509a63a85cc0e8eee4116a2dacccc`，恢复SHA `337084d885264af20b9abd6492927bb7720dc91206a7925155b493be745c4803`。独立runtime报告 `ufs-cold-clock-reference-independent-review/round23-evidence.json` SHA `ef655e3bd497f952ca113d46a9c75dc8feac1d501a21c6367483f22e5ffa5c72`；root聚合 `round23/review.json` SHA `843ad2e61682d6ecee4c9824515fbc3fa2f56af15c02317680be53aebd1a1c56`。未刷分区、未改看门狗、仓库kernel未修改；完整kexec Android修复仍未完成。


## 四十二、第二十四轮实测：越过AUX返回−16，BCR释放后出现SEA

权威增量补丁 `other_patch/kexec_ufs_aux_halt_skip_diag_6.6.89.patch` SHA `37337b0ec580c1721433b2e364f7f81ff3df87374fbf14a5854c55f45d148189`，先保存后在新out副本fuzz0应用。新增默认false/0400参数，只在原force/kexec/Sun和已启用SWCTRL的完整守卫、KUFSAUX1/2之后，将单叶halt_check从BRANCH_HALT_VOTED精确赋BRANCH_HALT_SKIP=3。原enable/disable寄存器写入及MMIO错误返回保持，但取消了halt/HWCG状态检查、超时dump和原voted-disable延时；不能称为只删enable poll，更不能当作生产修复。未新增硬件访问、clock/reset调用或重试。

单次正常构建成功，GCC模块SHA `4fe792af469facc52b3d4e63041fbe72b10fcfb1def85e5355b792db887dcd0b`、BID `c3e465dfcaa69f6e05441aa1409c10e3ea20a9b7`，377376字节。23CRC与R20逐字相同、无新导入，10种布局和静态clock数据保持；独立ELF核实六项守卫支配唯一leaf字段写3，K1→K2→K3→原clock注册与原probe错误流保持。主验证SHA `9d1466f4225e6a78a597ada8681f586daa9a92869f76dcebe85db6064a421e0c`，独立窄审SHA `69475512d05a60091ce3496567c64ffef50083f5ddc5ee9ba4581dfd45c81543`。

source842、target7cfb、UFS9a9、PHY106及所有保留诊断与R20保持，仅换GCC并追加唯一halt-skip选项。实际两段CPIO由冻结R16 parser独立核实，其他544条原record逐字相同；payload SHA `e75c9b029252460b33dc8bfc45ccf2dd645fa77c5202ce47d197ffd547e711f7`。临时源UUID `01126976-410f-448e-bd5d-0f599e094088`、695原模块、Android/root正常；nonce `05160cb2b82875bc`。实际bootconfig刷新后的initrd18906392字节、SHA `5387d934444dd3d498be5ea1d72bb714c88ab6789a1c221f90be3bff3995ee31`，loaded DT SHA `eff7f3b34441cbfcd001517057f8e88cbda861c665730c474b2ec43ec3c41a78`。完整搬运页、控制metadata、76个关键Image页、GIC、双SP堆、四TZ保留与PHY命名资源范围检查均通过；host最终绑定SHA `723bc3ba418faecc4f64cdfc712ee8221bcf95df19e046bae40e81b97b0297b1`。

temporary boot/helper/load/execute严格各1。主证据为target原始pstore：211045字节、2295个LF，SHA `3fd849fec08f76c95b780c109d8976d5603985e133e001379109054eb2ca7faf`。完整LF2148明确KUFSAUX3 old_halt_check128/new3；LF2279–2281为leaf真实callback与最终返回0、count1；LF2288为原PHY power-on-return0；LF2290为原post-bcr-deassert0，is_phy_pwr_on1、CFG1=1c00052c、HW_VERSION=60010000、AH8=1800。因此本轮确实跨过旧的软件−16返回点及原BCR释放路径。LF2282的aux-after键、LF2289的时间戳/device前缀损坏，未修补为完整行。新GCC完整BID未见于保存raw，以唯一新marker的实际执行、显式参数和实际loaded payload绑定为正证，不把恢复后的stock模块身份冒充target。

随后LF2294在1.828530秒完整记录 `Internal error: synchronous external abort: 0000000096000010`，LF2295仅记录skipmd ftrace提示，文件在此结束。此次异常的PC/FAR/栈没有保存；更早proc/SPMI WARN中的PC不能拿来填补它。未取得PCS/link/MCQ/LUN或目标Android完成的正证。原common流程在device_reset返回后还先执行init_crypto，再进入HCE/PHY校准，因此不能仅凭时序将本次归到PCS或某个MMIO地址。HALT_SKIP本就掩盖ready失败，不证明物理AUX已on；后续SEA可能仍来自同一硬件条件，不能宣布已发现第二个独立原因。

设备自动回安装版BID931f、UUID `2236796a-1f91-4b9d-9646-060bda2e763f`，Android/root/watchdog0及恢复检查前后同UUID通过，无额外重启。最终state SHA `233e0ee85866f83262d0a40be1ab068c6c065e14b84e7d903d3a2dc902e52312`，恢复SHA `beacc074ec2adaeb092c221be5f0ee43a742c61d585fb0498a79b4be2cdebafc`；恢复live dmesg SHA `4cda6cd3d215d9925494d993cb429d5429b4a48c3d49eac9418463be4727b46f`明确不是target日志。两份窄证据SHA `e8fbc2aeafd30982da472d44b46fd4383b7bca17af9c08b675d42c3a0197dbf7` / `3412d3e93e55b2df646285fd2acea3465074eee746438cd98e957418f2a20e52`，root聚合 `round24/review.json` SHA `5cd853af309937fb007adaee47ecf7d9b91056a14cf61891d6662e1774ebbfd9`。未刷分区、未改看门狗、仓库kernel仍未修改。

随后在原do_sea首个厂商hook之前补首次匹配SEA上下文，不依赖更后的die notifier/show_regs一定保存。第二十五轮构建与实际结果见下一节；没有盲目改变硬件时序。


## 四十三、第二十五轮实测：存储已枚举，bootstrap-apexd失败后正常重启

权威补丁 `other_patch/kexec_sea_context_diag_6.6.89.patch` SHA `dd88c84b4bc09ce1023ded256c63c3fc173b0224c899aa6b12aa43d3406165ec`，仅改fault.c。要求唯一显式参数及booted-from-kexec标记，缓存默认关闭的开关，只在首次匹配kernel current-EL data SEA/FSC10时，在原首个厂商hook前输出raw ESR/FAR/FnV/PC/LR/SP/PSTATE、符号和保存寄存器。所有观察均只读，不读取故障地址/指令，不改原fixup、hook、notifier或返回；首次匹配事件不预先认定为fatal。

补丁先保存、后在独立out副本应用。首次构建因新增of.h导致一项genksyms CRC变化，未测试该产物；仅对新include增加__GENKSYMS__屏蔽后正常重建，真实C原型不变，16306条原CRC与19种布局全部保持。最终BID `146835a59b80c2c467222aa7c28892c00044a135`，Image SHA `a4f76d9d4ece98fa6526f446995b5e5909d0e722addf969d783af77898a93b43`。独立ELF审阅SHA `49f8f69954dcfe5d2459efbad0c6fc0c5bd95b6a331d98536e0298d193828be1`；实际console地址和88个关键Image页已重新计算。

source842、helper、三个R24模块和CPIO payload均保持。临时源UUID `aa4e24d2-4fe7-42c4-a1e4-0bcc8a8d3dc1`，695原模块、Android/root正常；nonce `ec670bd5f4eed0cb`。initrd18906392字节、SHA `5387d934444dd3d498be5ea1d72bb714c88ab6789a1c221f90be3bff3995ee31`。实际loaded DT SHA `dc6ac8a0cb461e02df6fb6414e1156f3643251aab0fa0c33e51ff1844b381fec`；搬运页、控制metadata、88个关键页、GIC、双SP堆和四TZ保留检查通过。独立PHY资源范围报告SHA `4656d60048c3d86aa490e3389656f6892df8ffd0994093c53a77ff924324bfe7`，root主机绑定SHA `f608b84a86f747442835b4db37927d1d2b16e1e46a010a0623cab3c0ebb1dce6`。

temporary boot/helper/load/execute各1。目标raw pstore恰为262132字节、3478个LF，SHA `d5db551c4c9f242dbffde712efb7f60f3f7690b09e95c8611416334a38a2f378`。满环首行是约2.117秒的截断行，早期内容已覆盖；所有行号按原始LF划分，坏字不修补。完整LF784/791/798/805/811/817分别有sdf到sda的SCSI cache同步，另有大量真实分区和dm35到dm0的device_shutdown记录。因此目标已注册六个SCSI磁盘和dm设备，不能继续概括为UFS完全未枚举；它们也不能替代首次PCS/link返回或特定分区挂载成功的日志。

完整LF511在11.881341秒由PID1记录 `reason: reboot,bootloader,bootstrap-apexd-failed`，后续进入正常shutdown/CPU stopping。LF495–505的misc by-name stat失败发生于处理重启请求时，是保留下来的后续错误，不能据此断言它触发apexd-bootstrap失败。尚未保存该服务的首条start/exit错误，不能确定是启动失败、非零退出还是信号；没有保存KSEA/SEA记录也不能反证早期没有异常。后段PDC读1/SW_RESET0来自不同代power-on调用，不能冒充对R24首次0/0的单点修复。

设备自动恢复安装版BID931f、UUID `5c4942b3-d45d-4e8c-a32c-43e24dddb77d`，Android/root/watchdog0及恢复采样前后同UUID通过，无额外重启。state SHA `189fd0943413788ba5d7cdab458ae06c7348dffda1ade71b2f54966d2b964620`，恢复SHA `c621a24debd78130ac8123d0fb052cb7214df076f1c1da044c07e770f89f3761`。恢复后的live dmesg SHA `a1e77a17b3154751b40be22d2d7b1fffde0fc16f96e813b7bd4ed55710fdec53`不是目标日志。root聚合 `round25/review.json` SHA `97970255e33e56f7753e59d996d87794294601029ecae15216d11effcc47c40f`；独立raw报告SHA `e49de45555f6a4c5879b923c91ec86d89ca7f21c6f2afcf8163ecef713897220`，后续路径报告SHA `a12de13dc6c0deac2b2bd0535972bd262dd7e7e61fab9c11114b600dfc6fd123`。

满环中2671条literal `KT: dev`占174557字节，来自主补丁在device_shutdown中的无条件EMERG打印；没有定向参数，降低loglevel也不能只去除它而保留同等级SEA记录。第二十六轮只用独立补丁删除这一条调试输出，保留原callback/锁/PM/硬件流程，不扩大ramoops、不改源842或模块payload。该项仅减少已知覆盖源，256KiB仍不能保证永不覆盖。完整目标及SP/TZ生产交接修复仍未完成，未刷分区、未改看门狗、仓库kernel仍未修改。


## 四十四、第二十六轮实测：第二阶段init成功，apexd-bootstrap被signal4终止

权威增量 `other_patch/kexec_shutdown_log_quiet_diag_6.6.89.patch` SHA `2cacafea0871231d02fd096968e7af68eabb1416d331fa5e999c1d64ec1cb6c8`，仅删除core.c一条无条件KT逐设备打印，先补丁后在新out副本应用。正常构建0，16306CRC、19种布局及原关键对象保持；独立实际ELF窄审确认原锁/PM/回调/引用/循环语义不变。新BID `87bae5a7d32c6d0a3103c2c067a52fc1b2d02138`，Image SHA `fc2d900c18f501e4cdb9e6498417cdae232b1be36e95c5c7adf8520adcfb13b9`，独立审阅SHA `9f9e316e8035d3beea7a09871477d7cfa89b62bab8df8d0cfd572f0a54e544ef`。源842、helper、三个模块及payload均保持。

临时源UUID `c05e083e-8db6-49d3-a3f7-a5fa2c1627c0`、695原模块及Android/root正常；nonce `65294cb39f7574d2`。实际loaded DT SHA `b4c801675ece36bf94f48e0b112c4ac6bdd5dd0ecfd240846d4da28929cbb658`，89个关键页、完整搬运页、GIC、双SP/四TZ、PHY范围均通过。temporary boot/helper/load/execute各1，无额外重启。原始target pstore为262132字节、2506个LF，SHA `fa7d5e9351c57c7fac6e45557598eed215a04685474579c7bc4ff4c4a22ad591`；虽仍满环，但头已提前至约1.19秒，literal KT dev为0。没有保存更早KSEA，不据此否定早期异常。

完整记录确认SCSI设备注册/attach、LF664 F2FS(sda10)、LF700 EROFS(dm19)、LF709/726 EXT4(sdf3)及后续dm挂载；LF980在1.630136秒明确`init second stage started!`。MCQ行LF579有坏字，不把具体队列字段补成完整记录。LF1694/1695明确启动apexd-bootstrap PID354，LF1724完整记录在1.763344秒收到signal4、等待0.053秒，LF1727明确reboot_on_failure触发关机。它把直接退出原因从泛化bootstrap失败缩到服务实际启动后的SIGILL，但未提供该PID的故障PC、指令、si_code或ESR。尾部CPU-stop用户PC属于ueventd等其他任务，不能当作PID354故障位置；SIGILL也可能由软件发送，不能凭信号号认定处理器特性、BTI/PAC或非法指令根因。

设备自动回安装版BID931f、UUID `71c25a8c-d7d7-4158-b710-c9e72f6605f8`，Android/root/watchdog0及前后同UUID核实通过，恢复SHA `35a9b1cf63aa3b332345ac4877995dea7588bac1c77a43552bcd351c53b0e7e5`。独立事实报告 `shutdown-log-quiet-independent-review/round26-evidence.json` SHA `5608008dc68027cc6f3347d68f480567aea77f28bd6809c0309b54cb9903be12`；root聚合 `round26/review.json` SHA `e65ec40154b5b30082e4d1f771d36d70d1eca68d65802ad19f63d587c53a31a7`。

下一轮仅追加已有 `print-fatal-signals=1 sysctl.debug.exception-trace=1`，保持87bae Image、89页、源842、模块和payload不变。实际parser、配置、sysctl注册顺序及get_signal到show_regs路径已核实；两参数可补致命信号PC/寄存器和部分路径/VMA信息，但不保证si_code或ESR，ARM64也没有32位ARM的user_debug参数。计划SHA `136029d450cf7bed223aa0e0d56faa0c07bd990ef1793265c6e56cb32aacd008`。只读取得安装版apexd和精确PT_INTERP `/system/bin/bootstrap/linker64` 副本供后续映射，不能把安装版文件身份当作已采到目标进程映射的证明。


## 四十五、第二十七轮实测：APEX bootstrap完成，后续无init进展记录

只新增上述两个既有信号诊断参数，不改C、不构建、不改Image/模块/payload。新runner校验SHA `f504002e836b64a021ec9f281a593a91bb8ca668a22472eed1158d01839b3d86`，新增选择8例通过，命令行1717字节；prepare、stage、实际loaded DT及execute均核对两参数唯一且长度小于2048。源842正常临时启动，UUID `3832ee69-346e-43d3-b2c9-dadfbf1f9b5e`，695原模块与Android/root正常。nonce `cd1bd079e10e2ceb`，实际目标DT SHA `ef80f9ed5e6be6c0eee07b104ae43c5769f889a04a18f7385c26e91ad960f5ec`。89页、GIC、双SP/四TZ、完整搬运页和PHY资源范围全部通过；本轮控制页分散到1640个memmap块，读取3899次，耗时较前轮增加，未因此跳过检查。

temporary boot/helper/load/execute各1。target raw为262132字节、2430个LF，SHA `c271c6937560c0b1caaa356e260330cc508adc9d397fab2050408689dee99cc6`，仍满环、开头被覆盖。完整LF1643/1644证明apexd-bootstrap PID355启动；LF1671进入--bootstrap；LF1786明确virt APEX成功挂载；LF1797在2.016256秒记录`OnBootstrap done, duration=185`。退出行LF1798的时间、PID、status字段均受损，原字节含`pid #55`和`sta4us 2`，不补成0，也不认定真实退出2。LF1804只保留linkerconfig exec-hook载荷，前缀/PID损坏，不能指定它的进程状态或故障位置。

此后未保存新的init进展、完整reboot_on_failure或restart原因；只有后续UFS时钟/电源PM、20.457951/29.929961秒的wdog_util ping c0，最后30.881863秒RT throttling。它们不足以确定看门狗复位机制，也不能把缺少本轮SIGILL记录视为该故障已经修复。现有结果显示用户态失败点并非稳定停在同一位置，需要同时补原始SIGILL上下文和停滞时PID1/exec子进程状态，不能只围绕已完成的UFS枚举继续盲改硬件。

最终自动回安装版BID931f、UUID `feedca25-bb70-4429-a38c-904f5d922821`，Android/root/watchdog0及恢复采样前后同UUID通过。恢复报告SHA `bce2efde55a6828f02068a6d2adee47448a6b924149821cd0abd39a0ed274f16`，独立raw报告 `sigill-independent-review/round27-evidence.json` SHA `b45bf55944b2634be67ffc9e3ea8f833d53bfb54d8ed014aef25daa2322c06ee`，root聚合 `round27/review.json` SHA `bd9b95bfc18690da383b200918fa172b72271e322fe167bc2abbe8b6862cf31e`。未额外重启、未刷分区、未改看门狗或仓库kernel；完整功能修复仍未完成，不能给可靠剩余轮数或完成时间。


## 四十六、第二十八轮：USB恢复后单次请求kexec，仅保存源交接尾

针对R26的SIGILL和R27的APEX bootstrap后停滞，先保存权威补丁 `other_patch/kexec_user_state_diag_6.6.89.patch`，SHA `2527bea1e3e8e6f9303aff4cff3ab6f3b6035cfbffb8faad28c02dd6ffc05643`，再在87bae的新out副本fuzz0/no-offset应用。仅新增observer C/header、Makefile条目和三处EL0 trap调用；保留原undef读取/模拟/force和BTI/FPAC原处理。默认关闭，须精确`kexec_diag.user_state=1`和chosen的kexec标记，late-init完成回调初始化后才发布active。

EL0-origin与SIGILL-deliver各4个静态槽，按PID1/apexd/linkerconfig筛选；复用原undef已读指令并标valid，不额外读用户VA或文件内容。SIGINFO仅在实际layout为SIL_FAULT时读addr，软件sender和default/ignore/user handler另列；不把SIGILL直接认作fatal。VMA仅工作线程trylock取元数据/path引用，记录为worker-time。5/12/24秒观察PID1/相关leader/直属用户子进程及有限线程；远端R/on_cpu跳过栈，其余回溯明确best effort。每任务最多8帧、每次最多32个成功输出帧；raw/map/event预算和每次header/stack预算独立，丢弃/截断可能发生，不保证4+4槽或16任务完整输出。未新增硬件访问、寄存器/任务修改、IPI或看门狗操作。

唯一正常构建exit0、48.719秒，C及冻结父ELF/config保持；BID `b04f54de1c3320828089eea032cc23bb774d6631`，Image37001728字节，SHA `ffa73e57c5cb7544fc6e17d604a15ff15ec765a4ce8d37ab23fdef690d8b003d`，memsz37683200。16306条CRC、19种布局、未变原对象均通过；freshconsole重审并从实际ELF重算119个关键Image页。首个host verifier因误用ET_REL地址取setup反汇编而停止，保留真实失败记录；只修主机检查，未改C、未重build。最终manifest SHA `2cb189aebc1a60f768b91074de70f2af1952bc5db9c1c24f4f2445c1eb3f1e45`；独立增量ELF审阅SHA `6c3f0bf4ed0f2a37eafac799e3a92fc431c70c245f10de90d55189fd06466f71`，无阻断，另以独立文件绑定manifest。

source842、helper、R24三模块及payload保持。runner只增加新selector、KUSR1捕获和实际目标/关键页绑定，既有守卫保持；复用已过的selector5例（1741字节），旧22/13/5/8用例未重复。最终validation SHA `aba6449d0cb464ed7b7f4bdf69ca87c8a265655c71d1c7c66a0ac0632e5ad0af`，root绑定 SHA `ccc69d937d2adc9b79a979366986b39befe07acdf7d56087a98b1247358a7fda`。运行前142个依赖实物哈希及四计数0均核实。

首次adb reboot bootloader及product=sun/current-slot=a/unlocked=yes均成功，发送同一源boot时却返回`Write to device failed in SendBuffer() (Permission denied)`、exit1。当时计数1/0/0/0，未运行新内核。主机USB节点对gold已有rw ACL，未将EACCES文本认定为权限根因。USB连接重置尝试返回No such device后，序列号从主机列表消失；用户重新进入fastboot后恢复。失败保存在 `round28/transfer-failure-review.json`，旧状态与日志未清零。

第二次临时boot用独立host恢复脚本；源身份/模块验证尾与冻结原runner字节相同，只为fastboot boot子进程附加已审ioctl观察器，传递O_APPEND普通文件FD，不改参数、返回或errno。观察器SHA `6af672b3b8b50e347fc52b171f02161f916699d64656880985a26e1bc70b1f28`，8个host fake-backend检查通过。本次upload/boot均OK，288条记录为144提交和144回收，实际ret0/status0，errno13仍保留；这证明本次成功调用可保留旧errno，不能倒推首次未捕获失败的真实原因。未读USB payload。

源842实际正常启动，UUID `bd117c7f-5c34-46dd-9354-d6bcdeabbc9d`、695原模块、Android/root/watchdog0均通过；nonce `db9b4a3ba4016008`。initrd18906392字节、SHA `5387d934444dd3d498be5ea1d72bb714c88ab6789a1c221f90be3bff3995ee31`；实际目标DT SHA `fff75bd009b13b2c185f97bd3b05458b908a353112f4f17be6984f92accadbcc`。7927个control分配页、189个memmap块、997次有界读取、119个关键页及完整搬运页/GIC/两SP/四TZ/PHY范围检查均通过。

随后helper/load/execute各1，无自动kexec重试。raw pstore262132字节、4047个LF，SHA `2f02ccf3288b269d1227e1077f63d8ce24f4f0641e79560fad24448e75c80387`。它与pre-helper/load/exec旧pstore不同，确有本次源会话shutdown；完整LF4044–4047依次保存before machine_kexec、stuck0/online1/pkm0、relocate参数和reloc/TTBR/el2信息。实际start82800000、DTB beb200000，头部与本ELF primary_entry跳转一致。没有literal KUSR1、目标BID、nonce或新Linux version。最后C侧打印不证明物理分支已经执行，缺少目标console也不证明目标完全未运行或late observer致错；本轮未取得SIGILL/停滞进程现场。

另找到4组源会话同timestamp/载荷框架的live正常文本与持久保存坏字对照，原始字节独立保存在 `user-state-independent-review/round28-persistence-pairs.json`，SHA `96a78eec7d81c6ce9191e53291765e3bb4c66bad6d4895edd2d06710038eda1a`；未修补pstore，也未把单个坏字当作目标用户内存损坏证据。独立运行报告SHA `6e8d9c06ade1dba896025d0e6e6f09d2afb69b094313fce7d855a3007be74f59`。

设备自动回安装版931f、UUID `a7abdfb2-c01b-47b4-9427-9713388af0aa`，Android/root/watchdog0及前后同UUID通过，无额外恢复重启；恢复SHA `cc62e9f8a9a5b9fdfe4234df97b6404a426b7e3f4da585bd42ad8873ffa6aaf8`。最终请求数2/1/1/1，root聚合 `round28/review.json` SHA `6bc9e0051df764db744b3f4a1d4a30e011ead4a096440838456e9fd0e4b8656c`。下一轮保持同b04 Image/源/模块/参数，原封不动复测一次；旧278字节entry模板绑定旧Image且KTT在当前native方案下故意关闭，不能直接重用。未刷分区、未改看门狗或仓库kernel，主补丁SHA仍`2ff710c967cfdf8cf8247ac71d95d061fe93709730373f5d530cca42e55588b7`。


## 四十七、第二十九轮：同镜像已进入目标，apexd分配清页触发SEA

本轮不改Image/模块/payload，也不重构建内核。新的runner只绑定round29、当前安装版UUID和单次源上传观察器；最终validation SHA `e1c0f4c57b17fadb81317ee98cfdf71fb3d22c01b648c7f1f3dd6f1fa3f1b3ef`，root运行前170个依赖实物绑定SHA `dfd3704a15d3bdbce33c8e48dfdd90a2aaa699738f503f0157ae913576043339`。1741字节append逐token比较，除nonce从R28的db9b4a3ba4016008变为本轮`be34b99a4daad460`外全部相同。

源842临时boot一次成功，UUID `03cf38fd-4c8f-486c-8af7-2df1df955e60`、695原模块、Android/root/watchdog0通过。USB观察器288行全部为原ioctl返回0、有效URB status0，仍保留旧errno13；不能倒推R28首次失败的原因。实际initrd18906392字节、SHA `5387d934444dd3d498be5ea1d72bb714c88ab6789a1c221f90be3bff3995ee31`；loaded DT1601399字节、SHA `747d10526264d7b23cae49cdb9687953dd5fdd32bee10fcab01fce37d49a678e`。7927个control分配页、127个memmap块、14207个目标页、119个关键Image页、873次有界读取，以及GIC/双SP/四TZ保留检查全部通过；实际PHY资源范围另审通过，SHA `4d9f11d9294976d614c00a8e1f1f4c0d814347eab5a37bac7f400d06ddc5156a`。

temporary boot/helper/load/execute严格各1。原始pstore262132字节、2635个LF，SHA `b7c83600eed24fd0e216fbe88958f49bf232dcc4131041ce2ab16c04d9938a29`，所有行号只按原始0x0a划分。LF507/665/725/785/844/977六处完整BID证明保存的是b04目标console；LF1699完整第二阶段init，LF2444完整T347 apexd进入--bootstrap，LF2513完整等待/dev/loop-control 82ms。当前运行身份核对仍是恢复后的stock，state中的target_kernel_identity_verified=false不可读成“目标从未执行”。本轮无完整nonce/banner，未补造。

LF2514–2521保存首次SEA观察。LF2514的FAR字段和LF2516的x0字段均完整为`ffffff802f32a000`，但两条完整行都有坏字；LF2514的ESR高位、raw PC/LR/SP和FnV键不能使用或修补。LF2515的PC符号`clear_page+0x18/0x4c`及LR函数名/偏移`post_alloc_hook+0x164`完整，LR size尾为`0x24,`，不补成240。LF2521独立保存同步外部中止和完整ESR数值`0000000096000010`，后缀损坏。

实际b04 ELF确认clear_page+18为`DC ZVA x0`，post_alloc_hook+160调用它、+164返回后继续原清页循环。完整x19字段支持普通prep_new_page路径的推断；没有完整外层Call trace，不能补成CMA分配链、特定文件读取或特定secure heap。x21、x22、x23与一个64KiB块中第10页清零的代码变换一致，但raw order字段坏，不能当完整order=4实测。假设目标memstart_addr=80000000时，候选PA为`af32a000`、块为`af320000..af330000`；配置/DRAM范围支持该条件推导，目标运行时memstart/PTE并未保存，不能据候选直接隔离或改固件归属。已知静态保留、16个GIC范围、四TZ和三目标segment均不与候选块重叠；14个目标动态reserved-memory的实际分配基址未测，不能声称全部排除。

5秒观察有PID1的S字段及完整do_epoll_wait帧0；5/12秒apexd的R字段位于损坏记录中，12秒还有两record合并，不能拆出新LF或据此指定当前PC、持续死循环或看门狗复位原因。没有literal EL0/SIGILL/signal-deliver事件，不证明R26的SIGILL已修复或与本次SEA同因/独立。

本轮自动回安装版931f、UUID `045e09e7-bc66-4929-be9c-fa3f64c3bf88`，Android/root/watchdog0与前后同UUID复核通过，没有额外恢复重启；恢复SHA `8c8c021590e605129ca38e985823583c60d4f1cebfc2c2cef13a7451c23e6fd3`。曾临时挂载debugfs只列接口后卸载，仅用于识别后续元数据采样能力，不是R29源归属证据。qcom_dma_pools的pool_size由qcom_iommu_util创建，只是普通atomic DMA pool总容量，不能枚举secure PFN或ACL。

独立raw事实SHA `a73d21094ac93c01e97e3730e883f802900f96e6380c6e5f13dddec660699d8a`，实际ELF/分配链SHA `858310b03958bc4b3d8e096ea7e679b271e54230bea7c541f3ef7ba1ece7f447`，条件PA与范围审阅SHA `727a3ec7db5c0d4156046df47c4e49c61ffe50e8904b3289b7302313322cd3f9`；root聚合 `round29/review.json` SHA `f96d6a6999ff441104a4a208bf0e41af5b167236cb49651e5c1d274ae4ee6a6e`。未启动条件性entry探针方案。

下一步只补本次缺失的目标实际linear PA和原异常寄存器栈，并在源端通过既有page_owner及安全池/active SG普通元数据查分配来源，不读取受保护backing、不重试SCM。source842已有CONFIG_PAGE_OWNER=y，但本轮没有page_owner=on，旧源不能追溯；下一次临时头可显式启用并保持最后stack_depot_disable=off，必须实际读到有效分配栈才确认生效。inactive安全池不在dmabuf全局表中，两类必须分别观察，token/软件标记也不等于固件ACL实测。新增C仍先保存独立补丁、后应用out副本；主补丁和仓库kernel未变，Android完整启动及正式交接修复均未完成。


## 四十八、第三十轮：完整清页SEA反查到同源GPU安全全局分配

本轮源Image仍是842，仅改临时boot v4头，启用`page_owner=on`；其余boot字节、Image和原厂模块保持。源包SHA `f9db74a55bdf9fdf22e361443b205ee93c31db678243fe2a42607453ef1c0964`，manifest SHA `a09814b2b485c308b65cd26fb5e77012dedecd9a250ccdb15fdf9a0d2329a651`。单次临时boot成功，源UUID `ca907ddf-d59e-48e7-a9d9-64c45327e7eb`，695原模块、Android/root及watchdog0通过；USB288行全为ret0/status0，不外推前次传输失败原因。

首次page_owner读取因dd的小读缓冲返回ENOMEM，保存为失败尝试，未当作设备OOM证据。改为cat后截取32768字节，66条完整分配记录中36条带真实分配栈，非仅early dummy记录；命令exit0、同UUID和debugfs卸载通过。接受报告SHA `9bf0504321c428563d6ad15fa558523c444aa560e5e3e7344909ecdddb45e91f`。随后限时45秒保存gzip归档：命令exit124，并未读到源文件EOF；压缩文件44098949字节、SHA `2a3c6335db36cc891a53ec37484c376a5101c49580f42b06bf87f3fa9f95c719`，可完整解压为1015504944字节、1338453条完整allocation记录。它是非原子的部分源记录；缺页不表示free/HLOS，也不能把R30源同PFN记录追认成R29源owner。

先保存权威补丁`other_patch/kexec_secure_pool_readonly_diag_6.6.89.patch`，SHA `3fcd6da0dc8032e30811b6e3895b098457ba005b5a2f5479cef4f7e2dbf223f2`，再应用独立out副本。单次构建及实际CRC/layout检查通过，KO SHA `e8bb862886ccb9f7b224346306341af41f479fd7ba819617356f023228fac4aa`，独立审阅SHA `7da00b57a4ca0295a4f1e8bab5bd30763467911c88b379efb2d14cee9fa2cdff`。仅锁内读取两个白名单secure-system heap的inactive pool，以及全局dma_buf表中匹配实际qcom SG ops对象的普通metadata；不读backing、不调用vendor ops/SCM、不释放任何原buffer。

主机采样包装脚本先后因缺pyelftools、kptr_restrict=2导致section地址0而在insmod前停止，两次均未加载模块。最终只为显示两条module section元数据临时置kptr_restrict=0，在同shell trap与外部finally恢复2，并读回确认后才insmod。实际采样器insmod/rmmod各1，raw306字节两行完整、SHA `e8464ac04902b8715ec908b9d50f3829c75619112cee052217387ea7b12e44b6`。scanned245、unknown_qcom_heap244、matched0、ranges0、busy/bad/cap/nofault全0；244是heap指针不在白名单的qcom SG对象，并未记录名字或secure性。六个白名单inactive池在各自锁内为空，不是全局原子快照。最终partial记录SHA `bcdc2b092f6bae39b72ae81c75aa01a0f8a665ad748f7f87cca18f422f215a41`，只证明采样完成且模块卸载，不是全局归属/固件ACL检查通过。

目标增量先保存`other_patch/kexec_sea_memory_diag_6.6.89.patch`，SHA `63f14177722d904090b6b3573bed088e97bb88954441b6f2ac71031d6c307d66`，仅改fault.c，复用原首次current-EL SEA和显式开关守卫。`KSEAM1`输出实际memstart/linear算术PA及从原pt_regs开始最多16帧的best-effort内核栈；不访问FAR/PTE/受保护页、不修改原异常处理，PA不是硬件可访问性实测。单次构建exit0、45.782秒，BID `337beb1178af6295c7072e8f0b5011eced5a3552`，Image SHA `9bc02c0342319e37ff9ee00dd0017e3b25f3b803056232d9f6bbb4a229cebd63`，manifest SHA `c53edcb46ef1c508048be2c528e0e247ff09b88e6cd67f90fdda5019e4efdaee`；16306CRC/19布局保持，实际重算123关键页，独立审阅SHA `7eb495834bfaa492f45f6c0be6f22eefc1ab117f3abe6a23a21efe2b5c175a9b`。两个host verifier问题已保留失败记录并只修检查，未因此改C或重build。

runner保持原SP/TZ/GIC/PHY/模块守卫，源page_owner参数不传给目标，目标唯一增加`kexec_diag.sea_memory=1`。新参数/守卫10例通过，旧ABI及selector测试未重复；最终validation SHA `4f168c900818d6eded8af5704b146fd8db2b599d30224bbd0060ed53090e1923`，最终主机绑定SHA `4513bd55af060fc13fe7a55aa0c463357f300c012d2eed3c5e95742be41c3660`。源page_owner内存和时序与R29不同，本轮不是相同条件重测。实际DT SHA `4403286ac748746fc245c955b88728ca36440b99fe1e7611a4dabefe9fc4eed9`，nonce `ae886f43ba35f58e`，1765字节append。123关键页、7927个control页、1503个metadata块及完整搬运页/GIC/双SP/四TZ核查全部通过；PHY范围报告SHA `eb6e13172d3e6b4e040fb824ba4e56d945f64aaf875f9057dcf93c110fc33bde`。本轮四TZ为ecea0000/20000、ecec0000/21000、ece8c000/3000、ed300000/80000，没有沿用R29地址。

四项请求严格各1。raw pstore117725字节、1298个LF，SHA `bdd8369d15e253c656e7c1e6c456d2a6cf34df5f111a3363ba4d1a94187c281e`，从本次目标Linux启动开始，保存环未满。LF2完整目标release，LF162完整nonce及sea_memory参数，LF1247完整目标BID337beb。LF1217完整ESR `96000010`、FAR/x0 `ffffff8804466000`、PC/LR/SP/FnV；LF1224实际memstart/PHYS_OFFSET均80000000，LF1225算术PA `884466000`/PFN `884466`。这是用本轮实际layout推导，仍不是PTE或硬件ACL查询。LF1226记录16帧、capacity达到；15条KSEAM frame格式完整，LF1237的symbol键受损未修补，原oops LF1275独立保存相应符号。

原oops LF1265–1288完整24帧：clear_page、prep_new_page、普通buddy分配、folio/shmem写入、xwrite/do_copy、gunzip/unpack_to_rootfs、do_populate_rootfs、async worker至ret_from_fork；PID82/Comm kworker/u18:1，0.715811秒LF1291明确Fatal exception panic。本轮故障发生在内核解包initramfs时，不能套用R29的apexd上下文。独立raw报告 `sea-memory-review/round30-evidence.json` SHA `58adfc3a768fe7226e94af0dc5a84847b52cd194917eb570d466aba5611dd4f8`。

仅做一次完整gzip流式区间查询，压缩及解压hash/1338453条记录全部匹配，PFN884466唯一命中807字节order0记录，归档offset141741691：surfaceflinger PID2313，分配时间7.391625178秒，调用链`kgsl_system_alloc_pages → kgsl_allocate_secure → kgsl_allocate_global → send_start_msg → gen8_hwsched_hfi_start → gen8_hwsched_first_open → adreno_first_open → kgsl_open`。报告 `secure-pool-readonly-review/r30-pfn-884466/lookup.json` SHA `3ff0a846afb503fa2c13f002660af55142cf4385fe0d80627268de21f1f1aab7`。它给出同源历史Linux分配来源，不单独证明之后分配仍存活、固件ACL或唯一根因；先前两dma_heap采样没有覆盖KGSL globals。

本轮目标14个动态reserved-memory池都有完整早期日志，故障PA不落在它们、有效静态保留、GIC、四TZ或三载荷段内。它几何上落在源初始dump_mem_region（880240000..885c40000），但源LF1993已明确释放81808K；实际memory_dump_v2模块的逐页free代码与日志支持尾部880c5c000..885c40000归还buddy，随后才有上述KGSL分配。不能把初始90MiB当作持续owner或据此整块保留。范围报告SHA `0b64ee85581f41e33f67a43251d7759dede57c6ccfca7e94784ded21371ff4e2`，释放补充报告SHA `fa3e8825c82e183adb802247e2224b74388bd0b5d22c1c87cc18f658fbf85d85`。

设备自动恢复安装版931f、UUID49d71bde，恢复核查SHA `57b3a14002e8d448e986884f29dd61097a4a4489cc75eb4638ea43ae49757980`。首个只读恢复检查误要求安装版不存在的kexec_loaded接口，已保留失败记录并改为记录接口缺失，不把它写成已读取0，也没有重启/重复execute。随后只读取安装版msm_kgsl.ko，SHA `c0d98b40d17f7f9cdc99b39239138e79f2b014007c9f088c1b17b42285ac1432`、BID `f95e145481d6423dffac1f0cb3e1236dfbb1b753`，与实际加载模块GNU note及文件hash一致；R30源使用同vendor文件系统，但跳转前未采KGSL GNU note，下次必须重新核对。

独立实际KGSL ELF审阅SHA `0f255c1033e5fc987ec56ce5572e594f56908c9c5c3c722b7c907d79a3361dfe`：六个相关platform driver的shutdown槽均原始0且无relocation；adreno普通PM suspend/resume也不是可选安全页hibernate分支。globals释放实际属于adreno_unbind/remove链，普通kexec的device_shutdown不调用它。实际secure分配中的hyp_assign_table为VMID3→10，正常free中的unlock反向10→3成功后才free页；不能仅因函数名认定已分配成功或盲调私有回收函数。下一步是受限只读核对运行中的secure globals/SG普通元数据，再选GPU停止与安全页归还或明确隔离的修复验证；不读受保护页、不盲重试SCM、不把单次隔离称正式修复。主补丁和仓库kernel未变，完整目标Android仍未启动。

第三十轮root聚合报告 `out/kexec-boot-fix/round30/review.json` SHA `caa2f44b912b98d9b69f2be93f7e688876954b21f16fb4e0a9f3bd71de9e4c09`。


## 四十九、第三十一轮准备：按本次源SG隔离GPU安全全局缓冲

在R30恢复安装版上先验证只读观察方法。第一次在stock BTF多个同名struct module的守卫处停止，尚无BPF普通内存读取；改为严格匹配所需size/字段投影并保留所有匹配ID。第二次在platform_driver.driver偏移守卫处停止，实际BTF和ELF重定位证明应为48（shutdown仍24），已修主机清单，原失败记录与旧工具全部保留。两次均未改C、加载模块或触发GPU/SCM操作。

第三次stock观察成功：精确kernel/module GNU、core BTF、原指令、module范围及设备链均匹配；126次普通元数据读取、15528字节，前后指定字段一致。20个global对象中，唯一软件secure对象名为`GMU CSW PRIV SECURE`，size `0x28e0000`（40.875MiB），该stock启动恰合为一段SG。报告SHA `4a2905e83f8ff61484a6d1e925159b42d4ee4d3a4ffb84ba898a317b7036d45e`。它没有锁/引用生命周期保障、不是固件ACL或完整覆盖证明，更不能当R30源现场。观察工具最终SHA `646b8c6e576058b76c7e3668ae73ad5513efc3e6f72e713da89a5dd0a0d20bcb`，实际offset清单SHA `ba832273b68aaa6eb7d2067d0c6ae69530ab7e816f6b74fca426dc29f07fd8ab`。

新的权威补丁先保存为`other_patch/kexec_kgsl_secure_nomap_diag_6.6.89.patch`，最终SHA `0d06a863496bbce04b533a50fcf457c16ede9596e4813d44708b900f1febdd0b`，仅改目标arm64/mm/init.c。严格early参数`kexec_diag.kgsl_nomap=hexPFN+hex页数,...`，默认关闭，须flat chosen的kexec标记；最多32个有序不重叠范围、256字符、64MiB。16MiB初始候选在apply/build前因上述真实40.875MiB观察而修订，未硬编码stock或R30旧地址。

全部范围先检查完整RAM、现有map/reserved、整个_text至_end（包括head64KiB）、initrd、FDT自体、header memreserve及enabled static reserved-memory的所有reg tuple；全部预查后才reserve+mark_nomap。hook位于原kernel/initrd保留之后、动态DT reserved-memory分配之前，因此新dump/CMA池应避开这些范围。明确非法或部分失败时panic，未实施回滚；不读取保留页/PTE/ACL、不调用GPU或SCM，也不声称覆盖更早的EFI/SCS访问、GPU已停止或全部安全分配。

补丁先在独立out副本fuzz0应用，唯一正常build exit0/47.836秒。新BID `4646f9c53d37fb382dbd5c23aa773837dc427084`，Image37001728字节、SHA `c86280df7acdeaec37fdfd125c30f2c422e35a40689282d49202a7116569aef4`，manifest SHA `165e9830ce3fcd726bed74caeb944a1d6adfaf051626f6fff3f01c54a48e8f69`；43个实际C/libfdt用例、16306CRC/19布局、fresh console及实际重算206关键页通过。原warning printk块被Clang重排导致一个额外主机静态顺序断言失败，已保存并按实际C后缀/非printk调用投影审阅，没有改C或重build；不称完整CFG等价。最终绑定SHA `9915cd7927705f26c4adb89ab8de4a7d1ce26abef6a786b2f7a92875f1bcabf4`，独立实际ELF审阅SHA `3298fca8fbce3d4b976673222919463f0375ce7e29fd81762229c81220219e37`。源842、父337与仓库kernel均未修改。

第三十一轮临时boot仍用同一f9源包，单次成功；当前源UUID `aa6fa070-cc0e-4643-8d03-96a0f148b8fa`，695原模块及KGSL f95e GNU note已在本次源启动实际保存核对。page_owner32768字节、36条真实分配栈通过，accepted SHA `630e2ea39deeba10f9c9040ff9a3ffa16341935f9dd86a2adaa656087815b5a4`，debugfs已卸载。SG采样前临时显示module section地址时kptr_restrict由2置0并恢复2，随后才读取普通元数据。

本次源SG观察成功SHA `ff282e02b79527dc7b1bad49cdde9a8f1130b55e0ace8a3c8a9b931ebc35d615`：仍为20 globals及唯一同名40.875MiB secure对象，却分成5个不相邻SG；PFN+hex页数为`8f23ba+22,8f241b+189c,8f3cf6+fc,8f3e31+89d,8f470d+689`，各SG头page_private为eeeeeeee。它体现本次软件对象/SG关系，不是硬件权限查询；不会复用stock单段或R30旧PA。下一步将这五段绑定到实际目标命令行、装载页/DT及保留范围检查，audit完成后再做一次同源SG重复观察，差异则不execute。当前尚未helper/load/execute；隔离实验及正式修复均未验证。

同源限时page_owner归档也已完成唯一一次主机流式校验：gzip46876307字节、SHA `15beac462c403cf503f942caf242ac2641d30ac5104d39ef57412f1461f11940`，完整解压1063840357字节、1394705条记录、尾碎片0字节。五段SG共10464页分别命中34/6300/252/2205/1673条KGSL栈正记录，原始head/order区间和记录字节另存；索引SHA `9343a1e3c56ae5b1d6052bd34b281fa703438f605089b032ba2dca1e2cdb4d15`。采集命令仍为超时124、未达到源EOF，不能把主机gzip完整当作源全覆盖；分配记录及普通SG观察也不证明跳转时固件ACL或持续存活。


## 五十、第三十一轮执行：目标进入init，libcrypto用户态SIGSEGV导致panic

新runner最终validation SHA `fa16232cd3ed718559dc8ab569f86949a7056dfaaa8f673058e41105e5955de2`，ROOT逐一核对265依赖，206个关键Image页与新4646目标绑定；新增21个集成检查通过，旧ABI用例未重复。主机独审发现并修正两项纯检查缺口：source Image所需三符号的allowlist，以及GPU范围在实际loaded RAM中的完整覆盖，未改内核代码。独审SHA `cb0a13c7d94360cb4ea314616671dadb90d4d4bf3952563c80bac6bf2f984375`。

实际1841字节append与R30逐token比较，仅nonce和新KGSL参数不同；nonce `f81560387ff99e55`，五段token与本轮源SG一致，未沿用旧地址。helper/load各1，实际DT1601531字节、SHA `9730d07d17a8464df2cdc29d02027e10df574f2e4a09b4eaed278a8ab1878d8f`。206关键页、7927control页、2575个memmap元数据块、5894次有界读取，以及sourceImage/三载荷段/全部搬运与bookkeeping页/GIC/两SP/四TZ/ramoops/static/header检查全部通过；GPU五段均在实际14个RAM tuple内。PHY实物范围审阅SHA `dd25ff738d150da01cc9f9cefecc314bd1badb5cd0623a7ab489e5860e08d6e8`。

完成audit后由ROOT记录真实开始/完成epoch，再次独立采同源KGSL普通元数据；late报告SHA `0209fce0ecb28c06c40f20bbe5201c2c67c9fa82882c911a22a03d1532c9007a`，20个globals的身份、secure SG与五段范围均相同，150次只读采样完成。这只能排除已观察字段的变化，仍不是生命周期封印、GPU停止或固件ACL实测。随后execute严格一次，没有自动重试。

raw pstore262132字节、2917个原始LF，SHA `7731f0d46fa4276f3f1b1025d5b3759163bb635b11438e1a63ea59a0bb5735b0`。满环起点已在早期dynamic pool中段，KGPUM1没有留存；LF133命令行本身损坏且受1024字节record上限截断，独立nonce token完整，但不能据缺少末尾隔离token判定未启用。LF90/92/96/98有四段与请求精确吻合的early-memory边界，另一段LF94坏；这些记录没有NOMAP标志，不能升级为逐段隔离成功。14个动态池只有secure_cdsp/cnss_wlan两条完整标准范围行，dump_mem数字完整而label/flags损坏，其他不修补；未声称全部目标动态池已核实。

本轮多处完整BID4646证明目标已运行。LF2627明确init first stage completed，LF2628–2630保存/system/bin/init的selinux_setup和PID1 exec。LF2649完整lower-EL DABT、ESR `92000005`、level1 translation fault，VMA为libcrypto.so[7fa00d1000+fc000]；LF2635/2636完整PC `7fa0116d04`/LR `7fa01ac050`，LF2648完整SIGSEGV11、code1、fault addr2，LF2683在1.617645秒明确kill-init panic、exit0b。LF2631的DABT单词和后续部分寄存器重复行受损，未修补。没有保存KSEAM1不能证明SEA已修好，更不能把这次SIGSEGV直接归到GPU或代码字节损坏。独立原字节报告SHA `5409c023e0763a07a709be8a3488ca69c6e7501791566d6c2385e1ac7ce55357`。

设备自动回安装版931f、UUID `62826719-1cea-40ef-932c-8d88896b4212`，Android/root/watchdog0、kptr2、debugfs卸载及前后同UUID通过；恢复SHA `9b0bfd45a7f2a092af236eab5b0118fbf95d7beafd5bed80d09503e78e9ab6fb`。kexec_loaded在安装版接口不存在，未写成已读0；没有额外恢复重启。ROOT聚合报告 `out/kexec-boot-fix/round31/review.json` 已保存。下一步仅用同一4646 Image做正常临时boot对照，并按实际libcrypto ELF分析异常指令；当前尚未正式修复，也未改主补丁、仓库kernel、分区或看门狗。


## 五十一、第三十二轮：同一4646 Image普通启动完整Android通过

本轮没有改C或重build：从R31实际4646 Image等长替换已验证f9临时boot包的kernel区间[4096,37005824)，头只去掉page_owner参数，cmdline精确为ramoops.console_flush_diag=1；v4/1584、ramdisk0、signature0及其余头/padding全部逐字一致。新boot37007360字节、SHA `744d170ba64fefa248f3fd7df5bfb5c2fa131cc84704880814c85263a6ad01b9`，封装验证SHA `9939768cb3c20e1224e3c232fe374d294d0cbda782d6ab64805bc4fc4323e755`。没有附加或替换ramdisk/模块，不带隔离地址或kexec-only参数。

ROOT从已核实的stock UUID62826719发起一次普通临时boot，fastboot返回0，实际GNU BID确为4646、release匹配、完整BTF与原目标匹配，Android sys.boot_completed=1、root/watchdog0/kexec_loaded0通过。当前UUID `52ac911d-1444-400b-bbe6-308c14dfe965`；695个原厂模块名集合与R31源完全相同，无新增/缺失模块，stock GCC/UFS/PHY及KGSL四个GNU note逐一核对。实际FDT的chosen没有linux,booted-from-kexec，实际cmdline没有kexec_diag.*或page_owner参数。helper/load/execute均0，未刷分区或改看门狗。

这是同一Image可正常启动Android的正对照，排除了该二进制在普通默认配置下必然启动失败的解释。它不能证明kexec已成功，也不能区分旧硬件/固件状态与只在热启动中开启的诊断参数、改装UFS/GCC/PHY模块所带来的影响，更不证明GPU隔离已执行。R31的用户态异常需要继续核查实际映射/原指令与交接状态。

另对恢复系统的两份实际libcrypto ELF做只读分析，完整RX字节相同。实际kernel print_vma_addr打印VMA起点而非loadbias；按两文件唯一RX PT_LOAD（vaddr/offset77000、页跨度fc000）作条件换算，PC对应ec_scalar_select+8c，原LDP [x12,-16]与日志x12=12正好得到地址2，多个邻近指令也能解释寄存器。更早caller的mask/正常frame布局与raw不自洽，因此没有把LR当完整调用历史，也没有据此声称目标代码字节损坏或DMA已证实。目标vm_pgoff/实际code尚未捕获；报告SHA `3713fd250d2aa7e39347b2e8a77f8e971343f60c1b165132a0cd51f84d7eed60`。下一增量仅补同步DABT元数据与隔离摘要的故障时重放，仍遵循补丁先行、独立out、普通路径不改变原异常行为。

后续两个取证增量已先保存权威补丁：`other_patch/kexec_kgsl_nomap_verify_diag_6.6.89.patch`（SHA `9a239601ebfaf41a993c6b0b37522a37650b6ab0564ba070aeda4436b4a4919e`）和`other_patch/kexec_user_dabt_diag_6.6.89.patch`（SHA `57f5bfb63ab289de3fabba516d02cf1787ae831105d2517884a102128f72ae50`）。前者在原async初始化完成后、free_initmem前，在热插拔读锁内检查两张memblock表的完整连续覆盖，再封存到只读摘要；异常时仅一次重放历史摘要，不重新遍历表，也不宣称实时权限。首候选的裸表指针并发释放风险已在构建前修订、归档旧候选。后者只观察原失败DABT路径，不改变原异常信号/寄存器/return；同步trylock保存PC/LR的VMA偏移和文件标量，只有可读且可执行的普通文件页才尝试4字节nofault取指，XOM明确跳过，不读FAR目标或用户栈。上述`57f5…`是首版候选；其首build仅因4个u64/`%lx`格式警告失败，原错误和产物另存attempt1，没有放宽编译器检查。权威补丁仅增加4个显式unsigned long转换后，当前SHA为`093ce95aa36f98b054590623ad8afc2ac913dffd3145fafe388ef60b29d76406`，诊断逻辑/协议未变。第二次build exit0、42.044秒，新BID `ca789cc7ad9ec9bcffc0093e69d3b2a46ab5e529`，Image SHA `0f1505221223e880b231d81b18ea3bc2b7bd4e85168f3f212efd26c7a6730fbf`。16306 CRC/19结构布局、原关键对象及shared ASM、fresh console通过；224个实际Image关键页，46个NOBITS状态单独记录，不伪造成文件字节。manifest SHA `3ab5099b79249fef47775b73c13c7bb1d988bbcf3974a17d318e4592bc992121`，增量实际ELF审阅SHA `7cd8818cf05fd5974d0736e959c97897b9c753057908eb405f7df4e1c44d0a91`。目标尚未运行；生产者验证及实际ELF独审均完成，独审SHA `efec6a8760589eadac1003c20c8fe26a8c850ec7492c145c931bf8954cb7dbf6`，最终静态绑定SHA `20d73bafcd8350ab24508e4d071e10e3f7dc09453267843a9ed903f27e0885fe`。


## 五十二、第三十三/三十四轮：源GPU碎片超出原表达或采样容量，均在装载前停止

R33源842临时启动成功，UUID `5fe1ded3-4868-49d8-942d-a4c63b129452`；page_owner真实栈、695原模块及KGSL f95e身份通过。只读SG观察完成，SHA `07f0e4c9117ec8324e5b5b967c891b79d0ad479c63b02f3ec530ea5146cc3c19`：同一40.875MiB软件secure global分为118条SG，仅合并精确相邻区间后仍75段/704字符。原目标仅支持32段/256字符，冻结encoder实际拒绝。没有删区间、扩成含未知洞的大范围或沿用R31地址；helper/load/execute均0。聚合报告SHA `0048f9adafbd39802761c4dc900d59726f5ba4f057016bbc9542f7c8773cf4c6`。

随后仅重新建立一次R34源会话，仍为同一f9 boot/842 Image，UUID `d33443dc-8ee9-4956-929c-4c686a0c8a85`。page_owner真实栈验证通过，accepted SHA `5940e441ab49e65c30cb06729693db021bff28d0d6c2e2e9f25bc75ffb832ffa`；读取KGSL module section地址时的kptr_restrict已恢复2，debugfs已卸载。冻结只读观察器在after阶段重读page flags/private时，达到1800次读取上限（累计43764字节），明确中止为ABORTED_NONATOMIC_METADATA_OBSERVATION。它保存了347条SG候选，算术合并为263段/2357字符，但没有完成所有after身份复核，绝不将这份中止报告提升为有效快照或传入装载。

R34再次在helper/load/execute前停止，三项计数全部0；实际只读复核同UUID、源BID842、Android/root、watchdog0、kexec_loaded0、kptr2、debugfs卸载及helper不存在。聚合报告SHA `a052dfc88380e8b85cb6f66f68bbf77617096d8d04753cb1b170691abfd91c16`。没有反复重启碰布局；下一步必须先设计能有界完整表达分散区间的二进制传递方案及由真实上界推导的观察器预算，维持完整碰撞检查、64MiB总量和before/after身份复核。现有ca789镜像及32/256旧协议冻结，没有绕过守卫执行。上述容量问题是诊断工具的限制，不是新增的Android内核故障证据。


## 五十三、二进制区间协议准备：新source与target均先保存补丁，尚未再次跳转

R33/R34均在装载前停止后，停止重启碰布局，转为显式新协议。冻结schema SHA `4b96f699047cd34ea75fdb07ba07acc677e28828d0c41ebe7433ac7fd022dbc7`：`kexec_diag.kgsl_nomap_fdt=1`，chosen属性`linux,kexec-kgsl-ranges`，32字节版本头及最多512个BE64 PA/byte-length tuple，仍限64MiB。CRC仅检查元数据完整性，不是认证或硬件权限证明；外部同时绑定完整blob SHA、真实源UUID/模块/BTF/SG和目标nonce。不向命令行塞长地址串，不舍弃区间或填补未知洞。

源端从普通initrd文件末尾取得有界blob/footer，捕获发生在IMA和任何载荷段放置之前；仅在显式开关与全部校验通过时裁去运输后缀，目标initrd保留原始前缀逐字一致。独立每image缓存参与GIC/GPU联合单调避洞，保留至kimage销毁，默认关闭不读取/裁剪后缀。权威source补丁`other_patch/kexec_kgsl_binary_transport_diag_6.6.89.patch`当前SHA `6ddab8113719bb32785008077bed59729f910f5de8df203e6108aeb45b4dbc93`。首版正常build后，ROOT审阅补入最终fdt_pack错误检查及2MiB上限，再一次正常增量build，exit0/40.524秒；新BID `4424630e5e18a578666635e066a255bdf42c3428`，Image SHA `34b87846705952d24a05c7c3d8af78bf50b0bcc84b65079c7b0b23560ecc12d3`。实际ELF独审SHA `82680d8435244c1857a7fd6ad75dbde5951bc9aa86d1bd4af6ab575877750654`，完整producer ABI/封装绑定仍在完成。2MiB及DMA交接要求参照[Linux 6.6 ARM64启动协议](https://www.kernel.org/doc/html/v6.6/arch/arm64/booting.html)；当前隔离并不提供协议要求的GPU/DMA停止。

目标端仍先验证全部输入/RAM/静态/内核/initrd/FDT碰撞，再reserve+NOMAP，部分失败panic不变。新增default-n诊断配置仅开启时使用2048项静态memory/reserved表，不提前开启resize；预查memory剩余至少2N、reserved至少N。512位历史覆盖摘要以有界KGPUM3重放，并绑定blob CRC/count/total，异常路径不遍历活表。目标权威补丁`other_patch/kexec_kgsl_binary_nomap_diag_6.6.89.patch`当前SHA `99d6c0b6005e90bea9dd581f2103d6e83d92547032f3e1039698d6b3e65a72f8`。首次真实build在宏重定义Werror处失败，未上机；此前generic-only主机断言关于default-n为128项的说法不完整，保留为失败候选证据。实际ca789 ELF及ARM64 EFI/ITS配置证明原memory为1024项、reserved为161项，纠正报告SHA `df2dc829eac38292902189e347fc4e6ad080758e261d3ae8ed35fd65d02f2f0c`。只在config-y块先#undef两架构宏再定义2048，config-n保留真实1024/161；完整真实编译命令预处理两模式通过，SHA `70dbe7a25f2ab4152ce97ceb270a64c432faa98ac83a37582b2b65683a8006a0`，第二次build已批准进行。原parser及碰撞逻辑没有因该编译修订而改变。

只读observer v2保留全部before/after验证，仅改为全局共享768个SG访问上限、512个data SG、4608次/256KiB读取预算。可推导最坏4282次/145512字节，13项定向host检查通过；原R34失败没有补数据或提升状态。新sourcefdt身份尚未实际绑定时，observer在任何设备访问前硬拒绝。独立host producer的42项协议边界检查通过，其中R33完整118条SG到75个union的10464页集合逐页相等；它只用于主机验证，不充当R35运行现场。本准备记录写入时仍是R34源，尚未新source临时boot；后续R35源启动及采样见下一节。新协议的目标接收路径和正式修复尚未获得设备运行验证。


## 五十四、第三十五轮源启动及采样：4424正常Android，完整9条SG；等待最终装载守卫

新source最终manifest SHA `e0224418a4d5821f32b62f93398f4b746166ee81ce4b89a33be925356245ae48`，BTF `4af0d389bc92615ac8982233f544f4653b67c6535ae869267f80da0fbf273550`；16306原CRC与新增gate的1个CRC全部保持，19原结构布局不变。kimage的私有arch追加指针使其840→848字节，新增arch.kgsl绝对偏移2d8，后续私有字段移动8字节；runner必须使用新真实BTF。source ELF私有缓存大小4048，不将vmalloc指针盲算线性PA。旧preserve helper保持冻结KO，实际全部import CRC/provider和所需结构重新核过，其日志里的842仅历史编译基底，不是本次运行内核身份。

ROOT用同一f9 v4/ramdisk0/signature0头封装实际4424 Image，原header cmdline仍仅ramoops.console_flush_diag=1/page_owner=on。新boot SHA `d7ce9eee4e4b5eff7b90d36134a6585d3fa82027dc1db16b38fb53815bb1ff17`，封装manifest SHA `184a630199b6aef244055d3a97f1bd5e997261f36e5fd097724aee0c9d256346`；另从实际Image抽出IKCONFIG，与build/.config逐字相同。独立delivery manifest SHA `e958f8b6a2f167d2fc14da7271bfdc02581fee17b01aa2905f3c026f53c1ea67`，没有继承旧source boot冒充新包。一次主机检查曾错误要求所有共享ASM的整个.o hash相同；已保留失败记录，正确范围是源文件、实际可执行字节及标准化relocation相同，relocate_kernel.o的debug部分不要求相同，没有改C或重build。

source-only boot脚本SHA `ec71998bfa0f0c5f03e6ccb5846ffdd202e68156df15a5ab1ebdc2ba69f592da`，22依赖的专用静态验证SHA `dc3015ed37082fe204c58cd4b0f560d4088fda57a8d3e7ee0b15faae005b1eeb`。仅此正常临时boot已执行：真实GNU BID4424、完整BTF、7个原厂关键模块GNU note、695模块名集合、Android完成/root/watchdog0/kexec_loaded0全部通过。当前UUID `985424e2-23f9-49f9-8137-5ce33ca95ef4`，临时boot/helper/load/execute为1/0/0/0；这不是目标kexec成功。

本源page_owner真实栈accepted SHA `3c46312c675d7874dce81d5ccd266533e74ebd874109c7500acb01d4d18a9fdb`。observer v2冻结脚本SHA `86797d628a9e314d86cfccc0655391ecd4d8b86c40108a7f4c2709e8e254b142`，已绑定实际新source/BTF的manifest SHA `84d8d25ee9e959717a708e97f8fd0b0e189f0f1f989a08fea1bca76caeaffd8f`；最终静态验证SHA `694af4cd301fb1e53710a9ae4ab27b8296fcec288f4725631bae02abecb4c78f`。本轮完整前后观察成功SHA `62eb951697d98ff8c504d14edee7e79da67e3f501a2e69a0ad278232ff099051`：174次普通读取，20 globals中仍只有同名40.875MiB软件secure对象，9条SG恰为9个union。ROOT完整raw验证及wire核算通过，blob176字节、SHA `c788b09cdb4a0306498132033e08b52c5f1a12497fefde771ca6e47a58a5bd58`。本轮恰有9段不代表512段运行路径已上机验证，也没有重新启动来挑9段；这是为实施新传递协议构建的新source。

另唯一45秒page_owner归档完成，exit124未达到源EOF；gzip35672407字节、SHA `6c908c5ab4fc1903c4e82f096ddcde1cf6467127de139472c2ef51000e13efa9`，捕获及解压828029530字节、SHA `8d4a40cdca3faea73b360fd1a8002e9810ea50b393a3986d56425e0613256ecc`完全一致，同UUID、debugfs已卸载。报告SHA `f915eeae129d2bf204093be4763e3322a923340bba9dc599b4905490198f9c1e`；这是部分非原子历史，gzip完整不代表源覆盖完整。

新target第二次正常build exit0/44.255秒，BID `68e85e134a894c34b5fef3ac30f4dd450d00a6b5`，Image SHA `8824087346c58ea7ff57b31fdcee795c509f7cc58699c558b234f1417851130f`，37001728字节/header image_size37748736。manifest SHA `3ef281065bac2dea83f3a7aa13e5514e6abd8cdd0131fca76d6e531768d38f92`，233实际Image页/46独立NOBITS项；实际ELF两初始表各49152字节/max2048、retained ranges8192、两mask各64，独审SHA `52137a0775c9454dee7912316eb5e06d001bdab1a374bdc30aa95ea7a4625b98`。source层的fdt64_ld按字节表达，但编译后实际为Normal-memory LDR/REV/RET12字节，依赖既有FDT Normal映射和SCTLR.A清的入口前提，不声称运行时PTE/ACL已读。ROOT已核真实Image和全部manifest源码hash；最终绑定SHA `7c9c5edba4b9a81c34aeb4eee25722f6d0e38df22bb8f9a72866e4954fbcfe11`。R35完整runtime守卫仍在完成，未helper/load/execute。


## 五十五、第三十五轮单次跳转：完成APEX bootstrap，用户态失败后有序重启

R35完整runner最终validation SHA `a54e8848e1b0a090d7bb441705d41bc0938d6188ec85f16e6521b5c1104d01a4`，18个脚本/318个依赖、14项新增host用例通过，没有重复旧ABI套件。源侧辅助独审SHA `c6a2f41a2d257e1f0883e53eb32e8e28241e87c0c7e58282230e102098ea4440`，GPU传输集成独审SHA `2650581d7625893c8351b5357e628b7f0bfaa470e13ac49c181042a851b18670`；ROOT再次核实依赖和22个补丁实物hash。已执行过的source-only boot脚本未改。

唯一helper/load均成功，nonce为`93037c1caf16fd7a`。实际原始initrd前缀18906392字节/SHA `5387d934444dd3d498be5ea1d72bb714c88ab6789a1c221f90be3bff3995ee31`；运输文件18906600字节，增加的是176字节blob及32字节footer。load日志、chosen的initrd extent及源per-image缓存均明确只保留原始前缀。源缓存与实际装载chosen的blob逐字等于主机数据，仍为9段/40.875MiB/SHA `c788b09cdb4a0306498132033e08b52c5f1a12497fefde771ca6e47a58a5bd58`。实际装载DT1601695字节/SHA `c1c02b3018f8c6097ee30262957dd63d640a63499560c4ba5fd53056182def71`。

本轮7,927个control分配页、28个搬运列表页、14,224个目标页和10个bookkeeping页均经实际链/字段与保护范围核对；233个实际Image关键页匹配。新增缓存实际可在线性范围中核实，没有猜测vmalloc的PA；GIC、两SP、四TZ、GPU、源内核、ramoops、静态/header保留及载荷段的既定碰撞检查通过。外置PHY资源审计SHA `19d9a4ef45780076c308e15043fb9a18227da5a9899a4d9dcdb77dfa93c855f4`。ROOT在审计完成后记录真实开始/完成epoch，再以本源新地址调用一次冻结v2 observer；174次普通元数据读取完成，全部指定字段/身份和9段blob与首次观察一致，绑定SHA `5aecc4f4b6520ae86eaa3722785c2fefd5017c297390197ede6660e78b67a2be`。这仍是非原子元数据对照，不提供引用生命周期、完整覆盖或固件ACL证明。

随后唯一execute。目标raw pstore262132字节/2176个原始LF，SHA `85cadf1a801bb592a4335bf2c122ff65ee623aaa8ac955f298ec9c40ee7568a4`；满环开头已到约1.423秒，早期dynamic pool和nonce均未保存。LF1072/1089/1137有3处完整目标BID68e8。LF110明确first stage completed；LF183/184明确CRYPTO_SELF_TEST_COMPLETED和second stage started；LF1048在1.826秒记录APEX OnBootstrap done。LF1056为受损首个KUSR2，ESR92000005/FAR28字段局部完整；LF1068保存PC `7faa1138e4`、VMA start `7faa0b5000`、pgoff51的局部完整标量。随后linkerconfig及modprobe的lower-EL DABT已有正记录。末段LF2147完整给出boringssl_self_test64的reboot_on_failure，LF2162明确Restarting system with command 'boringssl-self-check-failed'。本轮不是用panic概括的硬复位；没有完整kernel panic正记录，也不因SEA未留存而宣布SEA全部修复。

KGPUM3的LF1057摘要前半count9/applied9/checked1/total42860544/CRC56e28f43、c681bb41与请求一致，但后半字段损坏。LF1058完整NOMAP位图为16个word、meaningful9、低9位1ff；LF1059 reserved位图含原始0x10坏字节，不能修成完整双位图。范围2..7载荷与本轮请求逐项相同，其中3..7整行完整；0/1记录损坏，范围8按协议省略。raw没有nonce，不能将外部装载证明替换成raw-only本轮归属认证，parser保持完整snapshot/replay均未证实。KUSR2取指行的attempted键和value也损坏，没有把疑似字节补成有效指令。

恢复stock后只读取得普通linker64文件，SHA `48b1b212bd6910c2829d7f57394c93e8a01b1012f440da78892e5228fb8d82b6`，GNU BID `ed80a6c1a83206dfdde6762ccb144f26`。按上述目标VMA标量条件换算，PC文件offset为af8e4，对应vsnprintf中的LDR x9,[x19,#0x28]，前一条读取TPIDR_EL0；LR低地址也可对应log_buf_print调用后的返回位置。这是对恢复系统普通文件的条件分析，不是认证目标实际文件、live代码字或TLS为0的根因。它支持继续检查动态链接早期错误/日志路径，不能直接归因CPU上下文丢失、GPU DMA或用户内存损坏；持久日志本身此前已有正常live文本与坏字的独立对照。

两份独立原字节审阅分别为`round35-independent-raw-review/audit.json` SHA `51ebc5253f03b378b49830f8c37667a4c0a1319fa59833a414cdf63976f9eb28`和`kgsl-binary-r35-source-helper-independent-review/round35-evidence.json` SHA `7fd4623c29e5866b34625a092671304e182b63547136f49bf48fd17e3a0be19e`。另对公开GPU unbind的实际f95模块作窄审，SHA `6570bf5eb90498786a2ee19121f0275b1bf1f8fe7519e0557c615bcdb6cc32db`：有driver-core生命周期管理，但实际remove先free_globals、后GMU/HFI清理，securefree错误不传回sysfs，因此不能把解绑返回或空globals当作安全停止/权限归还，也未尝试解绑或私有回调。

设备自动恢复安装版931f，当前UUID `e601cc28-9c73-4f43-99d7-24fadaba842b`；Android/root/watchdog0/kptr2、debugfs卸载、helper不存在及前后同UUID均已只读复核。安装版kexec_loaded接口不存在，未写成0。temporary boot/helper/load/execute严格各1，无额外恢复重启、刷分区或看门狗变化。ROOT聚合`round35/review.json` SHA `a5a5cf72f70e52aba3bffd385167126408826b1050d78e8b7178f2ac75799fa8`。主补丁冻结SHA仍为`2ff710c967cfdf8cf8247ac71d95d061fe93709730373f5d530cca42e55588b7`，仓库kernel未改，完整修复尚未完成。


R35后续只读文件身份补充：恢复系统的`/bootstrap-apex/com.android.runtime/bin/linker64`与当前`/apex/com.android.runtime/bin/linker64`完整SHA相同；但`/system/bin/bootstrap/linker64`另为SHA `81a85c43781a6225c8d18ce8edd43a67be00d9876be2b27e21d38566b6f162eb`、GNU BID `0fc74b188d4c4f47c68603240fc613d8`。两版RX都round成12d000、pgoff同51、条件PC af8e4指令相同，但条件LR179010处的函数/前一指令不同，不能用当前文件固定目标调用链。独审SHA `7e23ca1863bebff76c137bbbfeb9ca49eb87b0d0175374a2bfc73a177156bc4b`，ROOT追加报告`round35/linker64-file-identity-addendum.json` SHA `ce53e9d004dcd8a453639f4bd75fc1abe8c147438e93f75b68175a76b50886f6`。因此没有先改TLS/context-switch，也没有从这份条件反汇编认定内存或代码损坏。此补充只读普通文件，无新boot或execute。


## 五十六、装载接口对照：当前实测为file_load，不能直接把参数换成legacy

用户后续补充：已测试两条装载路径，在当前情况下没有区别。按此实测反馈，后续不再展开装载接口对照，继续定位目标内核的硬件交接与GPI事件命令超时。以下保留当时本诊断镜像的接口限制和历史核查记录。

用户提醒的两条装载路径是`kexec -c -l`（`kexec_load`，用户态提供entry和segments）与`kexec -s -l`（`kexec_file_load`，内核读取Image/initrd并构造segments/DT）；装载后均用`kexec -e`。近期各轮使用明确的`-s -l`，尚无本轮镜像、源状态和交接保护等价的`-c`运行对照。

实际4424源的`arch/arm64/kernel/machine_kexec.c:78`在`CONFIG_ARM64_KEXEC_GIC_TABLES && !file_mode`时返回EOPNOTSUPP，权威GIC补丁528–529行有同一限制。这是本诊断保护实现的限制，不是Linux普遍不支持旧接口。legacy在复制用户entry/segment描述符后就调用prepare；file先做内核Image装载、GIC/TZ捕获、GPU运输裁剪及保留属性注入。仅删拒绝分支不会补齐这些能力，故没有为试旧命令关闭保护。

两条接口随后共用machine_kexec_post_load、关机、machine_kexec和relocate代码；ARM64的file路径直接进入Image，legacy通常进入用户态工具准备的purgatory，再由其携带Image入口和DTB地址。这一差异值得对照，但不能把换接口当作设备已停止或安全权限已归还。旁边旧legacy实验曾保存入口及MMU前阶段标记，不是当前源或完整Android成功证据。下一步先核对旧记录与两路径可等价保留的内容，再决定最小对照方案；本节无新设备测试、build或补丁变化。

上述接口窄审已冻结于`gpu-handoff-architecture-review/source4424-legacy-file-comparison.json`，SHA `900b49b6b84abf0659e460ebdd58a340f19f0906f1dff0899f40c3114ac886c9`，包含实际4424拒绝分支及旧legacy记录的逐文件绑定。

## 五十七、第三十六轮源禁KGSL对照未通过：尚未装载或执行kexec

为区分源GPU遗留状态与后续装载/用户态问题，准备了只追加`module_blacklist=msm_kgsl`的临时源boot，目标68e8 Image保持冻结，计划不携带源黑名单、GPU nomap选择器或GPU blob，并要求目标恢复原厂KGSL及完整Android。源boot SHA `e2543dcc0ad951bc323edf4a60f44eff29be52a4c291a2673b03e5baed4189c8`，与R35父boot仅header偏移86..111的26字节不同，Image及其余字节完全相同。源端独审SHA `08a99a95de9705fb02ebcb5fe64a106b717b5e4a136045d6131b0b2b577c12e8`；23条源依赖及ROOT绑定通过。此对照允许源无GUI，但仍须root ADB、vendor.all.modules.ready=1、实际黑名单和精确694模块集合，不能把启动参数当作生效证明。

唯一fastboot boot返回0。standalone boot-source等待100次仍未取得ADB/模块就绪，exit1，未自动重试；随后只读看到设备已自动回到安装版931f，UUID `d91d837f-dc0c-46dd-ad1f-e06681d1edd3`，Android1/root0/watchdog disable0。临时boot/helper/load/execute计数为1/0/0/0，没有source验证、page_owner采样、helper、目标装载或跳转。实际recovery notes是931f，不能当作新源身份；源黑名单是否实际生效仍未取证。

原始`round36/pstore-after-sourceboot-timeout.txt`为262132字节、3398个原始LF，SHA `1cf1ce31c9e10833792dbf78b8c2ba4d6c7ac031447b052a94c9a3e95ef02360`。LF3235等行的完整release/BID字段确认4424确实运行；满环首行已是片段，LF2约44.314秒已在T1逐设备关机枚举。约44.360秒的I2C/SC8547 warning样式记录处于shutdown内部，不能当作初始故障。LF3232/3233的syscore/重启行受损，保留原字节不修补；随后有secondary CPU stop。全环未保存literal黑名单/KGSL记录或完整初始重启原因，缺行不证明源未执行、黑名单无效或某个硬件原因。独立原字节审阅SHA `b6e77e4c999bfdd5cb29c486cf213088c27dc1216a494f741732e31426e5be6f`。

只读恢复报告SHA `c83d02cac70e1bde7755a8ad204753662003dafc5cd50a16a6836571778e459e`；boot reason只给出reboot，未提供更细起因。ROOT汇总`round36/review.json` SHA `28cb7b4470083d83fea2dbe1788c8306dcab76e15d1c8a86b505339c05be974c`，state为`SOURCE_TEMPBOOT_FAILED_RECOVERED_STOCK_NOT_LOADED`。本轮不能得出GPU因果结论，R35的目标Android失败仍未修复。

R36运行器28个新增host用例及7个增量脚本窄审已完成，修正了未设置char*参数会输出`(null)`而非空串的后验分类问题，保留所有目标cmdline/模块/服务检查；独审SHA `64d8d8c14f6d142573de266530c513fe54ca426db7f9988146fa7ac84c772782`。由于没有真实源端absent/owner证据，未生成full runtime validation，也未使用这些脚本发起装载。下一步先保住源异常前因：复用已有权威`other_patch/kexec_shutdown_log_quiet_diag_6.6.89.patch`，在新out副本删除同一条逐设备EMERG打印，保留全部原关机调用和次序；这仅改善取证，不是GPU或kexec修复。没有刷分区、改变看门狗或修改仓库kernel源码。

## 五十八、第三十七轮源取证：KGSL已拒绝，BoringSSL通过，SF关键服务恢复链重启

先复用已有权威quiet补丁，SHA `2cacafea0871231d02fd096968e7af68eabb1416d331fa5e999c1d64ec1cb6c8`，仅在独立`kgsl-blocked-quiet-source/source`删除core.c的一条逐设备pr_emerg。单次正常build exit0/42.388秒，新GNU BID `72782e2196eb1c46c8c5205ccd93f2acf42de294`，Image37001728字节/SHA `8401f353d7477c87db2e54ef5734ad2ac25acbe574a928b1c5b6ff82579f4f9e`；manifest SHA `5ccd7a628b12dc91ff8b0fd43faacaf5594bc60461c701b0ec2b151ad3bd1324`。配置/LOCALVERSION、BTF、完整vmlinux.symvers和18个关键object逐字同4424；Module.symvers原/新均不存在，如实记录，没有重跑旧ABI套件。源ELF独审SHA `bd87025f1957a07f0cb886489d0a712507ce0d55e88c268b861f691036f1843f`。没有修改仓库kernel或旧source/build。

补查实际模块依赖发现R36预期集合遗漏：R35及当前stock的KGSL holders均为oplus_bsp_geas_system，后者没有再被其他模块持有；完整553行modules.dep也明确其依赖KGSL。两者反向闭包恰为KGSL+GEAS，故新源合同改为原695精确减这两个，即693，另检查GEAS module缺席，黑名单仍只写msm_kgsl。只读实证SHA `bb4f3a0563f8378efee18758669827bcfdd52f0da13ae78d1a2e085b00893bb9`。这是装载后果预测，不能据此宣称R36重启原因。

新boot SHA `8b3a4a3acee3f01fc48fe30aa20f49a07af8f115976271b6ba4bac28880b4964`，R36整4096字节header及非内核padding原样，只替换为新Image；delivery SHA `9bae95bbea8d78b421d0fedee14a715a15abeb4d47a581410aa4e93837856680`。source-only validation SHA `0a3033ba5765bd75feed33e137e8a81b0a741d5996c5267fb2ce3028b14a5bc9`，27依赖/7个新增host用例；standalone脚本SHA `5144f45aecf26287399de7255ad03937333240ce84ae69af7458a34398f5ff18`，增加逐次getprop原始输出及首次ADB四项只读采样。包/脚本独审SHA `57720a915b5a7900dbdb7e0845170554d5f4f8ad093b4d432dbb5c0927a95894`。没有新增内核功能或目标Image修改。

唯一临时boot返回0。首次ADB即读到7278 GNU及UUID `a99e7a65-a389-42df-a216-3ceb62eee3d2`，cmdline含唯一msm_kgsl黑名单；live dmesg1688051字节、18139个原始LF，SHA `b9b05c736b2802d43c49cad2ec8d26ea75744962d5d8720298c25939e86dcc28`。LF8753完整显示3.302322秒Module msm_kgsl is blacklisted；LF6591/16595分别完整记录boringssl_self_test64、boringssl_self_test_apex64的status0。LF14324在5.750350秒明确vendor.all.modules.ready已经设置。这个源端正记录不等于R35目标的BoringSSL异常已修复，也不是源实际693集合/driver/BTF验证通过。

等待循环仍用普通shell getprop，未读到1而在100次后exit1；首次ADB/root本身实际已可用，不能将超时误报为未入源。恢复stock后的成对只读检查也显示普通shell返回空行、su-root返回1；此对照是在恢复后测得，没有冒充源瞬时root属性采样。后续新脚本应改用既有su-root通道，仍须真实新源GNU/UUID门，不能把stock的ready1当作新源成功。

quiet pstore保留了约5.318秒至45.737秒的窗口，262132字节/1917个原始LF，SHA `fb5e5ebe75a9813441c168688ff669e6bc768f93ab773de4c3595dd432196d5d`。LF577..1122有反复surfaceflinger bootup critical相关记录，损坏的次数/信号不补。LF1142保留完整reason后缀`ERROR_CRITICAL_SERVICE_CRASHED_4_TIMES happened, try to recovery system`；该行prefix/时间有坏字，原始时间字节34.719121不改写为其他值。随后init shutdown、LF1495完整__arm64_sys_reboot栈帧及CPU stop支持有序恢复链。它定位了无GPU源的启动关键服务恢复问题，未确定SF具体故障指令、信号或排他的GPU底因。原字节独审SHA `a497da4c87e34597f007f7ad5b85067ed2121e026a2dfab95374828994f17858`。

源之后自动恢复stock931f，UUID `06a07a15-61c4-48ad-8395-6c47d1d59650`，Android1/root0/watchdog disable0。临时boot/helper/load/execute仍为1/0/0/0，本轮未发任何源服务控制；完整693/BTF/driver门未执行，未采owner、未生成full target validation。ROOT汇总`round37/review.json` SHA `8223a895601b8e02eea6b113a317ac7d57ec70858d104b4ce6eee5522fda3fa6`。下一轮只复用同boot，修root-ready轮询，并在全部真实源门禁通过后仅一次临时stop surfaceflinger，验证同UUID稳定至少60秒后再考虑目标测试；这仍会改变源工作负载，只是因果对照，目标必须恢复完整GPU/SF/system_server，不能当作正式交接修复。


## 五十九、第三十八轮：源GPU缺席对照仍失败，定位GPI事件命令超时后的空指针缺陷

没有修改Image或重新build。本轮复用7278源boot与68e8目标Image，source-only脚本改用su-root读取vendor ready；仅在真实源身份、693精确模块集合、八处KGSL/GEAS缺席、BTF和六个vendor GNU note通过后，记录请求计数并唯一执行`/system/bin/stop surfaceflinger`。实际源UUID为`a462744d-3679-42ac-9def-f1a2968ae8ff`；live dmesg LF8385/8388完整记录2.848178、2.854994秒KGSL被黑名单拒绝。十三次5秒间隔采样及最终复核通过，同UUID稳定60.439864秒。BTF/六note在stop前检查，稳定结束的复核范围较小；后续运行器仍保留原有新鲜BTF检查，不混称每个边界都重采六note。

真实page_owner小样本32768字节中有38条完整分配栈，采集后debugfs已卸载；它不提供完整PFN/ACL清单。本轮不采GPU SG，也不伪造空SG报告。所有源运行边界要求root ready、同UUID、原693模块或仅加helper后的694、八处缺席、核心黑名单及SF stopped/pidof退出1且输出为空。全目标validation SHA `b62a95a022fcd44972896dd8b626482d3051dfff6a1c45ac2ea13f313b7ea4cb`，18脚本/369绑定依赖、9项新增host用例；独审SHA `642d31f519cfe9e1e87e2cd16b27a8b2752e4ce3a2dd659af723f12fc59ee50b`，没有重跑旧ABI套件。

helper/load/execute各一次；另临时boot及SF stop各一次。实际装载nonce为`5f6ebdb92e50a89a`，DT SHA `3ca4d55560d965a31d5c91a350e57cbd43ad5ca1b37904184f105e358754e4a5`。目标两个GPU选择器、黑名单及chosen GPU blob缺席，源per-image arch.kgsl实际为NULL；initrd为原始18906392字节，SHA `5387d934444dd3d498be5ea1d72bb714c88ab6789a1c221f90be3bff3995ee31`，无GPU运输后缀。7927个control分配页、28个搬运列表页、14223个目标页、5个bookkeeping页及233个目标关键页通过；GIC、两SP、四TZ、ramoops和独立PHY资源检查全部保留。没有源服务控制传入目标，也没有改PHX或看门狗；PHX等待240秒的既往记录不能当作精确硬deadline。

唯一跳转后未启动目标Android，设备自动恢复stock931f、UUID `89361880-a80b-45c4-9066-e163cc02fc2b`。raw pstore262132字节/2817个原始LF，SHA `f689111c71917278d996c9d1d47f91c9451967d408b522467fb34f606bafa7df`。LF2540完整ESR96000005、LF2541完整current-EL DABT、LF2550完整地址0128及三级页表0、LF2571完整PC `gpi_send_cmd+0x180/0x2e8 [msm_gpi]`。LF2615 panic载荷与LF2816 watchdog-bite载荷保留，但行前缀损坏，未修字；LF2616完整停止secondary CPUs。只有LF2753一处完整目标68e8 token，该行其余字段也坏；没有完整nonce/run_id，不能把装载前证据当作raw-only的本轮身份认证。原字节独审SHA `264b1593bbf49f6410545e25245b864d3d011f0035496ca17de6879812372e00`。

从实际R38 initrd提取的msm_gpi.ko与恢复系统原厂文件逐字相同：SHA `058a56c5a88bbbcf02a804e609b255c1b4dc38e5fe87daedd9c7ec918a9f855e`，GNU `017204038f33bb4419f33057adedc2b0a2490c74`，与保存栈中的完整GNU字段相符。实际gpi_alloc_ev_chan在+74传x1=0、+78传cmd10，再调用gpi_send_cmd；被调函数保存第二参数至x22，wait_for_completion_timeout返回0后，无条件在+180执行`LDR x8,[x22,#0x128]`。这独立证明合法event NULL参数会在timeout错误路径被解引用，与保存PC/地址吻合。raw Code括号内为f94086c8（offset108），实际ELF为f94096c8（offset128），差0x1000；明确保留不一致，不能据此宣布live代码被修改。寄存器和调用栈多行损坏，未补成完整调用历史。实际指令/参考源码窄审SHA `f84257417b86f1c3831c70df8bb55676378615c30bd04a99fd3e22ff89a51d09`。

修正先保存为`other_patch/kexec_gpi_event_timeout_null_fix_6.6.89.patch`，SHA `b5f5c372dd61d8464dd8539e29d9e4a71dc0eccd9242ed14f639c2135aa6b9d0`：在原timeout IRQ状态读后，非channel命令报错并返回-EIO，避免进入channel-only fallback；原channel处理及成功路径保持。补丁针对[OnePlus vendor msm_gpi.c的固定版本4553152f](https://github.com/OnePlusOSS/android_kernel_oneplus_sm8750/blob/4553152f62a3bd9f39bb6d068a4d94a15a8c07fd/drivers/dma/qcom/msm_gpi.c)，common的gpi.c是另一个驱动，不能靠把此diff加入common主补丁使原厂KO生效。先保存补丁，再在独立out参考副本以fuzz0/offset0应用。实际原/新函数的主机回归使用模拟MMIO与等待值：旧函数合法NULL事件超时被null sanitizer拒绝，新函数返回-EIO且不读channel；五项既有成功/channel/无效命令返回及访问计数相同。每版7例通过预期检查。独审SHA `86c0113ffaf0b7d4c99ffa3e133a6a7ff99632c8e96ce5bf09bd22ba2b45e74b`；尚未编译完整vendor模块或部署设备，不把函数级回归写成模块ABI/运行验证。

实际GPI与SPI platform_driver的shutdown均为NULL，原device_shutdown不会代替调用remove/PM。固定vendor参考只有LE-VM分支主动清理旧分配状态，而实际目标节点不是LE-VM；这提供热状态/IRQ交接的具体待证方向，不能直接照搬其复位。下一观测应先保留原wait结果、已有IRQ/error_log与EV完成点，不能吞错或猜寄存器复位。生命周期窄审SHA `4e18f0e0da95ea65cb450619d73e999bfd0158fbbc0c263d63850ed30a61da21`。本轮不是R35用户态DABT的同一现场，未证明TLS已修复、GPU是唯一原因或首次completion为何缺失。

恢复核查SHA `95e8867e771eb9e22459af27ef15c15dcf08a999fcfcdde47653861ee2df6f0d`确认stock Android/root/图形服务、watchdog0/kptr2、helper缺席及debugfs卸载；stock kexec_loaded接口缺席未写成0。ROOT汇总`round38/review.json` SHA `c2420897b334097612a9e975a414406b860276667469a59d6cf3329cfff589d5`。仓库kernel及主kexec补丁未改，无刷分区；完整修复仍未完成。

## 六十、第三十九轮：当前同一68e8 Image普通临时启动完整Android通过

为避免把旧4646普通启动对照外推到当前Image，等长封装实际68e8/8824087 Image为新v4 boot，ramdisk0/signature0。头cmdline仅为`ramoops.console_flush_diag=1`，与已验证模板相比只去掉14字节page_owner参数；其余头、padding和尾部保持。新包37007360字节，SHA `01d496ca7ba1404f6d0f42045cdf5f4ca17e9f5b76a7b73df2d0cf262eaabec5`，verification SHA `bf743e30a5c78db1a10f73d949a49dd4bbb227ca03743ed749500d16e8e833de`，host-validation SHA `f0dbd0b6a64c83e8bdab2026356ebc2a2f4fd357b85603162d0b44d3c7b1bb46`。独立审阅及17依赖最终绑定SHA `1e6c01cf4bfd512a69367a5b937a768397686fc2c3f7a4252badb673eaffc942`。

ROOT核R38恢复身份后唯一fastboot boot，上传与boot返回0。实际新UUID `55cf2d03-4429-4d36-8115-8d3dbe078e57`、GNU68e8、release与完整BTF匹配，Android1/root/watchdog0/kexec_loaded0通过。695个原厂模块名集合精确等于R35 baseline；GCC/UFS/PHY/KGSL/GPI/SPI六个GNU note核实，GPI仍为原厂0172040、SPI00ff969、KGSLf95。SF服务running且有PID、system_server有PID、KGSL字符设备存在。没有chosen kexec标记或GPU blob，cmdline没有kexec_diag/blacklist/page_owner/信号诊断/源服务控制；核心黑名单为未设置格式。收尾再次核对同UUID、Android/root/图形服务、watchdog0/kexec0/kptr2、debugfs卸载及helper缺席通过，SHA `4e1afbd9ecc788716327c4cb5e9e714a956f15d4558c99f57156e52f54c26ae1`。

temporary boot/helper/load/execute计数为1/0/0/0，没有新的kexec、自动恢复或服务控制。ROOT汇总`round39/review.json` SHA `6f86f639ce8517c8cf7c44974f96f59e807acd49c0118d75eeb239df1ffe96bb`。这证明当前同一Image在普通启动、默认诊断关闭、原厂模块配置下能运行完整Android；不能单独区分热交接硬件状态与kexec专用参数/三个改装GCC/UFS/PHY模块。GPI空指针补丁本轮未编译/部署，普通启动通过不是该补丁的运行验证，亦不是kexec成功。

## 六十一、GPI模块构建基线与首次事件命令观测准备

对实际原厂GPI的后续指令核查补充了一个关键事实：R38崩溃前约半秒已保存SPI错误回调载荷，`cb_event=1`来自GPI全局错误中断路径；SPI回调唤醒自己的传输等待，不会完成GPI的cmd_completion。因此不能将首次超时简单解释为“完全没有中断”。保存行部分损坏，type2/code2在固定官方头文件中没有语义枚举，不能据此认定“已分配”或补造完整error_log。R38实际装载FDT与R39普通启动FDT中的两个GPI、QUP和SPI相关完整节点属性相同，均非LE-VM。证据和最小观测设计在`gpi-first-timeout-diagnostic-design/`。

已用固定455 vendor源码和实际68e8目标构建输入，在全新out目录原样构建msm_gpi.ko。没有手工覆盖CRC/vermagic：80条版本记录与原KO逐字相同，其中77条自然匹配目标，3条匹配实际qcom_ipc_logging导出；12条GPI导出CRC/namespace自然相同。全部50函数、操作性ALLOC节和2338条规范化运行重定位相同，8个共享结构的全部124字段offset匹配实际目标BTF。正常差异仅release/intree/scmversion、GNU BID和调试元数据。KO SHA `74121b9cc5d4b3a6db0d97c64f2b629aa4d076bedbb1b77d6d093e71ad2c813e`；producer验证SHA `ed0a5090de13f13ac951e18b5ea8ea7e5151e6c75fbdb2e4ea07fa2499ca99b5`，独审SHA `1fbaadc459c1d01377421a49203db0aeeb6f23d6912c409399651d7ad5ca7be8`。这是原样基线验证，尚未部署，不是超时修复。

新诊断先保存为`other_patch/kexec_gpi_first_event_trace_diag_6.6.89.patch`，SHA `bde050531ba3d5f4936cf6eb4c16c31e0008ecde257eb947332d61754f82d022`，再在新out副本依次应用NULL修复与本补丁，fuzz0/offset0，C SHA `0b379492340d9d1ba2eee782171c0181736a3a9d2060b40b456812cdf6ba503b`。只增加默认关闭、0400的kexec_first_event_diag参数，选择a00000/双SE4/SPI的首次NULL事件分配，最多各一条提交、原wait返回、global error、EV completion记录。没有新MMIO、reset、改等待时长或吞错，保留原read/clear/callback/complete顺序。IRQ记录可在wait关窗后输出，也可能观察到旧的pending IRQ；它不是硬件事务标识，缺行不能证明IRQ未到。独审SHA `ad5c0ac6d83cc94ff98205388dbba17eb982d8ba7738f44a81a3b64b58f84110`。

实际命令函数与诊断helper的主机模拟检查通过：7个默认关闭差分用例返回值和MMIO访问次数相同；4个开启用例验证超时仍为-EIO且不读channel、最多四条记录及已捕获EV资格可晚输出。报告SHA `7ff4096c7202a62477f934569f27b57b48308035734a247f3be9d542c52ef9a7`，没有将其当作实际IRQ、模块ABI或设备运行验证。

补丁版完整KO随后单次编译成功，SHA `94669c47c94ab1e0bc9391f9e124b35e1b00d4ed18b8381dbf5bd0be8b65e111`，GNU `44f9608d617294a503cf5c0ecebad2da5bccb9d6`，479976字节。原80 CRC保留，唯一新增param_ops_bool自然匹配目标0x327f4ed5，12导出及8布局124字段仍匹配；实际NULL守卫位于channel字段读之前，两个修改函数的MMIO调用投影未变。验证SHA `867acecb3a9308f19b1e6407384a6cccb2c0434a83c2565c21b4c842c1aa44b0`。主机验证器首次比较匿名section+addend绝对偏移时误断，保留失败记录并只修主机归一化；没有改C/KO或再次编译。

在既有三模块载荷中只替换GPI并为modules.options追加一行，其余547条newc记录逐字相同，全部549条顺序和其他元数据、modules.dep/modules.load保持。新压缩payload为19081359字节，SHA `0bc257e792e8985d19410dff425ee7582989ba5ab103403b2a16c2a1d21cb6eb`，manifest SHA `86cea07753b23547d733aa7b42f388a5fb7d21fdb100d79a69b0206cc67637e3`，尚不含bootconfig，仍要求真实源重采后追加。下一轮脚本与独立产物复核仍在准备；当前设备仍是R39普通启动的55cf/68e8，Android正常，原GPI/SPI与trace参数缺席已只读复核，触控输入软件注册记录SHA `2303894424f5d1324d5aa0ff8cdd3177c48b167f02056b45972088068e940c8f`，SPI实际绑定novatek,nf_nt36536的补充SHA `e3ada3e419e1f80d59b98098a4c09f4dbeff0a72e2efc68d940a7a7c748c4c7e`。本准备没有新boot、helper、load或execute，完整修复尚未完成。

## 六十二、第四十轮：单次跳转仍失败，新GPI采用路径存在遗漏，不能评价修复效果

新KO实码独审SHA `b3fbe1a1996854fe2eea1b24ee3fc7a02f0fe961dba1d63c15f0c4901a4a8889`、实际payload独审SHA `8b656c219172126f3ccb3e892c21d0a3931d5618741eaf9ba1b0310f09bee35a`通过。20脚本与13项新增host用例冻结SHA `555403bc8e390561e7fcb8fb825884050b28adcc4dd324e7858fee9d53995f62`；观察循环须fresh合法新UUID和root完成属性同时满足，元数据收尾再核同UUID与fresh完成1，不硬写完成。旧初稿保留revision1。运行链独审SHA `01009d976925d0934ca1ec56287baad0c2c7aef55d582f1ca3d11fcab9318a5b`，ROOT静态冻结75文件，SHA `8d9640f8582bf71289f30ef256617dfd09b893bf6822846e94af81a2fc9372ca`。

首次调用在重启前因foreign debugfs挂载停止，全部五个请求计数仍0。只读证据SHA `140c144ef3baa82679a65d68da33c8d3f7054dbbf599a0f7c51438c325945702`；确认同R39 UUID且该路径确为debugfs后，按已有可逆准备权限仅普通umount一次，无force/lazy，cleanup SHA `984decb365b8d690f1d8313b133429470a247f753e8dc07971954464c674b0f8`。完整失败日志归档preflight-attempt1，未重置计数或放宽守卫；随后才发起唯一实际boot。

同7278/8b3临时源实际boot成功，UUID `052b2ac3-d801-4563-820c-384c3ad16996`，693精确模块、八处GPU缺席、BTF及六secure/GH加原版GPI/SPI共八note通过。GPI/SPI身份及trace参数缺席在SF stop两端与后续各live边界复核。唯一SF stop后同UUID稳定60.472436秒；真实小样本owner与卸载debugfs通过。真实全运行validation SHA `6c7d33e27d1794921d696b834dce5136ed09ce9718a45119043d18d224791471`，377绑定依赖；没有重跑旧ABI套件。

helper/load/execute各1，另boot/SF stop各1，nonce `f5b8101627e20e75`。同68e8 Image、233关键页与288字节relocate，原GIC/SP/TZ/ramoops/PHY及全部控制页守卫通过。host实际initrd19083256字节，SHA `20106d22`前缀，gzip为0bc257；装载元数据起止86800000–87a32ff8与长度相符。该检查没有逐页hash整个已装载initrd内容，不能把host文件与装载长度闭环写成实际全部initrd字节或运行模块证明。相对R38，完整initrd增加176864字节、目的页增加43；bootconfig文本相同但NUL padding少2字节。GIC实测分配地址、TZ display保留、随机种子及Gunyah节点亦自然变化，不能宣称严格单变量或归因为故障。范围窄审SHA `48f5e934f8e3824d21ae73a56a2672814c3d5929f391f49a4a3ae03ce8c022b4`。

目标Android未完成，设备自动恢复stock931f，UUID `16b13af7-b3d4-48e7-a4e5-d9e09d87d4af`。仅有console-ramoops-0一个pstore记录，262132字节/1894个原始LF，SHA `71e22c265731434aecbb7efb61ec586e4a03b0b87223339d16cfd170a0a2806e`，重复读取相同。完整nonce、目标BID、新GPI BID、KGPICMD1、panic/首个异常字段均未取得；LF1404仅KUSR2字面量完整，其余类型/ESR/PC/VMA损坏，不能重构成用户态DABT。存量before-pstore已有旧68e8身份，不能补到post。第一次ADB回连两端UUID与notes均明确stock，GPI为原0172040、参数不存在，不能当目标live log。原字节独审SHA `6a1eb3e588f0b0da705666923d8c727d380e20bc166352132dd26ce556bb03a7`。

事后发现之前漏查的模块选择环节：实际host initrd内只有一个94669/44f9新GPI及290字节四行options，无后archive旧KO覆盖，但normal modules.load的153项及155项硬依赖闭包均无GPI/SPI；GPI仅在recovery清单第170行。仅替换文件不能保证normal采用，后续vendor加载原副本是具体候选。实际bootconfig mode=normal、force_normal_boot=0且CPIO无recovery executable；不能把0当recovery证明。模块包/采用窄审SHA `83a422d6fb47897c4a5cecb1d42294eb2bd06b1c043e3a57f156b096f47e20ea`，独立加载链审阅SHA `c1d044772d8b2899a21d240d227659d138897ca625cc6b2a00d4f6bba52d11a1`。本轮不评价NULL修复是否有效，也不宣布首次命令超时已跨越。

恢复只读核查SHA `6665879faed1bf498db77171a0fe26cd17a361c9e236a4f5ce7df9f9d4d02a7d`确认stock Android/root/图形服务、watchdog0/kptr2、helper缺席及同UUID；kexec_loaded接口缺席。新的foreign debugfs正常挂载已原样记录，未再卸载。ROOT汇总`round40/review.json` SHA `3f8766d3c993f76a9520d47bcabfe6eaab35b2ce4fd761c8782e9ed011bb5d85`。本轮到此关闭，无第二次execute，无分区或看门狗变化，仓库kernel与主补丁未改。

## 六十三、下一轮仅补normal GPI模块选择，不同时改源GPI状态

最小修正先保存为`other_patch/kexec_gpi_initramfs_load_diag_6.6.89.patch`，SHA `24119953687e09ac68048facb88cedcda6e6b1e0a9c5ffaa25ecc164b70b8813`，再在新out副本fuzz0/offset0应用：normal modules.load末尾只增加`msm_gpi.ko`一行，2600→2611字节，SHA `ff5116fb9eb9a12dfdaead42fbda2efc74779c7b89f636019e9d0922d0a79753`。原硬闭包已包含GPI所需的14个依赖，追加后155→156，仅新增GPI，无需改dep或重编KO。parallel=true意味着末行不保证最后执行；把GPI纳入first-stage集合会前移其加载/probe时机，是明确的实验变化。实际内核同名LIVE模块返回EEXIST，后续vendor loader不能直接覆盖已成功加载的新版，但首载失败仍可落回原版，验收仍须实际新GNU44f9和参数Y。

新`gpi-normal-load-payload`保持四KO、290字节options与全部dep不变，549条记录仅normal modules.load变化，余548条raw逐字相同。gzip19081368字节，SHA `e2f781e3f6ffc46a084cf211eb51930fcfc4da0ba74ba0edeeabed180a0e3f78`，manifest SHA `4def33879e33520b81209b4192b6cd11f57cfee24433a756ad8fe32a29127150`。仍不含bootconfig，实际源后重采；R41运行器尚在准备，尚未新boot/load/execute。源继续同7278/8b3、仅KGSL黑名单与693模块，不同时加入GPI source blacklist；所有原交接保护保留。

## 六十四、第四十一轮：源ADB身份通过，单次跳转后有人工fastboot介入，未取得新GPI运行证明

R41只使用上一节的新加载清单载荷，Image与四个KO不再改动。运行链独审SHA `c196d52d50418366dd1acb825957f67157f8717a1b3881d8f67a7bf483570218`，ROOT静态冻结83文件，SHA `279f731d7fbbcaa0b214e62f1c968a24c976d37eff7cb5cdbc8a74bc9285694c`。发请求前确认同R40恢复stock身份，仅一次普通卸载已知foreign debugfs；没有force/lazy，准备记录SHA `8e5da39bec8c7a44c37e27e4a22c13ab9672a8890c5e6f0dc00e0ad435c8efd0`。

按北京时间，20:03:09 fastboot boot返回成功；20:03:21经ADB实际核实源7278、新UUID `f632eed3-0bd9-44d3-9a6e-649cbd833c4d`、BTF、精确693模块及GPU缺席。源验证记录SHA `1860ea1b62a6975dc5c3607a4c86992eb76f332c37392f161757517536034397`。源的Android完成属性为空；本源有意禁用GPU，随后唯一stop surfaceflinger，同UUID稳定60.475秒。这里的成功仅指运行中的源内核/ADB门通过，不代表屏幕显示或完整Android启动成功。用户看到fastboot画面，不能用ADB证据替代屏幕观察；旧画面保留只是可能解释，没有直接验证。

实际full validation SHA `affd4a1370cce9ef474c600fb0398bbd48f4db220ee9e25e6f2a10b1bc6b41c2`，379依赖；真实owner小样本、原GIC/SP/TZ/ramoops/PHY守卫、233目标关键页和实际装载元数据通过。nonce `9992c1bb1822e215`，host initrd19083268字节，normal清单ff511及新GPI请求闭环通过；仍没有逐页回读整个已装载initrd，host文件/装载长度不是运行采用证明。boot、SF stop、helper、load、execute请求各1，20:05:15执行唯一kexec。

首个新UUID的ADB回连明确为安装stock931f、UUID `73f15c91-ae79-4aab-b80f-f0d2f011ea46`，GPI原0172040，诊断参数不存在，不能标为目标68e8或新版GPI的运行记录。20:05:32 USB曾显示ADB在线、fastboot列表为空；后续等待没有观察到Android完成，最终ADB离线、fastboot在线。用户确认其间手动重新进入fastboot，精确时间未知。因此不能把fastboot终态、等待超时或首次回stock的触发原因归为完整的自然失败链，更不能把本轮当作NULL修复效果验证。用户报告与主机证据对照在`round41/screen-state-discrepancy-review.json`，保留原始版本。

旧采集器首次ADB回连只保存身份和dmesg，pstore要等Android完成后才读；本轮未走到该步，没有`pstore-after-exec.txt`。随后的只读尝试全部因设备缺席失败，空的前后缓冲相等不构成同UUID，已明确记为未取得身份或日志。为收尾仅一次`fastboot reboot`正常启动已安装系统，无新诊断boot或kexec；当前stock931f、新UUID `5719bd82-5a19-4cb0-a3d3-2d036f861682`、Android1/root/图形服务/watchdog0/kptr2、helper缺席和kexec接口缺席通过。恢复记录SHA `9eee1f494e1e7568fc873557bf484665b010e986f557752c349ba273082fee0f`，新foreign debugfs挂载仅记录未卸载。

恢复后console为262132字节/1790个LF，SHA `f5154810597ece16f61ba872203c77b6d93538632e2b199ede3ec3837c179aa4`；完整本轮nonce、68e8、GPI44f9及KGPICMD1均无。它已跨过人工fastboot与额外一次stock启动，不能预先归属目标现场。后续先改首接触采集，使ADB首次回连即保存原始pstore、失败也保留，并用成功且合法非空的UUID前后夹定；本轮不重跑。仓库kernel源码及主kexec补丁未改，首次GPI超时原因与完整启动修复仍未完成。

源/装载/执行边界独审SHA `9f39e4894ca3b9721ce17d017adc77f0ad12acf1f48e6e36485e6ba572c957a6`，原字节及恢复身份独审SHA `38edbd9bd7364a7b08ee1a9f1244135fc7b6915d4b00d50ca1c15bd343a0d8cf`。ROOT汇总`round41/review.json` SHA `71b6f4fec91563faf8dc29d09ecb5612ee6fcedd33b3cd092dabc369d97d80d1`，终态为目标运行未验证且有人工介入；原runner终态逐字快照单独保存，最终状态不再冒充等待中的源或目标成功。

后续首接触采集候选已保存于`gpi-early-pstore-capture-review/revision2/`，文件SHA `bada967d86ca731ed0ad307137faaecdfae0e011cfebc6387f99b08e578b53a0`。采集顺序为boot-before、pstore、立即boot-after-pstore并保存checkpoint，之后才读大dmesg；12项假远端测试验证原采集函数，revision2保持该函数逐字相同并补回原touch验收接口，静态报告SHA `977996caf14fea200fd4116c83711fbb10a4adc51ab54a0b5ddfbf2e28e17c63`。尚未集成未来caller或部署设备，不是新的运行验证。收尾fresh只读核查SHA `48eebc6a9947e8181503cd1b20f16977e56c480ec285d3661126f62c24be0c46`再次确认同5719/stock、Android1及图形服务正常，未发送任何新boot/load/execute。

## 六十五、第四十二轮：单次跳转后自动进入fastboot，目标身份及第一故障仍未知

本轮仅修改首次ADB回连的日志采集顺序，Image和四个目标KO与R41相同。源7278、UUID `fafaed69-96b0-4bb1-8491-9a15cbe8d380`的693模块和BTF通过，但源仍有GPU黑名单且随后停止SurfaceFlinger，Android完成属性为空。因此这里只能确认诊断内核及ADB运行，不能称为完整Android或屏幕正常。boot、SF stop、helper、load、execute各一次。

实际装载nonce `92363ab1bd2cf98f`、目标68e8、233关键页及原有装载守卫通过；这不证明重定位后的完整性或四个模块的运行采用。唯一execute后未保存自然回连的新目标ADB。用户明确答复“没有操作，是自动重启”，主机同时观察到ADB缺席、fastboot在线；本轮与R41的人工fastboot介入不同，但尚不清楚是哪一种复位机制。

仅一次普通fastboot reboot恢复已安装的931f，UUID `d8c53019-2f45-4c1f-a999-d0667971464d`，Android/root/GPU/SF正常；没有再执行kexec。此后的pstore虽读取到262132字节，完整本轮nonce、目标68e8、新GPI44f9及KGPICMD1均未出现，不能据此断言目标没进入、GPI没采用或异常已修复。该次pstore还跨过恢复启动，其产生者不确定。原始字节未修补、寄存器和旧故障栈未挪用。

ROOT汇总`out/kexec-boot-fix/round42/review.json` SHA `745583788a085c37998108b4180109b0d0025a5049c5463cc750034d14fe2a68`；runner原始终态另存快照，最终状态明确为自动fastboot、目标未验证。用户质疑诊断自身造成回归是合理的待查项：ABI/CRC通过、普通目标启动通过均不能排除kexec专用参数、内核路径和四个改装模块的行为问题。暂不继续使用GPU缺席的旧流程。

## 六十六、第四十三轮：撤销源GPU禁用，完整Android与桌面触摸通过

先保存`other_patch/kexec_source_full_graphics_boot_6.6.89.patch`，再生成独立的`source-full-graphics-baseline/kexec-source-full-graphics-boot.img`。仅将boot头命令行由`ramoops.console_flush_diag=1 page_owner=on module_blacklist=msm_kgsl`改为`ramoops.console_flush_diag=1`；Image、大小字段、ramdisk及其余字节保持不变。旧GPU缺席runner不得复用；本轮无停止服务、helper、load或execute操作，没有刷分区或改变watchdog。

唯一普通临时boot实测源GNU7278，新UUID `8212bfe6-d5ed-4c8b-be3f-dbecf7d93a1e`，BTF匹配，精确695个原模块齐全；原GPU `msm_kgsl` GNU `f95e145481d6423dffac1f0cb3e1236dfbb1b753`及GCC/UFS/PHY/GPI/SPI五个原模块身份全部匹配。`sys.boot_completed=1`、SurfaceFlinger running且有非空PID、system_server有非空PID、`/dev/kgsl-3d0`为字符设备，黑名单参数为null、kexec_loaded=0、watchdog disable=0，前后UUID一致。用户另外确认“桌面和触摸都正常”。记录位于`out/kexec-boot-fix/round43/`。

该对照确认：GPU禁用及SF停止流程干扰了源系统的完整使用，旧源“ADB可用”不能冒充“Android正常”。它没有执行kexec，不能解释或证明修好了目标跳转后的复位；R42目标参数本身没有GPU黑名单，也没有继承源SF停止状态。7278 Image仍含此前编译进去的诊断/交接改动，恢复图形并不等于已换回干净源内核。

为建立未改目标对照，已在R43前仅只读提取当前已安装、可正常启动的931f版本：`installed-kernel-baseline-audit/installed-boot-a.img`为100663296字节，SHA `3b6d3985f2fe5acbbbb326b54ecfa8f27b4f7d26e1e4e8c143419aeeafc458ef`；原始ARM64内核`installed-kernel-payload.bin`为37345792字节，SHA `c36d8c0f7d5f03ce3cc42c98b383166bc29ff838e677b765e56448d67211e980`。读取前后均为d8c5/931f，未写设备。它是已安装的Gold_bug自定义版本，不能称为未经修改的OEM内核；尚未用该原始目标执行新的kexec。
