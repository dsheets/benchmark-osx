module Unistd_unix_with_lwt_preemptive_detach = struct
  let pwrite fd buffer count offset =
    Lwt_preemptive.detach (fun () ->
      Unistd_unix.pwrite fd buffer count offset) ()
end

open Benchmark_osx_pwrite
module Benchmark =
  Make (Use_lwt) (Ctypes_buffer) (Unistd_unix_with_lwt_preemptive_detach)

let () = Benchmark.time ()
