require 'xcodeproj'

project_path = 'FSD.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

ui_group = project.main_group.find_subpath(File.join('FSD', 'UI'), true)

files_to_add = [
  'FSD/UI/ComparisonWorkspaceModel.swift',
  'FSD/UI/ComparisonBrowserModel.swift',
  'FSD/UI/ComparisonDestinationView.swift',
  'FSD/UI/ComparisonCreationView.swift',
  'FSD/UI/ComparisonWorkspaceView.swift'
]

files_to_add.each do |file_path|
  file_ref = ui_group.find_file_by_path(file_path)
  unless file_ref
    file_ref = ui_group.new_reference(File.basename(file_path))
  end
  unless target.source_build_phase.files_references.include?(file_ref)
    target.source_build_phase.add_file_reference(file_ref)
  end
end

project.save
