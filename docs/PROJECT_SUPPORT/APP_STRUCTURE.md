# Source Placeholder

The production Xcode project has not been generated in this planning package.

Recommended initial groups:

```text
FSDApp/
├── App/
├── Domain/
│   ├── Volume/
│   ├── Snapshot/
│   ├── Entry/
│   └── Comparison/
├── Infrastructure/
│   ├── Database/
│   ├── Filesystem/
│   ├── DiskArbitration/
│   └── Export/
├── Features/
│   ├── VolumeLibrary/
│   ├── Capture/
│   ├── SnapshotBrowser/
│   ├── Compare/
│   └── Settings/
└── Shared/
```

Suggested first implementation files:

```text
FSDApp.swift
AppState.swift
CatalogDatabase.swift
MigrationRunner.swift
SnapshotScanner.swift
ScanProgress.swift
SnapshotRepository.swift
VolumeRepository.swift
FolderPicker.swift
```
