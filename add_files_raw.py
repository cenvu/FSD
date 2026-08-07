import sys

with open('FSD.xcodeproj/project.pbxproj', 'r') as f:
    pbx = f.read()

def inject(target_str, append_str):
    global pbx
    idx = pbx.find(target_str)
    if idx != -1:
        pbx = pbx[:idx + len(target_str)] + append_str + pbx[idx + len(target_str):]
    else:
        print("Failed to find", target_str)

files_app = [
    ('ComparisonWorkspaceModel.swift', 'FSD/UI/ComparisonWorkspaceModel.swift', 'A20000000000000000000501', 'A10000000000000000000501'),
    ('ComparisonBrowserModel.swift', 'FSD/UI/ComparisonBrowserModel.swift', 'A20000000000000000000502', 'A10000000000000000000502'),
    ('ComparisonDestinationView.swift', 'FSD/UI/ComparisonDestinationView.swift', 'A20000000000000000000503', 'A10000000000000000000503'),
    ('ComparisonCreationView.swift', 'FSD/UI/ComparisonCreationView.swift', 'A20000000000000000000504', 'A10000000000000000000504'),
    ('ComparisonWorkspaceView.swift', 'FSD/UI/ComparisonWorkspaceView.swift', 'A20000000000000000000505', 'A10000000000000000000505'),
]

files_tests = [
    ('ComparisonWorkspaceModelTests.swift', 'FSDTests/ComparisonWorkspaceModelTests.swift', 'A20000000000000000000601', 'A10000000000000000000601'),
    ('ComparisonBrowserModelTests.swift', 'FSDTests/ComparisonBrowserModelTests.swift', 'A20000000000000000000602', 'A10000000000000000000602'),
]

# 1. PBXBuildFile
build_files = ""
for name, path, file_id, build_id in files_app + files_tests:
    build_files += f"\t\t{build_id} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_id} /* {name} */; }};\n"
inject("/* Begin PBXBuildFile section */\n", build_files)

# 2. PBXFileReference
file_refs = ""
for name, path, file_id, build_id in files_app + files_tests:
    file_refs += f"\t\t{file_id} /* {name} */ = {{isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode.swift; path = {name}; sourceTree = \"<group>\"; }};\n"
inject("/* Begin PBXFileReference section */\n", file_refs)

# 3. Add to groups
app_children = "".join([f"{file_id} /* {name} */, " for name, path, file_id, build_id in files_app])
inject("A40000000000000000000014 /* UI */ = {isa = PBXGroup; children = (", app_children)

test_children = "".join([f"{file_id} /* {name} */, " for name, path, file_id, build_id in files_tests])
inject("A40000000000000000000003 /* FSDTests */ = {isa = PBXGroup; children = (", test_children)

# 4. Add to build phases
app_builds = "".join([f"{build_id} /* {name} in Sources */, " for name, path, file_id, build_id in files_app])
inject("A30000000000000000000003 /* Sources */ = {isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (", app_builds)

test_builds = "".join([f"{build_id} /* {name} in Sources */, " for name, path, file_id, build_id in files_tests])
inject("A30000000000000000000005 /* Sources */ = {isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (", test_builds)

with open('FSD.xcodeproj/project.pbxproj', 'w') as f:
    f.write(pbx)
