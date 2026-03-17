import SwiftUI
import AppKit
import Foundation
import Darwin

// App Identity
let appName    = "sysMeter"
let appVersion = "1.0.0"
let appTagline = "Real-time system monitoring for your Mac"
let githubRepo = "BogdanAlinTudorache/sysMeter"

// MARK: - Color Helper
extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var n: UInt64 = 0; Scanner(string: s).scanHexInt64(&n)
        self.init(
            red:   Double((n >> 16) & 0xFF) / 255,
            green: Double((n >> 8)  & 0xFF) / 255,
            blue:  Double( n        & 0xFF) / 255
        )
    }
}

// MARK: - App Theme Enum
enum AppTheme: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
}

// MARK: - Color Preset Enum
enum ColorPreset: String, CaseIterable {
    case `default` = "Default"
    case tokyoNight = "Tokyo Night"
}

// MARK: - View Mode Enum
enum ViewMode: String, CaseIterable {
    case monitor = "Monitor"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .monitor:  return "speedometer"
        case .settings: return "gearshape"
        }
    }
}

// MARK: - Cursor Extension
extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { inside in
            if inside { cursor.push() } else { NSCursor.pop() }
        }
    }
}

// MARK: - App Entry Point
@main
struct SysMeterApp: App {
    @StateObject private var monitor = SystemMonitor()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView(monitor: monitor)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
    }

    private var menuBarLabel: some View {
        let cpuText = "⚙️ \(Int(monitor.cpuUsage))%"
        let ramText = "💾 \(Int(monitor.ramPercentage))%"

        if monitor.showCPU && monitor.showRAM {
            return AnyView(Text("\(cpuText)   \(ramText)"))
        } else if monitor.showCPU {
            return AnyView(Text(cpuText))
        } else if monitor.showRAM {
            return AnyView(Text(ramText))
        } else {
            return AnyView(Text("⚠️ Hidden"))
        }
    }
}

// MARK: - User Interface
struct ContentView: View {
    @ObservedObject var monitor: SystemMonitor
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Group {
            switch monitor.currentView {
            case .monitor:  MonitorView(monitor: monitor)
            case .settings: SettingsView(monitor: monitor)
            }
        }
        .background(themedBackground)
        .frame(width: 380, height: 580)
        .onAppear  { applyTheme() }
        .onChange(of: monitor.appTheme)  { _ in applyTheme() }
        .onChange(of: monitor.colorPreset) { _ in applyTheme() }
    }

    private var themedBackground: Color {
        guard monitor.colorPreset == ColorPreset.tokyoNight.rawValue else { return .clear }
        return colorScheme == .dark ? Color(hex: "24283b") : Color(hex: "e6e7ed")
    }

    private func applyTheme() {
        let t = AppTheme(rawValue: monitor.appTheme) ?? .system
        NSApp.appearance = t == .light ? NSAppearance(named: .aqua)
                         : t == .dark  ? NSAppearance(named: .darkAqua)
                         : nil
    }
}

// MARK: - Monitor View
struct MonitorView: View {
    @ObservedObject var monitor: SystemMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            tabBar

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    let cpuColor: Color = monitor.cpuUsage >= 80 ? .red : (monitor.cpuUsage >= 60 ? .orange : .primary)
                    let ramColor: Color = monitor.ramPercentage >= 80 ? .red : (monitor.ramPercentage >= 60 ? .orange : .primary)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("System Resources")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .opacity(0.7)

                        VStack(spacing: 10) {
                            ResourceRow(icon: "cpu", title: "CPU Load", value: String(format: "%.1f%%", monitor.cpuUsage), valueColor: cpuColor)

                            if monitor.showDisk {
                                ResourceRow(icon: "internaldrive", title: "Disk Space", value: monitor.diskSpace, valueColor: .primary)
                            }

                            ResourceRow(icon: "memorychip", title: "Memory", value: monitor.ramPercentageString, valueColor: ramColor)
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Memory Details")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .opacity(0.7)

                        HStack(alignment: .top, spacing: 20) {
                            VStack(alignment: .leading, spacing: 12) {
                                MemoryDetailRow(title: "Physical", value: monitor.physicalMemory)
                                MemoryDetailRow(title: "Used", value: monitor.memoryUsed)
                                MemoryDetailRow(title: "Cached", value: monitor.cachedFiles)
                                MemoryDetailRow(title: "Swap", value: monitor.swapUsed)
                            }
                            Spacer(minLength: 0)
                            VStack(alignment: .leading, spacing: 12) {
                                MemoryDetailRow(title: "App", value: monitor.appMemory)
                                MemoryDetailRow(title: "Wired", value: monitor.wiredMemory)
                                MemoryDetailRow(title: "Compressed", value: monitor.compressedMemory)
                            }
                        }
                        .padding(14)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Uptime")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.secondary)
                            Text(monitor.uptime)
                                .font(.system(size: 12, weight: .medium))
                        }
                        Spacer()
                        Button("Quit") { NSApplication.shared.terminate(nil) }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                }
                .padding(16)
            }
        }
    }

    private var tabBar: some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "speedometer")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.blue)
                Text(appName)
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 8) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            monitor.currentView = mode
                        }
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 15, weight: .semibold))
                            Text(mode.rawValue)
                                .font(.system(size: 9, weight: .bold))
                        }
                        .frame(minWidth: 48, minHeight: 44)
                        .foregroundStyle(monitor.currentView == mode ? .primary : .secondary)
                        .background(
                            monitor.currentView == mode
                                ? Color.accentColor.opacity(0.25)
                                : Color.white.opacity(0.05)
                        )
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .padding(14)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var monitor: SystemMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            tabBar

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    settingSection("Display") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Show CPU Load", isOn: $monitor.showCPU).toggleStyle(.switch).font(.callout)
                            Toggle("Show RAM Usage", isOn: $monitor.showRAM).toggleStyle(.switch).font(.callout)
                            Toggle("Show Disk Space", isOn: $monitor.showDisk).toggleStyle(.switch).font(.callout)
                            Divider()
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Refresh Rate").font(.callout).fontWeight(.medium)
                                Picker("", selection: $monitor.refreshRate) {
                                    Text("1s").tag(1.0)
                                    Text("2s").tag(2.0)
                                    Text("5s").tag(5.0)
                                }
                                .pickerStyle(.segmented).labelsHidden()
                                .onChange(of: monitor.refreshRate) {
                                    monitor.restartTimer()
                                }
                            }
                        }
                    }

                    settingSection("Appearance") {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Theme").font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                                Picker("", selection: $monitor.appTheme) {
                                    ForEach(AppTheme.allCases, id: \.rawValue) {
                                        Text($0.rawValue).tag($0.rawValue)
                                    }
                                }
                                .pickerStyle(.segmented).labelsHidden()
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Color").font(.system(size: 12, weight: .medium)).foregroundStyle(.secondary)
                                Picker("", selection: $monitor.colorPreset) {
                                    ForEach(ColorPreset.allCases, id: \.rawValue) {
                                        Text($0.rawValue).tag($0.rawValue)
                                    }
                                }
                                .pickerStyle(.segmented).labelsHidden()
                            }
                        }
                    }

                    settingSection("Updates") {
                        VStack(alignment: .leading, spacing: 8) {
                            Button(monitor.isCheckingUpdate ? "Checking…" : "Check for Updates") {
                                monitor.checkForUpdates()
                            }
                            .disabled(monitor.isCheckingUpdate)
                            if !monitor.updateStatus.isEmpty {
                                Text(monitor.updateStatus)
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }

                    settingSection("About") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .firstTextBaseline) {
                                Text("\(appName) v\(appVersion)").font(.callout).fontWeight(.medium)
                                Spacer()
                                Link("Changelog ↗",
                                     destination: URL(string: "https://github.com/\(githubRepo)/commits/main/")!)
                                    .font(.caption2)
                            }
                            Text(appTagline)
                                .font(.caption2).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("Real-time · Local · Private")
                                .font(.caption2).foregroundStyle(.tertiary)
                        }
                    }

                    Divider()
                    HStack {
                        Spacer()
                        Button("Quit \(appName)") { NSApplication.shared.terminate(nil) }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
                .padding(14)
            }
        }
    }

    private var tabBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "speedometer")
                    .font(.title3).foregroundStyle(.blue)
                Text(appName)
                    .font(.headline).fontWeight(.semibold)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            ForEach(ViewMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        monitor.currentView = mode
                    }
                } label: {
                    VStack(spacing: 2) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 14, weight: .semibold))
                        Text(mode.rawValue)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .frame(minWidth: 50)
                    .foregroundStyle(monitor.currentView == mode ? .primary : .secondary)
                    .padding(.vertical, 8)
                    .background(
                        monitor.currentView == mode
                            ? Color.accentColor.opacity(0.2)
                            : Color.clear
                    )
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding(12)
    }

    @ViewBuilder
    private func settingSection<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .opacity(0.7)
                .tracking(0.5)

            content()
                .padding(14)
                .background(
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                )
        }
    }
}

// MARK: - Reusable UI Components
struct ResourceRow: View {
    let icon: String
    let title: String
    let value: String
    let valueColor: Color

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .frame(width: 24, alignment: .center)
                .foregroundColor(.blue)
                .font(.system(size: 15, weight: .semibold))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
    }
}

struct MemoryDetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - View Model (Logic & Data Fetching)
class SystemMonitor: ObservableObject {
    @AppStorage("appTheme")    var appTheme:    String = "system"
    @AppStorage("colorPreset") var colorPreset: String = "default"
    @AppStorage("refreshRate") var refreshRate: Double = 2.0
    @AppStorage("showCPU") var showCPU: Bool = true
    @AppStorage("showRAM") var showRAM: Bool = true
    @AppStorage("showDisk") var showDisk: Bool = true

    @Published var currentView: ViewMode = .monitor
    @Published var cpuUsage: Double = 0.0
    @Published var updateStatus: String = ""
    @Published var isCheckingUpdate: Bool = false

    private var previousCpuInfo: processor_info_array_t?
    private var previousCpuInfoCount: mach_msg_type_number_t = 0

    @Published var ramPercentageString: String = "..."
    @Published var ramPercentage: Double = 0.0
    @Published var physicalMemory: String = "..."
    @Published var memoryUsed: String = "..."
    @Published var cachedFiles: String = "..."
    @Published var appMemory: String = "..."
    @Published var wiredMemory: String = "..."
    @Published var compressedMemory: String = "..."
    @Published var swapUsed: String = "..."
    @Published var diskSpace: String = "Calculating..."
    @Published var uptime: String = "Uptime: ..."

    private var timer: Timer?

    init() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.restartTimer()
        }
    }

    func restartTimer() {
        timer?.invalidate()
        updateStats()
        timer = Timer.scheduledTimer(withTimeInterval: refreshRate, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
    }

    func checkForUpdates() {
        isCheckingUpdate = true
        updateStatus = ""
        let url = URL(string: "https://api.github.com/repos/\(githubRepo)/releases/latest")!
        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                self.isCheckingUpdate = false
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let tag  = json["tag_name"] as? String else {
                    self.updateStatus = "Could not check for updates"
                    return
                }
                let latest = tag.trimmingCharacters(in: .init(charactersIn: "v"))
                self.updateStatus = latest == appVersion
                    ? "✓ v\(appVersion) — up to date"
                    : "↑ v\(latest) available"
            }
        }.resume()
    }

    private func updateStats() {
        fetchRealCPU()
        fetchRealRAMAndSwap()
        fetchDiskSpace()
        fetchUptime()
    }

    private func fetchDiskSpace() {
        do {
            let fileURL = URL(fileURLWithPath: NSHomeDirectory())
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            if let available = values.volumeAvailableCapacity {
                let availableGB = Double(available) / 1_073_741_824.0
                DispatchQueue.main.async { self.diskSpace = String(format: "%.1f GB Free", availableGB) }
            }
        } catch {
            DispatchQueue.main.async { self.diskSpace = "Error" }
        }
    }

    private func fetchUptime() {
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.standardError = Pipe()
        task.arguments = ["-c", "uptime | awk '{print $3,$4,$5}' | sed 's/,//g'"]
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.standardInput = nil

        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                DispatchQueue.main.async {
                    self.uptime = "Uptime: \(output)"
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.uptime = "Uptime: Error"
            }
        }
    }

    private func fetchRealCPU() {
        var cpuInfo: processor_info_array_t?
        var numCPUs: natural_t = 0
        var cpuInfoCount: mach_msg_type_number_t = 0
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUs, &cpuInfo, &cpuInfoCount)

        if result == KERN_SUCCESS, let cpuInfo = cpuInfo {
            if let prevCpuInfo = previousCpuInfo {
                var totalTicks: Int32 = 0
                var idleTicks: Int32 = 0
                for i in 0..<Int(numCPUs) {
                    let index = Int32(i) * CPU_STATE_MAX
                    let inUse = cpuInfo[Int(index + CPU_STATE_USER)] + cpuInfo[Int(index + CPU_STATE_SYSTEM)] + cpuInfo[Int(index + CPU_STATE_NICE)]
                    let idle = cpuInfo[Int(index + CPU_STATE_IDLE)]
                    let prevInUse = prevCpuInfo[Int(index + CPU_STATE_USER)] + prevCpuInfo[Int(index + CPU_STATE_SYSTEM)] + prevCpuInfo[Int(index + CPU_STATE_NICE)]
                    let prevIdle = prevCpuInfo[Int(index + CPU_STATE_IDLE)]
                    totalTicks += (inUse - prevInUse) + (idle - prevIdle)
                    idleTicks += (idle - prevIdle)
                }
                let usage = totalTicks > 0 ? Double(totalTicks - idleTicks) / Double(totalTicks) * 100.0 : 0.0
                DispatchQueue.main.async { self.cpuUsage = usage }
                let prevSize = vm_size_t(previousCpuInfoCount) * vm_size_t(MemoryLayout<integer_t>.size)
                vm_deallocate(mach_task_self_, vm_address_t(bitPattern: prevCpuInfo), prevSize)
            }
            previousCpuInfo = cpuInfo
            previousCpuInfoCount = cpuInfoCount
        }
    }

    private func fetchRealRAMAndSwap() {
        let totalBytes = ProcessInfo.processInfo.physicalMemory
        let totalGB = Double(totalBytes) / 1_073_741_824.0
        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)
        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        if result == KERN_SUCCESS {
            let wiredGB = (Double(vmStats.wire_count) * Double(pageSize)) / 1_073_741_824.0
            let compressedGB = (Double(vmStats.compressor_page_count) * Double(pageSize)) / 1_073_741_824.0
            let appMemGB = (Double(vmStats.internal_page_count - vmStats.purgeable_count) * Double(pageSize)) / 1_073_741_824.0
            let usedGB = appMemGB + wiredGB + compressedGB
            let cachedGB = (Double(vmStats.external_page_count + vmStats.purgeable_count) * Double(pageSize)) / 1_073_741_824.0
            let percentage = (usedGB / totalGB) * 100
            DispatchQueue.main.async {
                self.ramPercentage = percentage
                self.ramPercentageString = String(format: "%.1f%%", percentage)
                self.physicalMemory = String(format: "%.2f GB", totalGB)
                self.memoryUsed = String(format: "%.2f GB", usedGB)
                self.cachedFiles = String(format: "%.2f GB", cachedGB)
                self.appMemory = String(format: "%.2f GB", appMemGB)
                self.wiredMemory = String(format: "%.2f GB", wiredGB)
                self.compressedMemory = String(format: "%.2f GB", compressedGB)
            }
        }

        var mib = [CTL_VM, VM_SWAPUSAGE]
        var swapUsage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        if sysctl(&mib, 2, &swapUsage, &size, nil, 0) == 0 {
            let swapGB = Double(swapUsage.xsu_used) / 1_073_741_824.0
            DispatchQueue.main.async { self.swapUsed = String(format: "%.2f GB", swapGB) }
        }
    }

    deinit {
        timer?.invalidate()
    }
}
