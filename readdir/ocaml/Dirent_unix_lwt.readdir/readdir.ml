open Benchmark_osx_readdir
module Benchmark = Benchmark_osx_readdir_lwt.Run_lwt(Dirent_unix_lwt_readdir)

let () = run "Dirent_unix_lwt.readdir" (module Benchmark)
