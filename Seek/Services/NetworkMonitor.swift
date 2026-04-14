import Foundation
import Network

/// Observes network reachability via NWPathMonitor. Inject as an environment
/// object at the app root so any view can check `isConnected` and react to
/// connectivity changes.
@Observable
final class NetworkMonitor {
    /// True when the device has an active network path (wifi, cellular, or
    /// wired). Starts optimistic so the first UI paint doesn't flash an
    /// offline state while NWPathMonitor warms up.
    var isConnected: Bool = true

    /// Whether the active path is considered expensive (cellular or personal
    /// hotspot). Not currently surfaced in UI but handy for future policies
    /// like "don't auto-refresh over cellular".
    var isExpensive: Bool = false

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.loucesario.seek.networkmonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            let expensive = path.isExpensive
            Task { @MainActor in
                self?.isConnected = connected
                self?.isExpensive = expensive
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
