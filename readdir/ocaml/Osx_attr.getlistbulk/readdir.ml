open Benchmark_osx_readdir
module Benchmark = Run(Osx_attr_getlistbulk)

let () = run "Osx_attr.getlistbulk" (module Benchmark)
