open Benchmark_osx_readdir
module Benchmark = Benchmark_osx_readdir_lwt.Run_lwt(Osx_attr_lwt_getlistbulk)

let () = run "Osx_attr_lwt.getlistbulk" 10 (module Benchmark)
