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
  val join : unit t list -> unit t

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

  let time_configured buffer_size repetitions concurrency =
    let files =
      Array.init concurrency
        (Printf.sprintf "../../scratch_output/thread-%i")
    in

    (* Closed on process exit. *)
    let fds =
      Array.init concurrency (fun n ->
        Unix.(openfile files.(n) [O_WRONLY; O_CREAT; O_TRUNC] 0o644))
    in

    let buffers =
      Array.init concurrency (fun _ -> Buffer.allocate buffer_size) in

    let thread n =
      let open IO in
      let rec repeat = function
        | n' when n' <= 0 -> return ()
        | n' ->
          Pwrite.pwrite fds.(n) buffers.(n) buffer_size 0L
          >>= fun written ->
          assert (written = buffer_size);
          repeat (n' - 1)
      in
      repeat repetitions
    in

    IO.init ();
    IO.run
      begin
        let open IO in

        let start = Mtime.counter () in
        let threads = Array.init concurrency thread |> Array.to_list in
        IO.join threads >>= fun () ->
        let elapsed = Mtime.count start in

        let per_byte =
          Mtime.to_ns elapsed
          /. (float_of_int buffer_size)
          /. (float_of_int repetitions)
          /. (float_of_int concurrency)
        in
        let per_second =
          (float_of_int (buffer_size * repetitions * concurrency))
          /. (Mtime.to_s elapsed)
          /. 1024. /. 1024.
        in
        Printf.printf "%9.02f ns/B (%.0f MB/sec)\n" per_byte per_second;

        IO.return ()
      end

  let time () =
    let open Cmdliner in

    let buffer_size =
      Arg.(value & opt int 4096 &
        info ["buffer-size"] ~docv:"BYTES"
          ~env:(env_var "BENCHMARK_BUFFER_SIZE"))
    in

    let repetitions =
      Arg.(value & opt int 65536 &
        info ["repetitions"] ~docv:"N"
          ~env:(env_var "BENCHMARK_REPETITIONS"))
    in

    let concurrency =
      Arg.(value & opt int 1 &
        info ["concurrency"] ~docv:"N"
          ~env:(env_var "BENCHMARK_CONCURRENCY"))
    in

    let command =
      Term.(const time_configured $ buffer_size $ repetitions $ concurrency),
      Term.info "pwrite"
    in

    Term.(exit @@ eval command)
end

module Use_blocking_io : IO with type 'a t = 'a = struct
  type 'a t = 'a

  let return x = x
  let (>>=) x f = f x
  let join _ = ()

  let init () = ()
  let run x = x
end

module Use_lwt : IO with type 'a t = 'a Lwt.t = struct
  type 'a t = 'a Lwt.t

  let return = Lwt.return
  let (>>=) = Lwt.bind
  let join = Lwt.join

  let init () = Lwt_engine.(set (new Lwt_engine.Versioned.libev_2 ()))
  let run = Lwt_main.run
end

module Use_threaded_cps = struct
  type 'a t = ('a -> unit) -> unit

  let return x = fun k -> k x
  let (>>=) f g = fun k -> f (fun x -> g x k)
  let join fs =
    fun k ->
      let remaining = ref (List.length fs) in
      if !remaining = 0 then k ()
      else
        let k' () =
          if !remaining = 1 then k ()
          else remaining := !remaining - 1
        in
        List.iter (fun f -> f k') fs

  let init () = ()

  let notifications : (unit -> unit) list ref = ref []
  let notification_mutex = Mutex.create ()
  let notification_condition = Condition.create ()

  let notify g =
    Mutex.lock notification_mutex;
    notifications := !notifications @ [g];
    Condition.signal notification_condition;
    Mutex.unlock notification_mutex

  let run f =
    let result = ref None in
    f (fun x -> result := Some x);
    Mutex.lock notification_mutex;
    let rec loop () =
      match !result with
      | Some x ->
        Mutex.unlock notification_mutex;
        x
      | None ->
        match !notifications with
        | [] ->
          Condition.wait notification_condition notification_mutex;
          loop ()
        | g::more ->
          notifications := more;
          Mutex.unlock notification_mutex;
          g ();
          Mutex.lock notification_mutex;
          loop ()
    in
    let result = loop () in
    Mutex.unlock notification_mutex;
    result
end

module Ctypes_buffer : BUFFER with type t = unit Ctypes.ptr = struct
  type t = unit Ctypes.ptr

  let allocate buffer_size =
    Ctypes.(allocate_n char ~count:buffer_size |> to_voidp)
end
