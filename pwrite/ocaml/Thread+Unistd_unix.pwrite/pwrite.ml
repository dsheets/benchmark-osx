(* This keeps a "thread pool" of one thread, and runs pwrite calls in that
   thread. *)
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
     offset : int64}

  let arguments_cell = cell ()
  let result_cell = cell ()

  (* Worker thread. *)
  let rec run_pwrite () =
    let arguments = wait arguments_cell in
    let written =
      Unistd_unix.pwrite
        arguments.fd arguments.buffer arguments.count arguments.offset
    in
    notify result_cell written;
    run_pwrite ()

  let (_ : Thread.t) = Thread.create run_pwrite ()

  (* Called repeatedly in the main thread. *)
  let pwrite fd buffer count offset =
    notify arguments_cell {fd; buffer; count; offset};
    wait result_cell
end

open Benchmark_osx_pwrite
module Benchmark = Make (Use_blocking_io) (Unistd_unix_with_std_threads)

let () = Benchmark.time ()
