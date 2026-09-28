#!/usr/bin/env python3
"""Register FeastNarratives.swift in RosaryGuide.xcodeproj/project.pbxproj if missing."""
from __future__ import annotations
import re
import sys
import uuid
from pathlib import Path

def new_id() -> str:
    return uuid.uuid4().hex[:24].upper()

def main() -> int:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".")
    pbx = root / "RosaryGuide.xcodeproj" / "project.pbxproj"
    if not pbx.exists():
        print(f"missing {pbx}", file=sys.stderr)
        return 1
    text = pbx.read_text()
    if "FeastNarratives.swift" in text:
        print("FeastNarratives.swift already in pbxproj")
        return 0

    # Find FeastCatalog.swift as template neighbor in Data group
    m = re.search(r"([A-F0-9]{24}) /\* FeastCatalog\.swift \*/ = \{isa = PBXFileReference;[^}]+\};", text)
    if not m:
        # try shorter form
        m = re.search(r"([A-F0-9]{24}) /\* FeastCatalog\.swift \*/ = \{isa = PBXFileReference;.*?\};", text)
    if not m:
        print("Could not find FeastCatalog.swift PBXFileReference", file=sys.stderr)
        return 1
    file_ref = new_id()
    build_file = new_id()

    file_ref_line = (
        f"\t\t{file_ref} /* FeastNarratives.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FeastNarratives.swift; sourceTree = \"<group>\"; }};\n"
    )
    # Insert after FeastCatalog file reference
    text = text.replace(m.group(0), m.group(0) + "\n" + file_ref_line.rstrip("\n"), 1)

    # PBXBuildFile
    bf = re.search(r"(/\* Begin PBXBuildFile section \*/\n)", text)
    if not bf:
        print("No PBXBuildFile section", file=sys.stderr)
        return 1
    build_line = f"\t\t{build_file} /* FeastNarratives.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref} /* FeastNarratives.swift */; }};\n"
    text = text.replace(bf.group(1), bf.group(1) + build_line, 1)

    # Add to Data group children near FeastCatalog
    g = re.search(r"([A-F0-9]{24}) /\* FeastCatalog\.swift \*/,", text)
    if not g:
        print("Could not find FeastCatalog in group children", file=sys.stderr)
        return 1
    text = text.replace(g.group(0), g.group(0) + f"\n\t\t\t\t{file_ref} /* FeastNarratives.swift */,", 1)

    # Sources build phase
    s = re.search(r"([A-F0-9]{24}) /\* FeastCatalog\.swift in Sources \*/,", text)
    if not s:
        print("Could not find FeastCatalog in Sources", file=sys.stderr)
        return 1
    text = text.replace(s.group(0), s.group(0) + f"\n\t\t\t\t{build_file} /* FeastNarratives.swift in Sources */,", 1)

    pbx.write_text(text)
    print(f"Registered FeastNarratives.swift (fileRef={file_ref}, build={build_file})")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
