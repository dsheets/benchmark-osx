open Benchmark_osx_pwrite
module Benchmark = Make (Use_blocking_io) (Ctypes_buffer) (Unistd_unix)

let () = Benchmark.time ()
