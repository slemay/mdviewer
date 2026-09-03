import Foundation

public final class FileWatcher: @unchecked Sendable {
    private let url: URL
    private let queue = DispatchQueue(label: "com.mdviewer.filewatcher", qos: .utility)
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: CInt = -1
    private var debounceWorkItem: DispatchWorkItem?
    private let debounceInterval: TimeInterval = 0.08
    private var isCancelled = false

    public var onChange: (@Sendable () -> Void)?

    public init(url: URL) {
        self.url = url
    }

    deinit {
        stop()
    }

    public func start() {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.isCancelled = false
            self.setupSource()
        }
    }

    public func stop() {
        queue.sync {
            isCancelled = true
            debounceWorkItem?.cancel()
            debounceWorkItem = nil
            teardownSource()
        }
    }

    private func setupSource() {
        guard !isCancelled else { return }

        teardownSource()

        let path = url.path
        fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor >= 0 else {
            // If file is temporarily missing (e.g. during atomic replace), retry in 100ms
            retrySetupLater()
            return
        }

        let eventMask: DispatchSource.FileSystemEvent = [.write, .extend, .attrib, .rename, .delete]
        let newSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: eventMask,
            queue: queue
        )

        newSource.setEventHandler { [weak self] in
            guard let self = self, !self.isCancelled else { return }
            let data = newSource.data

            if data.contains(.delete) || data.contains(.rename) {
                // Atomic file swap detected - wait briefly for write to finish and re-arm
                self.scheduleDebouncedCallback()
                self.retrySetupLater()
            } else if data.contains(.write) || data.contains(.extend) || data.contains(.attrib) {
                self.scheduleDebouncedCallback()
            }
        }

        newSource.setCancelHandler { [weak self] in
            guard let self = self else { return }
            if self.fileDescriptor >= 0 {
                close(self.fileDescriptor)
                self.fileDescriptor = -1
            }
        }

        source = newSource
        newSource.resume()
    }

    private func teardownSource() {
        if let existing = source {
            existing.cancel()
            source = nil
        } else if fileDescriptor >= 0 {
            close(fileDescriptor)
            fileDescriptor = -1
        }
    }

    private func retrySetupLater() {
        guard !isCancelled else { return }
        queue.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            guard let self = self, !self.isCancelled else { return }
            self.setupSource()
        }
    }

    private func scheduleDebouncedCallback() {
        debounceWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, !self.isCancelled else { return }
            self.onChange?()
        }
        debounceWorkItem = workItem
        queue.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
    }
}
