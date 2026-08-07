import SwiftUI

struct ComparisonDestinationView: View {
    @StateObject private var workspaceModel: ComparisonWorkspaceModel
    
    init(database: CatalogDatabase) {
        _workspaceModel = StateObject(wrappedValue: ComparisonWorkspaceModel(database: database))
    }
    
    var body: some View {
        VStack {
            if let error = workspaceModel.error {
                EmptyStateView(title: "Comparison Error", systemImage: "exclamationmark.triangle", detail: error)
            } else if workspaceModel.activeBrowser != nil {
                ComparisonWorkspaceView(model: workspaceModel)
            } else {
                ComparisonCreationView(model: workspaceModel)
            }
        }
        .onAppear {
            workspaceModel.refresh()
            #if DEBUG
            // DEBUG-only runtime diagnostic (same pattern as the startup
            // catalog line): lets an automated probe confirm the comparison
            // destination loaded its history, eligible snapshots and profiles
            // without reading the UI.
            let model = workspaceModel
            let newest = model.history.first { $0.status == .complete }
            var outcomeLine = ""
            if let newest {
                outcomeLine = " newest complete: matched=\(newest.matchedCount) added=\(newest.addedCount) removed=\(newest.removedCount) changed=\(newest.changedCount) uncertain=\(newest.uncertainCount) differences=\(newest.totalDifferences) total=\(newest.totalComparedEntries)"
            }
            FileHandle.standardError.write(Data(
                "FSD comparison destination loaded: \(model.history.count) comparison(s), \(model.availableSnapshots.count) eligible snapshot(s), \(model.profiles.count) profile(s).\(outcomeLine)\n".utf8
            ))
            #endif
        }
    }
}
