"""Check or update all registered Content map CRCs (Python 3.9+, stdlib only).

Retail 0x52C180 reads the map file in 4096-byte blocks and folds each unsigned
byte with 0x92F110: h = ((h << 1) + (h >> 31) + byte) & 0xFFFFFFFF, starting
at zero. This is not polynomial CRC32. Hash the stored .map bytes without
decompressing them; map.str, previews and compiled map assets are not included.

Run after adding a map's MapMetaData entry or changing its .map file. All
references are resolved and checked before writing; only CRC attribute values
are replaced. Comments, whitespace, encoding and other XML values are retained.
"""

import argparse
from pathlib import Path
import re
import sys
from xml.parsers import expat


MAP_TAG = "uri:ea.com:eala:asset}MapMetaData"
START_TAG = re.compile(rb'''<(?:[^>"']|"[^"]*"|'[^']*')*>''')
ATTRIBUTE = re.compile(rb'''([\w:.-]+)\s*=\s*(?:"([^"]*)"|'([^']*)')''')


def map_crc(path):
    value = 0
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(4096), b""):
            for byte in block:
                value = ((value << 1) + (value >> 31) + byte) & 0xFFFFFFFF
    return value


def metadata_entries(data, path):
    """Use the XML parser's byte positions to avoid rewriting commented tags."""
    parser = expat.ParserCreate(namespace_separator="}")
    entries = []

    def start(name, attributes):
        if name != MAP_TAG or "FileName" not in attributes:
            return
        tag = START_TAG.match(data, parser.CurrentByteIndex)
        if tag is None:
            raise ValueError(f"{path}: cannot locate MapMetaData opening tag")
        span = None
        for attribute in ATTRIBUTE.finditer(data, tag.start(), tag.end()):
            if attribute[1] == b"CRC":
                span = attribute.span(2 if attribute[2] is not None else 3)
                break
        if span is None:
            insertion = tag.end() - 1
            if data[insertion - 1:insertion] == b"/":
                insertion -= 1
            span = (insertion, insertion)
        entries.append((attributes["FileName"], attributes.get("CRC"), span))

    parser.StartElementHandler = start
    parser.Parse(data, True)
    return entries


def update(root, write=False):
    metadata_files = sorted((root / "Data/additionalmaps").glob("mapmetadata_*.xml"))
    if not metadata_files:
        raise ValueError(f"No mapmetadata_*.xml files in {root / 'Data/additionalmaps'}")

    additional = root / "Additional"
    maps = {}
    for path in sorted((additional / "Data/maps/official").rglob("*")):
        if path.is_file() and path.suffix.casefold() == ".map":
            key = path.relative_to(additional).as_posix().casefold()
            if key in maps:
                raise ValueError(f"Map paths differ only in case: {maps[key]} and {path}")
            maps[key] = path

    # Resolve every reference before hashing or writing. Duplicate registrations
    # across current/old/Corona pools share one checksum, but retain every entry.
    documents = []
    referenced = set()
    entry_count = 0
    for path in metadata_files:
        data = path.read_bytes()
        entries = metadata_entries(data, path)
        if not entries:
            raise ValueError(f"{path}: no map entries")
        rows = []
        for filename, current, span in entries:
            key = filename.replace("\\", "/").casefold()
            if key not in maps:
                raise ValueError(f"{path}: map file not found in Additional: {filename}")
            rows.append((key, current, span))
            referenced.add(key)
        entry_count += len(rows)
        documents.append((path, data, rows))
    unregistered = sorted(maps.keys() - referenced)
    if unregistered:
        raise ValueError("Maps have no MapMetaData entry: " + ", ".join(unregistered))

    checksums = {key: str(map_crc(maps[key])) for key in sorted(referenced)}
    changed_entries = 0
    updates = []
    for path, data, rows in documents:
        edits = []
        for key, current, (begin, end) in rows:
            expected = checksums[key]
            if current == expected:
                continue
            print(f"{path.relative_to(root)}: {maps[key].stem}: "
                  f"{current if current is not None else '(missing)'} -> {expected}")
            replacement = expected.encode("ascii")
            if current is None:
                replacement = b' CRC="' + replacement + b'"'
            edits.append((begin, end, replacement))
        if edits:
            changed_entries += len(edits)
            for begin, end, replacement in reversed(edits):
                data = data[:begin] + replacement + data[end:]
            updates.append((path, data))

    if write:
        for path, data in updates:
            path.write_bytes(data)
    action = "Updated" if write else "Found"
    print(f"Checked {entry_count} entries / {len(checksums)} map files / "
          f"{len(metadata_files)} metadata files. "
          f"{action} {changed_entries} CRC differences in {len(updates)} files.")
    return 0 if write or not updates else 1


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true", help="Check CRCs without writing; exit 1 on mismatch")
    mode.add_argument("--write", action="store_true", help="Update missing or stale CRC attributes")
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2],
                        help="Content repository root (defaults to this script's repository)")
    args = parser.parse_args(argv)
    try:
        return update(args.root.resolve(), args.write)
    except (OSError, ValueError, expat.ExpatError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
