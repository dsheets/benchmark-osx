## Directory listing benchmarks

In order to understand how to efficiently perform one of the most common
file system traversal tasks, we compare directory listing
implementations in Swift, Go, C, and OCaml using all the common methods
at our disposal. OS X 10.10+ offers a 'bulk' attribute retrieval system
call, `getattrlistbulk`, for reading the same properties from every node
in a directory. We compare this interface to `readdir` and use common
asynchronous programming packages where available.
