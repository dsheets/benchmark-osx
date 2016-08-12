open Benchmark_osx_readdir
module Benchmark = Run(Osx_attr_getbulk)

let () = run "Osx_attr.getbulk" (module Benchmark)
