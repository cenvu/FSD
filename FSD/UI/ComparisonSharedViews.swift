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
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 12)

            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 8) {
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
                .padding(.bottom, 12)
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
                            .font(.system(size: FSDDesignTokens.bodySize, weight: .medium))
                        Text("Unavailable")
                            .font(.system(size: FSDDesignTokens.labelSize))
                    }
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8.5))
                }
                .foregroundStyle(FSDDesignTokens.secondaryText.opacity(0.72))
                .padding(.horizontal, 9)
                .padding(.vertical, 8)
                .background(FSDDesignTokens.selected.opacity(0.22), in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
                .overlay(RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius).stroke(FSDDesignTokens.accent.opacity(0.20), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(true)
            .help("Auto Capture is unavailable until a connected-drive service exists.")
            .accessibilityLabel("Auto Capture, unavailable")
            .accessibilityHint("Automatic capture is not available yet.")
            .padding(8)
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
                Button {} label: {
                    Label("Search", systemImage: "magnifyingglass")
                        .font(.system(size: FSDDesignTokens.toolbarLabelSize, weight: .medium))
                        .foregroundStyle(FSDDesignTokens.mutedText.opacity(0.68))
                        .padding(.horizontal, 10)
                        .frame(height: 30)
                        .frame(minHeight: 44)
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
                VStack(alignment: .leading, spacing: 4) {
                    Text("Library Overview")
                        .font(.system(size: FSDDesignTokens.overviewTitleSize, weight: .semibold))
                        .tracking(-0.2)
                    Text("Browse saved captures and compare changes across snapshots.")
                        .font(.system(size: FSDDesignTokens.overviewSubtitleSize))
                        .foregroundStyle(FSDDesignTokens.secondaryText)
                }

                captureCard

                metricsSection

                FSDWeightedColumnsLayout(
                    leftWeight: FSDDesignTokens.homeGridLeftWeight,
                    rightWeight: FSDDesignTokens.homeGridRightWeight,
                    minimumRightWidth: FSDDesignTokens.homeGridMinimumRightWidth,
                    spacing: FSDDesignTokens.homeGridGap
                ) {
                    recentComparisonsPanel
                    VStack(alignment: .leading, spacing: FSDDesignTokens.recentDrivesSpacing) {
                        recentCapturesPanel
                        recentDrivesPanel
                    }
                }
            }
            .padding(.horizontal, FSDDesignTokens.pageInsetHorizontal)
            .padding(.top, FSDDesignTokens.pageInsetTop)
            .padding(.bottom, FSDDesignTokens.pageInsetBottom)
            .frame(maxWidth: FSDDesignTokens.pageMaxContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .scrollIndicators(.hidden)
        .background(FSDDesignTokens.window)
        .onAppear(perform: loadRecentComparisons)
    }

    private var captureCard: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius)
                    .fill(FSDDesignTokens.primaryAction.opacity(0.30))
                    .frame(width: 48, height: 48)
                Image(systemName: "externaldrive.badge.plus")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(FSDDesignTokens.accent)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text("Choose a source to capture")
                        .font(.system(size: FSDDesignTokens.bodySize, weight: .semibold))
                    Text("MANUAL")
                        .font(.system(size: FSDDesignTokens.labelSize, weight: .bold))
                        .tracking(0.7)
                        .foregroundStyle(FSDDesignTokens.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                    .background(FSDDesignTokens.primaryAction.opacity(0.30), in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
                }
                Text("Select a folder when you are ready. FSD records filesystem metadata only.")
                    .font(.system(size: 12))
                    .foregroundStyle(FSDDesignTokens.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Metadata only  ·  Content Not Verified")
                    .font(.system(size: FSDDesignTokens.labelSize, weight: .medium))
                    .foregroundStyle(FSDDesignTokens.mutedText)
            }
            Spacer(minLength: 8)
            Button(action: onCapture) {
                Label("Capture", systemImage: "arrow.right")
                    .font(.system(size: FSDDesignTokens.toolbarLabelSize, weight: .semibold))
                    .foregroundStyle(FSDDesignTokens.primaryText)
                    .padding(.horizontal, 14)
                    .frame(height: 34)
                    .background(FSDDesignTokens.primaryAction, in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open manual capture")
            .accessibilityHint("Opens the existing folder selection and metadata capture workflow.")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(minHeight: 84)
        .background(FSDDesignTokens.captureSurface, in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius).stroke(FSDDesignTokens.captureBorder, lineWidth: 1))
        .accessibilityElement(children: .contain)
    }

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Library Overview")
                .font(.system(size: FSDDesignTokens.sectionTitleSize, weight: .semibold))
                .foregroundStyle(FSDDesignTokens.primaryText)

            VStack(spacing: 0) {
                overviewSeparator
                HStack(spacing: 0) {
                    OverviewMetricCell(title: "Drives", value: "—", note: "Registry unavailable")
                    metricDivider
                    OverviewMetricCell(title: "Snapshots", value: "\(model.history.count)", note: "Saved captures")
                    metricDivider
                    OverviewMetricCell(title: "Items", value: "—", note: "Aggregate unavailable")
                    metricDivider
                    OverviewMetricCell(title: "Storage", value: "—", note: "Aggregate unavailable")
                }
                .frame(minHeight: 76)
                overviewSeparator
            }
        }
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(FSDDesignTokens.separator)
            .frame(width: 1, height: 48)
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
                                    .background(FSDDesignTokens.selected, in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(record.mode.label)
                                        .font(.system(size: FSDDesignTokens.bodySize, weight: .medium))
                                        .lineLimit(1)
                                    Text("\(record.totalDifferences) differences  ·  \(record.startedAt)")
                                        .font(.system(size: FSDDesignTokens.labelSize))
                                        .foregroundStyle(FSDDesignTokens.secondaryText)
                                        .lineLimit(1)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(FSDDesignTokens.mutedText)
                            }
                            .frame(minHeight: 52)
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
                                    .background(FSDDesignTokens.selected, in: RoundedRectangle(cornerRadius: FSDDesignTokens.cornerRadius))
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(summary.displayName)
                                        .font(.system(size: FSDDesignTokens.bodySize, weight: .medium))
                                        .lineLimit(1)
                                    Text("\(snapshotStatus(summary.status))  ·  \(summary.startedAt)")
                                        .font(.system(size: FSDDesignTokens.labelSize))
                                        .foregroundStyle(FSDDesignTokens.secondaryText)
                                        .lineLimit(1)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(FSDDesignTokens.mutedText)
                            }
                            .frame(minHeight: 52)
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

private struct FSDWeightedColumnsLayout: Layout {
    let leftWeight: CGFloat
    let rightWeight: CGFloat
    let minimumRightWidth: CGFloat
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard subviews.count >= 2 else { return .zero }
        let proposedWidth = proposal.width ?? (minimumRightWidth + spacing)
        let (leftWidth, rightWidth) = columnWidths(for: proposedWidth)
        let leftSize = subviews[0].sizeThatFits(ProposedViewSize(width: leftWidth, height: proposal.height))
        let rightSize = subviews[1].sizeThatFits(ProposedViewSize(width: rightWidth, height: proposal.height))
        return CGSize(width: proposedWidth, height: max(leftSize.height, rightSize.height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count >= 2 else { return }
        let (leftWidth, rightWidth) = columnWidths(for: bounds.width)
        subviews[0].place(
            at: CGPoint(x: bounds.minX, y: bounds.minY),
            anchor: .topLeading,
            proposal: ProposedViewSize(width: leftWidth, height: nil)
        )
        subviews[1].place(
            at: CGPoint(x: bounds.minX + leftWidth + spacing, y: bounds.minY),
            anchor: .topLeading,
            proposal: ProposedViewSize(width: rightWidth, height: nil)
        )
    }

    private func columnWidths(for totalWidth: CGFloat) -> (left: CGFloat, right: CGFloat) {
        let availableWidth = max(0, totalWidth - spacing)
        guard availableWidth > 0 else { return (0, 0) }
        let weightTotal = leftWeight + rightWeight
        let weightedRight = availableWidth * rightWeight / weightTotal
        let rightWidth = min(availableWidth, max(minimumRightWidth, weightedRight))
        return (availableWidth - rightWidth, rightWidth)
    }
}

private struct OverviewMetricCell: View {
    let title: String
    let value: String
    let note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: FSDDesignTokens.metricLabelSize, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(FSDDesignTokens.mutedText)
            Text(value)
                .font(.system(size: FSDDesignTokens.metricValueSize, weight: .semibold, design: .rounded))
                .foregroundStyle(value == "—" ? FSDDesignTokens.mutedText : FSDDesignTokens.primaryText)
            Text(note)
                .font(.system(size: 9))
                .foregroundStyle(FSDDesignTokens.secondaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
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
                    .font(.system(size: FSDDesignTokens.sectionTitleSize, weight: .semibold))
                    .foregroundStyle(FSDDesignTokens.primaryText)
                Spacer()
                if let trailingTitle, let action {
                    Button(trailingTitle, action: action)
                        .font(.system(size: FSDDesignTokens.labelSize, weight: .medium))
                        .foregroundStyle(FSDDesignTokens.accent)
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(trailingTitle) \(title)")
                }
            }
            .padding(.bottom, 8)
            Rectangle()
                .fill(FSDDesignTokens.separator)
                .frame(height: 1)
            content
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .topLeading)
            Rectangle()
                .fill(FSDDesignTokens.separator)
                .frame(height: 1)
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
