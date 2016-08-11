
module Bench_sys = struct
  type t = string

  let readdir p =
    let listing = Sys.readdir p in
    Array.to_list listing (* TODO: Does this unacceptably skew results? *)
end

module Bench_unix = struct
  type t = string

  let readdir p =
    let dh = Unix.opendir p in
    let rec next listing =
      match Unix.readdir dh with
      | exception End_of_file -> listing
      | dirent -> next (dirent::listing)
    in
    let listing = next [] in
    Unix.closedir dh;
    listing
end

module Bench_dirent = struct
  type t = Dirent.Dirent.t

  let readdir p =
    let dh = Dirent_unix.opendir p in
    let rec next listing =
      match Dirent_unix.readdir dh with
      | exception End_of_file -> listing
      | dirent -> next (dirent::listing)
    in
    let listing = next [] in
    Dirent_unix.closedir dh;
    listing
end

module Bench_lwt_unix = struct
  type t = string
  open Lwt.Infix

  let readdir p =
    Lwt_unix.opendir p
    >>= fun dh ->
    let rec next listing =
      Lwt.catch
        (fun () -> Lwt_unix.readdir dh >>= Lwt.return_some)
        (function End_of_file -> Lwt.return_none | exn -> Lwt.fail exn)
      >>= function
      | Some dirent -> next (dirent::listing)
      | None -> Lwt.return listing
    in
    next []
    >>= fun listing ->
    Lwt_unix.closedir dh
    >>= fun () ->
    Lwt.return listing
end

module Bench_dirent_lwt = struct
  type t = Dirent.Dirent.t
  open Lwt.Infix

  let readdir p =
    Dirent_unix_lwt.opendir p
    >>= fun dh ->
    let rec next listing =
      Lwt.catch
        (fun () -> Dirent_unix_lwt.readdir dh >>= Lwt.return_some)
        (function End_of_file -> Lwt.return_none | exn -> Lwt.fail exn)
      >>= function
      | Some dirent -> next (dirent::listing)
      | None -> Lwt.return listing
    in
    next []
    >>= fun listing ->
    Dirent_unix_lwt.closedir dh
    >>= fun () ->
    Lwt.return listing
end

module Bench_osx_attr = struct
  type t = string * Osx_attr.Vnode.Vtype.t option

  let readdir p =
    let fd = Unix.openfile p [] 0 in
    let rec next listing =
      match Osx_attr.(getbulk (Select.Common Common.OBJTYPE) fd) with
      | [] -> listing
      | more -> next (List.rev_append more listing)
    in
    let listing = next [] in
    Unix.close fd;
    listing
end

module Bench_osx_attr_full = struct
  type t = Osx_attr.Value.t list

  let type_and_id = Osx_attr.(Query.[
    Common Common.OBJTYPE;
    Common Common.FILEID;
  ])

  let readdir p =
    let fd = Unix.openfile p [] 0 in
    let rec next listing =
      match Osx_attr.(getlistbulk type_and_id fd) with
      | [] -> listing
      | more -> next (List.rev_append more listing)
    in
    let listing = next [] in
    Unix.close fd;
    listing
end

module Bench_osx_attr_lwt = struct
  type t = string * Osx_attr.Vnode.Vtype.t option
  open Lwt.Infix

  let readdir p =
    Lwt_unix.openfile p [] 0
    >>= fun lwt_fd ->
    let fd = Lwt_unix.unix_file_descr lwt_fd in
    let rec next listing =
      Osx_attr_lwt.getbulk Osx_attr.(Select.Common Common.OBJTYPE) fd
      >>= function
      | [] -> Lwt.return listing
      | more -> next (List.rev_append more listing)
    in
    next []
    >>= fun listing ->
    Lwt_unix.close lwt_fd
    >>= fun () ->
    Lwt.return listing
end

module Bench_osx_attr_lwt_full = struct
  type t = Osx_attr.Value.t list
  open Lwt.Infix

  let readdir p =
    Lwt_unix.openfile p [] 0
    >>= fun lwt_fd ->
    let fd = Lwt_unix.unix_file_descr lwt_fd in
    let rec next listing =
      Osx_attr_lwt.getlistbulk Bench_osx_attr_full.type_and_id fd
      >>= function
      | [] -> Lwt.return listing
      | more -> next (List.rev_append more listing)
    in
    next []
    >>= fun listing ->
    Lwt_unix.close lwt_fd
    >>= fun () ->
    Lwt.return listing  
end

module Bench_async_sys = struct
  type t = string
  open Async.Std
  open Async_unix
  
  let readdir p =
    Async_sys.readdir p
    >>= fun listing ->
    (* TODO: Does this unacceptably skew results? *)
    return (Array.to_list listing)
end

module Bench_async_unix = struct
  type t = string
  open Core.Std
  open Async.Std
  open Async_unix.Std
  open Async_unix

  let readdir p =
    Unix_syscalls.opendir p
    >>= fun dh ->
    let rec next listing =
      try_with ~extract_exn:true (fun () -> Unix_syscalls.readdir dh)
      >>= function
      | Ok dirent -> next (dirent::listing)
      | Error End_of_file -> return listing
      | Error exn -> raise exn
    in
    next []
    >>= fun listing ->
    Unix_syscalls.closedir dh
    >>= fun () ->
    return listing
end

module type READDIR = sig
  type t

  val readdir : string -> t list
end

module type READDIR_LWT = sig
  type t

  val readdir : string -> t list Lwt.t
end

module type READDIR_ASYNC = sig
  open Async.Std
  type t

  val readdir : string -> t list Deferred.t
end

module type BENCHMARK = sig
  val time : unit -> float
end

let path = "bigdir"
let expected_length = 4096

module Run(M : READDIR) : BENCHMARK = struct
  let time () =
    let start = Mtime.counter () in
    let listing = M.readdir path in
    let span = Mtime.count start in
    let len = List.length listing in
    assert (len = expected_length || len = expected_length + 2);
    Mtime.to_ms span
end

module Run_lwt(M : READDIR_LWT) : BENCHMARK = struct
  open Lwt.Infix

  let time () =
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

module Run_sys = Run(Bench_sys)
module Run_unix = Run(Bench_unix)
module Run_dirent = Run(Bench_dirent)
module Run_osx_attr = Run(Bench_osx_attr)
module Run_osx_attr_full = Run(Bench_osx_attr_full)

module Run_lwt_unix = Run_lwt(Bench_lwt_unix)
module Run_dirent_lwt = Run_lwt(Bench_dirent_lwt)
module Run_osx_attr_lwt = Run_lwt(Bench_osx_attr_lwt)
module Run_osx_attr_lwt_full = Run_lwt(Bench_osx_attr_lwt)

module Run_async_sys = Run_async(Bench_async_sys)
module Run_async_unix = Run_async(Bench_async_unix)

let run name count modu =
  let module Benchmark = (val modu : BENCHMARK) in
  print_endline name;
  for i = 0 to count - 1 do
    let f = Benchmark.time () in
    Printf.printf "%f\n" f
  done;
  print_endline ""
;;

run "sys" 10 (module Run_sys);
run "unix" 10 (module Run_unix);
run "dirent" 10 (module Run_dirent);
run "osx_attr" 10 (module Run_osx_attr);
run "osx_attr_full" 10 (module Run_osx_attr_full);
run "lwt_unix" 10 (module Run_lwt_unix);
run "dirent_lwt" 10 (module Run_dirent_lwt);
run "osx_attr_lwt" 10 (module Run_osx_attr_lwt);
run "osx_attr_lwt_full" 10 (module Run_osx_attr_lwt_full);
run "async_sys" 10 (module Run_async_sys);
run "async_unix" 10 (module Run_async_unix);
()

