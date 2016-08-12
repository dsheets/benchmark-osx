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

for _ in 0..<10 {
    print(run())
}
