import SwiftUI

enum FSDDesignTokens {
    static let window = Color(red: 0.055, green: 0.067, blue: 0.083)
    static let sidebar = Color(red: 0.043, green: 0.053, blue: 0.067)
    static let panel = Color(red: 0.082, green: 0.098, blue: 0.12)
    static let raisedPanel = Color(red: 0.105, green: 0.125, blue: 0.15)
    static let hover = Color(red: 0.12, green: 0.145, blue: 0.18)
    static let selected = Color(red: 0.08, green: 0.22, blue: 0.39)
    static let separator = Color(red: 0.14, green: 0.165, blue: 0.20)
    static let primaryText = Color(red: 0.92, green: 0.94, blue: 0.97)
    static let secondaryText = Color(red: 0.62, green: 0.67, blue: 0.73)
    static let mutedText = Color(red: 0.43, green: 0.49, blue: 0.56)
    static let accent = Color(red: 0.20, green: 0.55, blue: 0.98)
    static let connected = Color(red: 0.28, green: 0.78, blue: 0.55)
    static let warning = Color(red: 0.95, green: 0.68, blue: 0.24)
    static let destructive = Color(red: 0.96, green: 0.35, blue: 0.37)

    static let sidebarWidth: CGFloat = 194
    static let toolbarHeight: CGFloat = 47
    static let cornerRadius: CGFloat = 8
    static let smallCornerRadius: CGFloat = 6
    static let pageSpacing: CGFloat = 14
}

private enum FSDDestination: Hashable {
    case libraryOverview
    case allDrives
    case recentCaptures
    case comparisons
    case capture

    var breadcrumb: String {
        switch self {
        case .libraryOverview: return "FSD  ›  Library"
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
        HStack(spacing: 0) {
            FSDSidebarView(selection: $selection)
                .frame(width: FSDDesignTokens.sidebarWidth)

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
        .foregroundStyle(FSDDesignTokens.primaryText)
        .preferredColorScheme(.dark)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brand
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 14)

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 12) {
                    sectionTitle("HOME")
                    navigationRow("Library Overview", icon: "square.grid.2x2", destination: .libraryOverview)

                    sectionTitle("LIBRARY")
                    navigationRow("All Drives", icon: "externaldrive", destination: .allDrives)
                    navigationRow("Recent Captures", icon: "clock.arrow.circlepath", destination: .recentCaptures)

                    HStack {
                        sectionTitle("DRIVE SETS")
                        Spacer(minLength: 4)
                        Button {} label: {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(FSDDesignTokens.mutedText)
                        }
                        .buttonStyle(.plain)
                        .disabled(true)
                        .help("Drive Sets are not available yet.")
                        .accessibilityLabel("New Drive Set unavailable")
                        .accessibilityHint("Drive Set support is not available yet.")
                    }
                    .padding(.top, 1)
                    Text("Drive Sets unavailable")
                        .font(.system(size: 10.5))
                        .foregroundStyle(FSDDesignTokens.mutedText)
                        .padding(.leading, 8)
                        .accessibilityLabel("Drive Sets unavailable. Drive Set support is not available yet.")

                    sectionTitle("COMPARE")
                    navigationRow("Comparisons", icon: "arrow.left.arrow.right", destination: .comparisons)

                    sectionTitle("CONNECTED NOW")
                    Label("No connected-drive service yet", systemImage: "externaldrive")
                        .font(.system(size: 10.5))
                        .foregroundStyle(FSDDesignTokens.mutedText)
                        .labelStyle(.titleAndIcon)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 10)
                        .accessibilityElement(children: .combine)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 14)
            }
            .scrollIndicators(.hidden)

            Rectangle()
                .fill(FSDDesignTokens.separator)
                .frame(height: 1)

            Button {} label: {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(FSDDesignTokens.accent.opacity(0.72))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto Capture")
                            .font(.system(size: 11.5, weight: .medium))
                        Text("Unavailable")
                            .font(.system(size: 9.5))
                    }
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8.5))
                }
                .foregroundStyle(FSDDesignTokens.secondaryText.opacity(0.72))
                .padding(.horizontal, 9)
                .padding(.vertical, 8)
                .background(FSDDesignTokens.selected.opacity(0.22), in: RoundedRectangle(cornerRadius: FSDDesignTokens.smallCornerRadius))
                .overlay(RoundedRectangle(cornerRadius: FSDDesignTokens.smallCornerRadius).stroke(FSDDesignTokens.accent.opacity(0.20), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(true)
            .help("Auto Capture is unavailable until a connected-drive service exists.")
            .accessibilityLabel("Auto Capture, unavailable")
            .accessibilityHint("Automatic capture is not available yet.")
            .padding(10)
        }
        .background(FSDDesignTokens.sidebar)
    }

    private var brand: some View {
        HStack(spacing: 10) {
            Text("F")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(FSDDesignTokens.accent)
                .frame(width: 28, height: 28)
                .background(FSDDesignTokens.selected.opacity(0.38), in: RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(FSDDesignTokens.accent.opacity(0.34), lineWidth: 1))
            VStack(alignment: .leading, spacing: 2) {
                Text("FSD")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .tracking(0.5)
                Text("FISHSOCK DIFFER")
                    .font(.system(size: 8, weight: .medium))
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
            .font(.system(size: 9, weight: .bold))
            .tracking(1.05)
            .foregroundStyle(FSDDesignTokens.mutedText)
            .padding(.horizontal, 8)
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
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .frame(width: 16)
                Text(title)
                    .font(.system(size: 11.5, weight: isSelected ? .semibold : .regular))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .foregroundStyle(isSelected ? FSDDesignTokens.primaryText : FSDDesignTokens.secondaryText)
            .padding(.horizontal, 8)
            .frame(height: 29)
            .background(
                isSelected ? FSDDesignTokens.selected : (isHovered ? FSDDesignTokens.hover : .clear),
                in: RoundedRectangle(cornerRadius: FSDDesignTokens.smallCornerRadius)
            )
            .overlay(alignment: .leading) {
                if isSelected {
                    Capsule().fill(FSDDesignTokens.accent).frame(width: 2, height: 16)
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
                    .font(.system(size: 10))
                    .foregroundStyle(FSDDesignTokens.accent)
                Text(selection.breadcrumb)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(FSDDesignTokens.secondaryText)
                    .lineLimit(1)
            }
            Spacer(minLength: 12)
            HStack(spacing: 6) {
                toolbarButton("Capture", icon: "plus", isActive: selection == .capture) {
                    onSelect(.capture)
                }
                Button {} label: {
                    Label("Search", systemImage: "magnifyingglass")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(FSDDesignTokens.mutedText)
                        .padding(.horizontal, 8)
                        .frame(height: 27)
                        .background(FSDDesignTokens.panel.opacity(0.55), in: RoundedRectangle(cornerRadius: 5))
                        .frame(minHeight: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(true)
                .help("Library-wide search is not available yet. Search within an individual snapshot from its browser.")
                .accessibilityLabel("Search unavailable")
                .accessibilityHint("Library-wide search is not available. Search within a snapshot from its browser.")
                toolbarButton("Compare", icon: "arrow.left.arrow.right", isActive: selection == .comparisons) {
                    onSelect(.comparisons)
                }
                toolbarButton("History", icon: "clock.arrow.circlepath", isActive: selection == .recentCaptures) {
                    onSelect(.recentCaptures)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: FSDDesignTokens.toolbarHeight)
        .background(FSDDesignTokens.window)
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
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(isActive ? FSDDesignTokens.primaryText : FSDDesignTokens.secondaryText)
                .padding(.horizontal, 8)
                .frame(height: 27)
                .background(
                    isActive ? FSDDesignTokens.selected : (isHovered ? FSDDesignTokens.hover : FSDDesignTokens.panel),
                    in: RoundedRectangle(cornerRadius: 5)
                )
                .frame(minHeight: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .accessibilityLabel(title)
    }
}

private struct LibraryOverviewView: View {
    @ObservedObject var model: ApplicationModel
    let onCapture: () -> Void
    let onComparisons: () -> Void
    let onHistory: () -> Void
    let onOpenSnapshot: (SnapshotSummary) -> Void
    @State private var recentComparisons: [ComparisonRecord] = []
    @State private var comparisonsUnavailable = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: FSDDesignTokens.pageSpacing) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Library Overview")
                        .font(.system(size: 24, weight: .semibold))
                    Text("Browse saved captures and compare changes across snapshots.")
                        .font(.system(size: 12.5))
                        .foregroundStyle(FSDDesignTokens.secondaryText)
                }

                captureCard

                metricsSection

                HStack(alignment: .top, spacing: 20) {
                    recentComparisonsPanel
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    VStack(alignment: .leading, spacing: FSDDesignTokens.pageSpacing) {
                        recentCapturesPanel
                        recentDrivesPanel
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .frame(maxWidth: 1120, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .scrollIndicators(.hidden)
        .background(FSDDesignTokens.window)
        .onAppear(perform: loadRecentComparisons)
    }

    private var captureCard: some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(FSDDesignTokens.selected)
                    .frame(width: 44, height: 44)
                Image(systemName: "externaldrive.badge.plus")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(FSDDesignTokens.accent)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text("Choose a source to capture")
                        .font(.system(size: 13.5, weight: .semibold))
                    Text("MANUAL")
                        .font(.system(size: 7.5, weight: .bold))
                        .tracking(0.7)
                        .foregroundStyle(FSDDesignTokens.accent)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(FSDDesignTokens.selected, in: Capsule())
                }
                Text("Select a folder when you are ready. FSD records filesystem metadata only.")
                    .font(.system(size: 10.5))
                    .foregroundStyle(FSDDesignTokens.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Metadata only  ·  Content Not Verified")
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(FSDDesignTokens.mutedText)
            }
            Spacer(minLength: 8)
            Button(action: onCapture) {
                Label("Capture", systemImage: "arrow.right")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 11)
                    .frame(height: 31)
                    .background(FSDDesignTokens.accent, in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open manual capture")
            .accessibilityHint("Opens the existing folder selection and metadata capture workflow.")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(minHeight: 78)
        .background(FSDDesignTokens.raisedPanel, in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius).stroke(FSDDesignTokens.separator, lineWidth: 1))
        .accessibilityElement(children: .contain)
    }

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Library Overview")
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(FSDDesignTokens.primaryText)

            HStack(spacing: 0) {
                OverviewMetricCell(title: "Drives", value: "—", note: "Registry unavailable")
                metricDivider
                OverviewMetricCell(title: "Snapshots", value: "\(model.history.count)", note: "Saved captures")
                metricDivider
                OverviewMetricCell(title: "Items", value: "—", note: "Aggregate unavailable")
                metricDivider
                OverviewMetricCell(title: "Storage", value: "—", note: "Aggregate unavailable")
            }
            .padding(.vertical, 2)
            .background(FSDDesignTokens.panel, in: RoundedRectangle(cornerRadius: FSDDesignTokens.smallCornerRadius))
            .overlay(RoundedRectangle(cornerRadius: FSDDesignTokens.smallCornerRadius).stroke(FSDDesignTokens.separator, lineWidth: 1))
        }
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(FSDDesignTokens.separator)
            .frame(width: 1, height: 43)
    }

    private var recentComparisonsPanel: some View {
        OverviewSection(title: "Recent Comparisons", trailingTitle: "View all", action: onComparisons) {
            if comparisonsUnavailable {
                OverviewMessageRow(icon: "exclamationmark.circle", text: "Comparison history is unavailable.")
            } else if recentComparisons.isEmpty {
                OverviewMessageRow(icon: "arrow.left.arrow.right", text: "No comparisons yet.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(recentComparisons.enumerated()), id: \.element.id) { index, record in
                        Button(action: onComparisons) {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(FSDDesignTokens.accent)
                                    .frame(width: 25, height: 25)
                                    .background(FSDDesignTokens.selected.opacity(0.7), in: RoundedRectangle(cornerRadius: 6))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(record.mode.label)
                                        .font(.system(size: 11, weight: .medium))
                                        .lineLimit(1)
                                    Text("\(record.totalDifferences) differences  ·  \(record.startedAt)")
                                        .font(.system(size: 9.5))
                                        .foregroundStyle(FSDDesignTokens.secondaryText)
                                        .lineLimit(1)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(FSDDesignTokens.mutedText)
                            }
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Open comparisons, \(record.mode.label), \(record.totalDifferences) differences")
                        if index < recentComparisons.count - 1 {
                            overviewSeparator
                        }
                    }
                }
            }
        }
    }

    private var recentCapturesPanel: some View {
        OverviewSection(title: "Recent Captures", trailingTitle: "View all", action: onHistory) {
            if model.history.isEmpty {
                OverviewMessageRow(icon: "clock.arrow.circlepath", text: "No captures yet.")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(model.history.prefix(3).enumerated()), id: \.element.id) { index, summary in
                        Button {
                            onOpenSnapshot(summary)
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "square.stack.3d.up")
                                    .font(.system(size: 12))
                                    .foregroundStyle(FSDDesignTokens.accent)
                                    .frame(width: 25, height: 25)
                                    .background(FSDDesignTokens.selected.opacity(0.7), in: RoundedRectangle(cornerRadius: 6))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(summary.displayName)
                                        .font(.system(size: 11, weight: .medium))
                                        .lineLimit(1)
                                    Text("\(snapshotStatus(summary.status))  ·  \(summary.startedAt)")
                                        .font(.system(size: 9.5))
                                        .foregroundStyle(FSDDesignTokens.secondaryText)
                                        .lineLimit(1)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(FSDDesignTokens.mutedText)
                            }
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Browse snapshot \(summary.displayName), \(snapshotStatus(summary.status)), captured \(summary.startedAt)")
                        if index < min(model.history.count, 3) - 1 {
                            overviewSeparator
                        }
                    }
                }
            }
        }
    }

    private var recentDrivesPanel: some View {
        OverviewSection(title: "Recent Drives", trailingTitle: nil, action: nil) {
            OverviewMessageRow(
                icon: "externaldrive",
                text: "Drive registry is not available yet. Saved captures remain available in Recent Captures."
            )
        }
    }

    private var overviewSeparator: some View {
        Rectangle().fill(FSDDesignTokens.separator).frame(height: 1)
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

    private func snapshotStatus(_ status: SnapshotStatus) -> String {
        status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

private struct OverviewMetricCell: View {
    let title: String
    let value: String
    let note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 8.5, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(FSDDesignTokens.mutedText)
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(value == "—" ? FSDDesignTokens.mutedText : FSDDesignTokens.primaryText)
            Text(note)
                .font(.system(size: 8.5))
                .foregroundStyle(FSDDesignTokens.secondaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value). \(note)")
    }
}

private struct OverviewSection<Content: View>: View {
    let title: String
    let trailingTitle: String?
    let action: (() -> Void)?
    let content: Content

    init(title: String, trailingTitle: String?, action: (() -> Void)?, @ViewBuilder content: () -> Content) {
        self.title = title
        self.trailingTitle = trailingTitle
        self.action = action
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(FSDDesignTokens.primaryText)
                Spacer()
                if let trailingTitle, let action {
                    Button(trailingTitle, action: action)
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundStyle(FSDDesignTokens.accent)
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(trailingTitle) \(title)")
                }
            }
            .padding(.bottom, 7)
            Rectangle()
                .fill(FSDDesignTokens.separator)
                .frame(height: 1)
            content
                .frame(maxWidth: .infinity, minHeight: 28, alignment: .topLeading)
                .padding(.top, 5)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
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
                .background(FSDDesignTokens.raisedPanel.opacity(0.76), in: RoundedRectangle(cornerRadius: 5))
            Text(text)
                .font(.system(size: 10.5))
                .foregroundStyle(FSDDesignTokens.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
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
            VStack(alignment: .leading, spacing: 8) {
                Text("Snapshot history").font(.system(size: 17, weight: .semibold)).padding(.horizontal, 12).padding(.top, 14)
                Text("Stored in the catalog. Browsing works with the source disconnected.")
                    .font(.caption).foregroundStyle(.secondary).padding(.horizontal, 12)
                if model.history.isEmpty {
                    EmptyStateView(
                        title: "No snapshots yet",
                        systemImage: "square.stack.3d.up.slash",
                        detail: "Use Capture to record the first metadata snapshot."
                    )
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
                }
                Spacer()
            }
            .frame(minWidth: 300, idealWidth: 340)
            if let browser = model.browser {
                SnapshotBrowserView(model: browser)
                    .id(browser.summary.id)
                    .frame(minWidth: 560)
            } else {
                EmptyStateView(
                    title: "Select a snapshot",
                    systemImage: "sidebar.right",
                    detail: "Choose a capture to browse its stored metadata offline."
                )
                .frame(minWidth: 560)
            }
        }
        .background(FSDDesignTokens.window)
    }
}

private struct FSDCaptureScreen: View {
    @ObservedObject var model: ApplicationModel

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Metadata Capture").font(.system(size: 20, weight: .semibold))
                Spacer()
                Button("Choose Source…", action: model.chooseSource)
                    .disabled(model.captureState.isActive)
                    .accessibilityLabel("Choose source folder")
            }
            if let recoveryMessage = model.recoveryMessage {
                Label(recoveryMessage, systemImage: "arrow.clockwise.circle")
                    .foregroundStyle(FSDDesignTokens.warning)
            }
            GroupBox("Capture") {
                VStack(alignment: .leading, spacing: 10) {
                    Text(model.selectedSource?.path ?? "No folder selected")
                        .font(.callout)
                        .foregroundStyle(model.selectedSource == nil ? FSDDesignTokens.secondaryText : FSDDesignTokens.primaryText)
                        .lineLimit(2)
                    HStack {
                        Button("Start Metadata Capture", action: model.startCapture)
                            .disabled(model.selectedSource == nil || model.captureState.isActive)
                        if model.captureState.isActive {
                            Button("Cancel", action: model.cancelCapture)
                        }
                        Spacer()
                        Text(model.captureState.title).foregroundStyle(FSDDesignTokens.secondaryText)
                        if case let .failed(message) = model.captureState {
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(FSDDesignTokens.destructive)
                        }
                    }
                    if model.captureState.isActive || model.captureProgress.processedEntries > 0 {
                        ProgressView()
                        Text("\(model.captureProgress.processedEntries) entries — \(model.captureProgress.phase)")
                            .font(.caption)
                            .foregroundStyle(FSDDesignTokens.secondaryText)
                        if !model.captureProgress.currentPath.isEmpty {
                            Text(model.captureProgress.currentPath)
                                .font(.caption2)
                                .foregroundStyle(FSDDesignTokens.secondaryText)
                                .lineLimit(1)
                        }
                    }
                    Text("Metadata only. Content Not Verified.")
                        .font(.caption)
                        .foregroundStyle(FSDDesignTokens.secondaryText)
                }
                .padding(4)
            }
            Text(model.catalogDiagnostics)
                .font(.caption2)
                .foregroundStyle(FSDDesignTokens.secondaryText)
                .textSelection(.enabled)
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(FSDDesignTokens.window)
    }
}

private struct SnapshotHistoryRow: View {
    let summary: SnapshotSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(summary.displayName).font(.headline).lineLimit(1)
            HStack(spacing: 6) {
                Image(systemName: icon).foregroundStyle(tint)
                Text(statusText).foregroundStyle(tint)
                Text("·").foregroundStyle(.secondary)
                Text(summary.startedAt).foregroundStyle(.secondary)
            }
            .font(.caption)
            Text("\(summary.totalFiles) files · \(summary.totalFolders) folders · "
                 + ByteCountFormatter.string(fromByteCount: summary.totalLogicalBytes, countStyle: .file))
                .font(.caption2).foregroundStyle(.secondary)
            Text("Source at capture: \(summary.capture.displayNameForHistory)")
                .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
        }
        .padding(.vertical, 2)
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
