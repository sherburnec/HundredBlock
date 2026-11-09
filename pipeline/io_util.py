"""Atomic writes and completion markers (safe to re-run after an interruption)."""
import hashlib
import json
import os
from pathlib import Path
from typing import Any, Iterable


def atomic_write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(text, encoding="utf-8", newline="\n")
    os.replace(tmp, path)


def write_json(path: Path, obj: Any, *, pretty: bool = False) -> None:
    if pretty:
        text = json.dumps(obj, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    else:
        text = json.dumps(obj, ensure_ascii=False, separators=(",", ":")) + "\n"
    atomic_write_text(path, text)


def write_jsonl(path: Path, rows: Iterable[Any]) -> int:
    lines = [json.dumps(r, ensure_ascii=False, separators=(",", ":")) for r in rows]
    atomic_write_text(path, "\n".join(lines) + ("\n" if lines else ""))
    return len(lines)


def read_jsonl(path: Path) -> list[Any]:
    with open(path, encoding="utf-8") as f:
        return [json.loads(line) for line in f if line.strip()]


def params_key(*parts: Any) -> str:
    return hashlib.sha256(json.dumps(parts, sort_keys=True, default=str).encode()).hexdigest()[:16]


def done_marker(path: Path) -> Path:
    return path.with_name(path.name + ".done")


def is_done(path: Path, key: str) -> bool:
    m = done_marker(path)
    return path.exists() and m.exists() and m.read_text().strip() == key


def mark_done(path: Path, key: str) -> None:
    atomic_write_text(done_marker(path), key + "\n")
