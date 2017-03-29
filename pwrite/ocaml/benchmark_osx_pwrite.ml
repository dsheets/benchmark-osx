module type BENCHMARK = sig
  val time : unit -> unit
end

module type PWRITE = sig
  type 'a io
  type buffer

  val pwrite : Unix.file_descr -> buffer -> int -> int64 -> int io
end

module type IO = sig
  type 'a t

  val return : 'a -> 'a t
  val (>>=) : 'a t -> ('a -> 'b t) -> 'b t

  val init : unit -> unit
  val run : 'a t -> 'a
end

module type BUFFER = sig
  type t

  val allocate : int -> t
end

module Make
  (IO : IO)
  (Buffer : BUFFER)
  (Pwrite : PWRITE
    with type 'a io := 'a IO.t
    and type buffer := Buffer.t) : BENCHMARK = struct

  let time () =
    let buffer_size, repetitions =
      if Array.length Sys.argv > 2
      then int_of_string (Sys.argv.(1)), int_of_string (Sys.argv.(2))
      else 4096, 65536
    in

    let file = "../../scratch_output" in

    (* Closed on process exit. *)
    let fd = Unix.(openfile file [O_WRONLY; O_CREAT; O_TRUNC] 0o644) in
    let buffer = Buffer.allocate buffer_size in

    IO.init ();
    IO.run
      begin
        let open IO in

        let start = Mtime.counter () in
        let rec repeat = function
          | n when n <= 0 -> return ()
          | n ->
            Pwrite.pwrite fd buffer buffer_size 0L
            >>= fun written ->
            assert (written = buffer_size);
            repeat (n - 1)
        in
        repeat repetitions
        >>= fun () ->
        let elapsed = Mtime.count start in

        let elapsed = Mtime.to_us elapsed /. (float_of_int repetitions) in
        Printf.printf "%9.02f µs\n" elapsed;
        IO.return ()
      end
end

module Use_blocking_io : IO with type 'a t = 'a = struct
  type 'a t = 'a

  let return x = x
  let (>>=) x f = f x

  let init () = ()
  let run x = x
end

module Use_lwt : IO with type 'a t = 'a Lwt.t = struct
  type 'a t = 'a Lwt.t

  let return = Lwt.return
  let (>>=) = Lwt.bind

  let init () = Lwt_engine.(set (new Lwt_engine.Versioned.libev_2 ()))
  let run = Lwt_main.run
end

module Ctypes_buffer : BUFFER with type t = unit Ctypes.ptr = struct
  type t = unit Ctypes.ptr

  let allocate buffer_size =
    Ctypes.(allocate_n char ~count:buffer_size |> to_voidp)
end
