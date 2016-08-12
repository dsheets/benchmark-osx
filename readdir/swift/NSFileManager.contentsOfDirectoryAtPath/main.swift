// Based on http://stackoverflow.com/questions/27721418/getting-list-of-files-in-documents-folder

import Foundation

func run() -> Double {
    let dir = "../../bigdir"
    var timer = Timer()

    timer.start()
    
    let fileManager =  NSFileManager.defaultManager()

    do {
        try fileManager.contentsOfDirectoryAtPath(dir)
    } catch let error as NSError {
        print(error.localizedDescription)
    }

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
