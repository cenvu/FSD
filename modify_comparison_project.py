#!/usr/bin/env python3
"""Adds the Milestone 4 comparison files to FSD.xcodeproj following the
project's existing explicit PBXFileReference/PBXBuildFile conventions."""

import re
import sys

PROJECT = "/Users/cenvu/DEV/FSD/FSD.xcodeproj/project.pbxproj"

# (filename, fileRefID, buildFileID, groupPath)
FSD_FILES = [
    ("ComparisonModels.swift", "A20000000000000000000301", "A10000000000000000000301", "FSD/Diff"),
    ("ComparisonProfileRepository.swift", "A20000000000000000000302", "A10000000000000000000302", "FSD/Diff"),
    ("ComparisonEngine.swift", "A20000000000000000000303", "A10000000000000000000303", "FSD/Diff"),
    ("ComparisonResultRepository.swift", "A20000000000000000000304", "A10000000000000000000304", "FSD/Diff"),
    ("ComparisonService.swift", "A20000000000000000000305", "A10000000000000000000305", "FSD/Diff"),
    ("TransientSnapshotLifecycle.swift", "A20000000000000000000306", "A10000000000000000000306", "FSD/Catalog"),
]

TEST_FILES = [
    ("TestSupport.swift", "A20000000000000000000311", "A10000000000000000000311"),
    ("ComparisonSemanticsTests.swift", "A20000000000000000000312", "A10000000000000000000312"),
    ("ComparisonIdentityTests.swift", "A20000000000000000000313", "A10000000000000000000313"),
    ("ComparisonSnapshotStateTests.swift", "A20000000000000000000314", "A10000000000000000000314"),
    ("ComparisonModeTests.swift", "A20000000000000000000315", "A10000000000000000000315"),
    ("ComparisonPersistenceTests.swift", "A20000000000000000000316", "A10000000000000000000316"),
    ("ComparisonScaleTests.swift", "A20000000000000000000317", "A10000000000000000000317"),
    ("ComparisonEndToEndProbeTests.swift", "A20000000000000000000318", "A10000000000000000000318"),
]

DIFF_GROUP_ID = "A40000000000000000000015"

with open(PROJECT, "r", encoding="utf-8") as handle:
    content = handle.read()

# 1. PBXBuildFile entries
build_entries = []
for name, file_ref, build_ref, _ in FSD_FILES + [(name, fr, br, None) for name, fr, br in TEST_FILES]:
    build_entries.append(
        f"\t\t{build_ref} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref} /* {name} */; }};"
    )
content = content.replace(
    "/* End PBXBuildFile section */",
    "\n".join(build_entries) + "\n/* End PBXBuildFile section */",
    1,
)

# 2. PBXFileReference entries
file_entries = []
for name, file_ref, build_ref, _ in FSD_FILES + [(name, fr, br, None) for name, fr, br in TEST_FILES]:
    file_entries.append(
        f"\t\t{file_ref} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = \"<group>\"; }};"
    )
content = content.replace(
    "/* End PBXFileReference section */",
    "\n".join(file_entries) + "\n/* End PBXFileReference section */",
    1,
)

# 3. Groups: new Diff group, FSD children, FSDTests children, Catalog children
diff_children = "".join(
    f"A2000000000000000000030{i} /* {name} */, "
    for i, (name, _, _) in enumerate(
        [(n, f, b) for n, f, b, _ in FSD_FILES if _ == "FSD/Diff"], start=1
    )
).rstrip(", ")
diff_group = (
    f"\t\t{DIFF_GROUP_ID} /* Diff */ = {{isa = PBXGroup; children = ({diff_children},); path = Diff; sourceTree = \"<group>\"; }};"
)
content = content.replace(
    "\t\tA40000000000000000000014 /* UI */ =",
    diff_group + "\n\t\tA40000000000000000000014 /* UI */ =",
    1,
)

# FSD root group children: append the Diff group reference.
content = content.replace(
    "A40000000000000000000013, A40000000000000000000014,); path = FSD;",
    f"A40000000000000000000013, A40000000000000000000014, {DIFF_GROUP_ID},); path = FSD;",
    1,
)

# Catalog group children: append TransientSnapshotLifecycle.
content = content.replace(
    "A20000000000000000000112 /* SnapshotWriter.swift */, A20000000000000000000113 /* RecoveryService.swift */,); path = Catalog;",
    "A20000000000000000000112 /* SnapshotWriter.swift */, A20000000000000000000113 /* RecoveryService.swift */, A20000000000000000000306 /* TransientSnapshotLifecycle.swift */,); path = Catalog;",
    1,
)

# FSDTests group children: append the new test files.
test_children = ", ".join(
    f"A2000000000000000000031{i} /* {name} */" for i, (name, _, _) in enumerate(TEST_FILES, start=1)
)
content = content.replace(
    "A20000000000000000000228 /* FilesystemMatrixTests.swift */,); path = FSDTests;",
    f"A20000000000000000000228 /* FilesystemMatrixTests.swift */, {test_children},); path = FSDTests;",
    1,
)

# 4. Sources build phases: FSD target (phase A30000000000000000000003) and
# FSDTests target (phase A30000000000000000000005).
fsd_build_refs = "".join(
    f"A1000000000000000000030{i} /* {name} in Sources */, "
    for i, (name, _, _) in enumerate(
        [(n, f, b) for n, f, b, _ in FSD_FILES], start=1
    )
).rstrip(", ")
fsd_phase = content.index("\t\tA30000000000000000000003 /* Sources */")
fsd_phase_end = content.index("/* End PBXSourcesBuildPhase section */")
content = content[:fsd_phase_end] + "\t\t" + fsd_build_refs + ", " + content[fsd_phase_end:]

test_build_refs = "".join(
    f"A1000000000000000000031{i} /* {name} in Sources */, "
    for i, (name, _, _) in enumerate(TEST_FILES, start=1)
).rstrip(", ")
# Insert into the FSDTests Sources phase line.
test_phase_marker = "A10000000000000000000228 /* FilesystemMatrixTests.swift in Sources */,);"
assert test_phase_marker in content, "FSDTests Sources phase marker not found"
content = content.replace(
    test_phase_marker,
    "A10000000000000000000228 /* FilesystemMatrixTests.swift in Sources */, " + test_build_refs + ",);",
    1,
)

with open(PROJECT, "w", encoding="utf-8") as handle:
    handle.write(content)

print("project.pbxproj updated")
