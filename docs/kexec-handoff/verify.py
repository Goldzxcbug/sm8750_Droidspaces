#!/usr/bin/env python3
"""Verify local handoff files. No device or network operations."""
from pathlib import Path
import hashlib
import json
import sys

root = Path(__file__).resolve().parent
manifest = json.loads((root / "manifest.json").read_text(encoding="utf-8"))
errors = []
seen = set()
for row in manifest["files"]:
    rel = row["path"]
    path = (root / rel).resolve()
    try:
        path.relative_to(root)
    except ValueError:
        errors.append(f"outside package: {rel}")
        continue
    if rel in seen:
        errors.append(f"duplicate: {rel}")
        continue
    seen.add(rel)
    if not path.is_file():
        errors.append(f"missing: {rel}")
        continue
    data = path.read_bytes()
    if len(data) != row["bytes"] or hashlib.sha256(data).hexdigest() != row["sha256"]:
        errors.append(f"bytes or SHA-256 mismatch: {rel}")
if len(seen) != manifest["file_count"]:
    errors.append("manifest count mismatch")
checksummed = 0
for line in (root / "SHA256SUMS").read_text(encoding="utf-8").splitlines():
    want, rel = line.split("  ", 1)
    path = (root / rel).resolve()
    try:
        path.relative_to(root)
    except ValueError:
        errors.append(f"checksum path outside package: {rel}")
        continue
    if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != want:
        errors.append(f"package checksum mismatch: {rel}")
    checksummed += 1
if errors:
    print("\n".join(errors), file=sys.stderr)
    sys.exit(1)
print(f"PASS: {len(seen)} files, {manifest['total_original_file_bytes']} original bytes; {checksummed} package checksums")
