// Based on https://gist.github.com/acadet/4ad0557e07a855c84981

import Darwin

struct Timer {
    static var b: mach_timebase_info = mach_timebase_info(numer: 0, denom: 0)
    var startTime: UInt64 = 0
    var stopTime: UInt64 = 0

    init() {
        mach_timebase_info(&Timer.b)
    }

    mutating func start() {
        startTime = mach_absolute_time()
    }

    mutating func stop() {
        stopTime = mach_absolute_time()
    }

    var nanoseconds: UInt64 {
        let elapsed = stopTime - startTime
        return elapsed * UInt64(Timer.b.numer) / UInt64(Timer.b.denom)
    }

    var milliseconds: Double {
        return Double(nanoseconds) / 1_000_000
    }
}
