# 未随日志包复制的大制品

以下仍在原主机。将仓库交给别人并不等于把这些二进制或全部out依赖交给别人；如需精确复现，可另行取出对应制品，或按构建身份和配置重新生成。

| 原主机路径（相对仓库） | 内容及边界 |
| --- | --- |
| `out/kexec-boot-fix/source-full-graphics-baseline/kexec-source-full-graphics-boot.img` | R43完整GPU普通临时boot包，Image7278不变；header SHA等见包内manifest。 |
| `out/kexec-boot-fix/kgsl-blocked-quiet-source/build/arch/arm64/boot/Image`、`out/kexec-boot-fix/kgsl-blocked-quiet-source/build/vmlinux` | 源7278与符号。完整构建目录含继承诊断修改。 |
| `out/kexec-boot-fix/kgsl-binary-target/build/arch/arm64/boot/Image`、同级构建根`vmlinux` | 目标68e8与符号，不等于最小未改目标。 |
| `out/kexec-boot-fix/installed-kernel-baseline-audit/installed-boot-a.img` | 只读提取已安装版本，不是OEM原厂镜像。 |
| `out/kexec-boot-fix/installed-kernel-baseline-audit/installed-kernel-payload.bin` | 原始ARM64 Image，BID931f、SHA c36d8c0f…，尚未做新的kexec对照。 |
| `out/kexec-boot-fix/round30/` 中page_owner大档案 | 原压缩档约44MB、解压约1GB，采集exit124不能当EOF。包内lookup保留全档hash、偏移及实际807B正匹配。 |
| 各target payload目录的initramfs及原始完整源树/工具链 | 未随包复制。manifest可能引用其他绝对路径，其存在和哈希不是当前可直接重跑的保证。 |

本包中的3个小型KO是例外，目的是让接手者离线核对关键故障指令和构建差异，不应据此直接装入当前设备。
