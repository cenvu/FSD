import SwiftUI

struct SaveComparisonControls: View {
    @ObservedObject var workspace: ComparisonWorkspaceModel
    @ObservedObject var model: SavedComparisonsModel
    @State private var confirmsNewCopy = false

    var body: some View {
        VStack(alignment:.leading,spacing:6) {
            HStack {
                if model.isSaving {
                    ProgressView().controlSize(.small)
                    Text(model.saveMessage ?? "Saving metadata…")
                    Button("Cancel Save",action:model.cancelSave).accessibilityLabel("Cancel Save Comparison")
                    Button("Cancel Save and Close",action:workspace.closeComparison)
                        .disabled(workspace.isClosing).accessibilityLabel("Cancel Save and close comparison workspace")
                } else {
                    switch model.eligibility {
                    case .available:
                        Button(model.saveError == nil ? "Save Comparison" : "Retry Save Comparison") { model.save() }
                            .keyboardShortcut("s",modifiers:.command).accessibilityLabel("Save Comparison")
                        Text("Keep both sides’ metadata for offline reopening.")
                    case .deleted:
                        Button("Save Again as New…") { confirmsNewCopy = true }
                            .accessibilityLabel("Save comparison again as a new artifact")
                        Text("The previous saved artifact was deleted. Retry will not restore it.")
                    case .saved(let id):
                        Label("Comparison saved",systemImage:"checkmark.circle")
                        Button("Open Saved Comparison") { model.open(id); workspace.showsSavedComparisons = true }
                            .accessibilityLabel("Open saved comparison offline")
                    case .checking:
                        Button("Save Comparison") {}.disabled(true)
                        ProgressView().controlSize(.small)
                        Text("Checking completion evidence…")
                    case .unavailable(let reason):
                        Button("Save Comparison") {}.disabled(true)
                        Text(reason).fixedSize(horizontal:false,vertical:true)
                    }
                }
                Spacer(minLength:0)
            }
            .font(.callout)
            if let error = model.saveError {
                Label(error,systemImage:"exclamationmark.triangle").font(.callout)
                    .accessibilityLabel("Save error: \(error)")
            }
            if workspace.isClosing { Text("Closing after Save commits or rolls back…").font(.caption) }
        }
        .padding(12)
        .background(.quaternary.opacity(0.4))
        .confirmationDialog("Save a new comparison artifact?",isPresented:$confirmsNewCopy) {
            Button("Save Again as New") { model.save(asNewAfterDeletion:true) }
        } message: { Text("The deleted artifact stays deleted. This explicit action creates a separate saved artifact for the completed comparison.") }
    }
}

struct SavedComparisonsView: View {
    @ObservedObject var model: SavedComparisonsModel
    var body: some View {
        Group {
            if model.readerID != nil { SavedComparisonDetailView(model:model) }
            else { library }
        }
        .confirmationDialog("Delete Saved Comparison?",isPresented:Binding(get:{ model.deletionCandidate != nil },set:{ if !$0 { model.deletionCandidate = nil } })) {
            Button("Delete Saved Comparison",role:.destructive,action:model.confirmDeletion)
            Button("Cancel",role:.cancel) { model.deletionCandidate = nil }
        } message: {
            Text("Permanently delete saved artifact \(model.deletionCandidate?.uuidString ?? ""). Its metadata copy will be removed. Original captures and other saved artifacts are preserved.")
        }
    }
    private var library: some View {
        VStack(alignment:.leading,spacing:12) {
            HStack {
                VStack(alignment:.leading,spacing:4) {
                    Text("Saved Comparisons").font(.title2.bold())
                    Text("Durable metadata copies. Reopen without original sources.").foregroundStyle(.secondary)
                }
                Spacer()
                Button("Reload",action:model.reloadLibrary).disabled(model.libraryLoading || model.isDeleting)
                    .keyboardShortcut("r",modifiers:.command).accessibilityLabel("Reload Saved Comparisons")
            }
            if model.libraryLoading { ProgressView("Loading Saved Comparisons…") }
            if let error = model.libraryError { Label(error,systemImage:"exclamationmark.triangle").accessibilityLabel("Saved library error: \(error)") }
            if model.summaries.isEmpty && !model.libraryLoading && model.libraryError == nil {
                EmptyStateView(title:"No Saved Comparisons",systemImage:"archivebox",detail:"Choose Save Comparison in a completed workspace to retain its metadata. Recent Comparisons have a separate lifecycle.")
            } else {
                List(model.summaries) { summary in
                    HStack(alignment:.top) {
                        VStack(alignment:.leading,spacing:5) {
                            Text("\(summary.receipt.profile.name) · v\(summary.receipt.profile.revision)").font(.headline)
                            Text("Completed \(summary.receipt.completedAt)").font(.caption)
                            Text("\(summary.receipt.closure.resultRows) results · \(summary.receipt.warnings.count) warnings · Metadata only").font(.caption).foregroundStyle(.secondary)
                            Text(summary.id.uuidString).font(.caption2).textSelection(.enabled)
                        }
                        Spacer()
                        Button("Open") { model.open(summary.id) }.accessibilityLabel("Open saved comparison \(summary.id.uuidString)")
                        Button("Delete…",role:.destructive) { model.deletionCandidate = summary.id }
                            .disabled(model.isDeleting).accessibilityLabel("Delete saved comparison \(summary.id.uuidString)")
                    }.padding(.vertical,7)
                }.accessibilityLabel("Durable Saved Comparisons")
            }
            HStack {
                Button("Previous Page",action:model.previousLibraryPage).disabled(model.libraryPage == 0 || model.libraryLoading)
                Text("Page \(model.libraryPage + 1) · up to 20 artifacts").font(.caption)
                Button("Next Page",action:model.nextLibraryPage).disabled(!model.libraryHasNext || model.libraryLoading)
            }
        }.padding(18)
    }
}

struct SavedComparisonDetailView: View {
    @ObservedObject var model: SavedComparisonsModel
    var body: some View {
        VStack(alignment:.leading,spacing:10) {
            HStack {
                Button("Back to Saved Comparisons") { model.closeReader(); model.reloadLibrary() }
                    .keyboardShortcut(.leftArrow,modifiers:.command).accessibilityLabel("Back to Saved Comparisons")
                Spacer()
                Button("Reload Evidence") { if let id = model.readerID { model.open(id) } }
                    .disabled(model.readerLoading).accessibilityLabel("Reload saved evidence")
                Button("Delete Saved Comparison…",role:.destructive) { model.deletionCandidate = model.readerID }
                    .disabled(model.isDeleting).accessibilityLabel("Delete Saved Comparison")
            }
            if let receipt = model.receipt {
                Text("Saved Comparison · \(receipt.profile.name) (version \(receipt.profile.revision))").font(.title2.bold())
                Text("Completed \(receipt.completedAt) · \(model.readerID?.uuidString ?? "")").font(.caption).textSelection(.enabled)
                DisclosureGroup("Frozen executed profile and warnings (\(receipt.warnings.count))") {
                    ScrollView {
                        VStack(alignment:.leading,spacing:4) {
                            Text("Engine: \(receipt.engineVersion) · Normalization: \(receipt.normalizationVersion) · Key: \(receipt.selectedPathKey)")
                            Text(verbatim:"Fields — type: \(receipt.profile.compareItemType), logical size: \(receipt.profile.compareLogicalSize), allocated size: \(receipt.profile.compareAllocatedSize), modified: \(receipt.profile.compareModifiedAt), created: \(receipt.profile.compareCreatedAt)")
                            Text(verbatim:"Timestamp tolerance: \(receipt.profile.timestampToleranceSeconds)s · Include hidden: \(receipt.profile.includeHiddenItems)")
                            Text("Ignore rules: \(receipt.profile.ignoreRules.joined(separator:", "))")
                            if receipt.warnings.isEmpty { Text("No compatibility warnings recorded.") }
                            ForEach(receipt.warnings,id:\.self) { Text($0) }
                        }.frame(maxWidth:.infinity,alignment:.leading).font(.caption).textSelection(.enabled)
                    }.frame(maxHeight:120)
                }
                Text(ComparisonResultType.allCases.map { "\($0.rawValue.capitalized): \(receipt.closure.counts[$0.rawValue] ?? 0)" }.joined(separator:"  ·  "))
                    .font(.callout).accessibilityLabel("Frozen result counts")
                Text("Ignored entries were excluded by the executed profile; they are not verified matches.").font(.caption).foregroundStyle(.secondary)
            }
            Label("Content Not Verified — historical metadata only; no file-content hashing or physical-device verification.",systemImage:"info.circle")
                .font(.callout).accessibilityElement(children:.ignore).accessibilityLabel("Content Not Verified. Historical metadata only. No file content or physical device verification.")
            if model.readerLoading { ProgressView("Loading saved evidence…") }
            if let error = model.readerError { Label(error,systemImage:"exclamationmark.triangle").accessibilityLabel("Saved evidence error: \(error)") }
            if model.receipt != nil {
                HStack {
                    Picker("Evidence",selection:$model.pageKind) {
                        ForEach(SavedComparisonsModel.PageKind.allCases,id:\.self) { Text($0.rawValue).tag($0) }
                    }.frame(maxWidth:260).accessibilityLabel("Saved evidence category")
                    Spacer()
                    Button("Previous Page",action:model.previousPage).disabled(model.pageIndex == 0 || model.readerLoading)
                        .keyboardShortcut(.upArrow,modifiers:[.command,.shift]).accessibilityLabel("Previous saved evidence page")
                    Text("Page \(model.pageIndex+1) · \(model.rows.count) rows").font(.caption)
                    Button("Next Page",action:model.nextPage).disabled(!model.hasNext || model.readerLoading)
                        .keyboardShortcut(.downArrow,modifiers:[.command,.shift]).accessibilityLabel("Next saved evidence page")
                }.disabled(model.isDeleting)
                HSplitView {
                    evidenceList.frame(minWidth:240,idealWidth:320)
                    ScrollView {
                        VStack(alignment:.leading,spacing:12) {
                            if let row = model.selected {
                                Text("Selected \(model.pageKind.rawValue)").font(.headline)
                                Text("Saved row ID: \(row.id)").font(.caption).textSelection(.enabled)
                                DisclosureGroup("Original typed row metadata (provenance IDs)") { typedMetadata(row.original) }
                                if model.pageKind == .groups || model.pageKind == .members {
                                    Text("Collision evidence is unpaired. Group IDs identify candidates; no deterministic match is implied.")
                                        .font(.callout)
                                }
                                if model.detailsLoading { ProgressView("Loading selected metadata…") }
                                else { HStack(alignment:.top,spacing:12) {
                                    side("LEFT · Before / Reference",evidence:model.selectedLeft,header:model.receipt?.left)
                                    Divider()
                                    side("RIGHT · After / Changed",evidence:model.selectedRight,header:model.receipt?.right)
                                } }
                            } else { Text("Select a row to inspect its saved typed metadata.").foregroundStyle(.secondary) }
                        }.padding(12).frame(maxWidth:.infinity,alignment:.leading)
                    }.frame(minWidth:420)
                }
            }
        }.padding(14)
    }
    private var evidenceList: some View {
        VStack {
            if model.rows.isEmpty && !model.readerLoading && model.readerError == nil { Text("No rows in this evidence category.").padding() }
            List(selection:Binding(get:{ model.selected?.id },set:{ id in model.select(model.rows.first { $0.id == id }) })) {
                ForEach(model.rows,id:\.id) { row in
                    VStack(alignment:.leading,spacing:3) {
                        Text(row.original["display_name"]?.text ?? row.original["name"]?.text ?? row.original["result_path"]?.text ?? "Evidence \(row.id)").lineLimit(2)
                        Text(row.original["result_type"]?.text?.capitalized ?? row.original["relative_path"]?.text ?? row.original["side"]?.text ?? "Saved metadata").font(.caption).foregroundStyle(.secondary)
                        if let group = row.groupID { Text("Saved collision group \(group)").font(.caption2) }
                    }.tag(row.id).accessibilityElement(children:.combine)
                }
            }.accessibilityLabel("Paged saved comparison evidence")
        }
    }
    private func side(_ title: String,evidence: SavedEvidenceRow?,header: CompletionSnapshotEvidence?) -> some View {
        VStack(alignment:.leading,spacing:6) {
            Text(title).font(.headline)
            if let header {
                Text("Frozen snapshot \(header.header["id"]?.integer ?? 0) · \(header.header["status"]?.text ?? "")").font(.caption)
                Text("\(header.issues.count) completion-time issues").font(.caption)
                DisclosureGroup("Completion-time header") { typedMetadata(header.header) }
            }
            if let evidence { typedMetadata(evidence.original) }
            else { Text("No entry linked on this side. No match is inferred.").font(.caption).foregroundStyle(.secondary) }
        }.frame(maxWidth:.infinity,alignment:.leading)
    }
    private func typedMetadata(_ metadata: [String:CompletionMetadataValue]) -> some View {
        VStack(alignment:.leading,spacing:4) {
            ForEach(metadata.keys.sorted(),id:\.self) { key in
                VStack(alignment:.leading,spacing:1) {
                    Text(key).font(.caption2).foregroundStyle(.secondary)
                    Text(Self.value(metadata[key]!)).font(.caption).textSelection(.enabled)
                }.accessibilityElement(children:.combine)
            }
        }
    }
    static func value(_ value: CompletionMetadataValue) -> String {
        switch value {
        case .null: return "NULL"
        case .integer(let n): return String(n)
        case .text(let text): return text.isEmpty ? "TEXT (empty)" : text
        case .blob(let bytes): return "BLOB (\(bytes.count) bytes), base64: \(bytes.base64EncodedString())"
        }
    }
}
