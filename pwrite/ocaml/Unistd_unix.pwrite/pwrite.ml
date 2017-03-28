open Benchmark_osx_pwrite
module Benchmark = Make (Use_blocking_io) (Unistd_unix)

let () = Benchmark.time ()
