open Benchmark_osx_readdir
module Benchmark = Run(Unix_readdir)

let () = run "Unix.readdir" (module Benchmark)
