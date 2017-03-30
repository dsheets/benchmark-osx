open Benchmark_osx_pwrite

(* This keeps a thread pool of one thread per file descriptor, and runs pwrite
   calls in those threads. *)
module Unistd_unix_with_std_threads = struct
  (* Cells for communication between the main thread and worker thread. *)
  type 'a cell =
    {mutable value : 'a option;
     mutex         : Mutex.t;
     condition     : Condition.t}

  let cell () =
    {value = None; mutex = Mutex.create (); condition = Condition.create ()}

  let wait : 'a cell -> 'a = fun cell ->
    Mutex.lock cell.mutex;
    let rec repeat () =
      match cell.value with
      | None ->
        Condition.wait cell.condition cell.mutex;
        repeat ()
      | Some value ->
        cell.value <- None;
        value
    in
    let value = repeat () in
    Mutex.unlock cell.mutex;
    value

  let notify : 'a cell -> 'a -> unit = fun cell value ->
    Mutex.lock cell.mutex;
    assert (cell.value = None);
    cell.value <- Some value;
    Condition.signal cell.condition;
    Mutex.unlock cell.mutex;

  (* The actual cells. *)
  type arguments =
    {fd     : Unix.file_descr;
     buffer : unit Ctypes.ptr;
     count  : int;
     offset : int64;
     k      : int -> unit}

  let arguments_cells : (Unix.file_descr, arguments cell) Hashtbl.t =
    Hashtbl.create 16

  (* Worker threads. *)
  let rec run_pwrite arguments_cell =
    let arguments = wait arguments_cell in
    let written =
      Unistd_unix.pwrite
        arguments.fd arguments.buffer arguments.count arguments.offset
    in
    Use_threaded_cps.notify (fun () -> arguments.k written);
    run_pwrite arguments_cell

  (* Called repeatedly in the main thread. *)
  let pwrite fd buffer count offset k =
    let arguments_cell =
      match Hashtbl.find arguments_cells fd with
      | c -> c
      | exception Not_found ->
        let arguments_cell = cell () in
        ignore (Thread.create run_pwrite arguments_cell);
        Hashtbl.add arguments_cells fd arguments_cell;
        arguments_cell
    in
    notify arguments_cell {fd; buffer; count; offset; k = (fun i -> k i)};
end

module Benchmark =
  Make (Use_threaded_cps) (Ctypes_buffer) (Unistd_unix_with_std_threads)

let () = Benchmark.time ()
