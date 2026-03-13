// MARK: - PTY Multiplexer (Step 2.1)
// kqueue-based I/O multiplexer for N PTY sessions on a single thread.

import Foundation
import Darwin.POSIX

/// Calls the kevent() system call, disambiguated from the kevent struct.
private func keventSyscall(
    _ kq: Int32,
    _ changelist: UnsafePointer<kevent>?,
    _ nchanges: Int32,
    _ eventlist: UnsafeMutablePointer<kevent>?,
    _ nevents: Int32,
    _ timeout: UnsafePointer<timespec>?
) -> Int32 {
    return syscall_kevent(kq, changelist, nchanges, eventlist, nevents, timeout)
}

// C-level trampoline for kevent — avoids Swift name collision
@_silgen_name("kevent")
private func syscall_kevent(
    _ kq: Int32,
    _ changelist: UnsafePointer<kevent>?,
    _ nchanges: Int32,
    _ eventlist: UnsafeMutablePointer<kevent>?,
    _ nevents: Int32,
    _ timeout: UnsafePointer<timespec>?
) -> Int32

final class PTYMultiplexer {

    // MARK: - Properties

    private let kqueueFD: Int32
    private let ioQueue = DispatchQueue(label: "com.agentsboard.pty-io", qos: .userInteractive)
    private var sessions: [Int32: MultiplexedSession] = [:]
    private var isRunning = false

    // MARK: - Types

    private struct MultiplexedSession {
        let process: PTYProcess
        weak var delegate: TerminalDataReceiving?
        let sessionProxy: any TerminalSessionManaging
    }

    // MARK: - Init

    init() throws {
        kqueueFD = Darwin.kqueue()
        guard kqueueFD >= 0 else {
            throw MultiplexerError.kqueueFailed(errno)
        }
    }

    deinit {
        stop()
        Darwin.close(kqueueFD)
    }

    // MARK: - Registration

    func register(
        process: PTYProcess,
        session: any TerminalSessionManaging,
        delegate: TerminalDataReceiving
    ) {
        let fd = process.fileDescriptor
        sessions[fd] = MultiplexedSession(
            process: process,
            delegate: delegate,
            sessionProxy: session
        )

        // Register for read events on this fd
        var event = Darwin.kevent(
            ident: UInt(fd),
            filter: Int16(EVFILT_READ),
            flags: UInt16(EV_ADD | EV_ENABLE),
            fflags: 0,
            data: 0,
            udata: nil
        )
        keventSyscall(kqueueFD, &event, 1, nil, 0, nil)
    }

    func unregister(fileDescriptor fd: Int32) {
        var event = Darwin.kevent(
            ident: UInt(fd),
            filter: Int16(EVFILT_READ),
            flags: UInt16(EV_DELETE),
            fflags: 0,
            data: 0,
            udata: nil
        )
        keventSyscall(kqueueFD, &event, 1, nil, 0, nil)
        sessions.removeValue(forKey: fd)
    }

    // MARK: - Event Loop

    func start() {
        guard !isRunning else { return }
        isRunning = true

        ioQueue.async { [weak self] in
            self?.eventLoop()
        }
    }

    func stop() {
        isRunning = false
    }

    private func eventLoop() {
        var events = [Darwin.kevent](repeating: Darwin.kevent(), count: 64)
        let readBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 65536)
        defer { readBuffer.deallocate() }

        while isRunning {
            var timeout = timespec(tv_sec: 0, tv_nsec: 10_000_000) // 10ms
            let eventCount = keventSyscall(kqueueFD, nil, 0, &events, Int32(events.count), &timeout)

            guard eventCount >= 0 else {
                if errno == EINTR { continue }
                break
            }

            for i in 0..<Int(eventCount) {
                let event = events[i]
                let fd = Int32(event.ident)

                if event.flags & UInt16(EV_EOF) != 0 {
                    // Process exited
                    handleProcessExit(fd: fd)
                    continue
                }

                if event.filter == Int16(EVFILT_READ) && event.data > 0 {
                    let bytesRead = read(fd, readBuffer, min(Int(event.data), 65536))
                    if bytesRead > 0 {
                        let data = Data(bytes: readBuffer, count: bytesRead)
                        handleData(data, forFD: fd)
                    }
                }
            }
        }
    }

    private func handleData(_ data: Data, forFD fd: Int32) {
        guard let session = sessions[fd] else { return }
        DispatchQueue.main.async {
            session.delegate?.terminalSession(session.sessionProxy, didReceiveData: data)
        }
    }

    private func handleProcessExit(fd: Int32) {
        guard let session = sessions[fd] else { return }
        let exitCode = session.process.waitForExit()
        unregister(fileDescriptor: fd)
        DispatchQueue.main.async {
            session.delegate?.terminalSession(session.sessionProxy, didExitWithCode: exitCode)
        }
    }
}

// MARK: - Errors

enum MultiplexerError: Error {
    case kqueueFailed(Int32)
}
