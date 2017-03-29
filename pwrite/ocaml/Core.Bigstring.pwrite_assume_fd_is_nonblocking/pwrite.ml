module Core_bigstring_buffer = struct
  type t = Core.Bigstring.t

  let allocate buffer_size = Core.Bigstring.create buffer_size
end

module Core_pwrite = struct
  (* The pwrite call is run on the main thread. The fd is actually in blocking
     mode. *)
  let pwrite fd buffer count offset =
    Core.Bigstring.pwrite_assume_fd_is_nonblocking
      fd ~offset:(Int64.to_int offset) ~pos:0 ~len:count buffer
end

open Benchmark_osx_pwrite
module Benchmark = Make (Use_blocking_io) (Core_bigstring_buffer) (Core_pwrite)

let () = Benchmark.time ()
