open Benchmark_osx_readdir

module type READDIR_LWT = sig
  type t

  val readdir : string -> t list Lwt.t
end

module Run_lwt(M : READDIR_LWT) : BENCHMARK = struct
  open Lwt.Infix

  let time () =
    Lwt_engine.(set (new libev));
    Lwt_main.run (
      let start = Mtime.counter () in
      M.readdir path
      >>= fun listing ->
      let span = Mtime.count start in
      let len = List.length listing in
      assert (len = expected_length || len = expected_length + 2);
      Lwt.return (Mtime.to_ms span)
    )
end
