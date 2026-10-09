import SwiftUI

enum FSDDesignTokens {
    static let window = Color(hex: 0x161A1F)
    static let sidebar = Color(hex: 0x11161C)
    static let inset = Color(hex: 0x11161C)
    static let panel = Color(hex: 0x20252C)
    static let raisedPanel = Color(hex: 0x2A3038)
    static let hover = raisedPanel
    static let toolbar = Color(hex: 0x1B2027)
    static let titlebar = Color(hex: 0x191E24)
    static let captureSurface = Color(hex: 0x202832)
    static let captureBorder = Color(hex: 0x384755)
    static let separator = Color(hex: 0x343C47)
    static let primaryText = Color(hex: 0xEDF1F6)
    static let mutedText = Color(hex: 0xA7B1BD)
    static let secondaryText = mutedText
    static let accent = Color(hex: 0x7AB6FF)
    static let primaryAction = Color(hex: 0x2463AA)
    static let selected = primaryAction.opacity(0.30)
    static let connected = Color(hex: 0x70D8A0)
    static let success = Color(hex: 0x70D8A0)
    static let warning = Color(hex: 0xFFD080)
    static let destructive = Color(hex: 0xFF9094)
    static let uncertain = Color(hex: 0xC7B8DE)

    static let sidebarBreakpoint: CGFloat = 1280
    static let compactSidebarWidth: CGFloat = 198
    static let desktopSidebarWidth: CGFloat = 224
    static let toolbarHeight: CGFloat = 50
    static let titlebarReferenceHeight: CGFloat = 38
    static let cornerRadius: CGFloat = 4
    static let smallCornerRadius: CGFloat = 4
    static let pageMaxContentWidth: CGFloat = 1540
    static let pageInsetHorizontal: CGFloat = 28
    static let pageInsetTop: CGFloat = 24
    static let pageInsetBottom: CGFloat = 32
    static let pageSpacing: CGFloat = 20
    static let homeGridGap: CGFloat = 28
    static let homeGridLeftWeight: CGFloat = 1.13
    static let homeGridRightWeight: CGFloat = 0.87
    static let homeGridMinimumRightWidth: CGFloat = 330
    static let recentDrivesSpacing: CGFloat = 19
    static let sidebarRowHeight: CGFloat = 34
    static let brandTileSize: CGFloat = 25
    static let overviewTitleSize: CGFloat = 22
    static let overviewSubtitleSize: CGFloat = 12
    static let sectionTitleSize: CGFloat = 13.5
    static let bodySize: CGFloat = 13
    static let labelSize: CGFloat = 10
    static let toolbarLabelSize: CGFloat = 12
    static let metricValueSize: CGFloat = 21
    static let metricLabelSize: CGFloat = 11

    static func sidebarWidth(for viewportWidth: CGFloat) -> CGFloat {
        viewportWidth < sidebarBreakpoint ? compactSidebarWidth : desktopSidebarWidth
    }
}

struct FSDPrimaryActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: FSDDesignTokens.bodySize, weight: .semibold))
            .foregroundStyle(FSDDesignTokens.primaryText)
            .padding(.horizontal, 14)
            .frame(minHeight: 34)
            .background(FSDDesignTokens.primaryAction, in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius).stroke(FSDDesignTokens.accent.opacity(0.22), lineWidth: 1))
            .opacity(isEnabled ? (configuration.isPressed ? 0.84 : 1) : 0.48)
            .contentShape(RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
    }
}

struct FSDSecondaryActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: FSDDesignTokens.bodySize, weight: .medium))
            .foregroundStyle(FSDDesignTokens.primaryText)
            .padding(.horizontal, 12)
            .frame(minHeight: 34)
            .background(
                configuration.isPressed ? FSDDesignTokens.raisedPanel : FSDDesignTokens.panel,
                in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius)
            )
            .overlay(RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius).stroke(FSDDesignTokens.separator, lineWidth: 1))
            .opacity(isEnabled ? 1 : 0.48)
            .contentShape(RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

private enum FSDDestination: Hashable {
    case libraryOverview
    case allDrives
    case recentCaptures
    case comparisons
    case capture

    var breadcrumb: String {
        switch self {
        case .libraryOverview: return "FSD  ›  Home"
        case .allDrives: return "Library  /  All Drives"
        case .recentCaptures: return "Library  /  Recent Captures"
        case .comparisons: return "Compare  /  Comparisons"
        case .capture: return "Library  /  Capture"
        }
    }
}

struct FSDAppShellView: View {
    @ObservedObject var model: ApplicationModel
    @State private var selection: FSDDestination
    @State private var homeSelectedSnapshotID: SnapshotID?

    init(model: ApplicationModel) {
        self.model = model
        var initial = FSDDestination.libraryOverview
        #if DEBUG
        if CommandLine.arguments.contains("-FSDSelectCompare") {
            initial = .comparisons
        } else if CommandLine.arguments.contains("-FSDSelectCapture") {
            initial = .capture
        }
        #endif
        _selection = State(initialValue: initial)
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                FSDSidebarView(selection: $selection)
                    .frame(width: FSDDesignTokens.sidebarWidth(for: geometry.size.width))

                Rectangle()
                    .fill(FSDDesignTokens.separator)
                    .frame(width: 1)

                VStack(spacing: 0) {
                    FSDTopBarView(selection: selection) { destination in
                        selection = destination
                    }
                    Rectangle()
                        .fill(FSDDesignTokens.separator)
                        .frame(height: 1)
                    destinationView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(FSDDesignTokens.window)
        }
        .background(FSDDesignTokens.window)
        .foregroundStyle(FSDDesignTokens.primaryText)
        .preferredColorScheme(.dark)
        .onChange(of: model.history.map(\.id)) { oldIDs, newIDs in
            guard newIDs != oldIDs,
                  let newlyCompletedID = SourceNavigatorSnapshotSelection.newlyCompletedSnapshotID(
                    selectedID: homeSelectedSnapshotID,
                    after: Set(oldIDs),
                    in: model.history
                  )
            else { return }
            homeSelectedSnapshotID = newlyCompletedID
        }
    }

    @ViewBuilder
    private var destinationView: some View {
        if let startupError = model.startupError {
            EmptyStateView(
                title: "Catalog unavailable",
                systemImage: "exclamationmark.triangle",
                detail: startupError
            )
            .foregroundStyle(FSDDesignTokens.primaryText)
        } else {
            switch selection {
            case .libraryOverview:
                LibraryOverviewView(
                    model: model,
                    selectedSnapshotID: $homeSelectedSnapshotID,
                    onCapture: { selection = .capture },
                    onComparisons: { selection = .comparisons },
                    onHistory: { selection = .recentCaptures },
                    onOpenSnapshot: { summary in
                        model.openSnapshot(summary)
                        selection = .recentCaptures
                    }
                )
            case .allDrives:
                FSDUnavailableDestinationView(
                    title: "All Drives",
                    subtitle: "Browse saved captures from Recent Captures.",
                    detail: "A per-drive library is not available yet. FSD does not detect mounted drives in this screen.",
                    systemImage: "externaldrive"
                )
            case .recentCaptures:
                FSDCaptureHistoryView(model: model)
            case .comparisons:
                if let catalog = model.database {
                    ComparisonDestinationView(database: catalog)
                } else {
                    EmptyStateView(title: "Catalog unavailable", systemImage: "exclamationmark.triangle")
                }
            case .capture:
                FSDCaptureScreen(model: model)
            }
        }
    }
}

private struct FSDSidebarView: View {
    @Binding var selection: FSDDestination
    @State private var isUnavailableExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brand
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 12)

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 8) {
                    sectionTitle("HOME")
                    navigationRow("Home", icon: "house", destination: .libraryOverview)

                    sectionTitle("LIBRARY")
                    navigationRow("Recent Captures", icon: "clock.arrow.circlepath", destination: .recentCaptures)

                    sectionTitle("COMPARE")
                    navigationRow("Comparisons", icon: "arrow.left.arrow.right", destination: .comparisons)

                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { isUnavailableExpanded || selection == .allDrives },
                            set: { isUnavailableExpanded = $0 }
                        )
                    ) {
                        VStack(alignment: .leading, spacing: 5) {
                            navigationRow("All Drives", icon: "externaldrive", destination: .allDrives)

                            Label("Drive Sets unavailable", systemImage: "rectangle.stack")
                                .font(.system(size: FSDDesignTokens.bodySize - 1))
                                .foregroundStyle(FSDDesignTokens.mutedText)
                                .padding(.horizontal, 10)
                                .frame(minHeight: 30, alignment: .leading)
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("Drive Sets unavailable. Drive Set support is not available yet.")

                            Label("No connected-drive service yet", systemImage: "externaldrive")
                                .font(.system(size: FSDDesignTokens.bodySize - 1))
                                .foregroundStyle(FSDDesignTokens.mutedText)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .accessibilityElement(children: .combine)

                            Button {} label: {
                                Label("Auto Capture unavailable", systemImage: "arrow.clockwise")
                                    .font(.system(size: FSDDesignTokens.bodySize - 1))
                                    .foregroundStyle(FSDDesignTokens.mutedText)
                                    .padding(.horizontal, 10)
                                    .frame(minHeight: 34, alignment: .leading)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(true)
                            .help("Auto Capture is unavailable until a connected-drive service exists.")
                            .accessibilityLabel("Auto Capture unavailable")
                            .accessibilityHint("Automatic capture is not available yet.")
                        }
                        .padding(.top, 5)
                    } label: {
                        Text("Not available yet")
                            .font(.system(size: FSDDesignTokens.bodySize - 1, weight: .medium))
                            .foregroundStyle(FSDDesignTokens.mutedText)
                    }
                    .tint(FSDDesignTokens.mutedText)
                    .padding(.top, 5)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
            .scrollIndicators(.hidden)

            Rectangle()
                .fill(FSDDesignTokens.separator)
                .frame(height: 1)
        }
        .background(FSDDesignTokens.sidebar)
    }

    private var brand: some View {
        HStack(spacing: 10) {
            Text("F")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(FSDDesignTokens.accent)
                .frame(width: FSDDesignTokens.brandTileSize, height: FSDDesignTokens.brandTileSize)
                .background(FSDDesignTokens.selected, in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
                .overlay(RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius).stroke(FSDDesignTokens.accent.opacity(0.34), lineWidth: 1))
            VStack(alignment: .leading, spacing: 2) {
                Text("FSD")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .tracking(0.5)
                Text("FISHSOCK DIFFER")
                    .font(.system(size: FSDDesignTokens.labelSize, weight: .medium))
                    .tracking(0.75)
                    .foregroundStyle(FSDDesignTokens.mutedText)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("FSD, FishSock Differ")
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: FSDDesignTokens.labelSize, weight: .bold))
            .tracking(1.05)
            .foregroundStyle(FSDDesignTokens.mutedText)
            .padding(.horizontal, 10)
            .padding(.top, 0)
    }

    private func navigationRow(_ title: String, icon: String, destination: FSDDestination) -> some View {
        SidebarNavigationRow(
            title: title,
            icon: icon,
            isSelected: selection == destination
        ) {
            selection = destination
        }
    }
}

private struct SidebarNavigationRow: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: FSDDesignTokens.bodySize, weight: isSelected ? .semibold : .regular))
                    .frame(width: 16)
                Text(title)
                    .font(.system(size: FSDDesignTokens.bodySize, weight: isSelected ? .semibold : .regular))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .foregroundStyle(isSelected ? FSDDesignTokens.primaryText : FSDDesignTokens.secondaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(minHeight: FSDDesignTokens.sidebarRowHeight)
            .background(
                isSelected ? FSDDesignTokens.selected : (isHovered ? FSDDesignTokens.hover : .clear),
                in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius)
            )
            .overlay(alignment: .leading) {
                if isSelected {
                    Rectangle().fill(FSDDesignTokens.accent).frame(width: 2, height: 16)
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityLabel(isSelected ? "\(title), selected" : title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct FSDTopBarView: View {
    let selection: FSDDestination
    let onSelect: (FSDDestination) -> Void

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: FSDDesignTokens.labelSize, weight: .semibold))
                    .foregroundStyle(FSDDesignTokens.accent)
                Text(selection.breadcrumb)
                    .font(.system(size: FSDDesignTokens.toolbarLabelSize, weight: .medium))
                    .foregroundStyle(FSDDesignTokens.secondaryText)
                    .lineLimit(1)
            }
            Spacer(minLength: 12)
            HStack(spacing: 6) {
                toolbarButton("Capture", icon: "plus", isActive: selection == .capture) {
                    onSelect(.capture)
                }
                toolbarButton("Compare", icon: "arrow.left.arrow.right", isActive: selection == .comparisons) {
                    onSelect(.comparisons)
                }
                toolbarButton("History", icon: "clock.arrow.circlepath", isActive: selection == .recentCaptures) {
                    onSelect(.recentCaptures)
                }
            }
        }
        .padding(.horizontal, 20)
        .frame(height: FSDDesignTokens.toolbarHeight)
        .background(FSDDesignTokens.toolbar)
    }

    private func toolbarButton(_ title: String, icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        TopBarActionButton(title: title, icon: icon, isActive: isActive, action: action)
    }
}

private struct TopBarActionButton: View {
    let title: String
    let icon: String
    let isActive: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.system(size: FSDDesignTokens.toolbarLabelSize, weight: .medium))
                .foregroundStyle(isActive ? FSDDesignTokens.primaryText : FSDDesignTokens.secondaryText)
                .padding(.horizontal, 10)
                .frame(height: 30)
                .background(
                    isActive ? FSDDesignTokens.selected : (isHovered ? FSDDesignTokens.hover : FSDDesignTokens.panel),
                    in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius)
                )
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityLabel(title)
    }
}

enum SourceNavigatorSnapshotSelection {
    static func resolve(_ selectedID: SnapshotID?, in history: [SnapshotSummary]) -> SnapshotSummary? {
        if let selectedID, let selected = history.first(where: { $0.id == selectedID }) {
            return selected
        }
        return history.first(where: \.isComplete) ?? history.first
    }

    static func canBrowse(_ summary: SnapshotSummary?) -> Bool {
        summary?.isComplete == true
    }

    static func latestCompletedSnapshotID(in history: [SnapshotSummary]) -> SnapshotID? {
        history.first(where: \.isComplete)?.id
    }

    static func newlyCompletedSnapshotID(
        selectedID: SnapshotID?,
        after priorIDs: Set<SnapshotID>,
        in history: [SnapshotSummary]
    ) -> SnapshotID? {
        guard selectedID == nil else { return nil }
        return history.first(where: { $0.isComplete && !priorIDs.contains($0.id) })?.id
    }
}

private struct LibraryOverviewView: View {
    @ObservedObject var model: ApplicationModel
    @Binding var selectedSnapshotID: SnapshotID?
    let onCapture: () -> Void
    let onComparisons: () -> Void
    let onHistory: () -> Void
    let onOpenSnapshot: (SnapshotSummary) -> Void
    @State private var recentComparisons: [ComparisonRecord] = []
    @State private var comparisonsUnavailable = false

    private var selectedSummary: SnapshotSummary? {
        SourceNavigatorSnapshotSelection.resolve(selectedSnapshotID, in: model.history)
    }

    private var visibleHistory: [SnapshotSummary] {
        var summaries = Array(model.history.prefix(5))
        if let selectedSummary, !summaries.contains(where: { $0.id == selectedSummary.id }) {
            summaries.append(selectedSummary)
        }
        return summaries
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                pageHeading
                if model.history.isEmpty {
                    emptyCatalog
                } else if let selectedSummary {
                    selectedCaptureCard(selectedSummary)
                    captureHistory
                }
                recentComparisonsSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, FSDDesignTokens.pageInsetBottom)
            .frame(maxWidth: FSDDesignTokens.pageMaxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .scrollIndicators(.hidden)
        .background(FSDDesignTokens.window)
        .onAppear {
            if selectedSnapshotID == nil {
                selectedSnapshotID = selectedSummary?.id
            }
            loadRecentComparisons()
        }
    }

    private var pageHeading: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Source Navigator")
                    .font(.system(size: FSDDesignTokens.overviewTitleSize, weight: .semibold))
                    .tracking(-0.2)
                    .accessibilityAddTraits(.isHeader)
                Text("Browse stored filesystem metadata from saved captures.")
                    .font(.system(size: FSDDesignTokens.overviewSubtitleSize))
                    .foregroundStyle(FSDDesignTokens.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            if !model.history.isEmpty {
                Button(action: onCapture) {
                    Label("Capture Snapshot", systemImage: "plus")
                        .frame(minHeight: 44)
                }
                .buttonStyle(FSDSecondaryActionButtonStyle())
                .accessibilityLabel("Open manual Capture")
                .accessibilityHint("Opens the existing folder selection and metadata capture workflow.")
            }
        }
    }

    private var emptyCatalog: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 23, weight: .regular))
                .foregroundStyle(FSDDesignTokens.accent)
                .accessibilityHidden(true)
            Text("No saved captures yet")
                .font(.system(size: FSDDesignTokens.sectionTitleSize, weight: .semibold))
                .foregroundStyle(FSDDesignTokens.primaryText)
                .accessibilityAddTraits(.isHeader)
            Text("Choose a source folder to create the first metadata snapshot. Capture is manual, and FSD stores filesystem metadata without verifying file contents.")
                .font(.system(size: FSDDesignTokens.bodySize))
                .foregroundStyle(FSDDesignTokens.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: onCapture) {
                Label("Capture Snapshot", systemImage: "plus")
                    .frame(minHeight: 44)
            }
            .buttonStyle(FSDPrimaryActionButtonStyle())
            .accessibilityLabel("Start manual Capture")
            .accessibilityHint("Opens the existing folder selection and metadata capture workflow.")
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FSDDesignTokens.panel, in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius).stroke(FSDDesignTokens.separator, lineWidth: 1))
        .accessibilityElement(children: .contain)
    }

    private func selectedCaptureCard(_ summary: SnapshotSummary) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SELECTED SAVED CAPTURE")
                        .font(.system(size: FSDDesignTokens.labelSize, weight: .bold))
                        .tracking(0.8)
                        .foregroundStyle(FSDDesignTokens.mutedText)
                    Text(recordedSourceLabel(for: summary))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(FSDDesignTokens.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Snapshot label: \(summary.displayName)  ·  Captured root: \(summary.scanRootName)")
                        .font(.system(size: FSDDesignTokens.overviewSubtitleSize))
                        .foregroundStyle(FSDDesignTokens.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                SourceNavigatorStatusBadge(status: summary.status)
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "questionmark.circle")
                    .foregroundStyle(FSDDesignTokens.warning)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Live source identity not verified")
                        .font(.system(size: FSDDesignTokens.bodySize, weight: .medium))
                        .foregroundStyle(FSDDesignTokens.primaryText)
                    Text("Original source connection is unverified. This view uses persisted capture facts and stored metadata.")
                        .font(.system(size: FSDDesignTokens.overviewSubtitleSize))
                        .foregroundStyle(FSDDesignTokens.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)

            HStack(spacing: 8) {
                SourceNavigatorMetadataCell(title: "Snapshot ID", value: "#\(summary.id.rawValue)")
                SourceNavigatorMetadataCell(title: "Captured at", value: summary.startedAt)
            }

            HStack(spacing: 0) {
                SourceNavigatorCountCell(title: "Files recorded", value: summary.totalFiles)
                SourceNavigatorCountCell(title: "Folders recorded", value: summary.totalFolders)
                SourceNavigatorCountCell(title: "Unreadable items", value: summary.inaccessibleItems)
                SourceNavigatorCountCell(title: "Warnings", value: summary.warningCount)
            }
            .padding(.vertical, 2)
            .background(FSDDesignTokens.inset, in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Captured metadata counts")

            captureActionRow(for: summary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FSDDesignTokens.panel, in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius).stroke(FSDDesignTokens.separator, lineWidth: 1))
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func captureActionRow(for summary: SnapshotSummary) -> some View {
        if SourceNavigatorSnapshotSelection.canBrowse(summary) {
            HStack(spacing: 10) {
                browseButton(for: summary)
                Spacer(minLength: 8)
                historyButton
                compareButton
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    browseButton(for: summary)
                    Text("This capture is incomplete. Select a completed capture to browse its stored metadata.")
                        .font(.system(size: FSDDesignTokens.bodySize - 0.5))
                        .foregroundStyle(FSDDesignTokens.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("This capture is incomplete. Select a completed capture to browse its stored metadata.")
                }

                HStack(spacing: 10) {
                    Spacer(minLength: 0)
                    if let latestCompletedID = SourceNavigatorSnapshotSelection.latestCompletedSnapshotID(in: model.history) {
                        Button {
                            selectedSnapshotID = latestCompletedID
                        } label: {
                            Label("Select latest complete", systemImage: "checkmark.circle")
                                .frame(minHeight: 34)
                        }
                        .buttonStyle(FSDSecondaryActionButtonStyle())
                        .accessibilityLabel("Select latest complete capture, snapshot #\(latestCompletedID.rawValue)")
                        .accessibilityHint("Selects this completed capture as the Home context. It does not open the snapshot.")
                    }
                    historyButton
                    compareButton
                }
            }
        }
    }

    private func browseButton(for summary: SnapshotSummary) -> some View {
        Button {
            onOpenSnapshot(summary)
        } label: {
            Label("Browse Snapshot", systemImage: "folder")
                .frame(minHeight: 44)
        }
        .buttonStyle(FSDPrimaryActionButtonStyle())
        .disabled(!SourceNavigatorSnapshotSelection.canBrowse(summary))
        .accessibilityLabel(
            SourceNavigatorSnapshotSelection.canBrowse(summary)
                ? "Browse snapshot #\(summary.id.rawValue)"
                : "Browse snapshot unavailable for partial capture #\(summary.id.rawValue)"
        )
        .accessibilityHint(
            SourceNavigatorSnapshotSelection.canBrowse(summary)
                ? "Opens this completed snapshot in the stored-metadata browser."
                : "This capture is partial. Select a completed capture to browse from Home."
        )
    }

    private var historyButton: some View {
        Button(action: onHistory) {
            Label("History", systemImage: "clock.arrow.circlepath")
                .frame(minHeight: 44)
        }
        .buttonStyle(FSDSecondaryActionButtonStyle())
        .accessibilityLabel("Open capture History")
    }

    private var compareButton: some View {
        Button(action: onComparisons) {
            Label("Compare", systemImage: "arrow.left.arrow.right")
                .frame(minHeight: 44)
        }
        .buttonStyle(FSDSecondaryActionButtonStyle())
        .accessibilityLabel("Open Compare workspace")
        .accessibilityHint("Opens the existing comparison workspace. Choose comparison sources there.")
    }

    private var captureHistory: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Capture History")
                    .font(.system(size: FSDDesignTokens.sectionTitleSize, weight: .semibold))
                    .foregroundStyle(FSDDesignTokens.primaryText)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button("View all") { onHistory() }
                    .buttonStyle(.plain)
                    .foregroundStyle(FSDDesignTokens.accent)
                    .accessibilityLabel("View all captures in History")
            }
            VStack(spacing: 0) {
                ForEach(Array(visibleHistory.enumerated()), id: \.element.id) { index, summary in
                    SourceNavigatorCaptureRow(
                        summary: summary,
                        sourceLabel: recordedSourceLabel(for: summary),
                        isSelected: summary.id == selectedSummary?.id
                    ) {
                        selectedSnapshotID = summary.id
                    }
                    if index < visibleHistory.count - 1 {
                        Rectangle().fill(FSDDesignTokens.separator).frame(height: 1)
                    }
                }
            }
            .background(FSDDesignTokens.panel, in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius).stroke(FSDDesignTokens.separator, lineWidth: 1))
        }
    }

    private var recentComparisonsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent Comparisons")
                    .font(.system(size: FSDDesignTokens.sectionTitleSize, weight: .semibold))
                    .foregroundStyle(FSDDesignTokens.primaryText)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button("Open Compare") { onComparisons() }
                    .buttonStyle(.plain)
                    .foregroundStyle(FSDDesignTokens.accent)
                    .accessibilityLabel("Open Compare workspace")
            }
            VStack(spacing: 0) {
                if comparisonsUnavailable {
                    OverviewMessageRow(icon: "exclamationmark.circle", text: "Comparison history is unavailable. The Compare workspace remains available.")
                        .padding(12)
                } else if recentComparisons.isEmpty {
                    OverviewMessageRow(icon: "arrow.left.arrow.right", text: "No saved comparisons yet. Open Compare to start from its existing source selectors.")
                        .padding(12)
                } else {
                    ForEach(Array(recentComparisons.enumerated()), id: \.element.id) { index, record in
                        Button(action: onComparisons) {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(FSDDesignTokens.accent)
                                    .frame(width: 25, height: 25)
                                    .background(FSDDesignTokens.selected, in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(record.mode.label)
                                        .font(.system(size: FSDDesignTokens.bodySize, weight: .medium))
                                        .foregroundStyle(FSDDesignTokens.primaryText)
                                    Text("\(record.totalDifferences) differences  ·  \(record.startedAt)")
                                        .font(.system(size: FSDDesignTokens.labelSize))
                                        .foregroundStyle(FSDDesignTokens.secondaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(FSDDesignTokens.mutedText)
                            }
                            .padding(.horizontal, 12)
                            .frame(minHeight: 52)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Open Compare, \(record.mode.label), \(record.totalDifferences) differences")
                        if index < recentComparisons.count - 1 {
                            Rectangle().fill(FSDDesignTokens.separator).frame(height: 1)
                        }
                    }
                }
            }
            .background(FSDDesignTokens.panel, in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius).stroke(FSDDesignTokens.separator, lineWidth: 1))
        }
        .onAppear(perform: loadRecentComparisons)
    }

    private func recordedSourceLabel(for summary: SnapshotSummary) -> String {
        guard let label = summary.capture.volumeDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines), !label.isEmpty else {
            return "Source label not recorded at capture time"
        }
        return label
    }

    private func loadRecentComparisons() {
        guard let database = model.database else {
            comparisonsUnavailable = true
            return
        }
        do {
            recentComparisons = try ComparisonResultRepository(database: database).listComparisons(limit: 3)
            comparisonsUnavailable = false
        } catch {
            recentComparisons = []
            comparisonsUnavailable = true
        }
    }
}

private struct SourceNavigatorStatusBadge: View {
    let status: SnapshotStatus

    private var title: String {
        switch status {
        case .scanning: return "In progress"
        case .complete: return "Complete"
        case .completeWithWarnings: return "Complete with warnings"
        case .interrupted: return "Interrupted · partial"
        case .cancelled: return "Cancelled · partial"
        case .failed: return "Failed · partial"
        }
    }

    private var tint: Color {
        switch status {
        case .complete: return FSDDesignTokens.success
        case .completeWithWarnings, .interrupted, .cancelled: return FSDDesignTokens.warning
        case .failed: return FSDDesignTokens.destructive
        case .scanning: return FSDDesignTokens.mutedText
        }
    }

    private var symbol: String {
        switch status {
        case .complete: return "checkmark.circle.fill"
        case .completeWithWarnings: return "exclamationmark.circle.fill"
        case .interrupted: return "pause.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .scanning: return "clock.fill"
        }
    }

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.system(size: FSDDesignTokens.labelSize, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Capture status: \(title)")
    }
}

private struct SourceNavigatorMetadataCell: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: FSDDesignTokens.labelSize, weight: .semibold))
                .tracking(0.7)
                .foregroundStyle(FSDDesignTokens.mutedText)
            Text(value)
                .font(.system(size: FSDDesignTokens.bodySize, weight: .medium, design: title == "Snapshot ID" ? .monospaced : .default))
                .foregroundStyle(FSDDesignTokens.primaryText)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(FSDDesignTokens.inset, in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

private struct SourceNavigatorCountCell: View {
    let title: String
    let value: Int64

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: FSDDesignTokens.labelSize, weight: .medium))
                .foregroundStyle(FSDDesignTokens.mutedText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(value.formatted())
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(FSDDesignTokens.primaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 46, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

private struct SourceNavigatorCaptureRow: View {
    let summary: SnapshotSummary
    let sourceLabel: String
    let isSelected: Bool
    let action: () -> Void

    private var statusText: String {
        switch summary.status {
        case .scanning: return "In progress"
        case .complete: return "Complete"
        case .completeWithWarnings: return "Complete with warnings"
        case .interrupted: return "Interrupted · partial"
        case .cancelled: return "Cancelled · partial"
        case .failed: return "Failed · partial"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? FSDDesignTokens.accent : FSDDesignTokens.mutedText)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(sourceLabel)
                        .font(.system(size: FSDDesignTokens.bodySize, weight: .medium))
                        .foregroundStyle(FSDDesignTokens.primaryText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Snapshot #\(summary.id.rawValue)  ·  \(statusText)  ·  \(summary.startedAt)")
                        .font(.system(size: FSDDesignTokens.labelSize))
                        .foregroundStyle(FSDDesignTokens.secondaryText)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(FSDDesignTokens.mutedText)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            .background(isSelected ? FSDDesignTokens.selected : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Select \(sourceLabel), snapshot #\(summary.id.rawValue), \(statusText), captured \(summary.startedAt)")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint("Selects this saved capture as the Home context. It does not open a content preview.")
    }
}

private struct OverviewMessageRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(FSDDesignTokens.mutedText)
                .frame(width: 22, height: 22)
                .background(FSDDesignTokens.raisedPanel, in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(FSDDesignTokens.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct FSDUnavailableDestinationView: View {
    let title: String
    let subtitle: String
    let detail: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.system(size: 25, weight: .semibold))
                Text(subtitle).font(.system(size: 11.5)).foregroundStyle(FSDDesignTokens.secondaryText)
            }
            EmptyStateView(title: title + " unavailable", systemImage: systemImage, detail: detail)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(FSDDesignTokens.panel, in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
                .overlay(RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius).stroke(FSDDesignTokens.separator, lineWidth: 1))
        }
        .padding(26)
        .frame(maxWidth: 1120, maxHeight: .infinity, alignment: .topLeading)
        .frame(maxWidth: .infinity, alignment: .center)
        .background(FSDDesignTokens.window)
    }
}

private struct FSDCaptureHistoryView: View {
    @ObservedObject var model: ApplicationModel

    var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Recent Captures")
                            .font(.system(size: FSDDesignTokens.overviewTitleSize, weight: .semibold))
                            .foregroundStyle(FSDDesignTokens.primaryText)
                        Spacer(minLength: 8)
                        Text("\(model.history.count) saved")
                            .font(.system(size: FSDDesignTokens.labelSize, weight: .medium))
                            .foregroundStyle(FSDDesignTokens.mutedText)
                    }
                    Text("Saved metadata snapshots remain available when the source is disconnected.")
                        .font(.system(size: FSDDesignTokens.overviewSubtitleSize))
                        .foregroundStyle(FSDDesignTokens.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 14)

                Rectangle()
                    .fill(FSDDesignTokens.separator)
                    .frame(height: 1)

                if model.history.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("No captures yet", systemImage: "square.stack.3d.up.slash")
                            .font(.system(size: FSDDesignTokens.bodySize, weight: .semibold))
                            .foregroundStyle(FSDDesignTokens.primaryText)
                        Text("Choose Capture to record the first metadata snapshot.")
                            .font(.system(size: FSDDesignTokens.bodySize))
                            .foregroundStyle(FSDDesignTokens.secondaryText)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    List(model.history, selection: Binding(
                        get: { model.selectedSnapshotID },
                        set: { newValue in
                            guard let newValue, let summary = model.history.first(where: { $0.id == newValue }) else {
                                model.closeSnapshot()
                                return
                            }
                            model.openSnapshot(summary)
                        }
                    )) { summary in
                        SnapshotHistoryRow(summary: summary).tag(summary.id)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .listRowInsets(EdgeInsets(top: 5, leading: 12, bottom: 5, trailing: 12))
                    .listRowSeparatorTint(FSDDesignTokens.separator)
                    .background(FSDDesignTokens.window)
                }
                Spacer()
            }
            .frame(minWidth: 300, idealWidth: 360)
            .background(FSDDesignTokens.window)

            if let browser = model.browser {
                SnapshotBrowserView(model: browser)
                    .id(browser.summary.id)
                    .frame(minWidth: 560)
            } else {
                VStack(spacing: 9) {
                    Image(systemName: "square.stack.3d.up")
                        .font(.system(size: 26, weight: .regular))
                        .foregroundStyle(FSDDesignTokens.accent)
                    Text("Select a capture")
                        .font(.system(size: FSDDesignTokens.sectionTitleSize, weight: .semibold))
                        .foregroundStyle(FSDDesignTokens.primaryText)
                    Text("Choose a saved capture to browse its stored metadata offline.")
                        .font(.system(size: FSDDesignTokens.bodySize))
                        .foregroundStyle(FSDDesignTokens.secondaryText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 340)
                }
                .frame(minWidth: 560)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(FSDDesignTokens.window)
            }
        }
        .background(FSDDesignTokens.window)
    }
}

private struct FSDCaptureScreen: View {
    @ObservedObject var model: ApplicationModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FSDDesignTokens.pageSpacing) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Capture")
                        .font(.system(size: FSDDesignTokens.overviewTitleSize, weight: .semibold))
                        .foregroundStyle(FSDDesignTokens.primaryText)
                    Text("Choose a source folder when you are ready. FSD records filesystem metadata only.")
                        .font(.system(size: FSDDesignTokens.overviewSubtitleSize))
                        .foregroundStyle(FSDDesignTokens.secondaryText)
                }

                if let recoveryMessage = model.recoveryMessage {
                    HStack(alignment: .top, spacing: 9) {
                        Image(systemName: "arrow.clockwise.circle")
                            .foregroundStyle(FSDDesignTokens.warning)
                        Text(recoveryMessage)
                            .font(.system(size: FSDDesignTokens.bodySize))
                            .foregroundStyle(FSDDesignTokens.primaryText)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(FSDDesignTokens.panel, in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
                    .overlay(RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius).stroke(FSDDesignTokens.separator, lineWidth: 1))
                }

                captureSurface
            }
            .padding(.horizontal, FSDDesignTokens.pageInsetHorizontal)
            .padding(.top, FSDDesignTokens.pageInsetTop)
            .padding(.bottom, FSDDesignTokens.pageInsetBottom)
            .frame(maxWidth: FSDDesignTokens.pageMaxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(FSDDesignTokens.window)
        .foregroundStyle(FSDDesignTokens.primaryText)
        .tint(FSDDesignTokens.accent)
    }

    private var captureSurface: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 12) {
                Image(systemName: "externaldrive")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(FSDDesignTokens.accent)
                    .frame(width: 42, height: 42)
                    .background(FSDDesignTokens.selected, in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))

                VStack(alignment: .leading, spacing: 4) {
                    Text(model.selectedSource == nil ? "Choose a source" : "Source selected")
                        .font(.system(size: FSDDesignTokens.sectionTitleSize, weight: .semibold))
                        .foregroundStyle(FSDDesignTokens.primaryText)
                    Text(selectedSourceLabel)
                        .font(.system(size: FSDDesignTokens.bodySize))
                        .foregroundStyle(model.selectedSource == nil ? FSDDesignTokens.secondaryText : FSDDesignTokens.primaryText)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .accessibilityLabel(model.selectedSource == nil ? "No source selected" : "Selected source: \(selectedSourceLabel)")
                }

                Spacer(minLength: 12)

                Button(action: model.chooseSource) {
                    Label("Choose Source", systemImage: "folder")
                }
                .buttonStyle(FSDSecondaryActionButtonStyle())
                .disabled(model.captureState.isActive)
                .accessibilityLabel("Choose Source")
            }

            Rectangle()
                .fill(FSDDesignTokens.separator)
                .frame(height: 1)

            HStack(spacing: 10) {
                Label("Metadata only · Content Not Verified", systemImage: "checkmark.shield")
                    .font(.system(size: FSDDesignTokens.labelSize, weight: .medium))
                    .foregroundStyle(FSDDesignTokens.mutedText)

                Spacer(minLength: 10)

                HStack(spacing: 6) {
                    Circle().fill(statusTint).frame(width: 7, height: 7)
                    Text(model.captureState.title)
                        .font(.system(size: FSDDesignTokens.bodySize, weight: .medium))
                        .foregroundStyle(statusTint)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Capture status: \(model.captureState.title)")

                if model.captureState.isActive {
                    Button("Cancel", action: model.cancelCapture)
                        .buttonStyle(FSDSecondaryActionButtonStyle())
                        .accessibilityLabel("Cancel metadata capture")
                }

                Button(action: model.startCapture) {
                    Label("Start Metadata Capture", systemImage: "arrow.right")
                }
                .buttonStyle(FSDPrimaryActionButtonStyle())
                .disabled(model.selectedSource == nil || model.captureState.isActive)
                .accessibilityLabel("Start Metadata Capture")
                .accessibilityHint(model.selectedSource == nil ? "Choose a source folder before starting capture." : "Records filesystem metadata only.")
            }

            if model.captureState.isActive || model.captureProgress.processedEntries > 0 {
                VStack(alignment: .leading, spacing: 7) {
                    ProgressView().tint(FSDDesignTokens.accent)
                    HStack(spacing: 8) {
                        Text("\(model.captureProgress.processedEntries) entries · \(model.captureProgress.phase)")
                            .font(.system(size: FSDDesignTokens.bodySize))
                            .foregroundStyle(FSDDesignTokens.secondaryText)
                        Spacer()
                        if !model.captureProgress.currentPath.isEmpty {
                            Text(URL(fileURLWithPath: model.captureProgress.currentPath).lastPathComponent)
                                .font(.system(size: FSDDesignTokens.labelSize))
                                .foregroundStyle(FSDDesignTokens.mutedText)
                                .lineLimit(1)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Capture progress: \(model.captureProgress.processedEntries) entries, \(model.captureProgress.phase)")
            }

            if case let .failed(message) = model.captureState {
                Text(message)
                    .font(.system(size: FSDDesignTokens.bodySize))
                    .foregroundStyle(FSDDesignTokens.destructive)
                    .accessibilityLabel("Capture failed: \(message)")
            }
        }
        .padding(16)
        .background(FSDDesignTokens.captureSurface, in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius).stroke(FSDDesignTokens.captureBorder, lineWidth: 1))
    }

    private var selectedSourceLabel: String {
        guard let selectedSource = model.selectedSource else { return "No source selected" }
        let name = selectedSource.lastPathComponent
        return name.isEmpty ? "Filesystem root" : name
    }

    private var statusTint: Color {
        switch model.captureState {
        case .idle: return FSDDesignTokens.secondaryText
        case .scanning: return FSDDesignTokens.accent
        case .cancelling, .interrupted, .cancelled, .completeWithWarnings: return FSDDesignTokens.warning
        case .complete: return FSDDesignTokens.success
        case .failed: return FSDDesignTokens.destructive
        }
    }
}

private struct SnapshotHistoryRow: View {
    let summary: SnapshotSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 9) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(FSDDesignTokens.accent)
                    .frame(width: 26, height: 26)
                    .background(FSDDesignTokens.selected, in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))

                VStack(alignment: .leading, spacing: 3) {
                    Text(summary.displayName)
                        .font(.system(size: FSDDesignTokens.bodySize, weight: .semibold))
                        .foregroundStyle(FSDDesignTokens.primaryText)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Image(systemName: icon).foregroundStyle(tint)
                        Text(statusText).foregroundStyle(tint)
                        Text("·").foregroundStyle(FSDDesignTokens.mutedText)
                        Text(summary.startedAt).foregroundStyle(FSDDesignTokens.secondaryText)
                    }
                    .font(.system(size: FSDDesignTokens.labelSize))
                    .lineLimit(1)
                }
            }

            HStack(spacing: 5) {
                Text("\(summary.totalFiles) files")
                Text("·")
                Text("\(summary.totalFolders) folders")
                Text("·")
                Text(ByteCountFormatter.string(fromByteCount: summary.totalLogicalBytes, countStyle: .file))
            }
            .font(.system(size: FSDDesignTokens.labelSize))
            .foregroundStyle(FSDDesignTokens.secondaryText)
            .lineLimit(1)

            Text("Source at capture: \(summary.capture.displayNameForHistory)")
                .font(.system(size: FSDDesignTokens.labelSize))
                .foregroundStyle(FSDDesignTokens.mutedText)
                .lineLimit(1)
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(summary.displayName), \(statusText), started \(summary.startedAt), \(summary.totalFiles) files, \(summary.totalFolders) folders, source at capture \(summary.capture.displayNameForHistory)")
    }

    private var statusText: String {
        summary.status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private var icon: String {
        switch summary.status {
        case .complete: return "checkmark.seal"
        case .completeWithWarnings: return "checkmark.seal.fill"
        case .interrupted: return "bolt.horizontal.circle"
        case .cancelled: return "xmark.circle"
        case .failed: return "exclamationmark.octagon"
        case .scanning: return "clock"
        }
    }

    private var tint: Color {
        switch summary.status {
        case .complete: return FSDDesignTokens.connected
        case .completeWithWarnings: return FSDDesignTokens.warning
        case .interrupted, .cancelled: return FSDDesignTokens.warning
        case .failed: return FSDDesignTokens.destructive
        case .scanning: return FSDDesignTokens.secondaryText
        }
    }
}

/// Shared empty-state presentation used by the comparison destination, the
/// creation view, the workspace view and the app shell. File-scope internal so
/// every UI file can use it without duplicating it per file.
struct EmptyStateView: View {
    let title: String
    let systemImage: String
    var detail: String?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage).font(.system(size: 36)).foregroundStyle(.secondary)
            Text(title).font(.title3)
            if let detail {
                Text(detail).foregroundStyle(.secondary).multilineTextAlignment(.center).frame(maxWidth: 420)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title + (detail.map { ", \($0)" } ?? ""))
    }
}

/// Bounded, user-facing descriptions for errors the comparison GUI surfaces.
/// The GUI never renders raw SQLite text when a bounded description exists.
enum ComparisonUIErrorDescription {
    static func message(for error: Error) -> String {
        if let comparisonError = error as? ComparisonError {
            switch comparisonError {
            case let .database(databaseError):
                return message(for: databaseError)
            case let .liveCaptureFailed(scannerError):
                return message(for: scannerError)
            case let .collisionGroupTooLarge(count):
                return "A single comparison identity has too many members (\(count)) to classify safely. No arbitrary pairing was performed."
            default:
                return comparisonError.errorDescription ?? "The comparison could not be completed."
            }
        }
        if let scannerError = error as? SnapshotScannerError {
            return message(for: scannerError)
        }
        if let databaseError = error as? CatalogDatabaseError {
            return message(for: databaseError)
        }
        if error is CancellationError {
            return "The comparison was cancelled."
        }
        return "An unexpected error occurred."
    }

    static func message(for error: SnapshotScannerError) -> String {
        switch error {
        case .captureFailed:
            // Fixed, bounded presentation. This case carries an arbitrary
            // underlying `localizedDescription` (raw SQLite, POSIX/Cocoa,
            // path or provider internals), so the carried string must never
            // reach the user. The user only needs to know the capture failed
            // and what they can do next.
            return "Metadata capture failed. Verify that the source is available and try again."
        default:
            // Provider, writer and detector conditions keep their own fixed
            // wording; nothing here interpolates underlying error text.
            return "The live source could not be captured as metadata."
        }
    }

    static func message(for error: CatalogDatabaseError) -> String {
        switch error {
        case .cannotOpen:
            return "The catalog could not be opened."
        case let .sqlite(code, _):
            // Bounded presentation: the raw SQLite message is suppressed.
            return "The catalog database reported an error (code \(code))."
        case .missingSchemaResource:
            return "The catalog schema resource is missing."
        case .unsupportedSchemaVersion:
            return "The catalog uses an unsupported schema version."
        case .foreignKeysNotEnabled:
            return "The catalog integrity guard is unavailable."
        case .invalidSchemaVersion:
            return "The catalog schema version is invalid."
        case .migrationFailed:
            return "The catalog could not be migrated."
        case .schemaStateInvalid:
            return "The catalog state is invalid."
        }
    }
}

/// Stable, textual outcome wording. Color is never the only status
/// indicator: every result row and summary pill carries these words, and
/// the canonical orientation (left = reference/before, right = changed/after)
/// is expressed in the wording for added/removed.
enum ComparisonOutcomeWording {
    static func label(for type: ComparisonResultType) -> String {
        switch type {
        case .matched: return "Matched"
        case .added: return "Added — found only on the right (changed) side"
        case .removed: return "Removed — found only on the left (reference) side"
        case .changed: return "Changed"
        case .uncertain: return "Uncertain — no deterministic conclusion"
        case .ignored: return "Ignored"
        }
    }

    static func shortLabel(for type: ComparisonResultType) -> String {
        switch type {
        case .matched: return "Matched"
        case .added: return "Added"
        case .removed: return "Removed"
        case .changed: return "Changed"
        case .uncertain: return "Uncertain"
        case .ignored: return "Ignored"
        }
    }
}
