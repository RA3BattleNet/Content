"""Build one edited APT page for Content inputs or a mod's .8pv1 BIG stream.

Requires Python 3.9+, aptxmlai's Windows CLI, and the RA3 MOD SDK. All generated
files and logs stay in a new --work directory. The source and installed tools
are read only. This checks the ordered XML round trip, declared input paths,
self-contained stream header, and required output files. It does not verify
every compiled binary asset or prove that the UI works in the game.
"""

import argparse
import hashlib
import json
import math
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import xml.etree.ElementTree as ET


ET.register_namespace("", "uri:ea.com:eala:asset")

FLOAT_ATTRS = {
    "top", "left", "right", "bottom", "height",
    "rotm00", "rotm01", "rotm10", "rotm11", "tx", "ty",
}
ACTION_TAGS = {"action", "initaction", "clipaction", "buttonaction"}
STREAM_EXTENSIONS = ("manifest", "bin", "imp", "relo")


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def write_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n",
                    encoding="utf-8")


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


# These normalizations come from the verified stock UI8 build. Child order and
# every other XML value remain significant; do not expand this list merely to
# make a failed round trip pass.
def float_six_decimals(value):
    number = struct.unpack("<f", struct.pack("<f", float(value)))[0]
    require(math.isfinite(number), "Nonfinite XML number")
    return "%.6f" % number


def instructions(text):
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    labels = {}
    for line in lines:
        if re.fullmatch(r"[\w]+:", line):
            require(line[:-1] not in labels, "Duplicate script label: " + line)
            labels[line[:-1]] = "label" + str(len(labels))
    result = []
    for line in lines:
        if line.endswith(":") and line[:-1] in labels:
            line = labels[line[:-1]] + ":"
        else:
            jump = re.fullmatch(r"(jump|jumptrue|jumpfalse)\s+(\w+)", line)
            if jump:
                require(jump[2] in labels, "Missing script jump label: " + line)
                line = jump[1] + " " + labels[jump[2]]
            number = re.fullmatch(r"pushfloat\s+([-+\d.eE]+)", line)
            if number:
                line = "pushfloat " + float_six_decimals(number[1])
        result.append(line)
    return "\n".join(result)


def canonical_xml(path):
    """Compare ordered XML trees using only established exporter differences."""
    def ordered(element):
        attributes = dict(element.attrib)
        for key, value in attributes.items():
            if key in FLOAT_ATTRS:
                attributes[key] = float_six_decimals(value)
            if ((key == "geometry" and element.find("ru") is not None)
                    or (key == "image" and not value.isdigit())):
                attributes[key] = attributes[key].replace("\\", "/").lower()
        text = element.text or ""
        text = (instructions(text) if element.tag in ACTION_TAGS else
                "\n".join(line.strip() for line in text.splitlines() if line.strip()))
        return [element.tag, sorted(attributes.items()), text,
                [ordered(child) for child in element]]
    return ordered(ET.parse(path).getroot())


def run_command(arguments, cwd, work, label):
    """Retain complete stdout/stderr and invocation metadata, including failure."""
    arguments = list(map(str, arguments))
    log = work / "logs" / label
    record = {"args": arguments, "cwd": str(cwd), "status": "running"}
    write_json(log.with_suffix(".json"), record)
    environment = {**os.environ, "TEMP": str(work / "temp"),
                   "TMP": str(work / "temp"), "TMPDIR": str(work / "temp")}
    with log.with_suffix(".stdout.log").open("wb") as stdout, \
            log.with_suffix(".stderr.log").open("wb") as stderr:
        try:
            result = subprocess.run(arguments, cwd=cwd, env=environment,
                                    stdout=stdout, stderr=stderr, check=False)
        except OSError as error:
            record.update(status="launch_failed", error=str(error))
            write_json(log.with_suffix(".json"), record)
            raise
    record.update(status="finished", exit_code=result.returncode)
    write_json(log.with_suffix(".json"), record)
    require(result.returncode == 0,
            f"{label} failed (exit {result.returncode}); see {log}.stdout.log and .stderr.log")


def relative_resource(base, value):
    relative = Path(value.replace("\\", "/"))
    require(not relative.is_absolute() and not relative.drive,
            f"Expected a relative CLI resource path: {relative}")
    resource = (base / relative).resolve()
    require(resource.is_relative_to(base),
            f"CLI resource escapes its directory: {relative}")
    return relative, resource


def copy_textures(compiled, name, resources, textures):
    """Copy exactly the Texture files named by the generated declaration."""
    declaration = ET.parse(compiled / (name + ".xml"))
    inputs = {}
    for element in declaration.getroot().iter():
        if element.tag.rsplit("}", 1)[-1] != "Texture":
            continue
        relative, destination = relative_resource(compiled, element.attrib["File"])
        base = resources
        input_relative = relative
        if (textures is not None
                and tuple(part.lower() for part in relative.parts[:2]) == ("art", "textures")):
            base = textures
            input_relative = Path(*relative.parts[2:])
        _, source = relative_resource(base, str(input_relative))
        require(source.is_file(), f"Missing declared Texture input: {source}")
        key = relative.as_posix()
        if key in inputs:
            continue
        require(not destination.exists(), f"Texture would overwrite a generated file: {destination}")
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, destination)
        inputs[key] = {"source": str(source), "sha256": sha256(source)}
    return inputs


def prepare_declaration(compiled, name, stage):
    declaration = ET.parse(compiled / (name + ".xml"))
    assets = {}
    for element in declaration.getroot().iter():
        if "File" not in element.attrib:
            continue
        _, resource = relative_resource(compiled, element.attrib["File"])
        require(resource.is_file(), f"Missing declared CLI resource: {resource}")
        kind = element.tag.rsplit("}", 1)[-1]
        key = kind + ":" + element.attrib["id"]
        require(key not in assets, "Duplicate declared asset: " + key)
        assets[key] = str(resource)
        element.attrib["File"] = str(resource)
    require(assets, "CLI declaration contains no File resources")
    destination = stage / (name + ".xml")
    declaration.write(destination, encoding="utf-8", xml_declaration=True)
    return destination, assets


def package_stream(output, name, package):
    manifests = list(output.rglob(name + ".manifest"))
    require(len(manifests) == 1,
            f"Expected one {name}.manifest, found {len(manifests)} in {output}")
    manifest = manifests[0]
    header_bytes = manifest.read_bytes()[:48]
    require(len(header_bytes) == 48, "Truncated manifest header")
    header = struct.unpack("<BBH11I", header_bytes)
    require(header[:3] == (0, 1, 6), "Unsupported manifest format")
    require(header[11] == 0,
            "External manifest dependencies are outside this self-contained page builder's scope")
    stream_tag = header_bytes[4:8]
    companions = {}
    for extension in STREAM_EXTENSIONS:
        source = manifest.with_suffix("." + extension)
        require(source.is_file(), f"Missing stream companion: {source}")
        if extension != "manifest":
            with source.open("rb") as handle:
                require(handle.read(4) == stream_tag,
                        f"Stream checksum tag differs from the manifest: {source}")
        companions[extension] = source

    package.mkdir(parents=True)
    for extension, source in companions.items():
        shutil.copyfile(source, package / (name.lower() + ".8pv1." + extension))
    for sidecar in sorted(output.rglob("*.cdata")):
        require(sidecar.resolve().is_relative_to(manifest.parent.resolve()),
                f"CDATA lies outside the stream directory: {sidecar}")
        destination = package / sidecar.relative_to(manifest.parent)
        require(not destination.exists(), f"Duplicate package output: {destination}")
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(sidecar, destination)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, required=True, help="Edited APT XML (edit.xml)")
    parser.add_argument("--name", required=True, help="Original SDK page name, e.g. igm_pauseMenu")
    parser.add_argument("--sdk", type=Path, required=True, help="RA3 MOD SDK root directory")
    parser.add_argument("--aptxmlai", type=Path, required=True, help="Cloned aptxmlai root directory")
    parser.add_argument("--work", type=Path, required=True, help="New output directory; must not exist")
    parser.add_argument("--resources", type=Path, help="Root for relative Texture files; default: source directory")
    parser.add_argument("--textures", type=Path, help="Optional override directory for art/Textures references only")
    args = parser.parse_args()
    require(re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", args.name) is not None,
            "Use the original SDK page name, without a path, extension, or .8pv1 suffix")
    source = args.source.resolve()
    sdk = args.sdk.resolve()
    aptxmlai = args.aptxmlai.resolve()
    resources = (args.resources or source.parent).resolve()
    textures = args.textures.resolve() if args.textures else None
    work = args.work.resolve()
    cli = aptxmlai / "ra3apt-cli" / "ra3apt-cli.exe"
    tools = cli.parent / "cc3tools"
    bab = sdk / "tools" / "BinaryAssetBuilder.exe"
    schema = sdk / "Schemas" / "xsd" / "CnC3Types.xsd"
    for path in (source, cli, bab, schema):
        require(path.is_file(), f"Required file does not exist: {path}")
    for path in (resources, tools, sdk / "SageXml"):
        require(path.is_dir(), f"Required directory does not exist: {path}")
    if textures is not None:
        require(textures.is_dir(), f"Texture override directory does not exist: {textures}")
    require(not work.exists(), f"Use a new --work directory; already exists: {work}")
    work.mkdir(parents=True)
    for directory in ("temp", "logs", "cli", "bab_stage", "bab_out"):
        (work / directory).mkdir()
    compiled = work / "cli"
    stage = work / "bab_stage"
    output = work / "bab_out"
    receipt = {
        "status": "building", "name": args.name, "source": str(source),
        "source_sha256": sha256(source), "cli_sha256": sha256(cli),
        "bab_sha256": sha256(bab), "runtime_validation": "not_run",
        "scope": "Ordered XML round trip, declared input files, self-contained stream header, "
                 "matching stream checksum tags, and complete output file set; "
                 "not a complete compiled-asset closure or in-game validation.",
    }
    write_json(work / "receipt.json", receipt)
    apt = compiled / (args.name + ".apt")
    run_command([cli, "build", source, "-o", apt, "--tools-path", tools],
                compiled, work, "build")
    receipt["texture_inputs"] = copy_textures(compiled, args.name, resources, textures)
    write_json(work / "receipt.json", receipt)
    exported = compiled / "export.xml"
    run_command([cli, "expand", apt, "-o", exported, "--tools-path", tools],
                compiled, work, "expand")
    require(canonical_xml(source) == canonical_xml(exported),
            f"Ordered XML round trip differs; compare {source} and {exported}")
    asset_xml, assets = prepare_declaration(compiled, args.name, stage)
    run_command([
        bab, asset_xml, "/od:" + str(output), "/iod:" + str(output),
        "/csc:false", "/ls:true", "/osh:false", "/pc:true", "/res:true",
        "/slowclean:true", "/ss:true", "/sp:" + str(schema),
        "/data:" + str(stage) + ";" + str(sdk / "SageXml"),
        "/art:" + str(stage), "/audio:" + str(stage),
    ], stage, work, "bab")
    package = work / "package" / "data" / "aptui"
    package_stream(output, args.name, package)
    receipt.update(
        status="passed", ordered_xml_roundtrip_equal=True, declared_inputs=assets,
        package_files={path.relative_to(work / "package").as_posix(): sha256(path)
                       for path in sorted(package.rglob("*")) if path.is_file()},
    )
    write_json(work / "receipt.json", receipt)
    print(f"Built {args.name}")
    print(f"Content inputs: {compiled} (SDK declaration and its relative resources; export.xml is for inspection).")
    print(f"Mod BIG payload: {work / 'package'} (pack the data/ tree with its paths intact).")
    print("No .version file was generated.")
    print("Offline checks passed; compiled-asset closure and in-game behavior are not verified.")


if __name__ == "__main__":
    main()
