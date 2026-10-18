import SwiftUI

/// App actions share the production catalog APIs. No device/service dependency.
@MainActor
final class DriveSetsModel: ObservableObject {
    @Published private(set) var sets: [DriveSet] = []
    @Published private(set) var selected: DriveSet?
    @Published private(set) var members: [PhysicalDrive] = []
    @Published private(set) var available: [PhysicalDrive] = []
    @Published private(set) var included: Set<PhysicalDriveID> = []
    @Published private(set) var error: String?
    @Published private(set) var moreSets = false
    @Published private(set) var moreMembers = false
    @Published private(set) var moreDrives = false
    private let repository: DriveSetRepository
    private let identities: PhysicalDriveRepository
    private let database: CatalogDatabase
    private var setCursor: DriveSetCursor?
    private var memberCursor: PhysicalDriveID?
    private var driveCursor: PhysicalDriveID?
    init(database: CatalogDatabase) {
        self.database = database
        repository = DriveSetRepository(database: database)
        identities = PhysicalDriveRepository(database: database)
        refresh()
    }
    func refresh() {
        perform {
            let page = try repository.list()
            sets = page.records; moreSets = page.next != nil; setCursor = page.next
            if let prior = selected { selected = try repository.set(id: prior.id) }
            try loadMembers()
        }
    }
    func nextSets() {
        perform {
            guard let cursor = setCursor else { return }
            let page = try repository.list(after: cursor)
            sets = page.records; moreSets = page.next != nil; setCursor = page.next
        }
    }
    func select(_ record: DriveSet) {
        perform {
            guard let current = try repository.set(id: record.id) else { throw DriveSetError.notFound }
            selected = current; try loadMembers()
        }
    }
    @discardableResult func create(name: String) -> Bool {
        perform { selected = try repository.create(name: name); try loadMembers(); try reloadSets() }
    }
    @discardableResult func rename(name: String) -> Bool {
        perform {
            guard let record = selected else { throw DriveSetError.notFound }
            selected = try repository.rename(id: record.id, expectedRevision: record.revision, name: name)
            try reloadSets()
        }
    }
    @discardableResult func deleteSelected() -> Bool {
        perform {
            guard let record = selected else { throw DriveSetError.notFound }
            try repository.delete(id: record.id, expectedRevision: record.revision)
            selected = nil; members = []; try reloadSets()
        }
    }
    func showDrives() {
        driveCursor = nil
        perform { try loadDrives() }
    }
    func nextDrives() {
        guard moreDrives, let last = available.last else { return }
        driveCursor = last.id
        perform { try loadDrives() }
    }
    func nextMembers() {
        guard moreMembers, let last = members.last else { return }
        memberCursor = last.id
        perform { try loadMembers(reset: false) }
    }
    @discardableResult func membership(_ drive: PhysicalDrive, included: Bool) -> Bool {
        perform {
            guard let record = selected else { throw DriveSetError.notFound }
            selected = try repository.setMembership(setID: record.id, expectedRevision: record.revision,
                driveID: drive.id, expectedDriveRevision: drive.revision, included: included)
            try loadMembers(); try loadDrives()
        }
    }
    /// Creating a local record is separate from selecting its set membership.
    @discardableResult func createLocalRecord(label: String) -> Bool {
        perform {
            let name = label.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, name.utf8.count <= 256, !name.contains("\0") else { throw DriveSetError.invalidName }
            let created = try identities.createDrive(label: name, provenance: "User explicitly created an unverified local organization record in Drive Sets")
            // Start at this record's page so the new record is immediately selectable.
            driveCursor = nil; try loadDrives()
            if !available.contains(where: { $0.id == created.id }) {
                available = [created]; moreDrives = false
            }
        }
    }
    private func reloadSets() throws {
        let page = try repository.list(); sets = page.records; setCursor = page.next; moreSets = page.next != nil
    }
    private func loadMembers(reset: Bool = true) throws {
        if reset { memberCursor = nil }
        guard let record = selected else { members = []; moreMembers = false; return }
        let page = try repository.members(setID: record.id, after: memberCursor)
        members = page.records; moreMembers = page.isTruncated
    }
    private func loadDrives() throws {
        let page = try identities.drives(after: driveCursor)
        available = page.records; moreDrives = page.isTruncated
        included = []
        guard let record = selected else { return }
        guard !available.isEmpty else { return }
        let placeholders = Array(repeating: "?", count: available.count).joined(separator: ",")
        let rows = try database.query("SELECT physical_drive_id FROM drive_set_memberships WHERE set_id=? AND physical_drive_id IN (\(placeholders)) LIMIT 200",
            bindings: [.text(record.id.rawValue.uuidString)] + available.map { .text($0.id.rawValue.uuidString) })
        included = Set(rows.compactMap { $0["physical_drive_id"]?.stringValue.flatMap(UUID.init(uuidString:)).map { PhysicalDriveID(rawValue: $0) } })
    }
    @discardableResult private func perform(_ action: () throws -> Void) -> Bool {
        do { try action(); error = nil; return true }
        catch let failure as DriveSetError { error = failure.localizedDescription }
        catch { self.error = "The catalog could not complete this action. Refresh and try again." }
        return false
    }
}

struct DriveSetsView: View {
    @StateObject private var model: DriveSetsModel
    @State private var editor: Editor?
    @State private var name = ""
    @State private var localLabel = ""
    @State private var addingDrives = false
    @State private var deleting = false
    @State private var removing: PhysicalDrive?
    private enum Editor: String, Identifiable { case create, rename; var id: String { rawValue } }
    init(database: CatalogDatabase) { _model = StateObject(wrappedValue: DriveSetsModel(database: database)) }
    init(model: DriveSetsModel) { _model = StateObject(wrappedValue: model) }
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Drive Sets").font(.title2.bold())
                Spacer()
                Button("Refresh", action: model.refresh)
                Button("New Drive Set") { name = ""; editor = .create }
                    .buttonStyle(FSDPrimaryActionButtonStyle())
            }
            Text("Organize local drive records. Hardware identity and connection status are not verified.")
                .foregroundStyle(.secondary)
            errorMessage
            HSplitView {
                VStack(alignment: .leading) {
                    if model.sets.isEmpty { Text("No Drive Sets yet. Create a set to start organizing.").padding() }
                    List {
                        ForEach(model.sets, id: \.id) { record in
                            Button { model.select(record) } label: {
                                Label(record.name, systemImage: "externaldrive.badge.person.crop")
                                    .frame(maxWidth: .infinity, alignment: .leading).padding(6)
                                    .background(model.selected?.id == record.id ? FSDDesignTokens.selected : .clear)
                            }.buttonStyle(.plain)
                        }
                    }.accessibilityLabel("Drive Sets")
                    HStack {
                        Button("First Page", action: model.refresh)
                        Button("Next Page", action: model.nextSets).disabled(!model.moreSets)
                    }
                }.frame(minWidth: 220, idealWidth: 260, maxWidth: 350)
                VStack(alignment: .leading, spacing: 12) {
                    if let selected = model.selected {
                        HStack {
                            Text(selected.name).font(.headline)
                            Spacer()
                            Button("Rename") { name = selected.name; editor = .rename }
                            Button("Delete Set", role: .destructive) { deleting = true }
                        }
                        Button("Add Local Records") { model.showDrives(); addingDrives = true }
                        if model.members.isEmpty { Text("This Drive Set is empty. Add a local record; empty sets are kept.").foregroundStyle(.secondary).padding(.vertical) }
                        List {
                            ForEach(model.members, id: \.id) { drive in
                                HStack {
                                    driveLabel(drive)
                                    Spacer()
                                    Button("Remove") { removing = drive }.buttonStyle(.borderless)
                                }
                            }
                        }.accessibilityLabel("Drive Set members")
                        HStack {
                            Button("First Page") { model.select(selected) }
                            Button("Next Page", action: model.nextMembers).disabled(!model.moreMembers)
                        }
                    } else {
                        Text("Select a Drive Set").font(.headline)
                        Text("A record can belong to several sets. Sets do not change snapshots or Collections.").foregroundStyle(.secondary)
                        Spacer()
                    }
                }.padding().frame(minWidth: 420)
            }
        }
        .padding(24).background(FSDDesignTokens.window)
        .sheet(item: $editor) { kind in
            VStack(alignment: .leading, spacing: 16) {
                Text(kind == .rename ? "Rename Drive Set" : "New Drive Set").font(.headline)
                TextField("Drive Set name", text: $name).accessibilityIdentifier("DriveSetName")
                    .textFieldStyle(.roundedBorder)
                errorMessage
                HStack {
                    Spacer(); Button("Cancel") { editor = nil }.keyboardShortcut(.cancelAction)
                    Button("Save") {
                        let success = kind == .rename ? model.rename(name: name) : model.create(name: name)
                        if success { editor = nil }
                    }.keyboardShortcut(.defaultAction)
                }
            }.padding(24).frame(width: 460)
        }
        .sheet(isPresented: $addingDrives) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Add Local Records").font(.headline)
                Text("Unverified local records • connection status unknown. Select each record explicitly.").foregroundStyle(.secondary)
                errorMessage
                if model.available.isEmpty { Text("No local drive records yet. Create an unverified local record to organize it.") }
                List {
                    ForEach(model.available, id: \.id) { drive in
                        HStack {
                            driveLabel(drive); Spacer()
                            Button(model.included.contains(drive.id) ? "Added" : "Add") { model.membership(drive, included: true) }
                                .buttonStyle(.borderless)
                                .disabled(drive.retired || model.included.contains(drive.id))
                        }
                    }
                }
                DisclosureGroup("New Unverified Local Record") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Creates a local organization record without detecting or verifying hardware. Add it to the set explicitly afterward.").font(.caption)
                        HStack {
                            TextField("Local record label", text: $localLabel).accessibilityIdentifier("LocalRecordLabel").textFieldStyle(.roundedBorder)
                            Button("Create Local Record") { if model.createLocalRecord(label: localLabel) { localLabel = "" } }
                        }
                    }.padding(.vertical, 8)
                }
                HStack {
                    Button("First Page", action: model.showDrives)
                    Button("Next Page", action: model.nextDrives).disabled(!model.moreDrives)
                    Spacer()
                    Button("Done") { addingDrives = false }.keyboardShortcut(.cancelAction)
                }
            }.padding(24).frame(width: 680, height: 450)
        }
        .confirmationDialog("Delete this Drive Set? Local records and their evidence are kept.", isPresented: $deleting) {
            Button("Delete Drive Set", role: .destructive) { model.deleteSelected() }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Remove local record from this set?", isPresented: Binding(get: { removing != nil }, set: { if !$0 { removing = nil } })) {
            Button("Remove from Set", role: .destructive) { if let drive = removing { model.membership(drive, included: false) }; removing = nil }
            Button("Cancel", role: .cancel) { removing = nil }
        } message: { Text("The local record and its evidence are kept.") }
    }
    @ViewBuilder private var errorMessage: some View {
        if let error = model.error { Text(error).foregroundStyle(FSDDesignTokens.destructive).textSelection(.enabled).accessibilityLabel("Drive Sets error: \(error)") }
    }
    private func driveLabel(_ drive: PhysicalDrive) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(drive.label ?? "Unnamed local record")
            Text(drive.retired ? "Retired • unverified local record" : "Unverified local record • connection unknown").font(.caption).foregroundStyle(.secondary)
            Text(drive.id.rawValue.uuidString).font(.caption2).foregroundStyle(.secondary).textSelection(.enabled)
        }
    }
}
