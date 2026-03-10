import SwiftUI
import AppKit
import Foundation
import Darwin

// MARK: - App Theme Enum
enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark
}

// MARK: - App Entry Point
@main
struct SysMeterApp: App {
    @StateObject private var monitor = SystemMonitor()

    // User Preferences
    @AppStorage("showCPU") private var showCPU = true
    @AppStorage("showRAM") private var showRAM = true
    @AppStorage("showDisk") private var showDisk = true
    @AppStorage("appTheme") private var appTheme: AppTheme = .system

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            ContentView(
                monitor: monitor,
                showCPU: $showCPU,
                showRAM: $showRAM,
                showDisk: $showDisk,
                appTheme: $appTheme
            )
            .environment(\.colorScheme, colorSchemeForTheme)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.window)
    }

    private var menuBarLabel: Text {
        let cpuText = "⚙️ \(Int(monitor.cpuUsage))%"
        let ramText = "💾 \(Int(monitor.ramPercentage))%"

        if showCPU && showRAM {
            return Text("\(cpuText)   \(ramText)")
        } else if showCPU {
            return Text(cpuText)
        } else if showRAM {
            return Text(ramText)
        } else {
            return Text("⚠️ Hidden")
        }
    }

    private var colorSchemeForTheme: ColorScheme {
        switch appTheme {
        case .system:
            return NSApp.effectiveAppearance.isDarkMode ? .dark : .light
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

// MARK: - NSAppearance Extension
extension NSAppearance {
    var isDarkMode: Bool {
        if #available(macOS 10.14, *) {
            return self.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        } else {
            return false
        }
    }
}

// MARK: - User Interface
struct ContentView: View {
    @ObservedObject var monitor: SystemMonitor
    @Binding var showCPU: Bool
    @Binding var showRAM: Bool
    @Binding var showDisk: Bool
    @Binding var appTheme: AppTheme

    @State private var showingSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showingSettings {
                SettingsView(
                    monitor: monitor,
                    showingSettings: $showingSettings,
                    showCPU: $showCPU,
                    showRAM: $showRAM,
                    showDisk: $showDisk,
                    appTheme: $appTheme
                )
            } else {
                MonitorView(
                    monitor: monitor,
                    showingSettings: $showingSettings,
                    showDisk: showDisk
                )
            }
        }
        .frame(width: 320)
    }
}

// MARK: - Monitor View
struct MonitorView: View {
    @ObservedObject var monitor: SystemMonitor
    @Binding var showingSettings: Bool
    var showDisk: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("System Resources")
                    .font(.headline)
                Spacer()
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .onHover { isHovered in
                    if isHovered {
                        NSCursor.pointingHand.push()
                    } else {
                        NSCursor.pop()
                    }
                }
            }
            .padding(.bottom, 4)

            let cpuColor: Color = monitor.cpuUsage >= 80 ? .red : (monitor.cpuUsage >= 60 ? .orange : .primary)
            let ramColor: Color = monitor.ramPercentage >= 80 ? .red : (monitor.ramPercentage >= 60 ? .orange : .primary)

            ResourceRow(icon: "cpu", title: "CPU Load", value: String(format: "%.1f%%", monitor.cpuUsage), valueColor: cpuColor)

            if showDisk {
                ResourceRow(icon: "internaldrive", title: "Disk Space", value: monitor.diskSpace, valueColor: .primary)
            }

            ResourceRow(icon: "memorychip", title: "Memory", value: monitor.ramPercentageString, valueColor: ramColor)

            HStack(alignment: .top, spacing: 15) {
                VStack(alignment: .leading, spacing: 4) {
                    MemoryDetailRow(title: "Physical Memory:", value: monitor.physicalMemory)
                    Divider()
                    MemoryDetailRow(title: "Memory Used:", value: monitor.memoryUsed)
                    Divider()
                    MemoryDetailRow(title: "Cached Files:", value: monitor.cachedFiles)
                    Divider()
                    MemoryDetailRow(title: "Swap Used:", value: monitor.swapUsed)
                }
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    MemoryDetailRow(title: "App Memory:", value: monitor.appMemory)
                    MemoryDetailRow(title: "Wired Memory:", value: monitor.wiredMemory)
                    MemoryDetailRow(title: "Compressed:", value: monitor.compressedMemory)
                }
            }
            .padding(10)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.4))
            .cornerRadius(6)
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.3), lineWidth: 1))
            .padding(.horizontal, 4)

            Divider()

            HStack {
                Text(monitor.uptime)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Text("Quit SysMeter")
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                }
                .keyboardShortcut("q", modifiers: .command)
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
        }
        .padding()
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var monitor: SystemMonitor
    @Binding var showingSettings: Bool
    @Binding var showCPU: Bool
    @Binding var showRAM: Bool
    @Binding var showDisk: Bool
    @Binding var appTheme: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button(action: { showingSettings = false }) {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.plain)

                Text("Customisation")
                    .font(.headline)
                Spacer()
            }

            Form {
                Section(header: Text("Menu Bar Display").font(.subheadline).foregroundColor(.secondary)) {
                    Toggle("Show CPU Load", isOn: $showCPU)
                    Toggle("Show RAM Usage", isOn: $showRAM)
                }

                Divider().padding(.vertical, 4)

                Section(header: Text("Dropdown Display").font(.subheadline).foregroundColor(.secondary)) {
                    Toggle("Show Disk Space", isOn: $showDisk)
                }

                Divider().padding(.vertical, 4)

                Section(header: Text("Refresh Rate").font(.subheadline).foregroundColor(.secondary)) {
                    Picker("Update Interval", selection: $monitor.refreshRate) {
                        Text("1 Second").tag(1.0)
                        Text("2 Seconds").tag(2.0)
                        Text("5 Seconds").tag(5.0)
                    }
                    .pickerStyle(.radioGroup)
                    .onChange(of: monitor.refreshRate) {
                        monitor.restartTimer()
                    }
                }

                Divider().padding(.vertical, 4)

                Section(header: Text("Appearance").font(.subheadline).foregroundColor(.secondary)) {
                    Picker("Theme", selection: $appTheme) {
                        Text("System").tag(AppTheme.system)
                        Text("Light").tag(AppTheme.light)
                        Text("Dark").tag(AppTheme.dark)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .padding()
    }
}

// MARK: - Reusable UI Components
struct ResourceRow: View {
    let icon: String
    let title: String
    let value: String
    let valueColor: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 20, alignment: .center)
                .foregroundColor(.blue)
            Text(title)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(valueColor)
                .fontWeight(valueColor == .primary ? .regular : .bold)
        }
        .padding(.vertical, 4)
    }
}

struct MemoryDetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .medium))
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .regular))
        }
    }
}

// MARK: - View Model (Logic & Data Fetching)
class SystemMonitor: ObservableObject {
    @AppStorage("refreshRate") var refreshRate: Double = 2.0

    @Published var cpuUsage: Double = 0.0
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
        restartTimer()
    }

    func restartTimer() {
        timer?.invalidate()
        updateStats()
        timer = Timer.scheduledTimer(withTimeInterval: refreshRate, repeats: true) { [weak self] _ in
            self?.updateStats()
        }
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
