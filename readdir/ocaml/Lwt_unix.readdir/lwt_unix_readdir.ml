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
