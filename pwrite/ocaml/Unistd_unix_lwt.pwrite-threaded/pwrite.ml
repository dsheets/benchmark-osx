module Unistd_unix_lwt_threaded = struct
  (* This tells Lwt that the underlying file descriptor is open in blocking mode
     (which is correct). That causes Unistd_unix_lwt to use the Lwt thread pool
     to run the pwrite call. *)
  let pwrite = Unistd_unix_lwt.pwrite ~blocking:true
end

open Benchmark_osx_pwrite
module Benchmark = Make (Use_lwt) (Ctypes_buffer) (Unistd_unix_lwt_threaded)

let () = Benchmark.time ()
