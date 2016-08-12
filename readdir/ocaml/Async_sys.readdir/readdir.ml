open Benchmark_osx_readdir
module Benchmark = Benchmark_osx_readdir_async.Run_async(Async_sys_readdir)

let () = run "Async_sys.readdir" (module Benchmark)
