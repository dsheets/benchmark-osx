open Benchmark_osx_readdir
module Benchmark = Benchmark_osx_readdir_async.Run_async(Async_unix_readdir)

let () = run "Async_unix.readdir" 10 (module Benchmark)
