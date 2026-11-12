#!/usr/bin/env python3
"""R2 垃圾回收：裁剪旧清单，再删掉 files/patches 里没有任何清单引用的对象。

执行顺序：
    ① 裁剪清单：按清单自带的 <GenTime>（生成时刻）保留最新 WINDOW+1 份，更老的删掉
       （WINDOW 来自本仓库变量 PATCH_WINDOW，默认 3 => 保留最近 4 份）
    ② 用**剩下的**清单算 live 集，再删 files / patches 里的垃圾

为什么用 GenTime 而不是 rclone 的 ModTime：rclone 对 S3 对象报的 ModTime 是上传时本地文件的
mtime（写在 X-Amz-Meta-Mtime 里），重新上传或从备份恢复都会让它漂移；而 <GenTime> 是
XmlGenerator 生成清单那一刻打的时间戳，和发布顺序严格一致。缺 GenTime 的清单按最旧处理。

规则（唯一事实来源 = 剩下的清单）：
    files/<md5>.bin             md5 不在任何清单里                 -> 删
    patches/<old>_<new>.bin     new 不在任何清单里                 -> 删

补丁只看 new 侧：客户端拼补丁名用的是「本地文件 MD5（old）+ 清单里新文件 MD5（new）」，
old 侧来自客户端自己硬盘、不需要服务端还留着那份清单。要求两端都在会白删掉"老版本 -> 最新版"
的补丁，反而砍掉长区间增量更新的能力；new 不在任何清单里的补丁才是真没人会请求的。

只动 files/ 与 patches/；manifests/ 只按上面的窗口裁剪。重复执行幂等。

已知且**故意不做保护**的情况（团队决定）：如果回滚后 metadata 的 Current 指向一个已经被裁掉的
老版本，那份清单会被一起清掉；此时客户端拿不到清单，更新会失败，需要重新发布/补回清单后再跑。
Updater 对"补丁缺失"会回落完整文件下载，但对"清单 404"没有兜底，所以回滚期间别跑 GC。

由 .github/workflows/r2-gc.yml 手动触发调用。环境变量：
    R2_BUCKET  R2_BASE_PATH  R2_ENDPOINT  R2_ACCESS_KEY_ID  R2_SECRET_ACCESS_KEY  WINDOW
可选：
    GITHUB_STEP_SUMMARY  设置时追加一份 markdown 摘要
"""
from __future__ import annotations

import os
import re
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

REMOTE = "r2ci"                      # 临时 rclone conf 里的远端名
MD5_RE = re.compile(r"<MD5>([0-9a-fA-F]{32})</MD5>")
GEN_TIME_RE = re.compile(r"<GenTime>(\d+)</GenTime>")
FILE_RE = re.compile(r"^([0-9a-fA-F]{32})\.bin$")
PATCH_RE = re.compile(r"^([0-9a-fA-F]{32})_([0-9a-fA-F]{32})\.bin$")

SFLAGS = ["--s3-no-check-bucket"]
SUMMARY_LINES: list[str] = []


def log(msg: str = "") -> None:
    print(msg, flush=True)


def section(title: str) -> None:
    log(f"\n=== {title} ===")


def note(line: str) -> None:
    """同时进控制台与 step summary。"""
    log(line)
    SUMMARY_LINES.append(line)


def require_env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        raise SystemExit(f"缺少环境变量 {name}")
    return value


def write_rclone_config(path: Path) -> None:
    path.write_text(
        f"[{REMOTE}]\n"
        "type = s3\n"
        "provider = Cloudflare\n"
        f"endpoint = {require_env('R2_ENDPOINT')}\n"
        f"access_key_id = {require_env('R2_ACCESS_KEY_ID')}\n"
        f"secret_access_key = {require_env('R2_SECRET_ACCESS_KEY')}\n"
        "region = auto\n",
        encoding="utf-8",
    )


def rclone(*args: str) -> str:
    proc = subprocess.run(["rclone", *args], capture_output=True, text=True, encoding="utf-8")
    if proc.returncode != 0:
        raise SystemExit(
            f"rclone {' '.join(args)} 失败 rc={proc.returncode}\n"
            f"stdout:\n{proc.stdout}\nstderr:\n{proc.stderr}"
        )
    return proc.stdout


def list_objects(path: str) -> list[tuple[int, str]]:
    """列目录下的文件，返回 [(字节数, 文件名)]。一次 lsf 同时拿到大小与名字。"""
    out = rclone("lsf", path, "--files-only", "--format", "sp", *SFLAGS)
    rows: list[tuple[int, str]] = []
    for line in out.splitlines():
        line = line.strip()
        if not line:
            continue
        size, _, name = line.partition(";")
        if not name:
            size, _, name = line.partition(" ")
        rows.append((int(size), name.strip()))
    return rows


def read_manifests(root: str) -> list[tuple[int, str, str]]:
    """下载全部清单，返回 [(GenTime, 文件名, 正文)]，按生成时刻倒序（最新在前）。"""
    names = [name for _, name in list_objects(f"{root}/manifests")]
    entries: list[tuple[int, str, str]] = []
    for name in names:
        text = rclone("cat", f"{root}/manifests/{name}", *SFLAGS)
        match = GEN_TIME_RE.search(text)
        gen = int(match.group(1)) if match else 0
        entries.append((gen, name, text))
    entries.sort(key=lambda entry: (entry[0], entry[1]), reverse=True)
    return entries


def delete_many(path: str, names: list[str]) -> None:
    if not names:
        return
    fd, listing = tempfile.mkstemp(prefix="r2-gc-", suffix=".txt")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            fh.write("\n".join(names) + "\n")
        rclone("delete", path, "--files-from-raw", listing, "--transfers", "16", *SFLAGS)
    finally:
        os.unlink(listing)


def dead_files(objects: list[tuple[int, str]], live: set[str]) -> list[tuple[int, str]]:
    return [(size, name) for size, name in objects if (m := FILE_RE.match(name)) and m.group(1).lower() not in live]


def dead_patches(objects: list[tuple[int, str]], live: set[str]) -> list[tuple[int, str]]:
    dead = []
    for size, name in objects:
        match = PATCH_RE.match(name)
        if not match:
            continue
        new = match.group(2).lower()
        if new not in live:
            dead.append((size, name))
    return dead


def human_mb(total: int) -> str:
    return f"{total / (1024 * 1024):.1f} MB"


def human_time(gen: int) -> str:
    if gen <= 0:
        return "无 GenTime"
    return datetime.fromtimestamp(gen, tz=timezone.utc).astimezone().strftime("%Y-%m-%d %H:%M:%S")


def main() -> int:
    bucket = require_env("R2_BUCKET")
    base = require_env("R2_BASE_PATH").strip("/")
    keep_count = int(os.environ.get("WINDOW", "3")) + 1

    cfg = Path(tempfile.mkdtemp(prefix="r2-gc-cfg-")) / "rclone.conf"
    write_rclone_config(cfg)
    os.environ["RCLONE_CONFIG"] = str(cfg)

    root = f"{REMOTE}:{bucket}/{base}"
    log(f"目标: {root}")
    log(f"清单保留: 最新 {keep_count} 份（WINDOW+1）")

    section("裁剪旧清单")
    entries = read_manifests(root)
    kept = entries[:keep_count]
    pruned = entries[keep_count:]
    note(f"清单 {len(entries)} 份；保留 {len(kept)} 份，删除 {len(pruned)} 份")
    for gen, name, _ in pruned:
        log(f"  - 删除 {name}  ({human_time(gen)})")
    for gen, name, _ in kept:
        log(f"  = 保留 {name}  ({human_time(gen)})")
    delete_many(f"{root}/manifests", [name for _, name, _ in pruned])

    section("清单（live 集合）")
    live: set[str] = set()
    for _, _, text in kept:
        live.update(m.group(1).lower() for m in MD5_RE.finditer(text))
    note(f"生效清单 {len(kept)} 份；live MD5 {len(live)} 个")

    section("files")
    file_objects = list_objects(f"{root}/files")
    unknown_files = [name for _, name in file_objects if not FILE_RE.match(name)]
    dead_f = dead_files(file_objects, live)
    note(f"files: 共 {len(file_objects)} 个，待删 {len(dead_f)} 个，{human_mb(sum(s for s, _ in dead_f))}")
    for size, name in dead_f:
        log(f"  - {name}  {size} B")
    if unknown_files:
        note(f"files: 跳过 {len(unknown_files)} 个不识别的名字（不动）")

    section("patches")
    patch_objects = list_objects(f"{root}/patches")
    unknown_patches = [name for _, name in patch_objects if not PATCH_RE.match(name)]
    dead_p = dead_patches(patch_objects, live)
    note(f"patches: 共 {len(patch_objects)} 个，待删 {len(dead_p)} 个，{human_mb(sum(s for s, _ in dead_p))}")
    for size, name in dead_p:
        log(f"  - {name}  {size} B")
    if unknown_patches:
        note(f"patches: 跳过 {len(unknown_patches)} 个不识别的名字（不动）")

    section("删除")
    delete_many(f"{root}/files", [name for _, name in dead_f])
    delete_many(f"{root}/patches", [name for _, name in dead_p])
    note(f"已删除 files {len(dead_f)} 个，patches {len(dead_p)} 个")

    summary = os.environ.get("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as fh:
            fh.write(f"### R2 GC — `{base}`\n\n")
            for line in SUMMARY_LINES:
                fh.write(f"- {line}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
