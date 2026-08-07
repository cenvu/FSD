from pbxproj import XcodeProject

project = XcodeProject.load('FSD.xcodeproj/project.pbxproj')

files = [
    'FSD/UI/ComparisonWorkspaceModel.swift',
    'FSD/UI/ComparisonBrowserModel.swift',
    'FSD/UI/ComparisonDestinationView.swift',
    'FSD/UI/ComparisonCreationView.swift',
    'FSD/UI/ComparisonWorkspaceView.swift'
]
for file_path in files:
    project.add_file(file_path, force=False, parent=project.get_or_create_group('UI', parent=project.get_or_create_group('FSD')))

test_files = [
    'FSDTests/ComparisonWorkspaceModelTests.swift',
    'FSDTests/ComparisonBrowserModelTests.swift'
]
for file_path in test_files:
    project.add_file(file_path, force=False, target_name='FSDTests', parent=project.get_or_create_group('FSDTests'))

project.save()
