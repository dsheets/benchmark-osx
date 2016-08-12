open Benchmark_osx_readdir
module Benchmark = Run(Sys_readdir)

let () = run "Sys.readdir" (module Benchmark)
