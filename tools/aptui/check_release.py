"""Check APT declarations before BAB and linked streams before release."""

import argparse
from pathlib import Path
import struct
import xml.etree.ElementTree as ET


STREAM_EXTENSIONS = ("manifest", "bin", "imp", "relo")
APT_TYPE = 0x6C41E6DC  # AptAptData in a linked RA3 v6 manifest.
NATIVE_STREAMS = (
    "ra3battlenet",
    "ra3battlenet_automatchhelper",
    "ra3battlenet_connectioninformation",
    "ra3battlenet_splash",
    "ra3battlenet_virtuallist",
)
EIGHT_PLAYER_STREAMS = (
    "fe_m_assetsgamesetup",
    "feg_m_disconnect",
    "fem_m_gamesetup",
    "fem_m_load",
    "fem_m_postgameroundup",
    "fes_m_skirmishgamesetup",
    "igm_pausemenu",
)


def check_inputs(declaration, seen=None):
    """Resolve local Include sources recursively, before invoking BAB."""
    if seen is None:
        seen = set()
    declaration = declaration.resolve()
    if declaration in seen:
        return
    seen.add(declaration)
    for include in ET.parse(declaration).iter("{uri:ea.com:eala:asset}Include"):
        source = include.get("source")
        if not source:
            raise ValueError(f"{declaration}: Include has no source")
        if ":" in source:
            raise ValueError(f"{declaration}: expected a local APT Include, got {source}")
        target = declaration.parent / source.replace("\\", "/")
        if not target.is_file():
            raise ValueError(f"{declaration}: missing Include {source}")
        check_inputs(target, seen)


def check_stream(manifest):
    """Require a linked APT asset and its matching companion files."""
    data = manifest.read_bytes()
    if len(data) < 48:
        raise ValueError(f"{manifest}: truncated manifest")
    header = struct.unpack_from("<BBH11I", data)
    count = header[5]
    if header[:3] != (0, 1, 6) or 48 + count * 48 > len(data):
        raise ValueError(f"{manifest}: invalid linked RA3 v6 manifest")
    if not any(struct.unpack_from("<I", data, 48 + index * 48)[0] == APT_TYPE
               for index in range(count)):
        raise ValueError(f"{manifest}: no AptAptData (asset count {count})")
    for extension in STREAM_EXTENSIONS[1:]:
        companion = manifest.with_suffix("." + extension)
        with companion.open("rb") as stream:
            if stream.read(4) != data[4:8]:
                raise ValueError(f"{companion}: checksum tag differs from {manifest.name}")
            if extension == "bin" and not stream.read(1):
                raise ValueError(f"{companion}: empty APT binary")
    return header


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("inputs").add_argument("declarations", type=Path, nargs="+")
    package = commands.add_parser("package")
    package.add_argument("root", type=Path)
    package.add_argument("--development-button", action="store_true")
    args = parser.parse_args()
    try:
        if args.command == "inputs":
            for declaration in args.declarations:
                check_inputs(declaration)
        else:
            aptui = args.root / "data" / "aptui"
            streams = NATIVE_STREAMS + tuple(name + ".8pv1" for name in EIGHT_PLAYER_STREAMS)
            if args.development_button:
                streams += ("v4dev_mode_switch",)
                (aptui / "v4dev_mode_switch.version").read_bytes()
            for name in streams:
                check_stream(aptui / (name + ".manifest"))
            print(f"Checked {len(streams)} linked APT streams in {aptui}")
    except (OSError, ValueError, ET.ParseError) as error:
        parser.exit(1, f"APT release check failed: {error}\n")


if __name__ == "__main__":
    main()
