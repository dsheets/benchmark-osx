open Benchmark_osx_readdir
module Benchmark = Benchmark_osx_readdir_lwt.Run_lwt(Osx_attr_lwt_getbulk)

let () = run "Osx_attr_lwt.getbulk" 10 (module Benchmark)
