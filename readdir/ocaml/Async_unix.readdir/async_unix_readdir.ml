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
