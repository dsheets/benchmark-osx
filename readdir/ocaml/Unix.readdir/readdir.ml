open Benchmark_osx_readdir
module Benchmark = Run(Unix_readdir)

let () = run "Unix.readdir" 10 (module Benchmark)
