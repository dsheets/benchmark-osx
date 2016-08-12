open Benchmark_osx_readdir

module type READDIR_ASYNC = sig
  open Async.Std
  type t

  val readdir : string -> t list Deferred.t
end

module Run_async(M : READDIR_ASYNC) : BENCHMARK = struct
  open Async.Std

  let time () =
    Thread_safe.block_on_async_exn (fun () ->
      let start = Mtime.counter () in
      M.readdir path
      >>= fun listing ->
      let span = Mtime.count start in
      let len = List.length listing in
      assert (len = expected_length || len = expected_length + 2);
      return (Mtime.to_ms span)
    )
end
