module Unistd_unix_lwt_unthreaded = struct
  (* This tells Lwt that the underlying file descriptor is open in non-blocking
     mode. That is *false*, and it causes Unistd_unix_lwt to run the pwrite call
     on the main thread, i.e., without using the Lwt thread pool. This is not
     correct, as it can result in blocking, but it is still measured in order to
     estimate Lwt overhead not related to the thread pool. *)
  let pwrite = Unistd_unix_lwt.pwrite ~blocking:false
end

open Benchmark_osx_pwrite
module Benchmark = Make (Use_lwt) (Unistd_unix_lwt_unthreaded)

let () = Benchmark.time ()
