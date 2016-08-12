open Benchmark_osx_readdir
module Benchmark = Run(Dirent_unix_readdir)

let () = run "Dirent_unix.readdir" 10 (module Benchmark)
