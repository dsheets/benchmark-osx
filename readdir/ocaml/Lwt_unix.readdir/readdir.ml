open Benchmark_osx_readdir
module Benchmark = Benchmark_osx_readdir_lwt.Run_lwt(Lwt_unix_readdir)

let () = run "Lwt_unix.readdir" 10 (module Benchmark)
