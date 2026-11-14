#!/usr/bin/env python3
"""Check the 6.6.89 patch sequence against an unmodified kernel tree."""

import argparse
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


def main():
    repo = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=repo / "kernel")
    parser.add_argument("--kexec-patch", type=Path,
                        default=repo / "other_patch/kexec_kabi_6.6.89.patch")
    args = parser.parse_args()
    source = args.source.resolve()
    patches = [
        (repo / "droidspaces_patch/fix_cgroup_limits_kabi_6.6.89.patch", 0),
        (repo / "droidspaces_patch/fix_sysvipc_kabi_6_7_8.patch", 3),
        (args.kexec_patch.resolve(), 0),
    ]
    assembly = [
        "arch/arm64/kernel/head.S",
        "arch/arm64/kernel/cpu-reset.S",
        "arch/arm64/kernel/relocate_kernel.S",
    ]
    paths = set(assembly)
    for patch, _ in patches:
        paths.update(re.findall(r"^\+\+\+ b/(\S+)", patch.read_text(), re.M))

    with tempfile.TemporaryDirectory(prefix="kexec-patch-test-") as directory:
        target = Path(directory)
        for name in paths:
            relative = Path(name)
            if relative.is_absolute() or ".." in relative.parts:
                raise ValueError(f"Unsafe patch path: {name}")
            destination = target / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            if (source / relative).is_file():
                shutil.copyfile(source / relative, destination)

        for patch, fuzz in patches:
            result = subprocess.run(
                ["patch", "-p1", "--batch", "--forward", f"--fuzz={fuzz}",
                 "--no-backup-if-mismatch"],
                input=patch.read_bytes(), cwd=target, capture_output=True,
            )
            if result.returncode:
                raise RuntimeError(result.stdout.decode() + result.stderr.decode())
            print(f"PASS: {patch.name} (fuzz limit {fuzz})")

        for name in assembly:
            if (source / name).read_bytes() != (target / name).read_bytes():
                raise AssertionError(f"Boot/reset assembly changed: {name}")
        if (target / "arch/arm64/include/asm/kexec_trace.h").exists():
            raise AssertionError("Unexpected fixed-address trace header")
        print("PASS: primary boot, reset and relocation assembly unchanged")

        name = "arch/arm64/kernel/machine_kexec.c"
        start = "\tlocal_daif_mask();"
        end = "static void machine_kexec_mask_interrupts"
        original = (source / name).read_text().split(start, 1)[1].split(end, 1)[0]
        patched = (target / name).read_text().split(start, 1)[1].split(end, 1)[0]
        if original != patched:
            raise AssertionError("Final handoff changed after masking exceptions")
        if list(target.rglob("*.rej")):
            raise AssertionError("Patch rejects left behind")
        print("PASS: final handoff unchanged after masking exceptions")


if __name__ == "__main__":
    main()
