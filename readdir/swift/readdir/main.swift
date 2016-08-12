// Based on https://gist.github.com/kristopherjohnson/4bafee0b489add42a61f
import Foundation

func run() -> Double {
    var timer = Timer()

    timer.start()

    let dir = opendir("../../bigdir")
    if dir == nil {
        print("couldn't open directory")
        exit(1)
    }

    var entry = readdir(dir)
    while entry != nil {
        let d_namlen = entry.memory.d_namlen
        let d_name = entry.memory.d_name

        var nameBuf: [CChar] = Array()
        let tuple = Mirror(reflecting: d_name)
        var idx = tuple.children.startIndex
        for _ in 0..<d_namlen {
            let (_, elem) = tuple.children[idx]
            idx = idx.advancedBy(1)
            nameBuf.append(elem as! Int8)
        }

        nameBuf.append(0)
        entry = readdir(dir)
    }
    closedir(dir)
    timer.stop()
    return timer.milliseconds
}

var trials = 10
if Process.arguments.count > 1 {
    if let trial_count = Int(Process.arguments[1]) {
        trials = trial_count
    }
}
for _ in 0..<trials {
    print(run())
}
